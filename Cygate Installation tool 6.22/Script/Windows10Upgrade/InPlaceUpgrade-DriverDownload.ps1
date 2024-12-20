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
if ($RunningInTs)
{
	try
	{
		# Hide the progress dialog
		$TSProgressUI = new-object -comobject Microsoft.SMS.TSProgressUI
		$TSProgressUI.CloseProgressDialog()
	}
	catch { }
}
function global:Write-Log ($text)
{
	$LogPath = "$env:windir\Logs\Software"; If (!(Test-Path "$LogPath")) { New-Item -Path "$LogPath" -ItemType dir -Force }
	$LogFile = "$LogPath\WindowsUpgrade.log"
	(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName $text" | Out-File -FilePath $LogFile -Append
}
function Mount-ISO ($Image)
{
	if (Test-Path "$Image")
	{
		Write-Log "Start dismounting image if mounted"
		try
		{
			Dismount-ISO -Image $Image
			Write-Log "ISO: $Image dismounted"
		}
		catch { Write-Log "Could not dismount $Image, probably not mounted" }
		
		try
		{
			$MountResult = Mount-DiskImage -ImagePath "$Image" -StorageType ISO -PassThru -ErrorAction Stop
			Start-Sleep -Seconds 10
			$DriveLetter = ($MountResult | Get-Volume).DriveLetter
			if ($DriveLetter.count -gt 1) { $DriveLetter = $DriveLetter | Select-Object -First }
			if ($DriveLetter -ne $null) { $DriveLetterFixed = $DriveLetter + ":" }
			Write-Log "Mount-ISO Result, Attached:   $($MountResult.Attached)"
			Write-Log "Mount-ISO Result, DevicePath: $($MountResult.DevicePath)"
			Write-Log "Mount-ISO Result, ImagePath:  $($MountResult.ImagePath)"
			Write-Log "Mount-ISO Result, Size:       $($MountResult.Size)"
			$MountResult = $true
		}
		catch [System.Exception] { $Message = $_.Exception.Message; Write-Log "Mount-ISO: Error - failed to mount ISO: $Image with error message: $Message"; $MountResult = $false }
	}
	else { $MountResult = $false }
	
	if ($MountResult -eq $false)
	{
		# Try mounting using ImDisk tool
		$ParentDirectory = (Get-Item $PSScriptRoot).parent.parent.FullName
		if (Test-Path "$ParentDirectory\Tools\ImDisk\install.bat")
		{
			
			# Install Driver
			try
			{
				$Process = Start-Process -FilePath "$PSScriptRoot\install.bat" -ArgumentList "/fullsilent /lang:english /installfolder:`"${env:ProgramFiles(x86)}\ImDisk`" >> $env:windir\Logs\Software\ImDisk_Install.log 2>&1" -Wait -PassThru -WindowStyle Hidden -ErrorAction Stop
				$ErrorCode = $Process.ExitCode
				Write-Log "ImDisk drivers installed with exit code: $ErrorCode"
			}
			catch { Write-Log "Error installing ImDisk driver" }
			
			# Remove desktop shortcuts
			Remove-Item -Path "$env:USERPROFILE\Desktop\ImDisk*.*"
			Remove-Item -Path "$env:USERPROFILE\Desktop\Mount Image File*.*"
			Remove-Item -Path "$env:USERPROFILE\Desktop\RamDisk Configuration*.*"
			
			# Mount ISO
			if (Test-Path "${env:ProgramFiles(x86)}\ImDisk\MountImg.exe")
			{
				Try
				{
					Write-Log "Try mounting ISO using ImDisk tool"
					$Process = Start-Process -FilePath "${env:ProgramFiles(x86)}\ImDisk\MountImg.exe" -ArgumentList "`"$Image`" /MOUNT" -NoNewWindow -ErrorAction Stop
					$ErrorCode = $Process.ExitCode
				}
				catch { Write-Log "Error mounting ISO using ImDisk tool" }
				Start-Sleep -Seconds 10
			}
			else { Write-Log "Error: ${env:ProgramFiles(x86)}\ImDisk\MountImg.exe" }
			
			# Get mounted drive letter
			$DriveLetters = @("D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P")
			foreach ($DriveLetter in $DriveLetters)
			{
				$Path = $DriveLetter + ":\sources\install.wim"
				if (Test-Path "$Path") { $MountResult = $true; Write-Log "Mounted ISO connected to drive letter: $DriveLetter"; break }
			}
			if ($DriveLetter -like "*:*") { $DriveLetterFixed = $DriveLetter }
			else { $DriveLetterFixed = $DriveLetter + ":" }
		}
		else { Write-Log "Error: ImDisk tool not found - skipping" }
	}
	
	if ($MountResult -eq $false)
	{
		Write-Log "Mounting ISO did not succeed, trying fix disk problems before retry mount"
		# Try running chdksk and sfc to correct problem
		try
		{
			Write-Log "Running chkdsk /f"
			$Process = Start-Process -FilePath "chkdsk.exe" -ArgumentList "/f" -NoNewWindow -Wait -PassThru -ErrorAction Stop
			$ErrorCode = $Process.ExitCode
			Write-Log "chkdsk /f run with exit code: $ErrorCode"
		}
		catch { Write-Log "Error running chkdsk /f" }
		
		try
		{
			Write-Log "Running sfc /scannow"
			$Process = Start-Process -FilePath "sfc.exe" -ArgumentList "/scannow" -NoNewWindow -Wait -PassThru -ErrorAction Stop
			$ErrorCode = $Process.ExitCode
			Write-Log "sfc /scannow run with exit code: $ErrorCode"
		}
		catch { Write-Log "Error running sfc /scannow" }
		
		# Retry mounting ISO
		try
		{
			$MountResult = Mount-DiskImage -ImagePath "$Image" -StorageType ISO -PassThru -ErrorAction Stop
			Start-Sleep -Seconds 10
			$DriveLetter = ($MountResult | Get-Volume).DriveLetter
			if ($DriveLetter.count -gt 1) { $DriveLetter = $DriveLetter | Select-Object -First }
			if ($DriveLetter -ne $null) { $DriveLetterFixed = $DriveLetter + ":" }
			Write-Log "Mount-ISO Result, Attached:   $($MountResult.Attached)"
			Write-Log "Mount-ISO Result, DevicePath: $($MountResult.DevicePath)"
			Write-Log "Mount-ISO Result, ImagePath:  $($MountResult.ImagePath)"
			Write-Log "Mount-ISO Result, Size:       $($MountResult.Size)"
			$MountResult = $true
		}
		catch [System.Exception] { $Message = $_.Exception.Message; Write-Log "Mount-ISO: Error - failed to mount ISO: $Image with error message: $Message"; $MountResult = $false }
	}
	return $DriveLetterFixed, $MountResult
}
function Dismount-ISO ($Image)
{
	try
	{
		$DismountResult = Dismount-DiskImage -ImagePath "$Image"
	}
	catch { }
	
	# Uninstall driver (will also unmount)
	$ParentDirectory = (Get-Item $PSScriptRoot).parent.parent.FullName
	if (Test-Path "$ParentDirectory\Tools\ImDisk\install.bat")
	{
		try
		{
			$Process = Start-Process -FilePath "$ParentDirectory\Tools\ImDisk\install.bat" -ArgumentList "/silentuninstall" -Wait -PassThru -WindowStyle Hidden -ErrorAction Stop
			$ErrorCode = $Process.ExitCode
			Write-Log "ImDisk drivers uninstalled with exit code: $ErrorCode"
		}
		catch { Write-Log "Error uninstalling ImDisk driver" }
	}
	return
}
function Get-LanguageFromCode ($Code)
{
	switch ($Code)
	{
		"0416" { $Lang = 'pt-BR' }
		"0402" { $Lang = 'bg-BG' }
		"0004" { $Lang = 'zh-CN' }
		"7C04" { $Lang = 'zh-TW' }
		"041a" { $Lang = 'hr-HR' }
		"0405" { $Lang = 'cs-CZ' }
		"0406" { $Lang = 'da-DK' }
		"0413" { $Lang = 'nl-NL' }
		"0409" { $Lang = 'en-US' }
		"0425" { $Lang = 'et-EE' }
		"040b" { $Lang = 'fi-FI' }
		"040c" { $Lang = 'fr-FR' }
		"0c0c" { $Lang = 'fr-CA' }
		"0407" { $Lang = 'de-DE' }
		"0408" { $Lang = 'el-GR' }
		"040d" { $Lang = 'he-IL' }
		"040e" { $Lang = 'hu-HU' }
		"0410" { $Lang = 'it-IT' }
		"0411" { $Lang = 'ja-JP' }
		"0412" { $Lang = 'ko-KR' }
		"0426" { $Lang = 'lv-LV' }
		"0427" { $Lang = 'lt-LT' }
		"0414" { $Lang = 'nb-NO' }
		"0415" { $Lang = 'pl-PL' }
		"0816" { $Lang = 'pt-PT' }
		"0418" { $Lang = 'ro-RO' }
		"0419" { $Lang = 'ru-RU' }
		"081a" { $Lang = 'sr-Latn-CS' }
		"041b" { $Lang = 'sk-SK' }
		"0424" { $Lang = 'sl-SI' }
		"0c0a" { $Lang = 'es-ES' }
		"041d" { $Lang = 'sv-SE' }
		"041e" { $Lang = 'th-TH' }
		"041f" { $Lang = 'tr-TR' }
		"0422" { $Lang = 'uk-UA' }
	}
	return $Lang
}
#endregion Main Function

# Prepare for Logging
Write-Log " "
Write-Log "Download Driver for current model"

if ($tsenv.Value("OSDDriverPackageID") -eq $null)
{
	if ($tsenv.Value("OSDRequireDrivers") -eq $true)
	{
		Write-Log "Error: Driver variable not populated, skipping download - driver for PC not found"
		exit 0
	}
	else { Write-Log "Drivers not required for upgrade, will continue on best effort" }
}

try
{
	$tsenv.Value("OSDDownloadContinueDownloadOnError") = $true
	$tsenv.Value("OSDDownloadDestinationPath") = "$env:SystemDrive\Drivers"
	$tsenv.Value("OSDDownloadDestinationLocationType") = "Custom"
	$tsenv.Value("OSDDownloadDownloadPackages") = $tsenv.Value("OSDDriverPackageID")
	$tsenv.Value("OSDPackageCount") = 1
	$tsenv.Value("OSDPackage") = 1
	$tsenv.Value("OSDPackage0PackageId") = $tsenv.Value("OSDDriverPackageID")
	$tsenv.Value("OSDPackage0PkgType") = 0
	$OSDDownloadContinueDownloadOnError = $tsenv.Value("OSDDownloadContinueDownloadOnError")
	$OSDDownloadDestinationPath = $tsenv.Value("OSDDownloadDestinationPath")
	$OSDDownloadDestinationLocationType = $tsenv.Value("OSDDownloadDestinationLocationType")
	$OSDDownloadDownloadPackages = $tsenv.Value("OSDDownloadDownloadPackages")
	$OSDPackageCount = $tsenv.Value("OSDPackageCount")
	$OSDPackage = $tsenv.Value("OSDPackage")
	$OSDPackage0PackageId = $tsenv.Value("OSDPackage0PackageId")
	$OSDPackage0PkgType = $tsenv.Value("OSDPackage0PkgType")
	
	Write-Log "TS Variable set OSDDownloadDestinationPath:              $OSDDownloadDestinationPath"
	Write-Log "TS Variable set OSDDownloadDestinationLocationType:      $OSDDownloadDestinationLocationType"
	Write-Log "TS Variable set OSDDownloadDownloadPackages:             $OSDDownloadDownloadPackages"
	Write-Log "TS Variable set OSDPackageCount:                         $OSDPackageCount"
	Write-Log "TS Variable set OSDPackage:                              $OSDPackage"
	Write-Log "TS Variable set OSDPackage0PackageId:                    $OSDPackage0PackageId"
	Write-Log "TS Variable set OSDPackage0PkgType:                      $OSDPackage0PkgType"
}
catch { Write-Log "Error: Unable to set download variables" }

# Start download Package
Write-Log "Checking if folder $env:SystemDrive\Drivers exists"
if (!(Test-Path "$env:SystemDrive\Drivers"))
{
	New-Item -Path "$env:SystemDrive\Drivers" -ItemType dir -Force
	Write-Log "Creating folder $env:SystemDrive\Drivers"
}
else
{
	if (!(Test-Path "$env:SystemDrive\Drivers\DriverOK.txt"))
	{
		Write-Log "$env:SystemDrive\Drivers found but no DriverOK.txt - will delete and recreate folder"
		Remove-Item -Path "$env:SystemDrive\Drivers" -Recurse -Force
		New-Item -Path "$env:SystemDrive\Drivers" -ItemType dir -Force
	}
}

$Size = (Get-ChildItem "$env:SystemDrive\Drivers" -Recurse | measure Length -s).sum / 1Mb
if (($OSDPackage0PackageId -ne $null) -and ($OSDPackage0PackageId.Length -gt 3))
{
	Write-Log "OSD Package ID found: $OSDPackage0PackageId, continue downloading"
	if (($Size -lt 50) -and (!(Test-Path "$env:SystemDrive\Drivers\DriverOK.txt")))
	{
		Write-Log "Size of Drivers folder is less than 50MB and DriverOK.txt not found - driver not yet downloaded"
		try
		{
			Remove-Item -Path "$env:SystemDrive\Drivers\*" -Recurse -Force
			Write-Log "Start downloading driver content"
			$Process = Start-Process -FilePath "$env:windir\CCM\OsdDownloadContent.exe" -Wait -PassThru -NoNewWindow -ErrorAction Stop
			$ErrorCode = $Process.ExitCode
			Write-Log "Driver Downloaded with exit code: $ErrorCode"
			if ($ErrorCode -eq 0) { "$ErrorCode" | Out-File -FilePath "$env:SystemDrive\Drivers\DriverOK.txt" }
		}
		catch { Write-Log "Error: failed downloading driver" }
		
		# Check if driver package is in compressed file - eg. Drivers.zip. Then uncompress before DISM
		Write-Log "Check if drivers are compressed - eg. existence of Drivers.zip in $DownloadDrive\Drivers\%PackageID%\Drivers.zip"
		$DriverZIP = (Get-ChildItem -Path "$env:SystemDrive\Drivers" -Filter "Drivers.zip" -Recurse).FullName
		if (Test-Path "$DriverZIP")
		{
			Write-Log "Drivers.zip found in driver folder - will extract"
			try
			{
				Write-Log "Start extracting $DriverZIP to $env:SystemDrive\Drivers"
				Expand-Archive -Path "$DriverZIP" -DestinationPath "$env:SystemDrive\Drivers" -Force -ErrorAction Stop
				Write-Log "Drivers.zip extracted successfully"
				
				# Getting driver information from extracted drivers
				$DriverInf = Get-ChildItem -Path "$env:SystemDrive\Drivers" -Recurse | Where-Object -Property Extension -EQ ".inf"
				$DriverLog = "$LogPath\DriverInformation.log"
				if (Test-Path "$DriverLog") { Remove-Item -Path "$DriverLog" -Force }
				"Getting driver information from $env:SystemDrive\Drivers" | Out-File -FilePath "$DriverLog" -Append
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
				
			}
			catch { Write-Log "Error: Failed to extract Drivers.zip" }
			if (Test-Path "$DriverZIP") { Remove-Item -Path "$DriverZIP" -Force; Write-Log "Drivers.zip removed after extraction" }
		}
		else { Write-Log "Drivers.zip not found - assuming uncompressed drivers" }
	}
}
else { Write-Log "Error: OSD Package ID not found" }

if (Test-Path "$env:SystemDrive\Drivers\DriverOK.txt") { Write-Log "DriverOK.txt found - driver probably downloaded correctly" }

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