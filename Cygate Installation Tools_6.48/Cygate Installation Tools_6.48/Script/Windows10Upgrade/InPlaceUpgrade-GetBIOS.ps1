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
Write-Log "Get BIOS settings"

# Set variables
$Bios_Settings = "$env:TEMP\BIOS_Settings.txt"
$ParentDirectory = (Get-Item $PSScriptRoot).parent.parent.FullName
$tsenv.Value("OSDTPMDevice") = "NotExist" # will get Enable / Disable from BIOS  - manufacturers have different ways to represent if TPM is active
$tsenv.Value("OSDTPMState") = "NotExist" # will get Enable / Disable from BIOS  - manufacturers have different ways to represent if TPM is active
$tsenv.Value("OSDPXEBoot") = "NotExist"
$tsenv.Value("OSDLegacyBoot") = "NotExist"
$tsenv.Value("OSDUEFIBoot") = "NotExist"
$tsenv.Value("OSDLANWANSwitch") = "NotExist"
$tsenv.Value("OSDSecureBoot") = "NotExist"
$tsenv.Value("OSDHyperThreading") = "NotExist"
$tsenv.Value("OSDVirtualization") = "NotExist"
$tsenv.Value("OSDRAIDMode") = "NotExist"
$tsenv.Value("OSDBIOSVersion") = "0"
$tsenv.Value("OSDSetBIOS") = $false
$tsenv.Value("WakeByThunderbolt") = "NotExist"
$tsenv.Value("ThunderboltSecurityLevel") = "NotExist"
$tsenv.Value("PreBootForThunderboltDevice") = "NotExist"
$tsenv.Value("PreBootForThunderboltUSBDevice") = "NotExist"
$tsenv.Value("AlwaysOnUSB") = "NotExist"
$tsenv.Value("OSDTPMStatus") = "NotOK" # Will be set to "OK" if TPM is active. Manufacturers have different ways to represent if TPM is active
$tsenv.value("TPMActivationPolicy") = "NotExists"
$tsenv.Value("OSDVirtualMachine") = $false
$tsenv.Value("SGXControl") = "NotExist" # Controls fingerprint sensor (Lenovo), default value "SoftwareControl" seem to prevent driver installation
$tsenv.Value("AdaptiveThermalManagementAC") = "NotExist" # Power settings maximum on AC per default, casuses high fan noise
$tsenv.Value("WirelessAutoDisconnection") = "NotExist"
$tsenv.Value("MACAddressPassThrough") = "NotExist"
$tsenv.Value("FastBoot") = "NotExist" # When enabled on HP, can only boot on PXE and HDD - TS sometimes need to restart on WinPE image - which will fail
$tsenv.Value("vTdFeature") = "NotExist"
$tsenv.Value("BIOSUpdateByEndUsers") = "NotExist" # Allows standard user to update BIOS - this is necessary when using password protected BIOS
$tsenv.Value("PhysicalPresenceForTpmProvision") = "NotExist"
$tsenv.Value("PhysicalPresenceForTpmClear") = "NotExist"
$tsenv.Value("OSDTPMResetFromOS") = "NotExist"
$tsenv.Value("OSDCustomizedBoot") = "NotExist" # For HP to be able to restart on pre-loaded WinPE
$tsenv.Value("ThunderboltBIOSAssistMode") = "NotExist" # If enabled enhances ability to add/remove devices from dock


$OSVersionVariable = $tsenv.Value("OSDOSVersion")
Write-Log "OS Version variable: $OSVersionVariable"

# Getting Manufacturer
$Manufacturer = (Get-WmiObject Win32_ComputerSystem).Manufacturer.TrimEnd()
Write-Log "Manufacturer from WMI: $Manufacturer"


# Remove old BIOS file
if (Test-Path "$Bios_Settings"){ Remove-Item -Path "$Bios_Settings" -Force }

if ($Manufacturer -like "*Lenovo*")
{
	Write-Log "Found manufacturer to be Lenovo, extracting BIOS to file"
	gwmi -Class lenovo_Biossetting -Namespace root\wmi | select currentsetting | Out-File $Bios_Settings -Force -ErrorAction SilentlyContinue
	
	# BIOS Version
	$Value = (Get-WmiObject win32_bios).SMBIOSBIOSVersion
	if ($Value -like "*(*") { $Value = $Value.Substring($Value.IndexOf("(") + 1) }
	if ($Value -like "*)*") { $Value = $Value.Substring(0, $Value.IndexOf(")")).Trim() }
	$tsenv.Value("OSDBIOSVersion") = $Value
	Write-Log "BIOS Version: $Value"
	
	# Embedded Controller Version
	try
	{
		$ECPVersionMajor = (Get-WmiObject win32_bios).EmbeddedControllerMajorVersion
		$ECPVersionMinor = (Get-WmiObject win32_bios).EmbeddedControllerMinorVersion
		Write-Log "Embedded Controller Major version: $ECPVersionMajor, Minor Version: $ECPVersionMinor"
		if ($ECPVersionMinor -lt 10) { $ECPVersion = "$ECPVersionMajor.0" + "$ECPVersionMinor" }
		if ($ECPVersionMinor -gt 9) { $ECPVersion = "$ECPVersionMajor." + "$ECPVersionMinor" }
		$tsenv.Value("OSDECPBIOSVersion") = $ECPVersion
		Write-Log "Embedded Controller Version: $ECPVersion"
	}
	catch
	{ Write-Log "Unable to get Embedded Controller Version" }
	
	$BIOSFile = [System.IO.File]::OpenText("$Bios_Settings")
	if ($BIOSFile -eq $null) { Write-Log "Error extracting BIOS settings" } 
	while ($null -ne ($line = $BIOSFile.ReadLine()))
	{
		if ($line -like "SecurityChip*") # Active / Inactive / Disable
		{
			$Value = ($line.Substring($line.IndexOf(",") + 1, $line.Length - ($line.IndexOf(",") + 1))).Trim()
			Write-Log "SecurityChip: $Value"
			if ($Value -like "Inactive*") { $tsenv.Value("OSDTPMState") = "Inactive" } elseif ($Value -like "Active*") { $tsenv.Value("OSDTPMState") = "Active" } elseif ($Value -like "Enable*") { $tsenv.Value("OSDTPMState") = "Active" } else { $tsenv.Value("OSDTPMState") = "Disable" }
		}
		if ($line -like "Security Chip*") # Optional / Disabled / Enabled
		{
			$Value = ($line.Substring($line.IndexOf(",") + 1, $line.Length - ($line.IndexOf(",") + 1))).Trim()
			Write-Log "Security Chip: $Value"
			if ($Value -like "Disabled*") { $tsenv.Value("OSDTPMState") = "Inactive" } elseif ($Value -like "Enabled*") { $tsenv.Value("OSDTPMState") = "Active" } else { $tsenv.Value("OSDTPMState") = "Disable" }
		}
		if ($line -like "EthernetLANOptionROM*") # Enable / Disable
		{
			$Value = ($line.Substring($line.IndexOf(",") + 1, $line.Length - ($line.IndexOf(",") + 1))).Trim()
			Write-Log "EthernetLANOptionROM: $Value"
			if ($Value -like "*Enable*") { $tsenv.Value("OSDPXEBoot") = "Enable" }	else { $tsenv.Value("OSDPXEBoot") = "Disable" }
		}
		if ($line -like "VirtualizationTechnology*") # Enable / Disable
		{
			$Value = ($line.Substring($line.IndexOf(",") + 1, $line.Length - ($line.IndexOf(",") + 1))).Trim()
			Write-Log "VirtualizationTechnology: $Value"
			if ($Value -like "*Enable*") { $tsenv.Value("OSDVirtualization") = "Enable" } else { $tsenv.Value("OSDVirtualization") = "Disable" }
		}
		if ($line -like "Intel(R) Virtualization Technology*") # Enabled / Disabled
		{
			$Value = ($line.Substring($line.IndexOf(",") + 1, $line.Length - ($line.IndexOf(",") + 1))).Trim()
			Write-Log "Intel(R) Virtualization Technology: $Value"
			if ($Value -like "*Enable*") { $tsenv.Value("OSDVirtualization") = "Enable" } else { $tsenv.Value("OSDVirtualization") = "Disable" }
		}
		if ($line -like "VTdFeature*") # Enable / Disable
		{
			$Value = ($line.Substring($line.IndexOf(",") + 1, $line.Length - ($line.IndexOf(",") + 1))).Trim()
			Write-Log "VTdFeature: $Value"
			if ($Value -like "*Enable*") { $tsenv.Value("VTdFeature") = "Enable" }
			else { $tsenv.Value("VTdFeature") = "Disable" }
		}
		if ($line -like "SecureBoot*") # Enable / Disable
		{
			$Value = ($line.Substring($line.IndexOf(",") + 1, $line.Length - ($line.IndexOf(",") + 1))).Trim()
			Write-Log "SecureBoot: $Value"
			if ($Value -like "*Enable*") { $tsenv.Value("OSDSecureBoot") = "Enable" } else { $tsenv.Value("OSDSecureBoot") = "Disable" }
		}
		if ($line -like "Secure Boot*") # Enabled / Disabled
		{
			$Value = ($line.Substring($line.IndexOf(",") + 1, $line.Length - ($line.IndexOf(",") + 1))).Trim()
			Write-Log "Secure Boot: $Value"
			if ($Value -like "*Enable*") { $tsenv.Value("OSDSecureBoot") = "Enable" } else { $tsenv.Value("OSDSecureBoot") = "Disable" }
		}
		if ($line -like "HyperThreadingTechnology*") # Enable / Disable
		{
			$Value = ($line.Substring($line.IndexOf(",") + 1, $line.Length - ($line.IndexOf(",") + 1))).Trim()
			Write-Log "HyperThreadingTechnology: $Value"
			if ($Value -like "*Enable*") { $tsenv.Value("OSDHyperThreading") = "Enable" } else { $tsenv.Value("OSDHyperThreading") = "Disable" }
		}
		if ($line -like "RAIDMode*") # Enable / Disable
		{
			$Value = ($line.Substring($line.IndexOf(",") + 1, $line.Length - ($line.IndexOf(",") + 1))).Trim()
			Write-Log "RAIDMode: $Value"
			if ($Value -like "*Enable*") { $tsenv.Value("OSDRAIDMode") = "Enable" } else { $tsenv.Value("OSDRAIDMode") = "Disable" }
		}
		if ($line -like "WakeByThunderbolt*") # Enable / Disable
		{
			$Value = ($line.Substring($line.IndexOf(",") + 1, $line.Length - ($line.IndexOf(",") + 1))).Trim()
			Write-Log "WakeByThunderbolt: $Value"
			if ($Value -like "*Enable*") { $tsenv.Value("WakeByThunderbolt") = "Enable" } else { $tsenv.Value("WakeByThunderbolt") = "Disable" }
		}
		if ($line -like "ThunderboltSecurityLevel*") # User Authorization / Disable / NoSecurity
		{
			$Value = ($line.Substring($line.IndexOf(",") + 1, $line.Length - ($line.IndexOf(",") + 1))).Trim()
			Write-Log "ThunderboltSecurityLevel: $Value"
			if ($Value -like "*NoSecurity*") { $tsenv.Value("ThunderboltSecurityLevel") = "Enable" } else { $tsenv.Value("ThunderboltSecurityLevel") = "Disable" }
		}
		if ($line -like "PreBootForThunderboltDevice*") # Enable / Disable
		{
			$Value = ($line.Substring($line.IndexOf(",") + 1, $line.Length - ($line.IndexOf(",") + 1))).Trim()
			Write-Log "PreBootForThunderboltDevice: $Value"
			if ($Value -like "*Enable*") { $tsenv.Value("PreBootForThunderboltDevice") = "Enable" } else { $tsenv.Value("PreBootForThunderboltDevice") = "Disable" }
		}
		if ($line -like "PreBootForThunderboltUSBDevice*") # Enable / Disable
		{
			$Value = ($line.Substring($line.IndexOf(",") + 1, $line.Length - ($line.IndexOf(",") + 1))).Trim()
			Write-Log "PreBootForThunderboltUSBDevice: $Value"
			if ($Value -like "*Enable*") { $tsenv.Value("PreBootForThunderboltUSBDevice") = "Enable" } else { $tsenv.Value("PreBootForThunderboltUSBDevice") = "Disable" }
		}
		if ($line -like "AlwaysOnUSB*") # Enable / Disable
		{
			$Value = ($line.Substring($line.IndexOf(",") + 1, $line.Length - ($line.IndexOf(",") + 1))).Trim()
			Write-Log "AlwaysOnUSB: $Value"
			if ($Value -like "*Enable*") { $tsenv.Value("AlwaysOnUSB") = "Enable" } else { $tsenv.Value("AlwaysOnUSB") = "Disable" }
		}
		if ($line -like "SGXControl*") # Enable / SoftwareControl
		{
			$Value = ($line.Substring($line.IndexOf(",") + 1, $line.Length - ($line.IndexOf(",") + 1))).Trim()
			Write-Log "SGXControl: $Value"
			if ($Value -like "*SoftwareControl*") { $tsenv.Value("SGXControl") = "Enable" } else { $tsenv.Value("SGXControl") = "Disable" }
		}
		if ($line -like "AdaptiveThermalManagementAC*") # MaximizePerformance / Balanced
		{
			$Value = ($line.Substring($line.IndexOf(",") + 1, $line.Length - ($line.IndexOf(",") + 1))).Trim()
			Write-Log "AdaptiveThermalManagementAC: $Value"
			if ($Value -like "*Balanced*") { $tsenv.Value("AdaptiveThermalManagementAC") = "Enable" } else { $tsenv.Value("AdaptiveThermalManagementAC") = "Disable" }
		}
		if ($line -like "WirelessAutoDisconnection*") # Enable / Disable
		{
			$Value = ($line.Substring($line.IndexOf(",") + 1, $line.Length - ($line.IndexOf(",") + 1))).Trim()
			Write-Log "WirelessAutoDisconnection: $Value"
			if ($Value -like "*Enable*") { $tsenv.Value("WirelessAutoDisconnection") = "Enable" } else { $tsenv.Value("WirelessAutoDisconnection") = "Disable" }
		}
		if ($line -like "MACAddressPassThrough*") # Enable / Disable
		{
			$Value = ($line.Substring($line.IndexOf(",") + 1, $line.Length - ($line.IndexOf(",") + 1))).Trim()
			Write-Log "MACAddressPassThrough: $Value"
			if ($Value -like "*Enable*") { $tsenv.Value("MACAddressPassThrough") = "Enable" } else { $tsenv.Value("MACAddressPassThrough") = "Disable" }
		}
		if ($line -like "BIOSUpdateByEndUsers*") # Enable / Disable
		{
			$Value = ($line.Substring($line.IndexOf(",") + 1, $line.Length - ($line.IndexOf(",") + 1))).Trim()
			Write-Log "BIOSUpdateByEndUsers: $Value"
			if ($Value -like "*Enable*") { $tsenv.Value("BIOSUpdateByEndUsers") = "Enable" } else { $tsenv.Value("BIOSUpdateByEndUsers") = "Disable" }
		}
		if ($line -like "PhysicalPresenceForTpmProvision*") # Enable / Disable
		{
			$Value = ($line.Substring($line.IndexOf(",") + 1, $line.Length - ($line.IndexOf(",") + 1))).Trim()
			Write-Log "PhysicalPresenceForTpmProvision: $Value"
			if ($Value -like "*Enable*") { $tsenv.Value("PhysicalPresenceForTpmProvision") = "Enable" } else { $tsenv.Value("PhysicalPresenceForTpmProvision") = "Disable" }
		}
		if ($line -like "PhysicalPresenceForTpmClear*") # Enable / Disable
		{
			$Value = ($line.Substring($line.IndexOf(",") + 1, $line.Length - ($line.IndexOf(",") + 1))).Trim()
			Write-Log "PhysicalPresenceForTpmClear: $Value"
			if ($Value -like "*Enable*") { $tsenv.Value("PhysicalPresenceForTpmClear") = "Enable" } else { $tsenv.Value("PhysicalPresenceForTpmClear") = "Disable" }
		}
		if ($line -like "ThunderboltBIOSAssistModer*") # Enable / Disable
		{
			$Value = ($line.Substring($line.IndexOf(",") + 1, $line.Length - ($line.IndexOf(",") + 1))).Trim()
			Write-Log "ThunderboltBIOSAssistMode: $Value"
			if ($Value -like "*Enable*") { $tsenv.Value("ThunderboltBIOSAssistMode") = "Enable" }	else { $tsenv.Value("ThunderboltBIOSAssistMode") = "Disable" }
		}
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
	
	# BIOS Version
	$Value = (Get-WmiObject win32_bios).SMBIOSBIOSVersion
	$tsenv.Value("OSDBIOSVersion") = $Value
	Write-Log "BIOS Version: $Value"
	
	$BIOSFile = [System.IO.File]::OpenText("$Bios_Settings")
	if ($BIOSFile -eq $null) { Write-Log "Error extracting BIOS settings" }
	while ($null -ne ($line = $BIOSFile.ReadLine()))
	{
		# TPM Device
		if ($line -like "*tpm=*") # on / off
		{
			$Value = $line.Substring($line.IndexOf("=") + 1).Trim()
			Write-Log "TPM Device: $Value"
			if ($Value -like "*on*") { $tsenv.Value("OSDTPMDevice") = "Available" } else { $tsenv.Value("OSDTPMDevice") = "Hidden" }
		}
		# TPM State
		if ($line -like "*tpmactivation=*") # activated / deactivated / or Enabled / Disabled
		{
			$Value = $line.Substring($line.IndexOf("=") + 1).Trim()
			Write-Log "TPM State: $Value"
			if (($Value -like "activate*") -or ($Value -like "Enabled*")) { $tsenv.Value("OSDTPMState") = "Active" } else { $tsenv.Value("OSDTPMState") = "Disable" }
		}
		# Secure Boot
		if ($line -like "*secureboot=*") # enable / disable
		{
			$Value = $line.Substring($line.IndexOf("=") + 1).Trim()
			Write-Log "Secure Boot: $Value"
			if ($Value -like "*enable*") { $tsenv.Value("OSDSecureBoot") = "Enable" } else { $tsenv.Value("OSDSecureBoot") = "Disable" }
		}
		# LAN / WLAN Auto Switching
		if ($line -like "*wirelesswitchnlanctrl=*") # enable / disable
		{
			$Value = $line.Substring($line.IndexOf("=") + 1).Trim()
			Write-Log "LAN / WLAN Auto Switching: $Value"
			if ($Value -like "*enable*") { $tsenv.Value("OSDLANWANSwitch") = "Enable" } else { $tsenv.Value("OSDLANWANSwitch") = "Disable" }
		}
		# Hyperthreading
		if ($line -like "*logicproc=*") # enable / disable
		{
			$Value = $line.Substring($line.IndexOf("=") + 1).Trim()
			Write-Log "Hyperthreading: $Value"
			if ($Value -like "*enable*") { $tsenv.Value("OSDHyperThreading") = "Enable" } else { $tsenv.Value("OSDHyperThreading") = "Disable" }
		}
		# Virtualization
		if ($line -like "*virtualization=*") # enable / disable
		{
			$Value = $line.Substring($line.IndexOf("=") + 1).Trim()
			Write-Log "Virtualization: $Value"
			if ($Value -like "*enable*") { $tsenv.Value("OSDVirtualization") = "Enable" } else { $tsenv.Value("OSDVirtualization") = "Disable" }
		}
		# RAID mode AHCI / Other
		if ($line -like "*embsataraid=*") # ahci / other
		{
			$Value = $line.Substring($line.IndexOf("=") + 1).Trim()
			Write-Log "RAID Mode: $Value"
			if ($Value -like "*ahci*") { $tsenv.Value("OSDRAIDMode") = "ahci" } else { $tsenv.Value("OSDRAIDMode") = $Value }
		}
	}
}


if (($Manufacturer -like "*Hewlett*") -or ($Manufacturer -like "*HP*"))
{
	Write-Log "Found manufacturer to be Hewlett Packard, extracting BIOS to file"
	If ((Get-CimInStance Win32_OperatingSystem).OSArchitecture -like "*64-Bit*") { $BIOSConfigTool = "$ParentDirectory\Tools\HP\BiosConfigUtility64.exe"; Write-Log "OS Architecture is 64-bit" }
	Else { $BIOSConfigTool = "$ParentDirectory\Tools\HP\BiosConfigUtility.exe"; Write-Log "OS Architecture is 32-bit"	}
	Write-Log "BIOS Config Tool Path: $BIOSConfigTool"
	$Process = Start-Process -FilePath "$BIOSConfigTool" -ArgumentList "/Get:`"$Bios_Settings`"" -NoNewWindow -Wait -PassThru
	$ErrorCode = $Process.ExitCode
	Write-Log "Getting BIOS settings with exit code: $ErrorCode"
	
	# BIOS Version
	$Value = (Get-WmiObject win32_bios).SMBIOSBIOSVersion
	$tsenv.Value("OSDBIOSVersion") = $Value
	Write-Log "BIOS Version: $Value"
	
	$RetryCounter = 5
	$BIOSExtractionStatus = $false
	while (($RetryCounter -ne 0) -and ($BIOSExtractionStatus -eq $false))
	{
		$BIOSFile = [System.IO.File]::OpenText("$Bios_Settings")
		while ($null -ne ($line = $BIOSFile.ReadLine()))
		{
			if (($line -like "*;*") -and ($line -like "*Found*"))
			{
				$SettingsNumber = ($line.Substring($line.IndexOf("Found") + 6)).Trim()
				$SettingsNumber = [int](($SettingsNumber.Substring(0, $SettingsNumber.IndexOf("sett") - 1)).Trim())
				if ($SettingsNumber -lt 100)
				{
					Write-Log "Number of settings in BIOS file ($SettingsNumber) to few, rerunning extraction"
					Remove-Item -Path "$Bios_Settings" -Force
					$Process = Start-Process -FilePath "$BIOSConfigTool" -ArgumentList "/Get:`"$Bios_Settings`"" -NoNewWindow -Wait -PassThru
					$ErrorCode = $Process.ExitCode
					Write-Log "Getting BIOS settings with exit code: $ErrorCode"
				}
				else { Write-Log "Number of settings in BIOS file ($SettingsNumber) acceptable, extraction OK"; $BIOSExtractionStatus = $true; break }
			}
		}
		$RetryCounter = $RetryCounter - 1
	}
	
	$BIOSFile = [System.IO.File]::OpenText("$Bios_Settings")
	if ($BIOSFile -eq $null) { Write-Log "Error extracting BIOS settings" }
	while ($null -ne ($line = $BIOSFile.ReadLine()))
	{
		# TPM Device
		if (($line -like "*TPM Device*") -and ($line -notlike "*TPM Device Security*")) # Available / Hidden
		{
			$line = $BIOSFile.ReadLine(); $linetest = [int[]][char[]]$line; if ($linetest -contains [char]42) { $Value = $line.Trim().Substring(1) }
			$line = $BIOSFile.ReadLine(); $linetest = [int[]][char[]]$line; if ($linetest -contains [char]42) { $Value = $line.Trim().Substring(1) }
			Write-Log "TPM Device: $Value"
			if ($Value -like "*Available*") { $tsenv.Value("OSDTPMDevice") = "Available" } else { $tsenv.Value("OSDTPMDevice") = "Hidden" }
		}
		# TPM State
		if ($line -like "*TPM State*") # Enable / Disable
		{
			$line = $BIOSFile.ReadLine(); $linetest = [int[]][char[]]$line; if ($linetest -contains [char]42) { $Value = $line.Trim().Substring(1) }
			$line = $BIOSFile.ReadLine(); $linetest = [int[]][char[]]$line; if ($linetest -contains [char]42) { $Value = $line.Trim().Substring(1) }
			Write-Log "TPM State: $Value"
			if ($Value -like "*Enable*") { $tsenv.Value("OSDTPMState") = "Active" } else { $tsenv.Value("OSDTPMState") = "Disable" }
		}
		# Network (PXE)
		if ($line -like "*Network (PXE) Boot*") # Enable / Disable
		{
			$line = $BIOSFile.ReadLine(); $linetest = [int[]][char[]]$line; if ($linetest -contains [char]42) { $Value = $line.Trim().Substring(1) }
			$line = $BIOSFile.ReadLine(); $linetest = [int[]][char[]]$line; if ($linetest -contains [char]42) { $Value = $line.Trim().Substring(1) }
			Write-Log "Network (PXE) Boot: $Value"
			if ($Value -like "*Enable*") { $tsenv.Value("OSDPXEBoot") = "Enable" } else { $tsenv.Value("OSDPXEBoot") = "Disable" }
		}
		if ($line -like "*PXE Internal NIC boot*") # Enable / Disable
		{
			$line = $BIOSFile.ReadLine(); $linetest = [int[]][char[]]$line; if ($linetest -contains [char]42) { $Value = $line.Trim().Substring(1) }
			$line = $BIOSFile.ReadLine(); $linetest = [int[]][char[]]$line; if ($linetest -contains [char]42) { $Value = $line.Trim().Substring(1) }
			Write-Log "PXE Internal NIC boot: $Value"
			if ($Value -like "*Enable*") { $tsenv.Value("OSDPXEBoot") = "Enable" }
			else { $tsenv.Value("OSDPXEBoot") = "Disable" }
		}
		if ($line -like "*PXE Internal IPV4 NIC boot*") # Enable / Disable
		{
			$line = $BIOSFile.ReadLine(); $linetest = [int[]][char[]]$line; if ($linetest -contains [char]42) { $Value = $line.Trim().Substring(1) }
			$line = $BIOSFile.ReadLine(); $linetest = [int[]][char[]]$line; if ($linetest -contains [char]42) { $Value = $line.Trim().Substring(1) }
			Write-Log "PXE Internal IPV4 NIC boot: $Value"
			if ($Value -like "*Enable*") { $tsenv.Value("OSDPXEBoot") = "Enable" }
			else { $tsenv.Value("OSDPXEBoot") = "Disable" }
		}
		# Legacy Boot Options
#		if ($line -like "*Legacy Boot Options*") # Enable / Disable
#		{
#			$line = $BIOSFile.ReadLine(); $linetest = [int[]][char[]]$line; if ($linetest -contains [char]42) { $Value = $line.Trim().Substring(1) }
#			$line = $BIOSFile.ReadLine(); $linetest = [int[]][char[]]$line; if ($linetest -contains [char]42) { $Value = $line.Trim().Substring(1) }
#			Write-Log "Legacy Boot Options: $Value"
#			if ($Value -like "*Enable*") { $tsenv.Value("OSDLegacyBoot") = "Enable" } else { $tsenv.Value("OSDLegacyBoot") = "Disable" }
#		}
		# UEFI / Legacy
		if ($line -like "*UEFI Boot Options*") # Enable / Disable
		{
			$line = $BIOSFile.ReadLine(); $linetest = [int[]][char[]]$line; if ($linetest -contains [char]42) { $Value = $line.Trim().Substring(1) }
			$line = $BIOSFile.ReadLine(); $linetest = [int[]][char[]]$line; if ($linetest -contains [char]42) { $Value = $line.Trim().Substring(1) }
			Write-Log "UEFI Boot Options: $Value"
			if ($Value -like "*Enable*") { $tsenv.Value("OSDUEFIBoot") = "Enable" }	else { $tsenv.Value("OSDUEFIBoot") = "Disable" }
		}
		# LAN / WLAN Auto Switching
		if ($line -like "*LAN / WLAN Auto Switching*") # Enable / Disable
		{
			$line = $BIOSFile.ReadLine(); $linetest = [int[]][char[]]$line; if ($linetest -contains [char]42) { $Value = $line.Trim().Substring(1) }
			$line = $BIOSFile.ReadLine(); $linetest = [int[]][char[]]$line; if ($linetest -contains [char]42) { $Value = $line.Trim().Substring(1) }
			Write-Log "LAN / WLAN Auto Switching: $Value"
			if ($Value -like "*Enable*") { $tsenv.Value("OSDLANWANSwitch") = "Enable" } else { $tsenv.Value("OSDLANWANSwitch") = "Disable" }
		}
		# Configure Legacy Support and Secure Boot
		if ($line -like "*Configure Legacy Support and Secure Boot*") # Legacy Support Enable and Secure Boot Disable / Legacy Support Disable and Secure Boot Enable / Legacy Support Disable and Secure Boot Disable
		{
			$line = $BIOSFile.ReadLine(); $linetest = [int[]][char[]]$line; if ($linetest -contains [char]42) { $Value = $line.Trim().Substring(1) }
			$line = $BIOSFile.ReadLine(); $linetest = [int[]][char[]]$line; if ($linetest -contains [char]42) { $Value = $line.Trim().Substring(1) }
			Write-Log "Configure Legacy Support and Secure Boot: $Value"
			if ($Value -like "*Legacy Support Enable and Secure Boot Disable*") { $tsenv.Value("OSDSecureBoot") = "Disable" }
			elseif ($Value -like "*Legacy Support Disable and Secure Boot Enable*") { $tsenv.Value("OSDSecureBoot") = "Enable" }
			elseif ($Value -like "*Legacy Support Disable and Secure Boot Disable*") { $tsenv.Value("OSDSecureBoot") = "Disable" }
		}
		# Hyperthreading
		if ($line -like "*Hyperthreading*") # Enable / Disable
		{
			$line = $BIOSFile.ReadLine(); $linetest = [int[]][char[]]$line; if ($linetest -contains [char]42) { $Value = $line.Trim().Substring(1) }
			$line = $BIOSFile.ReadLine(); $linetest = [int[]][char[]]$line; if ($linetest -contains [char]42) { $Value = $line.Trim().Substring(1) }
			Write-Log "Hyperthreading: $Value"
			if ($Value -like "*Enable*") { $tsenv.Value("OSDHyperThreading") = "Enable" } elseif ($Value -like "*Disable*") { $tsenv.Value("OSDHyperThreading") = "Disable" } else { $tsenv.Value("OSDHyperThreading") = "NotExist" }
		}
		# Virtualization Technology (VTx)
		if (($line -like "*Virtualization Technology (VTx)*") -and ($line -notlike "*Virtualization Technology (VTx) Security*")) # Enable / Disable
		{
			$line = $BIOSFile.ReadLine(); $linetest = [int[]][char[]]$line; if ($linetest -contains [char]42) { $Value = $line.Trim().Substring(1) }
			$line = $BIOSFile.ReadLine(); $linetest = [int[]][char[]]$line; if ($linetest -contains [char]42) { $Value = $line.Trim().Substring(1) }
			Write-Log "Virtualization Technology (VTx): $Value"
			if ($Value -like "*Enable*") { $tsenv.Value("OSDVirtualization") = "Enable" } else { $tsenv.Value("OSDVirtualization") = "Disable" }
		}
		# TPM Activation Policy
		if (($line -like "*TPM Activation Policy*") -or ($line -like "*Embedded Security Activation Policy*")) # F1 to boot / Allow user to reject / No prompts
		{
			$line = $BIOSFile.ReadLine(); $linetest = [int[]][char[]]$line; if ($linetest -contains [char]42) { $Value = $line.Trim().Substring(1) }
			$line = $BIOSFile.ReadLine(); $linetest = [int[]][char[]]$line; if ($linetest -contains [char]42) { $Value = $line.Trim().Substring(1) }
			$line = $BIOSFile.ReadLine(); $linetest = [int[]][char[]]$line; if ($linetest -contains [char]42) { $Value = $line.Trim().Substring(1) }
			Write-Log "TPM Activation Policy: $Value"
			if ($Value -like "*No prompts*") { $tsenv.Value("TPMActivationPolicy") = "Enable" } else { $tsenv.Value("TPMActivationPolicy") = "Disable" }
		}
		# Fast Boot
		if (($line -like "*Fast Boot*") -and ($line -notlike "*Fast Boot Security*")) # Enable / Disable
		{
			$line = $BIOSFile.ReadLine(); $linetest = [int[]][char[]]$line; if ($linetest -contains [char]42) { $Value = $line.Trim().Substring(1) }
			$line = $BIOSFile.ReadLine(); $linetest = [int[]][char[]]$line; if ($linetest -contains [char]42) { $Value = $line.Trim().Substring(1) }
			Write-Log "Fast Boot: $Value"
			if ($Value -like "*Enable*") { $tsenv.Value("FastBoot") = "Enable" } else { $tsenv.Value("FastBoot") = "Disable" }
		}
		if (($line -like "*Reset of TPM from OS*") -and ($line -notlike "*Reset of TPM from OS Security Level*")) # Enable / Disable
		{
			$line = $BIOSFile.ReadLine(); $linetest = [int[]][char[]]$line; if ($linetest -contains [char]42) { $Value = $line.Trim().Substring(1) }
			$line = $BIOSFile.ReadLine(); $linetest = [int[]][char[]]$line; if ($linetest -contains [char]42) { $Value = $line.Trim().Substring(1) }
			Write-Log "Reset of TPM from OS: $Value"
			if ($Value -like "*Enable*") { $tsenv.Value("OSDTPMResetFromOS") = "Enable" }
			else { $tsenv.Value("OSDTPMResetFromOS") = "Disable" }
		}
		if (($line -like "*SecureBoot*") -and ($line -notlike "*SecureBoot Security*")) # Enable / Disable
		{
			$line = $BIOSFile.ReadLine(); $linetest = [int[]][char[]]$line; if ($linetest -contains [char]42) { $Value = $line.Trim().Substring(1) }
			$line = $BIOSFile.ReadLine(); $linetest = [int[]][char[]]$line; if ($linetest -contains [char]42) { $Value = $line.Trim().Substring(1) }
			Write-Log "SecureBoot: $Value"
			if ($Value -like "*Enable*") { $tsenv.Value("OSDSecureBoot") = "Enable" }
			else { $tsenv.Value("OSDSecureBoot") = "Disable" }
		}
		if (($line -like "*Boot Mode*") -and ($line -notlike "*Boot Mode Security*")) # Enable / Disable
		{
			$line = $BIOSFile.ReadLine(); $linetest = [int[]][char[]]$line; if ($linetest -contains [char]42) { $Value = $line.Trim().Substring(1) }
			$line = $BIOSFile.ReadLine(); $linetest = [int[]][char[]]$line; if ($linetest -contains [char]42) { $Value = $line.Trim().Substring(1) }
			Write-Log "Boot Mode: $Value"
			if ($Value -like "*Legacy*") { $tsenv.Value("OSDLegacyBoot") = "Enable"; $tsenv.Value("OSDUEFIBoot") = "Disable" }
			elseif ($Value -like "*UEFI Hybrid (With CSM)*") { $tsenv.Value("OSDLegacyBoot") = "Disable"; $tsenv.Value("OSDUEFIBoot") = "Enable" }
			else { $tsenv.Value("OSDLegacyBoot") = "Disable"; $tsenv.Value("OSDUEFIBoot") = "Enable" }
		}
		if (($line -like "*Customized Boot*") -and ($line -notlike "*Customized Boot Security*")) # Enable / Disable
		{
			$line = $BIOSFile.ReadLine(); $linetest = [int[]][char[]]$line; if ($linetest -contains [char]42) { $Value = $line.Trim().Substring(1) }
			$line = $BIOSFile.ReadLine(); $linetest = [int[]][char[]]$line; if ($linetest -contains [char]42) { $Value = $line.Trim().Substring(1) }
			Write-Log "Boot Mode: $Value"
			if ($Value -like "*Enable*") { $tsenv.Value("OSDCustomizedBoot") = "Enable" }
			else { $tsenv.Value("OSDCustomizedBoot") = "Disable" }
		}
		
	}
}

# Hyper-V
if ($Manufacturer -like "*Microsoft Corporation*")
{
	$ModelFriendlyName = (Get-WmiObject Win32_ComputerSystem).Model.TrimEnd()
	if ($ModelFriendlyName -like "*Virtual Machine*") {	$tsenv.Value("OSDVirtualMachine") = $true }
}

# VMware
if ($Manufacturer -like "*VMware*")
{
	$ModelFriendlyName = (Get-WmiObject Win32_ComputerSystem).Model.TrimEnd()
	if ($ModelFriendlyName -like "*VMware Virtual*") { $tsenv.Value("OSDVirtualMachine") = $true }
}

# Determine if BIOS must be changed
Write-Log "Determine if BIOS needs changing"
if ($tsenv.Value("OSDVirtualMachine") -eq $false)
{
	$tsenv.Value("OSDSetBIOS") = $false
	if (($tsenv.Value("OSDBitlocker") -eq $true) -and ($tsenv.Value("OSDTPMState") -eq "Disable")) { $tsenv.Value("OSDSetBIOS") = $true; Write-Log "TPM not Active and Bitlocker used - BIOS change necessary" }
	if (($tsenv.Value("OSDPXEBoot") -eq "Disable") -and ($tsenv.Value("OSDPXEBoot") -ne "NotExist")) { $tsenv.Value("OSDSetBIOS") = $true; Write-Log "PXE Boot not enabled - BIOS change necessary" }
	if (($tsenv.Value("OSDUEFIBoot") -eq "Disable") -and ($tsenv.Value("OSDUEFIBoot") -ne "NotExist")) { $tsenv.Value("OSDSetBIOS") = $true; Write-Log "UEFI Boot not enabled - BIOS change necessary" }
	if (($tsenv.Value("OSDLANWANSwitch") -eq "Disable") -and ($tsenv.Value("OSDLANWANSwitch") -ne "NotExist")) { $tsenv.Value("OSDSetBIOS") = $true; Write-Log "LAN / WLAN Auto Switching not enabled - BIOS change necessary" }
	if (($tsenv.Value("OSDTPMDevice") -ne "Available") -and ($tsenv.Value("OSDTPMDevice") -ne "NotExist")) { $tsenv.Value("OSDSetBIOS") = $true; Write-Log "TPM chip not visible - BIOS change necessary" }
	
	if ($tsenv.Value("OSDOSVersion") -eq "WIN10X64")
	{
		if (($tsenv.Value("OSDSecureBoot") -eq "Disable") -and ($tsenv.Value("OSDSecureBoot") -ne "NotExist")) { $tsenv.Value("OSDSetBIOS") = $true; Write-Log "Secure Boot not enabled - BIOS change necessary" }
		if (($tsenv.Value("OSDLegacyBoot") -eq "Disable") -and ($tsenv.Value("OSDLegacyBoot") -ne "NotExist")) { $tsenv.Value("OSDSetBIOS") = $true; Write-Log "Legacy Boot not disabled - BIOS change necessary" }
	}
	if ($tsenv.Value("OSDOSVersion") -eq "WIN7X64")
	{
		if (($tsenv.Value("OSDSecureBoot") -eq "Enable") -and ($tsenv.Value("OSDSecureBoot") -ne "NotExist")) { $tsenv.Value("OSDSetBIOS") = $true; Write-Log "Secure Boot enabled (Windows 7) - BIOS change necessary" }
		if (($tsenv.Value("OSDLegacyBoot") -eq "Enable") -and ($tsenv.Value("OSDLegacyBoot") -ne "NotExist")) { $tsenv.Value("OSDSetBIOS") = $true; Write-Log "Legacy Boot disabled (Windows 7) - BIOS change necessary" }
	}
	
	if (($tsenv.Value("OSDHyperThreading") -eq "Disable") -and ($tsenv.Value("OSDHyperThreading") -ne "NotExist")) { $tsenv.Value("OSDSetBIOS") = $true; Write-Log "Hyperthreading not enabled - BIOS change necessary" }
	if (($tsenv.Value("OSDVirtualization") -eq "Disable") -and ($tsenv.Value("OSDVirtualization") -ne "NotExist")) { $tsenv.Value("OSDSetBIOS") = $true; Write-Log "Virtualization not enabled - BIOS change necessary" }
	if (($tsenv.Value("VTdFeature") -eq "Disable") -and ($tsenv.Value("VTdFeature") -ne "NotExist")) { $tsenv.Value("OSDSetBIOS") = $true; Write-Log "VTdFeature not enabled - BIOS change necessary" }
	if (($tsenv.Value("OSDRAIDMode") -eq "Enable") -and ($tsenv.Value("OSDRAIDMode") -ne "NotExist")) { $tsenv.Value("OSDSetBIOS") = $true; Write-Log "Virtualization not enabled - BIOS change necessary" }
	if (($tsenv.Value("WakeByThunderbolt") -eq "Disable") -and ($tsenv.Value("WakeByThunderbolt") -ne "NotExist")) { $tsenv.Value("OSDSetBIOS") = $true; Write-Log "WakeByThunderbolt not enabled - BIOS change necessary" }
	if (($tsenv.Value("ThunderboltSecurityLevel") -eq "Disable") -and ($tsenv.Value("ThunderboltSecurityLevel") -ne "NotExist")) { $tsenv.Value("OSDSetBIOS") = $true; Write-Log "ThunderboltSecurityLevel not enabled - BIOS change necessary" }
	if (($tsenv.Value("PreBootForThunderboltDevice") -eq "Disable") -and ($tsenv.Value("PreBootForThunderboltDevice") -ne "NotExist")) { $tsenv.Value("OSDSetBIOS") = $true; Write-Log "PreBootForThunderboltDevice not enabled - BIOS change necessary" }
	if (($tsenv.Value("PreBootForThunderboltUSBDevice") -eq "Disable") -and ($tsenv.Value("PreBootForThunderboltUSBDevice") -ne "NotExist")) { $tsenv.Value("OSDSetBIOS") = $true; Write-Log "PreBootForThunderboltUSBDevice not enabled - BIOS change necessary" }
	if (($tsenv.Value("AlwaysOnUSB") -eq "Disable") -and ($tsenv.Value("AlwaysOnUSB") -ne "NotExist")) { $tsenv.Value("OSDSetBIOS") = $true; Write-Log "AlwaysOnUSB not disabled - BIOS change necessary" }
	if (($tsenv.Value("TPMActivationPolicy") -eq "Disable") -and ($tsenv.Value("TPMActivationPolicy") -ne "NotExist")) { $tsenv.Value("OSDSetBIOS") = $true; Write-Log "TPM Activation policy is not silent - BIOS change necessary" }
	if (($tsenv.Value("SGXControl") -eq "Disable") -and ($tsenv.Value("SGXControl") -ne "NotExist")) { $tsenv.Value("OSDSetBIOS") = $true; Write-Log "SGXControl is not enabled - BIOS change necessary" }
	if (($tsenv.Value("AdaptiveThermalManagementAC") -eq "Disable") -and ($tsenv.Value("AdaptiveThermalManagementAC") -ne "NotExist")) { $tsenv.Value("OSDSetBIOS") = $true; Write-Log "AdaptiveThermalManagementAC is set to maximum - BIOS change necessary" }
	if (($tsenv.Value("WirelessAutoDisconnection") -eq "Disable") -and ($tsenv.Value("WirelessAutoDisconnection") -ne "NotExist")) { $tsenv.Value("OSDSetBIOS") = $true; Write-Log "WirelessAutoDisconnection is set to disabled - BIOS change necessary" }
	if (($tsenv.Value("MACAddressPassThrough") -eq "Disable") -and ($tsenv.Value("MACAddressPassThrough") -ne "NotExist")) { $tsenv.Value("OSDSetBIOS") = $true; Write-Log "MACAddressPassThrough is set to disabled - BIOS change necessary" }
	if (($tsenv.Value("FastBoot") -eq "Enable") -and ($tsenv.Value("FastBoot") -ne "NotExist")) { $tsenv.Value("OSDSetBIOS") = $true; Write-Log "Fast Boot is set to enabled - BIOS change necessary" }
	if (($tsenv.Value("BIOSUpdateByEndUsers") -eq "Disable") -and ($tsenv.Value("BIOSUpdateByEndUsers") -ne "NotExist")) { $tsenv.Value("OSDSetBIOS") = $true; Write-Log "BIOSUpdateByEndUsers is set to disabled - BIOS change necessary" }
	if (($tsenv.Value("PhysicalPresenceForTpmProvision") -eq "Enable") -and ($tsenv.Value("PhysicalPresenceForTpmProvision") -ne "NotExist")) { $tsenv.Value("OSDSetBIOS") = $true; Write-Log "PhysicalPresenceForTpmProvision is set to enabled - BIOS change necessary" }
	if (($tsenv.Value("PhysicalPresenceForTpmClear") -eq "Enable") -and ($tsenv.Value("PhysicalPresenceForTpmClear") -ne "NotExist")) { $tsenv.Value("OSDSetBIOS") = $true; Write-Log "PhysicalPresenceForTpmClear is set to enabled - BIOS change necessary" }
	if (($tsenv.Value("OSDTPMResetFromOS") -eq "Disable") -and ($tsenv.Value("OSDTPMResetFromOS") -ne "NotExist")) { $tsenv.Value("OSDSetBIOS") = $true; Write-Log "OSDTPMResetFromOS is set to disabled - BIOS change necessary" }
	if (($tsenv.Value("OSDCustomizedBoot") -eq "Disable") -and ($tsenv.Value("OSDCustomizedBoot") -ne "NotExist")) { $tsenv.Value("OSDSetBIOS") = $true; Write-Log "Customized Boot is set to disabled - BIOS change necessary" }
	if (($tsenv.Value("ThunderboltBIOSAssistMode") -eq "Disable") -and ($tsenv.Value("ThunderboltBIOSAssistMode") -ne "NotExist")) { $tsenv.Value("OSDSetBIOS") = $true; Write-Log "Thunderbolt BIOS Assist Mode is set to disabled - BIOS change necessary" }
	
	# List Non-Exixting Values
	if ($tsenv.Value("OSDTPMDevice") -eq "NotExist") { Write-Log "Non-existing value in BIOS: TPM Device Value" }
	if ($tsenv.Value("OSDTPMState") -eq "NotExist") { Write-Log "Non-existing value in BIOS: TPM State Value" }
	if ($tsenv.Value("OSDPXEBoot") -eq "NotExist") { Write-Log "Non-existing value in BIOS: PXE Boot enable" }
	if ($tsenv.Value("OSDLegacyBoot") -eq "NotExist") { Write-Log "Non-existing value in BIOS: Legacy Boot disable" }
	if ($tsenv.Value("OSDUEFIBoot") -eq "NotExist") { Write-Log "Non-existing value in BIOS: UEFI Boot enable" }
	if ($tsenv.Value("OSDLANWANSwitch") -eq "NotExist") { Write-Log "Non-existing value in BIOS: LAN / WAN auto-switch " }
	if ($tsenv.Value("OSDSecureBoot") -eq "NotExist") { Write-Log "Non-existing value in BIOS: Secure Boot enable" }
	if ($tsenv.Value("OSDHyperThreading") -eq "NotExist") { Write-Log "Non-existing value in BIOS: Hyperthreading" }
	if ($tsenv.Value("OSDVirtualization") -eq "NotExist") { Write-Log "Non-existing value in BIOS: Virtualization" }
	if ($tsenv.Value("VTdFeature") -eq "NotExist") { Write-Log "Non-existing value in BIOS: VTdFeature" }
	if ($tsenv.Value("TPMActivationPolicy") -eq "NotExist") { Write-Log "Non-existing value in BIOS: TPM Activation Policy" }
	if ($tsenv.Value("SGXControl") -eq "NotExist") { Write-Log "Non-existing value in BIOS: SGXControl" }
	if ($tsenv.Value("AdaptiveThermalManagementAC") -eq "NotExist") { Write-Log "Non-existing value in BIOS: AdaptiveThermalManagementAC" }
	if ($tsenv.Value("WirelessAutoDisconnection") -eq "NotExist") { Write-Log "Non-existing value in BIOS: WirelessAutoDisconnection" }
	if ($tsenv.Value("MACAddressPassThrough") -eq "NotExist") { Write-Log "Non-existing value in BIOS: MACAddressPassThrough" }
	if ($tsenv.Value("Fast Boot") -eq "NotExist") { Write-Log "Non-existing value in BIOS: Fast Boot" }
	if ($tsenv.Value("BIOSUpdateByEndUsers") -eq "NotExist") { Write-Log "Non-existing value in BIOS: BIOSUpdateByEndUsers" }
	if ($tsenv.Value("PhysicalPresenceForTpmProvision") -eq "NotExist") { Write-Log "Non-existing value in BIOS: PhysicalPresenceForTpmProvision" }
	if ($tsenv.Value("PhysicalPresenceForTpmClear") -eq "NotExist") { Write-Log "Non-existing value in BIOS: PhysicalPresenceForTpmClear" }
	if ($tsenv.Value("OSDTPMResetFromOS") -eq "NotExist") { Write-Log "Non-existing value in BIOS: Reset of TPM from OS" }
	if ($tsenv.Value("OSDCustomizedBoot") -eq "NotExist") { Write-Log "Non-existing value in BIOS: Customized Boot" }
	if ($tsenv.Value("ThunderboltBIOSAssistMode") -eq "NotExist") { Write-Log "Non-existing value in BIOS: ThunderboltBIOSAssistMode" }
	
	if ($tsenv.Value("OSDSetBIOS") -eq $false) { Write-Log "No need to change BIOS - all values set" }
	
	if ($tsenv.Value("OSDTPMState") -eq "Active") { Write-Log "TPM turned on OSDTPMStatus = OK"; $tsenv.Value("OSDTPMStatus") = "OK" }
	elseif ($tsenv.Value("OSDTPMState") -ne "NotExist")	{ Write-Log "TPM NOT turned on OSDTPMStatus = NotOK"	}
	else
	{
		Write-Log "OSDTPMState value not found, checking TPM status with WMI"
		try
		{
			$TPM = Get-WmiObject -Class Win32_TPM -Namespace root\CIMV2\Security\MicrosoftTpm
			$TPMEnabled = $TPM.IsEnabled_InitialValue
			Write-Log "TPM value IsEnabled_InitialValue: $TPMEnabled"
			$TPMActivated = $TPM.IsActivated_InitialValue
			Write-Log "TPM value IsActivated_InitialValue: $TPMActivated"
			if ($TPMActivated -eq $true)
			{
				Write-Log "TPM found to be activated, setting variable OSDTPMState to Active"
				$tsenv.Value("OSDTPMState") = "Active"
			}
			else
			{
				Write-Log "TPM NOT activated, setting variable OSDTPMState to Disable"
				$tsenv.Value("OSDTPMState") = "Disable"
			}
		}
		catch { Write-Log "Error: not able to get TPM status from WMI" }
	}
}
else { Write-Log "Machine is virtual, BIOS settings skipped" }

# Debug
#$OSDTPMDevice = $tsenv.Value("OSDTPMDevice"); Write-Log "OSDTPMDevice: $OSDTPMDevice"
#$OSDTPMState = $tsenv.Value("OSDTPMState"); Write-Log "OSDTPMState: $OSDTPMState"
#$OSDPXEBoot = $tsenv.Value("OSDPXEBoot"); Write-Log "OSDPXEBoot: $OSDPXEBoot"
#$OSDLegacyBoot = $tsenv.Value("OSDLegacyBoot"); Write-Log "OSDLegacyBoot: $OSDLegacyBoot"
#$OSDUEFIBoot = $tsenv.Value("OSDUEFIBoot"); Write-Log "OSDUEFIBoot: $OSDUEFIBoot"
#$OSDLANWANSwitch = $tsenv.Value("OSDLANWANSwitch"); Write-Log "OSDLANWANSwitch: $OSDLANWANSwitch"
#$OSDSecureBoot = $tsenv.Value("OSDSecureBoot"); Write-Log "OSDSecureBoot: $OSDSecureBoot"
#$OSDHyperThreading = $tsenv.Value("OSDHyperThreading"); Write-Log "OSDHyperThreading: $OSDHyperThreading"
#$OSDVirtualization = $tsenv.Value("OSDVirtualization"); Write-Log "OSDVirtualization: $OSDVirtualization"
#$OSDRAIDMode = $tsenv.Value("OSDRAIDMode"); Write-Log "OSDRAIDMode: $OSDRAIDMode"
#$OSDBIOSVersion = $tsenv.Value("OSDBIOSVersion"); Write-Log "OSDBIOSVersion: $OSDBIOSVersion"
#$OSDSetBIOS = $tsenv.Value("OSDSetBIOS"); Write-Log "OSDSetBIOS: $OSDSetBIOS"

