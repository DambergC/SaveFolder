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
function Write-Log ($text)
{
	$global:LogPath = $tsenv.Value("_SMSTSLogPath")
	$global:LogFile = "$LogPath\Installation.log"
	(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName $text" | Out-File -FilePath $LogFile -Append
}
function Mount-ISO ($Image)
{
	if (Test-Path "$Image")
	{
		try
		{
			$MountResult = Mount-DiskImage -ImagePath "$Image" -StorageType ISO -PassThru
			Start-Sleep -Seconds 3
			$DriveLetter = ($MountResult | Get-Volume).DriveLetter
			$DriveLetterFixed = $DriveLetter + ":"
		}
		catch { }
	}
	else { }
	return $DriveLetterFixed
}
function Dismount-ISO ($Image)
{
	try
	{
		$DismountResult = Dismount-DiskImage -ImagePath "$Image"
	}
	catch { }
	return
}
function Dell-ExitCode ($ErrorCode)
{
	switch ($ErrorCode)
	{
		0 { $ErrorMessage = 'Success.' }
		1 { $ErrorMessage = 'Attempt to read write-only parameter `" % s`".' }
		2 { $ErrorMessage = 'Clear SEL cannot be accompanied with any other option.' }
		3 { $ErrorMessage = 'racreset cannot be accompanied with any other option.' }
		4 { $ErrorMessage = 'Cannot execute command `" % s`". Command, or request parameter(s), not supported in present state.' }
		5 { $ErrorMessage = 'Invalid sub net mask.' }
		6 { $ErrorMessage = 'Load defaults cannot be accompanied with any other option.' }
		7 { $ErrorMessage = 'Parameter out of range. One or more parameters in the data field of the Request are out of range.' }
		8 { $ErrorMessage = 'Attempt to write read-only parameter `" % s`".' }
		9 { $ErrorMessage = 'Option `" % s`" requires an argument.' }
		10 { $ErrorMessage = 'The Asset Tag for this system is not available.' }
		11 { $ErrorMessage = 'The Asset Tag cannot be more than %s characters long.' }
		12 { $ErrorMessage = 'The required BIOS interfaces cannot be found on this system.' }
		13 { $ErrorMessage = 'The BIOS version information is not available.' }
		14 { $ErrorMessage = 'There was a problem getting the state byte.' }
		15 { $ErrorMessage = 'The state byte is not available on this system.' }
		16 { $ErrorMessage = 'There was a problem setting the state byte.' }
		17 { $ErrorMessage = 'The state byte must be a value between 0 and 255 decimal.' }
		18 { $ErrorMessage = 'The CPU information is not available.' }
		19 { $ErrorMessage = 'The dependent option `" % s`" required for this subcommand is missing in the command line.' }
		20 { $ErrorMessage = 'Duplicate sub command `" % s`" has been entered.' }
		21 { $ErrorMessage = 'The script file does contain not a valid DTK environment script signature.  (%s)' }
		22 { $ErrorMessage = 'The format of the environment variable is incorrect.' }
		23 { $ErrorMessage = 'The --envar/-s option can only be used for a single option.' }
		24 { $ErrorMessage = 'The --envar/-s option can only be used for report operations.' }
		25 { $ErrorMessage = 'There was an error opening the file %s.' }
		26 { $ErrorMessage = 'File `" % s`" does not have write permission.' }
		27 { $ErrorMessage = 'The file contains invalid option `" % s`".' }
		28 { $ErrorMessage = 'There can only be one section in the input file.' }
		29 { $ErrorMessage = 'Bad ini file, the required section [%s] cannot be found.' }
		30 { $ErrorMessage = 'Report operations and set operations must be separate.' }
		31 { $ErrorMessage = 'Help is not available for the option `" % s`".' }
		32 { $ErrorMessage = 'The -x (--hex) option can only be used with -b or -r.' }
		33 { $ErrorMessage = 'Input file `" % s`" not found.' }
		34 { $ErrorMessage = 'Input file `" % s`" cannot be read.' }
		35 { $ErrorMessage = 'Invalid argument for the provided option `" % s`".' }
		36 { $ErrorMessage = 'The machine ID was not found in the file `" % s`".' }
		37 { $ErrorMessage = 'The system memory information is not available.' }
		38 { $ErrorMessage = 'The output file `" % s`" could not be opened. Please make sure the path exists and the media is not write protected.' }
		39 { $ErrorMessage = 'Could not write to output file, disk may be full.' }
		40 { $ErrorMessage = 'The old password must be provided to set a new password using --ValSysPwd.' }
		41 { $ErrorMessage = 'The old password must be provided to set a new password using --ValSetupPwd.' }
		42 { $ErrorMessage = 'The option `" % s`" is not available or cannot be configured through this tool.' }
		43 { $ErrorMessage = 'There was an error setting the option `" % s`".' }
		44 { $ErrorMessage = 'The -n (--namefile) option can only be used with --pci.' }
		45 { $ErrorMessage = 'The set operation, `" % s`", requires sub commands.' }
		46 { $ErrorMessage = 'The service tag for this system is not available.' }
		47 { $ErrorMessage = 'The system ID value is not available.' }
		48 { $ErrorMessage = 'The system information string is not available.' }
		49 { $ErrorMessage = 'A system error has occured.' }
		50 { $ErrorMessage = 'Usage error.' }
		51 { $ErrorMessage = 'The uuid information is not present on this system.' }
		52 { $ErrorMessage = 'The manufacturing/first-power-on date information is not present on this system.' }
		53 { $ErrorMessage = 'Version cannot be accompanied with any other option.' }
		54 { $ErrorMessage = 'Cannot start /etc/omreg.cfg file. Please ensure /etc/omreg.cfg file is present and is valid for your environment. You can copy this file from the DTK iso.' }
		55 { $ErrorMessage = 'HAPI Driver Load Error.' }
		56 { $ErrorMessage = 'Password is not required for retrieving the TPM options.' }
		57 { $ErrorMessage = 'There was an error setting the TPM option.' }
		58 { $ErrorMessage = 'The setup password provided is incorrect. Please try again.' }
		59 { $ErrorMessage = 'Unsupported device. Re-try with supported device' }
		60 { $ErrorMessage = 'Password not changed, new password does not meet criteria.' }
		61 { $ErrorMessage = 'Error in Validation.' }
		62 { $ErrorMessage = 'Error in Setting the Value.' }
		63 { $ErrorMessage = 'The password length should not exceed the maximum value %s.' }
		64 { $ErrorMessage = 'This is not a Dell machine. DCC supports only Dell machines.' }
		65 { $ErrorMessage = 'Setup Password is required to change the setting. Use --ValSetupPwd to provide password.' }
		66 { $ErrorMessage = 'System Password is required to change the setting. Use --ValSysPwd to provide password.' }
		67 { $ErrorMessage = 'The system password provided is incorrect. Please try again.' }
		68 { $ErrorMessage = 'The Sequence list must be a comma-separated list of valid unique device names (ex: hdd,cdrom).' }
		69 { $ErrorMessage = 'The system revision information is not available for this system.' }
		70 { $ErrorMessage = 'The completion code information is not available for this system.' }
		71 { $ErrorMessage = 'Please use 64-bit version of this application.' }
		72 { $ErrorMessage = '%s cannot be modified when TPM is OFF.' }
		73 { $ErrorMessage = 'adddevice option not supported by this machines BIOS' }
		74 { $ErrorMessage = 'usb device already present in this machine.' }
		75 { $ErrorMessage = '%s - Error : Unable to store BIOS information.' }
		76 { $ErrorMessage = 'Duplicate entry found in the input list : %s , Operation Aborted.' }
		77 { $ErrorMessage = 'Typo found in the input list : %s , Operation Aborted.' }
		78 { $ErrorMessage = 'Asset tag can have only printable ASCII characters.' }
		79 { $ErrorMessage = 'Multiple inputs will not be accepted.' }
		80 { $ErrorMessage = 'Invalid Hex format.' }
		81 { $ErrorMessage = 'Hex value range should be 0x0 to 0xffff.' }
		82 { $ErrorMessage = '%s - Only positive numeric values are acceptable.' }
		83 { $ErrorMessage = '%s - Length cannot exceed two characters.' }
		84 { $ErrorMessage = 'Range for autoon hour value should be 0 to 23(24 hour format).' }
		85 { $ErrorMessage = 'Range for autoon minute value should be 0 to 59.' }
		86 { $ErrorMessage = 'This option Not supported on UEFI Bios.' }
		87 { $ErrorMessage = 'Unable to Set Bootorder.' }
		88 { $ErrorMessage = 'Invalid Arguments. Unable to Set Bootorder.' }
		89 { $ErrorMessage = 'The provided command %s should not combine with other suboptions.' }
		90 { $ErrorMessage = 'The property ownership tag for this system is not available.' }
		91 { $ErrorMessage = 'The property ownership tag cannot be more than 80 characters for non portable machines.' }
		92 { $ErrorMessage = 'The property ownership tag is limited to 48 characters for portable systems.' }
		93 { $ErrorMessage = 'Property ownership tag can have only printable ASCII characters.' }
		94 { $ErrorMessage = 'Error in Setting the Value. Note : In some machines, If Hdd password or System password is set, you cant set Setup password.' }
		95 { $ErrorMessage = '`"admin/root`" privileges required to execute this application.' }
		96 { $ErrorMessage = 'The option related BIOS information is not available in this machine.' }
		97 { $ErrorMessage = 'Improper Output from Bios. Please try again.' }
		98 { $ErrorMessage = ';Error in Bootorder.' }
		99 { $ErrorMessage = 'Not Applicable.' }
		100 { $ErrorMessage = ';Uefi bootlisttype is not supported in this Machine.' }
		101 { $ErrorMessage = 'Unable to get information specific to machine.' }
		102 { $ErrorMessage = 'The input file is invalid.' }
		103 { $ErrorMessage = 'No Status Present.' }
		104 { $ErrorMessage = 'File Do not have configurable Options.' }
		105 { $ErrorMessage = 'Please provide the days to enable.' }
		106 { $ErrorMessage = 'Password is not Installed. Please try again without providing --Val%s' }
		107 { $ErrorMessage = 'Please provide the old password to set the new password using --ValOwnerPwd.' }
		108 { $ErrorMessage = 'The owner password is incorrect. Please try again.' }
		109 { $ErrorMessage = 'Error in setting the value. Note : Setup or system password might be set on the system. Clear the password(s) and try again.' }
		110 { $ErrorMessage = 'Owner password is not supported in file operations.' }
		111 { $ErrorMessage = 'Password operation is not supported on the system.' }
		112 { $ErrorMessage = 'The owner of the system has enabled the Owner Access feature. To set the Bios configuration, create setup or system password.' }
		113 { $ErrorMessage = 'Either the system hardware or the BIOS version does not support the option. To resolve the BIOS version issue, upgrade the BIOS to the latest version.' }
		114 { $ErrorMessage = 'Unable to get password information.' }
		115 { $ErrorMessage = 'Please provide the start and stop values. Example: Custom:start-end.' }
		116 { $ErrorMessage = 'The start and stop values should be in the range `" % s`".' }
		117 { $ErrorMessage = 'The stop value should be greater than the start value by 5 percentage.' }
		118 { $ErrorMessage = 'The option `" % s`" is not supported in this machine.' }
		119 { $ErrorMessage = 'Unable to set `" % s`". Note: To set this Option Legacy Option rom(LegacyOrom) should be enable and SecureBoot should be disable.' }
		120 { $ErrorMessage = 'Unable to set `" % s`". Note: To set this Option bootmode(activebootlist) should be uefi and legacy option rom (LegacyOrom) should be disable.' }
		121 { $ErrorMessage = 'Unable to set `" % s`". Note: To enable this Option SecureBoot should be disable. To disable this Option SecureBoot should be disable and bootmode(ActiveBootList) should be uefi.' }
		122 { $ErrorMessage = 'The allowed value for the option in the system are in between %s.' }
		123 { $ErrorMessage = 'The option `" % s`" is not enabled.' }
		124 { $ErrorMessage = 'Invalid argument! The possible values are: 0, 1-15, and 255.' }
		125 { $ErrorMessage = 'Invalid argument. The arguments must be set in such a way that [Start time] less than or equal [End time] less than or equal [Charge Start time].' }
		126 { $ErrorMessage = 'Unable to set the Non critical Threshold values.' }
		127 { $ErrorMessage = 'Cannot set the passed value as it is not within the range. The value should be less than or equal to `"Upper Threshold Critical`" and greater than or equal to `"Minimum value`"' }
		128 { $ErrorMessage = 'Error in Setting the Value. Note: To set TPM - 1. Admin Password must be set , 2. TPM must not be owned and 3. TPM must be deactivated.' }
		129 { $ErrorMessage = 'Invalid format! Enter the value in the `"R, G, B`" format.' }
		130 { $ErrorMessage = 'Invalid value! Expected values are `"White`", `"Red`", `"Green`", `"Blue`", `"CustomColor1`", `"CustomColor2`" and `"None`"' }
		131 { $ErrorMessage = 'Invalid value! Expected values are `"White`", `"Red`", `"Green`", `"Blue`", `"CustomColor1`" and `"CustomColor2`"' }
		132 { $ErrorMessage = 'Invalid format! Enter only one value.' }
		133 { $ErrorMessage = 'Invalid format! No other value is allowed with `"none`"' }
		134 { $ErrorMessage = 'Invalid format! Duplicate entry found in the input list:`" % s`"' }
		135 { $ErrorMessage = 'Invalid operation! Set operation for `" % s`" attribute is not allowed using file mode' }
		136 { $ErrorMessage = 'Invalid format! String for `" % s`" attribute should contain maximum 4 characters. Supported characters are 0-9, A-F and a-f.' }
		137 { $ErrorMessage = 'Invalid format! String for `" % s`" attribute should contain maximum 8 characters. Supported characters are 0-9, A-F and a-f.' }
		138 { $ErrorMessage = 'Invalid set operation! `" % s`" attribute is read-only attribute.' }
		139 { $ErrorMessage = 'The option `" % s`" is not disabled.' }
		140 { $ErrorMessage = 'This system does not have a WMI-ACPI compliant BIOS. Update the BIOS with a compatible version, if available.' }
		141 { $ErrorMessage = 'Couldnt get WMI-ACPI Buffer Size!!' }
		142 { $ErrorMessage = 'Unable to get BIOS tables or Unknown type encountered!!.' }
		143 { $ErrorMessage = 'The dependent file is not loaded from the appropriate path, repair or reinstall to fix the issue.' }
		144 { $ErrorMessage = '%s cannot be modified when the current value is set to PermanentlyDisabled.' }
		145 { $ErrorMessage = 'Legacy option is not supported on this machine.' }
		146 { $ErrorMessage = 'Importing ini file is failing for some features. For more information, check log.' }
	}
	return $ErrorMessage
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
$tsenv.Value("ActionAfterPowerLoss") = "NotExist" # Usually following values: Power Off, Power On, Previous State
$tsenv.Value("TpmPpiClearOverride") = "NotExist" # Dell
$tsenv.Value("WlanAutoSense") = "NotExist" # Dell
$tsenv.Value("WwanAutoSense") = "NotExist" # Dell

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
	if ($Value -like "*Ver.*") { $Value = $Value.Substring($Value.IndexOf("Ver.") + 4).Trim() }
	if ($Value -like "*Ver*") { $Value = $Value.Substring($Value.IndexOf("Ver") + 3).Trim() }
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
		if ($line -like "PhysicalPresenceForTpmClear*") # Enable / Disable
		{
			$Value = ($line.Substring($line.IndexOf(",") + 1, $line.Length - ($line.IndexOf(",") + 1))).Trim()
			Write-Log "PhysicalPresenceForTpmClear: $Value"
			if ($Value -like "*Enable*") { $tsenv.Value("PhysicalPresenceForTpmClear") = "Enable" }
			else { $tsenv.Value("PhysicalPresenceForTpmClear") = "Disable" }
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
	$ErrorMessage = Dell-ExitCode $ErrorCode
	Write-Log "Getting BIOS settings with exit code: $ErrorCode"
	Write-Log "BIOS settings translated message: $ErrorMessage"
	
	
	# BIOS Version
	$Value = (Get-WmiObject win32_bios).SMBIOSBIOSVersion
	if ($Value -like "*(*") { $Value = $Value.Substring($Value.IndexOf("(") + 1) }
	if ($Value -like "*)*") { $Value = $Value.Substring(0, $Value.IndexOf(")")).Trim() }
	if ($Value -like "*Ver.*") { $Value = $Value.Substring($Value.IndexOf("Ver.") + 4).Trim() }
	if ($Value -like "*Ver*") { $Value = $Value.Substring($Value.IndexOf("Ver") + 3).Trim() }
	$tsenv.Value("OSDBIOSVersion") = $Value
	Write-Log "BIOS Version: $Value"
	
	$BIOSFile = [System.IO.File]::OpenText("$Bios_Settings")
	if ($BIOSFile -eq $null) { Write-Log "Error extracting BIOS settings" }
	while ($null -ne ($line = $BIOSFile.ReadLine()))
	{
		# TPM Device
		if (($line -like "*tpm=*") -and ($($tsenv.Value("OSDTPMDevice")) -eq "NotExist"))# on / off
		{
			$Value = $line.Substring($line.IndexOf("=") + 1).Trim()
			Write-Log "TPM Device: $Value"
			if ($Value -like "*on*") { $tsenv.Value("OSDTPMDevice") = "Available" } else { $tsenv.Value("OSDTPMDevice") = "Hidden" }
		}
		if (($line -like "*TpmSecurity=*") -and ($($tsenv.Value("OSDTPMDevice")) -eq "NotExist" )) # Enabled / Disabled
		{
			$Value = $line.Substring($line.IndexOf("=") + 1).Trim()
			Write-Log "TPM Device: $Value"
			if ($Value -like "*Enabked*") { $tsenv.Value("OSDTPMDevice") = "Available" }
			else { $tsenv.Value("OSDTPMDevice") = "Hidden" }
		}
		# TPM State
		if ($line -like "*tpmactivation=*") # activated / deactivated / or Enabled / Disabled
		{
			$Value = $line.Substring($line.IndexOf("=") + 1).Trim()
			Write-Log "TPM State: $Value"
			if (($Value -like "activate*") -or ($Value -like "Enabled*")) { $tsenv.Value("OSDTPMState") = "Active" } else { $tsenv.Value("OSDTPMState") = "Disable" }
		}
		# TPM PPI Clear Override
		if ($line -like "*TpmPpiClearOverride=*") # activated / deactivated / or Enabled / Disabled
		{
			$Value = $line.Substring($line.IndexOf("=") + 1).Trim()
			Write-Log "TPM PPI Clear Override: $Value"
			if (($Value -like "activate*") -or ($Value -like "Enabled*")) { $tsenv.Value("TpmPpiClearOverride") = "Active" }
			else { $tsenv.Value("TpmPpiClearOverride") = "Disabled" }
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
		# LAN / WLAN Auto Switching
		if ($line -like "*WlanAutoSense=*") # enable / disable
		{
			$Value = $line.Substring($line.IndexOf("=") + 1).Trim()
			Write-Log "LAN / WLAN Auto Switching (WlanAutoSense): $Value"
			if ($Value -like "*enable*") { $tsenv.Value("WlanAutoSense") = "Enable" } else { $tsenv.Value("WlanAutoSense") = "Disable" }
		}
		# LAN / WLAN Auto Switching
		if ($line -like "*WwanAutoSense=*") # enable / disable
		{
			$Value = $line.Substring($line.IndexOf("=") + 1).Trim()
			Write-Log "LAN / WLAN Auto Switching (WwanAutoSense): $Value"
			if ($Value -like "*enable*") { $tsenv.Value("WwanAutoSense") = "Enable" } else { $tsenv.Value("WwanAutoSense") = "Disable" }
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
	if ($Value -like "*(*") { $Value = $Value.Substring($Value.IndexOf("(") + 1) }
	if ($Value -like "*)*") { $Value = $Value.Substring(0, $Value.IndexOf(")")).Trim() }
	if ($Value -like "*Ver.*") { $Value = $Value.Substring($Value.IndexOf("Ver.") + 4).Trim() }
	if ($Value -like "*Ver*") { $Value = $Value.Substring($Value.IndexOf("Ver") + 3).Trim() }
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
		if ($line -like "*After Power Loss*") # Power Off / Power On / Previous State
		{
			$line = $BIOSFile.ReadLine(); $linetest = [int[]][char[]]$line; if ($linetest -contains [char]42) { $Value = $line.Trim().Substring(1) }
			$line = $BIOSFile.ReadLine(); $linetest = [int[]][char[]]$line; if ($linetest -contains [char]42) { $Value = $line.Trim().Substring(1) }
			Write-Log "After Power Loss: $Value"
			if ($Value -like "*Power On*") { $tsenv.Value("ActionAfterPowerLoss") = "Enable" } else { $tsenv.Value("ActionAfterPowerLoss") = "Disable" }
		}
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
	if ($ModelFriendlyName -like "*VMware*") { $tsenv.Value("OSDVirtualMachine") = $true }
}

# Xen
if ($Manufacturer -like "*Xen*") { $tsenv.Value("OSDVirtualMachine") = $true }

# Innotek
if ($Manufacturer -like "*innotek*")
{
	$ModelFriendlyName = (Get-WmiObject Win32_ComputerSystem).Model.TrimEnd()
	if ($ModelFriendlyName -like "*VirtualBox*") { $tsenv.Value("OSDVirtualMachine") = $true }
}

# Parallels
if ($Manufacturer -like "*Parallels Software*")
{
	$ModelFriendlyName = (Get-WmiObject Win32_ComputerSystem).Model.TrimEnd()
	if ($ModelFriendlyName -like "*Virtual Platform*") { $tsenv.Value("OSDVirtualMachine") = $true }
}

# Check BIOS upgrade
try
{
	$BIOSUpgrade = $tsenv.Value("OSDBIOSUpdateRequired")
	if ($BIOSUpgrade -eq $true)
	{
		$BIOSFolderVersion = $tsenv.Value("OSDBIOSUpdateExpectedVersion")
		$OSDBIOSVersion = $tsenv.Value("OSDBIOSVersion")
		$ModelFriendlyName = $tsenv.Value("OSDModelFriendlyName")
		$tsenv.Value("OSDBIOSUpdateRequired") = $false
		if ($BIOSFolderVersion -ne $OSDBIOSVersion)
		{
			if ($($tsenv.Value("OSDVirtualMachine")) -ne $true)
			{
				(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "BIOS did not update properly for computer: $env:COMPUTERNAME, model: $ModelFriendlyName" | Out-File -FilePath "$LogPath\BIOSError.txt" -Append
				Write-Log "Error: BIOS did not update properly, current version: $OSDBIOSVersion, expected version: $BIOSFolderVersion"
			}
			else { Write-Log "Machine type is virtual - BIOS upgrade skipped." }
		}
	}
}
catch { }

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
	if (($tsenv.Value("ActionAfterPowerLoss") -eq "Disable") -and ($tsenv.Value("ActionAfterPowerLoss") -ne "NotExist")) { $tsenv.Value("OSDSetBIOS") = $true; Write-Log "After Power Loss is not set to 'Power On' - BIOS change necessary" }
	if (($tsenv.Value("TpmPpiClearOverride") -eq "Disabled") -and ($tsenv.Value("TpmPpiClearOverride") -ne "NotExist")) { $tsenv.Value("OSDSetBIOS") = $true; Write-Log "TpmPpiClearOverride is set to disabled - BIOS change necessary" }
	if (($tsenv.Value("WlanAutoSense") -eq "Disable") -and ($tsenv.Value("WlanAutoSense") -ne "NotExist")) { $tsenv.Value("OSDSetBIOS") = $true; Write-Log "WlanAutoSense is set to disable - BIOS change necessary" }
	if (($tsenv.Value("WwanAutoSense") -eq "Disable") -and ($tsenv.Value("WwanAutoSense") -ne "NotExist")) { $tsenv.Value("OSDSetBIOS") = $true; Write-Log "WwanAutoSense is set to disabled - BIOS change necessary" }
	
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
	if ($tsenv.Value("ActionAfterPowerLoss") -eq "NotExist") { Write-Log "Non-existing value in BIOS: After Power Loss" }
	if ($tsenv.Value("TpmPpiClearOverride") -eq "NotExist") { Write-Log "Non-existing value in BIOS: TpmPpiClearOverride" }
	if ($tsenv.Value("WlanAutoSense") -eq "NotExist") { Write-Log "Non-existing value in BIOS: WlanAutoSense" }
	if ($tsenv.Value("WwanAutoSense") -eq "NotExist") { Write-Log "Non-existing value in BIOS: WwanAutoSense" }
	
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

