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
Write-Log "Getting Information from Web Service"

$ComputerName = $tsenv.Value("OSDCOMPUTERNAME")
if (($ComputerName -eq $null) -or ($ComputerName.Length -lt 4)) { $ComputerName = $tsenv.Value("_SMSTSMachineName") }
$MacAddress = $tsenv.Value("MacAddress001")
$UUID = $tsenv.Value("UUID")
$SMSTSAssignedSiteCode = $tsenv.Value("_SMSTSAssignedSiteCode")
if ($SMSTSAssignedSiteCode -eq $null) { $SMSTSAssignedSiteCode = $tsenv.Value("OSDSCCMSiteCode") }
$AD_Attribute = "OperatingSystem"
$WebServers = $tsenv.Value("OSDWebService")
$OSDDomainOUName = $tsenv.Value("OSDDomainOUName")

Write-Log "Computer Name from %OSDCOMPUTERNAME%: $ComputerName"
Write-Log "MAC address                         : $MacAddress"
Write-Log "SCCM Site Code                      : $SMSTSAssignedSiteCode"
Write-Log "OU Path %OSDDomainOUName%           : $OSDDomainOUName"

if (($tsenv.Value("OSDWebService") -eq $null) -or ($tsenv.Value("OSDWebService").Length -lt 2))
{
	Write-Log "No Web Service configured, quitting..."
	exit
}

# Filter Webservers if array (eg. OSDWebService = Server1.somedomain.com,Server2.somedomain.com and test if online)
Write-Log "Start Testing Web Server(s) configured: $WebServers"
$WebServers = ($WebServers -split ",").Trim()
$tsenv.Value("OSDWebServiceSCCMOperational") = $false
$tsenv.Value("OSDWebServiceADOperational") = $false


# Test of Webservice for SCCM connection - webservice could be split for different functions (eg, 1 webservice for SCCM, 1 webservice for AD)
Write-Log "Test WebServices for SCCM connection"
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
				Write-Log "SCCM site code from variable: $SMSTSAssignedSiteCode"
				$TestSCCM = $test.GetOSDCollections("$SMSTSAssignedSiteCode")
				if (($TestSCCM.Length -gt 0) -and ($TestSCCM -ne $null))
				{
					$tsenv.Value("OSDWebServiceSCCMOperational") = $true
					Write-Log "Quering data from SCCM successful"
					break
				}
				else
				{
					$ErrorCode = "Unsuccessful"
					Write-Log "Quering data from SCCM NOT successful"
				}
			}
			Write-Log "Testing Web sccm.asmx $WebServer with exit code: $ErrorCode"
		}
		catch { Write-Log "Failed connecting to: $WebServer" }
	}
}
if ($tsenv.Value("OSDWebServiceSCCMOperational") -eq $true)
{
	Write-Log "Found operational Web Service for SCCM functions on $WebServer"
	$WebServiceSCCM = "http://$WebServer/deploymentwebservice/sccm.asmx?WDSL"; $tsenv.Value("OSDWebServiceSCCM") = $WebServiceSCCM
}
else { Write-Log "No operational Web Services found for SCCM functions" }


# Test of Webservice for AD connection - webservice could be split for different functions (eg, 1 webservice for SCCM, 1 webservice for AD)
Write-Log "Test WebServices for AD connection"
foreach ($WebServer in $WebServers)
{
	if ($tsenv.Value("OSDWebServiceADOperational") -eq $false)
	{
		$WebServiceAD = "http://$WebServer/deploymentwebservice/ad.asmx?WDSL"
		$Error.clear()
		$ErrorCode = "Unknown error"
		try
		{
			$test = New-WebServiceProxy -Uri $WebServiceAD
			if ($Error -like "*unable to connect*") { $ErrorCode = "Unable to connect" }
			if ($error -like "404:") { $ErrorCode = "404 Error, Webservice not available - Check if Web Service site exist and IIS service is running" }
			if ($error -like "503:") { $ErrorCode = "503 Error, Service unavailable - check Application Pool on Web Service" }
			if ($test.UserAgent -like "*MS Web Services*")
			{
				$ErrorCode = "Web Service for AD on $WebServer is operational"
				# Test getting data from AD
				$TestAD = $test.GetADSiteNames()
				Write-Log "Return String from quering AD: $TestAD"
				if (($TestAD.Lenght -gt 0) -or ($true -ne $null))
				{
					$tsenv.Value("OSDWebServiceADOperational") = $true
					Write-Log "Quering data from AD successful"
					break
				}
			}
			Write-Log "Testing Web ad.asmx $WebServer with exit code $ErrorCode"
		}
		catch { Write-Log "Failed connecting to: $WebServer" }
	}
}
if ($tsenv.Value("OSDWebServiceADOperational") -eq $true)
{
	Write-Log "Found operational Web Service for AD functions on $WebServer"
	$WebServiceAD = "http://$WebServer/deploymentwebservice/ad.asmx?WDSL"; $tsenv.Value("OSDWebServiceAD") = $WebServiceAD
}
else { Write-Log "No operational Web Services found for AD functions" }


if ($tsenv.Value("OSDWebServiceSCCMOperational") -eq $true)
{
	Write-Log "Getting information from Web Service (SCCM)"
	
	# Get Computer Name from SCCM database
	$SCCMWeb = New-WebServiceProxy -Uri $WebServiceSCCM
	$ComputerNameFromSCCM = $SCCMWeb.GetComputerName("$MacAddress", "$UUID", "$SMSTSAssignedSiteCode")
	Write-Log "Computer Name in SCCM [ComputerNameFromSCCM]: $ComputerNameFromSCCM"
	
	# Get information about if computer object exist in SCCM database
	$SCCMWeb = New-WebServiceProxy -Uri $WebServiceSCCM
	$ComputerExistInSCCM = $SCCMWeb.IsComputerKnown("$MacAddress", "$UUID", "$SMSTSAssignedSiteCode")
	Write-Log "Computer Exist in SCCM [ComputerExistInSCCM]: $ComputerExistInSCCM"
}


if ($tsenv.Value("OSDWebServiceADOperational") -eq $true)
{
	Write-Log "Getting information from Web Service (AD)"
	
	# Get AD groups the computer is member of
	$ADWeb = New-WebServiceProxy -Uri $WebServiceAD
	$groups = $ADWeb.GetComputerGroupsByName("$ComputerName")
	$Outfile = $env:TEMP + "\Groups.txt"
	$groups | Out-File $Outfile -Encoding "ASCII"
	$GroupSize = $groups.Length
	Write-Log "Getting AD group members for computer: $ComputerName"
	Write-Log "Webservice connected: $WebServiceAD"
	Write-Log "size of groups extracted: $GroupSize"
	if (($GroupSize -gt 5) -or ($groups -ne $null))
	{
		$objFile = [System.IO.File]::OpenText("$Outfile")
		while ($null -ne ($line = $objFile.ReadLine()))
		{
			Write-Log "AD Group: $line"
			$tsenv.Value("OSDADGroupsFromComputerObject") = $tsenv.Value("OSDADGroupsFromComputerObject") + ",$line"
		}
	}
	else
	{
		Write-Log "Computer is not member of any AD groups"
	}
	
	# Check if OSDComputerName matches data from asking SCCM database (eg. is name MININT...)
	
	if ($ComputerName -like "*MININT*")
	{
		Write-Log "Name from %OSDCOMPUTERNAME% is wrong: $ComputerName"
		if (($ComputerName -ne $ComputerNameFromSCCM) -and ($ComputerNameFromSCCM.Length -gt 5))
		{
			$ComputerName = $ComputerNameFromSCCM
			Write-Log "Using Name from SCCM instead: $ComputerNameFromSCCM"
		}
	}
	
	# Get information about if computer object exist in AD
	$ADWeb = New-WebServiceProxy -Uri $WebServiceAD
	$ComputerExistInAD = $ADWeb.DoesComputerExist("$ComputerName")
	Write-Log "Computer Exist in AD [ComputerExistInAD]: $ComputerExistInAD"
	
	# Get LDAP Path in AD
	$ADWeb = New-WebServiceProxy -Uri $WebServiceAD
	$OUPath = $ADWeb.GetComputerParentPath("$ComputerName")
	$Outfile = $env:TEMP + "\OUPath.txt"
	$OUPath | Out-File $Outfile -Encoding "ASCII"
	Write-Log "Computer LDAP Path [OSDDomainOUNameFromWebService]: $OUPath"
	
	# Get OS version attribute from AD object
	$ADWeb = New-WebServiceProxy -Uri $WebServiceAD
	$OSVersionFromAD = $ADWeb.GetComputerAttribute("$ComputerName", "$AD_Attribute")
	Write-Log "OS Version (reported from AD object)[OSVersionFromAD]: $OSVersionFromAD"
	
	# Get AD site for current IP adress
	$ADWeb = New-WebServiceProxy -Uri $WebServiceAD
	$ADSite = $ADWeb.GetADSite()
	Write-Log "AD Site [OSDADSite]: $ADSite"
	
	# Get subfolders in OU path (Check if "Laptop" and "Desktop" folder exist), relative to the path configured as variable in TS
	Write-Log "Getting Subfolders on parent OU: $OSDDomainOUName"
	if ($OSDDomainOUName -ne $null)
	{
		# Extract string - LDAP:// from OUPath
		$Index = $OSDDomainOUName.IndexOf("/")
		$OSDDomainOUName = $OSDDomainOUName.Substring($Index + 2, $OSDDomainOUName.Length - ($Index + 2))
		Write-Log "LDAP path converted: $OSDDomainOUName"
		
		$ADWeb = New-WebServiceProxy -Uri $WebServiceAD
		$OUCheckFolders = $ADWeb.GetOUs("$OSDDomainOUName", "0")
		$Length = $OUCheckFolders.Length
		Write-Log "Number of subfolder(s) under $OSDDomainOUName : $Length"
		
		if (($OUCheckFolders -ne $null) -or ($OUCheckFolders.Length -gt 1))
		{
			$Outfile = $tsenv.Value("_SMSTSLogPath") + "\OUFolders.txt"
			$OUCheckFolders.Path | Out-File $Outfile -Encoding "ASCII"
			$DesktopLaptopFolderFound = $false
			Write-Log "Enumerating OU Folder(s) below $OSDDomainOUName"
			$objFile = [System.IO.File]::OpenText("$Outfile")
			while ($null -ne ($line = $objFile.ReadLine()))
			{
				if ($line -like "*OU=*")
				{
					$Index = $line.IndexOf("OU=")
					$OUTemp = ($line.Substring($Index, $line.Length - $Index)).Trim()
					$Index = $OUTemp.IndexOf(",")
					$OUTemp = ($OUTemp.Substring(0, $Index)).Trim()
					$Index = $OUTemp.IndexOf("=")
					$OUTemp = $OUTemp.Substring($Index + 1, $OUTemp.Length - ($Index + 1))
					Write-Log "OU Folder: $OUTemp"
					
					if (($OUTemp -like "Laptop*") -and (($OUTemp.Length -eq 6) -or ($OUTemp.Length -eq 7)))
					{
						$tsenv.Value("OSDDomainNameOULaptop") = "LDAP://OU=" + $OUTemp + "," + $OSDDomainOUName
						$TempOUName = $tsenv.Value("OSDDomainNameOULaptop")
						Write-Log "Laptop OU found, full path: $TempOUName"
						$DesktopLaptopFolderFound = $true
					}
					elseif (($OUTemp -like "Desktop*") -and (($OUTemp.Length -eq 7) -or ($OUTemp.Length -eq 8)))
					{
						$tsenv.Value("OSDDomainNameOUDesktop") = "LDAP://OU=" + $OUTemp + "," + $OSDDomainOUName
						$TempOUName = $tsenv.Value("OSDDomainNameOUDesktop")
						Write-Log "Desktop OU found, full path: $TempOUName"
						$DesktopLaptopFolderFound = $true
					}
				}
			}
			if ($DesktopLaptopFolderFound -eq $false) {	Write-Log "No Desktop/Laptop subfolder found" }
		}
		else
		{
			Write-Log "No OU subfolder(s) found (or invalid path): $OUCheckFolders"
		}
	}
}

# Set TS variables
$tsenv.Value("ComputerExistInSCCM") = $ComputerExistInSCCM
$tsenv.Value("ComputerExistInAD") = $ComputerExistInAD
if (($OUPath -ne $null) -and ($OUPath.Length -gt 5)) { $tsenv.Value("OSDDomainOUNameFromWebService") = $OUPath }
$tsenv.Value("OSVersionFromAD") = $OSVersionFromAD
$tsenv.Value("ComputerNameFromSCCM") = $ComputerNameFromSCCM
$tsenv.Value("OSDADSite") = $ADSite
