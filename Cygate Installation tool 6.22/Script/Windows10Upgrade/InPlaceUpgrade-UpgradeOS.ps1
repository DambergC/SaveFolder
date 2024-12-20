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
#endregion Main Function

# Prepare for Logging
Write-Log " "
Write-Log "Start Upgrade OS"

$OSDOSImagePath = $tsenv.Value("OSDOSImagePath01")

if (Test-Path "$env:windir\Logs\Software\ISOExtraction.log") { Remove-Item -Path "$env:windir\Logs\Software\ISOExtraction.log" -Force }

if ($OSDOSImagePath -ne $null)
{
	Write-Log "OSDOSImagePath variable is set to: $OSDOSImagePath, check for ISO"
	$ISO = (Get-ChildItem -Path "$OSDOSImagePath" -Filter "*.iso" -Recurse -ErrorAction Stop).FullName
	if ($ISO -ne $null) { Write-Log "ISO file found: $ISO" }
	else
	{
		Write-Log "ISO file not found using OSDOSImagePath variable - trying $env:SystemDrive\OSUpgradeImage"
		$ISO = (Get-ChildItem -Path "$env:SystemDrive\OSUpgradeImage" -Filter "*.iso" -Recurse -ErrorAction Stop).FullName
		if ($ISO -ne $null) { Write-Log "ISO file found: $ISO" }
		else { Write-Log "ISO file not found in $env:SystemDrive\OSUpgradeImage" }
	}
}
else
{
	Write-Log "Find ISO file in $env:SystemDrive\OSUpgradeImage"
	$ISO = (Get-ChildItem -Path "$env:SystemDrive\OSUpgradeImage" -Filter "*.iso" -Recurse -ErrorAction Stop).FullName
	if ($ISO -ne $null) { Write-Log "ISO file found: $ISO" }
	else { Write-Log "ISO file not found in $env:SystemDrive\OSUpgradeImage" }
}

if (Test-Path "$ISO")
{
	try
	{
		if ($ISO -ne $null)
		{
			$ISOMounted = $false
			$DriveLetter, $MountResult = Mount-ISO $ISO
			if (($DriveLetter -ne $null) -and ($MountResult -eq $true))
			{
				Write-Log "ISO file mounted to: $DriveLetter"
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
					if (Test-Path -Path "$DriveLetter\Sources\install.wim") { $UpgradeImageInfo = Get-WindowsImage -ImagePath "$DriveLetter\Sources\install.wim"; $ISOMounted = $true; Write-Log "Installation Image found in extracted ISO"; $tsenv.Value("OSDReboot") = $false }
					else
					{
						Write-Log "Error: $DriveLetter\Sources\install.wim was not found"
						$ReturnCode = 8022
						$tsenv.Value("OSDReboot") = $true
					}
				}
				catch { Write-Log "Error: Failed to extract ISO to $env:SystemDrive\ExtractedISO"; $tsenv.Value("OSDReboot") = $true }
			}
		}
		else { Write-Log "Error: ISO file for upgrade not found"; $ReturnCode = 8022 }
	}
	catch { Write-Log "Error: Failed to find upgrade ISO file"; $ReturnCode = 8022 }
	if ($DriveLetter -ne $null)
	{
		try
		{
			$OSIndex = $tsenv.Value("OSImageIndex")
			$OSImageName = $tsenv.Value("OSImageName")
			Write-Log "OS Name/Edition/Language from variable: $OSImageName"
			
			# Get license type
			Write-Log "Getting License info using slmgr.vbs to $env:TEMP\License.txt"
			try { $Process = Start-Process -FilePath "cscript.exe" -ArgumentList "$env:windir\System32\slmgr.vbs /dlv" -Wait -WindowStyle Hidden -ErrorAction Stop -RedirectStandardOutput "$env:TEMP\License.txt" }
			catch { Write-Log "Error: failed to extract license info using slmgr.vbs" }
			Write-Log "License text created with exit code: $ErrorCode"
			
			$KMSClient = $false
			if (Test-Path "$env:TEMP\License.txt") { $LicenseInfo = Get-Content "$env:TEMP\License.txt" } else { Write-Log "Error: $env:TEMP\License.txt not found" }
			if (($LicenseInfo -like "*2YT43*") -or ($LicenseInfo -like "*T83GX*") -or ($LicenseInfo -like "*6Q84J*") -or ($LicenseInfo -like "*VCFB2*")) { $KMSClient = $true; Write-Log "KMS client key found in license information - assuming KMS client" }
			else { Write-Log "No KMS client key found in license information - assuming MAK client" }
			
			if ($KMSClient -eq $true)
			{
				if ($OSImageName -like "*Enterprise*") { $ProductKey = "NPPR9-FWDCX-D2C8J-H872K-2YT43"; Write-Log "Adding Product Key Enterprise: $ProductKey" }
				elseif ($OSImageName -like "*Pro*") { $ProductKey = "W269N-WFGWX-YVC9B-4J6C9-T83GX"; Write-Log "Adding Product Key Pro: $ProductKey" }
				elseif ($OSImageName -like "*Pro for Workstations*") { $ProductKey = "NRG8B-VKK3Q-CXVCJ-9G2XF-6Q84J"; Write-Log "Adding Product Key Pro for Workstations: $ProductKey" }
				elseif ($OSImageName -like "*Education*") { $ProductKey = "NW6C2-QMPVW-D7KKK-3GKT6-VCFB2"; Write-Log "Adding Product Key Pro for Education: $ProductKey" }
				else { $ProductKey = "" }
			}
			
			Write-Log "OS Index from variable: $OSIndex"
			
			$tsenv.Value("OSDUpgradeDynamicUpdateSettings") = "Disable"; $OSDUpgradeDynamicUpdateSettings = $tsenv.Value("OSDUpgradeDynamicUpdateSettings")
			$tsenv.Value("OSDUpgradeIgnoreMessages") = "true"; $OSDUpgradeIgnoreMessages = $tsenv.Value("OSDUpgradeIgnoreMessages")
			$tsenv.Value("OSDUpgradeInstallEditionIndex") = $OSIndex; $OSDUpgradeInstallEditionIndex = $tsenv.Value("OSDUpgradeInstallEditionIndex")
			$tsenv.Value("OSDUpgradeInstallPath") = "$DriveLetter"; $OSDUpgradeInstallPath = $tsenv.Value("OSDUpgradeInstallPath")
			$tsenv.Value("OSDUpgradePreserveSettings") = "Upgrade"; $OSDUpgradePreserveSettings = $tsenv.Value("OSDUpgradePreserveSettings")
			$tsenv.Value("OSDUpgradeScanOnly") = "false"; $OSDUpgradeScanOnly = $tsenv.Value("OSDUpgradeScanOnly")
			$tsenv.Value("OSDUpgradeStagedContent") = "C:\Drivers"; $OSDUpgradeStagedContent = $tsenv.Value("OSDUpgradeStagedContent")
			$tsenv.Value("OSDSetupAdditionalUpgradeOptions") = "/Priority High"; $OSDSetupAdditionalUpgradeOptions = $tsenv.Value("OSDSetupAdditionalUpgradeOptions")
			if ($KMSClient -eq $true) { $tsenv.Value("OSDUpgradeOsProductKey") = $ProductKey; $OSDUpgradeOsProductKey = $tsenv.Value("OSDUpgradeOsProductKey") }
			
			Write-Log "TS Variable set OSDUpgradeDynamicUpdateSettings:			$OSDUpgradeDynamicUpdateSettings"
			Write-Log "TS Variable set OSDUpgradeIgnoreMessages:				$OSDUpgradeIgnoreMessages"
			Write-Log "TS Variable set OSDUpgradeInstallEditionIndex:			$OSDUpgradeInstallEditionIndex"
			Write-Log "TS Variable set OSDUpgradeInstallPath:					$OSDUpgradeInstallPath"
			Write-Log "TS Variable set OSDUpgradePreserveSettings:				$OSDUpgradePreserveSettings"
			Write-Log "TS Variable set OSDUpgradeScanOnly:						$OSDUpgradeScanOnly"
			Write-Log "TS Variable set OSDUpgradeStagedContent:					$OSDUpgradeStagedContent"
			if ($KMSClient -eq $true) { Write-Log "TS Variable set OSDUpgradeOsProductKey:					$OSDUpgradeOsProductKey" }
			
			Write-Log "Start Upgrading OS using OSDUpgradeOS.exe"
			$Process = Start-Process -FilePath "$env:windir\CCM\OSDUpgradeOS.exe" -Wait -PassThru -NoNewWindow -ErrorAction SilentlyContinue
			$ErrorCode = $Process.ExitCode
			Write-Log "Setup ended with exit code: $ErrorCode"
			$tsenv.Value("ReturnCode") = $ErrorCode
			Write-Log "Dismounting ISO"
			Dismount-ISO $ISO
			Write-Log "ISO dismounted"
		}
		catch { Write-Log "Error: Failed to start installation"; $ReturnCode = 8022; $tsenv.Value("ReturnCode") = $ReturnCode }
	}
	else { Write-Log "Error: Failed to mount ISO file, no drive letter"; $ReturnCode = 8022; $tsenv.Value("ReturnCode") = $ReturnCode }
}
else { Write-Log "Error: ISO upgrade image not found"; $ReturnCode = 8022; $tsenv.Value("ReturnCode") = $ReturnCode }
