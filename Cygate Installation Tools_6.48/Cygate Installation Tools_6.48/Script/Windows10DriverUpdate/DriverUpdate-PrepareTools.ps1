# Preparing for TS environment
$tsenv = New-Object -ComObject Microsoft.SMS.TSEnvironment

# Prepare for Logging
$LogPath = $tsenv.Value("_SMSTSLogPath")
$LogFile = "$LogPath\Installation.log"
$ScriptName = "[" + ([io.fileinfo]$MyInvocation.MyCommand.Definition).BaseName + "]"
if (Test-Path "$LogFile") { (Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Prepare tools - copying to local disk" | Out-File -FilePath $LogFile -Append }
else { (Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Prepare tools - copying to local disk" | Out-File -FilePath $LogFile -Force }

$ParentDirectory = (Get-Item $PSScriptRoot).parent.parent.FullName

(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Parent directory of package: $ParentDirectory" | Out-File -FilePath $LogFile -Append

# Copy Tool to local disk
try
{
	Copy-Item -Path "$PSScriptRoot\*.exe" -Destination "$env:windir" -Force -ErrorAction Stop
	(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Copy OSDeployment-CustomMessage.exe to local disk" | Out-File -FilePath $LogFile -Append
}
catch { (Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Error: Failed to copy OSDeployment-CustomMessage.exe to local disk" | Out-File -FilePath $LogFile -Append }

# Copy ServiceUI to local disk
try
{
	Copy-Item -Path "$ParentDirectory\Tools\ServiceUI\ServiceUI.exe" -Destination "$env:windir" -Force -ErrorAction Stop
	(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Copy ServiceUI.exe to local disk" | Out-File -FilePath $LogFile -Append
}
catch
{ (Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Error: Failed to copy ServiceUI.exe to local disk" | Out-File -FilePath $LogFile -Append }
