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
Write-Log "Configure SCCM client"

$SCCMServers = $tsenv.Value("OSDManagementPoint")

# If SCCM server variable is empty, then assume AUTO
if (($tsenv.Value("OSDManagementPoint") -eq $null) -or ($tsenv.Value("OSDManagementPoint").Length -lt 2))
{
	Write-Log "No SCCM Server configured - assuming value AUTO and quitting..."
	$tsenv.Value("OSDSMSMP") = $null
	exit
}

# Filter SCCM server if array (eg. OSDManagementPoint = Server1.somedomain.com,Server2.somedomain.com and test if online)
Write-Log "Start Testing SCCM Server(s) configured: $SCCMServers"
$SCCMServers = ($SCCMServers -split ",").Trim()
$tsenv.Value("OSDManagementPointOperational") = $false

# Testing MP role connection
foreach ($SCCMServer in $SCCMServers)
{
	if ($tsenv.Value("OSDManagementPointOperational") -eq $false)
	{
		$WebServiceSCCM = "http://$SCCMServer/sms_mp/.sms_aut?mplist"
		$Error.clear()
		$ErrorCode = "Unknown error"
		$test = Invoke-WebRequest "http://$SCCMServer/sms_mp/.sms_aut?mplist" -UseBasicParsing
		if ($Error -like "*unable to connect*") { $ErrorCode = "Unable to connect" }
		if ($error -like "404:") { $ErrorCode = "404 Error, Webservice not available - Check if Web Service site exist and IIS service is running" }
		if ($error -like "503:") { $ErrorCode = "503 Error, Service unavailable - check Application Pool on Web Service" }
		if ($test.Content -like "*Capabilities SchemaVersion=*")
		{
			$ErrorCode = "MP role for SCCM on $SCCMServer is accessible and operational"
			$tsenv.Value("OSDManagementPointOperational") = $true
			break			
		}
		Write-Log "Testing MP role on $SCCMServer with exit code: $ErrorCode"
	}
}

# Set variable OSDSMSMP
if ($tsenv.Value("OSDManagementPointOperational") -eq $true)
{
	Write-Log "Found operational SCCM MP role on $SCCMServer"
	$tsenv.Value("OSDSMSMP") = $SCCMServer
}
else { Write-Log "No operational SCCM MP role found" }

