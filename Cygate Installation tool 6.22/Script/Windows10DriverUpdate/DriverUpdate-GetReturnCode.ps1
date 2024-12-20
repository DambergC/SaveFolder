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
if (Test-Path "$LogFile") { (Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Get Return Code from Registry" | Out-File -FilePath $LogFile -Append }
else { (Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Get Return Code from Registry" | Out-File -FilePath $LogFile -Force }

# Get Return Code from Registry
try
{
	$ReturnCode = (Get-ItemProperty -Path hklm:software\Windows10driverUpdate -Name "ReturnCode").ReturnCode
	(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Getting Return Code from Registry: $ReturnCode" | Out-File -FilePath $LogFile -Append
	$tsenv.Value("returncode") = $ReturnCode
}
catch { (Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Error Getting Return Code from Registry" | Out-File -FilePath $LogFile -Append }

