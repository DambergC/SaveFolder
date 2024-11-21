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
function global:Write-GlobalLog ($text)
{
	try
	{
		$LogServer = $tsenv.Value("OSDLogServer")
		$LogShare = "\\" + $tsenv.Value("OSDLogServer") + '\Logs$'
	} catch {}
	$ComputerName = $env:COMPUTERNAME
	$GlobalLogFile = "_WindowsUpgradeError.log"
	
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
	
	try
	{
		(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "Computer Name: $ComputerName $text" | Out-File -FilePath $GlobalLogFile -Append
	}
	catch { Write-Log "Error: Failed copying upgrade error messages to $LogShare" }
	
	# Disconnect drive
	try
	{
		$Process = Start-Process -FilePath "NET.exe" -ArgumentList "USE T: /DELETE /Y" -NoNewWindow -Wait -PassThru -ErrorAction Stop
		Write-Log "Disconnecting Log share"
	}
	catch { Write-Log "No Log share to disconnect" }
}
function Mount-ISO ($Image)
{
	try { $tsenv.Value("OSDReboot") = $false }
	catch { }
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
		try { $tsenv.Value("OSDReboot") = $true }
		catch { }
		
		#		# Try running chdksk and sfc to correct problem
		#		try
		#		{
		#			Write-Log "Running chkdsk /f"
		#			$Process = Start-Process -FilePath "chkdsk.exe" -ArgumentList "/f" -NoNewWindow -Wait -PassThru -ErrorAction Stop
		#			$ErrorCode = $Process.ExitCode
		#			Write-Log "chkdsk /f run with exit code: $ErrorCode"
		#		}
		#		catch { Write-Log "Error running chkdsk /f" }
		#		
		#		try
		#		{
		#			Write-Log "Running sfc /scannow"
		#			$Process = Start-Process -FilePath "sfc.exe" -ArgumentList "/scannow" -NoNewWindow -Wait -PassThru -ErrorAction Stop
		#			$ErrorCode = $Process.ExitCode
		#			Write-Log "sfc /scannow run with exit code: $ErrorCode"
		#		}
		#		catch { Write-Log "Error running sfc /scannow" }
		#		
		#		# Retry mounting ISO
		#		try
		#		{
		#			$MountResult = Mount-DiskImage -ImagePath "$Image" -StorageType ISO -PassThru -ErrorAction Stop
		#			Start-Sleep -Seconds 10
		#			$DriveLetter = ($MountResult | Get-Volume).DriveLetter
		#			if ($DriveLetter.count -gt 1) { $DriveLetter = $DriveLetter | Select-Object -First }
		#			if ($DriveLetter -ne $null) { $DriveLetterFixed = $DriveLetter + ":" }
		#			Write-Log "Mount-ISO Result, Attached:   $($MountResult.Attached)"
		#			Write-Log "Mount-ISO Result, DevicePath: $($MountResult.DevicePath)"
		#			Write-Log "Mount-ISO Result, ImagePath:  $($MountResult.ImagePath)"
		#			Write-Log "Mount-ISO Result, Size:       $($MountResult.Size)"
		#			$MountResult = $true
		#		}
		#		catch [System.Exception] { $Message = $_.Exception.Message; Write-Log "Mount-ISO: Error - failed to mount ISO: $Image with error message: $Message"; $MountResult = $false }
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
function Get-LoggedOnUser
{
	$LoggedOnUser = $false
	$Sessions = WmiObject win32_ComputerSystem | select Username
	foreach ($Session in $Sessions)
	{
		$LocalUser = $Session.UserName
		if ($LocalUser -like "*\*")
		{
			$LoggedOnUser = $true; Write-Log "Logged on user - A console user is logged on to this device: $LocalUser"
		}
	}
	if ($LoggedOnUser -eq $false) { Write-Log "Logged on user - No console user is logged on to this device" }
	
	$LoggedOnRDPUser = $false
	$RDPUser = quser /server:'localhost'
	$RDPUserFile = "$env:TEMP\RDPUser.txt"
	if (Test-Path "$RDPUserFile") { Remove-Item -Path "$RDPUserFile" -Force }
	$RDPUser | Out-File "$RDPUserFile" -Append
	foreach ($line in [System.IO.File]::ReadLines($RDPUserFile))
	{
		if ($line -like "*rdp-*")
		{
			$Position = $line.IndexOf("rdp-")
			$username = $line.Substring(0, $Position - 3)
			$username = $username.Trim()
			$Position = $line.IndexOf("Active")
			$SessionID = ($line.Substring($Position - 3, 2)).Trim()
			[int]$SessionID = [convert]::ToInt32($SessionID)
			Write-Log "Logged on user - A RDP user is logged on to this device: $username on sessionID: $SessionID"
			$LoggedOnUser = $true
			$LoggedOnRDPUser = $true
		}
		if ($line -like "*Active*")
		{
			$Position = $line.IndexOf("Active")
			$username = $line.Substring(0, $Position)
			$username = $username.Trim()
			$Position = $line.IndexOf("Active")
			$SessionID = ($line.Substring($Position - 3, 2)).Trim()
			[int]$SessionID = [convert]::ToInt32($SessionID)
			Write-Log "Logged on user - A RDP console user is logged on to this device: $username on sessionID: $SessionID"
			$LoggedOnUser = $true
			$LoggedOnRDPUser = $true
		}
	}
	return $LoggedOnUser, $LoggedOnRDPUser, $username, $SessionID
}
function KillProcessesWithHandles
{
	param ([string]$path)
	$allProcesses = Get-Process
	
	# Then close all processes running inside the folder we are trying to delete
	$allProcesses | where { $_.Path -like ($path + "*") } | Stop-Process -Force -ErrorAction SilentlyContinue
	
	# Finally close all processes with modules loaded from folder we are trying to delete
	foreach ($lockedFile in Get-ChildItem -Path $path -Include * -Recurse)
	{
		foreach ($process in $allProcesses)
		{
			$process.Modules | where { $_.FileName -eq $lockedFile } | Stop-Process -Force -ErrorAction SilentlyContinue
		}
	}
}
#endregion Main Function

# Prepare for Logging
$global:LogFileGlobal = "$env:TEMP\UpgradeErrors.log"
if (Test-Path "$LogFileGlobal") { Remove-Item -Path "$LogFileGlobal" -Force }
Write-Log " "
Write-Log "Start Upgrade - running pre-req check"

# Setting variables
$Username = $tsenv.Value("OSDLogUser")
$Password = $tsenv.Value("OSDLogUserPassword")
try
{
	if ($tsenv.Value("OSDWindowsUpgrade") -ne $false) { $tsenv.Value("OSDWindowsUpgrade") = $true }
} catch {}
$returnCode = 0

# Close running Ready tool if opened (from another upgrade attempt)
Write-Log "Check if InPlaceUpgrade-ReadyTool.exe is running from another upgrade attempt"
if (Get-Process InPlaceUpgrade-ReadyTool -ErrorAction silentlycontinue)
{
	try { Write-Log "Another InPlaceUpgrade-ReadyTool.exe running - will close"; Start-Process -FilePath "taskkill.exe" -ArgumentList "/IM InPlaceUpgrade-ReadyTool.exe /F /T" -Wait -PassThru -NoNewWindow -ErrorAction SilentlyContinue }	catch { }
}
else { Write-Log "InPlaceUpgrade-ReadyTool.exe is not already running" }

# Get Task sequence version
try
{
	$TSversion = $tsenv.Value("TaskSequenceVer")
	$TSName = $tsenv.Value("_SMSTSPackageName")
	if ($TSName -ne $null) { Write-Log "Versions - Task Sequence Name   : $TSName" }
	if ($TSversion -ne $null) { Write-Log "Versions - Task Sequence Version: $TSversion" }
}
catch { }

# Get Installation Tools version from version text file in root of tools
$ParentDirectory = (Get-Item $PSScriptRoot).parent.parent.FullName
try
{
	$ToolsVersion = Get-Content "$ParentDirectory\Version.txt" -Force
}
catch { Write-Log "Versions - Error: Failed to get version from file" }
if ($ToolsVersion -eq $null) { $ToolsVersion = "Pre 5.4 - No version information found" }
Write-Log "Versions - Installation Tools Version:                        $ToolsVersion"

# Extract TS
$TStext = "$env:TEMP\TS.txt"
$TSxml = "$env:TEMP\TS.xml"
$tsenv.Value("_SMSTSTaskSequence") | Out-File -FilePath "$TStext" -Force
$xDoc = New-Object System.Xml.XmlDocument
$xDoc.Load($TStext)
$xDoc.Save($TSxml) #will save correctly

# Check if upgrade or install TS
$TSType = "Upgrade"
$FoundTSType = $false
foreach ($item in $tsenv.Value("_SMSTSTaskSequence"))
{
	if ($item -like "*OSDApplyOS.exe*") { $TSType = "Install"; Write-Log "Task Sequence is of type 'OS Deployment'"; $FoundTSType = $true }
	if ($item -like "*OSDUpgradeOS.exe*") { $TSType = "Upgrade"; Write-Log "Task Sequence is of type 'Upgrade'"; $FoundTSType = $true }
}
if ($FoundTSType -eq $false) { Write-Log "OSDApplyOS.exe or OSDUpgradeOS.exe not found in TS - assuming type Upgrade" }
$tsenv.Value("OSDTSType") = $TSType

# Get Computername for logging
$computerName = $env:COMPUTERNAME
try { $tsenv.Value("_SMSTSMachineName") = $computerName } catch {}
Write-Log "Computername = $computerName"

# Check if target Windows 10-build is already installed
$Build = [System.Environment]::OSVersion.Version.Build
$TargetBuild = $tsenv.Value("OSDTargetBuild")

if ($Build -lt $($tsenv.Value("OSDTargetBuild")))
{
	Write-Log "Current Windows version $Build is less than $TargetBuild, moving on"
	$tsenv.Value("OSDWindowsUpgrade") = $true
}
else
{
	Write-Log "Current Windows Version $Build is greater than or equal to $TargetBuild, skip upgrade..."
	$tsenv.Value("OSDWindowsUpgrade") = $false
	$tsenv.Value("gotoEnd") = $true
	# exit 0
}

# Get Registered Organization to use if OSDTitle is blank
try
{
	$OSDTitle = $tsenv.Value("OSDTitle")
	if (($OSDTitle -eq $null) -or ($OSDTitle.Length -lt 2))
	{
		$OSDTitle = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name "RegisteredOrganization").RegisteredOrganization
		$tsenv.Value("OSDTitle") = $OSDTitle
		Write-Log "OSDTitle is blank, using Registered Organization from regstry: $OSDTitle"
	}
	else
	{
		Write-Log "OSDTitle is set to: $OSDTitle"
	}
}
catch
{
	$tsenv.Value("OSDTitle") = "Corporate IT"
	Write-Log "Error setting OSDTitle, using 'Corporate IT' as variable"
}

# Make sure Software directory exists
Write-Log "Check if log folder exist"
$SoftwareLogFolderLocation = 'C:\Windows\Logs\Software'
$SoftwareLogFolderExist = Test-Path -Path $SoftwareLogFolderLocation
Write-Log "Log folder $SoftwareLogFolderLocation exists = $SoftwareLogFolderExist"

If (!$SoftwareLogFolderExist)
{
	Write-Log "Log folder does not exist - creating"
	New-Item -Path $SoftwareLogFolderLocation -ItemType dir -Force
}

# Make sure current IP Subnet is allowed
if (Test-Path "$PSScriptRoot\AllAllowedSubnets.txt")
{
	$allowedSubnets = Get-Content .\AllAllowedSubnets.txt
	$allowedSubnetsRegex = [string]::Join('|', $allowedSubnets)
	$allIPAddresses = Get-WmiObject Win32_NetworkAdapterConfiguration | Where { $_.Ipaddress.length -gt 1 } | Select-Object -ExpandProperty IPAddress
	Write-Log "All allowed IP Subnets $allowedSubnetsRegex"
	
	if ($allIPAddresses -match $allowedSubnetsRegex)
	{
		Write-Log "Current IP Subnet $allIPAddresses is allowed, moving on"
	}
	
	else
	{
		Write-Log "Current IP Subnet $allIPAddresses is NOT allowed, error"
		$tsenv.Value("OSDWindowsUpgrade") = $false
		$tsenv.Value("gotoEnd") = $false
		Write-GlobalLog "Error: Current IP Subnet $allIPAddresses is NOT allowed, error"
	}
}
else { Write-Log "No AllAllowedSubnets file found - consider all subnets allowed" }

# Make sure computer model is supported
if (Test-Path -Path "$PSScriptRoot\CertifiedComputerModels.txt")
{
	$supportedModels = Get-Content -Path "$PSScriptRoot\CertifiedComputerModels.txt"
	Write-Log "Currently supported computer models: $supportedModels"
}
else { Write-Log "CertifiedComputerModels.txt not found - skipping" }

$Manufacturer = (Get-WmiObject Win32_ComputerSystem).Manufacturer.TrimEnd()
if (Test-Path -Path "$PSScriptRoot\CertifiedComputerModels.txt")
{
	if ($Manufacturer -like "*Lenovo*")
	{
		$ModelFriendlyName = (Get-WmiObject Win32_ComputerSystemProduct).Version.TrimEnd()
		# Strip geration marker from name 1st, 2nd etc
		if ($ModelFriendlyName -like "*1st") { $ModelFriendlyName = $ModelFriendlyName.Substring(0, $ModelFriendlyName.IndexOf("1st")).TrimEnd() }
		if ($ModelFriendlyName -like "*2nd") { $ModelFriendlyName = $ModelFriendlyName.Substring(0, $ModelFriendlyName.IndexOf("2nd")).TrimEnd() }
		if ($ModelFriendlyName -like "*3rd") { $ModelFriendlyName = $ModelFriendlyName.Substring(0, $ModelFriendlyName.IndexOf("3rd")).TrimEnd() }
		if ($ModelFriendlyName -like "*4th") { $ModelFriendlyName = $ModelFriendlyName.Substring(0, $ModelFriendlyName.IndexOf("4th")).TrimEnd() }
		if ($ModelFriendlyName -like "*5th") { $ModelFriendlyName = $ModelFriendlyName.Substring(0, $ModelFriendlyName.IndexOf("5th")).TrimEnd() }
		if ($ModelFriendlyName -like "*6th") { $ModelFriendlyName = $ModelFriendlyName.Substring(0, $ModelFriendlyName.IndexOf("6th")).TrimEnd() }
		$ModelNumber = (Get-WmiObject Win32_ComputerSystem).Model.TrimEnd()
		$ModelNumber = $ModelNumber.Substring(0, 4)
		$modelMatch = $supportedModels | where { $_ -like "$ModelFriendlyName" }
		if (!($modelMatch)) { $modelMatch = $supportedModels | where { $_ -like "$ModelNumber" } }
	}
	else
	{
		$currentComputerModel = Get-WmiObject Win32_ComputerSystem | Select-Object -ExpandProperty Model
		$modelMatch = $supportedModels | where { $_ -like "$currentComputerModel" }
	}
	
	if ($modelMatch)
	{
		Write-Log "Current computer model $currentComputerModel is supported, moving on"
	}
	else
	{
		Write-Log "Current computer model $currentComputerModel is NOT supported, error"
		$tsenv.Value("OSDWindowsUpgrade") = $false
		$tsenv.Value("gotoEnd") = $false
		$returnCode = 8022
		Write-GlobalLog "Error: Current computer model $currentComputerModel is NOT supported, error"
	}
}
else { Write-Log "No CertifiedComputerModels file found - consider all models allowed" }


# Check Windows 10 Edition
$winEdition = (Get-WmiObject -class Win32_OperatingSystem).Caption

if ($winEdition -like "*enterprise"){ Write-Log "Current Windows 10 Edition = $winEdition" }
else { Write-Log "Current Windows 10 Edition = $winEdition" }

# Determine OS-Architecture, if not 64-bit = Exit
$OSArchitecture = (Get-WmiObject Win32_OperatingSystem).OSArchitecture
if (! $OSArchitecture -eq '64-Bit')
{
	Write-Log "Current OS-Architecture is not 64-bit! Upgrade will not continue"
	$tsenv.Value("OSDWindowsUpgrade") = $false
	$tsenv.Value("gotoEnd") = $true
	$returnCode = 8022
	Write-GlobalLog "Error: Current OS-Architecture is not 64-bit! Upgrade will not continue"
} else { Write-Log "OS architecture is 64-bit - moving on" }

# Check log server and share
# Filter Log servers if array (eg. OSDLogServer = Server1.somedomain.com,Server2.somedomain.com and test if online)
$LogServers = $tsenv.Value("OSDLogServer")
Write-Log "Log Share - Start Testing Log Server(s) configured: $LogServers"
$LogServers = ($LogServers -split ",").Trim()
$tsenv.Value("OSDlogServerOperational") = $false

# Test of Log Server(s) for connection - LogServers could be with primary and secondary
if (($($Username.Length) -lt 1) -or ($($Password.Length) -lt 1) -or ($($LogServers.Length) -lt 1))
{
	Write-Log "Log Share - Log share parameters missing - skipping Log share check"
}
else
{
	foreach ($LogServer in $LogServers)
	{
		if (Test-Path "T:")
		{
			try
			{
				$Process = Start-Process -FilePath "NET.exe" -ArgumentList "USE T: /DELETE /Y" -NoNewWindow -Wait -PassThru -ErrorAction Stop
				Write-Log "Log Share - Disconnected mapped drive to log share"
			}
			catch { Write-Log "Log Share - No mapped drive to disconnect" }
		}
		
		$LogShare = "\\" + $LogServer + '\Logs$'
		$UsernameFull = $LogServer + "\" + $Username
		Write-Log "Log Share - Testing connection to Log Share"
		Write-Log "Log Share - LogServer: $LogServer"
		Write-Log "Log Share - LogServer: $LogShare"
		Write-Log "Log Share - Full Username: $UsernameFull"
		
		$TestConnection = Test-Connection $LogServer -Count 1 -Quiet
		if ($TestConnection -eq $true)
		{
			Write-Log "Log Share - Testing connection towards $LogServer - successful"
			try
			{
				$net = New-Object -comobject Wscript.Network
				$net.MapNetworkDrive("T:", "$LogShare", 0, "$UsernameFull", "$Password")
				Write-Log "Log Share - Mapping Log Share OK"
				$ErrorMapping = $false
			}
			catch [System.Exception]{
				$Message = $_.Exception.Message
				Write-Log "Log Share - Connecting to log share $LogShare, exit code: $Message"
				Write-Log "Log Share - Trying to map T: (Net Use T: $LogShare /user:$UsernameFull $Password)"
				$Process = Start-Process -FilePath "NET.exe" -ArgumentList "USE T: $LogShare /user:$UsernameFull $Password" -NoNewWindow -Wait -PassThru -ErrorAction SilentlyContinue
				$ErrorCode = $Process.ExitCode
				Write-Log "Log Share - Mapped T: with NET USE with exit code: $ErrorCode"
				if ($ErrorCode -ne 0)
				{
					# exit
				}
			}
			if ($ErrorMapping -eq $false)
			{
				try
				{
					$TestFile = "T:\" + $tsenv.Value("_SMSTSMachineName") + ".txt"
					"dummy" | Out-File -FilePath "$TestFile" -Force -ErrorAction Stop
					Write-Log "Log Share - Log Share - Permissions OK"
					if (Test-Path "$TestFile") { Remove-Item -Path "$TestFile" -Force }
					$tsenv.Value("OSDLogServer") = $LogServer
					$ErrorPermission = $false
					break
				}
				catch
				{
					Write-Log "Log Share - Permission Error"
					$ErrorPermission = $true
				}
			}
		}
		else { Write-Log "Log Share - Testing connection towards $LogServer - failed" }
	}
	if ($ErrorMapping -eq $true) { $tsenv.Value("OSDWindowsUpgrade") = $false; $tsenv.Value("gotoEnd") = $true; $returnCode = 8022; Write-GlobalLog "Error: Could not connect to Log Share: $LogShare" }
	if ($ErrorPermission -eq $true) { $tsenv.Value("OSDWindowsUpgrade") = $false; $tsenv.Value("gotoEnd") = $true; $returnCode = 8022; Write-GlobalLog "rror: Permissions not sufficient on Log Share: $LogShare" }
	
	try
	{
		Start-Process -FilePath "NET.exe" -ArgumentList "USE T: /DELETE /Y" -NoNewWindow -Wait -PassThru -ErrorAction Stop
		Write-Log "Log Share - Disconnecting Log share"
	}
	catch { Write-Log "Log Share - No Log share to disconnect" }
}

# Check if VM
Write-Log "Virtual machine status"
$VM = $false
$Manufacturer = (Get-WmiObject Win32_ComputerSystem).Manufacturer.TrimEnd()
$ModelFriendlyName = (Get-WmiObject Win32_ComputerSystem).Model.TrimEnd()
if (($Manufacturer -like "*Microsoft Corporation*") -and ($ModelFriendlyName -like "*Virtual Machine*")) { $VM = $true }
if (($Manufacturer -like "*VMware*") -and ($ModelFriendlyName -like "*VMware Virtual*")) { $VM = $true }
if ($Manufacturer -like "*Xen*") { $VM = $true }
If ($ModelFriendlyName -like "*VirtualBox*") { $VM = $true }
if ($VM -eq $true) { Write-Log "Virtual machine status - Device is Virtual, Manufacturer: $Manufacturer, Model: $ModelFriendlyName" }
else { Write-Log "Virtual machine status - Device is physical" }

# Check Driver Status
Write-Log "Driver Status - Checking driver availability for current model"
$ReturnCodeDriver = 0
if ($VM -eq $true)
{
	Write-Log "Driver Status - Model is Virtual, Manufacturer: $Manufacturer - skipping driver check"
}
else
{
	try
	{
		$OSDDistributionPoint = $tsenv.Value("OSDDistributionPoint")
		$DriverDistributed = $tsenv.Value("OSDDriverDistributed")
		$DriverFound = $tsenv.Value("OSDDriverFound")
		$PackageID = $tsenv.Value("OSDDriverPackageID")
		try { $Message = $tsenv.Value("OSDMessage") } catch { }
		Write-Log "Driver Status - Driver Package ID from driver check script: $PackageID"
		if (($DriverDistributed -eq $true) -and ($DriverFound -eq $true)) { Write-Log "Driver Status - Driver for model was found, continue upgrade" }
		if (($DriverDistributed -eq $false) -and ($DriverFound -eq $true)) { Write-Log "Driver Status - Error: Driver for model ($ModelFriendlyName) was found but not distributed to $OSDDistributionPoint, will not continue upgrading"; $tsenv.Value("OSDWindowsUpgrade") = $false; $tsenv.Value("gotoEnd") = $true; $returnCode = 8022; Write-GlobalLog "Error: Driver for model was found but not distributed to $OSDDistributionPoint, will not continue upgrading" }
		if (($PackageID.count -gt 1) -and ($DriverFound -eq $false) -and ($Message.length -gt 0)) { Write-Log "Driver - Warning: Driver package was found with duplicate ID:s ($PackageID) for this model ($ModelFriendlyName) - please make sure only 1 driverpackage exist per model and target OS" }
		elseif ($DriverFound -eq $false) { Write-Log "Driver Status - Error: Driver for model ($ModelFriendlyName) was NOT found, will not continue upgrading"; $tsenv.Value("OSDWindowsUpgrade") = $false; $tsenv.Value("gotoEnd") = $true; $returnCode = 8020; Write-GlobalLog "Error: Driver for model ($ModelFriendlyName) was NOT found, will not continue upgrading" }
	}
	catch { Write-Log "Driver Status - Error checking availability on drivers, will not continue upgrading"; $tsenv.Value("OSDWindowsUpgrade") = $false; $tsenv.Value("gotoEnd") = $true; $returnCode = 8022; Write-GlobalLog "Error: Error checking availability on drivers, will not continue upgrading" }
	# Check that driver was actually downloaded
	if (Test-Path "$env:SystemDrive\Drivers")
	{
		$Size = (Get-ChildItem "$env:SystemDrive\Drivers" -Recurse | measure Length -s).sum / 1kb
		if (($Size -lt 5) -and (!(Test-Path "$env:SystemDrive\Drivers\DriverOK.txt")))
		{
			Write-Log "Driver Status - Error: Size of Drivers folder is less than 5kb and DriverOK.txt not found - driver not propery downloaded"
			$tsenv.Value("OSDWindowsUpgrade") = $false
			$ReturnCodeDriver = 8022
			# "$env:COMPUTERNAME Error: Size of Drivers folder is less than 50MB - driver not propery downloaded" | Out-File -FilePath "$LogFileGlobal" -Append
			Write-GlobalLog "Error: Size of Drivers folder is less than 50MB - driver not propery downloaded"
		}
		else { Write-Log "Driver Status - Size of Drivers folder is greater than 50MB - driver probably downloaded correctly" }
	}
	else { Write-Log "Driver Status - Error: Drivers folder could not be found"; $tsenv.Value("OSDWindowsUpgrade") = $false; $tsenv.Value("gotoEnd") = $true; $ReturnCodeDriver = 8022; Write-GlobalLog "Error: Drivers folder could not be found" }
}
if ($tsenv.Value("OSDRequireDrivers") -eq $false)
{
	Write-Log "Drivers not required for upgrade per TS variable OSDRequireDrivers"
	if ($returnCode -eq 0)
	{
		Write-Log "No error messages other than driver abscence found - will continue upgrade"
	}
	else { Write-Log "Other errors not related to driver abscence found, will stop installation" }
}
else
{
	Write-Log "Drivers required for upgrade per TS variable OSDRequireDrivers, setting return code: $ReturnCodeDriver"
	$returnCode = $ReturnCodeDriver
}

# Check if logged on user
$UpgradeWhenNoUserLoggedOn = $tsenv.Value("UpgradeWhenNoUserLoggedOn")
Write-Log "Logged on user"
Write-Log "Logged on user - Check if logged on user"
$LoggedOnUser, $LoggedOnRDPUser, $username, $SessionID = Get-LoggedOnUser
Write-Log "Logged on user - Variable LoggedOnUser: $LoggedOnUser"
Write-Log "Logged on user - Variable LoggedOnRDPUser: $LoggedOnRDPUser"

$tsenv.Value("ForceUpgrade") = $false
if ($UpgradeWhenNoUserLoggedOn -eq $true)
{
	Write-Log "Logged on user - TS variable UpgradeWhenNoUserLoggedOn is set to $UpgradeWhenNoUserLoggedOn - will perform upgrade if no user is logged on"
	if (($LoggedOnRDPUser -eq $false) -and ($LoggedOnUser -eq $false)) { $tsenv.Value("ForceUpgrade") = $true; Write-Log "Logged on user - User is NOT logged on and force upgrade is true" }
}
else
{
	Write-Log "Logged on user - TS variable UpgradeWhenNoUserLoggedOn is set to $UpgradeWhenNoUserLoggedOn - will NOT perform upgrade if no user is logged on"
	if (($LoggedOnRDPUser -eq $false) -and ($LoggedOnUser -eq $false)) { $returnCode = 8022; Write-Log "Logged on user - Warning No user logged on, setting returncode 8022 to stop upgrade" }
}

# Check OS SKU
$WMIResult = get-wmiobject -class "Win32_OperatingSystem" -namespace "root\CIMV2"
foreach ($objItem in $WMIResult)
{
	$MUILanguageCount = $objItem.MUILanguages.count
	$OSArchitecture = $objItem.OSArchitecture
	If ($OSArchitecture -match "32") { $OSArchitecture = "32-Bit" }
	If ($OSArchitecture -match "64") { $OSArchitecture = "64-Bit" }
	$OSVersion = $objItem.Version
	$OperatingSystemSKU = $objItem.OperatingSystemSKU
	Write-Log "OSVersion detected: $OSVersion"
	If ($RunningInTs) { $tsenv.Value("OSVersion") = $OSVersion }
	Write-Log "OSArchitecture detected: $OSArchitecture"
	If ($RunningInTs) { $tsenv.Value("OSArchitecture") = $OSArchitecture }
	$OSSKU = switch ($OperatingSystemSKU)
	{
		1 { "ULTIMATE" }
		4 { "ENTERPRISE" }
		5 { "BUSINESS" }
		7 { "STANDARD_SERVER" }
		10 { "ENTERPRISE_SERVER" }
		27 { "ENTERPRISE_N" }
		28 { "ULTIMATE_N" }
		48 { "PROFESSIONAL" }
		125 { "ENTERPRISE_LTSB" }
		default { "UNKNOWN" }
	}
	Write-Log "OSSKU $OperatingSystemSKU detected: $OSSKU"
	If ($RunningInTs) { $tsenv.Value("OSSKU") = $OSSKU }
	
	ForEach ($Mui in $objItem.MUILanguages)
	{
		Write-Log "MUILanguage: $Mui"
		If ($RunningInTs) { $tsenv.Value($Mui) = $True }
	}
	$LCID = $objItem.OSLanguage
	Write-Log "Current LCID detected: $LCID"
}

# Check if current language is included in Upgrade Image
$CurrentOSLanguage = (Get-UICulture).Name
Write-Log "Detected current OS Language: $CurrentOSLanguage"

# Get Language and index information from upgrade image
$ComplianceOK = $false
If ($RunningInTs) { $tsenv.Value("CurrentOSLanguage") = $CurrentOSLanguage }
try
{
	$OSDOSImagePath = $null
	if (Test-Path "$env:SystemDrive\OSUpgradeImage")
	{
		Write-Log "$env:SystemDrive\OSUpgradeImage found - check if ISO file exist"
		$ISO = (Get-ChildItem -Path "$env:SystemDrive\OSUpgradeImage" -Filter "*.iso" -Recurse -ErrorAction SilentlyContinue).FullName
		if ($null -ne $ISO) { $OSDOSImagePath = $tsenv.Value("OSDOSImagePath"); Write-Log "ISO found in $OSDOSImagePath" }
		else { Write-Log "No ISO image found in $env:SystemDrive\OSUpgradeImage" }
	}
	if ($OSDOSImagePath -eq $null)
	{
		$OSDOSImagePathTemp = $tsenv.Value("OSDOSImagePath01")
		Write-Log "Try find ISO using variable OSDOSImagePath: $OSDOSImagePathTemp"
		$ISO = (Get-ChildItem -Path "$OSDOSImagePathTemp" -Filter "*.iso" -Recurse -ErrorAction SilentlyContinue).FullName
		if ($null -ne $ISO) { $OSDOSImagePath = $tsenv.Value("OSDOSImagePath01"); Write-Log "ISO found in $OSDOSImagePath" }
		else { Write-Log "No ISO image found in $OSDOSImagePath" }
	}
	
	if ($ISO -ne $null)
	{
		Write-Log "Dismounting ISO if mounted"
		Dismount-ISO $ISO
		Write-Log "Mounting ISO: $ISO"
		$ISOMounted = $false
		$DriveLetter, $MountResult = Mount-ISO $ISO
		if (($DriveLetter -ne $null) -and ($MountResult -eq $true))
		{
			Write-Log "ISO Mounted with driver letter: $DriveLetter"
			if (Test-Path "$DriveLetter\Sources\install.wim")
			{
				$ISOMounted = $true
				Write-Log "Getting OS Information from $DriveLetter\Sources\install.wim"
				$UpgradeImageInfo = Get-WindowsImage -ImagePath "$DriveLetter\Sources\install.wim"
			}
			else { Write-Log "Unable to find $DriveLetter\Sources\install.wim" }
		}
		else
		{
			Write-Log "Error: Failed to mount ISO: $ISO - will try extract ISO"
			
			$ParentDirectory = (Get-Item $PSScriptRoot).parent.parent.FullName
			Write-Log "Parent directory of package: $ParentDirectory"
			
			# Copy 7zip to local disk
			try
			{
				Copy-Item -Path "$ParentDirectory\Tools\7zip\7z.exe" -Destination "$env:windir" -Force -ErrorAction Stop
				Write-Log "Copy 7z.exe to local disk"
				Copy-Item -Path "$ParentDirectory\Tools\7zip\7z.dll" -Destination "$env:windir" -Force -ErrorAction Stop
				Write-Log "Copy 7z.dll to local disk"
			}
			catch
			{ Write-Log "Error: Failed to copy 7z.exe/7z.dll to local disk" }
			
			if (Test-Path "$env:SystemDrive\ExtractedISO") { Remove-Item -Path "$env:SystemDrive\ExtractedISO" -Force -Recurse }
			New-Item -Path "$env:SystemDrive\ExtractedISO" -ItemType dir -Force
			
			try
			{
				$ISO = (Get-ChildItem -Path "$env:SystemDrive\OSUpgradeImage\*.iso" -Recurse).FullName
				Write-Log "$ISO found - continue extraction"
			}
			catch { Write-Log "Error: ISO not found" }
			
			try
			{
				$DriveLetter = "$env:SystemDrive\ExtractedISO"; $parameter = @('x', '-y', "-o$DriveLetter", "$ISO"); $7ZipLog = "$env:windir\Logs\Software\ISOExtraction.log"; Write-Log "Driveletter is now: $DriveLetter"
				Write-Log "Running extraction with 7Zip using command line: C:\Windows\7z.exe $parameter > `"$7ZipLog`""
				& "C:\Windows\7z.exe" $parameter > "$7ZipLog" | Out-Null
				if (Test-Path -Path "$DriveLetter\Sources\install.wim") { $UpgradeImageInfo = Get-WindowsImage -ImagePath "$DriveLetter\Sources\install.wim"; $ISOMounted = $true; Write-Log "Installation Image found in extracted ISO"; $tsenv.Value("OSDReboot") = $false }
				else
				{
					Write-Log "Error: $DriveLetter\Sources\install.wim was not found"
					$tsenv.Value("OSDReboot") = $true
				}
			}
			catch { Write-Log "Error: Failed to extract ISO to $env:SystemDrive\ExtractedISO"; $tsenv.Value("OSDReboot") = $true }
		}
		
		$OSLanguageIncludedInImage = $false
		if ($ISOMounted -eq $true)
		{
			foreach ($item in $UpgradeImageInfo)
			{
				$Language = (Get-WindowsImage -ImagePath "$DriveLetter\Sources\install.wim" -Index $item.ImageIndex).Languages
				$Edition = (Get-WindowsImage -ImagePath "$DriveLetter\Sources\install.wim" -Index $item.ImageIndex).EditionID
				Write-Log "Checking Image with Index: $($item.ImageIndex), Language: $Language, Edition: $Edition"
				if (($Language -like "*$CurrentOSLanguage*") -and ($Edition -like "*$OSSKU*"))
				{
					$OSLanguageIncludedInImage = $true
					$OSImageIndex = $item.ImageIndex
					$tsenv.Value("OSImageIndex") = $OSImageIndex
					$tsenv.Value("OSImageName") = $item.ImageName
					break
				}
			}
			Dismount-ISO -Image $ISO
		}
	}
	else { Write-Log "Error: ISO file for upgrade not found"; $returnCode = 8022 }
}
catch { Write-Log "Error: Failed to find upgrade ISO file"; $returnCode = 8022 }

if ($ISO -ne $null)
{
	Write-Log "ISO is mounted - trying to dismount"
	try
	{
		Dismount-ISO -Image $ISO
		Write-Log "ISO: $ISO dismounted"
	}
	catch { Write-Log "Error: Failed to dismount $ISO" }
}
else { Write-Log "Nothing to dismount" }

if ($ISO -ne $null)
{
	if ($OSLanguageIncludedInImage -eq $true) { Write-Log "OS image matching current language found with index: $OSImageIndex" }
	else { Write-Log "Error: Language matching current OS NOT found in image"; $returnCode = 8022; $tsenv.Value("OSDWindowsUpgrade") = $false; Write-GlobalLog "Error: Language matching current OS NOT found in image" }
}

# Check Diskspace
$disk = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='C:'" | Select-Object Size, FreeSpace
$disk = [Math]::Round($Disk.Freespace / 1GB)
Write-Log "Disk Space is: $disk GB"
if (($disk -lt 40) -and ($disk -gt 20)) { Write-Log "Warning: Disk is low on C drive, space left: $disk"; Write-GlobalLog "Warning: Disk is low on C drive, space left: $disk GB" }
if ($disk -lt 20) { Write-Log "Error: Disk is low on C drive, space left: $disk - will not continue upgrade"; $returnCode = 8022; $tsenv.Value("OSDWindowsUpgrade") = $false; Write-GlobalLog "Error: Disk is low on C drive, space left: $disk GB - will not continue upgrade" }

# returnCode 0 = continue with upgrade 
if ($returnCode -eq 0)
{
	if ($UserLoggedOn -eq $true)
	{
		$Counter = (Get-ItemProperty -Path hklm:software\Windows10Upgrade -Name "Postpone" -ErrorAction Ignore).PostPone
		if ($Counter -lt '1' -and $Counter -ne $null)
		{
			$returnCode = '0'
			Write-Log "Amount of postpones left: $Counter"
			$postponeDisabled = $true
			Write-Log "No postpones left, installation will start"
			Write-Log "Continuing with returnCode: $returnCode"
		}
		
		else
		{
			$returnCode = '0'
			Write-Log "Amount of postpones left: $Counter"
			$postponeDisabled = $false
			Write-Log "Still more postpones left"
			Write-Log "Continuing with returnCode: $returnCode"
			Write-Log "PostponeDisabled = $postponeDisabled"
		}
	}
	
	if ($UserLoggedOn -eq $false)
	{
		$returnCode = $null
	}
}
else { Write-Log "Error from previous checks set to $returnCode, will not check postpones" }

$ParentDirectory = (Get-Item $PSScriptRoot).parent.parent.FullName
Write-Log "Parent directory of package: $ParentDirectory"

# Copy Tool to local disk
try
{
	Copy-Item -Path "$PSScriptRoot\*.exe" -Destination "$env:windir" -Force -ErrorAction Stop
	Write-Log "Copy InPlaceUpgrade-ReadyTool.exe to local disk"
}
catch { Write-Log "Error: Failed to copy OSDeployment-CustomMessage.exe to local disk" }

# Copy ServiceUI to local disk
try
{
	Copy-Item -Path "$ParentDirectory\Tools\ServiceUI\ServiceUI.exe" -Destination "$env:windir" -Force -ErrorAction Stop
	Write-Log "Copy ServiceUI.exe to local disk"
}
catch
{ Write-Log "Error: Failed to copy ServiceUI.exe to local disk" }

# Remove previous Drivers and Language folders
if ((Test-Path "$env:SystemDrive\DRIVERS") -and (!(Test-Path -Path "$env:SystemDrive\Drivers\DriverOK.txt")))
{
	Remove-Item -Path "$env:SystemDrive\DRIVERS" -Recurse -Force
	Write-Log "Removing Drivers folder, not finding DriverOK.txt in folder: $env:SystemDrive\Drivers"
}
if (Test-Path "$env:SystemDrive\LanguagePacks")
{
	Remove-Item -Path "$env:SystemDrive\LanguagePacks" -Recurse -Force
	Write-Log "Removing LanguagePacks folder: $env:SystemDrive\LanguagePacks"
}

# Logging off disconnected users
Write-Log "Logging off disconnected users"
quser | Select-String "Disc" | ForEach { logoff ($_.tostring() -split ' +')[2] }

# Cleanup previous attempts
if (Test-Path -Path 'c:\$WINDOWS.~BT')
{
	$Counter = 2
	While ($Counter -ne 0)
	{
		if (Test-Path -Path 'C:\$Windows.~BT')
		{
			Write-Log 'C:\$Windows.~BT exist - will delete. Start taking ownership'
			# $folder = 'C:\$Windows.~BT'
			# takeown /F $folder /R /A /D Y
			
			if (Test-Path "$ParentDirectory\Tools\SetACL\64 bit\SetACL.exe")
			{
				$Process = Start-Process -FilePath "$ParentDirectory\Tools\SetACL\64 bit\SetACL.exe" -ArgumentList '-on C:\$Windows.~BT -ot file -rec cont_obj -actn setowner -ownr "n:S-1-5-32-544" -ignoreerr -silent' -Wait -PassThru -ErrorAction SilentlyContinue
				$ErrorCode = $Process.ExitCode
				$Text = 'Finished Taking ownership of C:\$Windows.~BT using SetACL with exit code: ' + "$ErrorCode" 
				Write-Log "$Text"
			}
			else { Write-Log "$ParentDirectory\Tools\SetACL\64 bit\SetACL.exe was not found" }
			
			# Give user permissions to folder (NTFS)
			Write-Log 'Ownership taken on C:\$Windows.~BT. Setting permissions'
			$FullPath = 'C:\$Windows.~BT'
			icacls ("$FullPath") /Grant "*S-1-5-32-545:(OI)(CI)M" /Grant "*S-1-5-32-544:(OI)(CI)F" /T /C /Q
			icacls ("$FullPath") /Grant "*S-1-5-32-545:M"  /Grant "*S-1-5-32-544:F" /T /C /Q
			Write-Log 'Permissions set on C:\$Windows.~BT. Now start deleting directory'
			
			$Path = 'C:\$Windows.~BT'
			try { cmd /c rmdir /S /Q $Path } catch { }
			Write-Log 'Directory C:\$Windows.~BT deleted.'
			
			if (Test-Path -Path 'C:\$Windows.~BT')
			{
				Write-Log "Start closing open processes - was unable to delete all files"
				KillProcessesWithHandles -path 'C:\$Windows.~BT'
				Write-Log 'Processes closed in C:\$Windows.~BT.'
			}
			$Counter = $Counter - 1
		}
		else
		{
			$Counter = 0
		}
	}
}
else { Write-Log 'C:\$Windows.~BT does not exist - no directory to delete' }

if (Test-Path -Path 'C:\$Windows.~WS')
{
	Write-Log 'C:\$Windows.~WS exist - will delete. Start taking ownership'
	
	if (Test-Path "$ParentDirectory\Tools\SetACL\64 bit\SetACL.exe")
	{
		$Process = Start-Process -FilePath "$ParentDirectory\Tools\SetACL\64 bit\SetACL.exe" -ArgumentList '-on C:\$Windows.~WS -ot file -rec cont_obj -actn setowner -ownr "n:S-1-5-32-544" -ignoreerr -silent' -Wait -PassThru -ErrorAction SilentlyContinue
		$ErrorCode = $Process.ExitCode
		$Text = 'Finished Taking ownership of $Windows.~WS using SetACL with exit code: ' + "$ErrorCode"
		Write-Log "$Text"
	}
	else { Write-Log "$ParentDirectory\Tools\SetACL\64 bit\SetACL.exe was not found" }
	
	# Give user permissions to folder (NTFS)
	Write-Log 'Ownership taken on $Windows.~WS. Setting permissions'
	$FullPath = 'C:\$Windows.~WS'
	icacls ("$FullPath") /Grant "*S-1-5-32-545:(OI)(CI)M" /Grant "*S-1-5-32-544:(OI)(CI)F" /T /C /Q
	icacls ("$FullPath") /Grant "*S-1-5-32-545:M"  /Grant "*S-1-5-32-544:F" /T /C /Q
	Write-Log 'Permissions set on C:\$Windows.~WS. Now start deleting directory'
	
	$Path = 'C:\$Windows.~WS'
	try { cmd /c rmdir /S /Q $Path }
	catch { }
	Write-Log 'Directory C:\$Windows.~BT deleted.'
}
else { Write-Log 'C:\$Windows.~WS does not exist - no directory to delete' }

if (Test-Path -Path 'C:\Windows.old')
{
	try
	{
		$folder = 'C:\Windows.old'
		Write-Log "Removing $folder"
		Remove-Item -Path 'C:\Windows.old' -Recurse -Force -ErrorAction Stop
		Write-Log "Folder $folder removed successfully"
	}
	catch { Write-Log "Error: failed to remove folder $folder" }
}

# Check if Upgrade Window - then wait
if ($($tsenv.Value("ForceUpgrade")) -eq $true)
{
	Write-Log "Checking Upgrade time window - force upgrade is true and no user logged on"
	if (($($tsenv.Value("UpgradeWindow")) -eq $null) -or ($($tsenv.Value("UpgradeWindow").Length -lt 1))) { Write-Log "No time window specified - assuming any time is acceptable" }
	else
	{
		try { $UpgradeWindow = $tsenv.Value("UpgradeWindow"); Write-Log "Setting Upgrade window variable" }	catch { Write-Log "Error: Unable to set Upgrade window variable" }
		$StartTime = ($UpgradeWindow.Substring(0, $UpgradeWindow.IndexOf("-"))).Trim()
		$EndTime = ($UpgradeWindow.Substring($UpgradeWindow.IndexOf("-") + 1)).Trim()
		Write-Log "Time Window for upgrade specified, Start Time: $StartTime , End Time: $EndTime"
		$CurrentTime = (Get-Date).ToString("HH:mm")
		
		if ($StartTime -lt $EndTime)
		{
			if (($CurrentTime -lt $EndTime) -and ($CurrentTime -gt $StartTime))	{ Write-Log "Time is within Upgrade Window - will start upgrade" }
			else
			{
				Write-Log "Time is not within Upgrade Window - waiting..."
				while (!(($CurrentTime -lt $EndTime) -and ($CurrentTime -gt $StartTime)))
				{
					Start-Sleep -Seconds 60
					$CurrentTime = (Get-Date).ToString("HH:mm")
				}
			}
		}
		if ($StartTime -gt $EndTime)
		{
			if ((($CurrentTime -gt $StartTime) -and ($StartTime -lt "23:59")) -or (($StartTime -gt "00:00") -and ($StartTime -lt $EndTime))) { Write-Log "Time is within Upgrade Window - will start upgrade" }
			else
			{
				Write-Log "Time is not within Upgrade Window - waiting..."
				while (!((($CurrentTime -gt $StartTime) -and ($StartTime -lt "23:59")) -or (($StartTime -gt "00:00") -and ($StartTime -lt $EndTime))))
				{
					Start-Sleep -Seconds 60
					$CurrentTime = (Get-Date).ToString("HH:mm")
				}
			}
		}
	}
	Write-Log "Check if user has logged on during waiting for Service Window"
	$LoggedOnUser, $LoggedOnRDPUser, $username, $SessionID = Get-LoggedOnUser
	if (($LoggedOnUser -eq $true) -or ($LoggedOnRDPUser -eq $true)) { Write-Log "User is now logged on - will not force upgrade"; $tsenv.Value("ForceUpgrade") = $false }
	else { Write-Log "No user logged on - continue upgrade" }
}

# Declare variables
$OSDWindowsUpgrade = $tsenv.Value("OSDWindowsUpgrade")
Write-Log "*** Declaring variables ***"
Write-Log "Continuing with returnCode: $returnCode"
Write-Log "PostponeDisabled = $postponeDisabled"
Write-Log "OSDWindowsUpgrade = $OSDWindowsUpgrade"
$tsenv.Value("returncode") = $returncode
$tsenv.Value("ReturnCodeDriver") = $ReturnCodeDriver
$tsenv.Value("postponeDisabled") = $postponeDisabled
Exit $returncode