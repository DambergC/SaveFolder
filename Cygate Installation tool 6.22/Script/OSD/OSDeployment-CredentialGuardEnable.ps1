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
Write-Log "Enable Credential Guard"

$SCCMServers = $tsenv.Value("OSDManagementPoint")

if ((gwmi win32_computersystem).partofdomain -eq $true)
{
	$DomainJoined = $true
}
else { $DomainJoined = $false }
Write-Log "Device is member of domain: $DomainJoined"

# Get Build version
$BuildVersion = [System.Environment]::OSVersion.Version.Build

if ($DomainJoined -eq $true)
{
	Write-Log "Machine member of domain - will enable credential guard"
	if ($BuildVersion -lt 17763)
	{
		Write-Log "Windows Build version ($BuildVersion) is less than 17763, will install Hyper-V and HostGuardian for credential guard"
		try
		{
			# For version older than Windows 10 version 1607 (build 14939), enable required Windows Features for Credential Guard
			Enable-WindowsOptionalFeature -FeatureName Microsoft-Hyper-V-HyperVisor -Online -All -LimitAccess -NoRestart -ErrorAction Stop
			Write-Log "Successfully enabled Microsoft-Hyper-V-HyperVisor feature"
			
			# For version older than Windows 10 version 1607 (build 14939), add the IsolatedUserMode feature as well
			Enable-WindowsOptionalFeature -FeatureName HostGuardian -Online -All -LimitAccess -NoRestart -ErrorAction Stop
			Write-Log "Successfully enabled IsolatedUserMode feature"
		}
		catch [System.Exception] {
			Write-Log "An error occured when enabling required windows features"
		}
	}
	else { Write-Log "Windows Build version ($BuildVersion) same or greater than 17763, will NOT install Hyper-V and HostGuardian for credential guard" }
	
	# Add required registry key for Credential Guard
	$RegistryKeyPath = "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard"
	if (-not (Test-Path -Path $RegistryKeyPath))
	{
		Write-Log "Creating HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\DeviceGuard registry key"
		New-Item -Path $RegistryKeyPath -ItemType Directory -Force
	}
	
	# Add registry value RequirePlatformSecurityFeatures - 1 for Secure Boot only, 3 for Secure Boot and DMA Protection
	Write-Log "Adding HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\DeviceGuard\RequirePlatformSecurityFeatures value as DWORD with data 1"
	New-ItemProperty -Path $RegistryKeyPath -Name RequirePlatformSecurityFeatures -PropertyType DWORD -Value 1 -Force
	
	# Add registry value EnableVirtualizationBasedSecurity - 1 for Enabled, 0 for Disabled
	Write-Log "Adding HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\DeviceGuard\EnableVirtualizationBasedSecurity value as DWORD with data 1"
	New-ItemProperty -Path $RegistryKeyPath -Name EnableVirtualizationBasedSecurity -PropertyType DWORD -Value 1 -Force
	
	# Add registry value LsaCfgFlags - 1 enables Credential Guard with UEFI lock, 2 enables Credential Guard without lock, 0 for Disabled
	Write-Log "Adding HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Lsa\LsaCfgFlags value as DWORD with data 1"
	New-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Control\Lsa -Name LsaCfgFlags -PropertyType DWORD -Value 1 -Force
	
	# Write end of log file
	Write-Log "Successfully enabled Credential Guard"
}
else { Write-Log "Machine NOT member of domain - will NOT enable credential guard" }