# Some computer models have an OEM productkey in BIOS. During installation when activating an Enterprise installation might downgrade to Professional depending on the BIOS key.
# Variable $tsenv.Value("UseOEMProductKey") when true utilizes BIOS key, false will use configured MAK/KMS key.

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
Write-Log "Activating Windows"

$ComputerName = $tsenv.Value("OSDCOMPUTERNAME")
$MacAddress = $tsenv.Value("MacAddress001")
$UUID = $tsenv.Value("UUID")
$SMSTSAssignedSiteCode = $tsenv.Value("_SMSTSAssignedSiteCode")
$AD_Attribute = "OperatingSystem"
if ($tsenv.Value("OSDWebServiceAD") -ne $null) { $WebServiceAD = $tsenv.Value("OSDWebServiceAD") }
$Groups = $tsenv.Value("OSDADGroups")

# Check if BIOS OEM key
$ProdKeyBIOS = (Get-WmiObject -Class SoftwareLicensingService).OA3xOriginalProductKey
if ($ProdKeyBIOS.Length -gt 5) { Write-Log "BIOS OEM key exists: $ProdKeyBIOS"; $ProductKey = $ProdKeyBIOS }

if (($tsenv.Value("UseOEMProductKey") -eq $false) -and ($ProdKeyBIOS.Length -gt 5))
{
	if ($tsenv.Value("OSDOSVersion") -eq "WIN7x64")
	{
		$ProductKey = $tsenv.Value("OSDWinSettingsProdKeyWIN7")
		Write-Log "BIOS key not used, Windows 7 key is: $ProductKey"
	}
	if ($tsenv.Value("OSDOSVersion") -eq "WIN81x64")
	{
		$ProductKey = $tsenv.Value("OSDWinSettingsProdKeyWIN81")
		Write-Log "BIOS key not used, Windows 8.1 key is: $ProductKey"
	}
	if ($tsenv.Value("OSDOSVersion") -eq "WIN10x64")
	{
		$ProductKey = $tsenv.Value("OSDWinSettingsProdKeyWIN10")
		Write-Log "BIOS key not used, Windows 10 key is: $ProductKey"
		Invoke-Expression "cscript /b C:\Windows\System32\slmgr.vbs -ato"
		Start-Sleep 5
		$Process = Start-Process -FilePath "Changepk.exe" -ArgumentList "/ProductKey `"$ProductKey`"" -NoNewWindow -Wait -PassThru -ErrorAction SilentlyContinue
		$ErrorCode = $Process.ExitCode
		Write-Log "Change Windows 10 Product key using Changepk.exe with exit code: $ErrorCode"
		Start-Sleep 5
	}
}
Invoke-Expression "cscript /b C:\Windows\System32\slmgr.vbs -ipk $Productkey"
Start-Sleep 5
Invoke-Expression "cscript /b C:\Windows\System32\slmgr.vbs -ato"
