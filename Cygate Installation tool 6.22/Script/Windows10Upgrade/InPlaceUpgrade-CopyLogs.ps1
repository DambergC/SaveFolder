$global:ScriptName = "[" + ([io.fileinfo]$MyInvocation.MyCommand.Definition).BaseName + "]"

#region Source: Main Functions
Try
{
	$tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment
	$RunningInTs = $true
}
Catch
{
	$RunningInTs = $false
}
if ($RunningInTs)
{
	try
	{
		# Hide the progress dialog
		$TSProgressUI = new-object -comobject Microsoft.SMS.TSProgressUI
		$TSProgressUI.CloseProgressDialog()
	}
	catch { }
}
function global:Write-Log ($text)
{
	$LogPath = "$env:windir\Logs\Software"; If (!(Test-Path "$LogPath")) { New-Item -Path "$LogPath" -ItemType dir -Force }
	$LogFile = "$LogPath\WindowsUpgrade.log"
	(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName $text" | Out-File -FilePath $LogFile -Append
}
function Mount-ISO ($Image)
{
	if (Test-Path "$Image")
	{
		Write-Log "Start dismounting image if mounted"
		try
		{
			Dismount-ISO -Image $Image
			Write-Log "ISO: $Image dismounted"
		}
		catch { Write-Log "Could not dismount $Image, probably not mounted" }
		
		try
		{
			$MountResult = Mount-DiskImage -ImagePath "$Image" -StorageType ISO -PassThru -ErrorAction Stop
			Start-Sleep -Seconds 10
			$DriveLetter = ($MountResult | Get-Volume).DriveLetter
			if ($DriveLetter.count -gt 1) { $DriveLetter = $DriveLetter | Select-Object -First }
			if ($DriveLetter -ne $null) { $DriveLetterFixed = $DriveLetter + ":" }
			Write-Log "Mount-ISO Result, Attached:   $($MountResult.Attached)"
			Write-Log "Mount-ISO Result, DevicePath: $($MountResult.DevicePath)"
			Write-Log "Mount-ISO Result, ImagePath:  $($MountResult.ImagePath)"
			Write-Log "Mount-ISO Result, Size:       $($MountResult.Size)"
			$MountResult = $true
		}
		catch [System.Exception] { $Message = $_.Exception.Message; Write-Log "Mount-ISO: Error - failed to mount ISO: $Image with error message: $Message"; $MountResult = $false }
	}
	else { $MountResult = $false }
	
	if ($MountResult -eq $false)
	{
		# Try mounting using ImDisk tool
		$ParentDirectory = (Get-Item $PSScriptRoot).parent.parent.FullName
		if (Test-Path "$ParentDirectory\Tools\ImDisk\install.bat")
		{
			
			# Install Driver
			try
			{
				$Process = Start-Process -FilePath "$PSScriptRoot\install.bat" -ArgumentList "/fullsilent /lang:english /installfolder:`"${env:ProgramFiles(x86)}\ImDisk`" >> $env:windir\Logs\Software\ImDisk_Install.log 2>&1" -Wait -PassThru -WindowStyle Hidden -ErrorAction Stop
				$ErrorCode = $Process.ExitCode
				Write-Log "ImDisk drivers installed with exit code: $ErrorCode"
			}
			catch { Write-Log "Error installing ImDisk driver" }
			
			# Remove desktop shortcuts
			Remove-Item -Path "$env:USERPROFILE\Desktop\ImDisk*.*"
			Remove-Item -Path "$env:USERPROFILE\Desktop\Mount Image File*.*"
			Remove-Item -Path "$env:USERPROFILE\Desktop\RamDisk Configuration*.*"
			
			# Mount ISO
			if (Test-Path "${env:ProgramFiles(x86)}\ImDisk\MountImg.exe")
			{
				Try
				{
					Write-Log "Try mounting ISO using ImDisk tool"
					$Process = Start-Process -FilePath "${env:ProgramFiles(x86)}\ImDisk\MountImg.exe" -ArgumentList "`"$Image`" /MOUNT" -NoNewWindow -ErrorAction Stop
					$ErrorCode = $Process.ExitCode
				}
				catch { Write-Log "Error mounting ISO using ImDisk tool" }
				Start-Sleep -Seconds 10
			}
			else { Write-Log "Error: ${env:ProgramFiles(x86)}\ImDisk\MountImg.exe" }
			
			# Get mounted drive letter
			$DriveLetters = @("D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P")
			foreach ($DriveLetter in $DriveLetters)
			{
				$Path = $DriveLetter + ":\sources\install.wim"
				if (Test-Path "$Path") { $MountResult = $true; Write-Log "Mounted ISO connected to drive letter: $DriveLetter"; break }
			}
			if ($DriveLetter -like "*:*") { $DriveLetterFixed = $DriveLetter }
			else { $DriveLetterFixed = $DriveLetter + ":" }
		}
		else { Write-Log "Error: ImDisk tool not found - skipping" }
	}
	
	if ($MountResult -eq $false)
	{
		Write-Log "Mounting ISO did not succeed, trying fix disk problems before retry mount"
		# Try running chdksk and sfc to correct problem
		try
		{
			Write-Log "Running chkdsk /f"
			$Process = Start-Process -FilePath "chkdsk.exe" -ArgumentList "/f" -NoNewWindow -Wait -PassThru -ErrorAction Stop
			$ErrorCode = $Process.ExitCode
			Write-Log "chkdsk /f run with exit code: $ErrorCode"
		}
		catch { Write-Log "Error running chkdsk /f" }
		
		try
		{
			Write-Log "Running sfc /scannow"
			$Process = Start-Process -FilePath "sfc.exe" -ArgumentList "/scannow" -NoNewWindow -Wait -PassThru -ErrorAction Stop
			$ErrorCode = $Process.ExitCode
			Write-Log "sfc /scannow run with exit code: $ErrorCode"
		}
		catch { Write-Log "Error running sfc /scannow" }
		
		# Retry mounting ISO
		try
		{
			$MountResult = Mount-DiskImage -ImagePath "$Image" -StorageType ISO -PassThru -ErrorAction Stop
			Start-Sleep -Seconds 10
			$DriveLetter = ($MountResult | Get-Volume).DriveLetter
			if ($DriveLetter.count -gt 1) { $DriveLetter = $DriveLetter | Select-Object -First }
			if ($DriveLetter -ne $null) { $DriveLetterFixed = $DriveLetter + ":" }
			Write-Log "Mount-ISO Result, Attached:   $($MountResult.Attached)"
			Write-Log "Mount-ISO Result, DevicePath: $($MountResult.DevicePath)"
			Write-Log "Mount-ISO Result, ImagePath:  $($MountResult.ImagePath)"
			Write-Log "Mount-ISO Result, Size:       $($MountResult.Size)"
			$MountResult = $true
		}
		catch [System.Exception] { $Message = $_.Exception.Message; Write-Log "Mount-ISO: Error - failed to mount ISO: $Image with error message: $Message"; $MountResult = $false }
	}
	return $DriveLetterFixed, $MountResult
}
function Dismount-ISO ($Image)
{
	try
	{
		$DismountResult = Dismount-DiskImage -ImagePath "$Image"
	}
	catch { }
	
	# Uninstall driver (will also unmount)
	$ParentDirectory = (Get-Item $PSScriptRoot).parent.parent.FullName
	if (Test-Path "$ParentDirectory\Tools\ImDisk\install.bat")
	{
		try
		{
			$Process = Start-Process -FilePath "$ParentDirectory\Tools\ImDisk\install.bat" -ArgumentList "/silentuninstall" -Wait -PassThru -WindowStyle Hidden -ErrorAction Stop
			$ErrorCode = $Process.ExitCode
			Write-Log "ImDisk drivers uninstalled with exit code: $ErrorCode"
		}
		catch { Write-Log "Error uninstalling ImDisk driver" }
	}
	return
}
function Get-LanguageFromCode ($Code)
{
	switch ($Code)
	{
		"0416" { $Lang = 'pt-BR' }
		"0402" { $Lang = 'bg-BG' }
		"0004" { $Lang = 'zh-CN' }
		"7C04" { $Lang = 'zh-TW' }
		"041a" { $Lang = 'hr-HR' }
		"0405" { $Lang = 'cs-CZ' }
		"0406" { $Lang = 'da-DK' }
		"0413" { $Lang = 'nl-NL' }
		"0409" { $Lang = 'en-US' }
		"0425" { $Lang = 'et-EE' }
		"040b" { $Lang = 'fi-FI' }
		"040c" { $Lang = 'fr-FR' }
		"0c0c" { $Lang = 'fr-CA' }
		"0407" { $Lang = 'de-DE' }
		"0408" { $Lang = 'el-GR' }
		"040d" { $Lang = 'he-IL' }
		"040e" { $Lang = 'hu-HU' }
		"0410" { $Lang = 'it-IT' }
		"0411" { $Lang = 'ja-JP' }
		"0412" { $Lang = 'ko-KR' }
		"0426" { $Lang = 'lv-LV' }
		"0427" { $Lang = 'lt-LT' }
		"0414" { $Lang = 'nb-NO' }
		"0415" { $Lang = 'pl-PL' }
		"0816" { $Lang = 'pt-PT' }
		"0418" { $Lang = 'ro-RO' }
		"0419" { $Lang = 'ru-RU' }
		"081a" { $Lang = 'sr-Latn-CS' }
		"041b" { $Lang = 'sk-SK' }
		"0424" { $Lang = 'sl-SI' }
		"0c0a" { $Lang = 'es-ES' }
		"041d" { $Lang = 'sv-SE' }
		"041e" { $Lang = 'th-TH' }
		"041f" { $Lang = 'tr-TR' }
		"0422" { $Lang = 'uk-UA' }
	}
	return $Lang
}
#endregion Main Function

$Username = $tsenv.Value("OSDLogUser")
$Password = $tsenv.Value("OSDLogUserPassword")

# Prepare for Logging
$LogFileGlobal = "_Upgrade Errors.log"
$LogFileComplianceGlobal = "_ComplianceCheckErrors.log"
Write-Log "Copy Logs"

$ComputerName = $env:COMPUTERNAME

# Disonnect Log Share
if (Test-Path "T:")
{
	try
	{
		$Process = Start-Process -FilePath "NET.exe" -ArgumentList "USE T: /DELETE /Y" -NoNewWindow -Wait -PassThru -ErrorAction Stop
		Write-Log "Disconnecting mapped drive to log share"
	}
	catch { Write-Log "Error: Failed disconnecting mapped drive to log share" }
}

$LogShare = "\\" + $tsenv.Value("OSDLogServer") + '\Logs$'
$LogServer = $tsenv.Value("OSDLogServer")

# Connect Log share
try
{
	Write-Log "Mapping Network Drive T: to Log Share $LogShare"
	$net = New-Object -comobject Wscript.Network
    $net.MapNetworkDrive("T:", "$LogShare", 0, "$LogServer\$Username", "$Password")
}
catch [System.Exception]{
	$Message = $_.Exception.Message
	Write-Log "Connecting to log share $LogShare, exit code: $Message"
	# exit
	Write-Log "Trying to map T: with NET USE"
	$Process = Start-Process -FilePath "NET.exe" -ArgumentList "USE T: $LogShare /user:`"$LogServer\$Username`" $Password" -Wait -PassThru -NoNewWindow -ErrorAction SilentlyContinue
	$ErrorCode = $Process.ExitCode
	Write-Log "Mapped T: with NET USE with exit code: $ErrorCode"
	if ($ErrorCode -ne 0)
	{
		# exit
	}
}
if (!(Test-Path "T:"))
{
	Write-Log "Try mapping T: without username / password"
	$Process = Start-Process -FilePath "NET.exe" -ArgumentList "USE T: $LogShare" -Wait -PassThru -NoNewWindow -ErrorAction SilentlyContinue
	$ErrorCode = $Process.ExitCode
	Write-Log "Mapped T: with NET USE with exit code: $ErrorCode"
}

# First time copy
if (($tsenv.Value("OSDFirstLogCopy") -eq $null) -or ($tsenv.Value("OSDFirstLogCopy") -ne $true))
{
	Write-Log "This is first time copying log files"
	if (Test-Path "T:\$ComputerName\WindowsUpgrade")
	{
		Write-Log "Folder $ComputerName already exist"
		try
		{
			Remove-Item -Path "T:\$ComputerName\WindowsUpgrade\*" -Recurse -Force
			Write-Log "First time connecting to log share - deleting old logs"
		}
		catch [System.Exception]{
			$Message = $_.Exception.Message
			Write-Log "First time connecting to log share - deleting old logs with exit code: $Message"
		}
	}
	else
	{ Write-Log "Folder $ComputerName does not exist - creating"; New-Item -Path "T:\$ComputerName\WindowsUpgrade" -ItemType dir -Force -ErrorAction SilentlyContinue }
		$tsenv.Value("OSDFirstLogCopy") = $true
}

# Update Timestamp on folder
try
{
	(Get-Item "T:\$ComputerName" -Force -ErrorAction Stop).LastWriteTime = (Get-Date)
	Write-Log "Update time stamp on log folder T:\$ComputerName"
}
catch { Write-Log "Error: Failed to update time stamp on folder T:\$ComputerName" }

# Check if global Errors file exist
if (Test-Path "$env:TEMP\UpgradeErrors.log")
{
	Write-Log "Copying upgrade messages to $LogShare"
	try
	{
		foreach ($line in [System.IO.File]::ReadLines("$env:TEMP\UpgradeErrors.log"))
		{
			$line | Out-File -FilePath "T:\$LogFileGlobal" -Append
		}
		Copy-Item -Path "$env:TEMP\UpgradeErrors.log" -Destination "T:\$ComputerName\WindowsUpgrade" -Force
		Remove-Item -Path "$env:TEMP\UpgradeErrors.log" -Force
	}
	catch { Write-Log "Error: Failed copying upgrade error messages to $LogShare" }
}

# Check if BIOS error log exist to copy to root of log share
if (Test-Path "$env:windir\Logs\Software\BIOSError.txt")
{
	Write-Log "Copying BIOS error log from $env:windir\Logs\Software to $LogShare"
	try
	{
		foreach ($line in [System.IO.File]::ReadLines("$env:windir\Logs\Software\BIOSError.txt"))
		{
			$line | Out-File -FilePath "T:\$LogFileGlobal" -Append
		}
		Copy-Item -Path "$env:windir\Logs\Software\BIOSError.txt" -Destination "T:\$ComputerName" -Force
		Remove-Item -Path "$env:windir\Logs\Software\BIOSError.txt" -Force
	}
	catch { }
}

# Copy HP firmware update log(s)
if (Test-Path "$env:TEMP\HP*.log")
{
	try
	{
		Copy-Item -Path "$env:TEMP\HP*.log" -Destination "T:\$ComputerName" -Force
		Write-Log "Copying HP firmware update log(s) to $LogShare\$ComputerName"
	}
	catch [System.Exception]{
		$Message = $_.Exception.Message
		Write-Log "Copying HP firmware update log(s) to $LogShare\$ComputerName with exit code: $Message"
	}
}

# Check if global compatibility check error file exist
if (Test-Path "$env:TEMP\ComplianceCheckErrors.log")
{
	Write-Log "Copying compliance messages to $LogShare"
	try
	{
		foreach ($line in [System.IO.File]::ReadLines("$env:TEMP\ComplianceCheckErrors.log"))
		{
			$line | Out-File -FilePath "T:\$LogFileComplianceGlobal" -Append
		}
		Copy-Item -Path "$env:TEMP\ComplianceCheckErrors.log" -Destination "T:\$ComputerName\WindowsUpgrade" -Force
		Remove-Item -Path "$env:TEMP\ComplianceCheckErrors.log" -Force
	}
	catch { Write-Log "Error: Failed copying upgrade error messages to $LogShare" }
}

# Remove wrong ComplianceCheckErrors.log
if (Test-Path "T:\$ComputerName\ComplianceCheckErrors.log")
{
	try
	{
		Remove-Item -Path "T:\$ComputerName\ComplianceCheckErrors.log" -Force
		Write-Log "Removing wrong T:\$ComputerName\ComplianceCheckErrors.log"
	}
	catch { Write-Log "Error: Failed to remove wrong T:\$ComputerName\ComplianceCheckErrors.log" }
}

# Copy all logs in _SMSTSLOGS and TEMP
if (Test-Path "$env:SystemDrive\_SMSTaskSequence\Logs\Smstslog")
{
	try
	{
		Copy-Item -Path "$env:SystemDrive\_SMSTaskSequence\Logs\Smstslog\*.*" -Destination "T:\$ComputerName\WindowsUpgrade" -Force
		Write-Log "Copying logs from $env:SystemDrive\_SMSTaskSequence\Logs\Smstslog to T:\$ComputerName\WindowsUpgrade"
	}
	catch [System.Exception]{
		$Message = $_.Exception.Message
		Write-Log "Error copying logs from $env:SystemDrive\_SMSTaskSequence\Logs\Smstslog to $LogShare\$ComputerName\WindowsUpgrade with exit code: $Message"
	}
}
else { Write-Log "Did not find $env:SystemDrive\_SMSTaskSequence\Logs\Smstslog" }

if (Test-Path "$env:windir\CCM\Logs\Smstslog\smsts.log")
{
	try
	{
		
		Copy-Item -Path "$env:windir\CCM\Logs\Smstslog\*.*" -Destination "T:\$ComputerName\WindowsUpgrade" -Force
		Write-Log "Copying logs from $env:windir\CCM\Logs\Smstslog to T:\$ComputerName\WindowsUpgrade"
	}
	catch [System.Exception]{
		$Message = $_.Exception.Message
		Write-Log "Error copying logs from $env:SystemDrive\_SMSTaskSequence\Logs\Smstslog to $LogShare\$ComputerName\WindowsUpgrade with exit code: $Message"
	}
}
else { Write-Log "Did not find $env:SystemDrive\_SMSTaskSequence\Logs\Smstslog" }

if (Test-Path 'C:\$WINDOWS.~BT\Sources\Panther')
{
	New-Item -Path "T:\$ComputerName\WindowsUpgrade\Panther" -ItemType dir -Force
	try
	{
		Copy-Item -Path 'C:\$WINDOWS.~BT\Sources\Panther\*.*' -Destination "T:\$ComputerName\WindowsUpgrade\Panther" -Force
			Write-Log "Copying logs from Panther folder to T:\$ComputerName\WindowsUpgrade\Panther"
	}
	catch [System.Exception]{
		$Message = $_.Exception.Message
		Write-Log "Error copying logs from Panther folder to $LogShare\$ComputerName\WindowsUpgrade\Panther with exit code: $Message"
	}
}
else { Write-Log "Did not find C:\sWINDOWS.~BT\Sources\Panther" }

if (Test-Path "$env:windir\Logs\Software\setupdiag_windowsupgrade.log")
{
	try
	{
		Copy-Item -Path "$env:windir\Logs\Software\setupdiag_windowsupgrade.log" -Destination "T:\$ComputerName\WindowsUpgrade" -Force
		Write-Log "Copying $env:windir\Logs\Software\setupdiag_windowsupgrade.log to T:\$ComputerName\WindowsUpgrade"
	}
	catch [System.Exception]{
		$Message = $_.Exception.Message
		Write-Log "Error copying $env:windir\Logs\Software\setupdiag_windowsupgrade.log to $LogShare\$ComputerName\WindowsUpgrade with exit code: $Message"
	}
}

if (Test-Path "$env:windir\Logs\Software\Logs.zip")
{
	try
	{
		Copy-Item -Path "$env:windir\Logs\Software\Logs.zip" -Destination "T:\$ComputerName\WindowsUpgrade" -Force
		Write-Log "Copying $env:windir\Logs\Software\Logs.zip to T:\$ComputerName\WindowsUpgrade"
	}
	catch [System.Exception]{
		$Message = $_.Exception.Message
		Write-Log "Error copying $env:windir\Logs\Software\Logs.zip to $LogShare\$ComputerName\WindowsUpgrade with exit code: $Message"
	}
}

if (Test-Path "$env:windir\Logs\Software\CompatCheck")
{
	try
	{
		if (Test-Path -Path "T:\$ComputerName\WindowsUpgrade\CompatCheck") { Remove-Item -Path "T:\$ComputerName\WindowsUpgrade\CompatCheck" -Force -Recurse }
		New-Item -Path "T:\$ComputerName\WindowsUpgrade\CompatCheck" -ItemType Dir -Force -ErrorAction SilentlyContinue
		Copy-Item -Path "$env:windir\Logs\Software\CompatCheck\*" -Destination "T:\$ComputerName\WindowsUpgrade\CompatCheck" -Force -Recurse
		Write-Log "Copying $env:windir\Logs\Software\CompatCheck to T:\$ComputerName\WindowsUpgrade\CompatCheck"
	}
	catch [System.Exception]{
		$Message = $_.Exception.Message
		Write-Log "Error copying $env:windir\Logs\Software\CompatCheck to $LogShare\$ComputerName\WindowsUpgrade\CompatCheck with exit code: $Message"
	}
}

# Writing variables to log file
try
{
	$ReturnCode = $tsenv.Value("ReturnCode")
	$OSDWindowsUpgrade = $tsenv.Value("OSDWindowsUpgrade")
	$OSDUpgradeCompatibility = $tsenv.Value("OSDUpgradeCompatibility")
	Write-Log "ReturnCode:              $ReturnCode"
	Write-Log "OSDWindowsUpgrade:       $OSDWindowsUpgrade"
	Write-Log "OSDUpgradeCompatibility: $OSDUpgradeCompatibility"
}
catch { Write-Log "Error: Failed to write variables to log file" }

if (Test-Path "$env:windir\Logs\Software\WindowsUpgrade.log")
{
	try
	{
		Copy-Item -Path "$env:windir\Logs\Software\WindowsUpgrade.log" -Destination "T:\$ComputerName\WindowsUpgrade" -Force
		Write-Log "Copying $env:windir\Logs\Software\WindowsUpgrade.log to T:\$ComputerName\WindowsUpgrade"
	}
	catch [System.Exception]{
		$Message = $_.Exception.Message
		Write-Log "Error copying $env:windir\Logs\Software\WindowsUpgrade.log to $LogShare\$ComputerName\WindowsUpgrade with exit code: $Message"
	}
}

if (Test-Path "$env:windir\Logs\Software\ISOExtraction.log")
{
	try
	{
		Copy-Item -Path "$env:windir\Logs\Software\ISOExtraction.log" -Destination "T:\$ComputerName\WindowsUpgrade" -Force
		Write-Log "Copying $env:windir\Logs\Software\ISOExtraction.log to T:\$ComputerName\WindowsUpgrade"
	}
	catch [System.Exception]{
		$Message = $_.Exception.Message
		Write-Log "Error copying $env:windir\Logs\Software\ISOExtraction.log to $LogShare\$ComputerName\WindowsUpgrade with exit code: $Message"
	}
}

if (Test-Path "$env:SystemDrive\_SMSTaskSequence\Logs\smsts.log")
{
	try
	{
		Copy-Item -Path "$env:SystemDrive\_SMSTaskSequence\Logs\*.*" -Destination "T:\$ComputerName\WindowsUpgrade" -Force
		Write-Log "Copying $env:windir\Logs\Software\WindowsUpgrade.log to T:\$ComputerName\WindowsUpgrade"
	}
	catch [System.Exception]{
		$Message = $_.Exception.Message
		Write-Log "Error copying $env:SystemDrive\_SMSTaskSequence\Logs\smsts.log to $LogShare\$ComputerName\WindowsUpgrade with exit code: $Message"
	}
}

# Disconnect drive
try
{
	$Process = Start-Process -FilePath "NET.exe" -ArgumentList "USE T: /DELETE /Y" -NoNewWindow -Wait -PassThru -ErrorAction Stop
	Write-Log "Disconnecting Log share"
}
catch { Write-Log "No Log share to disconnect" }
