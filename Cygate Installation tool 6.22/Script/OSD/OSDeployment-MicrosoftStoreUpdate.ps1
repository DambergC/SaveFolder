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
#endregion Main Function

# Prepare for Logging
Write-Log " "
Write-Log "Create schedule for Store Apps Update"

# Create scheduled task configuration file
Write-Log "Creating config file for importing schedule"
$ConfigFile = "$env:windir\config.txt"
$ConfigFileXML = "$env:windir\config.xml"

"<?xml version=`"1.0`" encoding=`"UTF-16`"?>" | Out-File -FilePath $ConfigFile -Force
"<Task version=`"1.2`" xmlns=`"http://schemas.microsoft.com/windows/2004/02/mit/task`">" | Out-File -FilePath $ConfigFile -Append
"<RegistrationInfo>" | Out-File -FilePath $ConfigFile -Append
"<Date>2018-11-07T10:33:55.9620483</Date>" | Out-File -FilePath $ConfigFile -Append
"<Author>Administrator</Author>" | Out-File -FilePath $ConfigFile -Append
"<URI>\Microsoft Store Update</URI>" | Out-File -FilePath $ConfigFile -Append
"</RegistrationInfo>" | Out-File -FilePath $ConfigFile -Append
"<Triggers>" | Out-File -FilePath $ConfigFile -Append
"<LogonTrigger>" | Out-File -FilePath $ConfigFile -Append
"<ExecutionTimeLimit>PT1H</ExecutionTimeLimit>" | Out-File -FilePath $ConfigFile -Append
"<Enabled>true</Enabled>" | Out-File -FilePath $ConfigFile -Append
"</LogonTrigger>" | Out-File -FilePath $ConfigFile -Append
"<CalendarTrigger>" | Out-File -FilePath $ConfigFile -Append
"<StartBoundary>2021-03-30T09:00:00</StartBoundary>" | Out-File -FilePath $ConfigFile -Append
"<ExecutionTimeLimit>PT1H</ExecutionTimeLimit>" | Out-File -FilePath $ConfigFile -Append
"<Enabled>true</Enabled>" | Out-File -FilePath $ConfigFile -Append
"<ScheduleByWeek>" | Out-File -FilePath $ConfigFile -Append
"<DaysOfWeek>" | Out-File -FilePath $ConfigFile -Append
"<Monday />" | Out-File -FilePath $ConfigFile -Append
"</DaysOfWeek>" | Out-File -FilePath $ConfigFile -Append
"<WeeksInterval>1</WeeksInterval>" | Out-File -FilePath $ConfigFile -Append
"</ScheduleByWeek>" | Out-File -FilePath $ConfigFile -Append
"</CalendarTrigger>" | Out-File -FilePath $ConfigFile -Append
"</Triggers>" | Out-File -FilePath $ConfigFile -Append
"<Principals>" | Out-File -FilePath $ConfigFile -Append
"<Principal id=`"Author`">" | Out-File -FilePath $ConfigFile -Append
"<UserId>S-1-5-18</UserId>" | Out-File -FilePath $ConfigFile -Append
"<RunLevel>HighestAvailable</RunLevel>" | Out-File -FilePath $ConfigFile -Append
"</Principal>" | Out-File -FilePath $ConfigFile -Append
"</Principals>" | Out-File -FilePath $ConfigFile -Append
"<Settings>" | Out-File -FilePath $ConfigFile -Append
"<MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>" | Out-File -FilePath $ConfigFile -Append
"<DisallowStartIfOnBatteries>true</DisallowStartIfOnBatteries>" | Out-File -FilePath $ConfigFile -Append
"<StopIfGoingOnBatteries>true</StopIfGoingOnBatteries>" | Out-File -FilePath $ConfigFile -Append
"<AllowHardTerminate>true</AllowHardTerminate>" | Out-File -FilePath $ConfigFile -Append
"<StartWhenAvailable>true</StartWhenAvailable>" | Out-File -FilePath $ConfigFile -Append
"<RunOnlyIfNetworkAvailable>true</RunOnlyIfNetworkAvailable>" | Out-File -FilePath $ConfigFile -Append
"<IdleSettings>" | Out-File -FilePath $ConfigFile -Append
"<StopOnIdleEnd>true</StopOnIdleEnd>" | Out-File -FilePath $ConfigFile -Append
"<RestartOnIdle>false</RestartOnIdle>" | Out-File -FilePath $ConfigFile -Append
"</IdleSettings>" | Out-File -FilePath $ConfigFile -Append
"<AllowStartOnDemand>true</AllowStartOnDemand>" | Out-File -FilePath $ConfigFile -Append
"<Enabled>true</Enabled>" | Out-File -FilePath $ConfigFile -Append
"<Hidden>true</Hidden>" | Out-File -FilePath $ConfigFile -Append
"<RunOnlyIfIdle>false</RunOnlyIfIdle>" | Out-File -FilePath $ConfigFile -Append
"<WakeToRun>false</WakeToRun>" | Out-File -FilePath $ConfigFile -Append
"<ExecutionTimeLimit>PT1H</ExecutionTimeLimit>" | Out-File -FilePath $ConfigFile -Append
"<Priority>7</Priority>" | Out-File -FilePath $ConfigFile -Append
"</Settings>" | Out-File -FilePath $ConfigFile -Append
"<Actions Context=`"Author`">" | Out-File -FilePath $ConfigFile -Append
"<Exec>" | Out-File -FilePath $ConfigFile -Append
"<Command>Powershell.exe</Command>" | Out-File -FilePath $ConfigFile -Append
"<Arguments>-ExecutionPolicy Bypass -File `"%WINDIR%\MicrosoftStoreUpdate.ps1`"</Arguments>" | Out-File -FilePath $ConfigFile -Append
"</Exec>" | Out-File -FilePath $ConfigFile -Append
"</Actions>" | Out-File -FilePath $ConfigFile -Append
"</Task>" | Out-File -FilePath $ConfigFile -Append

Get-Content -Path "$ConfigFile" | Out-File -FilePath "$ConfigFileXML" -Encoding default

$Process = Start-Process -FilePath "schtasks" -ArgumentList "/Create /XML `"$ConfigFileXML`" /TN `"\Microsoft Store Update`" /F /HRESULT" -NoNewWindow -Wait -PassThru -ErrorAction SilentlyContinue
$ErrorCode = $Process.ExitCode
Write-Log "imported task with exit code: $ErrorCode"

# Create Configuration file
Write-Log "Create script file"
$ConfigFile = "$env:windir\MicrosoftStoreUpdate.ps1"

[char]36 + "namespaceName = `"root\cimv2\mdm\dmmap`"" | Out-File -FilePath $ConfigFile -Force
[char]36 + "className = `"MDM_EnterpriseModernAppManagement_AppManagement01`"" | Out-File -FilePath $ConfigFile -Append
[char]36 + "wmiObj = Get-WmiObject -Namespace " + [char]36 + "namespaceName -Class " + [char]36 + "className" | Out-File -FilePath $ConfigFile -Append
[char]36 + "result = " + [char]36 + "wmiObj.UpdateScanMethod()" | Out-File -FilePath $ConfigFile -Append

