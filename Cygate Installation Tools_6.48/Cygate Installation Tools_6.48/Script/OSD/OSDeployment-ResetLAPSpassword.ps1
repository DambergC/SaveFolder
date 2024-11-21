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
Write-Log "Reset LAPS password"

$Installed = Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName
$Installed = $Installed + (Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName)
$LAPSInstalled = $false
if ($Installed -like "*Local Administrator Password Solution*")
{
	$LAPSInstalled = $true
	Write-Log "LAPS is installed - continue reset"
}
else { Write-Log "LAPS is NOT installed - exit" }

if ((gwmi win32_computersystem).partofdomain -eq $true)
{
	$DomainJoined = $true
}
else { $DomainJoined = $false }
Write-Log "Device is member of domain: $DomainJoined (if false no reset of LAPS will occur)"

if (($LAPSInstalled -eq $true) -and ($DomainJoined -eq $true))
{
	# Update GPO to get LAPS settings
	Write-Log "Update GPO to to get LAPS settings from domain"
	REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\GPExtensions\{827D319E-6EAC-11D2-A4EA-00C04F79F83A}" /v MaxNoGPOListChangesInterval /t REG_DWORD /d 960 /f
	Stop-Service "gpsvc" -Force
	Start-Service "gpsvc"
	sleep -Seconds 30
	
	try
	{
		Start-Process -FilePath "gpupdate.exe" -ArgumentList "/f" -WindowStyle Hidden -ErrorAction SilentlyContinue
		# Invoke-GPUpdate -RandomDelayInMinutes 0 -Force
		Write-Log "GPO Updated"
	}
	catch { Write-Log "Error: Failed to update GPO" }
	
	sleep -Seconds 60
	Write-Log "Finished updating GPO to to get LAPS settings from domain"
	
	#Get NetBIOS domain name
	$Info = new-object -com ADSystemInfo
	$t = $info.GetType()
	
	$domainName = $t.InvokeMember("DomainShortName", "GetProperty", $null, $info, $null)
	$computerName = $env:computerName
	
	#translate domain\computername to distinguishedName
	$translator = new-object -com NameTranslate
	$t = $translator.gettype()
	$t.InvokeMember("Init", "InvokeMethod", $null, $translator, (3, $null)) #resolve via GC
	$t.InvokeMember("Set", "InvokeMethod", $null, $translator, (3, "$domainName\$ComputerName`$"))
	$computerDN = $t.InvokeMember("Get", "InvokeMethod", $null, $translator, 1)
	
	Write-Log "Domain Name               : $domainName"
	Write-Log "Computer Name             : $computerName"
	Write-Log "Domain Distinguised Name  : $computerDN"
	
	#connect to computer object
	$computerObject = new-object System.DirectoryServices.DirectoryEntry("LDAP://$computerDN")
	
	# Getting Expiration Time
	try
	{
		$Computer = (Get-ADComputer –Identity "$env:COMPUTERNAME" -prop ms-Mcs-AdmPwd, ms-Mcs-AdmPwdExpirationTime)
		$ExpirationTime = [datetime]::FromFileTime($Computer."ms-Mcs-AdmPwdExpirationTime")
		Write-Log "Expiration Time  : $ExpirationTime"
	}
	catch
	{
		Write-Log "No Expiration Time Found"
	}
	
	# Get Current LAPS password using web service
	if ($tsenv.Value("OSDWebServiceADOperational") -eq $true)
	{
		$WebServiceAD = $tsenv.Value("OSDWebServiceAD")
		$ADWeb = New-WebServiceProxy -Uri $WebServiceAD
		$LAPSpassword = $ADWeb.GetComputerAttribute("$ComputerName", "ms-Mcs-AdmPwd")
		if ($LAPSpassword -ne $null)
		{
			Write-Log "Current LAPS password: $LAPSpassword"
		}
		else
		{
			Write-Log "No current LAPS password found"
		}
	}
	
	# Forcing Password Reset
	if ($tsenv.Value("OSDWebServiceADOperational") -eq $true)
	{
		$WebServiceAD = $tsenv.Value("OSDWebServiceAD")
		$ADWeb = New-WebServiceProxy -Uri $WebServiceAD
		$Result = $ADWeb.SetComputerAttribute("$ComputerName", "ms-Mcs-AdmPwdExpirationTime", "0")
		Write-Log "Resetting LAPS password with exit code: $Result"
		try
		{
			$Computer = (Get-ADComputer –Identity "$env:COMPUTERNAME" -prop ms-Mcs-AdmPwd, ms-Mcs-AdmPwdExpirationTime)
			$ExpirationTime = [datetime]::FromFileTime($Computer."ms-Mcs-AdmPwdExpirationTime")
			Write-Log "Expiration Time (after Reset)  : $ExpirationTime"
		}
		catch
		{
			Write-Log "No Expiration Time Found after Reset"
		}
	}
	
	# Update GPO to initiate password change
	Write-Log "Update GPO to initiate password change"
	REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\GPExtensions\{827D319E-6EAC-11D2-A4EA-00C04F79F83A}" /v MaxNoGPOListChangesInterval /t REG_DWORD /d 960 /f
	Stop-Service "gpsvc" -Force
	Start-Service "gpsvc"
	sleep -Seconds 30
	Invoke-GPUpdate -RandomDelayInMinutes 0 -Force
	sleep -Seconds 60
	Write-Log "Finished updating GPO to initiate password change"
	
	# Get Current LAPS password using web service
	if ($tsenv.Value("OSDWebServiceADOperational") -eq $true)
	{
		$WebServiceAD = $tsenv.Value("OSDWebServiceAD")
		$ADWeb = New-WebServiceProxy -Uri $WebServiceAD
		$LAPSpassword = $ADWeb.GetComputerAttribute("$ComputerName", "ms-Mcs-AdmPwd")
		if ($LAPSpassword -ne $null)
		{
			Write-Log "LAPS password after reset: $LAPSpassword"
		}
		else
		{
			Write-Log "No LAPS password found after reset"
		}
	}
}