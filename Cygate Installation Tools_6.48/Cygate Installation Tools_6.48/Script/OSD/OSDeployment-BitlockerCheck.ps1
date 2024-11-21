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
Write-Log "Checking TPM status"

try { $tsenv.Value("OSDReboot") = $true } catch { }

$TPM = Get-WmiObject Win32_TPM -Namespace root\cimv2\Security\MicrosoftTPM
Write-Log "IsActivated: $($TPM.IsActivated_InitialValue)"
Write-Log "IsEnabled  : $($TPM.IsEnabled_InitialValue)"
Write-Log "IsOwned    : $($TPM.IsOwned_InitialValue)"

try
{
	$TPMReady = Get-Tpm
	Write-Log "TpmPresent        : $($TPMReady.TpmPresent)"
	Write-Log "TpmReady          : $($TPMReady.TpmReady)"
	Write-Log "ManagedAuthLevel  : $($TPMReady.ManagedAuthLevel)"
	Write-Log "OwnerAuth         : $($TPMReady.OwnerAuth)"
	Write-Log "OwnerClearDisabled: $($TPMReady.OwnerClearDisabled)"
	Write-Log "AutoProvisioning  : $($TPMReady.AutoProvisioning)"
	Write-Log "LockedOut         : $($TPMReady.LockedOut)"
	Write-Log "LockoutHealTime   : $($TPMReady.LockoutHealTime)"
	Write-Log "LockoutCount      : $($TPMReady.LockoutCount)"
}
catch { Write-Log "Error: Failed to run Get-TPM command" }

#####################################  For now no action is taken - only logging ##################################
Write-Log "Will not take action, only log current settings from TPM - exiting script..."
try { $tsenv.Value("OSDReboot") = $false } catch { }
exit 0; # Will not take action, only log current settings from TPM
###################################################################################################################

If ($TpmReady.OwnerAuth) { Write-Log "TPM owned with current install ownership key - nothing to do here but move on"; try { $tsenv.Value("OSDReboot") = $false }	catch { } }
ElseIf ($TPMReady.ManagedAuthLevel -like "*Delegated*") { Write-Log "TPM ownership delegated.  Continuing..."; try { $tsenv.Value("OSDReboot") = $false } catch { } }
ElseIf ($TPM.LockedOut -eq $True)
{
	Write-Log "TPM Locked out - attempting unblock..."
	try
	{
		Unblock-TPM
		Start-Sleep 5
		$TPM = Get-Tpm
		If ($TPM.LockedOut -eq $True) { Write-Log "Error: TPM unblock unsuccessful. Please unlock manually with tpm.msc."; Exit 0 }
		ElseIf ($TPM.LockedOut -eq $False) { Write-Log "TPM Unblock successful. Please reboot and re-run script to continue."; Exit 0 }
	}
	catch { Write-Log "Error: Failed to run Unblock-TPM" }
}
ElseIf ($TPMReady.TpmReady -eq $True)
{
	# Disable OwnerAuth autoprovisioning so we can insert our own OwnerAuth key later
	
	try
	{
		Disable-TpmAutoProvisioning | Out-Null
		
		# Clear, enable, activate TPM
		Write-Log "Sending TPM clear request..."
		$ClearRequest = $TPM.SetPhysicalPresenceRequest(14)
		
		If ($ClearRequest.ReturnValue -ne "0") { Write-Log "TPM clear request failed.  Use tpm.msc to clear TPM manually."; Exit 0 }
		
		# Figure out if the request succeeded
		Write-Log "TPM clear request sent, validating return..."
		$ClearResponse = $TPM.GetPhysicalPresenceTransition().ReturnValue
		
		If ($ClearResponse -ne "0") { Write-Log "TPM clear request succeeded, but the TPM hardware returned an error code.  See event log for details."; Exit 0 }
		
		$Action = $TPM.GetPhysicalPresenceTransition().Transition
		Write-Log "TPM clear successful."
		
		Switch ($Action)
		{
			0 {
				Write-Log "UNKNOWN ERROR OCCURRED. Use tpm.msc to clear TPM manually"
			}
			1 {
				Write-Log "NEXT ACTION: Completely power off machine (shutdown, not reboot) and power on via power button"
				# & shutdown.exe /s /t 10 /d p:1:1 /c "TPM Cleared"
			}
			2 {
				Write-Log "NEXT ACTION: Restart machine (reboot, not shutdown) and accept change prompt from UEFI/BIOS"
				# & shutdown.exe /r /t 10 /d p:1:1 /c "TPM Cleared"
			}
		}
		Exit 0
	}
	catch { }
}
ElseIf ($TPMReady.TpmReady -eq $False)
{
	# Check that the vendor actually put a proper endorsement key pair in the UEFI
	If (!(($TPM.IsEndorsementKeyPairPresent()).IsEndorsementKeyPairPresent))
	{
		# If not - put one in there or the TPM will never work
		Write-Log "Creating TPM endorsement key pair..."
		$TPM.CreateEndorsementKeyPair()
	}
	
	If (($TPM.IsEndorsementKeyPairPresent()).IsEndorsementKeyPairPresent)
	{
		# Make sure that the TPM is not still "owned" by someone else - if so, something still failed
		If ($TPM.IsOwned().IsOwned -ne $False) { Write-Log "TPM still listed as owned. Use tpm.msc to clear TPM manually."; Exit 0 }
		
		# Generate an OwnerAuth password based on the string
		$OwnerAuth = $TPM.ConvertToOwnerAuth("P@ssw0rd")
		
		# Clear TPM of any ownership / password info
		Write-Log "Clearing TPM of any OwnerAuth info..."
		$TPM.Clear() | Out-Null
		
		# Take ownership using the OwnerAuth string above
		Write-Log "Writing new OwnerAuth information to TPM..."
		$TPM.TakeOwnership($OwnerAuth.OwnerAuth) | Out-Null
		
		# Re-enable OwnerAuth autoprovisioning (as this is the inbox default)
		Enable-TpmAutoProvisioning
		Write-Log "Reboot for changes to take effect."
		Exit 0
	}
}
