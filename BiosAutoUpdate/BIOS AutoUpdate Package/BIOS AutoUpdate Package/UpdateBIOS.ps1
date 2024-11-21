$Version = "1.1"
# Version history
# 1.1 20221019 Add date to central log

# Get input argument - default update (check / update) where check only performs a control whether BIOS is up to date
# Get Friendly name (ex Thinkpad T460s) and model (ex. 20F9) of current hardware
# Match this with Supported hardware file downloaded together with software
# When upgrading content no adjustment in script needed - it will get subfolder automatically

# Get input argument - default update (check / update) where check only performs a control whether BIOS is up to date
# $Action = $args[0]
# if ($Action -eq $null) { $Action = "Update" }
# else { $Action = "Check" }

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
function Write-Log ($text)
{
	If (!(Test-Path "$env:windir\Logs\Software")) { New-Item -Path "$env:windir\Logs\Software" -ItemType dir -Force }
	if ($TSType -like "*Upgrade*")
	{
		if ((!(Test-Path "$env:windir\Logs\Software\WindowsUpgrade.log")) -and (Test-Path "$env:SystemDrive\Windows.old\Logs\Software\WindowsUpgrade.log")) { $global:LogFile = "$env:SystemDrive\Windows.old\Logs\Software\WindowsUpgrade.log" }
	}
	if ($TSType -like "*Install*")
	{
		try
		{
			$global:LogPath = $tsenv.Value("_SMSTSLogPath")
			$global:LogFile = "$LogPath\Installation.log"
		}
		catch { }
	}
	if ($LogFile -eq $null) { $global:LogFile = "$LogPath\BIOSupgrade.log" } 
	(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName $text" | Out-File -FilePath "$LogFile" -Append
}

function GetBIOSfolder ($Manufacturer, $ModelFriendlyName)
{
	$ModelFriendlyName = $ModelFriendlyName.Replace("HP","").Trim()
	$ModelFriendlyName = $ModelFriendlyName.Replace("Hewlett-Packard", "").Trim()
	$ModelFriendlyName = $ModelFriendlyName.Replace("Lenovo", "").Trim()
	$ModelFriendlyName = $ModelFriendlyName.Replace("Dell", "").Trim()
	if ($Manufacturer -like "*Hewlett*") { $Manufacturer = "HP" }
	$BIOSPath = "$PSScriptRoot\$Manufacturer\$ModelFriendlyName"
	Write-Log "GetBIOSfolder: Testing path $BIOSPath"
	if ($Manufacturer -like "*Lenovo*")
	{
		Write-Log "GetBIOSfolder: Manufacturer: $Manufacturer"
		$BIOSFolderVersion = (Get-ChildItem -Path $BIOSPath).Name
		Write-Log "GetBIOSfolder: BIOS folder version: $BIOSFolderVersion"
		if ($BIOSFolderVersion -ne $null)
		{
			$BIOSPathTotal = $BIOSPath + "\" + $BIOSFolderVersion
			Write-Log "GetBIOSfolder: BIOS path total: $BIOSPathTotal"
			if (Test-Path "$BIOSPathTotal\WINUPTP.EXE")
			{
				$RunType = "WINUPTP"
				if (($Architecture -eq "x64") -and (Test-Path "$BIOSPathTotal\WINUPTP64.EXE")) { $BIOSEXEName = "WINUPTP64.EXE" }
				else { $BIOSEXEName = "WINUPTP.EXE" }
				$BIOSFilePath = $BIOSPathTotal + "\" + $BIOSEXEName
			}
			if (Test-Path "$BIOSPathTotal\flash.cmd")
			{
				$RunType = "FlashCMD"
				if ($Architecture -eq "x64") { $BIOSEXEName = "Flash64.cmd"; $BIOSwflash = (Get-ChildItem -Path "$BIOSPathTotal" -Filter "*WFLASH2x64.*").Name; if (Test-Path "$BIOSPathTotal\$BIOSwflash") { $BIOSEXEName = $BIOSwflash } }
				else { $BIOSEXEName = "Flash.cmd"; $BIOSwflash = (Get-ChildItem -Path "$BIOSPathTotal" -Filter "*WFLASH2.*").Name; if (Test-Path "$BIOSPathTotal\$BIOSwflash") { $BIOSEXEName = $BIOSwflash } }
				$BIOSFilePath = $BIOSPathTotal + "\" + $BIOSEXEName
			}
		}
	}
	if ($Manufacturer -like "*Dell*")
	{
		Write-Log "GetBIOSfolder: Manufacturer: $Manufacturer"
		$RunType = "Dell"
		$BIOSFolderVersion = (Get-ChildItem -Path $BIOSPath).Name
		$BIOSPathTotal = $BIOSPath + "\" + $BIOSFolderVersion
		$BIOSEXEName = (Get-ChildItem -Path "$BIOSPathTotal" -Filter "*.exe").Name
		$BIOSVersionFile = (Get-ChildItem -Path "$BIOSPathTotal" -Filter "*.txt").Name
		$BIOSFilePath = $BIOSPathTotal + "\$BIOSEXEName"
		$BIOSVersionFilePath = $BIOSPathTotal + "\$BIOSVersionFile"
		if (($BIOSEXEName -ne $null) -and ($BIOSEXEName.Length -gt 2))
		{
			if (Test-Path "$BIOSVersionFilePath")
			{
				$File = [System.IO.File]::OpenText("$BIOSVersionFilePath")
				while ($null -ne ($line = $File.ReadLine()))
				{
					if ($line -ne $null) { $BIOSFolderVersion = $line; break }
				}
			}
			try
			{
				$BIOSVersion = [version]$BIOSVersion
				$BIOSFolderVersion = [version]$BIOSFolderVersion
			}
			catch
			{
				# BIOS version no numeric - mixed characters
			}
		}
	}
	if (($Manufacturer -like "*HP*") -or ($Manufacturer -like "*Hewlett*"))
	{
		Write-Log "GetBIOSfolder: Manufacturer: $Manufacturer"
		$RunType = "HP"
		$BIOSFolderVersion = (Get-ChildItem -Path "$BIOSPath").Name
		try { $BIOSPathTotal = $BIOSPath + "\" + $BIOSFolderVersion } catch { Write-Log "Error: failed to find Bios folder for model" }
		$BIOSFolderVersion = ($BIOSFolderVersion.Substring(0, $BIOSFolderVersion.IndexOf("Rev") - 1)).Trim()
		
		if ($Architecture -eq "x64")
		{
			# if (Test-Path "$BIOSPathTotal\HpFirmwareUpdRec64.exe") { $BIOSFilePath = "$BIOSPathTotal\HpFirmwareUpdRec64.exe"; $Argument = "-s -p`"$env:TEMP\Password.bin`" -r -b"; Write-Log "BIOS EXE: $BIOSFilePath"; $BIOSExist = $true; $BIOSEXEName = "HpFirmwareUpdRec64.exe" }
			if (Test-Path "$BIOSPathTotal\HpFirmwareUpdRec64.exe") { $BIOSFilePath = "$BIOSPathTotal\HpFirmwareUpdRec64.exe"; $Argument = "-s -p" + "$env:TEMP\Password.bin" + " -r -b"; Write-Log "BIOS EXE: $BIOSFilePath"; $BIOSExist = $true; $BIOSEXEName = "HpFirmwareUpdRec64.exe" }
			if (Test-Path "$BIOSPathTotal\HPBIOSUPDREC64.exe") { $BIOSFilePath = "$BIOSPathTotal\HPBIOSUPDREC64.exe"; $Argument = "-s -h -p" + "$env:TEMP\Password.bin" + " -r"; Write-Log "BIOS EXE: $BIOSFilePath"; $BIOSExist = $true; $BIOSEXEName = "HPBIOSUPDREC64.exe" }
			if (Test-Path "$BIOSPathTotal\HPBIOSUPDREC\HPBIOSUPDREC64.exe") { $BIOSFilePath = "$BIOSPathTotal\HPBIOSUPDREC\HPBIOSUPDREC64.exe"; $Argument = "-s -h -p" + "$env:TEMP\Password.bin" + " -r"; Write-Log "BIOS EXE: $BIOSFilePath"; $BIOSExist = $true; $BIOSEXEName = "HPBIOSUPDREC64.exe" }
			if (Test-Path "$BIOSPathTotal\hpqflash64.exe") { $BIOSFilePath = "$BIOSPathTotal\hpqflash64.exe"; $Argument = "-s -p" + "$env:TEMP\Password.bin" + " -r"; Write-Log "BIOS EXE: $BIOSFilePath"; $BIOSExist = $true; $BIOSEXEName = "hpqflash64.exe" }
			if ((Test-Path "$BIOSPathTotal\HPQFlash\hpqflash64.exe") -and (Test-Path "$BIOSPath\HPQFlash\rom.cab")) { $BIOSFilePath = "$BIOSPath\HPQFlash\hpqflash64.exe"; $Argument = "-s -p" + "$env:TEMP\Password.bin" + " -r"; Write-Log "BIOS EXE: $BIOSFilePath"; $BIOSExist = $true; $BIOSEXEName = "hpqflash64.exe" }
		}
		else
		{
			if (Test-Path "$BIOSPathTotal\HpFirmwareUpdRec.exe") { $BIOSFilePath = "$BIOSPathTotal\HpFirmwareUpdRec.exe"; $Argument = "-s -p" + "$env:TEMP\Password.bin" + " -r -b"; Write-Log "BIOS EXE: $BIOSFilePath"; $BIOSExist = $true; $BIOSEXEName = "HpFirmwareUpdRec.exe" }
			if (Test-Path "$BIOSPathTotal\HPBIOSUPDREC.exe") { $BIOSFilePath = "$BIOSPathTotal\HPBIOSUPDREC.exe"; $Argument = "-s -p" + "$env:TEMP\Password.bin" + " -r"; Write-Log "BIOS EXE: $BIOSFilePath"; $BIOSExist = $true; $BIOSEXEName = "HPBIOSUPDREC.exe" }
			if (Test-Path "$BIOSPathTotal\HPBIOSUPDREC\HPBIOSUPDREC.exe") { $BIOSFilePath = "$BIOSPathTotal\HPBIOSUPDREC\HPBIOSUPDREC.exe"; $Argument = "-s -p" + "$env:TEMP\Password.bin" + " -r"; Write-Log "BIOS EXE: $BIOSFilePath"; $BIOSExist = $true; $BIOSEXEName = "HPBIOSUPDREC.exe" }
			if (Test-Path "$BIOSPathTotal\hpqflash.exe") { $BIOSFilePath = "$BIOSPathTotal\hpqflash.exe"; $Argument = "-s -p" + "$env:TEMP\Password.bin" + " -r"; Write-Log "BIOS EXE: $BIOSFilePath"; $BIOSExist = $true; $BIOSEXEName = "hpqflash.exe" }
			if ((Test-Path "$BIOSPathTotal\HPQFlash\HpqFlash.exe") -and (Test-Path "$BIOSPathTotal\HPQFlash\rom.cab")) { $BIOSFilePath = "$BIOSFolder\HPQFlash\HpqFlash.exe"; $Argument = "-s -p" + "$env:TEMP\Password.bin" + " -r"; Write-Log "BIOS EXE: $BIOSFilePath"; $BIOSExist = $true; $BIOSEXEName = "hpqflash.exe" }
		}
	}
	return $BIOSFolderVersion, $BIOSPath, $BIOSPathTotal, $BIOSFilePath, $BIOSEXEName, $RunType, $Argument
}

function BIOS-Update-WinUptp
{
	$FlashSwitch = "-s"
	$RebootNeeded = $false
	if ($UseBIOSPassword -eq $true) { $FlashSwitch = $FlashSwitch + " /pass:$($BIOSPassword)" }
	if ($BIOSVersion -lt $BIOSFolderVersion)
	{
		Write-Log "BIOS-Update-WinUptp: BIOS Version in folder is higher than installed - upgrading, Folder version: $BIOSFolderVersion"
		Write-Log "BIOS-Update-WinUptp: BIOS upgrade type is (WINUPTP.exe)"
		Write-Log "BIOS-Update-WinUptp: BIOS path is: $BIOSPathTotal"
		Write-Log "BIOS-Update-WinUptp: BIOS file is: $BIOSFilePath"
		
		if (Test-Path "$BIOSFilePath")
		{
			$Process = Start-Process -FilePath "$BIOSFilePath" -WorkingDirectory "$BIOSPathTotal" -ArgumentList "$FlashSwitch" -Wait -PassThru
			$ErrorCode = $Process.ExitCode
			Write-Log "BIOS-Update-WinUptp: BIOS upgraded with exit code: $ErrorCode"
			if ($ErrorCode -eq 0) { $ErrorMessage = "BIOS update is successful and system will reboot. (normal update)" }
			if ($ErrorCode -eq 1) { $ErrorMessage = "BIOS update is successful and system does not reboot. (silent update)" }
			if ($ErrorCode -eq -1) { $ErrorMessage = "WINUPTP Option is undefined." }
			if ($ErrorCode -eq -2) { $ErrorMessage = "Driver(tpflhlp.sys) failed to load." }
			if ($ErrorCode -eq -3) { $ErrorMessage = "This utility does not support this system or OS." }
			if ($ErrorCode -eq -4) { $ErrorMessage = "This utility requires Administrator privileges to run." }
			if ($ErrorCode -eq -5) { $ErrorMessage = "BIOS image file does not match this system." }
			if ($ErrorCode -eq -6) { $ErrorMessage = "EC image file is damaged." }
			if ($ErrorCode -eq -7) { $ErrorMessage = "EC image file does not match this system." }
			if ($ErrorCode -eq -8) { $ErrorMessage = "The custom start up image file is missing or not a supported format." }
			if ($ErrorCode -eq -9) { $ErrorMessage = "BIOS image file is same as BIOS ROM." }
			if ($ErrorCode -eq -10) { $ErrorMessage = "AC/Battery is detached or battery is not charged." }
			Write-Log "BIOS-Update-WinUptp: Exit message translated: $ErrorMessage"
			try
			{
				Copy-Item -Path "$BIOSPathTotal\*.log" -Destination "$LogPath" -Force -ErrorAction Stop
				Write-Log "BIOS-Update-WinUptp: Copying BIOS Update log to Log Path: $LogPath"
			}
			catch { Write-Log "BIOS-Update-WinUptp: Error: could not copy BIOS update log file to log path" }
			$RebootNeeded = $true
		}
		else { Write-Log "BIOS-Update-WinUptp: Error: BIOS file NOT found!" }
	}
	else { Write-Log "BIOS-Update-WinUptp: BIOS Version in folder same as from machine - skip upgrade"; try { $tsenv.Value("OSDBIOSUpdateRequired") = $false } catch { } }
	return $RebootNeeded
}

function BIOS-Update-FlashCMD
{
	$FlashSwitch = "/quiet /sccm /ign"
	$RebootNeeded = $false
	if ($UseBIOSPassword -eq $true) { $FlashSwitch = $FlashSwitch + " /pass:$($BIOSPassword)" }
	if ($BIOSVersion -ne $BIOSFolderVersion)
	{
		Write-Log "BIOS-Update-FlashCMD: BIOS Version in folder different from machine - upgrading, Folder version: $BIOSFolderVersion"
		Write-Log "BIOS-Update-FlashCMD: BIOS upgrade type is ($BIOSEXEName)"
		Write-Log "BIOS-Update-FlashCMD: BIOS path is: $BIOSPathTotal"
		Write-Log "BIOS-Update-FlashCMD: BIOS file is: $BIOSFilePath"
		
		if (Test-Path "$BIOSFilePath")
		{
			Write-Log "BIOS-Update-FlashCMD: BIOS Exe file found"
			# Get BIOS ROM file
			try
			{
				$BIOSROM = (Get-ChildItem -Path "$BIOSPathTotal" -Filter "*.rom" -Recurse).Name
				Write-Log "BIOS-Update-FlashCMD: BIOS ROM file found: $BIOSROM"
			}
			catch { Write-Log "BIOS-Update-FlashCMD: Error: BIOS ROM file NOT found!" }
			if ($BIOSROM -ne $null)
			{
				$Process = Start-Process -FilePath "$BIOSFilePath" -ArgumentList "`"$BIOSPathTotal\$BIOSROM`" $FlashSwitch" -WorkingDirectory "$BIOSPathTotal" -Wait -PassThru -NoNewWindow
				$ErrorCode = $Process.ExitCode
				$RebootNeeded = $true
				Write-Log "BIOS-Update-FlashCMD: BIOS updated with exit code: $ErrorCode"
				Copy-Item -Path "$BIOSPathTotal\Winuptp.log" -Destination "$LogPath" -Force
				sleep -Seconds 10
			}
		}
		else { Write-Log "BIOS-Update-FlashCMD: Error: BIOS file NOT found!" }
	}
	else { Write-Log "BIOS-Update-FlashCMD: BIOS Version in folder same as from machine - skip upgrade"; try { $tsenv.Value("OSDBIOSUpdateRequired") = $false } catch { } }
	return $RebootNeeded
}

function BIOS-Update-Dell
{
	$RebootNeeded = $false
	$BIOSUpgradeNeeded = $false
	if ($BIOSFolderVersion -match "^[\d\.]+$")
	{
		# Only numeric in version
		if ($BIOSFolderVersion -gt $BIOSVersion) { $BIOSUpgradeNeeded = $true }
	}
	else
	{
		# Non-numeric in version number - ex. A10
		$BIOSFolderVersionTemp = $BIOSFolderVersion -replace "[^0-9]"
		$BIOSVersionTemp = $BIOSVersion -replace "[^0-9]"
		if ($BIOSFolderVersionTemp -gt $BIOSVersionTemp) { $BIOSUpgradeNeeded = $true }
	}
	
	if ($BIOSUpgradeNeeded -eq $true)
	{
		Write-Log "BIOS-Update-Dell: BIOS Version in folder ($BIOSFolderVersion) is higher than installed ($BIOSVersion) - upgrading"
		Write-Log "BIOS-Update-Dell: BIOS file path is: $BIOSFilePath"
		Write-Log "BIOS-Update-Dell: BIOS Executable: $BIOSEXEName"
		$ToolPath = "$PSScriptRoot\_Tools\Flash64W.exe"
		$Argument = "/b=" + [char]34 + $BIOSFilePath + [char]34 + " /s /f /l=" + [char]34 + "$LogPath\BIOSUpdate.log" + [char]34
		Write-Log "BIOS-Update-Dell: BIOS Update command: $ToolPath $Argument"
		$Process = Start-Process -FilePath "$ToolPath" -ArgumentList "$Argument" -NoNewWindow -Wait -PassThru -ErrorAction SilentlyContinue
		if (Test-Path "$LogPath\BIOSUpdate.log")
		{
			$RebootNeeded = $true
			$File = [System.IO.File]::OpenText("$LogPath\BIOSUpdate.log")
			while ($null -ne ($line = $File.ReadLine()))
			{
				if ($line -like "*Error*") { Write-Log "BIOS-Update-Dell: BIOS Update failed: $line"; $RebootNeeded = $false }
			}
			if ($RebootNeeded -eq $true) { Write-Log "BIOS-Update-Dell: BIOS Update succeeded, will reboot" }
		}
	}
	else { Write-Log "BIOS-Update-Dell: Upgrade not neccessary. Current BIOS version: $BIOSVersion , available version: $BIOSFolderVersion"; try { $tsenv.Value("OSDBIOSUpdateRequired") = $false }	catch { } }
	return $RebootNeeded
}

function BIOS-Update-HP
{
	$RebootNeeded = $false
	try
	{
		$BIOSVersion = [version]$BIOSVersion
		$BIOSFolderVersion = [version]$BIOSFolderVersion
		Write-Log "BIOS-Update-HP: BIOS Version: $BIOSVersion"
		Write-Log "BIOS-Update-HP: BIOS Folder Version: $BIOSFolderVersion"
	}
	catch { Write-Log "BIOS-Update-HP: Error: failed to get BIOS versions" }
	
	if ($BIOSFolderVersion -gt $BIOSVersion)
	{
		if (Test-Path "$env:TEMP\Password.bin") { Write-Log "$env:TEMP\Password.bin is found" } else { Write-Log "$env:TEMP\Password.bin is NOT found" }
		Write-Log "BIOS-Update-HP: Starting BIOS Update with command: $BIOSFilePath $Argument"
		$Process = Start-Process -FilePath "$BIOSFilePath" -ArgumentList "$Argument" -NoNewWindow -Wait -PassThru -ErrorAction SilentlyContinue
		$ErrorCode = $Process.ExitCode
		if ($ErrorCode -eq "3010") { $ErrorMessage = "SUCCESS:REBOOT=A restart is required to complete the install" }
		if ($ErrorCode -eq "3011") { $ErrorMessage = "SUCCESS:REBOOT=Rollback successful and previous flash preparation removed. A reboot is required." }
		if ($ErrorCode -eq "3012") { $ErrorMessage = "FAILURE:NOREBOOT=Rollback failed and previous flash preparation removal failed." }
		if ($ErrorCode -eq "1602") { $ErrorMessage = "CANCEL:NOREBOOT=The install is cannot complete due to a dependency" }
		if ($ErrorCode -eq "259") { $ErrorMessage = "FAILURE:NOREBOOT=Password file not found" }
		if ($ErrorCode -eq "273") { $ErrorMessage = "CANCEL:NOREBOOT=Flash did not update because update is same BIOS version" }
		if ($ErrorCode -eq "280") { $ErrorMessage = "CANCEL:NOREBOOT=BIOS installed is newer than the one you're attempting to install" }
		if ($ErrorCode -eq "282") { $ErrorMessage = "CANCEL:NOREBOOT=Flash did not update because update is an older BIOS version" }
		if ($ErrorCode -eq "290") { $ErrorMessage = "SUCCESS:NOREBOOT=Bitlocker is enabled and utility is running in silent mode." }
		if ($ErrorCode -eq "128") { $ErrorMessage = "FAILURE:NOREBOOT=Setup password does not match, or unable to read password file" }
		if ($ErrorCode -eq "9191") { $ErrorMessage = "FAILURE:NOREBOOT=Setup password bin file not found" }
		Write-Log "BIOS-Update-HP: BIOS Updated with exit code: $ErrorCode, message translated: $ErrorMessage"
		$RebootNeeded = $true
		$tsenv.Value("OSDReboot") = $RebootNeeded
	}
	else { Write-Log "BIOS-Update-HP: Upgrade not neccessary. Current BIOS version: $BIOSVersion , available version: $BIOSFolderVersion"; try { $tsenv.Value("OSDBIOSUpdateRequired") = $false } catch { } }
	return $RebootNeeded
}

#endregion Main Function

# Prepare for Logging
Write-Log " "
Write-Log "Update BIOS (script version $Version)"

try
{
	$global:TSType = $tsenv.Value("OSDTSType")
	Write-Log "Task sequence type is: $TSType (from TS variable)"
}
catch { Write-Log "Unable to find TS Type based on TS variable" }

try
{
	$ECPVersion = $tsenv.Value("OSDECPBIOSVersion")
	$ECPUpgradeDone = $tsenv.Value("OSDECPUpgradeDone")
	$BIOSVersion = $tsenv.Value("OSDBIOSVersion")
	$ECPVersion = $tsenv.Value("OSDECPBIOSVersion")
}
catch { }

# Define variables
$global:BIOSPath = ""
$global:BIOSPathTotal = ""
$global:BIOSFolderVersion = ""
$global:BIOSFilePath = ""
$global:UseBIOSPassword = $false
$global:BIOSFolderVersion = ""
$global:BIOSVersion = ""
$global:BIOSEXEName = ""
$global:RebootNeeded = $false
$global:BIOSPassword = ""
$global:ErrorCode = ""
$global:Architecture = ""
$PasswordTemp = "CygatePW"

# Prepare for Logging
if ($RunningInTs -eq $true) { $global:LogPath = $tsenv.Value("_SMSTSLogPath"); $global:LogFile = "$LogPath\Installation.log" }
else { $global:LogPath = "$env:windir\Logs\Software"; $global:LogFile = "$LogPath\BIOSupgrade.log" }
try
{
	$TSType = $tsenv.Value("OSDTSType")
	if ($TSType -eq "Upgrade")
	{
		$global:LogPath = "$env:windir\Logs\Software"
		$global:LogFile = "$LogPath\WindowsUpgrade.log"
		if ((!(Test-Path "$env:windir\Logs\Software\WindowsUpgrade.log")) -and (Test-Path "$env:SystemDrive\Windows.old\Logs\Software\WindowsUpgrade.log")) { $global:LogFile = "$env:SystemDrive\Windows.old\Logs\Software\WindowsUpgrade.log" }
	}
}
catch {}
$global:ErrorLog = "$LogPath\BIOSError.txt" # Pass error to text file to be picked up by CopyLog in OSD, result will be added to _Installation Errors.log in root of log share

# Set variables
if ($RunningInTs -eq $true) { $tsenv.Value("OSDReboot") = $RebootNeeded }

try { $VirtualMachine = $false; $VirtualMachine = $tsenv.Value("OSDVirtualMachine") } catch { Write-Log "Error: Could not determine if machine is virtual" }

if ($VirtualMachine -eq $false)
{
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
	
	If ((Get-CimInStance Win32_OperatingSystem).OSArchitecture -like "*64*") { $Architecture = "x64"; Write-Log "OS Architecture is 64-bit" }
	Else { $Architecture = "x86"; Write-Log "OS Architecture is 32-bit" }
	
	try
	{
		$OSVersionVariable = $tsenv.Value("OSDOSVersion")
		Write-Log "OS Version variable: $OSVersionVariable"
	}
	catch { }
	
	# Getting Manufacturer and model
	$Manufacturer = (Get-WmiObject Win32_ComputerSystem).Manufacturer.TrimEnd()
	Write-Log "Manufacturer: $Manufacturer"
	if ($Manufacturer -like "*Lenovo*")
	{
		$ModelFriendlyName = (Get-WmiObject Win32_ComputerSystemProduct).Version.TrimEnd()
		if ($ModelFriendlyName -like "*1st*") { $ModelFriendlyName = ($ModelFriendlyName -replace (" 1st", "")).Trim() }
		$ModelNumber = (Get-WmiObject Win32_ComputerSystem).Model.TrimEnd().SubString(0, 4)
	}
	else { $ModelFriendlyName = (Get-WmiObject Win32_ComputerSystem).Model.TrimEnd() }
	
	if (($Manufacturer -like "*HP*") -or ($Manufacturer -like "*Hewlett*"))
	{
		if ($ModelFriendlyName -like "* G1*") { $ModelFriendlyName = ($ModelFriendlyName.Substring(0, $ModelFriendlyName.IndexOf(" G1") + 3)).Trim(); Write-Log "HP - Model Trimmed (G1): $ModelFriendlyName" }
		if ($ModelFriendlyName -like "* G2*") { $ModelFriendlyName = ($ModelFriendlyName.Substring(0, $ModelFriendlyName.IndexOf(" G2") + 3)).Trim(); Write-Log "HP - Model Trimmed (G2): $ModelFriendlyName" }
		if ($ModelFriendlyName -like "* G3*") { $ModelFriendlyName = ($ModelFriendlyName.Substring(0, $ModelFriendlyName.IndexOf(" G3") + 3)).Trim(); Write-Log "HP - Model Trimmed (G3): $ModelFriendlyName" }
		if ($ModelFriendlyName -like "* G4*") { $ModelFriendlyName = ($ModelFriendlyName.Substring(0, $ModelFriendlyName.IndexOf(" G4") + 3)).Trim(); Write-Log "HP - Model Trimmed (G4): $ModelFriendlyName" }
		if ($ModelFriendlyName -like "* G5*") { $ModelFriendlyName = ($ModelFriendlyName.Substring(0, $ModelFriendlyName.IndexOf(" G5") + 3)).Trim(); Write-Log "HP - Model Trimmed (G5): $ModelFriendlyName" }
		if ($ModelFriendlyName -like "* G6*") { $ModelFriendlyName = ($ModelFriendlyName.Substring(0, $ModelFriendlyName.IndexOf(" G6") + 3)).Trim(); Write-Log "HP - Model Trimmed (G6): $ModelFriendlyName" }
		if ($ModelFriendlyName -like "* G7*") { $ModelFriendlyName = ($ModelFriendlyName.Substring(0, $ModelFriendlyName.IndexOf(" G7") + 3)).Trim(); Write-Log "HP - Model Trimmed (G7): $ModelFriendlyName" }
		if ($ModelFriendlyName -like "* G8*") { $ModelFriendlyName = ($ModelFriendlyName.Substring(0, $ModelFriendlyName.IndexOf(" G8") + 3)).Trim(); Write-Log "HP - Model Trimmed (G8): $ModelFriendlyName" }
		if ($ModelFriendlyName -like "* G9*") { $ModelFriendlyName = ($ModelFriendlyName.Substring(0, $ModelFriendlyName.IndexOf(" G9") + 3)).Trim(); Write-Log "HP - Model Trimmed (G9): $ModelFriendlyName" }
		
		if ($ModelFriendlyName -like "*SFF*") { $ModelFriendlyName = ($ModelFriendlyName.Replace("SFF", "")).Trim(); Write-Log "HP - Model Trimmed (SFF): $ModelFriendlyName" }
		if ($ModelFriendlyName -like "*USDT*") { $ModelFriendlyName = ($ModelFriendlyName.Replace("USDT", "")).Trim(); Write-Log "HP - Model Trimmed (USDT): $ModelFriendlyName" }
		if ($ModelFriendlyName -like "*TWR*") { $ModelFriendlyName = ($ModelFriendlyName.Replace("TWR", "")).Trim(); Write-Log "HP - Model Trimmed (TWR): $ModelFriendlyName" }
		if ($ModelFriendlyName -like "* DM*") { $ModelFriendlyName = ($ModelFriendlyName.Replace("DM", "")).Trim(); Write-Log "HP - Model Trimmed (DM): $ModelFriendlyName" }
		if ($ModelFriendlyName -like "* 35W*") { $ModelFriendlyName = ($ModelFriendlyName.Replace("35W", "")).Trim(); Write-Log "HP - Model Trimmed (35W): $ModelFriendlyName" }
		if ($ModelFriendlyName -like "* 65W*") { $ModelFriendlyName = ($ModelFriendlyName.Replace("65W", "")).Trim(); Write-Log "HP - Model Trimmed (65W): $ModelFriendlyName" }
		if ($ModelFriendlyName -like "*(TAA)*") { $ModelFriendlyName = ($ModelFriendlyName.Replace("(TAA)", "")).Trim(); Write-Log "HP - Model Trimmed (TAA): $ModelFriendlyName" }
		if ($ModelFriendlyName -like "* MINI*") { $ModelFriendlyName = ($ModelFriendlyName.Replace("MINI", "")).Trim(); Write-Log "HP - Model Trimmed (MINI): $ModelFriendlyName" }
		if ($ModelFriendlyName -like "* MT*") { $ModelFriendlyName = ($ModelFriendlyName.Replace("MT", "")).Trim(); Write-Log "HP - Model Trimmed (MT): $ModelFriendlyName" }
		if ($ModelFriendlyName -like "* Series*") { $ModelFriendlyName = ($ModelFriendlyName.Replace("Series", "")).Trim(); Write-Log "HP - Model Trimmed (Series): $ModelFriendlyName" }
		if ($ModelFriendlyName -like "* Mini*") { $ModelFriendlyName = ($ModelFriendlyName.Replace("Mini", "")).Trim(); Write-Log "HP - Model Trimmed (Mini): $ModelFriendlyName" }
		if ($ModelFriendlyName -like "* Desktop") { $ModelFriendlyName = ($ModelFriendlyName.Replace("Desktop", "")).Trim(); Write-Log "HP - Model Trimmed (Desktop): $ModelFriendlyName" }
		if ($ModelFriendlyName -like "* PC") { $ModelFriendlyName = ($ModelFriendlyName.Replace("PC", "")).Trim(); Write-Log "HP - Model Trimmed (PC): $ModelFriendlyName" }
		if ($ModelFriendlyName -like "* NoteBooK") { $ModelFriendlyName = ($ModelFriendlyName.Replace("NoteBooK", "")).Trim(); Write-Log "HP - Model Trimmed (NoteBooK): $ModelFriendlyName" }
	}
	
	if ($Manufacturer -like "*Dell*")
	{
		$Manufacturer = "Dell"
		if ($ModelFriendlyName -like "*Tower*") { $ModelFriendlyName = ($ModelFriendlyName.Replace("Tower", "")).Trim(); Write-Log "Dell - Model Trimmed (Tower): $ModelFriendlyName" }
		if ($ModelFriendlyName -like "*Rugged Extreme Tablet*") { $ModelFriendlyName = ($ModelFriendlyName.Replace("Rugged Extreme Tablet", "")).Trim(); Write-Log "Dell - Model Trimmed (Rugged Extreme Tablet): $ModelFriendlyName" }
	}
	
	Write-Log "Model Friendly Name: $ModelFriendlyName"
	if ($Manufacturer -like "*Lenovo*") { Write-Log "Model Number: $ModelNumber" }
	
	# BIOS Version
	$BIOSVersionFromVariable = $tsenv.Value("OSDBIOSVersion")
	Write-Log "BIOS version from variable: $BIOSVersionFromVariable"
	
	# Calculate BIOS version (stripping alphanumeric characters etc)
	$Value = (Get-WmiObject win32_bios).SMBIOSBIOSVersion
	if ($Value -like "*(*") { $Value = $Value.Substring($Value.IndexOf("(") + 1) }
	if ($Value -like "*)*") { $Value = $Value.Substring(0, $Value.IndexOf(")")).Trim() }
	$BIOSVersion = $Value
	if (($Manufacturer -like "*HP*") -or ($Manufacturer -like "*Hewlett*"))
	{
		if ($BIOSVersion -like "*Ver.*")
		{
			try
			{
				$BIOSVersion = ($BIOSVersion.Substring($BIOSVersion.IndexOf("Ver.") + 4)).Trim()
				Write-Log "BIOS version contains 'Ver.', stripping - new value: $BIOSVersion"
			}
			catch { Write-Log "Error: failed stripping BIOS version from 'Ver.'" }
		}
	}
	Write-Log "Current BIOS Version: $BIOSVersion"
	
	# Check if using BIOS Password
	$BIOSPassword = "1"
	$UseBIOSPassword = $false
	if ($tsenv.Value("OSDUseBIOSPassword") -eq $true)
	{
		$BIOSPassword = $tsenv.Value("OSDBIOSPassword1")
		if ($BIOSPassword.Length -gt 4) { $UseBIOSPassword = $true }
		else { $BIOSPassword = "1" }
		Write-Log "BIOS password is used"
	}
	else { Write-Log "BIOS password is NOT used" }
	
	$BIOSFolderVersion, $BIOSPath, $BIOSPathTotal, $BIOSFilePath, $BIOSEXEName, $RunType, $Argument = GetBIOSfolder $Manufacturer $ModelFriendlyName
	if ($BIOSFolderVersion -ne $null)
	{
		if (($BIOSEXEName -like "*.exe*") -or ($BIOSEXEName -like "*.cmd*")) { }
		else { $BIOSEXEName = "Error: could not find any BIOS update executable" }
		Write-Log "BIOS for Model found"
		Write-Log "Checking BIOS folder, BIOSFolderVersion:	    $BIOSFolderVersion"
		Write-Log "Checking BIOS folder, BIOSPath:              $BIOSPath"
		Write-Log "Checking BIOS folder, RunType:               $RunType"
		Write-Log "Checking BIOS folder, BIOSEXEName:           $BIOSEXEName"
		try { $tsenv.Value("OSDBIOSUpdateExpectedVersion") = $BIOSFolderVersion; $tsenv.Value("OSDModelFriendlyName") = $ModelFriendlyName }
		catch { }
	}
	else
	{
		Write-Log "Error: BIOS folder for this machine not found"
		if ($Manufacturer -like "*Lenovo*") { Write-Log "No BIOS found based on model friendly name: $ModelFriendlyName, Model Number: $ModelNumber"; (Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "No BIOS found based on model friendly name: $ModelFriendlyName, Model Number: $ModelNumber" | Out-File -FilePath "$ErrorLog" -Append }
		else { Write-Log "No BIOS found based on model friendly name: $ModelFriendlyName"; (Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "No BIOS found based on model friendly name: $ModelFriendlyName" | Out-File -FilePath "$ErrorLog" -Append }
	}
	
	# Upgrade Main BIOS
	if ($BIOSFolderVersion -ne $null)
	{
		Write-Log "BIOS folder version: $BIOSFolderVersion"
		if ($BIOSEXEName -like "*Error*")
		{
			Write-Log "No BIOS executable found - will not upgrade"
			try { $tsenv.Value("OSDBIOSUpdateRequired") = $true }
			catch { }
		}
		else
		{
			Write-Log "BIOS executable found: $BIOSEXEName - will continue upgrade"
			try { $tsenv.Value("OSDBIOSUpdateRequired") = $true }
			catch { }
			if ($RunType -eq "WINUPTP") { Write-Log "BIOS Update using WINUPTP"; $RebootNeeded = BIOS-Update-WinUptp }
			if ($RunType -eq "FlashCMD") { Write-Log "BIOS Update using FlashCMD"; $RebootNeeded = BIOS-Update-FlashCMD }
			if ($RunType -eq "Dell") { Write-Log "BIOS Update using Dell"; $RebootNeeded = BIOS-Update-Dell }
			if ($RunType -eq "HP")
			{
				Write-Log "BIOS Update using HP"
				
				If ($Architecture -like "*64*") { $BIOSPasswordTool = "$PSScriptRoot\_Tools\HPQPswd64.exe"; Write-Log "OS Architecture is 64-bit" }
				Else { $BIOSPasswordTool = "$PSScriptRoot\_Tools\HPQPswd.exe"; Write-Log "OS Architecture is 32-bit" }
				Write-Log "BIOS Password Tool Path: $BIOSPasswordTool"
				
				# Create Password file(s)
				if ($UseBIOSPassword -eq $true)
				{
					foreach ($Password in $BIOSPasswordArray)
					{
						$Process = Start-Process -FilePath "$BIOSPasswordTool" -ArgumentList "/s /f`"$env:TEMP\Password.bin`" /P`"$Password`"" -NoNewWindow -Wait -PassThru
						$ErrorCode = $Process.ExitCode
						Write-Log "BIOS Password bin file created using password: $Password with exit code: $ErrorCode"
						$RebootNeeded = BIOS-Update-HP
					}
				}
				else
				{
					Write-Log "Use BIOS variable is false, creating temporary password file"
					$Process = Start-Process -FilePath "$BIOSPasswordTool" -ArgumentList "/s /f`"$env:TEMP\Password.bin`" /P`"$PasswordTemp`"" -NoNewWindow -Wait -PassThru
					$ErrorCode = $Process.ExitCode
					Write-Log "BIOS Password bin file created using password: $PasswordTemp with exit code: $ErrorCode"
					$RebootNeeded = BIOS-Update-HP
				}
			}
		}
	}
	else { Write-Log "BIOS folder not found, skip upgrade" }
}
else { Write-Log "Machine is virtual - skipping BIOS upgrade" }

try
{
	$tsenv.Value("OSDReboot") = $RebootNeeded
	Write-Log "OSDReboot variable set to: $RebootNeeded"
}
catch { }

if ($ErrorCode -eq "1") { exit 0 }