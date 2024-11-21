# This Script is to check if all conditions are in order to perform installation.
# 1.	Log folder exist and accessible
# 2.	Allowed MPs accessible
# 3.	Web service(s) accessible
# 4.	OU Path exist
# 5.	Join domain account - check permission - not in place
# 6.	Driver for installed model in TS
# 7.	List all applications to be installed
# 8.	Network access account _SMSTSReserved1-000
# 9.	Applications might have condition - check and compare to local variables
# 10.	Applications might be in a group - check conditions. Find block between "<group name=" and "</group>" should find string "SMS_TaskSequence_InstallSoftwareAction"
# 11.	There might be different queries TS variables, wmi query etc
# 12.	Check if power adapter is connected - for BIOS upgrade


# Check variable _SMSTSTaskSequence - might contain TS itself

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
function global:Write-Log ($text)
{
	$global:LogPath = $tsenv.Value("_SMSTSLogPath")
	$global:LogFile = "$LogPath\Installation.log"
	(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName $text" | Out-File -FilePath $LogFile -Append
	return
}
function Mount-ISO ($Image)
{
	if (Test-Path "$Image")
	{
		try
		{
			$MountResult = Mount-DiskImage -ImagePath "$Image" -StorageType ISO -PassThru -ErrorAction Stop
			Start-Sleep -Seconds 3
			$DriveLetter = ($MountResult | Get-Volume).DriveLetter
			if ($DriveLetter -ne $null) { $DriveLetterFixed = $DriveLetter + ":" }
		}
		catch { Write-Log " Mount-ISO: Error - failed to mount ISO: $Image" }
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

try
{
	# Check if upgrade or install TS
	$TSType = "Upgrade"
	$FoundTSType = $false
	foreach ($item in $tsenv.Value("_SMSTSTaskSequence"))
	{
		if ($item -like "*OSDApplyOS.exe*") { $TSType = "Install"; Write-Log "Task Sequence is of type 'OS Deployment'"; $FoundTSType = $true }
		if ($item -like "*OSDUpgradeOS.exe*") { $TSType = "Upgrade"; Write-Log "Task Sequence is of type 'Upgrade'"; $FoundTSType = $true }
	}
	if ($FoundTSType -eq $false) { Write-Log "OSDApplyOS.exe or OSDUpgradeOS.exe not found in TS - assuming type Upgrade" }
	$tsenv.Value("OSDTSType") = $TSType
}
catch { Write-Log "Unable to find TS type 'Install/Upgrade" }

# Prepare for Logging
Write-Log " "
Write-Log "Running Pre-Flight tests"

# Setting variables
$Username = $tsenv.Value("OSDLogUser")
$Password = $tsenv.Value("OSDLogUserPassword")
$Message = ""
$SCCMServers = $tsenv.Value("OSDManagementPoint")
$WebServers = $tsenv.Value("OSDWebService")
$SMSTSAssignedSiteCode = $tsenv.Value("_SMSTSAssignedSiteCode")
if ($SMSTSAssignedSiteCode -eq $null) { $SMSTSAssignedSiteCode = $tsenv.Value("OSDSCCMSiteCode") }
$tsenv.Value("TSApplications") = $null
$NewLine = "`n"
$ParentDirectory = (Get-Item $PSScriptRoot).parent.parent.FullName

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

# Get Task sequence version
try
{
	$TSversion = $tsenv.Value("TaskSequenceVer")
	$TSName = $tsenv.Value("_SMSTSPackageName")
	if ($TSName -ne $null) { Write-Log "Versions - Task Sequence Name   : $TSName" }
	if ($TSversion -ne $null) { Write-Log "Versions - Task Sequence Version: $TSversion" }
}
catch { }

# Check if Error message passed from Driver check script
$MessageTemp = $tsenv.Value("OSDMessage")
if ($MessageTemp -ne $null) { $Message = $tsenv.Value("OSDMessage") }

# Get Installation Tools version from version text file in root of tools
$ParentDirectory = (Get-Item $PSScriptRoot).parent.parent.FullName
try
{
	$ToolsVersion = Get-Content "$ParentDirectory\Version.txt" -Force
}
catch { Write-Log "Versions - Error: Failed to get version from file" }
if ($ToolsVersion -eq $null) { $ToolsVersion = "Pre 5.4 - No version information found" }
Write-Log "Versions - Installation Tools Version:                        $ToolsVersion"

# Get Machine Information - Name, MAC, IP, model number, model name etc
$ComputerName = $tsenv.Value("_SMSTSMachineName")
if ($ComputerName -like "*MININT*") { $ComputerName = "New Computer (Name not set)" }
$IPAddress = (Get-WmiObject -class win32_NetworkAdapterConfiguration -Filter 'ipenabled = "true"').ipaddress[0]
$IPMAC = Get-WmiObject -Class Win32_NetworkAdapterConfiguration
$MACAddress = ($IPMAC | where { $_.IpAddress -eq $IPAddress }).MACAddress
$DNSDomain = (Get-WmiObject -class win32_NetworkAdapterConfiguration -Filter 'ipenabled = "true"').DNSDomain # Used to find from which domain client is coming from in a multi domain environment
$tsenv.Value("OSDDNSDomain") = $DNSDomain

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
	}
	if ($Manufacturer -like "*ASUS*")
	{
		$ModelFriendlyName = (Get-WmiObject Win32_BaseBoard).Product.TrimEnd()
	}
}

Write-Log "Machine Information - Computer Name:               $ComputerName"
Write-Log "Machine Information - IP Address:                  $IPAddress"
Write-Log "Machine Information - DNS Domain:                  $DNSDomain"
Write-Log "Machine Information - MAC Address:                 $MACAddress"
Write-Log "Machine Information - Manufacturer:                $Manufacturer"
Write-Log "Machine Information - Model Friendly Name:         $ModelFriendlyName"

if ($Manufacturer -like "*Lenovo*")
{
	Write-Log "Machine Information - Model Number:                $ModelNumber"
}

# Get Net Adapter information
$NICAdapters = Get-NetAdapter -Name *
foreach ($Adapter in $NICAdapters)
{
	Write-Host "Machine Information - NIC Adapter: $($Adapter.InterfaceDescription) Status: $($Adapter.Status) and MAC adress: $($Adapter.MacAddress)"
	
}


# Check log server and share
# Filter Log servers if array (eg. OSDLogServer = Server1.somedomain.com,Server2.somedomain.com and test if online)
$LogServers = $tsenv.Value("OSDLogServer")
Write-Log "Log Share - Start Testing Log Server(s) configured: $LogServers"
$LogServers = ($LogServers -split ",").Trim()
$tsenv.Value("OSDlogServerOperational") = $false

# Test of Log Server(s) for connection - LogServers could be with primary and secondary
if (($($Username.Length) -lt 1) -or ($($Password.Length) -lt 1) -or ($($LogServers.Length) -lt 1))
{
	Write-Log "Log share parameters missing - skipping Log share check"
}
else
{
	foreach ($LogServer in $LogServers)
	{
		if (Test-Path "T:")
		{
			try
			{
				$Process = Start-Process -FilePath "NET.exe" -ArgumentList "USE T: /DELETE /Y" -NoNewWindow -Wait -PassThru -ErrorAction SilentlyContinue
				Write-Log "Log Share - Disconnecting mapped drive to log share"
			}
			catch { Write-Log "Log Share - Error: Failed disconnecting mapped drive to log share, " }
		}
		
		$LogShare = "\\" + $LogServer + "\Logs$"
		$UsernameFull = $LogServer + "\" + $Username
		Write-Log "Log Share - Testing connection to Log Share"
		Write-Log "Log Share - LogServer: $LogServer"
		Write-Log "Log Share - LogServer: $LogShare"
		Write-Log "Log Share - Full Username: $UsernameFull"
		
		# Disconnect all shares
		try
		{
			$Process = Start-Process -FilePath "NET.exe" -ArgumentList "USE * /DELETE /Y" -NoNewWindow -Wait -PassThru -ErrorAction Stop
			Write-Log "Log Share - Disconnecting mapped drive to log share"
		}
		catch { Write-Log "Log Share - Error: Failed disconnecting mapped drive to log share, " }
		
		$TestConnection = Test-Connection $LogServer -Count 1 -Quiet
		if ($TestConnection -eq $true)
		{
			
			# Connect Log Share
			try
			{
				$net = New-Object -comobject Wscript.Network
				$net.MapNetworkDrive("T:", "$LogShare", 0, "$UsernameFull", "$Password")
				Write-Log "Log Share - Mapping Log Share OK"
				$ErrorMapping = $false
			}
			catch [System.Exception]{
				Write-Log "Log Share - Error Connecting to log share $LogShare, exit code: $_"
				$ErrorMapping = $true
				Write-Log "Log Share - Trying to map T: (Net use T: $LogShare /user:$UsernameFull $Password)"
				$Process = Start-Process -FilePath "NET.exe" -ArgumentList "USE T: $LogShare /user:$UsernameFull $Password" -NoNewWindow -Wait -PassThru -ErrorAction SilentlyContinue
				$ErrorCode = $Process.ExitCode
				Write-Log "Mapped T: with NET USE with exit code: $ErrorCode"
				if ($ErrorCode -ne 0) { Write-Log "Log Share - Error: Failed mapping Log Share using NET USE" }
				else { $ErrorMapping = $false; Write-Log "Log Share - Mapped Log Share successfully" }
			}
			if ($ErrorMapping -eq $false)
			{
				try
				{
					$TestFile = "T:\" + $tsenv.Value("_SMSTSMachineName") + ".txt"
					"dummy" | Out-File -FilePath "$TestFile" -Force -ErrorAction Stop
					Write-Log "Log Share - Permissions OK"
					if (Test-Path "$TestFile") { Remove-Item -Path "$TestFile" -Force }
					$tsenv.Value("OSDLogServer") = $LogServer
					$ErrorPermission = $false
					break
				}
				catch
				{
					Write-Log "Log Share - Permission Error"
					$ErrorPermission = $true
				}
			}
		}
		else { Write-Log "Testing connection towards $LogServer - failed" }
	}
	if ($ErrorMapping -eq $true) { $Message = $Message + "Log Share - Mapping failed, please check configuration" + ";" }
	if ($ErrorPermission -eq $true) { $Message = $Message + "Log Share - Check permissions on share/filesystem:" + $tsenv.Value("OSDLogServer") + ";" }
	$Process = Start-Process -FilePath "NET.exe" -ArgumentList "USE T: /DELETE /Y" -NoNewWindow -Wait -PassThru -ErrorAction SilentlyContinue
}

# Check BIOS Password configuration
$UseBIOSPassword = $tsenv.Value("OSDUseBIOSPassword")
Write-Log "BIOS Password - Checking BIOS password config"
if ($UseBIOSPassword -eq $true)
{
	Write-Log "BIOS Password - Use of BIOS password is set to True"
	if (($tsenv.Value("OSDBIOSPassword1")) -ne $null)
	{
		if (($tsenv.Value("OSDBIOSPassword1")).Length -ge 4)
		{
			Write-Log "BIOS Password - BIOS password found containing valid string"
		}
		else
		{
			$UseBIOSPassword = $false
			Write-Log "BIOS Password - BIOS password string does not include password with at least 4 characters"
			$Message = $Message + "BIOS Password - BIOS PW is activated in TS but invalid password is found in TS variable" + ";"
		}
	}
	else
	{
		$UseBIOSPassword = $false
		Write-Log "BIOS Password - No valid BIOS password variable found"
		$Message = $Message + "BIOS Password - BIOS PW is activated in TS but no password is found in TS variables" + ";"
	}
}
else
{
    $UseBIOSPassword = $false
    Write-Log "BIOS Password - Use of BIOS password is set to False"
}

# Check MP functionality
Write-Log "SCCM MP Role - Testing connection to MP role"
Write-Log "SCCM MP Role - SCCM Server(s) $SCCMServers"
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
	Write-Log "SCCM MP Role - Found operational SCCM MP role on $SCCMServer"
}
else { Write-Log "SCCM MP Role - Error, No operational SCCM MP role found"; $Message = $Message + "SCCM MP Role: No accessible SCCM Management Point found" + ";" }


# Check Web Service
Write-Log "Web Service -  Start testing Web Server(s) configured: $WebServers"
$WebServers = ($WebServers -split ",").Trim()
$tsenv.Value("OSDWebServiceADOperational") = $false
$tsenv.Value("OSDWebServiceSCCMOperational") = $false
$CheckWebService = $true
if (($tsenv.Value("OSDWebService") -eq $null) -or ($tsenv.Value("OSDWebService").Length -lt 2))
{
	Write-Log "Web Service - No Web Service configured"
	$CheckWebService = $false
}
if ($CheckWebService -eq $true)
{
	Write-Log "Web Service - Testing Web Server(s) configured: $WebServers"
	$WebServers = ($WebServers -split ",").Trim()
	$tsenv.Value("OSDWebServiceSCCMOperational") = $false
	$tsenv.Value("OSDWebServiceADOperational") = $false
	
	# Testing Web services for AD connection
	Write-Log "Web Service - Test WebServices for AD connection"
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
		Write-Log "Web Service - Found operational Web Service for AD functions on $WebServer"
		$WebServiceAD = "http://$WebServer/deploymentwebservice/ad.asmx?WDSL"; $tsenv.Value("OSDWebServiceAD") = $WebServiceAD
	}
	else { Write-Log "Web Service - Error: No operational Web Services found for AD functions"; $Message = $Message + "Web Service -  No operational Web Services found" + ";" }
	
	# Testing Web services for SCCM connection
	Write-Log "Web Service - Test WebServices for SCCM connection"
	foreach ($WebServer in $WebServers)
	{
		if ($tsenv.Value("OSDWebServiceSCCMOperational") -eq $false)
		{
			$WebServiceSCCM = "http://$WebServer/deploymentwebservice/sccm.asmx?WDSL"
			$Error.clear()
			$ErrorCode = "Unknown error"
			try
			{
				$test = New-WebServiceProxy -Uri $WebServiceSCCM
				if ($Error -like "*unable to connect*") { $ErrorCode = "Unable to connect" }
				if ($error -like "404:") { $ErrorCode = "404 Error, Webservice not available - Check if Web Service site exist and IIS service is running" }
				if ($error -like "503:") { $ErrorCode = "503 Error, Service unavailable - check Application Pool on Web Service" }
				if ($test.UserAgent -like "*MS Web Services*")
				{
					$ErrorCode = "Web Service for SCCM on $WebServer is accessible, testing if operational"
					# Test getting data from SCCM
					Write-Log "Web Service - SCCM site code from variable: $SMSTSAssignedSiteCode"
					$TestSCCM = $test.GetOSDCollections("$SMSTSAssignedSiteCode")
					
					if (($TestSCCM.Length -gt 0) -and ($TestSCCM -ne $null))
					{
						$tsenv.Value("OSDWebServiceSCCMOperational") = $true
						Write-Log "Web Service - Quering data from SCCM successful"
						break
					}
					else
					{
						$ErrorCode = "Unsuccessful"
						Write-Log "Web Service - Quering data from SCCM NOT successful"
					}
				}
				Write-Log "Web Service - Testing Web sccm.asmx $WebServer with exit code: $ErrorCode"
			}
			catch { Write-Log "Web Service - Failed connecting to: $WebServer" }
		}
	}
	if ($tsenv.Value("OSDWebServiceSCCMOperational") -eq $true)
	{
		Write-Log "Web Service - Found operational Web Service for SCCM functions on $WebServer"
		$WebServiceSCCM = "http://$WebServer/deploymentwebservice/sccm.asmx?WDSL"; $tsenv.Value("OSDWebServiceSCCM") = $WebServiceSCCM
	}
	else { Write-Log "Web Service - Error: No operational Web Services found for SCCM functions" }
}

# Check if OU exist
$OUPathExist = $false
$OUPath = $tsenv.Value("OSDDomainOUName")
$OURoot = $false
try
{
	Write-Log "OU Path - Trying to get parent OU of $OUPath"
	if ($OUPath -like "*OU=*")
	{
		Write-Log "OU Path - This OU is not root (Contains OU in path)"
		$OUPathParent = $OUPath.Substring($OUPath.IndexOf(",") + 1)
		Write-Log "OU Path - OU Parent found: $OUPathParent"
	}
	else { Write-Log "OU Path - This OU is root"; $OUPathParent = $OUPath; $OURoot = $true }
}
catch
{
	Write-Log "OU Path - Failed to find Parent, assuming OUPath is root: $OUPath"
	$OUPathParent = $OUPath
	$OURoot = $true
}
Write-Log "OU Path - Testing OU Path with Web Service: $WebServiceAD"
Write-Log "OU Path - OU Path value from variable: $OUPath"

if ($tsenv.Value("OSDWebServiceADOperational") -eq $true)
{
	$WebServiceAD = $tsenv.Value("OSDWebServiceAD")
	$ADWeb = New-WebServiceProxy -Uri $WebServiceAD
	$OUCheckFolders = $ADWeb.GetOUs("$OUPathParent", "0")
	$OUCheckFolders | Out-File -FilePath "$env:TEMP\OUs.txt"
	$CounterMax = $OUCheckFolders.Count
	Write-Log "OU Path - Number of sub OU:s found: $CounterMax"
	$Counter = 0
	while ($Counter -lt $CounterMax)
	{
		$Path = $OUCheckFolders[$Counter].Path
		if ($OUPath -like "*$Path*") { $OUPathExist = $true }
		$Counter = $Counter + 1
		Write-Log "OU Path - Path: $Path"
	}
	if (($CounterMax -gt 0) -and ($OURoot -eq $true)) { Write-Log "OU Path - Root OU was configured and number of sub OU:s found: $CounterMax (more than zero)"; $OUPathExist = $true }
	if ($OUPathExist -eq $true) { Write-Log "OU Path - OU Path OK" }
	else { Write-Log "OU Path - Error, OU Path does not exist"; $Message = $Message + "OU Path - OU not found in AD" + ";" }
}
else { Write-Log "OU Path - Error, OU Path could not be tested, Web service not accessible" }

# Check if Power Adapter attached - not on battery
$Battery = Get-WmiObject -Class Win32_Battery
if ($Battery -ne $null)
{
	Write-Log "Battery - Checking if Power Adapter is Connected "
	$BatteryStatus = Get-WmiObject -Class Win32_Battery | Select-Object BatteryStatus -ExpandProperty BatteryStatus
	if ($BatteryStatus -eq 2)
	{
		Write-Log "Battery - Power Adapter connected "
	}
	else
	{
		Write-Log "Battery - Error, Power Adapter is NOT connected "
		#Hide the progress dialog
		$TSProgressUI = new-object -comobject Microsoft.SMS.TSProgressUI
		$TSProgressUI.CloseProgressDialog()
		$tsenv.Value("Message") = "Please connect Power Adapter!" + $NewLine
		$tsenv.Value("Title") = "Power Warning!"
		$tsenv.Value("ReturnCode") = 0
		Do
		{
			$BatteryStatus = Get-WmiObject -Class Win32_Battery | Select-Object BatteryStatus -ExpandProperty BatteryStatus
			Start-Process -FilePath "cscript.exe" -ArgumentList "$ParentDirectory\Script\OSD\Message\CustomMessage.vbs" -NoNewWindow -Wait -PassThru
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
else { Write-Log "Battery - No Battery found - assuming desktop " }

# Check if VM
Write-Log "Check if device is virtual..."
$VM = $false
if (($Manufacturer -like "*Microsoft Corporation*") -and ($ModelFriendlyName -like "*Virtual Machine*")) { $VM = $true }
if (($Manufacturer -like "*VMware*") -and ($ModelFriendlyName -like "*VMware Virtual*")) { $VM = $true }
if ($Manufacturer -like "*Xen*") { $VM = $true }
If ($ModelFriendlyName -like "*VirtualBox*") { $VM = $true }
If ($ModelFriendlyName -like "*Virtual Platform*") { $VM = $true }
if ($VM -eq $true) { Write-Log "Device is Virtual, Manufacturer: $Manufacturer, Model: $ModelFriendlyName" }

# Check Drivers
$DriverFound = $true
$DriverDistributed = $true
$DriverFound = $tsenv.Value("OSDDriverFound")
$DriverDistributed = $tsenv.Value("OSDDriverDistributed")
$OSDDistributionPoint = $tsenv.Value("OSDDistributionPoint")
$PackageID = $tsenv.Value("OSDDriverPackageID")
try { $Message = $tsenv.Value("OSDMessage") } catch { }

if (($PackageID.count -gt 1) -and ($DriverFound -eq $false) -and ($Message.length -gt 0)) { Write-Log "Driver - Warning: Driver package was found with duplicate ID:s ($PackageID) for this model ($ModelFriendlyName) - please make sure only 1 driverpackage exist per model and target OS" }

elseif (($VM -ne $true) -or ($Manufacturer -like "*VMware*")) # VMware requires drivers
{
	if ($tsenv.Value("OSDUseCheckDriverService") -eq $true)
	{
		Write-Log "Driver - Driver method: Check Driver Service"
		if ($DriverFound -eq $true) { Write-Log "Driver - Drivers for model found, PackageID for driver: $PackageID" }
		else { Write-Log "Driver - Warning: Drivers for model not found" }
		if (($DriverDistributed -eq $false) -and ($Message -notlike "*driver for this model*"))
		{
			Write-Log "Driver - Drivers with Package ID $PackageID not distributed to DP: $OSDDistributionPoint"
			$Message = $Message + "Driver - driver for this model ($ModelFriendlyName) not distributed to DP: $OSDDistributionPoint" + ";"
		}
	}
	else
	{
		Write-Log "Driver - Checking driver packages"
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
						# Loop to end of section
						while ($line -notlike "*</step>*")
						{
							$line = $Content.ReadLine()
							$DriverArray += $line
							$Counter = $Counter + 1
						}
						
						# Get step name
						$DriverName = $DriverArray[0]
						if ($DriverName -like "*RunCommandLineAction*")
						{
							$DriverName = $DriverName.Substring($DriverName.IndexOf("name=") + 6)
							$DriverName = ($DriverName.Substring(0, $DriverName.IndexOf("description") - 2)).Trim()
						}
						# Get Loop driver section in array getting package name, wmi query
						while ($Counter -ne 0)
						{
							$DriverLine = $DriverArray[$Counter]
							if ($DriverLine -like "*/run:*")
							{
								$DriverPackage = ($DriverLine.Substring($DriverLine.IndexOf("/run:") + 5)).Trim()
								$DriverPackage = ($DriverPackage.Substring(0, $DriverPackage.IndexOf(" "))).Trim()
							}
							$DriverQueryCounter = $Counter
							$DriverQuery = $DriverArray[$DriverQueryCounter]
							if (($DriverQuery -like "*Query*") -and ($DriverQuery -like "*/variable*"))
							{
								while ($DriverQueryCounter -ne 0)
								{
									if (($DriverQuery -like "*model like*") -or ($DriverQuery -like "*version like*") -or ($DriverQuery -like "*product like*") -or ($DriverQuery -like "*name like*"))
									{
										$DriverQuery = ($DriverQuery.Substring($DriverQuery.IndexOf("%") + 1)).Trim()
										try
										{
											$DriverQuery = ($DriverQuery.Substring(0, $DriverQuery.IndexOf("%"))).Trim()
										}
										catch
										{
											# Failed to get driverquery - no ending %
											try
											{
												$DriverQuery = $DriverQuery -replace '"', ''
											}
											catch { }
											try
											{
												$DriverQuery = $DriverQuery -replace "'", ''
											}
											catch { }
											if ($DriverQuery -like "*</*")
											{
												$DriverQuery = ($DriverQuery.Substring(0, $DriverQuery.IndexOf("</"))).Trim()
											}
										}
										Write-Log "Driver - Driver package query: $DriverQuery"
										if ($ModelFriendlyName -like "*$DriverQuery*")
										{
											$DriverMatch = $true
										}
										if (($ModelNumber -ne $null) -and ($ModelNumber -like "*$DriverQuery*"))
										{
											$DriverMatch = $true
											Write-Log "Driver - ModelNumber ne null ($ModelNumber) and modelnumber like Driverquery ($DriverQuery)"
										}
										break
									}
									$DriverQueryCounter = $DriverQueryCounter - 1
									$DriverQuery = $DriverArray[$DriverQueryCounter]
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
		if ($DriverMatch -eq $false) { Write-Log "Driver - Error, driver for this model ($ModelFriendlyName) not found"; $Message = $Message + "Driver - driver for this model ($ModelFriendlyName) not found." + ";" }
		else { Write-Log "Driver - Driver package found: OK" }
	}
}
else { Write-Log "Driver - Model is Virtual - skipping driver check" }
if ($Message.Length -gt 5) { Write-Log "Driver - Message after driver check: $Message" }

# Get Applications from TS
if (Test-Path "$env:TEMP\ApplicationInstall.txt") { Remove-Item -Path "$env:TEMP\ApplicationInstall.txt" -Force }
if (Test-Path "$env:TEMP\ApplicationNotInstall.txt") { Remove-Item -Path "$env:TEMP\ApplicationNotInstall.txt" -Force }
Write-Log "Applications - List all enabled applications"
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
					Write-Log "Applications - Application to Install: $ApplicationName"
					try
					{
						$tsenv.Value("TSApplications") += $ApplicationName + ","
					}
					catch { }
				}
			}
			elseif ($TS[$Counter] -like "*</defaultVarList*") { "$ApplicationName,$ApplicationPackageID" | Out-File -FilePath "$env:TEMP\ApplicationNotInstall.txt" -Append; Write-Log "Applications - Application will NOT Install: $ApplicationName" }
			$Counter = $Counter + 1
		}
	}
	# Write-Log "Applications - Remove duplicate entries"
	$TSApplicationsTemp = $tsenv.Value("TSApplications")
	$TSApplicationsTemp = $TSApplicationsTemp | select -Unique
	$tsenv.Value("TSApplications") = $TSApplicationsTemp
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

Write-Log "Applications - Remove duplicate rows"
try
{
	Get-Content "$env:TEMP\ApplicationInstall.txt" | sort | Get-Unique > "$env:TEMP\ApplicationInstallTemp.txt"
	Remove-Item -Path "$env:TEMP\ApplicationInstall.txt" -Force
	Rename-Item -Path "$env:TEMP\ApplicationInstallTemp.txt" -NewName "ApplicationInstall.txt" -Force
}
catch { Write-Log "Applications - Error: Failed to remove duplicate rows" }

if ($Message.Length -gt 5)
{
	$tsenv.Value("OSDMessage") = $Message
	$tsenv.Value("OSDMessageStatus") = $true
	Write-Log "Messages - Message(s) found: $Message"
	$Message | Out-File -FilePath "$LogPath\PreFlightError.txt"
}
else
{
	Write-Log "Messages - No Message(s) found"
	$tsenv.Value("OSDMessageStatus") = $false
}

# Copy Tool to local disk
Copy-Item -Path "$ParentDirectory\Tools\CustomMessage\*.exe" -Destination "$env:windir" -Force
Write-Log "Tools - Copy $ParentDirectory\Tools\CustomMessage\OSDeployment-CustomMessage.exe to local disk, $env:windir"


