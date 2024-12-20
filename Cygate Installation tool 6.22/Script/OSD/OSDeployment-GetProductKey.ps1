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
Write-Log "Getting ProductKey"

# Open unattend.xml and retrieve ProductKey
$UnattendFile = "c:\Windows\Panther\unattend\Unattend.xml"
$Unattend = [System.IO.File]::OpenText("$UnattendFile")
$ProductKey = $null

while ($null -ne ($line = $Unattend.ReadLine()))
{
	if ($line -like "*<ProductKey>*")
	{
		$Value = ($line.Substring($line.IndexOf("<ProductKey>") + 12, $line.Length - ($line.IndexOf("<ProductKey>") + 12))).Trim()
		$Value = $Value.Substring(0,$Value.IndexOf("</ProductKey>"))
		if (($Value -ne $null) -and ($Value.Length -eq 29))
		{
			Write-Log "Product Key: $Value"
			$tsenv.Value("ProductKey") = $Value
			$ProductKey = $Value
		}
	}
}
if ($ProductKey -eq $null) { Write-Log "Error: Product Key not found!" }