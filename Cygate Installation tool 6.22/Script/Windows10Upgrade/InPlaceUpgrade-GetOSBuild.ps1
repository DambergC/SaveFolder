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
	try { $tsenv.Value("OSDReboot") = $false } catch {}
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
		try { $tsenv.Value("OSDReboot") = $true } catch { }
		
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
Write-Log " "
Write-Log "########################################################################## Starting Upgrade #################################################################"
Write-Log "Get OS Build"

# Close running Ready tool if opened

try { Write-Log "Close InPlaceUpgrade-ReadyTool.exe if running"; Start-Process -FilePath "taskkill.exe" -ArgumentList "/IM InPlaceUpgrade-ReadyTool.exe /F /T" -Wait -PassThru -NoNewWindow -ErrorAction SilentlyContinue } catch { }

if (Test-Path "$env:windir\Logs\Software\ISOExtraction.log") { Remove-Item -Path "$env:windir\Logs\Software\ISOExtraction.log" -Force }

$OSDOSImagePath = $null
if (Test-Path "$env:SystemDrive\OSUpgradeImage")
{
	Write-Log "$env:SystemDrive\OSUpgradeImage found - check if ISO file exist"
	$ISO = (Get-ChildItem -Path "$env:SystemDrive\OSUpgradeImage" -Filter "*.iso" -Recurse -ErrorAction SilentlyContinue).FullName
	
	if (($null -ne $ISO) -and ($ISO -like "*.iso"))
	{
		$OSDOSImagePath = "$env:SystemDrive\OSUpgradeImage"; Write-Log "ISO found in $env:SystemDrive\OSUpgradeImage"
		
		# Check if ISO already downloaded is same as existing - if not, use downloaded
		Write-Log "Check if downloaded ISO is same or different as ISO in $env:SystemDrive\OSUpgradeImage"
		$ISOsystemdrive = (Get-ChildItem -Path "$env:SystemDrive\OSUpgradeImage" -Filter "*.iso" -Recurse -ErrorAction SilentlyContinue).Name
		
		$OSDOSImagePathTemp = $tsenv.Value("OSDOSImagePath01")
		Write-Log "Try find ISO using variable OSDOSImagePath: $OSDOSImagePathTemp"
		$ISOdownloaded = (Get-ChildItem -Path "$OSDOSImagePathTemp" -Filter "*.iso" -Recurse -ErrorAction SilentlyContinue).Name
		if (($null -ne $ISOdownloaded) -and ($ISOdownloaded -like "*.iso"))
		{
			Write-Log "ISO found in $OSDOSImagePathTemp"
			if ("$ISOsystemdrive" -eq "$ISOdownloaded") { Write-Log "ISO in $env:SystemDrive\OSUpgradeImage is same as downloaded - using ISO in $env:SystemDrive\OSUpgradeImage" }
			else
			{
				Write-Log "ISO in $env:SystemDrive\OSUpgradeImage is not same - removing and using downloaded"
				Remove-Item -Path "$env:SystemDrive\OSUpgradeImage" -Force -Recurse -ErrorAction SilentlyContinue
				$OSDOSImagePath = $null
			}
		}
		else { Write-Log "No ISO image found in $OSDOSImagePathTemp" }
	}
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

if (Test-Path "$OSDOSImagePath")
{
	try
	{
		$ISO = (Get-ChildItem -Path "$OSDOSImagePath" -Filter "*.iso" -Recurse -ErrorAction Stop).FullName
		if ($ISO -ne $null)
		{
			Write-Log "ISO file found: $ISO"
			$DriveLetter, $MountResult = Mount-ISO $ISO
			Write-Log "ISO file mounted to: $DriveLetter"
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
			try
			{
				Copy-Item -Path "$ParentDirectory\Tools\7zip\7z.dll" -Destination "$env:windir" -Force -ErrorAction Stop
				Write-Log "Copy 7z.dll to local disk"
			}
			catch
			{ Write-Log "Error: Failed to copy 7z.dll to local disk" }
			
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
	catch
	{
		Write-Log "Error: Failed to find upgrade ISO file"
		$ReturnCode = 8022
		$disk = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='C:'" | Select-Object Size, FreeSpace
		$disk = [Math]::Round($Disk.Freespace / 1GB)
		Write-Log "Disk Space is: $disk GB"
		$DriveLetter = $null
	}
	
	if ($DriveLetter -ne $null)
	{
		try
		{
			$Version = (dism /Get-WimInfo /WimFile:"$DriveLetter\Sources\install.wim" /index:1 | Select-String "Version ").ToString().Split(":")[1].Trim()
			Write-Log "Version from wim file: $Version"
			$Version = $Version -replace ("10.0.", "")
			Write-Log "Version from wim file adjusted: $Version"
		}
		catch { Write-Log "Error: Failed to get build version from wim file: $DriveLetter\Sources\install.wim" }
		Write-Log "Dismounting ISO: $ISO"
		Dismount-ISO $ISO
	}
	else { Write-Log "Error: Failed to mount ISO file, no drive letter" }
}
else
{
	Write-Log "$env:SystemDrive\OSUpgradeImage not found - trying TS variable"
	$OSDOSImagePath = $tsenv.Value("OSDOSImagePath01")
	Write-Log "OSUpgrade imgage location based on OSDOSImagePath: $OSDOSImagePath"
}

try
{
	$TargetBuild = $tsenv.Value("OSDTargetBuild")
	if (($TargetBuild -eq $null) -or ($TargetBuild -lt $Version)) { $tsenv.Value("OSDTargetBuild") = $Version; Write-Log "Target version from TS variable is either null or less than OS image version, setting Target Version: $Version" }
}
catch { Write-Log "Error: Failed to get build version from TS variable"; $tsenv.Value("OSDTargetBuild") = $Version }

$VersionCurrentOS = [System.Environment]::OSVersion.Version.Build
if ($VersionCurrentOS -ge $Version) { Write-Log "Current OS ($VersionCurrentOS) is higher or equal to source for upgrade ($Version) - will NOT continue upgrade"; $tsenv.Value("OSDWindowsUpgrade") = $false }
else { Write-Log "Current OS ($VersionCurrentOS) is lower than source for upgrade ($Version) - will continue upgrade"; $tsenv.Value("OSDWindowsUpgrade") = $true }
