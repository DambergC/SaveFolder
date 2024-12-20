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
Write-Log "Export current installed Language"

$MUIVariableFile = "$env:windir\MUIExport.txt"
# Check for MUIExport.txt (if previously failed upgrade these are the original settings)
if (Test-Path -Path "$MUIVariableFile")
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
else
{
	# Get MUI Language
	Write-Log "MUIExport.txt NOT found, reading values from registry"
	$SystemLanguage = [cultureinfo]::InstalledUICulture.Name
	if ($SystemLanguage -like "*en-GB*")
	{
		$SystemLanguage = "en-US"
	}
	Write-Log "System Language detected: $SystemLanguage"
	
	try
	{
		$tsenv.Value("OSDMUILanguage") = $SystemLanguage
		Write-Log "Setting OSDMUILanguage to: $SystemLanguage"
	}
	catch { Write-Log "Error: could not set TS variable OSDMUILanguage" }
	
	try
	{
		$OSDDefaultLanguage = Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Nls\Language' | Select-Object -ExpandProperty InstallLanguage
		Write-Log "Default Language from registry: $OSDDefaultLanguage"
	}
	catch { Write-Log "Error: failed to get default language from registry" }
}

# Remarked - not used in 5.9 since using native upgrade images - also moved to InplaceUpgrade-DetectMUI for other versions
#	# If $OSDDefaultLanguage = 0409 (en-US), no need to handle LanguagePacks
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

# Create MUI export file (used to restore language if upgrade breaks)
if ((!(Test-Path "$env:windir\MUIExport.txt")) -and (!(Test-Path "$env:SystemDrive\Windows.old\MUIExport.txt")))
{
	if ($tsenv.Value("OSDMultilingual") -eq $true){ $OSDMultilingual = "True" } else { $OSDMultilingual = "False" }
	"OSDMultilingual=$OSDMultilingual" | Out-File $MUIVariableFile -Force
	"OSDDefaultLanguage=$OSDDefaultLanguage" | Out-File $MUIVariableFile -Append
	"OSDMUILanguage=$SystemLanguage" | Out-File $MUIVariableFile -Append
	Write-Log "Writing Language variables in $env:windir\MUIExport.txt"
}
else { Write-Log "$env:windir\MUIExport.txt does already exist, reusing found settings" }

# Export registry from HKLM:\System\CurrentControlSet\Control\MUI\Settings and HKLM:\SYSTEM\CurrentControlSet\Control\CMF
if (!(Test-Path "$env:windir\OSDMUIRegBackup.reg"))
{
	try
	{
		$Process = Start-Process -FilePath "reg.exe" -ArgumentList "export `"HKLM\System\CurrentControlSet\Control\MUI\Settings`" `"$env:windir\OSDMUIRegBackup.reg`" /y" -Wait -NoNewWindow -PassThru -ErrorAction SilentlyContinue
		$ErrorCode = $Process.ExitCode
		Write-Log "Exported HKLM\System\CurrentControlSet\Control\MUI\Settings into $env:windir\OSDMUIRegBackup.reg"
		
		$Process = Start-Process -FilePath "reg.exe" -ArgumentList "export `"HKLM\SYSTEM\CurrentControlSet\Control\CMF`" `"$env:windir\OSDCMFRegBackup.reg`" /y" -Wait -NoNewWindow -PassThru -ErrorAction SilentlyContinue
		$ErrorCode = $Process.ExitCode
		Write-Log "Exported HKLM\SYSTEM\CurrentControlSet\Control\CMF into $env:windir\OSDCMFRegBackup.reg"
		
		$Process = Start-Process -FilePath "reg.exe" -ArgumentList "export `"HKEY_USERS\.DEFAULT\Control Panel\Desktop\MuiCached`" `"$env:windir\OSDDefaultUserRegBackup.reg`" /y" -Wait -NoNewWindow -PassThru -ErrorAction SilentlyContinue
		$ErrorCode = $Process.ExitCode
		Write-Log "Exported HKEY_USERS\.DEFAULT\Control Panel\Desktop\MuiCached into $env:windir\OSDDefaultUserRegBackup.reg"
		
		$Process = Start-Process -FilePath "reg.exe" -ArgumentList "export `"HKEY_USERS\.DEFAULT\Control Panel\Desktop`" `"$env:windir\OSDDefaultUserRegBackup.reg`" /y" -Wait -NoNewWindow -PassThru -ErrorAction SilentlyContinue
		$ErrorCode = $Process.ExitCode
		Write-Log "Exported HKEY_USERS\.DEFAULT\Control Panel\Desktop into $env:windir\OSDDefaultUserRegBackup.reg"
	}
	catch { Write-Log "Failed to export MUI and CMF to reg backup files" }
}
else { Write-Log "Registry backup already done, skipping" }