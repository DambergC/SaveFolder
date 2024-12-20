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
Write-Log "Reset TPM Configuration"

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

# Getting Manufacturer
$Manufacturer = (Get-WmiObject Win32_ComputerSystem).Manufacturer.TrimEnd()

Write-Log "Resetting TPM Owner"
$TPM = Get-WmiObject -Class Win32_TPM -Namespace root\CIMV2\Security\MicrosoftTpm

# Enable, activate the chip, and allow the installation of a TPM owner. https://msdn.microsoft.com/en-us/library/windows/desktop/aa376478(v=vs.85).aspx
# $TPM.SetPhysicalPresenceRequest(10)
# $TPM.SetPhysicalPresenceRequest(14)
# $Result = $TPM.SetPhysicalPresenceRequest(5)
$Result = $TPM.SetPhysicalPresenceRequest(22) # Enable + Activate + Clear + Enable + Activate
If ($Result.ReturnValue -eq 0)
{
	Write-Log "Reset TPM with exit code: $Result (Success)"
}
else
{
	Write-Log "Reset TPM with exit code: $Result (Failure)"
}

if (($Result.ReturnValue -ne 0) -and ($Manufacturer -like "*Lenovo*"))
{
	Write-Log "Found manufacturer to be Lenovo"
	gwmi -Class lenovo_Biossetting -Namespace root\wmi | select currentsetting | Out-File $Bios_Settings -Force -ErrorAction SilentlyContinue
	
	$BIOSFile = [System.IO.File]::OpenText("$Bios_Settings")
	if ($BIOSFile -eq $null) { Write-Log "Error extracting BIOS settings" }
	while ($null -ne ($line = $BIOSFile.ReadLine()))
	{
		if ($line -like "SecurityChip*") { $SecurityChip = ($line.Substring($line.IndexOf(",") + 1, $line.Length - ($line.IndexOf(",") + 1))).Trim(); Write-Log "SecurityChip: $SecurityChip"; $SecurityChipVariableName = "1" }
		if ($line -like "Security Chip*") { $SecurityChip = ($line.Substring($line.IndexOf(",") + 1, $line.Length - ($line.IndexOf(",") + 1))).Trim(); Write-Log "Security Chip: $SecurityChip"; $SecurityChipVariableName = "2" }
	}
	# TPM settings
	if ($SecurityChipVariableName -eq "1") { $Process = (gwmi -class Lenovo_SetBiosSetting –namespace root\wmi).SetBiosSetting("SecurityChip,Disable") }
	if ($SecurityChipVariableName -eq "2") { $Process = (gwmi -class Lenovo_SetBiosSetting –namespace root\wmi).SetBiosSetting("Security Chip 2.0,Disabled") }
	$RebootNeeded = $true
	$ErrorCode = $Process.return
	Write-Log "SecurityChip changed to Enable with exit code: $ErrorCode"
	
	# Save BIOS settings
	$Process = (gwmi -class Lenovo_SaveBiosSettings -namespace root\wmi).SaveBiosSettings()
	$ErrorCode = $Process.return
	Write-Log "Saving BIOS settings with exit code: $ErrorCode"
}

if (($Result.ReturnValue -ne 0) -and ($Manufacturer -like "*Dell*"))
{
	Write-Log "Found manufacturer to be Dell"
	$BIOSConfigTool = "$ParentDirectory\Tools\Dell\X86_64\cctk.exe"
	Write-Log "Tool Path: $BIOSConfigTool"
	
	# Setting temporaray admin password - required on Dell to enable TPM
	$process = Start-Process -FilePath `"$BIOSConfigTool`" -ArgumentList "--setuppwd=`"$PasswordTemp`" --logfile=`"$BIOSsetpwdlog`"" -Wait -NoNewWindow -PassThru -ErrorAction SilentlyContinue
	$ErrorCode = $Process.ExitCode
	$ErrorMessage = Dell-ExitCode $ErrorCode
	Write-Log "Setting Admin Password with exit code: $ErrorCode"
	Write-Log "Setting Admin Password translated message: $ErrorMessage"
	
	# Allow TPM PPI Clear Override (disable physical presence)
	$process = Start-Process -FilePath `"$ToolPath`" -ArgumentList "--TpmPpiClearOverride=enabled --valsetuppwd=`"$PasswordTemp`" --logfile=`"$BIOSturnTPMonlog`"" -Wait -NoNewWindow -PassThru -ErrorAction SilentlyContinue
	$ErrorCode = $Process.ExitCode
	$ErrorMessage = Dell-ExitCode $ErrorCode
	Write-Log "Allow TPM PPI Clear Override: $ErrorCode"
	Write-Log "Allow TPM PPI Clear Override translated message: $ErrorMessage"
	$RebootNeeded = $true
	
	# Applying Settings
	$process = Start-Process -FilePath `"$BIOSConfigTool`" -ArgumentList "--tpm=off --valsetuppwd=`"$PasswordTemp`" --logfile=`"$BIOSturnTPMonlog`"" -Wait -NoNewWindow -PassThru -ErrorAction SilentlyContinue
	$ErrorCode = $Process.ExitCode
	$ErrorMessage = Dell-ExitCode $ErrorCode
	Write-Log "Turn TPM off with exit code: $ErrorCode"
	Write-Log "Turn TPM off translated message: $ErrorMessage"
	$RebootNeeded = $true
				
	# Clearing / Removing admin password
	$process = Start-Process -FilePath `"$BIOSConfigTool`" -ArgumentList "--setuppwd= --valsetuppwd=`"$PasswordTemp`"" -Wait -NoNewWindow -PassThru -ErrorAction SilentlyContinue
	$ErrorCode = $process.ExitCode
	$ErrorMessage = Dell-ExitCode $ErrorCode
	Write-Log "Remove Admin password with exit code: $ErrorCode"
	Write-Log "Remove Admin password translated message: $ErrorMessage"
}

if (($Result.ReturnValue -ne 0) -and (($Manufacturer -like "*Hewlett*") -or ($Manufacturer -like "*HP*")))
{
	Write-Log "Found manufacturer to be Hewlett Packard"
	If ((Get-CimInStance Win32_OperatingSystem).OSArchitecture -like "*64-Bit*") { $BIOSConfigTool = "$ParentDirectory\Tools\HP\BiosConfigUtility64.exe"; Write-Log "OS Architecture is 64-bit" }
	Else { $BIOSConfigTool = "$ParentDirectory\Tools\HP\BiosConfigUtility.exe"; Write-Log "OS Architecture is 32-bit" }
	Write-Log "BIOS Config Tool Path: $BIOSConfigTool"
	
	# Writing config file
	"BIOSConfig 1.0" | Out-File -FilePath $BIOSApplyFile -Force
	";" | Out-File -FilePath $BIOSApplyFile -Append
	
#	Write-Log "Adding TPM Device *Hidden to configuration file"
#	"TPM Device" | Out-File -FilePath $BIOSApplyFile -Append
#	"	*Hidden" | Out-File -FilePath $BIOSApplyFile -Append
#	"	Available" | Out-File -FilePath $BIOSApplyFile -Append
	
	Write-Log "Adding Clear TPM to configuration file"
	"Clear TPM" | Out-File -FilePath $BIOSApplyFile -Append
	"	No" | Out-File -FilePath $BIOSApplyFile -Append
	"	*On next boot" | Out-File -FilePath $BIOSApplyFile -Append
	
	# Reencode configuration file to ANSI
	[System.Io.File]::ReadAllText($BIOSApplyFile) | Out-File -FilePath $BIOSApplyFile -Encoding Default # HP BIOS config file must have encoding ANSI which is the value "Default". If omitted encoding is set to Unicode.
	
	# Apply Settings
	# Set BIOS password - some functions require password to enable, fx TPM
	$Process = Start-Process -FilePath "$BIOSConfigTool" -ArgumentList "/nspwd:`"$ParentDirectory\Tools\HP\Password\password.bin`" /log /logpath:`"$LogPath\BIOS_Set_TPMenable.log`"" -NoNewWindow -Wait -PassThru
	$ErrorCode = $Process.ExitCode
	Write-Log "Setting BIOS settings with exit code: $ErrorCode"
	
	$Process = Start-Process -FilePath "$BIOSConfigTool" -ArgumentList "/cspwd:`"$ParentDirectory\Tools\HP\Password\password.bin`" /Set:`"$BIOSApplyFile`" /log /logpath:`"$LogPath\BIOSResult_TPMenable.log`"" -NoNewWindow -Wait -PassThru
	$ErrorCode = $Process.ExitCode
	Write-Log "Setting BIOS settings with exit code: $ErrorCode"
	
	# Clear BIOS password
	$Process = Start-Process -FilePath "$BIOSConfigTool" -ArgumentList "/nspwdfile:`"`" /cspwdfile:`"$ParentDirectory\Tools\HP\Password\password.bin`" /log /logpath:`"$LogPath\BIOS_Clear_TPMenable.log`"" -NoNewWindow -Wait -PassThru
	$ErrorCode = $Process.ExitCode
	Write-Log "Setting BIOS settings with exit code: $ErrorCode"
	
	$Result = $TPM.SetPhysicalPresenceRequest(10) # Enable + Activate + Clear + Enable + Activate
	
	$RebootNeeded = $true
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

$tsenv.Value("OSDReboot") = $RebootNeeded
