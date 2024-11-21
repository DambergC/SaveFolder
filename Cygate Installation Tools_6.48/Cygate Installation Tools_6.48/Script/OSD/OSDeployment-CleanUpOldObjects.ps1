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
Write-Log "Cleaning up Old objects in AD / SCCM"

$Username = $tsenv.Value("OSDLogUser")
$Password = $tsenv.Value("OSDLogUserPassword")

$ComputerName = $tsenv.Value("OSDComputerName")
$MacAddress = $tsenv.Value("MacAddress001")
$UUID = $tsenv.Value("UUID")
$SMSTSAssignedSiteCode = $tsenv.Value("_SMSTSAssignedSiteCode")
$AD_Attribute = "OperatingSystem"

if ($tsenv.Value("OSDWebServiceAD") -ne $null) { $WebServiceAD = $tsenv.Value("OSDWebServiceAD") }
if ($tsenv.Value("OSDWebServiceSCCM") -ne $null) { $WebServiceSCCM = $tsenv.Value("OSDWebServiceSCCM") }
Write-Log "Web Service for AD: $WebServiceAD"
Write-Log "Web Service for SCCM: $WebServiceSCCM"

# Delete C:\_SMStaskSequence
try
{
	Write-Log "Set deletion of C:\_SMSTaskSequence on first reboot"
	if (Test-Path "$env:SystemDrive\_SMSTaskSequence") { Write-Log "$env:SystemDrive\_SMSTaskSequence exists - set deletion"; Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" -Name "SMSTSCleanup" -Type String -Value "CMD /C RMDIR /S /Q C:\_SMSTaskSequence" -Force -ErrorAction Stop }
	else { Write-Log "$env:SystemDrive\_SMSTaskSequence does not exist - skip deletion" }
}
catch { Write-Log "Error: failed to set deletion of C:\_SMSTaskSequence on first reboot" }

# Delete C:\SMSTSLOG
try
{
	Write-Log "Set deletion of C:\SMSTSLOG on first reboot"
	if (Test-Path "$env:SystemDrive\SMSTSLOG") { Write-Log "$env:SystemDrive\SMSTSLOG exists - set deletion"; Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" -Name "SMSTSLOGCleanup" -Type String -Value "CMD /C RMDIR /S /Q C:\SMSTSLOG" -Force -ErrorAction Stop }
	else { Write-Log "$env:SystemDrive\SMSTSLOG does not exist - skip deletion" }
}
catch { Write-Log "Error: failed to set deletion of C:\SMSTSLOG on first reboot" }

try
{
	$ADWeb = New-WebServiceProxy -Uri $WebServiceAD
	Write-Log "Successfully connected to AD Web Service"
}
catch { Write-Log "Failed connecting to AD Web Service" }

try
{
	$SCCMWeb = New-WebServiceProxy -Uri $WebServiceSCCM
	Write-Log "Successfully connected to SCCM Web Service"
}
catch { Write-Log "Failed connecting to SCCM Web Service" }


if (($tsenv.Value("OSDNameChange") -eq $true) -and ($tsenv.Value("OSDWebServiceADOperational") -eq $true) -and ($tsenv.Value("OSDADComputerObjectRemoval") -eq $true))
{
	Write-Log "Cleanup is set to true and Web Service is operational"
	$ComputerNameOld = $tsenv.Value("OSDOldComputerName"); Write-Log "Old Computer Name: $ComputerNameOld"
	$ComputerName = $tsenv.Value("OSDComputerName"); Write-Log "New Computer Name: $ComputerName"
	
	# Restoring groups from old computer, previously saved in TS variable
	$Groups = $tsenv.Value("OSDADGroupsFromComputerObject")
	Write-Log "Getting groups from old computer object"
	if (($Groups -ne $null) -and ($Groups.Length -gt 0))
	{
		$Groups = ($Groups -split ",").Trim()
		foreach ($Group in $Groups)
		{
			$result = $ADWeb.AddComputerToGroup("$Group", "$ComputerName")
			Write-Log "AD Group: $Group  added:  $result"
		}
	}
	else { Write-Log "No AD groups found from old computer object" }
	
	# Delete Old Computer object from AD
	if ($ComputerNameOld.length -gt 5)
	{
		# find and delete the computer from AD
		$result = $ADWeb.DeleteComputerForced("$ComputerNameOld")
		if ($result -eq $true) { $result = "Successful" } else { $result = "Failed" }
		Write-Log "Deleting Old object ($ComputerNameOld) from AD: $result"
	}
}
else { Write-Log "Cleanup is set to FALSE and/or Web Service for AD is NOT operational - will not delete object in AD" }

# Delete Old Computer object from SCCM
if (($tsenv.Value("OSDNameChange") -eq $true) -and ($tsenv.Value("OSDWebServiceSCCMOperational") -eq $true))
{
	# Remove old computer object from SCCM database
	$result = $SCCMWeb.IsComputerKnown("$MacAddress", "", "$SMSTSAssignedSiteCode")
	Write-Log "Old object is known in SCCM DB: $result"
	if ($result -eq "True")
	{
		$result = $SCCMWeb.DeleteComputer("$MacAddress", "", "$SMSTSAssignedSiteCode")
		if ($result -eq $true) { $result = "Successful" }
		else { $result = "Failed" }
		Write-Log "Deleting Old object from SCCM: $result"
	}
}
else { Write-Log "Cleanup is set to FALSE and/or Web Service for SCCM is NOT operational - will not delete object in SCCM" }


# Connect to Log Share
$Process = Start-Process -FilePath "NET.exe" -ArgumentList "USE T: /DELETE /Y" -NoNewWindow -Wait -PassThru -ErrorAction SilentlyContinue
$LogShare = "\\" + $tsenv.Value("OSDLogServer") + "\Logs$"
try
{
	Write-Log "Mapping Network Drive T: to Log Share $LogShare"
	$net = New-Object -comobject Wscript.Network
	$net.MapNetworkDrive("T:", "$LogShare", 0, "$Username", "$Password")
}
catch [System.Exception]{
	$Message = $_.Exception.Message
	Write-Log "Connecting to log share $LogShare, exit code: $Message"
	# exit
	Write-Log "Trying to map T: with NET USE"
	$Process = Start-Process -FilePath "NET.exe" -ArgumentList "USE T: $LogShare /user:$Username $Password"
	$ErrorCode = $Process.ExitCode
	Write-Log "Mapped T: with NET USE with exit code: $ErrorCode"
	if ($ErrorCode -ne 0) { exit }
}

# Clean up Reservation txt file in log share
try
{
	$ReservationName = $tsenv.Value("OSDReservationName")
}
catch { $ReservationFile2 = "dummy.txt" }
$ReservationFile = $env:COMPUTERNAME + ".txt"
$ReservationFile2 = $ReservationName + ".txt"
if (Test-Path "T:\$ReservationFile")
{
	Remove-Item -Path "T:\$ReservationFile" -Force
	Write-Log "Reservation file: $ReservationFile found - deleting..."
}
elseif (Test-Path "T:\$ReservationFile2")
{
	Remove-Item -Path "T:\$ReservationFile2" -Force
	Write-Log "Reservation file: $ReservationFile2 found - deleting..."
}
else { Write-Log "Reservation file: $ReservationFile NOT found" }

# Set Removal of C:\_SMSTaskSequence after restart
REG ADD HKLM\Software\Microsoft\Windows\CurrentVersion\RunOnce /v "SMSTSCleanup" /t REG_SZ /d "CMD /C RMDIR /S /Q C:\_SMSTaskSequence" /f
# Set Removal of C:\SMSTSLOG after restart
REG ADD HKLM\Software\Microsoft\Windows\CurrentVersion\RunOnce /v "SMSTSLogCleanup" /t REG_SZ /d "CMD /C RMDIR /S /Q C:\SMSTSLog" /f

# Delete Drivers folder
if (Test-Path "$env:SystemDrive\Drivers")
{
	try
	{
		Write-Log "Delete of C:\Drivers"
		Remove-Item -Path "$env:SystemDrive\Drivers" -Recurse -Force -ErrorAction Stop
	}
	catch { Write-Log "Error: failed to delete C:\Drivers" }
}
else { Write-Log "C:\Drivers was not found, skipping deletion" }

# Remove Powershell file for creating Local Admin Group
if (Test-Path "$env:windir\CreateLocalAdminGroup.ps1")
{ 
	Remove-Item -Path "$env:windir\CreateLocalAdminGroup.ps1" -Force
	Write-Log "Deleting $env:windir\CreateLocalAdminGroup.ps1"
}
else { Write-Log "$env:windir\CreateLocalAdminGroup.ps1 was not found, skip deletion" }

# Tatoo registry with installation data
$CurrentBuild = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name CurrentBuild).CurrentBuild
$UBR = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name UBR).UBR
$OSVersion = $CurrentBuild + "." + $UBR

$OSEdition = (Get-WmiObject -Class "win32_operatingsystem").caption

$InstallDate = (Get-Date).ToString("yy-MM-dd HH:mm:ss")

try
{
	$TSversion = $tsenv.Value("TaskSequenceVer")
	$TSName = $tsenv.Value("_SMSTSPackageName")
}
catch { $TSversion = 0 }

# Get Installation Tools version from version text file in root of tools
$ParentDirectory = (Get-Item $PSScriptRoot).parent.parent.FullName
try
{
	$ToolsVersion = Get-Content "$ParentDirectory\Version.txt" -Force
}
catch { }
if ($ToolsVersion -eq $null) { $ToolsVersion = "Pre 5.4 - No version information found" }

# Get Log server
try
{
	$LogServer = $tsenv.Value("OSDLogServer")
	$LogShare = "\\" + $tsenv.Value("OSDLogServer") + "\Logs$"
}
catch {}

Set-ItemProperty -Path "HKLM:\SOFTWARE\Cygate" -Name "Installed" -Value "1" -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKLM:\SOFTWARE\Cygate" -Name "InstallDate" -Value "$InstallDate" -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKLM:\SOFTWARE\Cygate" -Name "OS Edition" -Value "$OSEdition" -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKLM:\SOFTWARE\Cygate" -Name "OS Image Build (during installation)" -Value "$OSVersion" -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKLM:\SOFTWARE\Cygate" -Name "Task Sequence Name" -Value "$TSName" -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKLM:\SOFTWARE\Cygate" -Name "Task Sequence Version" -Value "$TSversion" -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKLM:\SOFTWARE\Cygate" -Name "Installation Tools Version" -Value "$ToolsVersion" -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKLM:\SOFTWARE\Cygate" -Name "LogServer" -Value "$LogServer" -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKLM:\SOFTWARE\Cygate" -Name "LogShare" -Value "$LogShare" -Force -ErrorAction SilentlyContinue

