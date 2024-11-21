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
Write-Log "Change Windows Edition"

# Check if change is neccessary
$OSEdition = (Get-WmiObject -Class "win32_operatingsystem").caption
$ProductKey = $tsenv.Value("ProductKey")
Write-Log "OS Edition: $OSEdition"
Write-Log "Product Key: $ProductKey"
$ChangeNeeded = $false

if (($ProductKey -eq $null) -or ($ProductKey.Length -ne 29))
{
	Write-Log "Error: Product Key not found!, exiting..."
	exit 0
}
else
{
	$ProductKey | Out-File -FilePath "$env:windir\ProductKey.txt" -Append
	Copy-Item -Path "$PSScriptRoot\OSDeployment-ChangeWindowsEditioninFullOS.ps1" -Destination "$env:windir" -Force
}

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
}
else { Write-Log "Edition change not needed" }
