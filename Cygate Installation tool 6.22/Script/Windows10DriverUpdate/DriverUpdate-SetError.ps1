Try
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
" " | Out-File -FilePath $LogFile -Append
if (Test-Path "$LogFile") { (Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Setting Error Code 8022" | Out-File -FilePath $LogFile -Append }
else { (Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Setting Error Code 8022" | Out-File -FilePath $LogFile -Force }

Exit 8022