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
	$LogPath = $tsenv.Value("_SMSTSLogPath")
	$LogFile = "$LogPath\Installation.log"
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
Write-Log "Configure BIOS settings"

# Set variables
$PasswordTemp = "CygatePW"
$Bios_Settings = "$env:TEMP\BIOS_Settings.txt"
$ParentDirectory = (Get-Item $PSScriptRoot).parent.parent.FullName
$BIOSApplyFile = "$env:TEMP\BIOS_Settings_Apply.txt"
$BIOSSettingsLog = "$LogPath\BIOSSettingsLog.log"
$RebootNeeded = $false
$tsenv.Value("OSDReboot") = $RebootNeeded
$tsenv.Value("OSDRAIDChange") = $false
$tsenv.Value("OSDUEFILegacyChange") = $false
$tsenv.Value("OSDConvertToUEFI") = $false
$tsenv.Value("OSDConvertToLegacy") = $false

$OSVersionVariable = $tsenv.Value("OSDOSVersion")
Write-Log "OS Version variable: $OSVersionVariable"

# Getting Manufacturer
$Manufacturer = (Get-WmiObject Win32_ComputerSystem).Manufacturer.TrimEnd()
Write-Log "Manufacturer: $Manufacturer"
if ($Manufacturer -like "*Lenovo*")
{
	$ModelFriendlyName = (Get-WmiObject Win32_ComputerSystemProduct).Version.TrimEnd()
	$ModelNumber = (Get-WmiObject Win32_ComputerSystem).Model.TrimEnd().SubString(0, 4)
	Write-Log "Model: $ModelFriendlyName"
	Write-Log "Model Number: $ModelNumber"
}
else
{
	$ModelFriendlyName = (Get-WmiObject Win32_ComputerSystem).Model.TrimEnd()
	Write-Log "Model: $ModelFriendlyName"
}

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

# Remove old files
if (Test-Path "$BIOSApplyFile") { Remove-Item "$BIOSApplyFile" -Force }

################################################################################## Lenovo ###########################################################################################################################################

if ($Manufacturer -like "*Lenovo*")
{
	foreach ($BIOSPassword in $BIOSPasswordArray)
	{
		# Common settings
		if ($tsenv.Value("OSDPXEBoot") -eq "Disable") { $Process = (gwmi -class Lenovo_SetBiosSetting -namespace root\wmi).SetBiosSetting("EthernetLANOptionROM,Enable,$BIOSPassword,ascii,us"); $ErrorCode = $Process.return; Write-Log "EthernetLANOptionROM changed to Enable with exit code: $ErrorCode" }
		if ($tsenv.Value("OSDRAIDMode") -eq "Enable") { $Process = (gwmi -class Lenovo_SetBiosSetting -namespace root\wmi).SetBiosSetting("RAIDMode,Disable,$BIOSPassword,ascii,us"); $ErrorCode = $Process.return; $RebootNeeded = $true; $tsenv.Value("OSDRAIDChange") = $true; Write-Log "RAIDMode changed to Disable with exit code: $ErrorCode" }
		if ($tsenv.Value("OSDVirtualization") -eq "Disable") { $Process = (gwmi -class Lenovo_SetBiosSetting -namespace root\wmi).SetBiosSetting("VirtualizationTechnology,Enable,$BIOSPassword,ascii,us"); $ErrorCode = $Process.return; Write-Log "VirtualizationTechnology changed to Enable with exit code: $ErrorCode" }
		if ($tsenv.Value("OSDVirtualization") -eq "Disable") { $Process = (gwmi -class Lenovo_SetBiosSetting -namespace root\wmi).SetBiosSetting("Intel(R) Virtualization Technology,Enabled,$BIOSPassword,ascii,us"); $ErrorCode = $Process.return; Write-Log "Intel(R) Virtualization Technology changed to Enabled with exit code: $ErrorCode" }
		if ($tsenv.Value("VTdFeature") -eq "Disable") { $Process = (gwmi -class Lenovo_SetBiosSetting -namespace root\wmi).SetBiosSetting("VTdFeature,Enable,$BIOSPassword,ascii,us"); $ErrorCode = $Process.return; Write-Log "VTdFeature changed to Enabled with exit code: $ErrorCode" }
		if ($tsenv.Value("OSDHyperThreading") -eq "Disable") { $Process = (gwmi -class Lenovo_SetBiosSetting -namespace root\wmi).SetBiosSetting("HyperThreadingTechnology,Enable,$BIOSPassword,ascii,us"); $ErrorCode = $Process.return; Write-Log "HyperThreadingTechnology changed to Enable with exit code: $ErrorCode" }
		if ($tsenv.Value("WakeByThunderbolt") -eq "Disable") { $Process = (gwmi -class Lenovo_SetBiosSetting -namespace root\wmi).SetBiosSetting("WakeByThunderbolt,Enable,$BIOSPassword,ascii,us"); $ErrorCode = $Process.return; Write-Log "WakeByThunderbolt changed to Enable with exit code: $ErrorCode" }
		if ($tsenv.Value("ThunderboltSecurityLevel") -eq "Disable") { $Process = (gwmi -class Lenovo_SetBiosSetting -namespace root\wmi).SetBiosSetting("ThunderboltSecurityLevel,NoSecurity,$BIOSPassword,ascii,us"); $ErrorCode = $Process.return; Write-Log "ThunderboltSecurityLevel changed to NoSecurity with exit code: $ErrorCode" }
		if ($tsenv.Value("PreBootForThunderboltDevice") -eq "Disable") { $Process = (gwmi -class Lenovo_SetBiosSetting -namespace root\wmi).SetBiosSetting("PreBootForThunderboltDevice,Enable,$BIOSPassword,ascii,us"); $ErrorCode = $Process.return; Write-Log "PreBootForThunderboltDevice changed to Enable with exit code: $ErrorCode" }
		if ($tsenv.Value("PreBootForThunderboltUSBDevice") -eq "Disable") { $Process = (gwmi -class Lenovo_SetBiosSetting -namespace root\wmi).SetBiosSetting("PreBootForThunderboltUSBDevice,Enable,$BIOSPassword,ascii,us"); $ErrorCode = $Process.return; Write-Log "PreBootForThunderboltUSBDevice changed to Enable with exit code: $ErrorCode" }
		if ($tsenv.Value("AlwaysOnUSB") -eq "Disable") { $Process = (gwmi -class Lenovo_SetBiosSetting -namespace root\wmi).SetBiosSetting("AlwaysOnUSB,Enable,$BIOSPassword,ascii,us"); $ErrorCode = $Process.return; Write-Log "AlwaysOnUSB changed to Enable with exit code: $ErrorCode" }
		if ($tsenv.Value("SGXControl") -eq "Disable") { $Process = (gwmi -class Lenovo_SetBiosSetting -namespace root\wmi).SetBiosSetting("SGXControl,SoftwareControl,$BIOSPassword,ascii,us"); $ErrorCode = $Process.return; Write-Log "SGXControl changed to SoftwareControl with exit code: $ErrorCode" }
		if ($tsenv.Value("AdaptiveThermalManagementAC") -eq "Disable") { $Process = (gwmi -class Lenovo_SetBiosSetting -namespace root\wmi).SetBiosSetting("AdaptiveThermalManagementAC,Balanced,$BIOSPassword,ascii,us"); $ErrorCode = $Process.return; Write-Log "AdaptiveThermalManagementAC changed to Enable with exit code: $ErrorCode" }
		if ($tsenv.Value("WirelessAutoDisconnection") -eq "Disable") { $Process = (gwmi -class Lenovo_SetBiosSetting -namespace root\wmi).SetBiosSetting("WirelessAutoDisconnection,Enable,$BIOSPassword,ascii,us"); $ErrorCode = $Process.return; Write-Log "WirelessAutoDisconnection changed to Enable with exit code: $ErrorCode" }
		if ($tsenv.Value("MACAddressPassThrough") -eq "Disable") { $Process = (gwmi -class Lenovo_SetBiosSetting -namespace root\wmi).SetBiosSetting("MACAddressPassThrough,Enable,$BIOSPassword,ascii,us"); $ErrorCode = $Process.return; Write-Log "MACAddressPassThrough changed to Enable with exit code: $ErrorCode" }
		if ($tsenv.Value("BIOSUpdateByEndUsers") -eq "Disable") { $Process = (gwmi -class Lenovo_SetBiosSetting -namespace root\wmi).SetBiosSetting("BIOSUpdateByEndUsers,Enable,$BIOSPassword,ascii,us"); $ErrorCode = $Process.return; Write-Log "BIOSUpdateByEndUsers changed to Enable with exit code: $ErrorCode" }
		if ($tsenv.Value("PhysicalPresenceForTpmProvision") -eq "Enable") { $Process = (gwmi -class Lenovo_SetBiosSetting -namespace root\wmi).SetBiosSetting("PhysicalPresenceForTpmProvision,Enable,$BIOSPassword,ascii,us"); $ErrorCode = $Process.return; Write-Log "PhysicalPresenceForTpmProvision changed to Disable with exit code: $ErrorCode" }
		if ($tsenv.Value("PhysicalPresenceForTpmClear") -eq "Enable") { $Process = (gwmi -class Lenovo_SetBiosSetting -namespace root\wmi).SetBiosSetting("PhysicalPresenceForTpmClear,Enable,$BIOSPassword,ascii,us"); $ErrorCode = $Process.return; Write-Log "PhysicalPresenceForTpmClear changed to Disable with exit code: $ErrorCode" }
		if ($tsenv.Value("ThunderboltBIOSAssistMode") -eq "Disable") { $Process = (gwmi -class Lenovo_SetBiosSetting -namespace root\wmi).SetBiosSetting("ThunderboltBIOSAssistMode,Enable,$BIOSPassword,ascii,us"); $ErrorCode = $Process.return; Write-Log "ThunderboltBIOSAssistMode changed to Enable with exit code: $ErrorCode" }
		
		# Windows 7
		if ($tsenv.Value("OSDOSVersion") -eq "WIN7X64")
		{
			Write-Log "Settings in BIOS adjusted for Windows 7"
			if ($tsenv.Value("OSDSecureBoot") -eq "Enable") { $Process = (gwmi -class Lenovo_SetBiosSetting -namespace root\wmi).SetBiosSetting("SecureBoot,Disable,$BIOSPassword,ascii,us"); $RebootNeeded = $true; $ErrorCode = $Process.return; $tsenv.Value("OSDUEFILegacyChange") = $true; Write-Log "SecureBoot changed to Disable (Windows 7) with exit code: $ErrorCode" }
		}
		
		# Windows 10
		if ($tsenv.Value("OSDOSVersion") -eq "WIN10X64")
		{
			Write-Log "Settings in BIOS adjusted for Windows 10"
			if ($tsenv.Value("OSDSecureBoot") -eq "Disable") { $Process = (gwmi -class Lenovo_SetBiosSetting -namespace root\wmi).SetBiosSetting("SecureBoot,Enable,$BIOSPassword,ascii,us"); $RebootNeeded = $true; $ErrorCode = $Process.return; $tsenv.Value("OSDUEFILegacyChange") = $true; Write-Log "SecureBoot changed to Enable (Windows 10) with exit code: $ErrorCode" }
			if ($tsenv.Value("OSDSecureBoot") -eq "Disable") { $Process = (gwmi -class Lenovo_SetBiosSetting -namespace root\wmi).SetBiosSetting("Secure Boot,Enable,$BIOSPassword,ascii,us"); $RebootNeeded = $true; $ErrorCode = $Process.return; $tsenv.Value("OSDUEFILegacyChange") = $true; Write-Log "Secure Boot changed to Enabled (Windows 10) with exit code: $ErrorCode" }
		}
		
		# Save BIOS settings
		$Process = (gwmi -class Lenovo_SaveBiosSettings -namespace root\wmi).SaveBiosSettings("$BIOSPassword,ascii,us")
		$ErrorCode = $Process.return
		Write-Log "Saving BIOS settings with exit code: $ErrorCode"
	}
}


################################################################################## Dell ###########################################################################################################################################
foreach ($BIOSPassword in $BIOSPasswordArray)
{
	if ($Manufacturer -like "*Dell*")
	{
		# Writing config file
		"[cctk]" | Out-File -FilePath $BIOSApplyFile -Force
		
		# Common settings
		if ($tsenv.Value("OSDRAIDMode") -ne "ahci") { "embsataraid=ahci" | Out-File -FilePath $BIOSApplyFile -Append; $RebootNeeded = $true; $tsenv.Value("OSDRAIDChange") = $true; Write-Log "Adding embsataraid=ahci to configuration file" }
		if ($tsenv.Value("OSDVirtualization") -eq "Disable") { "virtualization=enable" | Out-File -FilePath $BIOSApplyFile -Append; $RebootNeeded = $true; Write-Log "Adding virtualization=enable to configuration file" }
		if ($tsenv.Value("OSDHyperThreading") -eq "Disable") { "logicproc=enable" | Out-File -FilePath $BIOSApplyFile -Append; Write-Log "Adding logicproc=enable to configuration file" }
		if ($tsenv.Value("OSDLANWANSwitch") -eq "Disable") { "wirelesswitchnlanctrl=enable" | Out-File -FilePath $BIOSApplyFile -Append; Write-Log "Adding wirelesswitchnlanctrl=enable to configuration file" }
		if ($tsenv.Value("WlanAutoSense") -eq "Disable") { "WlanAutoSense=enable" | Out-File -FilePath $BIOSApplyFile -Append; Write-Log "Adding WlanAutoSense=enable to configuration file" }
		if ($tsenv.Value("WwanAutoSense") -eq "Disable") { "WwanAutoSense=enable" | Out-File -FilePath $BIOSApplyFile -Append; Write-Log "Adding WwanAutoSense=enable to configuration file" }
		if ($tsenv.Value("TpmPpiClearOverride") -eq "Disabled") { "tpmppiclearoverride=enable" | Out-File -FilePath $BIOSApplyFile -Append; Write-Log "Adding tpmppiclearoverride=enable to configuration file" }
		
		# Windows 7
		if ($tsenv.Value("OSDOSVersion") -eq "WIN7X64")
		{
			Write-Log "Settings in BIOS adjusted for Windows 7"
			if ($tsenv.Value("OSDSecureBoot") -eq "Enable") { "secureboot=disable" | Out-File -FilePath $BIOSApplyFile -Append; $RebootNeeded = $true; $tsenv.Value("OSDUEFILegacyChange") = $true; Write-Log "Adding secureboot=disable (Windows 7) to configuration file" }
		}
		
		# Windows 10
		if ($tsenv.Value("OSDOSVersion") -eq "WIN10X64")
		{
			Write-Log "Settings in BIOS adjusted for Windows 10"
			if ($tsenv.Value("OSDSecureBoot") -eq "Disable") { "secureboot=enable" | Out-File -FilePath $BIOSApplyFile -Append; $RebootNeeded = $true; $tsenv.Value("OSDUEFILegacyChange") = $true; Write-Log "Adding secureboot=enable to configuration file" }
		}
		
		# Run Tool
		$BIOSConfigTool = "$ParentDirectory\Tools\Dell\X86_64\cctk.exe"
		Write-Log "Tool Path: $BIOSConfigTool"
		
		# Reencode configuration file to ANSI
		[System.Io.File]::ReadAllText($BIOSApplyFile) | Out-File -FilePath $BIOSApplyFile -Encoding Default # Dell BIOS config file must have encoding ANSI which is the value "Default". If omitted encoding is set to Unicode.
		
		$Argument = "--infile `"$BIOSApplyFile`" --logfile=`"$BIOSSettingsLog`""
		if ($UseBIOSPassword -eq $true) { $Argument = "--valsetuppwd=$BIOSPassword --infile `"$BIOSApplyFile`" --logfile=`"$BIOSSettingsLog`"" }
		
		$process = Start-Process -FilePath `"$BIOSConfigTool`" -ArgumentList "$Argument" -Wait -NoNewWindow -PassThru -ErrorAction SilentlyContinue
		$ErrorCode = $Process.ExitCode
		$ErrorMessage = Dell-ExitCode $ErrorCode
		Write-Log "Applied BIOS: $BIOSConfigTool $Argument with exit code: $ErrorCode"
		Write-Log "BIOS tool translated message: $ErrorMessage"
	}
}

################################################################################## HP (Hewlett-Packard) ###########################################################################################################################################
if (($Manufacturer -like "*Hewlett*") -or ($Manufacturer -like "*HP*"))
{
	# Writing config file
	"BIOSConfig 1.0" | Out-File -FilePath $BIOSApplyFile -Force
	";" | Out-File -FilePath $BIOSApplyFile -Append
	
	# Common settings
	if (($tsenv.Value("OSDPXEBoot") -ne "Enable") -and ($tsenv.Value("OSDPXEBoot") -ne "NotExist"))
	{
		"Network (PXE) Boot" | Out-File -FilePath $BIOSApplyFile -Append
		"	Disable" | Out-File -FilePath $BIOSApplyFile -Append
		"	*Enable" | Out-File -FilePath $BIOSApplyFile -Append
		$tsenv.Value("OSDPXEBoot") = $true
		Write-Log "Network (PXE) Boot=Enable to configuration file"
		
		"PXE Internal NIC boot" | Out-File -FilePath $BIOSApplyFile -Append
		"	Disable" | Out-File -FilePath $BIOSApplyFile -Append
		"	*Enable" | Out-File -FilePath $BIOSApplyFile -Append
		$tsenv.Value("OSDPXEBoot") = $true
		Write-Log "PXE Internal NIC boot=Enable to configuration file"
		
		"PXE Internal IPV4 NIC boot" | Out-File -FilePath $BIOSApplyFile -Append
		"	Disable" | Out-File -FilePath $BIOSApplyFile -Append
		"	*Enable" | Out-File -FilePath $BIOSApplyFile -Append
		$tsenv.Value("OSDPXEBoot") = $true
		Write-Log "PXE Internal NIC boot=Enable to configuration file"
	}
	if (($tsenv.Value("OSDLANWANSwitch") -ne "Enable") -and ($tsenv.Value("OSDLANWANSwitch") -ne "NotExist"))
	{
		"LAN / WLAN Auto Switching" | Out-File -FilePath $BIOSApplyFile -Append
		"	Disable" | Out-File -FilePath $BIOSApplyFile -Append
		"	*Enable" | Out-File -FilePath $BIOSApplyFile -Append
		$tsenv.Value("OSDLANWANSwitch") = $true
		Write-Log "LAN / WLAN Auto Switching=Enable to configuration file"
	}
	if (($tsenv.Value("OSDHyperThreading") -ne "Enable") -and ($tsenv.Value("OSDHyperThreading") -ne "NotExist"))
	{
		"Hyperthreading" | Out-File -FilePath $BIOSApplyFile -Append
		"	Disable" | Out-File -FilePath $BIOSApplyFile -Append
		"	*Enable" | Out-File -FilePath $BIOSApplyFile -Append
		$tsenv.Value("OSDHyperThreading") = $true
		Write-Log "Hyperthreading=Enable to configuration file"
	}
	if (($tsenv.Value("OSDVirtualization") -ne "Enable") -and ($tsenv.Value("OSDVirtualization") -ne "NotExist"))
	{
		"Virtualization Technology (VTx)" | Out-File -FilePath $BIOSApplyFile -Append
		"	Disable" | Out-File -FilePath $BIOSApplyFile -Append
		"	*Enable" | Out-File -FilePath $BIOSApplyFile -Append
		$tsenv.Value("OSDVirtualization") = $true
		Write-Log "Virtualization Technology (VTx)=Enable to configuration file"
	}
	if (($tsenv.Value("TPMActivationPolicy") -ne "Enable") -and ($tsenv.Value("TPMActivationPolicy") -ne "NotExist"))
	{
		"TPM Activation Policy" | Out-File -FilePath $BIOSApplyFile -Append
		"	F1 to boot" | Out-File -FilePath $BIOSApplyFile -Append
		"	Allow user to reject" | Out-File -FilePath $BIOSApplyFile -Append
		"	*No prompts" | Out-File -FilePath $BIOSApplyFile -Append
		$RebootNeeded = $true
		Write-Log "TPM Activation Policy = No prompts to configuration file"
	}
	if (($tsenv.Value("TPMActivationPolicy") -ne "Enable") -and ($tsenv.Value("TPMActivationPolicy") -ne "NotExist"))
	{
		"Embedded Security Activation Policy" | Out-File -FilePath $BIOSApplyFile -Append
		"	F1 to boot" | Out-File -FilePath $BIOSApplyFile -Append
		"	Allow user to reject" | Out-File -FilePath $BIOSApplyFile -Append
		"	*No prompts" | Out-File -FilePath $BIOSApplyFile -Append
		$RebootNeeded = $true
		Write-Log "Embedded Security Activation Policy = No prompts to configuration file"
	}
	if (($tsenv.Value("OSDTPMDevice") -ne "Available") -and ($tsenv.Value("OSDTPMDevice") -ne "NotExist"))
	{
		"TPM Device" | Out-File -FilePath $BIOSApplyFile -Append
		"	 Hidden" | Out-File -FilePath $BIOSApplyFile -Append
		"	*Available" | Out-File -FilePath $BIOSApplyFile -Append
		$RebootNeeded = $true
		Write-Log "TPM Device=Available to configuration file"
	}
	if (($tsenv.Value("FastBoot") -ne "Disable") -and ($tsenv.Value("FastBoot") -ne "NotExist"))
	{
		"Fast Boot" | Out-File -FilePath $BIOSApplyFile -Append
		"	*Disable" | Out-File -FilePath $BIOSApplyFile -Append
		"	Enable" | Out-File -FilePath $BIOSApplyFile -Append
		$RebootNeeded = $true
		Write-Log "Fast Boot=Disable to configuration file"
	}
	if (($tsenv.Value("OSDTPMResetFromOS") -ne "Enable") -and ($tsenv.Value("OSDTPMResetFromOS") -ne "NotExist"))
	{
		"Reset of TPM from OS" | Out-File -FilePath $BIOSApplyFile -Append
		"	Disable" | Out-File -FilePath $BIOSApplyFile -Append
		"	*Enable" | Out-File -FilePath $BIOSApplyFile -Append
		$RebootNeeded = $true
		Write-Log "Reset of TPM from OS=Enable to configuration file"
	}
	if (($tsenv.Value("ActionAfterPowerLoss") -ne "Enable") -and ($tsenv.Value("ActionAfterPowerLoss") -ne "NotExist"))
	{
		"After Power Loss" | Out-File -FilePath $BIOSApplyFile -Append
		"	Power Off" | Out-File -FilePath $BIOSApplyFile -Append
		"	*Power On" | Out-File -FilePath $BIOSApplyFile -Append
		"	Previous State" | Out-File -FilePath $BIOSApplyFile -Append
		$RebootNeeded = $false
		Write-Log "After Power Loss=power On to configuration file"
	}
	
	# Windows 7
	if ($tsenv.Value("OSDOSVersion") -eq "WIN7X64")
	{
		Write-Log "Settings in BIOS adjusted for Windows 7"
		if (($tsenv.Value("OSDLegacyBoot") -ne "Enable") -and ($tsenv.Value("OSDLegacyBoot") -ne "NotExist"))
		{
			"Legacy Boot Options" | Out-File -FilePath $BIOSApplyFile -Append
			"	Disable" | Out-File -FilePath $BIOSApplyFile -Append
			"	*Enable" | Out-File -FilePath $BIOSApplyFile -Append
			$RebootNeeded = $true
			$tsenv.Value("OSDLegacyBoot") = $true
			Write-Log "Legacy Boot Options=Enable (Windows 7) to configuration file"
		}
		if (($tsenv.Value("OSDSecureBoot") -ne "Disable") -and ($tsenv.Value("OSDSecureBoot") -ne "NotExist"))
		{
			"Configure Legacy Support and Secure Boot" | Out-File -FilePath $BIOSApplyFile -Append
			"	*Legacy Support Enable and Secure Boot Disable" | Out-File -FilePath $BIOSApplyFile -Append
			"	Legacy Support Disable and Secure Boot Enable" | Out-File -FilePath $BIOSApplyFile -Append
			"	Legacy Support Disable and Secure Boot Disable" | Out-File -FilePath $BIOSApplyFile -Append
			$RebootNeeded = $true
			$tsenv.Value("OSDSecureBoot") = $true
			$tsenv.Value("OSDUEFILegacyChange") = $true
			Write-Log "Secure Boot=Legacy Support Enable and Secure Boot Disable (Windows 10) to configuration file"
		}
	}
	
	# Windows 10
	if ($tsenv.Value("OSDOSVersion") -eq "WIN10X64")
	{
		Write-Log "Settings in BIOS adjusted for Windows 10"
		if (($tsenv.Value("OSDLegacyBoot") -eq "Enable") -and ($tsenv.Value("OSDLegacyBoot") -ne "NotExist"))
		{
			"Legacy Boot Options" | Out-File -FilePath $BIOSApplyFile -Append
			"	*Disable" | Out-File -FilePath $BIOSApplyFile -Append
			"	Enable" | Out-File -FilePath $BIOSApplyFile -Append
			$RebootNeeded = $true
			$tsenv.Value("OSDLegacyBoot") = $true
			Write-Log "Legacy Boot Options=Disable (Windows 10) to configuration file"
		}
		if (($tsenv.Value("OSDLegacyBoot") -eq "Enable") -and ($tsenv.Value("OSDLegacyBoot") -ne "NotExist"))
		{
			"Boot Mode" | Out-File -FilePath $BIOSApplyFile -Append
			"	Legacy" | Out-File -FilePath $BIOSApplyFile -Append
			"	UEFI Hybrid (With CSM)" | Out-File -FilePath $BIOSApplyFile -Append
			"	*UEFI Native (Without CSM)" | Out-File -FilePath $BIOSApplyFile -Append
			$RebootNeeded = $true
			$tsenv.Value("OSDLegacyBoot") = $true
			Write-Log "UEFI Native (Without CSM)=Enable (Windows 10) to configuration file"
		}
		if ($ModelFriendlyName -notlike "*G2*")
		{
			if (($tsenv.Value("OSDSecureBoot") -ne "Enable") -and ($tsenv.Value("OSDSecureBoot") -ne "NotExist"))
			{
				"Configure Legacy Support and Secure Boot" | Out-File -FilePath $BIOSApplyFile -Append
				"	Legacy Support Enable and Secure Boot Disable" | Out-File -FilePath $BIOSApplyFile -Append
				"	*Legacy Support Disable and Secure Boot Enable" | Out-File -FilePath $BIOSApplyFile -Append
				"	Legacy Support Disable and Secure Boot Disable" | Out-File -FilePath $BIOSApplyFile -Append
				$RebootNeeded = $true
				$tsenv.Value("OSDSecureBoot") = $true
				$tsenv.Value("OSDUEFILegacyChange") = $true
				Write-Log "Secure Boot=Legacy Support Disable and Secure Boot Enable (Windows 10) to configuration file"
			}
			if (($tsenv.Value("OSDSecureBoot") -ne "Enable") -and ($tsenv.Value("OSDSecureBoot") -ne "NotExist"))
			{
				"SecureBoot" | Out-File -FilePath $BIOSApplyFile -Append
				"	Disable" | Out-File -FilePath $BIOSApplyFile -Append
				"	*Enable" | Out-File -FilePath $BIOSApplyFile -Append
				$RebootNeeded = $true
				$tsenv.Value("OSDSecureBoot") = $true
				$tsenv.Value("OSDUEFILegacyChange") = $true
				Write-Log "SecureBoot=Disable (Windows 10) to configuration file"
			}
		}
		
		# UEFI Boot order
		"UEFI Boot Order" | Out-File -FilePath $BIOSApplyFile -Append
		"	PCIe/M.2 SSD Hard Drive" | Out-File -FilePath $BIOSApplyFile -Append
		"	OS Boot Manager" | Out-File -FilePath $BIOSApplyFile -Append
		"	USB Hard Drive" | Out-File -FilePath $BIOSApplyFile -Append
		"	Customized Boot" | Out-File -FilePath $BIOSApplyFile -Append
		"	Notebook Ethernet IPV4" | Out-File -FilePath $BIOSApplyFile -Append
		"	Notebook Ethernet IPV6" | Out-File -FilePath $BIOSApplyFile -Append
		"	SD Card Boot" | Out-File -FilePath $BIOSApplyFile -Append
		"	Generic USB Device" | Out-File -FilePath $BIOSApplyFile -Append
		$RebootNeeded = $true
		Write-Log "UEFI Boot Order to prioritize customized boot to configuration file"
	}
	
	# Reencode configuration file to ANSI
	[System.Io.File]::ReadAllText($BIOSApplyFile) | Out-File -FilePath $BIOSApplyFile -Encoding Default # HP BIOS config file must have encoding ANSI which is the value "Default". If omitted encoding is set to Unicode.
	
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
	
	# Run Tool
	If ((Get-CimInStance Win32_OperatingSystem).OSArchitecture -like "*64-Bit*") { $BIOSConfigTool = "$ParentDirectory\Tools\HP\BiosConfigUtility64.exe"; Write-Log "OS Architecture is 64-bit" }
	Else { $BIOSConfigTool = "$ParentDirectory\Tools\HP\BiosConfigUtility.exe"; Write-Log "OS Architecture is 32-bit" }
	Write-Log "BIOS Config Tool Path: $BIOSConfigTool"
	
	if ($UseBIOSPassword -eq $false)
	{
		# Set BIOS password - some functions require password to enable, fx TPM
		$Process = Start-Process -FilePath "$BIOSConfigTool" -ArgumentList "/nspwd:`"$env:TEMP\Password1.bin`" /log /logpath:`"$LogPath\BIOS_Set.log`"" -NoNewWindow -Wait -PassThru
		$ErrorCode = $Process.ExitCode
		Write-Log "Setting BIOS Password with exit code: $ErrorCode"
	}
	else
	{
		if (Test-Path "$env:TEMP\Password1.bin")
		{
			$Process = Start-Process -FilePath "$BIOSConfigTool" -ArgumentList "/cspwd:`"$env:TEMP\Password1.bin`" /Set:`"$BIOSApplyFile`" /log /logpath:`"$LogPath\BIOSResult.log`"" -NoNewWindow -Wait -PassThru
			$ErrorCode = $Process.ExitCode
			Write-Log "Setting BIOS settings using Password1.bin with exit code: $ErrorCode"
		}
		else { Write-Log "Error: Password1.bin not found" }
		
		if (Test-Path "$env:TEMP\Password2.bin")
		{
			$Process = Start-Process -FilePath "$BIOSConfigTool" -ArgumentList "/cspwd:`"$env:TEMP\Password2.bin`" /Set:`"$BIOSApplyFile`" /log /logpath:`"$LogPath\BIOSResult.log`"" -NoNewWindow -Wait -PassThru
			$ErrorCode = $Process.ExitCode
			Write-Log "Setting BIOS settings using Password2.bin with exit code: $ErrorCode"
		}
		else { Write-Log "Password2.bin not found" }
	}
	
	if ($UseBIOSPassword -eq $false)
	{
		# Clear BIOS password
		$Process = Start-Process -FilePath "$BIOSConfigTool" -ArgumentList "/nspwdfile:`"`" /cspwdfile:`"$env:TEMP\Password1.bin`" /log /logpath:`"$LogPath\BIOS_Clear.log`"" -NoNewWindow -Wait -PassThru
		$ErrorCode = $Process.ExitCode
		Write-Log "Clearing BIOS settings with exit code: $ErrorCode"
	}
	
	# Add Customized Boot Option using Powershell
	if ($UseBIOSPassword -eq $true)
	{
		foreach ($BIOSPassword in $BIOSPasswordArray)
		{
			Write-Log "Setting Customized Boot using Powershell - with password"
			$Password = '<utf-16/>' + "$BIOSPassword"
			$BIOS = gwmi -class hp_biossettinginterface -Namespace 'root\hp\instrumentedbios'
			$BIOS.SetBIOSSetting('Customized Boot', 'Disable', $Password)
			$BIOS.SetBIOSSetting('Define Customized Boot Option', '\EFI\Microsoft\Boot\bootmgfw.efi', $Password)
			$BIOS.SetBIOSSetting('Customized Boot', 'Enable', $Password)
		}
	}
	if ($UseBIOSPassword -eq $false)
	{
		Write-Log "Setting Customized Boot using Powershell - without password"
		$BIOS = gwmi -class hp_biossettinginterface -Namespace 'root\hp\instrumentedbios'
		$BIOS.SetBIOSSetting('Customized Boot', 'Disable', $Password)
		$BIOS.SetBIOSSetting('Define Customized Boot Option', '\EFI\Microsoft\Boot\bootmgfw.efi')
		$BIOS.SetBIOSSetting('Customized Boot', 'Enable')
	}
}

# Enable, activate the chip, and allow the installation of a TPM owner. https://msdn.microsoft.com/en-us/library/windows/desktop/aa376478(v=vs.85).aspx
# $Tpm = Get-wmiobject -Namespace ROOT\CIMV2\Security\MicrosoftTpm -Class Win32_Tpm
# try
# {
# 	# Sets the provision that you don't need to be physically presence to clear the TPM.
# 	$TPM.SetPhysicalPresenceRequest(18)
#	# Sets the provision that you don't need to be physically presence to set the TPM.
#	$TPM.SetPhysicalPresenceRequest(16)
# }
# catch {}
$tsenv.Value("OSDReboot") = $RebootNeeded
