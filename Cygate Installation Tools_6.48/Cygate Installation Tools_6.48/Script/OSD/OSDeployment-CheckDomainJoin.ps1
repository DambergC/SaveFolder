
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
Write-Log "Check if device is joined to domain"

$WebServer = $tsenv.Value("OSDWebServiceAD")
$ComputerName = $env:COMPUTERNAME

try { $DomainJoinStatus = (Get-WmiObject -Class Win32_ComputerSystem).PartOfDomain } catch {}
if ($DomainJoinStatus -eq $true) { Write-Log "Device is joined to domain"; $Message = "" }
else { Write-Log "Error: Device is NOT joined to domain"; $Message = "Error: Device is NOT joined to domain, please retry installation!" }

if ($Message.Length -gt 5)
{
	$tsenv.Value("OSDMessage") = $Message
	$tsenv.Value("OSDMessageStatus") = $true
	Write-Log "Messages - Message(s) found: $Message"
}
else
{
	Write-Log "Messages - No Message(s) found"
	$tsenv.Value("OSDMessageStatus") = $false
}

# Check if computer account exist in AD
if ($DomainJoinStatus -eq $true)
{
	Write-Log "Domain Join status is OK, check if Computer account is created in AD"
	try
	{
		if (($tsenv.Value("OSDWebService") -eq $null) -or ($tsenv.Value("OSDWebService").Length -lt 2))
		{
			Write-Log "No Web Service configured"
		}
		else
		{
			if (($tsenv.Value("OSDWebServiceAD") -eq $null) -or ($tsenv.Value("OSDWebServiceAD").Length -lt 2))
			{
				Write-Log "Check if Computer account is created in AD"
				$WebServiceAD = "http://$WebServer/deploymentwebservice/ad.asmx?WDSL"
				# Get information about if computer object exist in AD
				$ADWeb = New-WebServiceProxy -Uri $WebServiceAD
				$ComputerExistInAD = $ADWeb.DoesComputerExist("$ComputerName")
				Write-Log "Computer Exist in AD [ComputerExistInAD]: $ComputerExistInAD"
				if ($ComputerExistInAD -ne $true)
				{
					$Message = "Computer account not found in AD"; $tsenv.Value("OSDMessage") = $Message; $tsenv.Value("OSDMessageStatus") = $true; Write-Log "Messages - Message(s) found: $Message"
				}
			}
		}
	}
	catch { }
}
else { Write-Log "Domain Join status is NOT OK, no need to check for existing Computer account in AD" }

# Copy Tool to local disk
Copy-Item -Path "$ParentDirectory\Tools\CustomMessage\*.exe" -Destination "$env:windir" -Force
Write-Log "Tools - Copy $ParentDirectory\Tools\CustomMessage\OSDeployment-CustomMessage.exe to local disk, $env:windir"
