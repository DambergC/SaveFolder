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
	$LogFile = "$env:windir\Logs\ChangeWindowsEdition.log"
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
Write-Log "Change Windows Edition"

# Open ProductKey File
if (Test-Path "$env:windir\ProductKey.txt")
{
	$ProductKeyFile = [System.IO.File]::OpenText("$env:windir\ProductKey.txt")
	while ($null -ne ($line = $ProductKeyFile.ReadLine()))
	{
		if ($line -ne $null)
		{
			$ProductKey = $line
			Write-Log "ProductKey found: $ProductKey"
			break
		}
	}
}
else
{
	Write-Log "Error: Product Key not found!, exiting..."
	exit 0
}

# Check if change is neccessary
$OSEdition = (Get-WmiObject -Class "win32_operatingsystem").caption
Write-Log "OS Edition: $OSEdition"
Write-Log "Product Key: $ProductKey"
$ChangeNeeded = $false

if ($OSEdition -like "*Windows 8.1*")
{
	if (($OSEdition -like "*Pro*") -and ($ProductKey -ne "GCRJD-8NW9H-F2CDX-CCM8D-9D6T9")) { $ChangeNeeded = $true; Write-Log "OS Edition: $OSEdition with wrong Product Key - Edition change initiated" }
	if (($OSEdition -like "*Enter*") -and ($ProductKey -ne "MHF9N-XY6XB-WVXMC-BTDCT-MKKG7")) { $ChangeNeeded = $true; Write-Log "OS Edition: $OSEdition with wrong Product Key - Edition change initiated" }
}
if ($OSEdition -like "*Windows 10*")
{
	if (($OSEdition -like "*Pro*") -and ($ProductKey -ne "W269N-WFGWX-YVC9B-4J6C9-T83GX")) { $ChangeNeeded = $true; Write-Log "OS Edition: $OSEdition with wrong Product Key - Edition change initiated" }
	if (($OSEdition -like "*Enter*") -and ($ProductKey -ne "NPPR9-FWDCX-D2C8J-H872K-2YT43")) { $ChangeNeeded = $true; Write-Log "OS Edition: $OSEdition with wrong Product Key - Edition change initiated" }
}

if ($ChangeNeeded -eq $true)
{
	$Process = Start-Process -FilePath "changepk.exe" -ArgumentList "/ProductKey $ProductKey" -NoNewWindow -Wait -PassThru -ErrorAction SilentlyContinue
	$ErrorCode = $Process.ExitCode
	Write-Log "Edition changed with exit code: $ErrorCode"
	sleep -Seconds 30
	Restart-Computer -Force
}
else { Write-Log "Edition change not needed" }
