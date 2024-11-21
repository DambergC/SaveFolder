# This Script is to check if all conditions are in order to perform installation.
# 1.	Log folder exist and accessible
# 2.	Allowed MPs accessible
# 3.	Web service(s) accessible
# 4.	OU Path exist
# 5.	Join domain account - check permission
# 6.	Driver for installed model in TS
# 7.	List all applications to be installed
# 8.	Network access account _SMSTSReserved1-000
# 9.	Applications might have condition - check and compare to local variables
# 10.	Applications might be in a group - check conditions. Find block between "<group name=" and "</group>" should find string "SMS_TaskSequence_InstallSoftwareAction"
# 11.	There might be different queries TS variables, wmi query etc
# 12.	Check if power adapter is connected - for BIOS upgrade


# Check variable _SMSTSTaskSequence - might contain TS itself

# Preparing for TS environment
$tsenv = New-Object -ComObject Microsoft.SMS.TSEnvironment

# Prepare for Logging
$LogPath = $tsenv.Value("_SMSTSLogPath")
$LogFile = "$LogPath\Installation.log"
$ScriptName = "[" + ([io.fileinfo]$MyInvocation.MyCommand.Definition).BaseName + "]"
if (Test-Path "$LogFile") { (Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Running Pre-Flight tests" | Out-File -FilePath $LogFile -Append }
else { (Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Running Pre-Flight tests" | Out-File -FilePath $LogFile -Force }

# Setting variables
$Username = $tsenv.Value("OSDLogUser")
$Password = $tsenv.Value("OSDLogUserPassword")
$Message = ""
$SCCMServers = $tsenv.Value("OSDManagementPoint")
$WebServers = $tsenv.Value("OSDWebService")
$tsenv.Value("TSApplications") = $null

# Extract TS
$TStext = "$env:TEMP\TS.txt"
$TSxml = "$env:TEMP\TS.xml"
$tsenv.Value("_SMSTSTaskSequence") | Out-File -FilePath "$TStext" -Force
$xDoc = New-Object System.Xml.XmlDocument
$xDoc.Load($TStext)
$xDoc.Save($TSxml) #will save correctly

# To find drivers first look for group "Driver Installation", then find "Windows XXX" for correct OS
# Driver installation in exported TS looks: </step></group><group name="Driver Installation" description="">
# Windows 10 looks:							</group><group name="Windows 10" description=""><condition><operator type="or"><expression type="SMS_TaskSequence_VariableConditionExpression"><variable name="Operator">equals</variable><variable name="Value">WIN10x64</variable><variable name="Variable">OSDOSVersion</variable></expression></operator></condition>
# A driver looks:							<step type="SMS_TaskSequence_RunCommandLineAction" name="Apply Driver on Dell Latitude E4310" description="" continueOnError="true" runIn="WinPEandFullOS" successCodeList="0 3010" retryCount="0" runFromNet="false"><condition><operator type="or"><expression type="SMS_TaskSequence_WMIConditionExpression"><variable name="Namespace">root\cimv2</variable><variable name="Query">SELECT * FROM Win32_ComputerSystem WHERE Model like '%E4310%'</variable></expression></operator></condition><action>smsswd.exe /run:HB1000A2 Dism.exe /image:%OSDisk%\ /Add-Driver /Driver:. /recurse</action><defaultVarList><variable name="CommandLine" property="CommandLine" hidden="true">Dism.exe /image:%OSDisk%\ /Add-Driver /Driver:. /recurse</variable><variable name="SMSTSDisableWow64Redirection" property="DisableWow64Redirection">false</variable><variable name="PackageID" property="PackageID" hidden="true">HB1000A2</variable><variable name="_SMSTSRunCommandLineAsUser" property="RunAsUser">false</variable><variable name="SuccessCodes" property="SuccessCodes" hidden="true">0 3010</variable></defaultVarList></step></group>

# To find an application first find group "Applications", then find all packages - check if any rules
# Group Applications:						<group name="Applications" description=""><group name="Common" description="">
# Application Install:						<step type="SMS_TaskSequence_InstallSoftwareAction" name="Microsoft Office 2016" description="" continueOnError="true" runIn="FullOS" successCodeList="0" retryCount="0" runFromNet="false"><action>smsswd.exe /pkg:HB1000AC /install /basevar: /continueOnError:</action><defaultVarList><variable name="PackageID" property="PackageID" hidden="true">HB1000AC</variable><variable name="_SMSSWDProgramName" property="ProgramName">Install</variable></defaultVarList></step>
# Disabled application:						<step type="SMS_TaskSequence_InstallSoftwareAction" name="ClaroReadPlus 7.0.21 Eng" description="" disable="true" continueOnError="true" runIn="FullOS" successCodeList="0" retryCount="0" runFromNet="false"><action>smsswd.exe /pkg:HB10013E /install /basevar: /continueOnError:</action><defaultVarList><variable name="PackageID" property="PackageID" hidden="true">HB10013E</variable><variable name="_SMSSWDProgramName" property="ProgramName"></variable></defaultVarList></step>


# Get Machine Information - Name, MAC, IP, model number, model name etc
$ComputerName = $tsenv.Value("_SMSTSMachineName")
if ($ComputerName -like "*MININT*") { $ComputerName = "New Computer (Name not set)" }
# $IPAddress = ([System.Net.Dns]::GetHostByName($env:COMPUTERNAME).AddressList[0]).IpAddressToString
$IPAddress = (Get-WmiObject -class win32_NetworkAdapterConfiguration -Filter 'ipenabled = "true"').ipaddress[0]
$IPMAC = Get-WmiObject -Class Win32_NetworkAdapterConfiguration
$MACAddress = ($IPMAC | where { $_.IpAddress -eq $IPAddress }).MACAddress


$Manufacturer = (Get-WmiObject Win32_ComputerSystem).Manufacturer.TrimEnd()
if ($Manufacturer -like "*Lenovo*")
{
	$ModelFriendlyName = (Get-WmiObject Win32_ComputerSystemProduct).Version.TrimEnd()
	$ModelNumber = (Get-WmiObject Win32_ComputerSystem).Model.TrimEnd().SubString(0, 4)
}
else
{
	$ModelFriendlyName = (Get-WmiObject Win32_ComputerSystem).Model.TrimEnd()
}

# Check if Intel eg. NUC etc
if (($Manufacturer -eq $null) -or ($Manufacturer.length -lt 2))
{
	$Manufacturer = (Get-WmiObject Win32_BaseBoard).Manufacturer.TrimEnd()
	if ($Manufacturer -like "*intel*")
	{
		$ModelFriendlyName = (Get-WmiObject Win32_BaseBoard).Product.TrimEnd()
		# $ModelNumber = $ModelFriendlyName
	}
}

(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Machine Information - Computer Name:       $ComputerName" | Out-File -FilePath $LogFile -Append
(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Machine Information - IP Address:           $IPAddress" | Out-File -FilePath $LogFile -Append
(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Machine Information - MAC Address:          $MACAddress" | Out-File -FilePath $LogFile -Append
(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Machine Information - Manufacturer:        $Manufacturer" | Out-File -FilePath $LogFile -Append
(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Machine Information - Model Friendly Name: $ModelFriendlyName" | Out-File -FilePath $LogFile -Append
if ($Manufacturer -like "*Lenovo*")
{
	(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Machine Information - Model Number:        $ModelNumber" | Out-File -FilePath $LogFile -Append
}

# Check log server and share
# Filter Log servers if array (eg. OSDLogServer = Server1.somedomain.com,Server2.somedomain.com and test if online)
$LogServers = $tsenv.Value("OSDLogServer")
(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Start Testing Web Server(s) configured: $LogServers" | Out-File -FilePath $LogFile -Append
$LogServers = ($LogServers -split ",").Trim()
$tsenv.Value("OSDlogServerOperational") = $false

# Test of Log Server(s) for connection - LogServers could be with primary and secondary
foreach ($LogServer in $LogServers)
{
	$Process = Start-Process -FilePath "NET.exe" -ArgumentList "USE T: /DELETE /Y" -NoNewWindow -Wait -PassThru -ErrorAction SilentlyContinue
	$LogShare = "\\" + $LogServer + "\Logs$"
	(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Log Share - Testing connection to Log Share" | Out-File -FilePath $LogFile -Append
	(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Log Share - LogServer: $LogServer" | Out-File -FilePath $LogFile -Append
	(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Log Share - LogServer: $LogShare" | Out-File -FilePath $LogFile -Append
	try
	{
		$net = New-Object -comobject Wscript.Network
		$net.MapNetworkDrive("T:", "$LogShare", 0, "$Username", "$Password")
		(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Log Share - Mapping Log Share OK" | Out-File -FilePath $LogFile -Append
		$ErrorMapping = $false
	}
	catch [System.Exception]{
		(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Log Share - Error Connecting to log share $LogShare, exit code: $_" | Out-File -FilePath $LogFile -Append
		# $Message = $Message + "Log Share - Mapping failed, please check configuration" + [char]13
		$ErrorMapping = $true
	}
	if ($ErrorMapping -eq $false)
	{
		try
		{
			$TestFile = "T:\" + $tsenv.Value("_SMSTSMachineName") + ".txt"
			"dummy" | Out-File -FilePath "$TestFile" -Force -ErrorAction Stop
			(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Log Share - Permissions OK" | Out-File -FilePath $LogFile -Append
			if (Test-Path "$TestFile") { Remove-Item -Path "$TestFile" -Force }
			$tsenv.Value("OSDLogServer") = $LogServer
			$ErrorPermission = $false
			break
		}
		catch
		{
			(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Log Share - Permission Error" | Out-File -FilePath $LogFile -Append
			# $Message = $Message + "Log Share - Check permissions on share/filesystem" + [char]13
			$ErrorPermission = $true
		}
	}
}
if ($ErrorMapping -eq $true) { $Message = $Message + "Log Share - Mapping failed, please check configuration" + [char]13 }
if ($ErrorPermission -eq $true) { $Message = $Message + "Log Share - Check permissions on share/filesystem:" + $tsenv.Value("OSDLogServer") + [char]13 }
$Process = Start-Process -FilePath "NET.exe" -ArgumentList "USE T: /DELETE /Y" -NoNewWindow -Wait -PassThru -ErrorAction SilentlyContinue

# Check MP functionality
(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName SCCM MP Role - Testing connection to MP role" | Out-File -FilePath $LogFile -Append
(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName SCCM MP Role - SCCM Server(s) $SCCMServers" | Out-File -FilePath $LogFile -Append
$SCCMServers = ($SCCMServers -split ",").Trim()
$tsenv.Value("OSDManagementPointOperational") = $false

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
	}
}

if ($tsenv.Value("OSDManagementPointOperational") -eq $true)
{
	(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName SCCM MP Role - Found operational SCCM MP role on $SCCMServer" | Out-File -FilePath $LogFile -Append
}
else { (Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName SCCM MP Role - Error, No operational SCCM MP role found" | Out-File -FilePath $LogFile -Append; $Message = $Message + "SCCM MP Role: No accessible SCCM Management Point found" + [char]13 }


# Check Web Service
(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Web Service -  Start testing Web Server(s) configured: $WebServers" | Out-File -FilePath $LogFile -Append
$WebServers = ($WebServers -split ",").Trim()
$tsenv.Value("OSDWebServiceADOperational") = $false
$CheckWebService = $true
if (($tsenv.Value("OSDWebService") -eq $null) -or ($tsenv.Value("OSDWebService").Length -lt 2))
{
	(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Web Service - No Web Service configured" | Out-File -FilePath $LogFile -Append
	$CheckWebService = $false
}
if ($CheckWebService -eq $true)
{
	(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Web Service - Testing Web Server(s) configured: $WebServers" | Out-File -FilePath $LogFile -Append
	$WebServers = ($WebServers -split ",").Trim()
	$tsenv.Value("OSDWebServiceSCCMOperational") = $false
	$tsenv.Value("OSDWebServiceADOperational") = $false
	
	foreach ($WebServer in $WebServers)
	{
		if ($tsenv.Value("OSDWebServiceADOperational") -eq $false)
		{
			$WebServiceAD = "http://$WebServer/deploymentwebservice/ad.asmx?WDSL"
			$Error.clear()
			$ErrorCode = "Unknown error"
			$test = New-WebServiceProxy -Uri $WebServiceAD
			if ($Error -like "*unable to connect*") { $ErrorCode = "Unable to connect" }
			if ($error -like "404:") { $ErrorCode = "404 Error, Webservice not available - Check if Web Service site exist and IIS service is running" }
			if ($error -like "503:") { $ErrorCode = "503 Error, Service unavailable - check Application Pool on Web Service" }
			if ($test.UserAgent -like "*MS Web Services*")
			{
				$ErrorCode = "Web Service for AD on $WebServer is operational"
				# Test getting data from AD
				$TestAD = $test.GetADSiteNames()
				if (($TestAD.Lenght -gt 0) -or ($true -ne $null))
				{
					$tsenv.Value("OSDWebServiceADOperational") = $true
					break
				}
			}
		}
	}
	if ($tsenv.Value("OSDWebServiceADOperational") -eq $true)
	{
		(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Web Service - Found operational Web Service for AD functions on $WebServer" | Out-File -FilePath $LogFile -Append
		$WebServiceAD = "http://$WebServer/deploymentwebservice/ad.asmx?WDSL"; $tsenv.Value("OSDWebServiceAD") = $WebServiceAD
	}
	else { (Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Web Service - Error, No operational Web Services found for AD functions" | Out-File -FilePath $LogFile -Append; $Message = $Message + "Web Service -  No operational Web Services found" + [char]13 }
}

# Check if OU exist
$OUPathExist = $false
$OUPath = $tsenv.Value("OSDDomainOUName")
try
{
	$OUPathParent = $OUPath.Substring($OUPath.IndexOf(",") + 1)
	$OUPathParent = $OUPathParent.Substring($OUPathParent.IndexOf("LDAP://", [StringComparison]"CurrentCultureIgnoreCase"))
}
catch
{
	# Failed to get OU path
}
(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName OU Path - Testing OU Path" | Out-File -FilePath $LogFile -Append
(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName OU Path - OU Path value from variable: $OUPath" | Out-File -FilePath $LogFile -Append

if ($tsenv.Value("OSDWebServiceADOperational") -eq $true)
{
	$WebServiceAD = "http://$WebServer/deploymentwebservice/ad.asmx?WDSL"
	$ADWeb = New-WebServiceProxy -Uri $WebServiceAD
	$OUCheckFolders = $ADWeb.GetOUs("$OUPathParent", "0")
	$OUCheckFolders | Out-File -FilePath "$env:TEMP\OUs.txt"
	$CounterMax = $OUCheckFolders.Count
	$Counter = 0
	while ($Counter -lt $CounterMax)
	{
		$Path = $OUCheckFolders[$Counter].Path
		if ($OUPath -like "*$Path*") { $OUPathExist = $true }
		$Counter = $Counter + 1
		(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName OU Path - Path: $Path" | Out-File -FilePath $LogFile -Append
	}
	if ($OUPathExist -eq $true) { (Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName OU Path - OU Path OK" | Out-File -FilePath $LogFile -Append }
	else { (Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName OU Path - Error, OU Path does not exist" | Out-File -FilePath $LogFile -Append; $Message = $Message + "OU Path - OU not found in AD" + [char]13 }
}
else { (Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName OU Path - Error, OU Path could not be tested, Web service not accessible" | Out-File -FilePath $LogFile -Append }


# Check if VM
$VM = $false
if (($Manufacturer -like "*Microsoft Corporation*") -and ($ModelFriendlyName -like "*Virtual Machine*")) { $VM = $true }
if (($Manufacturer -like "*VMware*") -and ($ModelFriendlyName -like "*VMware Virtual*")){ $VM = $true }


# Check if Power Adapter attached - not on battery
$Battery = Get-WmiObject -Class Win32_Battery
if ($Battery -ne $null)
{
	(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Battery - Checking if Power Adapter is Connected " | Out-File -FilePath $LogFile -Append
	$BatteryStatus = Get-WmiObject -Class Win32_Battery | Select-Object BatteryStatus -ExpandProperty BatteryStatus
	if ($BatteryStatus -eq 2)
	{
		(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Battery - Power Adapter connected " | Out-File -FilePath $LogFile -Append
	}
	else
	{
		(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Battery - Error, Power Adapter is NOT connected " | Out-File -FilePath $LogFile -Append
		#Hide the progress dialog
		$TSProgressUI = new-object -comobject Microsoft.SMS.TSProgressUI
		$TSProgressUI.CloseProgressDialog()
		$tsenv.Value("Message") = "Please connect Power Adapter!" + [char]13
		$tsenv.Value("Title") = "Power Warning!"
		$tsenv.Value("ReturnCode") = 0
		Do
		{
			$BatteryStatus = Get-WmiObject -Class Win32_Battery | Select-Object BatteryStatus -ExpandProperty BatteryStatus
			Start-Process -FilePath "cscript.exe" -ArgumentList "$PSScriptRoot\CustomMessage.vbs" -NoNewWindow -Wait -PassThru
			sleep -Seconds 3
		}
		Until ($BatteryStatus -eq '2')
		
		# Show Progress dialog
		$orgName = $tsEnv.Value("_SMSTSOrgName")
		$pkgName = $tsEnv.Value("_SMSTSPackageName")
		$customMessage = $tsEnv.Value("_SMSTSCustomProgressDialogMessage")
		$currentAction = $tsEnv.Value("_SMSTSCurrentActionName")
		$Step = $tsEnv.Value("_SMSTSNextInstructionPointer")
		$maxStep = $tsEnv.Value("_SMSTSInstructionTableSize")
		$tsenv.ShowTSProgress($orgName, $pkgName, $customMessage, $currentAction, $Step, $maxStep)
	}
}
else { (Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Battery - No Battery found - assuming desktop " | Out-File -FilePath $LogFile -Append }


# Check Drivers
(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Driver - Checking driver packages" | Out-File -FilePath $LogFile -Append
$Content = [System.IO.File]::OpenText("$TSxml")
$DriverMatch = $false
while ($null -ne ($line = $Content.ReadLine()))
{
	$Counter = 0
	$DriverArray = @()
	if ($line -like "*<step type=*")
	{
		while ($line -notlike "*</step>*")
		{
			$DriverArray += $line
			$Counter = $Counter + 1
			# if ($line -like "*</step>*") { break }
			if ($line -like "*Dism.exe /image:*")
			{
				(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Debug: Found Dism.exe /image:" | Out-File -FilePath $LogFile -Append
				# Loop to end of section
				while ($line -notlike "*</step>*")
				{
					$line = $Content.ReadLine()
					$DriverArray += $line
					$Counter = $Counter + 1
				}
				
				# Get step name
				$DriverName = $DriverArray[0]
				(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Debug: Getting Step name: $DriverName" | Out-File -FilePath $LogFile -Append
				if ($DriverName -like "*RunCommandLineAction*")
				{
					(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Debug: Drivername like RunCommandLineAction: $DriverName" | Out-File -FilePath $LogFile -Append
					$DriverName = $DriverName.Substring($DriverName.IndexOf("name=") + 6)
					$DriverName = ($DriverName.Substring(0, $DriverName.IndexOf("description") - 2)).Trim()
					(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Debug: Trimmed Driver Name: $DriverName" | Out-File -FilePath $LogFile -Append
				}
				# Get Loop driver section in array getting package name, wmi query
				while ($Counter -ne 0)
				{
					$DriverLine = $DriverArray[$Counter]
					if ($DriverLine -like "*/run:*")
					{
						(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Debug: Driverline like /run:  $DriverLine" | Out-File -FilePath $LogFile -Append
						$DriverPackage = ($DriverLine.Substring($DriverLine.IndexOf("/run:") + 5)).Trim()
						$DriverPackage = ($DriverPackage.Substring(0, $DriverPackage.IndexOf(" "))).Trim()
						(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Debug: Driver Package: $DriverPackage" | Out-File -FilePath $LogFile -Append
					}
					$DriverQueryCounter = $Counter
					$DriverQuery = $DriverArray[$DriverQueryCounter]
					if (($DriverQuery -like "*Query*") -and ($DriverQuery -like "*/variable*"))
					{
						(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Debug: Driver query like query and /variable: $DriverQuery" | Out-File -FilePath $LogFile -Append
						while ($DriverQueryCounter -ne 0)
						{
							if (($DriverQuery -like "*model like*") -or ($DriverQuery -like "*version like*") -or ($DriverQuery -like "*product like*") -or ($DriverQuery -like "*name like*"))
							{
								(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Debug: Driver query like model like or version like: $DriverQuery" | Out-File -FilePath $LogFile -Append
								$DriverQuery = ($DriverQuery.Substring($DriverQuery.IndexOf("%") + 1)).Trim()
								(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Debug: Trimmed Driver Query: $DriverQuery" | Out-File -FilePath $LogFile -Append
								try
								{
									$DriverQuery = ($DriverQuery.Substring(0, $DriverQuery.IndexOf("%"))).Trim()
									(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Debug: Try Driver query substring: $DriverQuery" | Out-File -FilePath $LogFile -Append
								}
								catch
								{
									(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Debug: Try Driver query failed - no ending %" | Out-File -FilePath $LogFile -Append
									# Failed to get driverquery - no ending %
									try
									{
										$DriverQuery = $DriverQuery -replace '"', ''
										(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Debug: Try 2 Driver query replace 1: $DriverQuery" | Out-File -FilePath $LogFile -Append
									}
									catch { (Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Debug: Try 2 failed to replace" | Out-File -FilePath $LogFile -Append }
									try
									{
										$DriverQuery = $DriverQuery -replace "'", ''
										(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Debug: Try 3 Driver query replace 1: $DriverQuery" | Out-File -FilePath $LogFile -Append
									}
									catch { (Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Debug: Try 3 failed to replace" | Out-File -FilePath $LogFile -Append }
									if ($DriverQuery -like "*</*")
									{
										(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Debug: Driver query like </: $DriverQuery" | Out-File -FilePath $LogFile -Append
										$DriverQuery = ($DriverQuery.Substring(0, $DriverQuery.IndexOf("</"))).Trim()
										(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Debug: Driver query like </ (trimmed): $DriverQuery" | Out-File -FilePath $LogFile -Append
									}
								}
								(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Driver - Driver package query: $DriverQuery" | Out-File -FilePath $LogFile -Append
								if ($ModelFriendlyName -like "*$DriverQuery*")
								{
									$DriverMatch = $true
									(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Debug: ModelFriendlyName ($ModelFriendlyName) like DriverQuery ($DriverQuery)" | Out-File -FilePath $LogFile -Append
								}
								if (($ModelNumber -ne $null) -and ($ModelNumber -like "*$DriverQuery*"))
								{
									$DriverMatch = $true
									(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName ModelNumber ne null ($ModelNumber) and modelnumber like Driverquery ($DriverQuery)" | Out-File -FilePath $LogFile -Append
								}
								break
							}
							$DriverQueryCounter = $DriverQueryCounter - 1
							$DriverQuery = $DriverArray[$DriverQueryCounter]
							(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Debug: Decrease count: $DriverQueryCounter, DriverQuery now: $DriverQuery" | Out-File -FilePath $LogFile -Append
						}
					}
					$Counter = $Counter - 1
				}
			}
			if ($line -like "*</step>*") { break }
			$line = $Content.ReadLine()
		}
	}
}
if ($VM -eq $false)
{
	if ($DriverMatch -eq $false) { (Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Driver - Error, driver for this model ($ModelFriendlyName) not found" | Out-File -FilePath $LogFile -Append; $Message = $Message + "Driver - driver for this model ($ModelFriendlyName) not found." + [char]13 }
	else { (Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Driver - Driver package found: OK" | Out-File -FilePath $LogFile -Append }
}
else { (Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Driver - Machine is virtual, skipping drivercheck" | Out-File -FilePath $LogFile -Append }


# Get Applications from TS
if (Test-Path "$env:TEMP\ApplicationInstall.txt") { Remove-Item -Path "$env:TEMP\ApplicationInstall.txt" -Force }
if (Test-Path "$env:TEMP\ApplicationNotInstall.txt") { Remove-Item -Path "$env:TEMP\ApplicationNotInstall.txt" -Force }
(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Applications - List all enabled applications" | Out-File -FilePath $LogFile -Append
$Content = [System.IO.File]::OpenText("$TSxml")

############################### Functions ####################################
function Find-Group
{
	if ($TS[$Counter] -like "*<group name=*")
	{
		$GroupLevelCounter = $TS[$Counter].LastIndexOf("<")
		if ($GroupLevelCounter -le 2) { $OperatorTest = $true }
		# if (($OperatorTest -ne $false) -or ($GroupLevelCounter -le $GroupLevelCondition))
		if ($OperatorTest -ne $false)
		{
			$Counter = $Counter + 1
			if ($TS[$Counter] -like "*<condition>*") { $OperatorTest, $Counter = Test-Condition }
			if ($OperatorTest -eq $false)
			{
				$GroupLevelCondition = $GroupLevelCounter
			}
		}
		else
		{
			while ($GroupLevelCounter -le $GroupLevelCondition)
			{
				if ($TS[$Counter] -like "*</group>*")
				{
					$GroupLevelCounter = $TS[$Counter].LastIndexOf("<")
					if ($GroupLevelCondition -le $GroupLevelCounter) { $OperatorTest = $true; $GroupLevelCondition = 0 }
				}
				$Counter = $Counter + 1
			}
		}
	}
	if ($TS[$Counter + 1] -like "*</group>*")
	{
		$OperatorTest = $true
	}
	Write-Host $TS[$Counter] + " step: $Counter"
	return $GroupLevelCondition, $OperatorTest, $GroupLevelCounter, $Counter
}

Function Find-Application
{
	$ApplicationName = $null
	$InstallApplication = $true
	$CounterApplication = 0
	if (($TS[$Counter] -like "*<step type=*") -and ($TS[$Counter] -like "*SMS_TaskSequence_InstallSoftwareAction*") -and ($TS[$Counter] -notlike "*disable=*"))
	{
		while ($TS[$Counter] -notlike "*</step>*")
		{
			if (($TS[$Counter] -like "*name=*") -and ($TS[$Counter] -like "*description=*"))
			{
				$ApplicationName = $TS[$Counter].Substring($TS[$Counter].IndexOf("name=") + 6)
				$ApplicationName = ($ApplicationName.Substring(0, $ApplicationName.IndexOf("description") - 2)).Trim()
				$GroupTestDone = $false
			}
			
			if (($TS[$Counter] -like "*<condition>*")) { $OperatorTest, $Counter = Test-Condition }
			if (($TS[$Counter] -like "*name=*") -and ($TS[$Counter] -like "*PackageID*"))
			{
				$ApplicationPackageID = $TS[$Counter].Substring($TS[$Counter].IndexOf(">") + 1)
				$ApplicationPackageID = ($ApplicationPackageID.Substring(0, $ApplicationPackageID.IndexOf("</"))).Trim()
			}
			if (($OperatorTest -eq $true) -or ($OperatorTest -eq $false)) { $InstallApplication = $OperatorTest }
			else { $InstallApplication = $false }
			
			if (($TS[$Counter] -like "*</defaultVarList*") -and ($InstallApplication -eq $true))
			{
				if (($ApplicationName -notlike "*Lenovo*") -and ($ApplicationName -notlike "*HP *") -and ($ApplicationName -notlike "*Dell*") -and ($ApplicationName -notlike "*Hewlett*") -and ($ApplicationName -notlike "*Intel*"))
				{
					"$ApplicationName,$ApplicationPackageID" | Out-File -FilePath "$env:TEMP\ApplicationInstall.txt" -Append
					(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Applications - Application to Install: $ApplicationName" | Out-File -FilePath $LogFile -Append
					try
					{
						$tsenv.Value("TSApplications") += $ApplicationName + ","
					}
					catch { }
				}
			}
			elseif ($TS[$Counter] -like "*</defaultVarList*") { "$ApplicationName,$ApplicationPackageID" | Out-File -FilePath "$env:TEMP\ApplicationNotInstall.txt" -Append; (Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName Applications - Application will NOT Install: $ApplicationName" | Out-File -FilePath $LogFile -Append }
			$Counter = $Counter + 1
		}
	}
	Return $InstallApplication, $Counter
}

Function Test-Condition
{
	$Operator = $null
	$OperatorGroupTestArray = @()
	$ExpressionCount = 0
	$OperatorTest = $true
	while ($TS[$Counter] -notlike "*</condition>*")
	{
		if ($TS[$Counter] -like "*<expression type=*")
		{
			if ($TS[$Counter] -like "*WMIConditionExpression*")
			{
				if ($TS[$Counter - 1] -like "*and*") { $OperatorType = "and" }
				if ($TS[$Counter - 1] -like '*"or"*') { $OperatorType = "or" }
				$ExpressionCount = $ExpressionCount + 1
				while ($TS[$Counter] -notlike "*</expression>*")
				{
					if ($TS[$Counter] -like '*variable name="Query"*')
					{
						$Query = $TS[$Counter].Substring($TS[$Counter].IndexOf("variable name=") + 22); $Query = $Query.Substring(0, $Query.IndexOf("</")).Trim()
						$WMIClass = $Query.Substring($Query.IndexOf("FROM", [StringComparison]"CurrentCultureIgnoreCase") + 4).Trim()
						$WMIClass = $WMIClass.Substring(0, $WMIClass.IndexOf("WHERE", [StringComparison]"CurrentCultureIgnoreCase")).Trim()
						$Attribute = $Query.Substring($Query.IndexOf("WHERE", [StringComparison]"CurrentCultureIgnoreCase") + 5).Trim()
						$Attribute = $Attribute.Substring(0, $Attribute.IndexOf("LIKE", [StringComparison]"CurrentCultureIgnoreCase")).Trim()
						$SearchString = $Query.Substring($Query.IndexOf("%") + 1).Trim()
						$SearchString = $SearchString.Substring(0, $SearchString.IndexOf("%")).Trim()
						try
						{
							$test = (Get-WmiObject -Class $WMIClass).$Attribute
							
							if ($test -ne $SearchString) { $InstallApplication = $false; $OperatorTest = $false; $DoTest = $true }
							else { $OperatorTest = $true; $DoTest = $true }
						}
						catch
						{
							# $InstallApplication = $false
							$OperatorTest = $false; $DoTest = $true
						}
					}
					$Counter = $Counter + 1
				}
			}
			if ($TS[$Counter] -like "*VariableConditionExpression*")
			{
				if ($TS[$Counter - 1] -like "*and*") { $OperatorType = "and" }
				if ($TS[$Counter - 1] -like '*"or"*') { $OperatorType = "or" }
				$ExpressionCount = $ExpressionCount + 1
				while ($TS[$Counter] -notlike "*</expression>*")
				{
					if ($TS[$Counter] -like '*variable name="Operator"*') { $Operator = $TS[$Counter].Substring($TS[$Counter].IndexOf("variable name=") + 25); $Operator = $Operator.Substring(0, $Operator.IndexOf("</")).Trim() }
					if (($TS[$Counter] -like '*<variable name="Value"*') -and ($Operator -ne $null))
					{
						try
						{
							$Value = $TS[$Counter].Substring($TS[$Counter].IndexOf("variable name=") + 22); $Value = $Value.Substring(0, $Value.IndexOf("</")).Trim()
						}
						catch
						{
							# Out of range
						}
					}
					if (($TS[$Counter] -like '*<variable name="Variable"*') -and ($Operator -ne $null)) { $Variable = $TS[$Counter].Substring($TS[$Counter].IndexOf("variable name=") + 25); $Variable = $Variable.Substring(0, $Variable.IndexOf("</")).Trim(); $DoTest = $true }
					$Counter = $Counter + 1
				}
				# Test expression
				if ($Operator -eq "notExists")
				{
					$TSVariable = $tsenv.Value("$Variable")
					if (($TSVariable.Length -gt 0) -and ($TSVariable -ne $null))
					{
						$OperatorTest = $false
					}
					else { $OperatorTest = $true }
				}
				if ($Operator -eq "exists")
				{
					try
					{
						if ($tsenv.Value("$Variable") -eq $null) { $OperatorTest = $false }
					}
					catch { $OperatorTest = $false }
				}
				if ($Operator -eq "equals")
				{
					try
					{
						if ($tsenv.Value("$Variable") -ne $Value) { $OperatorTest = $false }
					}
					catch { $OperatorTest = $false }
				}
				if ($Operator -eq "notEquals")
				{
					try
					{
						if ($tsenv.Value("$Variable") -eq $Value) { $OperatorTest = $false }
					}
					catch { $OperatorTest = $false }
				}
			}
		}
		if ((($OperatorTest -eq $false) -or ($OperatorTest -eq $true)) -and ($DoTest -eq $true)) { $OperatorGroupTestArray += $OperatorTest; $InstallApplication = $OperatorGroupTestArray; $DoTest = $false }
		if ($ExpressionCount -gt 1)
		{
			if ($OperatorType -eq "and") { $ExpressionGroupTotalResult = $OperatorGroupTestArray[$ExpressionCount - 2] -and $OperatorGroupTestArray[($ExpressionCount - 1)] }
			if ($OperatorType -eq "or") { $ExpressionGroupTotalResult = $OperatorGroupTestArray[$ExpressionCount - 2] -or $OperatorGroupTestArray[$ExpressionCount - 1] }
		}
		elseif (($OperatorTest -eq $false) -and ($DoTest -eq $true)) { $InstallApplication = $false }
		$Counter = $Counter + 1
	}
	if (($ExpressionGroupTotalResult -eq $true) -or ($ExpressionGroupTotalResult -eq $false)) { $OperatorTest = $ExpressionGroupTotalResult }
	return $OperatorTest, $Counter
}


############################## End Functions ###################################

if (Test-Path "$env:TEMP\ApplicationInstall.txt") { Remove-Item -Path "$env:TEMP\ApplicationInstall.txt" -Force }
if (Test-Path "$env:TEMP\ApplicationNotInstall.txt") { Remove-Item -Path "$env:TEMP\ApplicationNotInstall.txt" -Force }

# Read config into array
$TS = @()
while ($null -ne ($line = $Content.ReadLine()))
{
	$TS += $line
}
$Counter = 0
$TSLength = $TS.Count

# Find Group
$GroupLevelCounter = 0
$InstallStep = $true
$InstallGroup = $true
while ($Counter -lt $TSLength)
{
	$GroupLevelCondition, $OperatorTest, $GroupLevelCounter, $Counter = Find-Group
	if ($OperatorTest -ne $false) { $installApplication, $Counter = Find-Application }
	$Counter = $Counter + 1
}

if ($Message.Length -gt 5) { $tsenv.Value("OSDMessage") = $Message }

