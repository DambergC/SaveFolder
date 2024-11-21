
#connect to Task Sequence environment
$tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment
# read variables set in the task sequence
$returncode = $tsenv.Value("returncode")

# Prepare for Logging
$LogPath = $tsenv.Value("_SMSTSLogPath")
if (Test-Path "$env:windir\ccm\Logs") { $LogPath = "$env:windir\CCM\Logs" }
$LogFile = "$LogPath\WindowsDriverUpdate.log"
$ScriptName = "[" + ([io.fileinfo]$MyInvocation.MyCommand.Definition).BaseName + "]"
if (Test-Path "$LogFile") { (Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Check if User logged on" | Out-File -FilePath $LogFile -Append }
else { (Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Check if User logged on" | Out-File -FilePath $LogFile -Force }

# Check if target Windows 10 Build is correct
$tsenv.Value("OSDWindowsUpgrade") = $true
$Build = [System.Environment]::OSVersion.Version.Build
if ($Build -eq $tsenv.Value("OSDTargetBuild"))
{
	(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Target version $Build is matching driver version - continuing..." | Out-File -FilePath $LogFile -Append
	$tsenv.Value("OSDWindowsDriverUpdate") = $true
}
else
{
	(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Installed Windows version, $Build is lower than driver version - exiting..." | Out-File -FilePath $LogFile -Append
	$tsenv.Value("OSDWindowsDriverUpdate") = $false
	exit 1
}
$OSDWindowsDriverUpdate = $tsenv.Value("OSDWindowsDriverUpdate")

# Check if logged on user
(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Logged on user - Check if logged on user." | Out-File -FilePath $LogFile -Append
$LoggedOnUser = $false
$tsenv.Value("LoggedOnUser") = $false
$Sessions = WmiObject win32_ComputerSystem | select Username
foreach ($Session in $Sessions)
{
	$LocalUser = $Session.UserName
	if ($LocalUser -like "*\*")
	{
		$LoggedOnUser = $true; (Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Logged on user - A console user is logged on to this device: $LocalUser" | Out-File -FilePath $LogFile -Append
	}
}
if ($LoggedOnUser -eq $false) { (Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Logged on user - No console user is logged on to this device" | Out-File -FilePath $LogFile -Append }

$LoggedOnRDPUser = $false
try
{
	$RDPUser = quser /server:'localhost' 2>$null
	(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName RDP user: $RDPUser" | Out-File -FilePath $LogFile -Append
}
catch
{
	$ErrorMessage = $_.Exception.Message
	(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Error testing RDP user, exit code: $ErrorMessage" | Out-File -FilePath $LogFile -Append
}
	
$RDPUserFile = "$env:TEMP\RDPUser.txt"
if (Test-Path "$RDPUserFile") { Remove-Item -Path "$RDPUserFile" -Force }
$RDPUser | Out-File "$RDPUserFile" -Append
foreach ($line in [System.IO.File]::ReadLines($RDPUserFile))
{
	if ($line -like "*rdp-*")
	{
		$Position = $line.IndexOf("rdp-")
		$username = $line.Substring(0, $Position - 3)
		$username = $username.Trim()
		(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Logged on user - A RDP user is logged on to this device: $username" | Out-File -FilePath $LogFile -Append
		$LoggedOnUser = $true
		$LoggedOnRDPUser = $true
	}
}
$tsenv.Value("LoggedOnUser") = $LoggedOnUser

# Bitlocker status
$BitlockerProtection = $false
$ProtectionState = Get-WmiObject -Namespace ROOT\CIMV2\Security\Microsoftvolumeencryption -Class Win32_encryptablevolume -Filter "DriveLetter = 'c:'"
if ($ProtectionState.GetProtectionStatus().protectionStatus -like "*Protected*") { $BitlockerProtection = $true }
$tsenv.Value("BitlockerEnabled") = $BitlockerProtection

# Setting Return code to 0 - if no user logged on this value is needed to continue
$tsenv.Value("ReturnCode") = 0
$returncode = $tsenv.Value("ReturnCode")

# Copy Tool to local disk
Copy-Item -Path "$PSScriptRoot\*.exe" -Destination "$env:windir" -Force
(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Copy DriverUpdate-WindowsDriverUpdateMessage.exe to local disk" | Out-File -FilePath $LogFile -Append

(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Listing variables" | Out-File -FilePath $LogFile -Append
(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName LoggedOnUser: $LoggedOnUser" | Out-File -FilePath $LogFile -Append
(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName BitlockerEnabled: $BitlockerProtection" | Out-File -FilePath $LogFile -Append
(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName ReturnCode: $returncode" | Out-File -FilePath $LogFile -Append
(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName OSDWindowsdriverUpdate: $OSDWindowsDriverUpdate" | Out-File -FilePath $LogFile -Append


