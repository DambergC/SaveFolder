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
Write-Log "Activate TPM chip"

# Set variables
$PasswordTemp = "CygatePW"
$Bios_Settings = "$env:TEMP\BIOS_Settings.txt"
$ParentDirectory = (Get-Item $PSScriptRoot).parent.parent.FullName
$BIOSApplyFile = "$env:TEMP\BIOS_Settings_Apply.txt"
$RebootNeeded = $false
$tsenv.Value("OSDReboot") = $RebootNeeded
$BIOSsetpwdlog = $tsenv.Value("_SMSTSLogPath") + "\BIOSsetpwd.log"
$BIOSturnTPMonlog = $tsenv.Value("_SMSTSLogPath") + "\BIOSturnTPMon.log"
$BIOSactivateTPMlog = $tsenv.Value("_SMSTSLogPath") + "\BIOSactivateTPM.log"
$ResetTPM = $false
$ResetTPM = $tsenv.Value("OSDResetTPM")

if (Test-Path "$BIOSApplyFile") { Remove-Item -Path "$BIOSApplyFile" -Force }

$OSVersionVariable = $tsenv.Value("OSDOSVersion")
Write-Log "OS Version variable: $OSVersionVariable"

# Getting Manufacturer
$Manufacturer = (Get-WmiObject Win32_ComputerSystem).Manufacturer.TrimEnd()

# Check use of BIOS password
$BIOSPasswordArray = @()
$UseBIOSPassword = $false
if ($tsenv.Value("OSDUseBIOSPassword") -eq $true)
{
	if (($tsenv.Value("OSDBIOSPassword1")) -ne $null) { $BIOSPasswordArray += $tsenv.Value("OSDBIOSPassword1") }
	if (($tsenv.Value("OSDBIOSPassword2")) -ne $null) { $BIOSPasswordArray += $tsenv.Value("OSDBIOSPassword2") }
	$UseBIOSPassword = $true
	Write-Log "BIOS password will be used"
}
else
{
	Write-Log "BIOS password will NOT be used"
	if ($Manufacturer -like "*Lenovo*") { $BIOSPasswordArray += "1" }
}

# Remove old BIOS file
if (Test-Path "$Bios_Settings") { Remove-Item -Path "$Bios_Settings" -Force }

if ($Manufacturer -like "*Lenovo*")
{
	Write-Log "Found manufacturer to be Lenovo, extracting BIOS to file"
	gwmi -Class lenovo_Biossetting -Namespace root\wmi | select currentsetting | Out-File $Bios_Settings -Force -ErrorAction SilentlyContinue
	
	$BIOSFile = [System.IO.File]::OpenText("$Bios_Settings")
	if ($BIOSFile -eq $null) { Write-Log "Error extracting BIOS settings" }
	while ($null -ne ($line = $BIOSFile.ReadLine()))
	{
		if ($line -like "SecurityChip*") { $SecurityChip = ($line.Substring($line.IndexOf(",") + 1, $line.Length - ($line.IndexOf(",") + 1))).Trim(); Write-Log "SecurityChip: $SecurityChip" }
	}
	
	foreach ($BIOSPassword in $BIOSPasswordArray)
	{
		# TPM settings
		if ($tsenv.Value("OSDTPMState") -eq "Inactive") { $Process = (gwmi -class Lenovo_SetBiosSetting –namespace root\wmi).SetBiosSetting("SecurityChip,Active,$BIOSPassword,ascii,us"); $RebootNeeded = $true; $ErrorCode = $Process.return; Write-Log "SecurityChip changed to Active with exit code: $ErrorCode" }
		
		# Save BIOS settings
		$Process = (gwmi -class Lenovo_SaveBiosSettings -namespace root\wmi).SaveBiosSettings("$BIOSPassword,ascii,us")
		$ErrorCode = $Process.return
		Write-Log "Saving BIOS settings with exit code: $ErrorCode"
	}
}

if ($Manufacturer -like "*Dell*")
{
	Write-Log "Found manufacturer to be Dell, extracting BIOS to file"
	$BIOSConfigTool = "$ParentDirectory\Tools\Dell\X86_64\cctk.exe"
	Write-Log "Tool Path: $BIOSConfigTool"
	$process = Start-Process -FilePath `"$BIOSConfigTool`" -ArgumentList "--outfile `"$Bios_Settings`"" -Wait -NoNewWindow -PassThru -ErrorAction SilentlyContinue
	$ErrorCode = $Process.ExitCode
	Write-Log "Getting BIOS settings with exit code: $ErrorCode"
	
	$BIOSFile = [System.IO.File]::OpenText("$Bios_Settings")
	if ($BIOSFile -eq $null) { Write-Log "Error extracting BIOS settings" }
	
	while ($null -ne ($line = $BIOSFile.ReadLine()))
	{
		if ($line -like "*tpmactivation=*") # on / off
		{
			$Value = $line.Substring($line.IndexOf("=") + 1).Trim()
			Write-Log "TPM Device: $Value"
			if ($Value -like "*deactivated*")
			{
				# Setting temporaray admin password - required on Dell to enable TPM
				$process = Start-Process -FilePath `"$BIOSConfigTool`" -ArgumentList "--setuppwd=`"$PasswordTemp`" --logfile=`"$BIOSsetpwdlog`"" -Wait -NoNewWindow -PassThru -ErrorAction SilentlyContinue
				$ErrorCode = $Process.ExitCode
				Write-Log "Setting Admin Password with exit code: $ErrorCode"
				
				# Applying Settings
				$process = Start-Process -FilePath `"$BIOSConfigTool`" -ArgumentList "--tpmactivation=activate --valsetuppwd=`"$PasswordTemp`" --logfile=`"$BIOSactivateTPMlog`"" -Wait -NoNewWindow -PassThru -ErrorAction SilentlyContinue
				$ErrorCode = $Process.ExitCode
				Write-Log "Activating TPM with exit code: $ErrorCode"
				if ($ErrorCode -eq 262) { Write-Log "Activating TPM failed, have to reset TPM owner"; $ResetTPM = $true }
				$RebootNeeded = $true
				
				# Clearing / Removing admin password
				$process = Start-Process -FilePath `"$BIOSConfigTool`" -ArgumentList "--setuppwd= --valsetuppwd=`"$PasswordTemp`"" -Wait -NoNewWindow -PassThru -ErrorAction SilentlyContinue
				$ErrorCode = $process.ExitCode
				Write-Log "Remove Admin password with exit code: $ErrorCode"
			}
			else { Write-Log "tpmactivation=activated already set, no change needed" }
			
			if ($Value -like "*Disabled*")
				{
					# Setting temporaray admin password - required on Dell to enable TPM
					$process = Start-Process -FilePath `"$BIOSConfigTool`" -ArgumentList "--setuppwd=`"$PasswordTemp`" --logfile=`"$BIOSsetpwdlog`"" -Wait -NoNewWindow -PassThru -ErrorAction SilentlyContinue
					$ErrorCode = $Process.ExitCode
					Write-Log "Setting Admin Password with exit code: $ErrorCode"
					
					# Applying Settings
					$process = Start-Process -FilePath `"$BIOSConfigTool`" -ArgumentList "--tpmactivation=Enabled --valsetuppwd=`"$PasswordTemp`" --logfile=`"$BIOSactivateTPMlog`"" -Wait -NoNewWindow -PassThru -ErrorAction SilentlyContinue
					$ErrorCode = $Process.ExitCode
					Write-Log "Activating TPM with exit code: $ErrorCode"
					if ($ErrorCode -eq 262) { Write-Log "Activating TPM failed, have to reset TPM owner"; $ResetTPM = $true }
					$RebootNeeded = $true
					
					# Clearing / Removing admin password
					$process = Start-Process -FilePath `"$BIOSConfigTool`" -ArgumentList "--setuppwd= --valsetuppwd=`"$PasswordTemp`"" -Wait -NoNewWindow -PassThru -ErrorAction SilentlyContinue
					$ErrorCode = $process.ExitCode
					Write-Log "Remove Admin password with exit code: $ErrorCode"
				}
				else { Write-Log "tpmactivation=activated already set, no change needed" }
				
		}
	}
}

if (($Manufacturer -like "*Hewlett*") -or ($Manufacturer -like "*HP*"))
{
	Write-Log "Found manufacturer to be Hewlett Packard, extracting BIOS to file"
	If ((Get-CimInStance Win32_OperatingSystem).OSArchitecture -like "*64-Bit*") { $BIOSConfigTool = "$ParentDirectory\Tools\HP\BiosConfigUtility64.exe"; Write-Log "OS Architecture is 64-bit" }
	Else { $BIOSConfigTool = "$ParentDirectory\Tools\HP\BiosConfigUtility.exe"; Write-Log "OS Architecture is 32-bit" }
	Write-Log "BIOS Config Tool Path: $BIOSConfigTool"
	$Process = Start-Process -FilePath "$BIOSConfigTool" -ArgumentList "/Get:`"$Bios_Settings`"" -NoNewWindow -Wait -PassThru
	$ErrorCode = $Process.ExitCode
	Write-Log "Getting BIOS settings with exit code: $ErrorCode"
	
	$BIOSFile = [System.IO.File]::OpenText("$Bios_Settings")
	if ($BIOSFile -eq $null) { Write-Log "Error extracting BIOS settings" }
	
	# Writing config file
	"BIOSConfig 1.0" | Out-File -FilePath $BIOSApplyFile -Force
	";" | Out-File -FilePath $BIOSApplyFile -Append
	
	while ($null -ne ($line = $BIOSFile.ReadLine()))
	{
		# TPM Device
		if ($line -like "*TPM State*") # Available / Hidden
		{
			$line = $BIOSFile.ReadLine(); $linetest = [int[]][char[]]$line; if ($linetest -contains [char]42) { $Value = $line.Trim().Substring(1) }
			$line = $BIOSFile.ReadLine(); $linetest = [int[]][char[]]$line; if ($linetest -contains [char]42) { $Value = $line.Trim().Substring(1) }
			Write-Log "TPM State: $Value"
			if ($Value -like "*Disable*")
			{
				Write-Log "Adding TPM State *Enable to configuration file"
				"TPM State" | Out-File -FilePath $BIOSApplyFile -Append
				"	Disable" | Out-File -FilePath $BIOSApplyFile -Append
				"	*Enable" | Out-File -FilePath $BIOSApplyFile -Append
				$RebootNeeded = $true
			}
			else { Write-Log "TPM State *Enable already set, no change needed" }
		}
		
		if ($line -like "*Activate TPM On Next Boot*") # Available / Hidden
		{
			$line = $BIOSFile.ReadLine(); $linetest = [int[]][char[]]$line; if ($linetest -contains [char]42) { $Value = $line.Trim().Substring(1) }
			$line = $BIOSFile.ReadLine(); $linetest = [int[]][char[]]$line; if ($linetest -contains [char]42) { $Value = $line.Trim().Substring(1) }
			Write-Log "Activate TPM On Next Boot: $Value"
			if ($Value -like "*Disable*")
			{
				Write-Log "Adding TPM State *Enable to configuration file"
				"Activate TPM On Next Boot" | Out-File -FilePath $BIOSApplyFile -Append
				"	Disable" | Out-File -FilePath $BIOSApplyFile -Append
				"	*Enable" | Out-File -FilePath $BIOSApplyFile -Append
				$RebootNeeded = $true
			}
			else { Write-Log "Activate TPM On Next Boot *Enable already set, no change needed" }
		}
		
		if ($line -like "*Activate Embedded Security On Next Boot*") # Available / Hidden
			{
				$line = $BIOSFile.ReadLine(); $linetest = [int[]][char[]]$line; if ($linetest -contains [char]42) { $Value = $line.Trim().Substring(1) }
				$line = $BIOSFile.ReadLine(); $linetest = [int[]][char[]]$line; if ($linetest -contains [char]42) { $Value = $line.Trim().Substring(1) }
				Write-Log "Activate Embedded Security On Next Boot: $Value"
				if ($Value -like "*Disable*")
				{
					Write-Log "Adding TPM State *Enable to configuration file"
					"Activate TPM On Next Boot" | Out-File -FilePath $BIOSApplyFile -Append
					"	Disable" | Out-File -FilePath $BIOSApplyFile -Append
					"	*Enable" | Out-File -FilePath $BIOSApplyFile -Append
					$RebootNeeded = $true
				}
				else { Write-Log "Activate TPM On Next Boot *Enable already set, no change needed" }
			}
		}
	
	# Create Password file(s)
	If ((Get-CimInStance Win32_OperatingSystem).OSArchitecture -like "*64-Bit*") { $BIOSPasswordTool = "$ParentDirectory\Tools\HP\HPQPswd64.exe"; Write-Log "OS Architecture is 64-bit" }
	Else { $BIOSPasswordTool = "$ParentDirectory\Tools\HP\HPQPswd.exe"; Write-Log "OS Architecture is 32-bit" }
	Write-Log "BIOS Password Tool Path: $BIOSPasswordTool"
	
	if ($UseBIOSPassword -eq $true)
	{
		Write-Log "Use BIOS variable is true, creating password file"
		if (($tsenv.Value("OSDBIOSPassword1")) -ne $null)
		{
			$BIOSPassword = $tsenv.Value("OSDBIOSPassword1")
			$Process = Start-Process -FilePath "$BIOSPasswordTool" -ArgumentList "/s /f`"$env:TEMP\Password1.bin`" /P`"$BIOSPassword`"" -NoNewWindow -Wait -PassThru
			$ErrorCode = $Process.ExitCode
			Write-Log "BIOS Password 1 bin file created with exit code: $ErrorCode"
		}
		if (($tsenv.Value("OSDBIOSPassword2")) -ne $null)
		{
			$BIOSPassword = $tsenv.Value("OSDBIOSPassword2")
			$Process = Start-Process -FilePath "$BIOSPasswordTool" -ArgumentList "/s /f`"$env:TEMP\Password2.bin`" /P`"$BIOSPassword`"" -NoNewWindow -Wait -PassThru
			$ErrorCode = $Process.ExitCode
			Write-Log "BIOS Password 2 bin file created with exit code: $ErrorCode"
		}
	}
	else
	{
		Write-Log "Use BIOS variable is false, creating temporary password file"
		$Process = Start-Process -FilePath "$BIOSPasswordTool" -ArgumentList "/s /f`"$env:TEMP\Password1.bin`" /P`"$PasswordTemp`"" -NoNewWindow -Wait -PassThru
		$ErrorCode = $Process.ExitCode
		Write-Log "BIOS Password 1 bin file created with exit code: $ErrorCode"
	}
	
	if ($RebootNeeded -eq $true)
	{
		Write-Log "Reboot needed is true, changes to be made in BIOS"
		# Reencode configuration file to ANSI
		[System.Io.File]::ReadAllText($BIOSApplyFile) | Out-File -FilePath $BIOSApplyFile -Encoding Default # HP BIOS config file must have encoding ANSI which is the value "Default". If omitted encoding is set to Unicode.
		
		# Apply Settings
		# Set BIOS password - some functions require password to enable, fx TPM
		if (Test-Path "$env:TEMP\Password1.bin")
		{
			if ($UseBIOSPassword -eq $false)
			{
				$Process = Start-Process -FilePath "$BIOSConfigTool" -ArgumentList "/nspwd:`"$env:TEMP\Password1.bin`" /log /logpath:`"$LogPath\BIOS_Set_TPMactivate.log`"" -NoNewWindow -Wait -PassThru
				$ErrorCode = $Process.ExitCode
				Write-Log "Setting BIOS settings with exit code: $ErrorCode"
			}
			
			$Process = Start-Process -FilePath "$BIOSConfigTool" -ArgumentList "/cspwd:`"$env:TEMP\Password1.bin`" /Set:`"$BIOSApplyFile`" /log /logpath:`"$LogPath\BIOSResult_TPMactivate.log`"" -NoNewWindow -Wait -PassThru
			$ErrorCode = $Process.ExitCode
			Write-Log "Setting BIOS settings with exit code: $ErrorCode"
			
			if ($UseBIOSPassword -eq $false)
			{
				# Clear BIOS password
				$Process = Start-Process -FilePath "$BIOSConfigTool" -ArgumentList "/nspwdfile:`"`" /cspwdfile:`"$env:TEMP\Password1.bin`" /log /logpath:`"$LogPath\BIOS_Clear_TPMactivate.log`"" -NoNewWindow -Wait -PassThru
				$ErrorCode = $Process.ExitCode
				Write-Log "Setting BIOS settings with exit code: $ErrorCode"
			}
		}
		else { Write-Log "Password1.bin not found" }
		
		if (Test-Path "$env:TEMP\Password2.bin")
		{
			$Process = Start-Process -FilePath "$BIOSConfigTool" -ArgumentList "/nspwd:`"$env:TEMP\Password2.bin`" /log /logpath:`"$LogPath\BIOS_Set_TPMactivate.log`"" -NoNewWindow -Wait -PassThru
			$ErrorCode = $Process.ExitCode
			Write-Log "Setting BIOS settings with exit code: $ErrorCode"
			
			$Process = Start-Process -FilePath "$BIOSConfigTool" -ArgumentList "/cspwd:`"$env:TEMP\Password2.bin`" /Set:`"$BIOSApplyFile`" /log /logpath:`"$LogPath\BIOSResult_TPMactivate.log`"" -NoNewWindow -Wait -PassThru
			$ErrorCode = $Process.ExitCode
			Write-Log "Setting BIOS settings with exit code: $ErrorCode"
			
			if ($UseBIOSPassword -eq $false)
			{
				# Clear BIOS password
				$Process = Start-Process -FilePath "$BIOSConfigTool" -ArgumentList "/nspwdfile:`"`" /cspwdfile:`"$env:TEMP\Password2.bin`" /log /logpath:`"$LogPath\BIOS_Clear_TPMactivate.log`"" -NoNewWindow -Wait -PassThru
				$ErrorCode = $Process.ExitCode
				Write-Log "Setting BIOS settings with exit code: $ErrorCode"
			}
		}
		else { Write-Log "Password2.bin not found" }
	}
	else { Write-Log "Reboot is found false, no changes made to BIOS" }
}

if ($ResetTPM -eq $true)
{
	$tsenv.Value("OSDResetTPM") = $ResetTPM
	Write-Log "Resetting TPM Owner"
	$TPM = Get-WmiObject -Class Win32_TPM -Namespace root\CIMV2\Security\MicrosoftTpm
	
	# Enable, activate the chip, and allow the installation of a TPM owner.
	$Result = $TPM.SetPhysicalPresenceRequest(5)
	If ($Result.ReturnValue -eq 0)
	{
		Write-Log "Reset TPM with exit code: $Result (Success)"
		$tsenv.Value("OSDResetTPM") = $false
	}
	else
	{
		Write-Log "Reset TPM with exit code: $Result (Failure)"
		$tsenv.Value("OSDResetTPM") = $true
	}
	
	
	If (!(($TPM.IsEndorsementKeyPairPresent()).IsEndorsementKeyPairPresent))
	{
		# Enable the TPM encryption
		$TPM.CreateEndorsementKeyPair()
	}
	
	# Check if the TPM chip currently has an owner 
	If (($TPM.IsEndorsementKeyPairPresent()).IsEndorsementKeyPairPresent)
	{
		# Convert password to hash
		$OwnerAuth = $TPM.ConvertToOwnerAuth("$PasswordTemp")
		# Clear current owner
		$TPM.Clear($OwnerAuth.OwnerAuth)
		# Take ownership
		$TPM.TakeOwnership($OwnerAuth.OwnerAuth)
	}
}

$tsenv.Value("OSDReboot") = $RebootNeeded
