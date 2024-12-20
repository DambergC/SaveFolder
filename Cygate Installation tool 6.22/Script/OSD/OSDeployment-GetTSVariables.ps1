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
Write-Log "Get TS Variables"

# Ectracting all TS variables into log file
$ExcludeVariables = @('_OSDOAF', '_SMSTSReserved', '_SMSTSTaskSequence')

$now = Get-Date -Format "yyyy-MM-dd-HH-mm-ss"
$logFile2 = "TSVariables-$now.log"
$logFileFullName = Join-Path -Path $logPath -ChildPath $logFile2

function MatchArrayItem {
    param (
        [array]$Arr,
        [string]$Item
        )

    $result = ($null -ne ($Arr | ? { $Item -match $_ }))
    return $result
}

$tsenv.GetVariables() | % {
    if(!(MatchArrayItem -Arr $ExcludeVariables -Item $_)) {
        "$_ = $($tsenv.Value($_))" | Out-File -FilePath $logFileFullName -Append
    }
}
