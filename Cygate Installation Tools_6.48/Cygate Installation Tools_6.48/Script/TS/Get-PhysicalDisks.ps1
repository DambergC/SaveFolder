$global:ScriptName = "[Get-PhysicalDisks] (TS-Step)"

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
function Get-BusType ($Bustype)
{
	if ($Bustype -eq 0) { $Bustype = "unknown" }
	if ($Bustype -eq 1) { $Bustype = "SCSI" }
	if ($Bustype -eq 2) { $Bustype = "ATAPI" }
	if ($Bustype -eq 3) { $Bustype = "ATA" }
	if ($Bustype -eq 4) { $Bustype = "IEEE 1394" }
	if ($Bustype -eq 5) { $Bustype = "SSA" }
	if ($Bustype -eq 6) { $Bustype = "Fibre Channel" }
	if ($Bustype -eq 7) { $Bustype = "USB" }
	if ($Bustype -eq 8) { $Bustype = "RAID" }
	if ($Bustype -eq 9) { $Bustype = "iSCSI" }
	if ($Bustype -eq 10) { $Bustype = "Serial Attached SCSI (SAS)" }
	if ($Bustype -eq 11) { $Bustype = "Serial ATA (SATA)" }
	if ($Bustype -eq 12) { $Bustype = "Secure Digital (SD)" }
	if ($Bustype -eq 13) { $Bustype = "Multimedia Card (MMC)" }
	if ($Bustype -eq 14) { $Bustype = "This value is reserved for system use." }
	if ($Bustype -eq 15) { $Bustype = "File-Backed Virtual" }
	if ($Bustype -eq 16) { $Bustype = "Storage spaces" }
	if ($Bustype -eq 17) { $Bustype = "NVMe" }
	return $Bustype
}
#endregion Main Function

# Prepare for Logging
Write-Log " "
Write-Log "Getting Physical Disks"

# Count Disks
Write-Log "Checking the Drive Count..."
$diskCount = (Get-Disk).Number.Count
$tsenv.Value("OSDMultiDisk") = $false

if ($diskCount -eq 1) { Write-Log "Only 1 disk detected - exiting..."; $TSEnv.Value("OSDDiskIndex") = 0; exit 0 }

# If there's more than 1, check for NVMe's.
# Only NVMe disks larger than 120GB will be targeted.  This should exclude smaller Optane drives.
elseif ($diskCount -gt 1)
{
	$tsenv.Value("OSDMultiDisk") = $true
	Write-Log "More than 1 physical disk identified, checking if NVME type is present"
	$nvmeDsks = @()
	$nvmeDsks += (Get-WmiObject -Namespace root\microsoft\windows\storage -Class msft_disk) | Where-Object { $_.BusType -eq 17 } | Where-Object { $_.Size -gt 128849018880 }
	
	$DiskCountNVME = $nvmeDsks.Count
	Write-Log "Found $DiskCountNVME NVMe disk(s)"
	
	if ($DiskCountNVME -gt 0)
	{
		foreach ($disk in $nvmeDsks)
		{
			$Size = [Math]::Round($($disk.Size) /1GB, 0)
			Write-Log "Disk Name:             $($disk.FriendlyName)"
			Write-Log "Disk Size:             $Size GB"
			Write-Log "Disk Number:           $($disk.number)"
			Write-Log "Disk Firmware version: $($disk.FirmwareVersion)"
			Write-Log "Disk Location:         $($disk.Location)"
		}
		
		# Identify the smallest disk to install the OS to
		Write-Log "Determining the smaller disk to assign as disk 0"
		$osDisk = ($nvmeDsks | Sort-Object -Property Size | Select-Object -First 1).Number
		Write-Log "OS disk chosen from smallest disk, disk number: $osDisk"
		$TSEnv.Value("OSDDiskIndex") = $osDisk
		Write-Log "NVMe should now equal Disk 0 in the TS."
	}
}

if (!($nvmeDsks) -and ($diskCount -gt 1))
{
	$tsenv.Value("OSDMultiDisk") = $true
	Write-Log "No NVMe disk found but more than 1 disk..."
	$PhysicalDisk = @()
	$PhysicalDisk += (Get-WmiObject -Namespace root\microsoft\windows\storage -Class msft_disk) | Where-Object { $_.Size -gt 128849018880 }
	
	Write-Log "Found $diskCount disk(s)"
	
	foreach ($disk in $PhysicalDisk)
	{
		$Size = [Math]::Round($($disk.Size) /1GB, 0)
		$BusType = Get-BusType $($disk.BusType)
		Write-Log "Disk Name:             $disk.FriendlyName"
		Write-Log "Disk Size:             $Size GB"
		Write-Log "Disk Number:           $disk.number"
		Write-Log "Disk Firmware version: $disk.FirmwareVersion"
		Write-Log "Disk Location:         $disk.Location"
		Write-Log "Disk Bus Type:         $BusType"
	}
	
	Write-Log "Determining the smaller disk to assign as disk 0"
	$osDisk = ($PhysicalDisk | Sort-Object -Property Size | Select-Object -First 1).Number
	Write-Log "OS disk chosen from smallest disk, disk number: $osDisk"
	$TSEnv.Value("OSDDiskIndex") = $osDisk
	Write-Log "Smallest disk should now equal Disk 0 in the TS."
}
