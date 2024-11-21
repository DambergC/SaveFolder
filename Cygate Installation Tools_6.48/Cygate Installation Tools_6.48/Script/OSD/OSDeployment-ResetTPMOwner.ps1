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
Write-Log "Reset TPM Owner"

$TPM = Get-WmiObject -Class Win32_TPM -Namespace root\CIMV2\Security\MicrosoftTpm

Write-Log "Clearing TPM ownership....."
$TSenv.Value("OSDReboot") = $false
$tmp = $oTPM.SetPhysicalPresenceRequest(10)
If ($tmp.ReturnValue -eq 0)
{
	Write-log "Successfully cleared the TPM chip. A reboot is required."
	$TSenv.Value("OSDReboot") = $true
	Exit 0
}
Else
{
	Write-Log "Failed to clear TPM ownership. Trying another method..."
	If (!(($TPM.IsEndorsementKeyPairPresent()).IsEndorsementKeyPairPresent))
	{
		Write-Log "Enable the TPM encryption"
		$TPM.CreateEndorsementKeyPair()
	}
	
	# Check if the TPM chip currently has an owner 
	If (($TPM.IsEndorsementKeyPairPresent()).IsEndorsementKeyPairPresent)
	{
		Write-Log "Convert password to hash"
		$OwnerAuth = $TPM.ConvertToOwnerAuth("customrandompassword")
		Write-Log "Clear current owner"
		$TPM.Clear($OwnerAuth.OwnerAuth)
		
		#		# Take ownership
		#		$TPM.TakeOwnership($OwnerAuth.OwnerAuth)
		
		$TSenv.Value("OSDReboot") = $false
	}
	Exit 0
}
