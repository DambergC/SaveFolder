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
Write-Log "Collect Intel ME Information"

$ParentDirectory = (Get-Item $PSScriptRoot).parent.parent.FullName

# Get current driver version
try
{
	$IntelMEdriverVersion = (Get-WmiObject Win32_PnPSignedDriver | Where-Object { $_.DeviceName -like "*Intel(R) Management Engine Interface*" }).DriverVersion
	Write-Log "Current Intel ME driver version: $IntelMEdriverVersion"
}
catch { Write-Log "Could not identify current Intel ME driver version" }

# Get Intel ME firmware version
if (Test-Path "$env:windir\Logs\Software\SA-00086*.*") { Remove-Item -Path "$env:windir\Logs\Software\SA-00086*.*" -Force }
$Process = Start-Process -FilePath "$ParentDirectory\Tools\Intel-SA-00086\DiscoveryTool\Intel-SA-00086-console.exe" -ArgumentList "-n -c -f -p `"$env:windir\Logs\Software`"" -Wait -PassThru -NoNewWindow -ErrorAction SilentlyContinue
$FirmwareFolderVersion = (Get-ChildItem -Path "$FirmwarePath")
$ConfigFile = (Get-ChildItem -Path "$env:windir\Logs\Software" -Filter "SA-00086*.xml").FullName
Write-Log "SA-00086 output file: $ConfigFile"
if (Test-Path "$ConfigFile")
{
	[xml]$TextFileContent = (Get-Content -Path "$ConfigFile")
	$Firmware = $TextFileContent.System.ME_Firmware_Information.FW_Version
	$Risk00068 = $TextFileContent.System.System_Status.System_Risk
}
else { Write-Log "Error: Could not find SA-00086 output file" }

if (Test-Path "$env:windir\Logs\Software\$env:COMPUTERNAME.xml") { Remove-Item -Path "$env:windir\Logs\Software\$env:COMPUTERNAME.xml" -Force }
$Process = Start-Process -FilePath "$ParentDirectory\Tools\Intel-SA-00075\Intel-SA-00075-console.exe" -ArgumentList "-discover -n -c -f -p `"$env:windir\Logs\Software`"" -Wait -PassThru -NoNewWindow -ErrorAction SilentlyContinue
$FirmwareFolderVersion = (Get-ChildItem -Path "$FirmwarePath")
$ConfigFile = (Get-ChildItem -Path "$env:windir\Logs\Software" -Filter "$env:COMPUTERNAME.xml").FullName
Write-Log "SA-00075 output file: $ConfigFile"
if (Test-Path "$ConfigFile")
{
	[xml]$TextFileContent = (Get-Content -Path "$ConfigFile")
	$Risk00075 = $TextFileContent.System.System_Status.System_Risk
}
else { Write-Log "Error: Could not find SA-00075 output file" }

if (Test-Path "$env:windir\Logs\Software\SA-00125*.*") { Remove-Item -Path "$env:windir\Logs\Software\SA-00125*.*" -Force }
$Process = Start-Process -FilePath "$ParentDirectory\Tools\Intel-SA-00125\DiscoveryTool\Intel-SA-00125-console.exe" -ArgumentList "-n -c -p `"$env:windir\Logs\Software`"" -Wait -PassThru -NoNewWindow -ErrorAction SilentlyContinue
$FirmwareFolderVersion = (Get-ChildItem -Path "$FirmwarePath")
$ConfigFile = (Get-ChildItem -Path "$env:windir\Logs\Software" -Filter "SA-00125*.xml").FullName
Write-Log "SA-00125 output file: $ConfigFile"
if (Test-Path "$ConfigFile")
{
	[xml]$TextFileContent = (Get-Content -Path "$ConfigFile")
	$Firmware = $TextFileContent.System.ME_Firmware_Information.FW_Version
	$Risk00125 = $TextFileContent.System.System_Status.System_Risk
}
else { Write-Log "Error: Could not find SA-00125 output file" }

Write-Log "Intel ME firmware version: $Firmware"
Write-Log "Risk assessment (00086) according to Intel discovery tool: $Risk00068"
Write-Log "Risk assessment (00075) according to Intel discovery tool: $Risk00075"
Write-Log "Risk assessment (00125) according to Intel discovery tool: $Risk00125"


