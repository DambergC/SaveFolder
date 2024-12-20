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
Write-Log "Removing Computer object from Domain"

$ComputerName = $tsenv.Value("OSDCOMPUTERNAME")
if ($tsenv.Value("OSDWebServiceAD") -ne $null) { $WebServiceAD = $tsenv.Value("OSDWebServiceAD") }

# Create scheduled task xml
Write-Log "Creating XML file for sceduled task"
$ScheduledTaskXML = "$env:windir\RemoveFromDomain.xml"
"<?xml version=`"1.0`" encoding=`"UTF-16`"?>" | Out-File -FilePath "$ScheduledTaskXML" -Force
"<Task version=`"1.4`" xmlns=`"http://schemas.microsoft.com/windows/2004/02/mit/task`">" | Out-File -FilePath "$ScheduledTaskXML" -Append
"<RegistrationInfo>" | Out-File -FilePath "$ScheduledTaskXML" -Append
"<Date>2019-10-01T12:45:19.4181595</Date>" | Out-File -FilePath "$ScheduledTaskXML" -Append
"<Author>Administrator</Author>" | Out-File -FilePath "$ScheduledTaskXML" -Append
"<URI>\RemoveFromDomain</URI>" | Out-File -FilePath "$ScheduledTaskXML" -Append
"</RegistrationInfo>" | Out-File -FilePath "$ScheduledTaskXML" -Append
"<Triggers>" | Out-File -FilePath "$ScheduledTaskXML" -Append
"<BootTrigger>" | Out-File -FilePath "$ScheduledTaskXML" -Append
"<ExecutionTimeLimit>PT30M</ExecutionTimeLimit>" | Out-File -FilePath "$ScheduledTaskXML" -Append
"<Enabled>true</Enabled>" | Out-File -FilePath "$ScheduledTaskXML" -Append
"<Delay>PT1M</Delay>" | Out-File -FilePath "$ScheduledTaskXML" -Append
"</BootTrigger>" | Out-File -FilePath "$ScheduledTaskXML" -Append
"</Triggers>" | Out-File -FilePath "$ScheduledTaskXML" -Append
"<Principals>" | Out-File -FilePath "$ScheduledTaskXML" -Append
"<Principal id=`"Author`">" | Out-File -FilePath "$ScheduledTaskXML" -Append
"<UserId>S-1-5-18</UserId>" | Out-File -FilePath "$ScheduledTaskXML" -Append
"<RunLevel>HighestAvailable</RunLevel>" | Out-File -FilePath "$ScheduledTaskXML" -Append
"</Principal>" | Out-File -FilePath "$ScheduledTaskXML" -Append
"</Principals>" | Out-File -FilePath "$ScheduledTaskXML" -Append
"<Settings>" | Out-File -FilePath "$ScheduledTaskXML" -Append
"<MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>" | Out-File -FilePath "$ScheduledTaskXML" -Append
"<DisallowStartIfOnBatteries>true</DisallowStartIfOnBatteries>" | Out-File -FilePath "$ScheduledTaskXML" -Append
"<StopIfGoingOnBatteries>true</StopIfGoingOnBatteries>" | Out-File -FilePath "$ScheduledTaskXML" -Append
"<AllowHardTerminate>true</AllowHardTerminate>" | Out-File -FilePath "$ScheduledTaskXML" -Append
"<StartWhenAvailable>false</StartWhenAvailable>" | Out-File -FilePath "$ScheduledTaskXML" -Append
"<RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>" | Out-File -FilePath "$ScheduledTaskXML" -Append
"<IdleSettings>" | Out-File -FilePath "$ScheduledTaskXML" -Append
"<StopOnIdleEnd>true</StopOnIdleEnd>" | Out-File -FilePath "$ScheduledTaskXML" -Append
"<RestartOnIdle>false</RestartOnIdle>" | Out-File -FilePath "$ScheduledTaskXML" -Append
"</IdleSettings>" | Out-File -FilePath "$ScheduledTaskXML" -Append
"<AllowStartOnDemand>true</AllowStartOnDemand>" | Out-File -FilePath "$ScheduledTaskXML" -Append
"<Enabled>true</Enabled>" | Out-File -FilePath "$ScheduledTaskXML" -Append
"<Hidden>false</Hidden>" | Out-File -FilePath "$ScheduledTaskXML" -Append
"<RunOnlyIfIdle>false</RunOnlyIfIdle>" | Out-File -FilePath "$ScheduledTaskXML" -Append
"<DisallowStartOnRemoteAppSession>false</DisallowStartOnRemoteAppSession>" | Out-File -FilePath "$ScheduledTaskXML" -Append
"<UseUnifiedSchedulingEngine>true</UseUnifiedSchedulingEngine>" | Out-File -FilePath "$ScheduledTaskXML" -Append
"<WakeToRun>false</WakeToRun>" | Out-File -FilePath "$ScheduledTaskXML" -Append
"<ExecutionTimeLimit>PT1H</ExecutionTimeLimit>" | Out-File -FilePath "$ScheduledTaskXML" -Append
"<Priority>7</Priority>" | Out-File -FilePath "$ScheduledTaskXML" -Append
"</Settings>" | Out-File -FilePath "$ScheduledTaskXML" -Append
"<Actions Context=`"Author`">" | Out-File -FilePath "$ScheduledTaskXML" -Append
"<Exec>" | Out-File -FilePath "$ScheduledTaskXML" -Append
"<Command>C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe</Command>" | Out-File -FilePath "$ScheduledTaskXML" -Append
"<Arguments>-executionpolicy bypass -file C:\Windows\RemoveFromDomain.ps1</Arguments>" | Out-File -FilePath "$ScheduledTaskXML" -Append
"</Exec>" | Out-File -FilePath "$ScheduledTaskXML" -Append
"</Actions>" | Out-File -FilePath "$ScheduledTaskXML" -Append
"</Task>" | Out-File -FilePath "$ScheduledTaskXML" -Append

$Process = Start-Process -FilePath "schtasks" -ArgumentList "/Change /Disable /TN RemoveFromDomain /HRESULT" -NoNewWindow -Wait -PassThru -ErrorAction SilentlyContinue
$ExitCode = $Process.ExitCode
Write-Log "Disable task RemoveFromDomain with exit code: $ExitCode"

$Process = Start-Process -FilePath "schtasks" -ArgumentList "/End /TN RemoveFromDomain /HRESULT" -NoNewWindow -Wait -PassThru -ErrorAction SilentlyContinue
$ExitCode = $Process.ExitCode
Write-Log "Stop task RemoveFromDomain with exit code: $ExitCode"

$Process = Start-Process -FilePath "schtasks" -ArgumentList "/Delete /TN RemoveFromDomain /F /HRESULT" -NoNewWindow -Wait -PassThru -ErrorAction SilentlyContinue
$ExitCode = $Process.ExitCode
Write-Log "Delete task RemoveFromDomain with exit code: $ExitCode"

$Process = Start-Process -FilePath "schtasks" -ArgumentList "/Create /TN RemoveFromDomain /HRESULT /XML `"$env:windir\RemoveFromDomain.xml`"" -NoNewWindow -Wait -PassThru -ErrorAction SilentlyContinue
$ExitCode = $Process.ExitCode
Write-Log "Create task RemoveFromDomain with exit code: $ExitCode"

# Copy Netdom tool
$ParentDirectory = (Get-Item $PSScriptRoot).parent.parent.FullName
Copy-Item -Path "$ParentDirectory\Tools\Microsoft\netdom.exe" -Destination "$env:windir\System32" -Force
Copy-Item -Path "$ParentDirectory\Tools\Microsoft\netdom.exe.mui" -Destination "$env:windir\System32\en-US" -Force
Write-Log "Copying Netdom Tool from $ParentDirectory\Tools\Microsoft to $env:windir\System32"

# Create RemoveFromDomain.ps1
Write-Log "Creating RemovefromDomain.ps1 in $env:windir"
$RemoveFromDomainFile = "$env:windir\RemoveFromDomain.ps1"

"# Prepare for Logging" | Out-File "$RemoveFromDomainFile" -Force
"XXLogFile = `"XXenv:windir\Logs\Software\RemoveFromDomain.log`"" | Out-File "$RemoveFromDomainFile" -Append
"XXScriptName = `"[`" + ([io.fileinfo]XXMyInvocation.MyCommand.Definition).BaseName + `"]`"" | Out-File "$RemoveFromDomainFile" -Append
"if (Test-Path `"XXLogFile`") { (Get-Date).ToString(`"yy-MM-dd HH:mm:ss`") + `"   `" + `"XXScriptName Remove Computer from domain`" | Out-File -FilePath XXLogFile -Append }" | Out-File "$RemoveFromDomainFile" -Append
"else { (Get-Date).ToString(`"yy-MM-dd HH:mm:ss`") + `"   `" + `"XXScriptName Remove Computer from domain`" | Out-File -FilePath XXLogFile -Force }" | Out-File "$RemoveFromDomainFile" -Append
" " | Out-File "$RemoveFromDomainFile" -Append
"XXProcessRunning = XXtrue" | Out-File "$RemoveFromDomainFile" -Append
"while (XXProcessRunning -ne XXnull)" | Out-File "$RemoveFromDomainFile" -Append
"{" | Out-File "$RemoveFromDomainFile" -Append
"XXProcessRunning = Get-Process TSManager -ErrorAction SilentlyContinue" | Out-File "$RemoveFromDomainFile" -Append
"Start-Sleep -Seconds 5" | Out-File "$RemoveFromDomainFile" -Append
"(Get-Date).ToString(`"yy-MM-dd HH:mm:ss`") + `"   `" + `"XXScriptName Script running in Task sequence - waiting for process to end`" | Out-File -FilePath XXLogFile -Append" | Out-File "$RemoveFromDomainFile" -Append
"}" | Out-File "$RemoveFromDomainFile" -Append
#"Start-Sleep -Seconds 60" | Out-File "$RemoveFromDomainFile" -Append
#"XXProcessActive = Get-Process TSManager -ErrorAction SilentlyContinue" | Out-File "$RemoveFromDomainFile" -Append
#"if (XXProcessActive -eq XXnull) { XXRunningInTS = XXfalse }" | Out-File "$RemoveFromDomainFile" -Append
#"else { XXRunningInTS = XXtrue }" | Out-File "$RemoveFromDomainFile" -Append
#"if (XXRunningInTS -eq XXtrue)" | Out-File "$RemoveFromDomainFile" -Append
#"{" | Out-File "$RemoveFromDomainFile" -Append
#"(Get-Date).ToString(`"yy-MM-dd HH:mm:ss`") + `"   `" + `"XXScriptName Script running in Task sequence - exit and wait for another restart`" | Out-File -FilePath XXLogFile -Append" | Out-File "$RemoveFromDomainFile" -Append
#"exit 0" | Out-File "$RemoveFromDomainFile" -Append
#"}" | Out-File "$RemoveFromDomainFile" -Append
#"else { (Get-Date).ToString(`"yy-MM-dd HH:mm:ss`") + `"   `" + `"XXScriptName Script not running in Task Sequence - will continue`" | Out-File -FilePath XXLogFile -Append }" | Out-File "$RemoveFromDomainFile" -Append
" " | Out-File "$RemoveFromDomainFile" -Append
"XXvalueExists = (Get-Item `"HKLM:\SOFTWARE\Cygate`" -EA Ignore).Property -contains `"Installed`"" | Out-File "$RemoveFromDomainFile" -Append
"if (XXvalueExists -eq XXfalse)" | Out-File "$RemoveFromDomainFile" -Append
"{" | Out-File "$RemoveFromDomainFile" -Append
"(Get-Date).ToString(`"yy-MM-dd HH:mm:ss`") + `"   `" + `"XXScriptName Installation not ready HKLM:\SOFTWARE\Cygate value installed is: XXvalueExists, will not remove from domain yet`" | Out-File -FilePath XXLogFile -Append" | Out-File "$RemoveFromDomainFile" -Append
"exit 0" | Out-File "$RemoveFromDomainFile" -Append
"}" | Out-File "$RemoveFromDomainFile" -Append
"else { (Get-Date).ToString(`"yy-MM-dd HH:mm:ss`") + `"   `" + `"XXScriptName Installation ready HKLM:\SOFTWARE\Cygate value installed is: XXvalueExists, will remove from domain`" | Out-File -FilePath XXLogFile -Append }" | Out-File "$RemoveFromDomainFile" -Append
[char]36 + "Domain = (Get-WmiObject Win32_ComputerSystem).Domain" | Out-File "$RemoveFromDomainFile" -Append
"try" | Out-File "$RemoveFromDomainFile" -Append
"{" | Out-File "$RemoveFromDomainFile" -Append
[char]36 + "Process = Start-Process -FilePath `"netdom.exe`" -ArgumentList `"remove XXenv:COMPUTERNAME /Domain:XXDomain /UserD:user /PasswordD:dummy /Force`" -Wait -PassThru -NoNewWindow -ErrorAction SilentlyContinue" | Out-File "$RemoveFromDomainFile" -Append
[char]36 + "ErrorCode = " + [char]36 + "Process.ExitCode"
"(Get-Date).ToString(`"yy-MM-dd HH:mm:ss`") + `"   `" + `"XXScriptName Computer Removed from domain: XXDomain with exit code:XXErrorCode`" | Out-File -FilePath `"XXLogFile`" -Append" | Out-File "$RemoveFromDomainFile" -Append
"}" | Out-File "$RemoveFromDomainFile" -Append
"catch { (Get-Date).ToString(`"yy-MM-dd HH:mm:ss`") + `"   `" + `"XXScriptName Error: Failed to remove computer from domain`" | Out-File -FilePath `"XXLogFile`" -Append }" | Out-File "$RemoveFromDomainFile" -Append
" " | Out-File "$RemoveFromDomainFile" -Append
" # Remove computer object from domain using web service" | Out-File "$RemoveFromDomainFile" -Append
"try" | Out-File "$RemoveFromDomainFile" -Append
"{" | Out-File "$RemoveFromDomainFile" -Append
"XXWebServiceAD = `"YYOSDWebServiceAD`"" | Out-File "$RemoveFromDomainFile" -Append
"(Get-Date).ToString(`"yy-MM-dd HH:mm:ss`") + `"   `" + `"XXScriptName Removing Computer object from AD using web server: XXWebServiceAD`" | Out-File -FilePath XXLogFile -Append" | Out-File "$RemoveFromDomainFile" -Append
"XXADWeb = New-WebServiceProxy -Uri XXWebServiceAD" | Out-File "$RemoveFromDomainFile" -Append
"(Get-Date).ToString(`"yy-MM-dd HH:mm:ss`") + `"   `" + `"XXScriptName AD Webservice: XXADWeb`" | Out-File -FilePath XXLogFile -Append" | Out-File "$RemoveFromDomainFile" -Append
"XXResult = XXADWeb.DeleteComputerForced(`"XXenv:COMPUTERNAME`")" | Out-File "$RemoveFromDomainFile" -Append
"(Get-Date).ToString(`"yy-MM-dd HH:mm:ss`") + `"   `" + `"XXScriptName Computer object: XXComputerName removed from domain:  XXResult`" | Out-File -FilePath XXLogFile -Append" | Out-File "$RemoveFromDomainFile" -Append
"}" | Out-File "$RemoveFromDomainFile" -Append
"catch { (Get-Date).ToString(`"yy-MM-dd HH:mm:ss`") + `"   `" + `"XXScriptName Error: failed to remove Computer object from AD`" | Out-File -FilePath XXLogFile -Append }" | Out-File "$RemoveFromDomainFile" -Append
" " | Out-File "$RemoveFromDomainFile" -Append
"# Get Local Administrator Name" | Out-File "$RemoveFromDomainFile" -Append
"Try" | Out-File "$RemoveFromDomainFile" -Append
"{" | Out-File "$RemoveFromDomainFile" -Append
"Add-Type -AssemblyName System.DirectoryServices.AccountManagement" | Out-File "$RemoveFromDomainFile" -Append
"XXPrincipalContext = New-Object System.DirectoryServices.AccountManagement.PrincipalContext([System.DirectoryServices.AccountManagement.ContextType]::Machine, XXenv:COMPUTERNAME)" | Out-File "$RemoveFromDomainFile" -Append
"XXUserPrincipal = New-Object System.DirectoryServices.AccountManagement.UserPrincipal(XXPrincipalContext)" | Out-File "$RemoveFromDomainFile" -Append
"XXSearcher = New-Object System.DirectoryServices.AccountManagement.PrincipalSearcher" | Out-File "$RemoveFromDomainFile" -Append
"XXSearcher.QueryFilter = XXUserPrincipal" | Out-File "$RemoveFromDomainFile" -Append
"XXAdminName = XXSearcher.FindAll() | Where-Object { XX_.Sid -Like `"*-500`" }" | Out-File "$RemoveFromDomainFile" -Append
"XXAdminName = XXAdminName.Name" | Out-File "$RemoveFromDomainFile" -Append
"(Get-Date).ToString(`"yy-MM-dd HH:mm:ss`") + `"   `" + `"XXScriptName Local Administrator friendly name: XXAdminName`" | Out-File -FilePath XXLogFile -Append" | Out-File "$RemoveFromDomainFile" -Append
"}" | Out-File "$RemoveFromDomainFile" -Append
"Catch" | Out-File "$RemoveFromDomainFile" -Append
"{" | Out-File "$RemoveFromDomainFile" -Append
"(Get-Date).ToString(`"yy-MM-dd HH:mm:ss`") + `"   `" + `"XXScriptName Error: Failed to find friendly name of local Administrator account: XX(XX_.Exception.Message)`" | Out-File -FilePath XXLogFile -Append" | Out-File "$RemoveFromDomainFile" -Append
"}" | Out-File "$RemoveFromDomainFile" -Append
" " | Out-File "$RemoveFromDomainFile" -Append
"# Enable local admin" | Out-File "$RemoveFromDomainFile" -Append
"Get-LocalUser -Name `"XXAdminName`" | Enable-LocalUser" | Out-File "$RemoveFromDomainFile" -Append
" " | Out-File "$RemoveFromDomainFile" -Append
"# Rename Workgroup" | Out-File "$RemoveFromDomainFile" -Append
"Add-Computer -WorkgroupName `"WORKGROUP`" -Force -ErrorAction SilentlyContinue" | Out-File "$RemoveFromDomainFile" -Append
" " | Out-File "$RemoveFromDomainFile" -Append
"# Remove scheduled task after unjoining from domain" | Out-File "$RemoveFromDomainFile" -Append
"XXProcess = Start-Process -FilePath `"schtasks`" -ArgumentList `"/Delete /TN RemoveFromDomain /F /HRESULT`" -NoNewWindow -Wait -PassThru -ErrorAction SilentlyContinue" | Out-File "$RemoveFromDomainFile" -Append
"XXExitCode = XXProcess.ExitCode" | Out-File "$RemoveFromDomainFile" -Append
"(Get-Date).ToString(`"yy-MM-dd HH:mm:ss`") + `"   `" + `"XXScriptName Delete task RemoveFromDomain with exit code: XXExitCode`"" | Out-File "$RemoveFromDomainFile" -Append
" " | Out-File "$RemoveFromDomainFile" -Append
"Set-ItemProperty -Path `"HKLM:\SOFTWARE\Cygate`" -Name `"RemovedFromDomain`" -Value `"True`" -Force -ErrorAction SilentlyContinue" | Out-File "$RemoveFromDomainFile" -Append
" " | Out-File "$RemoveFromDomainFile" -Append
"Restart-Computer -ComputerName `"XXenv:COMPUTERNAME`" -Force" | Out-File "$RemoveFromDomainFile" -Append

# Set variables in RemoveFromDomain.ps1
(Get-Content "$env:windir\RemoveFromDomain.ps1") -replace 'XX', '$' | Set-Content "$env:windir\RemoveFromDomain.ps1"
$OSDWebServiceAD = $null
try
{
	$OSDWebServiceAD = $tsenv.Value("OSDWebServiceAD")
}
catch { }

if ($tsenv.Value("OSDWebServiceAD") -ne $null)
{
	Write-Log "AD WebService found: $OSDWebServiceAD"
	$WebServiceAD = $OSDWebServiceAD
	(Get-Content "$env:windir\RemoveFromDomain.ps1") -replace 'YYOSDWebServiceAD', "$WebServiceAD" | Set-Content "$env:windir\RemoveFromDomain.ps1"
}
else { Write-Log "AD WebService not found" }

# Give user permissions to update (NTFS)
if (Test-Path "$env:windir\Logs\Software")
{
	$FullPath = "$env:windir\Logs\Software"
	icacls ("$FullPath") /Grant "*S-1-5-32-545:(OI)(CI)M" /T
	icacls ("$FullPath") /Grant "*S-1-5-32-545:M" /T
}

# Make computer restart at first boot after deployment is finished
REG ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" /V "Restart" /T REG_SZ /D "shutdown.exe /r /t 10" /F
