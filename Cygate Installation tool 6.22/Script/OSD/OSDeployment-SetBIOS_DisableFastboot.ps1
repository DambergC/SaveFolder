# Preparing for TS environment
$tsenv = New-Object -ComObject Microsoft.SMS.TSEnvironment

# Prepare for Logging
$LogPath = $tsenv.Value("_SMSTSLogPath")
$LogFile = "$LogPath\Installation.log"
$ScriptName = "[" + ([io.fileinfo]$MyInvocation.MyCommand.Definition).BaseName + "]"
if (Test-Path "$LogFile") { (Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Disable Fastboot" | Out-File -FilePath $LogFile -Append }
else { (Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Disable Fastboot" | Out-File -FilePath $LogFile -Force }

# Set variables
$Bios_Settings = "$env:TEMP\BIOS_Settings.txt"
$ParentDirectory = (Get-Item $PSScriptRoot).parent.FullName
$BIOSApplyFile = "$env:TEMP\BIOS_Settings_Apply.txt"
$BIOSSettingsLog = "$LogPath\BIOSSettingsLog.log"
$RebootNeeded = $false
$tsenv.Value("OSDReboot") = $RebootNeeded
$FastBoot = $tsenv.Value("FastBoot")


# Remove old files
if (Test-Path "$BIOSApplyFile") { Remove-Item "$BIOSApplyFile" -Force }

# Getting Manufacturer
$Manufacturer = (Get-WmiObject Win32_ComputerSystem).Manufacturer.TrimEnd()
if ($Manufacturer -like "*Lenovo*")
{
	$ModelFriendlyName = (Get-WmiObject Win32_ComputerSystemProduct).Version.TrimEnd()
	$ModelNumber = (Get-WmiObject Win32_ComputerSystem).Model.TrimEnd().SubString(0, 4)
}
else
{
	$ModelFriendlyName = (Get-WmiObject Win32_ComputerSystem).Model.TrimEnd()
}

if (($Manufacturer -like "*Lenovo*") -and ($FastBoot -eq "Enable"))
{
	
	
	# Save BIOS settings
	$Process = (gwmi -class Lenovo_SaveBiosSettings -namespace root\wmi).SaveBiosSettings()
	$ErrorCode = $Process.return
	(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Saving BIOS settings with exit code: $ErrorCode" | Out-File -FilePath $LogFile -Append
}

if (($Manufacturer -like "*Dell*") -and ($FastBoot -eq "Enable"))
{
	# Writing config file
	"[cctk]" | Out-File -FilePath $BIOSApplyFile -Force
	
	# Run Tool
	$ToolPath = "$ParentDirectory\Tools\Dell\X86_64\cctk.exe"
	(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Tool Path: $ToolPath" | Out-File -FilePath $LogFile -Append
	
	# Reencode configuration file to ANSI
	[System.Io.File]::ReadAllText($BIOSApplyFile) | Out-File -FilePath $BIOSApplyFile -Encoding Default # Dell BIOS config file must have encoding ANSI which is the value "Default". If omitted encoding is set to Unicode.
	
	$process = Start-Process -FilePath `"$ToolPath`" -ArgumentList "--infile `"$BIOSApplyFile`" --logfile=`"$BIOSSettingsLog`"" -Wait -NoNewWindow -PassThru -ErrorAction SilentlyContinue
	$ErrorCode = $Process.ExitCode
	(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Applied BIOS settings with exit code: $ErrorCode" | Out-File -FilePath $LogFile -Append
}

if (($Manufacturer -like "*Hewlett*") -or ($Manufacturer -like "*HP*"))
{
	if ($ModelFriendlyName -like "*ProBook 640 G1*")
	{
		# Writing config file
		"BIOSConfig 1.0" | Out-File -FilePath $BIOSApplyFile -Force
		";" | Out-File -FilePath $BIOSApplyFile -Append
		
		# Common settings
		if ($tsenv.Value("FastBoot") -ne "Disable")
		{
			"Fast Boot" | Out-File -FilePath $BIOSApplyFile -Append
			"	*Disable" | Out-File -FilePath $BIOSApplyFile -Append
			"	Enable" | Out-File -FilePath $BIOSApplyFile -Append
			$RebootNeeded = $true
			(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Fast Boot=Disable to configuration file" | Out-File -FilePath $LogFile -Append
		}
		
		# Windows 10
		if ($tsenv.Value("OSDOSVersion") -eq "WIN10X64")
		{
			(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Settings in BIOS adjusted for Windows 10"
			if ($tsenv.Value("OSDLegacyBoot") -eq "Enable")
			{
				"Legacy Boot Options" | Out-File -FilePath $BIOSApplyFile -Append
				"	*Disable" | Out-File -FilePath $BIOSApplyFile -Append
				"	Enable" | Out-File -FilePath $BIOSApplyFile -Append
				$RebootNeeded = $true
				$tsenv.Value("OSDLegacyBoot") = $true
				(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Legacy Boot Options=Disable (Windows 10) to configuration file" | Out-File -FilePath $LogFile -Append
			}
			if ($tsenv.Value("OSDSecureBoot") -eq "Enable")
			{
				"Configure Legacy Support and Secure Boot" | Out-File -FilePath $BIOSApplyFile -Append
				"	*Legacy Support Enable and Secure Boot Disable" | Out-File -FilePath $BIOSApplyFile -Append
				"	Legacy Support Disable and Secure Boot Enable" | Out-File -FilePath $BIOSApplyFile -Append
				"	Legacy Support Disable and Secure Boot Disable" | Out-File -FilePath $BIOSApplyFile -Append
				$RebootNeeded = $true
				$tsenv.Value("OSDSecureBoot") = $false
				(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Secure Boot=Legacy Support Enable and Secure Boot Disable (Windows 10) to configuration file" | Out-File -FilePath $LogFile -Append
			}
		}
		
		
		
		# Reencode configuration file to ANSI
		[System.Io.File]::ReadAllText($BIOSApplyFile) | Out-File -FilePath $BIOSApplyFile -Encoding Default # HP BIOS config file must have encoding ANSI which is the value "Default". If omitted encoding is set to Unicode.
		
		# Run Tool
		If ((Get-CimInStance Win32_OperatingSystem).OSArchitecture -like "*64-Bit*") { $ToolPath = "$ParentDirectory\Tools\HP\BiosConfigUtility64.exe"; (Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName OS Architecture is 64-bit" | Out-File -FilePath $LogFile -Append }
		Else { $ToolPath = "$ParentDirectory\Tools\HP\BiosConfigUtility.exe"; (Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName OS Architecture is 32-bit" | Out-File -FilePath $LogFile -Append }
		(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Tool Path: $ToolPath" | Out-File -FilePath $LogFile -Append
		
		# Set BIOS password - some functions require password to enable, fx TPM
		$Process = Start-Process -FilePath "$ToolPath" -ArgumentList "/nspwd:`"$PSScriptRoot\HP\password.bin`" /log /logpath:`"$LogPath\BIOS_Set.log`"" -NoNewWindow -Wait -PassThru
		$ErrorCode = $Process.ExitCode
		(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Setting BIOS settings with exit code: $ErrorCode" | Out-File -FilePath $LogFile -Append
		
		$Process = Start-Process -FilePath "$ToolPath" -ArgumentList "/cspwd:`"$PSScriptRoot\HP\password.bin`" /Set:`"$BIOSApplyFile`" /log /logpath:`"$LogPath\BIOSResult.log`"" -NoNewWindow -Wait -PassThru
		$ErrorCode = $Process.ExitCode
		(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Setting BIOS settings with exit code: $ErrorCode" | Out-File -FilePath $LogFile -Append
		
		# Clear BIOS password
		$Process = Start-Process -FilePath "$ToolPath" -ArgumentList "/nspwdfile:`"`" /cspwdfile:`"$PSScriptRoot\HP\password.bin`" /log /logpath:`"$LogPath\BIOS_Clear.log`"" -NoNewWindow -Wait -PassThru
		$ErrorCode = $Process.ExitCode
		(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Setting BIOS settings with exit code: $ErrorCode" | Out-File -FilePath $LogFile -Append
	}
}

$tsenv.Value("OSDReboot") = $RebootNeeded
