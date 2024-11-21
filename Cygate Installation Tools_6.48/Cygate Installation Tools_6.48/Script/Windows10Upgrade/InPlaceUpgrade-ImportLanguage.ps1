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
Write-Log " "
Write-Log "Import Language"

# Check if target Windows 10-build is already installed
$Build = [System.Environment]::OSVersion.Version.Build
$TargetBuild = $tsenv.Value("OSDTargetBuild")

# Check if MUIExport text file exist - reuse (could be that upgrade was broken before exported values were reapplied at the end of upgrade process)
$UseMUIFile = $false
if (Test-Path "$env:windir\MUIExport.txt") { $MUIVariableFile = "$env:windir\MUIExport.txt"; $UseMUIFile = $true; Write-Log "MUI variable found in $env:windir" }
if (Test-Path "$env:SystemDrive\Windows.old\MUIExport.txt") { $MUIVariableFile = "$env:windir\MUIExport.txt"; $UseMUIFile = $true; Write-Log "MUI variable found in $env:SystemDrive\Windows.old" }

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
		$tsenv.Value("OSDDefaultLanguage") = $OSDDefaultLanguage
		if ($OSMultiLingual -like "*True*") { $tsenv.Value("OSDMultilingual") = $true }
		else { $tsenv.Value("OSDMultilingual") = $false }
	}
	catch { Write-Log "Error: MUIExport.txt found, could not read values" }
}

try
{
	$OSDDefaultLanguage = $tsenv.Value("OSDDefaultLanguage")
	Write-Log "DefaultLanguage from variable: $OSDDefaultLanguage"
}
catch { Write-Log "Error: failed to find DefaultLanguage in variable" }

try
{
	$OSMultiLingual = $tsenv.Value("OSDMultilingual")
	if ($OSMultiLingual -eq $true)
	{
		New-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Nls\Language" -Name "InstallLanguage" -Value "$OSDDefaultLanguage" -PropertyType "String" -Force -ErrorAction Stop
		New-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Nls\Language" -Name "Default" -Value "$OSDDefaultLanguage" -PropertyType "String" -Force -ErrorAction Stop
		Write-Log "Adding InstallLanguage to registry: $OSDDefaultLanguage"
	}
}
catch { Write-Log "Error: Failed adding InstallLanguage to registry" }

if ($RunningInTs -eq $true)
{
	$OSDUILanguage = $tsenv.Value("OSDMUILanguage")
	Write-Log "MUI Language from TS variable: $OSDUILanguage"
}
try
{
	if ($OSDUILanguage -ne $null)
	{
		Write-Log "Run Set-WinUILanguageOverride to enable $OSDUILanguage on Logon Screen"
		Set-WinUILanguageOverride $OSDUILanguage -ErrorAction SilentlyContinue
		Set-WinSystemLocale $OSDUILanguage
		Set-WinUserLanguageList $OSDUILanguage -Force
		
		if (Test-Path "$env:SystemDrive\Windows.old\OSDMUIRegBackup.reg") { $RegImportPath = "$env:SystemDrive\Windows.old" }
		if (Test-Path "$env:windir\OSDMUIRegBackup.reg") { $RegImportPath = $env:windir }
		
		$Process = Start-Process -FilePath "regedit.exe" -ArgumentList "/S `"$RegImportPath\OSDMUIRegBackup.reg`"" -Wait -NoNewWindow -PassThru -ErrorAction SilentlyContinue
		$ErrorCode = $Process.ExitCode
		Write-Log "Imported settings from $RegImportPath\OSDMUIRegBackup.reg"
		
		$Process = Start-Process -FilePath "regedit.exe" -ArgumentList "/S `"$RegImportPath\OSDCMFRegBackup.reg`"" -Wait -NoNewWindow -PassThru -ErrorAction SilentlyContinue
		$ErrorCode = $Process.ExitCode
		Write-Log "Imported settings from $RegImportPath\OSDCMFRegBackup.reg"
		
		$Process = Start-Process -FilePath "regedit.exe" -ArgumentList "/S `"$RegImportPath\OSDDefaultUserRegBackup.reg`"" -Wait -NoNewWindow -PassThru -ErrorAction SilentlyContinue
		$ErrorCode = $Process.ExitCode
		Write-Log "Imported settings from $RegImportPath\OSDDefaultUserRegBackup.reg"
		
		New-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\MUI\Settings" -Name "PreferredUILanguages" -Value $OSDUILanguage -PropertyType "MultiString" -Force -ErrorAction SilentlyContinue
		
		if ($Build -eq $TargetBuild)
		{
			Write-Log "Current Build is same as target build - assume upgrade successful, remove registry backup"
			Remove-Item -Path "$RegImportPath\OSDMUIRegBackup.reg" -Force
			Remove-Item -Path "$RegImportPath\OSDCMFRegBackup.reg" -Force
			Remove-Item -Path "$RegImportPath\OSDDefaultUserRegBackup.reg" -Force
		}
		else { Write-Log "Current build is NOT same as target build - assume upgrade unsuccessful, keeping registry backup" }
	}
}
catch {}

# Language set, removing MUI text file(s))
if ($Build -eq $TargetBuild)
{
	Write-Log "Current Build is same as target build - assume upgrade successful, remove MUIExport.txt"
	try
	{
		if (Test-Path "$env:windir\MUIExport.txt") { Remove-Item -Path "$env:windir\MUIExport.txt" -Force; Write-Log "Removed $env:windir\MUIExport.txt" }
		if (Test-Path "$env:SystemDrive\Windows.old\MUIExport.txt") { Remove-Item -Path "$env:SystemDrive\Windows.old\MUIExport.txt" -Force; Write-Log "Removed $env:SystemDrive\Windows.old\MUIExport.txt" }
	}
	catch { }
}
else { Write-Log "Current build is NOT same as target build - assume upgrade unsuccessful, keeping MUIExport.txt" }
