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
Write-Log "Driver Post installation"

try
{
	$OSDNvidiaDriverInstall = $tsenv.Value("OSDNvidiaDriverInstall")
	$OSDNvidiaDriverSetupLocation = $tsenv.Value("OSDNvidiaDriverSetupLocation")
}
catch { }

# Detect if Nvidia card is present
$NvidiaDetected = $false
$driver = gwmi win32_VideoController | Where-Object { $_.Name.contains("NVIDIA") }

if ($driver -ne $null)
{
	if ($driver -is [system.array]) # if we have 2+ gpus, we get an array
	{
		$driver_version = $driver[0].DriverVersion
	}
	else
	{
		$driver_version = $driver.DriverVersion
	}
	Write-Log "Nvidia card with driver version installed: $driver_version"
	$NvidiaDetected = $true
}
else { Write-Log "No Nvidia card detected - will not install driver" }

if (($OSDNvidiaDriverInstall -eq $true) -and ($NvidiaDetected -eq $true))
{
	Write-Log "Nvidia driver was determined to be installed"
	foreach ($SetupExe in $OSDNvidiaDriverSetupLocation)
	{
		Write-Log "Found Setup.exe in path: $SetupExe"
		if (Test-Path "$SetupExe")
		{
			try
			{
				$Process = Start-Process -FilePath "$SetupExe" -ArgumentList "-noeula -clean -nosplashscreen -s -noreboot" -Wait -PassThru -WindowStyle Hidden -ErrorAction Stop
				$ErrorCode = $Process.ExitCode
				Write-Log "Installed Nvidia driver $SetupExe with exit code: $ErrorCode"
			}
			catch { Write-Log "Error: Failed to install Nvidia driver" }
		}
		else { Write-Log "Nvidia setup file was not found - will not install driver" }
	}
}
else { Write-Log "Nvidia driver will not be installed" }
