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
	$global:LogPath = $tsenv.Value("_SMSTSLogPath")
	$global:LogFile = "$LogPath\Installation.log"
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
$LogFileGlobal = "_Installation Errors.log"
Write-Log " "
Write-Log "Prepare for copying of logs, Log Path: $LogPath"

$Username = $tsenv.Value("OSDLogUser")
$Password = $tsenv.Value("OSDLogUserPassword")
# $Username = $tsenv.Value("_SMSTSReserved1-000")
# $Password = $tsenv.Value("_SMSTSReserved2-000")

$ComputerName = $tsenv.Value("_SMSTSMachineName")
if (($tsenv.Value("OSDComputerName") -ne $null) -and ($tsenv.Value("OSDComputerName") -ne $ComputerName))
{
	$ComputerName = $tsenv.Value("OSDComputerName")
	Write-Log "Computer Name from TS variable: $ComputerName"
}

if (($ComputerName.Length -lt 3) -or ($ComputerName -eq $null))
{
	$ComputerName = $env:COMPUTERNAME
	Write-Log "Computer Name from OS: $ComputerName"
}

# Disonnect Log Share
if (Test-Path "T:")
{
	try
	{
		$Process = Start-Process -FilePath "NET.exe" -ArgumentList "USE T: /DELETE /Y" -NoNewWindow -Wait -PassThru -ErrorAction SilentlyContinue
		Write-Log "Disconnecting mapped drive to log share"
	}
	catch { Write-Log "Error: Failed disconnecting mapped drive to log share, " }
}

$LogShare = "\\" + $tsenv.Value("OSDLogServer") + "\Logs$"
$UsernameFull = $tsenv.Value("OSDLogServer") + "\" + $Username

# Connect Log share
try
{
	Write-Log "Mapping Network Drive T: to Log Share: $LogShare with User: $UsernameFull"
	$net = New-Object -comobject Wscript.Network
    $net.MapNetworkDrive("T:", "$LogShare", 0, "$UsernameFull", "$Password")
}
catch [System.Exception]{
	$Message = $_.Exception.Message
	Write-Log "Connecting to log share $LogShare, exit code: $Message"
	# exit
	Write-Log "Trying to map T: with NET USE"
	$Process = Start-Process -FilePath "NET.exe" -ArgumentList "USE T: $LogShare /user:$UsernameFull $Password" -NoNewWindow -Wait -PassThru -ErrorAction SilentlyContinue
	$ErrorCode = $Process.ExitCode
	Write-Log "Mapped T: with NET USE with exit code: $ErrorCode"
	if ($ErrorCode -ne 0){ exit }
}

if (($tsenv.Value("OSDFirstLogCopy") -eq $null) -or ($tsenv.Value("OSDFirstLogCopy") -ne $true))
{
	Write-Log "This is first time copying log files"
	if (Test-Path "T:\$ComputerName")
	{
		Write-Log "Folder $ComputerName already exist"
		try
		{
			Remove-Item -Path "T:\$ComputerName\*" -Recurse -Force
			Write-Log "First time connecting to log share - deleting old logs"
		}
		catch [System.Exception]{
			$Message = $_.Exception.Message
			Write-Log "First time connecting to log share - deleting old logs with exit code: $Message"
		}
		
	}
	else
	{ Write-Log "Folder $ComputerName does not exist - creating"; New-Item -Path "T:\$ComputerName" -ItemType dir -Force -ErrorAction SilentlyContinue }
		$tsenv.Value("OSDFirstLogCopy") = $true
}

# Update Timestamp on folder
try
{
	(Get-Item "T:\$ComputerName" -Force -ErrorAction Stop).LastWriteTime = (Get-Date)
	Write-Log "Update time stamp on log folder T:\$ComputerName"
}
catch { Write-Log "Error: Failed to update time stamp on folder T:\$ComputerName" }

# Copy all logs in _SMSTSLOGS and TEMP
try
{
	Copy-Item -Path "$LogPath\*.log" -Destination "T:\$ComputerName" -Force
	Copy-Item -Path "$LogPath\*.txt" -Destination "T:\$ComputerName" -Force
	Copy-Item -Path "$env:TEMP\bios*.txt" -Destination "T:\$ComputerName" -Force
	Copy-Item -Path "$env:TEMP\group*.txt" -Destination "T:\$ComputerName" -Force
	Copy-Item -Path "$env:TEMP\ts.*" -Destination "T:\$ComputerName" -Force
	# Copy-Item -Path "$env:TEMP\*.log" -Destination "T:\$ComputerName" -Force
	Copy-Item -Path "$env:TEMP\app*.txt" -Destination "T:\$ComputerName" -Force
	Write-Log "Copying logs from $LogPath to $LogShare\$ComputerName"
}
catch [System.Exception]{
	$Message = $_.Exception.Message
	Write-Log "Copying _SMSTSLOGS logs from $LogPath to $LogShare\$ComputerName with exit code: $Message"
}

# Check if BIOS error log exist to copy to root of log share
if (Test-Path "$LogPath\BIOSError.txt")
{
	Write-Log "Copying BIOS error log from $LogPath to $LogShare"
	try
	{
		foreach ($line in [System.IO.File]::ReadLines("$LogPath\BIOSError.txt"))
		{
			$line | Out-File -FilePath "T:\$LogFileGlobal" -Append
		}
		Copy-Item -Path "$LogPath\BIOSError.txt" -Destination "T:\$ComputerName" -Force
		Remove-Item -Path "$LogPath\BIOSError.txt" -Force
	}
	catch { }
}

# Check if Preflight error log exist to copy to root of log share
if (Test-Path "$LogPath\PreFlightError.txt")
{
	Write-Log "Copying Preflight error log from $LogPath to $LogShare"
	try
	{
		foreach ($line in [System.IO.File]::ReadLines("$LogPath\PreFlightError.txt"))
		{
			$line | Out-File -FilePath "T:\$LogFileGlobal" -Append
		}
		Copy-Item -Path "$LogPath\PreFlightError.txt" -Destination "T:\$ComputerName" -Force
		Remove-Item -Path "$LogPath\PreFlightError.txt" -Force
	}
	catch { }
}

# Check if OUs text file exist in temp directory
if (Test-Path "$env:TEMP\OUs.txt")
{
	Write-Log "Copying OUs.txt from $env:TEMP to $LogShare"
	Copy-Item -Path "$env:TEMP\OUs.txt" -Destination "T:\$ComputerName" -Force
}

# Copy Windows Update logs
if (Test-Path "$env:windir\CCM\Logs\WUAHandler.log")
{
	try
	{
		if (Test-Path "$env:windir\CCM\Logs\UpdatesDeployment*.log") { Copy-Item -Path "$env:windir\CCM\Logs\UpdatesDeployment*.log" -Destination "T:\$ComputerName" -Force }
		if (Test-Path "$env:windir\CCM\Logs\UpdatesHandler.log") { Copy-Item -Path "$env:windir\CCM\Logs\UpdatesHandler.log" -Destination "T:\$ComputerName" -Force }
		Copy-Item -Path "$env:windir\CCM\Logs\UpdatesStore.log" -Destination "T:\$ComputerName" -Force
		Copy-Item -Path "$env:windir\CCM\Logs\WUAHandler.log" -Destination "T:\$ComputerName" -Force
		Write-Log "Copying logs from %windir%\CCM\Logs to $LogShare\$ComputerName"
	}
	catch [System.Exception]{
		$Message = $_.Exception.Message
		Write-Log "Copying Windows Update logs from %windir%\CCM\Logs to $LogShare\$ComputerName with exit code: $Message"
	}
}

# Copy BIOS settings etc from Temp folder
if (Test-Path "$env:TEMP\*.txt")
{
	try
	{
		Copy-Item -Path "$env:TEMP\bios*.txt" -Destination "T:\$ComputerName" -Force
		Copy-Item -Path "$env:TEMP\grou*.txt" -Destination "T:\$ComputerName" -Force
		Write-Log "Copying *.txt to $LogShare\$ComputerName"
	}
	catch [System.Exception]{
		$Message = $_.Exception.Message
		Write-Log "Copying *.txt to $LogShare\$ComputerName with exit code: $Message"
	}
}

# Copy Unattend.xml
if (Test-Path "c:\Windows\Panther\unattend\Unattend.xml")
{
	try
	{
		Copy-Item -Path "c:\Windows\Panther\unattend\Unattend.xml" -Destination "T:\$ComputerName" -Force
		Write-Log "Copying Unattend.xml to $LogShare\$ComputerName"
	}
	catch [System.Exception]{
		$Message = $_.Exception.Message
		Write-Log "Copying Unattend.xml to $LogShare\$ComputerName with exit code: $Message"
	}
}

# Copy Dism logs
if (Test-Path "c:\Windows\Logs\DISM\dism.log")
{
	try
	{
		Copy-Item -Path "$env:windir\Logs\DISM\dism*.log" -Destination "T:\$ComputerName" -Force
		Write-Log "Copying dism log(s) to $LogShare\$ComputerName"
	}
	catch [System.Exception]{
		$Message = $_.Exception.Message
		Write-Log "Copying dism.log to $LogShare\$ComputerName with exit code: $Message"
	}
}

# Copy Setupact.log
if (Test-Path "C:\Windows\Panther\UnattendGC\setupact.log")
{
	try
	{
		Copy-Item -Path "$env:windir\Panther\UnattendGC\setupact.log" -Destination "T:\$ComputerName" -Force
		Write-Log "Copying setupact.log to $LogShare\$ComputerName"
	}
	catch [System.Exception]{
		$Message = $_.Exception.Message
		Write-Log "Copying setupact.log to $LogShare\$ComputerName with exit code: $Message"
	}
}

# Copy NetSetup.log
if (Test-Path "$env:windir\debug\NetSetup.log")
{
	try
	{
		Copy-Item -Path "$env:windir\debug\NetSetup.log" -Destination "T:\$ComputerName" -Force
		Write-Log "Copying NetSetup.log to $LogShare\$ComputerName"
	}
	catch [System.Exception]{
		$Message = $_.Exception.Message
		Write-Log "Copying NetSetup.log to $LogShare\$ComputerName with exit code: $Message"
	}
}

# Copy setuperr.log
if (Test-Path "$env:windir\panther\setuperr.log")
{
	try
	{
		Copy-Item -Path "$env:windir\panther\setuperr.log" -Destination "T:\$ComputerName" -Force
		Write-Log "Copying setuperr.log to $LogShare\$ComputerName"
	}
	catch [System.Exception]{
		$Message = $_.Exception.Message
		Write-Log "Copying setuperr.log to $LogShare\$ComputerName with exit code: $Message"
	}
}

# Copy HP firmware update log(s)
if (Test-Path "$env:TEMP\HP*.log")
{
	try
	{
		Copy-Item -Path "$env:TEMP\HP*.log" -Destination "T:\$ComputerName" -Force
		Write-Log "Copying HP firmware update log(s) to $LogShare\$ComputerName"
	}
	catch [System.Exception]{
		$Message = $_.Exception.Message
		Write-Log "Copying HP firmware update log(s) to $LogShare\$ComputerName with exit code: $Message"
	}
}

# Copy Application Installation Logs
if (Test-Path "$env:windir\Logs\Software")
{
	if (Test-Path "T:\$ComputerName\Applications")
	{
		Write-Log "Folder Applications already exist"
	}
	else
	{
		Write-Log "Folder Applications does not exist - creating"; New-Item -Path "T:\$ComputerName\Applications" -ItemType dir -Force -ErrorAction SilentlyContinue
	}
	try
	{
		Copy-Item -Path "$env:windir\Logs\Software\*.*" -Destination "T:\$ComputerName\Applications" -Force -ErrorAction SilentlyContinue
		if (Test-Path "$env:windir\Temp\InstallO365.xml") { Copy-Item -Path "$env:windir\Temp\InstallO365.xml" -Destination "T:\$ComputerName\Applications" -Force -ErrorAction SilentlyContinue }
		Write-Log "Copying Application Installation Logs to $LogShare\$ComputerName"
	}
	catch [System.Exception]{
		$Message = $_.Exception.Message
		Write-Log "Copying Application Installation Logs to $LogShare\$ComputerName with exit code: $Message"
	}
}
else { Write-Log "No Logs in Application folder found" }

# Copy InstallO365.xml
if (Test-Path "$env:windir\Temp\InstallO365.xml")
{
	try
	{
		Copy-Item -Path "$env:windir\Temp\InstallO365.xml" -Destination "T:\$ComputerName" -Force
		Write-Log "Copying InstallO365.xml to $LogShare\$ComputerName"
	}
	catch [System.Exception]{
		$Message = $_.Exception.Message
		Write-Log "Copying InstallO365.xml to $LogShare\$ComputerName with exit code: $Message"
	}
}

# Copy Installation log
Copy-Item -Path "$LogFile" -Destination "T:\$ComputerName" -Force

try
{
	$Process = Start-Process -FilePath "NET.exe" -ArgumentList "USE T: /DELETE /Y" -NoNewWindow -Wait -PassThru -ErrorAction SilentlyContinue
	Write-Log "Disconnecting Log share"
}
catch { Write-Log "No Log share to disconnect" }