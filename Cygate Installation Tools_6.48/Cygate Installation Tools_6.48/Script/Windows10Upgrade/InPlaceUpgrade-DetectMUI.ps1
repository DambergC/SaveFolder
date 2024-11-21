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
			if ($DriveLetter -like "*:*") { $DriveLetterFixed = $DriveLetter } else { $DriveLetterFixed = $DriveLetter + ":" }
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
Write-Log "Detecting MUI"

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

Write-Log "MUILanguage Count: $MUILanguageCount"

If ($MUILanguageCount -gt 1)
{
	Write-Log "MUIdetected: True"
	If ($RunningInTs)
	{
		$tsenv.Value("MUIdetected") = $True
	}
}

# Detect Current OS Language
$CurrentOSLanguage = (Get-UICulture).Name
Write-Log "Detected current OS Language: $CurrentOSLanguage"

# Check if detected current os differs from registry (HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Nls\Language, Value InstallLanguage)
try
{
	$LanguageFromRegistry = (Get-Itemproperty hklm:SYSTEM\CurrentControlSet\Control\Nls\Language).InstallLanguage
	Write-Log "InstallLanguage code from registry: $LanguageFromRegistry"
	$RegistryCode = Get-LanguageFromCode $LanguageFromRegistry
	Write-Log "InstallLanguage from registry: $RegistryCode"
	if (($LanguageFromRegistry -ne $null) -and ($CurrentOSLanguage -ne $RegistryCode))
	{
		Write-Log "Detected default language from (Get-UICulture).Name ($CurrentOSLanguage) does not match registry ($RegistryCode), registry value will be used"
		$CurrentOSLanguage = $RegistryCode
	}
	elseif ($LanguageFromRegistry -eq $null) { Write-Log "Could not find language from registry" }
	else { Write-Log "Detected current OS is same as registry - no need for override" }
}
catch { Write-Log "Error: failed to get default language from registry" }

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
		if (($null -ne $ISO) -and ($ISO -like "*.iso")) { $OSDOSImagePath = "$env:SystemDrive\OSUpgradeImage"; Write-Log "ISO found in $env:SystemDrive\OSUpgradeImage" }
		else { Write-Log "No ISO image found in $env:SystemDrive\OSUpgradeImage"; $OSDOSImagePath = $null }
	}
	if ($OSDOSImagePath -eq $null)
	{
		$OSDOSImagePathTemp = $tsenv.Value("OSDOSImagePath01")
		Write-Log "Try find ISO using variable OSDOSImagePath: $OSDOSImagePathTemp"
		$ISO = (Get-ChildItem -Path "$OSDOSImagePathTemp" -Filter "*.iso" -Recurse -ErrorAction SilentlyContinue).FullName
		if (($null -ne $ISO) -and ($ISO -like "*.iso")) { $OSDOSImagePath = $tsenv.Value("OSDOSImagePath01"); Write-Log "ISO found in $OSDOSImagePath" }
		else { Write-Log "No ISO image found in $OSDOSImagePath" }
	}
	
	try
	{
		$ISO = (Get-ChildItem -Path "$OSDOSImagePath" -Filter "*.iso" -Recurse -ErrorAction Stop).FullName
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
				$Command = "$env:windir\7z.exe"
				$DriveLetter = "$env:SystemDrive\ExtractedISO"; $Argument = @('x', '-y', "-o$DriveLetter", "$ISO"); $Log = "$env:windir\Logs\Software\ISOExtraction.log"; Write-Log "Driveletter is now: $DriveLetter"
				Write-Log "Running extraction with 7Zip using command line: $Command $Argument > `"$Log`""
				& "$Command" $Argument > "$Log" | Out-Null
				if (Test-Path -Path "$DriveLetter\Sources\install.wim") { $UpgradeImageInfo = Get-WindowsImage -ImagePath "$DriveLetter\Sources\install.wim"; $ISOMounted = $true; Write-Log "Installation Image found in extracted ISO" }
				else
				{
					Write-Log "Error: $DriveLetter\Sources\install.wim was not found"
				}
			}
			catch { Write-Log "Error: Failed to extract ISO to $env:SystemDrive\ExtractedISO" }
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


if ($OSLanguageIncludedInImage -eq $true) { Write-Log "OS image matching current language found with index: $OSImageIndex" }
else { Write-Log "Error: Language matching current OS NOT found in image"; $returnCode = 8022 }


# Export Registry values
if (!(Test-Path -Path "$env:windir\MUIExport.txt"))
{
	Write-Log "MUIExport.txt not found - upgrade not previously run, exporting language from registry"
	try
	{
		$RegInstallValue = (Get-Itemproperty hklm:SYSTEM\CurrentControlSet\Control\Nls\Language).InstallLanguage
		$RegDefaultValue = (Get-Itemproperty hklm:SYSTEM\CurrentControlSet\Control\Nls\Language).Default
		Write-Log "Values from Registry, InstallValue: $RegInstallValue  ,Default: $RegDefaultValue"
		if ($RegInstallValue -ne $null) { $tsenv.Value("RegInstallValue") = $RegInstallValue }
		if ($RegInstallValue -ne $null) { $tsenv.Value("RegDefaultValue") = $RegDefaultValue }
	}
	catch
	{
		Write-Log "Error: Could not read registry value"
	}
}
else
{
	Write-Log "MUIExport.txt found - upgrade previously run, getting language from file"
	# Check if MUIExport text file exist - reuse (could be that upgrade was broken before exported values were reapplied at the end of upgrade process)
	$UseMUIFile = $false
	if (Test-Path "$env:windir\MUIExport.txt") { $MUIVariableFile = "$env:windir\MUIExport.txt"; $UseMUIFile = $true; Write-Log "MUI variable found in $env:windir" }
	if (Test-Path "$env:SystemDrive\Windows.old\MUIExport.txt") { $MUIVariableFile = "$env:SystemDrive\Windows.old\MUIExport.txt"; $UseMUIFile = $true; Write-Log "MUI variable found in $env:SystemDrive\Windows.old" }
	
	if ($UseMUIFile -eq $true)
	{
		Write-Log "MUIExport.txt found, reading values"
		try
		{
			foreach ($line in [System.IO.File]::ReadLines($MUIVariableFile))
			{
				if ($line -like "OSDMultilingual=*")
				{
					$index = $line.IndexOf("=") + 1
					$OSDMultilingual = $line.Substring($index, $line.Length - $index)
					$OSDMultilingual = $OSDMultilingual.Trim()
					Write-Log "MUIExport.txt - OSDMultilingual: $OSDMultilingual"
				}
				if ($line -like "OSDDefaultLanguage=*")
				{
					$index = $line.IndexOf("=") + 1
					$OSDDefaultLanguage = $line.Substring($index, $line.Length - $index)
					$OSDDefaultLanguage = $OSDDefaultLanguage.Trim()
					Write-Log "MUIExport.txt - OSDDefaultLanguage: $OSDDefaultLanguage"
				}
				if ($line -like "OSDMUILanguage=*")
				{
					$index = $line.IndexOf("=") + 1
					$OSDMUILanguage = $line.Substring($index, $line.Length - $index)
					$OSDMUILanguage = $OSDMUILanguage.Trim()
					Write-Log "MUIExport.txt - OSDMUILanguage: $OSDMUILanguage"
				}
			}
			$tsenv.Value("OSDDefaultLanguage") = $DefaultLanguage
			if ($OSMultiLingual -like "*True*") { $tsenv.Value("OSDMultilingual") = $true }
			else { $tsenv.Value("OSDMultilingual") = $false }
		}
		catch { Write-Log "Error: MUIExport.txt found, could not read values" }
	}
}

#	# Set OS upgrade Index for image 1:Education, 2:Education N, 3:EnterPrise, 4:Enterprise N, 5:Pro, 6:Pro N, 7:Pro Education
#	if ($tsenv.Value("OSSKU") -eq "ENTERPRISE") { $tsenv.Value("OSIndex") = 3 }
#	if ($tsenv.Value("OSSKU") -eq "PROFESSIONAL") { $tsenv.Value("OSIndex") = 5 }
#	$OSIndex = $tsenv.Value("OSIndex")
#   Write-Log "OS Index: $OSIndex"

# Just in case OSDRegionalSettings.ps1 has been used for bare metal install check for Get-WinUILanguageOverride
Try
{
	$OSDDefaultUILanguage = Get-WinUILanguageOverride
	If ($OSDDefaultUILanguage -eq $Null)
	{
		Write-Log "No UI Language Override detected"
	}
	Else
	{
		Write-Log "WinUILanguageOverride detected variable OSDDefaultUILanguage set to value: $OSDDefaultUILanguage"
		If ($RunningInTs) { $tsenv.Value("OSDDefaultUILanguage") = $OSDDefaultUILanguage }
	}
}
catch
{
	Write-Log "No UI Language Override detected"
}

#	# Make sure that InstallLanguage been set to 0409 - en-US (when using en-US as base upgrade image)
#	$tsenv.Value("OSDMultilingual") = $true
#	if ($OSDDefaultLanguage -eq '0409')
#	{
#		$tsenv.Value("OSDMultilingual") = $False
#		Write-Log "Language is not Multilingual"
#	}
#	else
#	{
#		$tsenv.Value("OSDMultilingual") = $True
#		Write-Log "Language is Multilingual exporting DefaultLanguage: $OSDDefaultLanguage"
#		$tsenv.Value("OSDDefaultLanguage") = $OSDDefaultLanguage
#		try
#		{
#			New-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Nls\Language" -Name "InstallLanguage" -Value "0409" -PropertyType "String" -Force -ErrorAction Stop
#			Write-Log "Add InstallLanguage to registry: 0409"
#		}
#		catch { Write-Log "Error: Failed to add InstallLanguage to registry" }
#	}
#