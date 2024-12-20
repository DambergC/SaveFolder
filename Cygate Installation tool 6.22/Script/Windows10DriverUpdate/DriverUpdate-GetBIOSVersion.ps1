try
{
	$tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment
	$RunningInTs = $True
	# Hide the progress dialog
	$TSProgressUI = new-object -comobject Microsoft.SMS.TSProgressUI
	$TSProgressUI.CloseProgressDialog()
}
Catch
{
	# "Script is running outside a Task Sequence"
}

# Prepare for Logging
$LogPath = $tsenv.Value("_SMSTSLogPath")
if (Test-Path "$env:windir\ccm\Logs") { $LogPath = "$env:windir\CCM\Logs" }
$LogFile = "$LogPath\WindowsDriverUpdate.log"
$ScriptName = "[" + ([io.fileinfo]$MyInvocation.MyCommand.Definition).BaseName + "]"
if (Test-Path "$LogFile") { (Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Get BIOS Version" | Out-File -FilePath $LogFile -Append }
else { (Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Get BIOS Version" | Out-File -FilePath $LogFile -Force }

# Getting Manufacturer
$Manufacturer = (Get-WmiObject Win32_ComputerSystem).Manufacturer.TrimEnd()
(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Manufacturer from WMI: $Manufacturer" | Out-File -FilePath $LogFile -Append


if ($Manufacturer -like "*Lenovo*")
{
	(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Found manufacturer to be Lenovo" | Out-File -FilePath $LogFile -Append
	
	# BIOS Version
	$Value = (Get-WmiObject win32_bios).SMBIOSBIOSVersion
	if ($Value -like "*(*") { $Value = $Value.Substring($Value.IndexOf("(") + 1) }
	if ($Value -like "*)*") { $Value = $Value.Substring(0, $Value.IndexOf(")")).Trim() }
	$tsenv.Value("OSDBIOSVersion") = $Value
	(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName BIOS Version: $Value" | Out-File -FilePath $LogFile -Append
}

if ($Manufacturer -like "*Dell*")
{
	(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Found manufacturer to be Dell" | Out-File -FilePath $LogFile -Append
	
	# BIOS Version
	$Value = (Get-WmiObject win32_bios).SMBIOSBIOSVersion
	$tsenv.Value("OSDBIOSVersion") = $Value
	(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName BIOS Version: $Value" | Out-File -FilePath $LogFile -Append
}

if (($Manufacturer -like "*Hewlett*") -or ($Manufacturer -like "*HP*"))
{
	(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Found manufacturer to be Hewlett Packard (HP)" | Out-File -FilePath $LogFile -Append
	
	# BIOS Version
	$Value = (Get-WmiObject win32_bios).SMBIOSBIOSVersion
	$tsenv.Value("OSDBIOSVersion") = $Value
	(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName BIOS Version: $Value" | Out-File -FilePath $LogFile -Append
}
