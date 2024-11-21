# Script will open smsts.log and find from which DP it downloads content

$tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment
$LogPath = $tsenv.Value("_SMSTSLogPath")

# Prepare for Logging
$LogPath = $tsenv.Value("_SMSTSLogPath")
$LogFile = "$LogPath\OSDBranding.log"
$ScriptName = "[" + ([io.fileinfo]$MyInvocation.MyCommand.Definition).BaseName + "]"
if (Test-Path "$LogFile") { "$ScriptName Branding log started..." | Out-File -FilePath $LogFile -Append }
else { "$ScriptName Branding log started..." | Out-File -FilePath $LogFile -Force }

try
{
	[string]$RegServerName = Get-ItemProperty -Path "HKLM\Software\Cygate" -Name "DistributionPoint" -ErrorAction SilentlyContinue
}
catch
{ "$ScriptName Registry Key not set (not found)" | Out-File -FilePath $LogFile -Append }


if (($RegServerName -eq $null) -or ($RegServerName -eq "") -or ($tsenv.Value("OSDDistributionPoint") -eq $null) -or ($tsenv.Value("OSDDistributionPoint").Length -lt 4))
{
	$ServerName = ""
}
if ($tsenv.Value("OSDDistributionPoint").Length -gt 4)
{
	$ServerName = $tsenv.Value("OSDDistributionPoint")
}

if ($RegServerName.Length -lt 4)
{
	$text = "No server found in registry" + "   " + (Get-Date).ToString("yy-MM-dd HH:mm")
	Out-File $LogFile -Append -InputObject $text
	$ServerName = "Not Found"
	
	if (Test-Path "$LogPath\smsts.log")
	{
		$text = "smsts.log found" + "   " + (Get-Date).ToString("yy-MM-dd HH:mm")
		Out-File $LogFile -Append -InputObject $text
		$LogContent = Get-Content -Path "$LogPath\smsts.log" -ErrorAction SilentlyContinue
		[array]::Reverse($LogContent)
		
		foreach ($DPline in $LogContent)
		{
			if ($DPline -eq $null)
			{
				Break
			}
			if ($DPline -like "*File: http://*")
			{
				$text = "Download info found in log file eg. File: http://" + "   " + (Get-Date).ToString("yy-MM-dd HH:mm")
				Out-File $LogFile -Append -InputObject $text
				
				$ServerName = $DPLine.substring($DPLine.IndexOf("File: http://") + 13)
				$ServerName = $ServerName.substring(0, $ServerName.IndexOf("/SMS"))
				$ServerName = $ServerName.substring(0, $ServerName.IndexOf("."))
				Reg add "HKLM\Software\Cygate" /V "DistributionPoint" /T REG_SZ /D "$ServerName" /F
				$tsenv.Value("OSDDistributionPoint") = $ServerName
				break
			}
		}
	}
}
else
{
	$RegServerName = $ServerName
	
	$text = "Server found in registry" + "   " + (Get-Date).ToString("yy-MM-dd HH:mm")
	Out-File $LogFile -Append -InputObject $text
	
	if (Test-Path "$LogPath\smsts.log")
	{
		$text = "smsts.log found" + "   " + (Get-Date).ToString("yy-MM-dd HH:mm")
		Out-File $LogFile -Append -InputObject $text
		
		$LogContent = Get-Content -Path "$LogPath\smsts.log" -ErrorAction SilentlyContinue
		[array]::Reverse($LogContent)
		
		
		foreach ($DPline in $LogContent)
		{
			if ($DPline -eq $null)
			{
				Break
			}
			if ($DPline -like "*File: http://*")
			{
				$text = "Download info found in log file eg. File: http://" + "   " + (Get-Date).ToString("yy-MM-dd HH:mm")
				Out-File $LogFile -Append -InputObject $text
				
				$ServerName = $DPLine.substring($DPLine.IndexOf("File: http://") + 13)
				$ServerName = $ServerName.substring(0, $ServerName.IndexOf("/SMS"))
				$ServerName = $ServerName.substring(0, $ServerName.IndexOf("."))
				if ($RegServerName -ne $ServerName)
				{
					$text = "DP Server changed" + "   " + (Get-Date).ToString("yy-MM-dd HH:mm")
					Out-File $LogFile -Append -InputObject $text
					
					$ServerName = $ServerName + " Changed from $RegServerName"
					Reg add "HKLM\Software\Cygate" /V "DistributionPoint" /T REG_SZ /D "$ServerName" /F
					$tsenv.Value("OSDDistributionPoint") = $ServerName
				}
				break
			}
		}
	}
}

