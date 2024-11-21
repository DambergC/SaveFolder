# Nicklas Ahlberg, Cygate AB

$SiteCode = "TEN"
$ProviderMachineName = "TEN-SCCM01.inside.ten.int"
$tsPath = 'c:\temp\tsts1.xml'
$logPath = 'C:\temp\tsts1.txt'
$taskSequenceName = "Windows Installation for TEN"

$initParams = @{ }


# Import the ConfigurationManager.psd1 module 
if ((Get-Module ConfigurationManager) -eq $null)
{
	Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" @initParams
}

# Connect to the site's drive if it is not already present
if ((Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue) -eq $null)
{
	New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $ProviderMachineName @initParams
}

# Set the current location to be the site code.
Set-Location "$($SiteCode):\" @initParams

(Get-CMTaskSequence | Where-Object { $_.Name -eq $taskSequenceName }).Sequence | Out-File $tsPath

# Load task sequence.xml
[xml]$Xml = Get-Content -Path $tsPath

# Export applications to .txt-file
$tsApps = $Xml.sequence.group | where { $_.name -match 'Applications' } | Select-Object -ExpandProperty step | Select-Object name
$tsApps = $tsApps | where { $_.name -match "install" -and $_.name -notmatch "branding" } | Select-Object -ExpandProperty Name
$tsapps = $tsApps -replace "Install ", ""
$tsApps | Sort-Object | Out-File -FilePath $logPath