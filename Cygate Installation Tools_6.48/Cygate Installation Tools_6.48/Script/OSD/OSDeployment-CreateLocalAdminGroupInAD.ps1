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
	$global:LogPath = $tsenv.Value("_SMSTSLogPath")
	$global:LogFile = "$LogPath\Installation.log"
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
Write-Log "Creating Local Admin AD group"

# Extract TS
Write-Log "Extracting Task Sequence"
$TStext = "$env:TEMP\TS.txt"
$TSxml = "$env:TEMP\TS.xml"
$tsenv.Value("_SMSTSTaskSequence") | Out-File -FilePath "$TStext" -Force
$xDoc = New-Object System.Xml.XmlDocument
$xDoc.Load($TStext)
$xDoc.Save($TSxml) #will save correctly

# Get Domain Join account and password
Write-Log "Getting Domain Join Account information"
$TS = Get-Content "$TSxml"
$DomainAccountArray = @()
$DomainAccountPasswordArray = @()
foreach ($item in $TS)
{
	if ($item -like "*OSDJoinAccount*")
	{
		$Account = $item.SubString($item.IndexOf(">") + 1)
		$Account = $Account.Substring(0, $Account.IndexOf("<"))
		$DomainAccountArray += $Account
		Write-Log "Found Joindomain Account in TS: $Account"
	}
	if ($item -like "*OSDJoinPassword*")
	{
		$Password = $item.SubString($item.IndexOf(">") + 1)
		$Password = $Password.Substring(0, $Password.IndexOf("<"))
		$DomainAccountPasswordArray += $Password
	}
}

if (Test-Path "$LogPath")
{
	foreach ($item in $DomainAccountArray)
	{
		Write-Log "Adding permissions on log folder to account: $item"
		icacls ("$LogPath") /Grant "$($item):(OI)(CI)M" /T
		icacls ("$LogPath") /Grant "$($item):M" /T
	}
}

# Get variables
$VariableFile = "$env:windir\TSVariables.txt"
Write-Log "Getting TS variables"
try
{
	$CreateAdminADGroup = $tsenv.Value("OSDCreateAdminADGroup")
	$LocalAdminADGroupOUPath = $tsenv.Value("OSDLocalAdminADGroupOUPath")
	$LocalAdminGroupName = $tsenv.Value("OSDLocalAdminGroupName")
	Write-Log "CreateAdminADGroup: $CreateAdminADGroup"
    Write-Log "LocalAdminADGroupOUPath: $LocalAdminADGroupOUPath"
	Write-Log "LocalAdminGroupName: $LocalAdminGroupName"
}
catch { Write-Log "Error: Failed to get TS variables" }

# Create Powershell file to run with alternate credentials
$ScriptTempName = ([io.fileinfo]$MyInvocation.MyCommand.Definition).Name
$FileContent = Get-Content "$PSScriptRoot\$ScriptTempName"
$PowershellFile = "$env:windir\CreateLocalAdminGroup.ps1"
if (Test-Path "$PowershellFile") { Remove-Item -Path "$PowershellFile" -Force }
Write-Log "Creating powershell file: $PowershellFile"
$WriteScript = $false
foreach ($line in $FileContent)
{
	if (($line -like "*Start Script*") -and ($line -notlike '*WriteScript*')) { $WriteScript = $true }
	if (($line -like "*End Script*") -and ($line -notlike '*WriteScript*')) { $WriteScript = $false }
	if ($WriteScript -eq $true) { $line | Out-File -FilePath "$PowershellFile" -Append }
}
(Get-Content "$PowershellFile").Replace("%_SMSTSLogPath%", "$LogPath") | Set-Content "$PowershellFile"
(Get-Content "$PowershellFile").Replace("%CreateAdminADGroup%", "$CreateAdminADGroup") | Set-Content "$PowershellFile"
(Get-Content "$PowershellFile").Replace("%LocalAdminADGroupOUPath%", "$LocalAdminADGroupOUPath") | Set-Content "$PowershellFile"
(Get-Content "$PowershellFile").Replace("%LocalAdminGroupName%", "$LocalAdminGroupName") | Set-Content "$PowershellFile"
(Get-Content "$PowershellFile").Replace("%COMPNAME%", "$env:COMPUTERNAME") | Set-Content "$PowershellFile"
(Get-Content "$PowershellFile").Replace("%COMPUTERNAME%", "$env:COMPUTERNAME") | Set-Content "$PowershellFile"

# Copy PSExec
$ParentDirectory = (Get-Item $PSScriptRoot).parent.parent.FullName
$ToolPath = "$ParentDirectory\Tools\Microsoft\PsExec.exe"
if (Test-Path "$ToolPath")
{
	try
	{
		Copy-Item -Path "$ToolPath" -Destination "$env:windir" -Force -ErrorAction Stop
		Write-Log "Copied $ToolPath to $env:windir"
	}
	catch { Write-Log "Error: Failed to copy $ToolPath to $env:windir" }
}
else { Write-Log "Error: Failed to find $ToolPath, could not copy" }

# Run script
$Counter = 0
foreach ($Account in $DomainAccountArray)
{
	$Password = $DomainAccountPasswordArray[$Counter]
	Write-Log "Running script in the context of account: $Account"
	$Process = Start-Process -FilePath "$env:windir\PsExec.exe" -ArgumentList "-accepteula -u `"$Account`" -p `"$Password`" -d -i -h powershell.exe -ExecutionPolicy Bypass -File `"$PowershellFile`"" -Wait -NoNewWindow -PassThru -ErrorAction SilentlyContinue
	$ErrorCode = $Process.ExitCode
	Write-Log "PSExec to add AD group ended with exit code: $ErrorCode"
	$Counter += 1
}
# if (Test-Path "$PowershellFile") { Remove-Item -Path "$PowershellFile" -Force }
exit 0

### Start Script ###
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
	$LogPath = "%_SMSTSLogPath%"
	$LogFile = "$LogPath\Installation.log"
	(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName $text" | Out-File -FilePath $LogFile -Append
}
#endregion Main Function

$CreateAdminADGroup = "%CreateAdminADGroup%"
$LocalAdminADGroupOUPath = "%LocalAdminADGroupOUPath%"
$LocalAdminGroupName = "%LocalAdminGroupName%"
Write-Log "CreateLocalAdminGroup - CreateAdminADGroup: $CreateAdminADGroup"
Write-Log "CreateLocalAdminGroup - LocalAdminADGroupOUPath: $LocalAdminADGroupOUPath"
Write-Log "CreateLocalAdminGroup - LocalAdminGroupName: $LocalAdminGroupName"

# Create AD group
$GroupType = @{
    Global      = 0x00000002
    DomainLocal = 0x00000004
    Universal   = 0x00000008
    Security    = 0x80000000
}

# Check if group already exist
$OUTestPath = $LocalAdminADGroupOUPath.Replace("LDAP://",""); $OUTestPath = "LDAP://CN=" + $LocalAdminGroupName + "," + $OUTestPath
try
{
    $Result = [ADSI]::Exists("$OUTestPath")
	Write-Log "CreateLocalAdminGroup - Check if group $LocalAdminGroupName already exist in path: $OUTestPath result: $Result"
}
catch { Write-Log "CreateLocalAdminGroup - Failed to check existence of group $LocalAdminGroupName in path: $OUTestPath" }


if ($Result -eq $false)
{
	Write-Log "CreateLocalAdminGroup - Group does not exist, will create"
	try
	{
		[ADSI]$OU = "$LocalAdminADGroupOUPath"
		$Group = $ou.create("group", "CN=$LocalAdminGroupName")
		$Group.put('grouptype', ($GroupType.Global))
		$Group.put("sAMAccountName", "$LocalAdminGroupName")
		$Group.setinfo()
		$Group.refreshcache()
		Write-Log "CreateLocalAdminGroup - Successfully created AD group: $LocalAdminGroupName in OU: $LocalAdminADGroupOUPath"
	}
	catch { Write-Log "CreateLocalAdminGroup - Error: failed to create AD group: $LocalAdminGroupName in OU: $LocalAdminADGroupOUPath with error code: $_" }
}
else
{
	if ($Result -eq $null) { Write-Log "CreateLocalAdminGroup - No result from querying AD, assume failed. Exiting..."; exit 0 }
	else { Write-Log "CreateLocalAdminGroup - Group already exists, skip creating" }
}

### End Script ###
