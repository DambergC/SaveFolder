$AllowedMPs = "ServerName"
$RestartService = $false
$CleanUp = $false
$LogFile = "$env:windir\Logs\SCCMClientRegistration.log"
$ScriptName = "[" + ([io.fileinfo]$MyInvocation.MyCommand.Definition).BaseName + "]"
if (Test-Path "$LogFile") { (Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Checking if SCCM agent tries to register towards correct MP" | Out-File -FilePath $LogFile -Append }
else { (Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Checking if SCCM agent tries to register towards correct MP" | Out-File -FilePath $LogFile -Force }

# Check if array
$MPArray = $false
if ($AllowedMPs -like "*,*")
{
	$MPArray = $true
	$AllowedMPArray = ($AllowedMPs -split ",").trim()
}

$MPServerWorking = $false
if ($MPArray -eq $true)
{
	foreach ($AllowedMP in $AllowedMPArray)
	{
		$WebServiceSCCM = "http://$AllowedMP/sms_mp/.sms_aut?mplist"
		$Error.clear()
		$ErrorCode = "Unknown error"
		try
		{
			$HTTP_Request = [System.Net.WebRequest]::Create("$WebServiceSCCM")
			$HTTP_Response = $HTTP_Request.GetResponse()
			$HTTP_Status = [int]$HTTP_Response.StatusCode
			(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Testing URL: http://$AllowedMP/sms_mp/.sms_aut?mplist" | Out-File -FilePath $LogFile -Append
			
			If ($HTTP_Status -eq 200)
			{
				(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Tested URL: http://$AllowedMP/sms_mp/.sms_aut?mplist - successful" | Out-File -FilePath $LogFile -Append
				$MPServerWorking = $true
				$AllowedMPs = $AllowedMP
			}
			Else
			{
				(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Tested URL: http://$AllowedMP/sms_mp/.sms_aut?mplist - Error: not able to connect" | Out-File -FilePath $LogFile -Append
			}
			
			$HTTP_Response.Close()
		}
		catch { (Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Failed connecting to: $AllowedMP" | Out-File -FilePath $LogFile -Append }
	}
}


# Check if Registry changed
$MPServer = (Get-WmiObject -Namespace "Root\CCM" -Class SMS_Authority).CurrentManagementPoint
if ($MPServerWorking -eq $true) { $MPServer = $AllowedMPs }
(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Current Management Point value from WMI: $MPServer, should be: $AllowedMPs" | Out-File -FilePath $LogFile -Append
if ($MPServer -notlike $AllowedMPs)
{
	REG ADD "HKLM\SOFTWARE\Microsoft\CCM" /v "AllowedMPs" /t REG_MULTI_SZ /d $AllowedMPs /f
	(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName AllowedMPs registry key does not match, changing to: $AllowedMPs" | Out-File -FilePath $LogFile -Append
	$RestartService = $true
}

if ($RestartService -eq $false)
{
	$LogFiletoCheck = "$env:windir\CCM\Logs\ClientIDManagerStartup.log"
	(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Reading $LogFiletoCheck" | Out-File -FilePath $LogFile -Append
	$Log1 = "NotOK"
	$LogContent = Get-Content "$LogFiletoCheck"
	foreach ($line in $LogContent)
	{
		if (($line -like "*Client is registered. Server*") -or ($line -like "*Client is already registered.*"))
		{
			$Log1 = "OK"
			(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Client is registered in $LogFiletoCheck" | Out-File -FilePath $LogFile -Append
			break
		}
	}
	if ($Log1 -eq "NotOK")
	{
		(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Client is NOT registered in $LogFiletoCheck" | Out-File -FilePath $LogFile -Append
		REG ADD "HKLM\SOFTWARE\Microsoft\CCM" /v "AllowedMPs" /t REG_MULTI_SZ /d $AllowedMPs /f
		(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Allowed MP is added to registry, checking registration next cycle" | Out-File -FilePath $LogFile -Append
	}
}

if (($Log1 -eq "OK") -and ($RestartService -eq $false))
{
	$LogFiletoCheck = "$env:windir\CCM\Logs\ClientServicing.log"
	$Log2 = "NotOK"
	(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Reading $LogFiletoCheck" | Out-File -FilePath $LogFile -Append
	$LogContent = Get-Content "$LogFiletoCheck"
	foreach ($line in $LogContent)
	{
		if ($line -like "*Client is registered. Sending*")
		{
			$Log2 = "OK"
			(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Client is registered in $LogFiletoCheck" | Out-File -FilePath $LogFile -Append
			break
		}
	}
	if ($Log2 -eq "NotOK")
	{
		(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Client is NOT registered in $LogFiletoCheck" | Out-File -FilePath $LogFile -Append
		REG ADD "HKLM\SOFTWARE\Microsoft\CCM" /v "AllowedMPs" /t REG_MULTI_SZ /d $AllowedMPs /f
		(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Allowed MP is added to registry, checking registration next cycle" | Out-File -FilePath $LogFile -Append
	}
}

if (($Log1 -eq "OK") -and ($Log2 -eq "OK") -and ($RestartService -eq $false))
{
	$LogFiletoCheck = "$env:windir\CCM\Logs\LocationServices.log"
	$Log3 = "NotOK"
	(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Reading $LogFiletoCheck" | Out-File -FilePath $LogFile -Append
	$LogContent = Get-Content "$LogFiletoCheck"
	foreach ($line in $LogContent)
	{
		if ($line -like "*Successfully created context from the raw certificate*")
		{
			$Log3 = "OK"
			(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Client is registered in $LogFiletoCheck, all logs OK. Client is now ready." | Out-File -FilePath $LogFile -Append
			$CleanUp = $true
			break
		}
	}
	if ($Log3 -eq "NotOK")
	{
		(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Client is NOT registered in $LogFiletoCheck" | Out-File -FilePath $LogFile -Append
		REG ADD "HKLM\SOFTWARE\Microsoft\CCM" /v "AllowedMPs" /t REG_MULTI_SZ /d $AllowedMPs /f
		(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Allowed MP is added to registry, checking registration next cycle" | Out-File -FilePath $LogFile -Append
	}
}

if ($RestartService -eq $true)
{
	$Process = Start-Process -FilePath "net.exe" -ArgumentList "stop ccmexec" -NoNewWindow -Wait -PassThru -ErrorAction SilentlyContinue
	$ErrorCode = $Process.ExitCode
	(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Stopping SMS Agent service with exit code: $ErrorCode" | Out-File -FilePath $LogFile -Append
	
	$Process = Start-Process -FilePath "net.exe" -ArgumentList "start ccmexec" -NoNewWindow -Wait -PassThru -ErrorAction SilentlyContinue
	$ErrorCode = $Process.ExitCode
	(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Starting SMS Agent service with exit code: $ErrorCode" | Out-File -FilePath $LogFile -Append
	
	Start-Sleep -Seconds 30
	
	# Trigger Machine Policy
	Invoke-Command -ComputerName $env:COMPUTERNAME -ScriptBlock {
	Invoke-WmiMethod -Namespace "Root\CCM" -Class SMS_Client -Name TriggerSchedule -ArgumentList "{00000000-0000-0000-0000-000000000021}"
	}
}

if ($CleanUp -eq $true)
{
	(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName SCCM Agent is now registered, cleaning up scheduled task" | Out-File -FilePath $LogFile -Append
	$Process = Start-Process -FilePath "schtasks" -ArgumentList "/Delete /TN SetAllowedMPs /F /HRESULT" -NoNewWindow -Wait -PassThru -ErrorAction SilentlyContinue
	$ErrorCode = $Process.ExitCode
	(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Deleted scheduled task with exit code: $ErrorCode" | Out-File -FilePath $LogFile -Append
	
	# Trigger Machine Policy
	Invoke-Command -ComputerName $env:COMPUTERNAME -ScriptBlock {
		Invoke-WmiMethod -Namespace "Root\CCM" -Class SMS_Client -Name TriggerSchedule -ArgumentList "{00000000-0000-0000-0000-000000000021}"
	}
	
	Start-Sleep -Seconds 30
	
	# Trigger Software Update Policy
	Invoke-Command -ComputerName $env:COMPUTERNAME -ScriptBlock {
		Invoke-WmiMethod -Namespace "Root\CCM" -Class SMS_Client -Name TriggerSchedule -ArgumentList "{00000000-0000-0000-0000-000000000113}"
	}
	
	Start-Sleep -Seconds 60
	
	# Trigger Software Updates Deployment Evaluation Cycle
	Invoke-Command -ComputerName $env:COMPUTERNAME -ScriptBlock {
		Invoke-WmiMethod -Namespace "Root\CCM" -Class SMS_Client -Name TriggerSchedule -ArgumentList "{00000000-0000-0000-0000-000000000108}"
	}
}