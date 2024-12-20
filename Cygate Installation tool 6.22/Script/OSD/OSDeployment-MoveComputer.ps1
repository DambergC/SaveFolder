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
Write-Log "Preparing to move Computer object in AD"

$ComputerName = $tsenv.Value("OSDComputerName")
$MacAddress = $tsenv.Value("MacAddress001")
$UUID = $tsenv.Value("UUID")
$SMSTSAssignedSiteCode = $tsenv.Value("_SMSTSAssignedSiteCode")
$AD_Attribute = "OperatingSystem"
if ($tsenv.Value("OSDWebServiceAD") -ne $null) { $WebServiceAD = $tsenv.Value("OSDWebServiceAD") }

if (($tsenv.Value("OSDDomainMove") -eq $true) -and ($tsenv.Value("OSDWebServiceADOperational") -eq $true))
{
	Write-Log "Move is set to true and Web Service is operational"
	$CurrentLocation = $tsenv.Value("OSDDomainOUNameFromWebService")
	Write-Log "Curent OU Location: $CurrentLocation"
	$NewLocation = $tsenv.Value("OSDDomainOUName")
	Write-Log "New OU Location: $NewLocation"
	
	# Move computer in AD
	$ADWeb = New-WebServiceProxy -Uri $WebServiceAD
	$ComputerMove = $ADWeb.MoveComputerToOU("$ComputerName", "$NewLocation")
	Write-Log "Computer moved with result: $ComputerMove"
}
if ($tsenv.Value("OSDDomainMove") -eq $false) { Write-Log "Move is set to false, Move not neccessary" }
if ($tsenv.Value("OSDWebServiceADOperational") -eq $false) { Write-Log "AD Web Service not operational, move cannot occur" }
