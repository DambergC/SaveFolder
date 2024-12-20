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
Write-Log "Getting WMI from Device"

# Getting Manufacturer
$Manufacturer = (Get-WmiObject Win32_ComputerSystem).Manufacturer.TrimEnd()
Write-Log "WMI query for Manufacturer (SELECT * FROM Win32_ComputerSystem WHERE Manufacturer LIKE `"%MANUFACTURER%`""
Write-Log "Manufacturer: $Manufacturer"

# Getting Model

# Lenovo
if ($Manufacturer -like "*Lenovo*")
{
	$ModelFriendlyName = (Get-WmiObject Win32_ComputerSystemProduct).Version.TrimEnd()
	Write-Log "WMI query for Model friendly name (SELECT * FROM Win32_ComputerSystemProduct WHERE Version LIKE `"%MODELNAME%`""
	Write-Log "Model friendly name: $ModelFriendlyName"
	$ModelNumber = (Get-WmiObject Win32_ComputerSystem).Model.TrimEnd().SubString(0,4)
	Write-Log "WMI query for Model number Select * From Win32_ComputerSystem WHERE Model LIKE `"%MODELNUMBER%`""
	Write-Log "Model number: $ModelNumber"
}

# Dell
if ($Manufacturer -like "*Dell*")
{
	$ModelFriendlyName = (Get-WmiObject Win32_ComputerSystem).Model.TrimEnd()
	Write-Log "WMI query for Model friendly name (SELECT * FROM Win32_ComputerSystem WHERE Model LIKE `"%MODELNAME%`""
	Write-Log "Model friendly name: $ModelFriendlyName"
}

# HP
if ($Manufacturer -like "*Hewlett-Packard*")
{
	$ModelFriendlyName = (Get-WmiObject Win32_ComputerSystem).Model.TrimEnd()
	Write-Log "WMI query for Model friendly name (SELECT * FROM Win32_ComputerSystem WHERE Model LIKE `"%MODELNAME%`""
	Write-Log "Model friendly name: $ModelFriendlyName"
}

# Hyper-V
if ($Manufacturer -like "*Microsoft Corporation*")
{
	$ModelFriendlyName = (Get-WmiObject Win32_ComputerSystem).Model.TrimEnd()
	if ($ModelFriendlyName -like "*Virtual Machine*")
	{
		Write-Log "WMI query for Model friendly name (SELECT * FROM Win32_ComputerSystem WHERE Manufacturer LIKE ""%Microsoft Corporation%"" AND Model LIKE ""%Virtual Machine%"""
		Write-Log "Model friendly name: $ModelFriendlyName"
	}
	else
	{
		Write-Log "WMI query for Model friendly name (SELECT * FROM Win32_ComputerSystem WHERE Manufacturer LIKE ""%Microsoft Corporation%"" AND Model LIKE ""%Model%"""
		Write-Log "Model friendly name: $ModelFriendlyName"
	}
}

# VMware
if ($Manufacturer -like "*VMware*")
{
	$ModelFriendlyName = (Get-WmiObject Win32_ComputerSystem).Model.TrimEnd()
	if ($ModelFriendlyName -like "*VMware Virtual*")
	{
		Write-Log "WMI query for Model friendly name (SELECT * FROM Win32_ComputerSystem WHERE Manufacturer LIKE ""%VMware%"" AND Model LIKE ""%VMware Virtual Platform%"""
		Write-Log "Model friendly name: $ModelFriendlyName"
	}
}

# ASUS
if ($Manufacturer -like "*ASUS*")
{
	$ModelFriendlyName = (Get-WmiObject Win32_BaseBoard).Product.TrimEnd()
	
	Write-Log "WMI query for Model friendly name (SELECT * FROM Win32_BaseBoard WHERE Manufacturer LIKE ""%ASUS%"" AND Product LIKE ""%VMware Virtual Platform%"""
	Write-Log "Model friendly name: $ModelFriendlyName"
}

