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
Write-Log "Configure SCCM client"

$ComputerName = $tsenv.Value("OSDComputerName")
$MacAddress = $tsenv.Value("MacAddress001")
$UUID = $tsenv.Value("UUID")
$SMSTSAssignedSiteCode = $tsenv.Value("_SMSTSAssignedSiteCode")
$AD_Attribute = "OperatingSystem"
if ($tsenv.Value("OSDWebServiceAD") -ne $null) { $WebServiceAD = $tsenv.Value("OSDWebServiceAD") }
$ParentDirectory = (Get-Item $PSScriptRoot).parent.parent.FullName

# Add Allowed Management Point(s) to registry
$AllowedMPs = $tsenv.Value("OSDAllowedMPs")
if (($AllowedMPs -ne $null) -and ($AllowedMPs.Length -gt 5))
{
	REG ADD "HKLM\SOFTWARE\Microsoft\CCM" /v "AllowedMPs" /t REG_MULTI_SZ /d $AllowedMPs /f
	Write-Log "Adding Allowed MPs into registry: $AllowedMPs"
}
else { Write-Log "AllowedMPs value empty, will not add" }

# Add site Code to SCCM Client
$SiteCode = $tsenv.Value("OSDSCCMSiteCode")
if (($SiteCode -ne $null) -and ($SiteCode.Length -gt 5))
{
	Write-Log "Settings SCCM Site Code: $SiteCode"
	$sms = New-Object -ComObject 'Microsoft.SMS.Client'
	$sms.SetAssignedSite("$SiteCode")
}
else { Write-Log "SCCM Site code not found." }


# create scheduled task to set AllowedMPs in registry until logs shows client is registered
if (($AllowedMPs -ne $null) -and ($AllowedMPs.Length -gt 5))
{
	$Process = Start-Process -FilePath "schtasks" -ArgumentList "/End /TN SetAllowedMPs /HRESULT" -NoNewWindow -Wait -PassThru -ErrorAction SilentlyContinue
	$ErrorCode = $Process.ExitCode
	Write-Log "Stopping scheduled task with exit code: $ErrorCode"
	$Process = Start-Process -FilePath "schtasks" -ArgumentList "/Delete /TN SetAllowedMPs /F /HRESULT" -NoNewWindow -Wait -PassThru -ErrorAction SilentlyContinue
	$ErrorCode = $Process.ExitCode
	Write-Log "Deleted scheduled task with exit code: $ErrorCode"
	$Process = Start-Process -FilePath "schtasks" -ArgumentList "/Create /TN SetAllowedMPs /XML `"$ParentDirectory\Script\Config\SetAllowedMPs.xml`"" -NoNewWindow -Wait -PassThru -ErrorAction SilentlyContinue
	$ErrorCode = $Process.ExitCode
	Write-Log "Created new scheduled task with exit code: $ErrorCode"
	
	# Copy and adjust script with correct servername
	Copy-Item -Path "$ParentDirectory\Script\Config\SCCMClientRegistration.ps1" -Destination "$env:windir" -Force -ErrorAction SilentlyContinue
	if (Test-Path "$env:windir\SCCMClientRegistration.ps1")
	{
		(get-content "$env:windir\SCCMClientRegistration.ps1") | foreach-object { $_ -replace "ServerName", "$AllowedMPs" } | set-content "$env:windir\SCCMClientRegistration.ps1"
	}
}
else { Write-Log "AllowedMPs value empty, will not add scheduled task" }
