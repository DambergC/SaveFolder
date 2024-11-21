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
Write-Log "Check Joindomain Account"

$Username = $tsenv.Value("OSDLogUser")
$Password = $tsenv.Value("OSDLogUserPassword")
$Message = ""

# Extract TS
$TStext = "$env:TEMP\TS.txt"
$TSxml = "$env:TEMP\TS.xml"
$tsenv.Value("_SMSTSTaskSequence") | Out-File -FilePath "$TStext" -Force
$xDoc = New-Object System.Xml.XmlDocument
$xDoc.Load($TStext)
$xDoc.Save($TSxml) #will save correctly


# Get Join domain account
$TSFile = [System.IO.File]::OpenText("$TSxml")
while ($null -ne ($line = $TSFile.ReadLine()))
{
	if ($line -like "*OSDJoinAccount*")
	{
		$pos = $line.IndexOf(">")
		$JoinDomainAccount = $line.Substring($pos + 1)
		$pos = $JoinDomainAccount.IndexOf("</")
		$JoinDomainAccount = $JoinDomainAccount.Substring(0, $pos)
		if ($JoinDomainAccount -like "*\*")
		{
			$JoinDomainAccountFull = $JoinDomainAccount
			$pos = $JoinDomainAccount.IndexOf("\")
			$JoinDomainAccount = $JoinDomainAccount.Substring($pos + 1)
		}
	}
}
Write-Log "Join Domain Information - Join Account:       $JoinDomainAccountFull"

$ADS_UF_LOCKOUT = 16
$Attribute = "msds-user-account-control-computed"
$ADSearcher = New-Object System.DirectoryServices.DirectorySearcher
$ADSearcher.PageSize = 1000
$ADSearcher.Filter = "samaccountname=$JoinDomainAccount"
$User = $ADSearcher.FindOne()
$MyUser = $User.GetDirectoryEntry()
$MyUser.RefreshCache($Attribute)
$UserAccountFlag = $MyUser.Properties[$Attribute].Value
if ($UserAccountFlag -band $ADS_UF_LOCKOUT)
{
	$JoinDomainAccountLockStatus = $true
	$Message = $Message + "Join Domain Account - Join Domain Account is Locked. Make sure account is unlocked before pressing OK!" + ";"
}
else { $JoinDomainAccountLockStatus = $false }
Write-Log "Join Domain Information - Join Account Locked:       $JoinDomainAccountLockStatus"

if ($Message.Length -gt 5)
{
	$tsenv.Value("OSDMessage") = $Message
	$tsenv.Value("OSDMessageStatus") = $true
	Write-Log "Message(s) found: $Message"
}
else
{
	Write-Log "No Message(s) found"
	$tsenv.Value("OSDMessageStatus") = $false
}


# Copy Tool to local disk
Copy-Item -Path "$PSScriptRoot\*.exe" -Destination "$env:windir" -Force
Write-Log "Copy OSDeployment-CustomMessage.exe to local disk"

