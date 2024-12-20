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
Write-Log "Adding Groups from TS custom variables"

$ComputerName = $tsenv.Value("OSDCOMPUTERNAME")
$MacAddress = $tsenv.Value("MacAddress001")
$UUID = $tsenv.Value("UUID")
$SMSTSAssignedSiteCode = $tsenv.Value("_SMSTSAssignedSiteCode")
$AD_Attribute = "OperatingSystem"
if ($tsenv.Value("OSDWebServiceAD") -ne $null) { $WebServiceAD = $tsenv.Value("OSDWebServiceAD") }
$Groups = $tsenv.Value("OSDADGroups")
$OSDCompDescription = $tsenv.Value("OSDCompDescription")

$ADWeb = New-WebServiceProxy -Uri $WebServiceAD

if (($tsenv.Value("OSDADGroups") -ne $null) -and ($tsenv.Value("OSDWebServiceADOperational") -eq $true))
{
	# Filter group names if array (eg. OSDADGroups = Group1, Group2 etc)
	Write-Log "Start Testing Group(s) configured: $Groups"
	$Groups = ($Groups -split ",").Trim()
	
	foreach ($Group in $Groups)
	{
		$result = $ADWeb.AddComputerToGroup("$Group", "$ComputerName")
		Write-Log "AD Group: $Group  added:  $result"
	}
}

# Set computer description
if (($tsenv.Value("OSDCompDescription") -ne $null) -and ($tsenv.Value("OSDWebServiceADOperational") -eq $true))
{
	$result = $ADWeb.SetComputerDescription("$ComputerName", "$OSDCompDescription")
	Write-Log "Computer Description: $OSDCompDescription  added:  $result"
}