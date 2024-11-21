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
Write-Log "Get Driver for current model"

$OSDDriverPackageID = $tsenv.Value("OSDDriverPackageID")
if (($OSDDriverPackageID -eq $null) -or ($OSDDriverPackageID.Length -lt 3)) { Write-Log "Error: Driver variable not populated, skipping download - driver for PC not found"; exit 0 }
else { Write-Log "OSDDriverPackageID contains vaild packagenumber ($OSDDriverPackageID) - will continue driver installation" }
if (Test-Path "C:") { $DownloadDrive = "C:" } else { $DownloadDrive = "$env:SystemDrive" }

try
{
	$tsenv.Value("OSDDownloadContinueDownloadOnError") = $true; $OSDDownloadContinueDownloadOnError = $tsenv.Value("OSDDownloadContinueDownloadOnError")
	$tsenv.Value("OSDDownloadDestinationPath") = "$DownloadDrive\Drivers"; $OSDDownloadDestinationPath = $tsenv.Value("OSDDownloadDestinationPath")
	$tsenv.Value("OSDDownloadDestinationLocationType") = "Custom"; $OSDDownloadDestinationLocationType = $tsenv.Value("OSDDownloadDestinationLocationType")
	$tsenv.Value("OSDDownloadDownloadPackages") = $tsenv.Value("OSDDriverPackageID"); $OSDDownloadDownloadPackages = $tsenv.Value("OSDDownloadDownloadPackages")
	$tsenv.Value("OSDPackageCount") = 1; $OSDPackageCount = $tsenv.Value("OSDPackageCount")
	$tsenv.Value("OSDPackage") = 1; $OSDPackage = $tsenv.Value("OSDPackage")
	$tsenv.Value("OSDPackage0PackageId") = $tsenv.Value("OSDDriverPackageID"); $OSDPackage0PackageId = $tsenv.Value("OSDPackage0PackageId")
	$tsenv.Value("OSDPackage0PkgType") = 0; $OSDPackage0PkgType = $tsenv.Value("OSDPackage0PkgType")
	Write-Log "TS Variable set OSDDownloadContinueDownloadOnError:		$OSDDownloadContinueDownloadOnError"
	Write-Log "TS Variable set OSDDownloadDestinationPath:				$OSDDownloadDestinationPath"
	Write-Log "TS Variable set OSDDownloadDestinationLocationType:		$OSDDownloadDestinationLocationType"
	Write-Log "TS Variable set OSDDownloadDownloadPackages:				$OSDDownloadDownloadPackages"
	Write-Log "TS Variable set OSDPackageCount:							$OSDPackageCount"
	Write-Log "TS Variable set OSDPackage:								$OSDPackage"
	Write-Log "TS Variable set OSDPackage0PackageId:					$OSDPackage0PackageId"
	Write-Log "TS Variable set OSDPackage0PkgType:						$OSDPackage0PkgType"
}
catch { }

# Start download Package
if (!(Test-Path "$DownloadDrive\Drivers")) { New-Item -Path "$DownloadDrive\Drivers" -ItemType dir -Force }
Write-Log "Driver folder created: $DownloadDrive\Drivers"
try
{
	$Process = Start-Process -FilePath "OsdDownloadContent.exe" -Wait -PassThru -NoNewWindow -ErrorAction Stop
	$ErrorCode = $Process.ExitCode
	Write-Log "Driver Downloaded with exit code: $ErrorCode"
}
catch { Write-Log "Error: failed downloading driver" }

if (Test-Path "$DownloadDrive\Drivers")
{
	# Check if driver package is in compressed file - eg. Drivers.zip. Then uncompress before DISM
	Write-Log "Check if drivers are compressed - eg. existence of Drivers.zip in $DownloadDrive\Drivers\%PackageID%\Drivers.zip"
	$DriverZIP = (Get-ChildItem -Path "$DownloadDrive\Drivers" -Filter "Drivers.zip" -Recurse).FullName
	if (Test-Path "$DriverZIP")
	{
		Write-Log "Drivers.zip found in driver folder - will extract"
		try
		{
			Write-Log "Start extracting $DriverZIP to $DownloadDrive\Drivers"
			Expand-Archive -Path "$DriverZIP" -DestinationPath "$DownloadDrive\Drivers" -Force -ErrorAction Stop
			Write-Log "Drivers.zip extracted successfully"
		}
		catch { Write-Log "Error: Failed to extract Drivers.zip" }
		if (Test-Path "$DriverZIP") { Remove-Item -Path "$DriverZIP" -Force; Write-Log "Drivers.zip removed after extraction" }
	}
	else { Write-Log "Drivers.zip not found - assuming uncompressed drivers" }
	
	try
	{
		# Getting driver information from extracted drivers
		$DriverInf = Get-ChildItem -Path "$DownloadDrive\Drivers" -Recurse | Where-Object -Property Extension -EQ ".inf"
		$DriverLog = "$LogPath\DriverInformation.log"
		if (Test-Path "$DriverLog") { Remove-Item -Path "$DriverLog" -Force }
		"Getting driver information from $DownloadDrive\Drivers" | Out-File -FilePath "$DriverLog" -Append
		foreach ($Driver in $DriverInf)
		{
			try
			{
				$DriverInfo = Get-Content "$($Driver.FullName)" -Encoding Default
				foreach ($Line in $DriverInfo)
				{
					if ($Line -like "*copyright*")
					{
						$Manufacturer = $Line.Substring($Line.IndexOf("copyright (c)", [StringComparison]"CurrentCultureIgnoreCase") + 13)
						$Manufacturer = $Line.Substring($Line.IndexOf("copyright", [StringComparison]"CurrentCultureIgnoreCase") + 9)
					}
					if (($Line -like "*Class*") -and (!($Line -like "*FilterClass*")) -and (!($Line -like "*GUID*")))
					{
						$Class = $Line.Substring($Line.IndexOf("=") + 1)
					}
				}
				"Driver file: $($Driver.FullName), Manufacturer: $Manufacturer, Class: $Class" | Out-File $DriverLog -Append
			}
			catch { }
		}
		
		# Getting systemdrive variable
		$OSDisk = $env:OSDisk
		if ($OSDisk -like "*:*") { Write-Log "%OSDisk% variable used, value: $OSDisk" }
		elseif ($($tsenv.Value("_OSDDetectedWinDrive")) -like "*:*") { $OSDisk = $tsenv.Value("_OSDDetectedWinDrive"); Write-Log "_OSDDetectedWinDrive used, value: $OSDisk" }
		elseif (Test-Path "C:\Windows\System32\Driverstore") { $OSDisk = "C:"; Write-Log "C:\Windows\System32\Driverstore exist, OS disk to be: $OSDisk" }
		
		Write-Log "Start adding drivers to driver store using DISM"
		$Process = Start-Process -FilePath "dism.exe" -ArgumentList "/image:$OSDisk\ /Add-Driver /Driver:`"$DownloadDrive\Drivers`" /recurse /logpath:`"$LogPath\DriverDism.log`"" -Wait -NoNewWindow -PassThru -ErrorAction SilentlyContinue
		$ErrorCode = $Process.ExitCode
		Write-Log "Drivers applied using dism with exit code: $ErrorCode"
	}
	catch { Write-Log "Error: failed applying drivers using dism" }
}

# Check and install Nvidia Driver
Write-Log "Check if driver package contains Nvdida driver - requires installation"
$tsenv.Value("OSDNvidiaDriverInstall") = $false
$DriverFolder = "$DownloadDrive\Drivers"
$NvidiaSetupArray = @()
$Include = @("Setup.exe")
try
{
	$NvidiaSetupArray = ((Get-ChildItem "$DriverFolder" -Include $Include -recurse -ErrorAction SilentlyContinue) | Where-Object { $_.FullName -like "*Nvidia*" }).Fullname
}
catch { Write-Log "Error: Failed to get Nvidia Drivers" }

if ($NvidiaSetupArray -ne $null)
{
	$tsenv.Value("OSDNvidiaDriverInstall") = $true
	$tsenv.Value("OSDNvidiaDriverSetupLocation") = $NvidiaSetupArray
}

# Clean up variables
Write-Log "Resetting download variables to null"
$tsenv.Value("OSDDownloadContinueDownloadOnError") = $null
$tsenv.Value("OSDDownloadDestinationPath") = $null
$tsenv.Value("OSDDownloadDestinationLocationType") = $null
$tsenv.Value("OSDDownloadDownloadPackages") = $null
$tsenv.Value("OSDPackageCount") = $null
$tsenv.Value("OSDPackage") = $null
$tsenv.Value("OSDPackage0PackageId") = $null
$tsenv.Value("OSDPackage0PkgType") = $null
