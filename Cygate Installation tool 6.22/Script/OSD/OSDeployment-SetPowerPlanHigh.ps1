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
Write-Log "Set Powerplan to high performance"

try
{
	$Process = Start-Process -FilePath "PowerCfg.exe" -ArgumentList "/S 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c" -NoNewWindow -Wait -PassThru -ErrorAction Stop
	$ErrorCode = $Process.ExitCode
	Write-Log "Setting PowerPlan to High Performance with exit code: $ErrorCode"
	$Process = Start-Process -FilePath "PowerCfg.exe" -ArgumentList "/change -monitor-timeout-ac 0" -NoNewWindow -Wait -PassThru -ErrorAction Stop
	Write-Log "Setting Display shutdown to never with exit code: $ErrorCode"
}
catch { Write-Log "Failed setting PowerPlan to High Performance" }
