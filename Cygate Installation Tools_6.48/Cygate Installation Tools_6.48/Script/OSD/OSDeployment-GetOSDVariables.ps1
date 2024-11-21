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
Write-Log "Prepare OSD variables for script running in other users context"

# Extract Variables to text file
$VariableFile = "$env:windir\TSVariables.txt"
if (Test-Path "$VariableFile") { Remove-Item -Path "$VariableFile" -Force }

$CreateAdminADGroup = $tsenv.Value("OSDCreateAdminADGroup")
$LocalAdminADGroupOUPath = $tsenv.Value("OSDLocalAdminADGroupOUPath")
if ($LocalAdminADGroupOUPath -notlike "*LDAP://*") { $LocalAdminADGroupOUPath = "LDAP://" + $LocalAdminADGroupOUPath }
$LocalAdminGroupName = $tsenv.Value("OSDLocalAdminGroupName")
$LocalAdminGroupName = $LocalAdminGroupName.Replace("%COMPNAME%","$env:COMPUTERNAME")
$LogPath = $tsenv.Value("_SMSTSLogPath")

"OSDLogfile=$LogFile" | Out-File -FilePath "$VariableFile" -Force
"OSDCreateAdminADGroup=$CreateAdminADGroup" | Out-File -FilePath "$VariableFile" -Append
"OSDLocalAdminADGroupOUPath=$LocalAdminADGroupOUPath" | Out-File -FilePath "$VariableFile" -Append
"OSDLocalAdminGroupName=$LocalAdminGroupName" | Out-File -FilePath "$VariableFile" -Append
"OSDLogPath=$LogPath" | Out-File -FilePath "$VariableFile" -Append
