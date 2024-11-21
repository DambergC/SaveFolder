# Preparing for TS environment
try
{
	$tsenv = New-Object -ComObject Microsoft.SMS.TSEnvironment
	$RunningInTS = $true
}
catch
{
	$RunningInTS = $false
}

# Prepare for Logging
if ($RunningInTS -eq $true) { $LogPath = $tsenv.Value("_SMSTSLogPath") }
else { $LogPath = "$env:windir\Temp" }
$LogFile = "$LogPath\Installation.log"
$ScriptName = "[OSDStatus]"
if (Test-Path "$LogFile") { (Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Prepare Application Installation Status" | Out-File -FilePath $LogFile -Append }
else { (Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Prepare Application Installation Status" | Out-File -FilePath $LogFile -Force }

$logFileFail = "$env:windir\Temp\OSDFailApps.txt"
$OSDStatusSuccess = $false

# Get failure-messages from .txt-file
$failures = Get-Content -Path $logFileFail | sort
try
{
	if (($failures -eq $null) -or (!(Test-Path "$logFileFail"))) { $tsenv.Value("OSDStatusSuccess") = $true }
	else { $tsenv.Value("OSDStatusSuccess") = $false }
}
catch {}

try
{
	$OSDStatusSuccess = $tsenv.Value("OSDStatusSuccess")
	$OSDStatusShowOnSuccess = $tsenv.Value("OSDStatusShowOnSuccess")
}
catch { }

if (($OSDStatusShowOnSuccess -eq $false) -and ($OSDStatusSuccess -eq $true))
{
	# Do Not Show
	(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName OSDStatusShowOnSuccess is false and all application installations succeeded - will not show OSD status" | Out-File -FilePath $LogFile -Append
}
else
{
	#Hide the progress dialog
	(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName OSDStatusShowOnSuccess is true and/or all applications are not installed correctly - will show OSD status" | Out-File -FilePath $LogFile -Append
	Start-Sleep -Seconds 5
	
	try
	{
		$TSProgressUI = new-object -comobject Microsoft.SMS.TSProgressUI
	}
	catch { }
	
	try
	{
		$TSProgressUI.CloseProgressDialog()
	}
	catch { }
	
	Start-Sleep -Seconds 5
	
	try
	{
		$TSProgressUI.CloseProgressDialog()
	}
	catch { }
	
	# Run OSDStatus.exe
	cmd /c ".\OSDStatus.exe"
}