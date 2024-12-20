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
if (Test-Path "$LogFile") { (Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Set result in Registry" | Out-File -FilePath $LogFile -Append }
else { (Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Set result in Registry" | Out-File -FilePath $LogFile -Force }

# Set result in registry for measurement - fx configuration baseline
try
{
	New-Item -Path "hklm:software\Windows10driverUpdate" -Force
	New-ItemProperty -Path "hklm:software\Windows10driverUpdate" -Name "Result" -Value 0 -Type Dword -Force
	(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Set value 0 in registry" | Out-File -FilePath $LogFile -Append
}
catch { (Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Error setting value in registry" | Out-File -FilePath $LogFile -Append }

