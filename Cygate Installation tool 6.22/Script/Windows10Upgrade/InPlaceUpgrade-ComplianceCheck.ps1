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

# Prepare for Logging
$LogFileGlobal = "$env:TEMP\ComplianceCheckErrors.log"
if (Test-Path "$LogFileGlobal") { Remove-Item -Path "$LogFileGlobal" -Force }
Write-Log " "
Write-Log "Start Upgrade - running compliance check"

# Setting variables
$Username = $tsenv.Value("OSDLogUser")
$Password = $tsenv.Value("OSDLogUserPassword")
try
{
	if ($tsenv.Value("OSDWindowsUpgrade") -ne $false) { $tsenv.Value("OSDWindowsUpgrade") = $true }
} catch {}
$returnCode = 0

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

# Make sure Software directory exists
$SoftwareLogFolderLocation = 'C:\Windows\Logs\Software'
$SoftwareLogFolderExist = Test-Path -Path $SoftwareLogFolderLocation

If (!$SoftwareLogFolderExist)
{
   New-Item -Path $SoftwareLogFolderLocation -ItemType dir -Force
}

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
}

# Check log server and share
# Filter Log servers if array (eg. OSDLogServer = Server1.somedomain.com,Server2.somedomain.com and test if online)
$LogServers = $tsenv.Value("OSDLogServer")
Write-Log "Log Share - Start Testing Log Server(s) configured: $LogServers"
$LogServers = ($LogServers -split ",").Trim()
$tsenv.Value("OSDlogServerOperational") = $false

# Test of Log Server(s) for connection - LogServers could be with primary and secondary
foreach ($LogServer in $LogServers)
{
	try
	{
		$Process = Start-Process -FilePath "NET.exe" -ArgumentList "USE T: /DELETE /Y" -NoNewWindow -Wait -PassThru -ErrorAction SilentlyContinue
		Write-Log "Log Share - Disconnected mapped drive to log share"
	}
	catch { Write-Log "Log Share - No mapped drive to disconnect" }
	
	$LogShare = "\\" + $LogServer + "\Logs$"
	Write-Log "Log Share - Testing connection to Log Share"
	Write-Log "Log Share - LogServer: $LogServer"
	Write-Log "Log Share - LogServer: $LogShare"
	try
	{
		$net = New-Object -comobject Wscript.Network
		$net.MapNetworkDrive("T:", "$LogShare", 0, "$Username", "$Password")
		Write-Log "Log Share - Mapping Log Share OK"
		$ErrorMapping = $false
	}
	catch [System.Exception]{
		Write-Log "Log Share - Error Connecting to log share $LogShare, exit code: $_"
		$ErrorMapping = $true
	}
	if ($ErrorMapping -eq $false)
	{
		try
		{
			$TestFile = "T:\" + $tsenv.Value("_SMSTSMachineName") + ".txt"
			"dummy" | Out-File -FilePath "$TestFile" -Force -ErrorAction Stop
			Write-Log "Log Share - Permissions OK"
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
if ($ErrorMapping -eq $true) { $tsenv.Value("OSDWindowsUpgrade") = $false; $tsenv.Value("gotoEnd") = $true; $returnCode = 8022; Write-GlobalLog "Error: Could not connect to Log Share: $LogShare" }
if ($ErrorPermission -eq $true) { $tsenv.Value("OSDWindowsUpgrade") = $false; $tsenv.Value("gotoEnd") = $true; $returnCode = 8022; Write-GlobalLog "Error: Permissions not sufficient on Log Share: $LogShare" }

try
{
	Start-Process -FilePath "NET.exe" -ArgumentList "USE T: /DELETE /Y" -NoNewWindow -Wait -PassThru -ErrorAction SilentlyContinue
}
catch { }


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

# Removing old files if exist
if (Test-Path -Path 'c:\$WINDOWS.~BT')
{
	try
	{
		Remove-Item -Path 'c:\$WINDOWS.~BT' -Force -Recurse
		Write-Log 'Removing existing folder c:\$WINDOWS.~BT'
	}
	catch { Write-Log 'Error: Failed to completely remove c:\$WINDOWS.~BT' }
}
if (Test-Path "$env:windir\Logs\Software\ISOExtraction.log") { Remove-Item -Path "$env:windir\Logs\Software\ISOExtraction.log" -Force }

# Get Language and index information from upgrade image
$ComplianceOK = $false
If ($RunningInTs) { $tsenv.Value("CurrentOSLanguage") = $CurrentOSLanguage }
try
{
	try
	{
		$ISO = (Get-ChildItem -Path "$env:SystemDrive\OSUpgradeImage\*.iso" -Recurse).FullName
		Write-Log "ISO found: $ISO"
	}
	catch { Write-Log "Error: Failed to find ISO image" }
	
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
			}
			catch
			{ Write-Log "Error: Failed to copy 7z.exe to local disk" }
			
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
				if (Test-Path -Path "$DriveLetter\Sources\install.wim") { $UpgradeImageInfo = Get-WindowsImage -ImagePath "$DriveLetter\Sources\install.wim"; $ISOMounted = $true; Write-Log "Installation Image found in extracted ISO" }
				else
				{
					Write-Log "Error: $DriveLetter\Sources\install.wim was not found"
					Write-GlobalLog "Error: Failed to mount ISO: $ISO + $DriveLetter\Sources\install.wim was not found in extracted folder"
				}
			}
			catch { Write-Log "Error: Failed to extract ISO to $env:SystemDrive\ExtractedISO"; Write-GlobalLog "Error: Failed to extract ISO to $env:SystemDrive\ExtractedISO" }
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
					
					Write-Log "Running compliance check..."
					try
					{
						if (Test-Path -Path "$env:windir\Logs\Software\CompatCheck") { Remove-Item -Path "$env:windir\Logs\Software\CompatCheck" -Force -Recurse }
						$Process = Start-Process -FilePath "$DriveLetter\Setup.exe" -ArgumentList "/auto upgrade /ImageIndex $OSImageIndex /quiet /compat scanonly /compat ignorewarning /dynamicupdate disable /copylogs `"$env:windir\Logs\Software\CompatCheck`"" -Wait -PassThru -ErrorAction Stop
						$ErrorCode = $Process.ExitCode
						if ($ErrorCode -eq -1047526896) { Write-Log "Compatibility check performed and result is OK)"; $ComplianceOK = $true }
						else { Write-Log "Compatibility check performed with exit code: $ErrorCode" }
					}
					catch { Write-Log "Error: Failed to run compatibility check" }
					break
				}
			}
		}
	}
	else { Write-Log "Error: ISO file for upgrade not found"; $returnCode = 8022; Write-GlobalLog "Error: ISO file for upgrade not found" }
}
catch { Write-Log "Error: Failed to find upgrade ISO file"; $returnCode = 8022; Write-GlobalLog "Error: Failed to find upgrade ISO file" }

if ($ISO -ne $null)
{
	Write-Log "Trying to dismount ISO"
	try
	{
		Dismount-ISO -Image $ISO
		Write-Log "ISO: $ISO dismounted"
	}
	catch { Write-Log "Error: Failed to dismount $ISO" }
}
else { Write-Log "Nothing to dismount" }

if (Test-Path "$env:SystemDrive\ExtractedISO") { Remove-Item -Path "$env:SystemDrive\ExtractedISO" -Force -Recurse; Write-Log "Removing folder $env:SystemDrive\ExtractedISO" }

if ($OSLanguageIncludedInImage -eq $true) { Write-Log "OS image matching current language ($CurrentOSLanguage) found with index: $OSImageIndex" }
if (($ISOMounted -eq $true) -and ($OSLanguageIncludedInImage -eq $false)) { Write-Log "Error: Language matching current OS ($CurrentOSLanguage) NOT found in image"; $returnCode = 8022; $tsenv.Value("OSDWindowsUpgrade") = $false; Write-GlobalLog "Error: Language matching current OS NOT found in image" }

# Check Diskspace
$disk = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='C:'" | Select-Object Size, FreeSpace
$disk = [Math]::Round($Disk.Freespace / 1GB)
Write-Log "Disk Space is: $disk GB"
if (($disk -lt 40) -and ($disk -gt 20)) { Write-Log "Warning: Disk is low on C drive, space left: $disk"; Write-GlobalLog "Warning: Disk is low on C drive, space left: $disk GB" }
if ($disk -lt 20) { Write-Log "Error: Disk is low on C drive, space left: $disk - will not continue upgrade"; $returnCode = 8022; Write-GlobalLog "Error: Disk is low on C drive, space left: $disk GB" }

if ($ComplianceOK -eq $false)
{
	Write-Log "Compliance check resulted in errors - checking logs..."
	
	# Checking setuperr.log
	$LogFile = 'c:\$WINDOWS.~BT\Sources\Panther\setuperr.log'
	Write-Log "Reading $LogFile"
	if (Test-Path "$LogFile")
	{
		try
		{
			$LogContent = Get-Content "$LogFile"
			foreach ($line in $LogContent)
			{
				if ($line -like "*Execute(282): Result =*")
				{
					$Pos = $line.IndexOf("=")
					$Status1 = ($line.SubString($Pos + 1)).Trim()
					$ErrorMessage, $Status = Get-ErrorMessage $Status1
					Write-Log "Status message Execute(282): Result = $Status1, Message converted: $ErrorMessage"
				}
				if ($line -like "*Execute(420): Result =*")
				{
					$Pos = $line.IndexOf("=")
					$Status1 = ($line.SubString($Pos + 1)).Trim()
					$ErrorMessage, $Status = Get-ErrorMessage $Status1
					Write-Log "Status message Execute(420): Result = $Status1, Message converted: $ErrorMessage"
					if ($ErrorMessage -like "*No issues found*")
					{ }
					else { Write-GlobalLog "Error: Status Message for complaince check from setuperr.log: $Status1, Message converted: $ErrorMessage" }
				}
			}
		}
		catch { Write-Log "Error Reading $LogFile" }
	}
	else { Write-Log "Could not find $LogFile" }
	
	
	# Checking ScanResult.xml
	Write-Log "Checking ScanResult.xml - if exist"
	$LogFile = 'c:\$WINDOWS.~BT\Sources\Panther\ScanResult.xml'
	$NewLogFile = "$env:TEMP\ScanResultNew.xml"
	
	if (Test-Path -Path "$LogFile")
	{
		Write-Log "$LogFile exist - reading..."
		
		$xDoc = New-Object System.Xml.XmlDocument
		$xDoc.Load($LogFile)
		$xDoc.Save($NewLogFile) #will save correctly
		[xml]$XmlDocument = Get-Content "$NewLogFile"
		
		$ErrorArray = @()
		$LogContent = Get-Content -Path "$NewLogFile"
		foreach ($line in $LogContent)
		{
			if ($line -like "*<Program Name*")
			{
				try
				{
					$ProgramName = $line.Substring($line.IndexOf("=") + 2)
					$ProgramName = $ProgramName.Substring(0, $ProgramName.IndexOf('Id=') - 2)
					$ErrorArray += $ProgramName
					Write-Log "Blocking application found: $ProgramName"
					Write-GlobalLog "Error: Blocking application found: $ProgramName"
				}
				catch { }
			}
		}
		Remove-Item -Path "$NewLogFile" -Force
	}
}
else { Write-Log "Since compliance check was successul, ScanResult.xml will not be examined" }
