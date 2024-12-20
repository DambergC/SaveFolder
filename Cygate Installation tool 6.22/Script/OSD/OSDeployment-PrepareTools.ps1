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
Write-Log "Prepare tools - copying to local disk"

$ParentDirectory = (Get-Item $PSScriptRoot).parent.parent.FullName

Write-Log "Parent directory of package: $ParentDirectory"

# Copy Tool to local disk
try
{
	Copy-Item -Path "$ParentDirectory\Tools\CustomMessage\*.exe" -Destination "$env:windir" -Force -ErrorAction Stop
	Write-Log "Copy OSDeployment-CustomMessage.exe to local disk"
}
catch { Write-Log "Error: Failed to copy OSDeployment-CustomMessage.exe to local disk" }

# Copy ServiceUI to local disk
try
{
	Copy-Item -Path "$ParentDirectory\Tools\ServiceUI\ServiceUI.exe" -Destination "$env:windir" -Force -ErrorAction Stop
	Write-Log "Copy ServiceUI.exe to local disk"
}
catch
{ Write-Log "Error: Failed to copy ServiceUI.exe to local disk" }
