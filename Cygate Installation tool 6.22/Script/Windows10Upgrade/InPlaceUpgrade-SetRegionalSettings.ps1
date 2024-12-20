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
if ($RunningInTs)
{
	try
	{
		# Hide the progress dialog
		$TSProgressUI = new-object -comobject Microsoft.SMS.TSProgressUI
		$TSProgressUI.CloseProgressDialog()
	}
	catch { }
}
function global:Write-Log ($text)
{
	$LogPath = "$env:windir\Logs\Software"; If (!(Test-Path "$LogPath")) { New-Item -Path "$LogPath" -ItemType dir -Force }
	$LogFile = "$LogPath\WindowsUpgrade.log"
	(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName $text" | Out-File -FilePath $LogFile -Append
}
function Mount-ISO ($Image)
{
	if (Test-Path "$Image")
	{
		Write-Log "Start dismounting image if mounted"
		try
		{
			Dismount-ISO -Image $Image
			Write-Log "ISO: $Image dismounted"
		}
		catch { Write-Log "Could not dismount $Image, probably not mounted" }
		
		try
		{
			$MountResult = Mount-DiskImage -ImagePath "$Image" -StorageType ISO -PassThru -ErrorAction Stop
			Start-Sleep -Seconds 10
			$DriveLetter = ($MountResult | Get-Volume).DriveLetter
			if ($DriveLetter.count -gt 1) { $DriveLetter = $DriveLetter | Select-Object -First }
			if ($DriveLetter -ne $null) { $DriveLetterFixed = $DriveLetter + ":" }
			Write-Log "Mount-ISO Result, Attached:   $($MountResult.Attached)"
			Write-Log "Mount-ISO Result, DevicePath: $($MountResult.DevicePath)"
			Write-Log "Mount-ISO Result, ImagePath:  $($MountResult.ImagePath)"
			Write-Log "Mount-ISO Result, Size:       $($MountResult.Size)"
			$MountResult = $true
		}
		catch [System.Exception] { $Message = $_.Exception.Message; Write-Log "Mount-ISO: Error - failed to mount ISO: $Image with error message: $Message"; $MountResult = $false }
	}
	else { $MountResult = $false }
	
	if ($MountResult -eq $false)
	{
		# Try mounting using ImDisk tool
		$ParentDirectory = (Get-Item $PSScriptRoot).parent.parent.FullName
		if (Test-Path "$ParentDirectory\Tools\ImDisk\install.bat")
		{
			
			# Install Driver
			try
			{
				$Process = Start-Process -FilePath "$PSScriptRoot\install.bat" -ArgumentList "/fullsilent /lang:english /installfolder:`"${env:ProgramFiles(x86)}\ImDisk`" >> $env:windir\Logs\Software\ImDisk_Install.log 2>&1" -Wait -PassThru -WindowStyle Hidden -ErrorAction Stop
				$ErrorCode = $Process.ExitCode
				Write-Log "ImDisk drivers installed with exit code: $ErrorCode"
			}
			catch { Write-Log "Error installing ImDisk driver" }
			
			# Remove desktop shortcuts
			Remove-Item -Path "$env:USERPROFILE\Desktop\ImDisk*.*"
			Remove-Item -Path "$env:USERPROFILE\Desktop\Mount Image File*.*"
			Remove-Item -Path "$env:USERPROFILE\Desktop\RamDisk Configuration*.*"
			
			# Mount ISO
			if (Test-Path "${env:ProgramFiles(x86)}\ImDisk\MountImg.exe")
			{
				Try
				{
					Write-Log "Try mounting ISO using ImDisk tool"
					$Process = Start-Process -FilePath "${env:ProgramFiles(x86)}\ImDisk\MountImg.exe" -ArgumentList "`"$Image`" /MOUNT" -NoNewWindow -ErrorAction Stop
					$ErrorCode = $Process.ExitCode
				}
				catch { Write-Log "Error mounting ISO using ImDisk tool" }
				Start-Sleep -Seconds 10
			}
			else { Write-Log "Error: ${env:ProgramFiles(x86)}\ImDisk\MountImg.exe" }
			
			# Get mounted drive letter
			$DriveLetters = @("D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P")
			foreach ($DriveLetter in $DriveLetters)
			{
				$Path = $DriveLetter + ":\sources\install.wim"
				if (Test-Path "$Path") { $MountResult = $true; Write-Log "Mounted ISO connected to drive letter: $DriveLetter"; break }
			}
			if ($DriveLetter -like "*:*") { $DriveLetterFixed = $DriveLetter }
			else { $DriveLetterFixed = $DriveLetter + ":" }
		}
		else { Write-Log "Error: ImDisk tool not found - skipping" }
	}
	
	if ($MountResult -eq $false)
	{
		Write-Log "Mounting ISO did not succeed, trying fix disk problems before retry mount"
		# Try running chdksk and sfc to correct problem
		try
		{
			Write-Log "Running chkdsk /f"
			$Process = Start-Process -FilePath "chkdsk.exe" -ArgumentList "/f" -NoNewWindow -Wait -PassThru -ErrorAction Stop
			$ErrorCode = $Process.ExitCode
			Write-Log "chkdsk /f run with exit code: $ErrorCode"
		}
		catch { Write-Log "Error running chkdsk /f" }
		
		try
		{
			Write-Log "Running sfc /scannow"
			$Process = Start-Process -FilePath "sfc.exe" -ArgumentList "/scannow" -NoNewWindow -Wait -PassThru -ErrorAction Stop
			$ErrorCode = $Process.ExitCode
			Write-Log "sfc /scannow run with exit code: $ErrorCode"
		}
		catch { Write-Log "Error running sfc /scannow" }
		
		# Retry mounting ISO
		try
		{
			$MountResult = Mount-DiskImage -ImagePath "$Image" -StorageType ISO -PassThru -ErrorAction Stop
			Start-Sleep -Seconds 10
			$DriveLetter = ($MountResult | Get-Volume).DriveLetter
			if ($DriveLetter.count -gt 1) { $DriveLetter = $DriveLetter | Select-Object -First }
			if ($DriveLetter -ne $null) { $DriveLetterFixed = $DriveLetter + ":" }
			Write-Log "Mount-ISO Result, Attached:   $($MountResult.Attached)"
			Write-Log "Mount-ISO Result, DevicePath: $($MountResult.DevicePath)"
			Write-Log "Mount-ISO Result, ImagePath:  $($MountResult.ImagePath)"
			Write-Log "Mount-ISO Result, Size:       $($MountResult.Size)"
			$MountResult = $true
		}
		catch [System.Exception] { $Message = $_.Exception.Message; Write-Log "Mount-ISO: Error - failed to mount ISO: $Image with error message: $Message"; $MountResult = $false }
	}
	return $DriveLetterFixed, $MountResult
}
function Dismount-ISO ($Image)
{
	try
	{
		$DismountResult = Dismount-DiskImage -ImagePath "$Image"
	}
	catch { }
	
	# Uninstall driver (will also unmount)
	$ParentDirectory = (Get-Item $PSScriptRoot).parent.parent.FullName
	if (Test-Path "$ParentDirectory\Tools\ImDisk\install.bat")
	{
		try
		{
			$Process = Start-Process -FilePath "$ParentDirectory\Tools\ImDisk\install.bat" -ArgumentList "/silentuninstall" -Wait -PassThru -WindowStyle Hidden -ErrorAction Stop
			$ErrorCode = $Process.ExitCode
			Write-Log "ImDisk drivers uninstalled with exit code: $ErrorCode"
		}
		catch { Write-Log "Error uninstalling ImDisk driver" }
	}
	return
}
function Get-LanguageFromCode ($Code)
{
	switch ($Code)
	{
		"0416" { $Lang = 'pt-BR' }
		"0402" { $Lang = 'bg-BG' }
		"0004" { $Lang = 'zh-CN' }
		"7C04" { $Lang = 'zh-TW' }
		"041a" { $Lang = 'hr-HR' }
		"0405" { $Lang = 'cs-CZ' }
		"0406" { $Lang = 'da-DK' }
		"0413" { $Lang = 'nl-NL' }
		"0409" { $Lang = 'en-US' }
		"0425" { $Lang = 'et-EE' }
		"040b" { $Lang = 'fi-FI' }
		"040c" { $Lang = 'fr-FR' }
		"0c0c" { $Lang = 'fr-CA' }
		"0407" { $Lang = 'de-DE' }
		"0408" { $Lang = 'el-GR' }
		"040d" { $Lang = 'he-IL' }
		"040e" { $Lang = 'hu-HU' }
		"0410" { $Lang = 'it-IT' }
		"0411" { $Lang = 'ja-JP' }
		"0412" { $Lang = 'ko-KR' }
		"0426" { $Lang = 'lv-LV' }
		"0427" { $Lang = 'lt-LT' }
		"0414" { $Lang = 'nb-NO' }
		"0415" { $Lang = 'pl-PL' }
		"0816" { $Lang = 'pt-PT' }
		"0418" { $Lang = 'ro-RO' }
		"0419" { $Lang = 'ru-RU' }
		"081a" { $Lang = 'sr-Latn-CS' }
		"041b" { $Lang = 'sk-SK' }
		"0424" { $Lang = 'sl-SI' }
		"0c0a" { $Lang = 'es-ES' }
		"041d" { $Lang = 'sv-SE' }
		"041e" { $Lang = 'th-TH' }
		"041f" { $Lang = 'tr-TR' }
		"0422" { $Lang = 'uk-UA' }
	}
	return $Lang
}
#endregion Main Function

# Prepare for Logging
Write-Log " "
Write-Log "Set Regional Settings"

[array]$SubsitudeValues = @()
[array]$KeyboardLayouts = @()
[array]$InputLocale = @()
[array]$AddKeyboardLayouts = @()
[array]$RemoveKeyboardLayouts = @()
[String]$ScriptPath = split-path $SCRIPT:MyInvocation.MyCommand.Path -parent
[String]$XMLFile = "$env:windir\temp\intlcfgposh1.xml"
[Array]$OSDInputLocale = @() # Default Value which will be overruled if Variable OSDInputLocale is defined in Task Sequence
[String]$OSDUILanguage = "" # Default Value which will be overruled if Variable OSDUILanguage is defined in Task Sequence
[String]$OSDDefaultUILanguage = "" # Default Value which will be overruled if Variable OSDDefaultUILanguage is defined in Task Sequence
[String]$OSDUserLocale = "" # Default Value which will be overruled if Variable OSDUserLocale is defined in Task Sequence
[String]$OSDSystemLocale = "" # Default Value which will be overruled if Variable OSDInputLocale is defined in Task Sequence
[String]$OSDGeoID = "" # Default Value which will be overruled if Variable OSDGeoID is defined in Task Sequence
[Boolean]$PreLoad = $False
[Boolean]$TasksCompleted = $False

#Check for Task Sequence Provided Variables
If($RunningInTs)
{
    If($tsenv.Value("OSDInputLocale"))
    {
        $OSDInputLocale = $tsenv.Value("OSDInputLocale")
		Write-Log "Variable OSDInputLocale found: OSDInputLocale will use value $OSDInputLocale"
    }
    If($tsenv.Value("OSDUILanguage"))
    {   # Classic fresh Baremetal deployment scenario
        $OSDUILanguage = $tsenv.Value("OSDUILanguage")
		Write-Log "Variable OSDUILanguage found: OSDUILanguage will use value $OSDUILanguage"
    }
    If($tsenv.Value("CurrentOSLanguage"))
    {   # Variable set via OSDDetectInstalledLP.ps1 Script - In-Place Upgrade scenario
        $OSDUILanguage = $tsenv.Value("CurrentOSLanguage")
		Write-Log "Variable CurrentOSLanguage found: OSDUILanguage will use value $OSDUILanguage"
    }
    If($tsenv.Value("OSDDefaultUILanguage"))
    {   # Variable which allows a general override to define default UI Language for all users
        $OSDUILanguage = $tsenv.Value("OSDDefaultUILanguage")
		Write-Log "Variable OSDDefaultUILanguage found: OSDUILanguage will use value $OSDUILanguage"
    }
    If($tsenv.Value("OSDUserLocale"))
    {
        $OSDUserLocale = $tsenv.Value("OSDUserLocale")
		Write-Log "Variable OSDUserLocale found: OSDUserLocale will use value $OSDUserLocale"
    }
    If($tsenv.Value("OSDSystemLocale"))
    {
        $OSDSystemLocale = $tsenv.Value("OSDSystemLocale")
		Write-Log "Variable OSDSystemLocale found: OSDSystemLocale will use value $OSDSystemLocale"
    }
    If($tsenv.Value("OSDInputLocale"))
    {
        $OSDInputLocale = $tsenv.Value("OSDInputLocale")
		Write-Log "Variable OSDInputLocale found: OSDInputLocale will use value $OSDInputLocale"
    }
    If($tsenv.Value("OSDGeoID"))
    {
        $OSDGeoID = $tsenv.Value("OSDGeoID")
		Write-Log "Variable OSDGeoID found: OSDGeoID will use value $OSDGeoID"
    }
}
 
#Remove possible spaces
$OSDInputLocale = $OSDInputLocale.Replace(" ", "")
#Just in case if ; is used as seperator
$OSDInputLocale = $OSDInputLocale.Replace(";", ",")
$InputLocale = $OSDInputLocale -split ","
 
# Memorize current PS-Drive
Push-Location
# Create a new drive to easily access HKU
If(-not(Test-Path HKU:))
{
	Write-Log "PSDrive HKU: not found creating it"
    New-PSDrive -Name HKU -PSProvider Registry -Root HKEY_USERS
}
 
Set-Location 'HKU:\.DEFAULT\Keyboard Layout\Substitutes'
$SubsitudeValues = Get-Item . |
Select-Object -ExpandProperty property |
ForEach-Object{New-Object psobject -Property @{"Name"=$_;
   "Value" = (Get-ItemProperty -Path . -Name $_).$_}} 
# Get back to PS-Drive we started from
Pop-Location
 
 
# Verify if Substitudes has a value
If($SubsitudeValues.Count -eq 0)
{
	Write-Log "HKU:\.DEFAULT\Keyboard Layout\Substitutes was empty use HKU:\.DEFAULT\Keyboard Layout\Preload"
    Set-Location 'HKU:\.DEFAULT\Keyboard Layout\Preload'
    $SubsitudeValues = Get-Item . |
    Select-Object -ExpandProperty property |
    ForEach-Object{New-Object psobject -Property @{"Name"=$_;
       "Value" = (Get-ItemProperty -Path . -Name $_).$_}}
    $PreLoad = $True 
    # Get back to PS-Drive we started from
    Pop-Location
}
 
$i = 0
Write-Log "Create Keyboard Layout values detected"
ForEach($Subsitude in $SubsitudeValues)
{
    If($Preload)
    {
        $KeyBoardLayout = $Subsitude.Value.substring($Subsitude.Value.length - 4, 4)
        $KeyBoardLayout = $KeyBoardLayout+":"+$Subsitude.Value
        $KeyboardLayouts = $KeyboardLayouts + $KeyboardLayout
    }
    Else
    {
        $KeyBoardLayout = $Subsitude.Name.substring($Subsitude.Name.length - 4, 4)
        $KeyBoardLayout = $KeyBoardLayout+":"+$Subsitude.Value
        $KeyboardLayouts = $KeyboardLayouts + $KeyboardLayout
    }
	Write-Log "Keyboard Layout: $KeyBoardLayout"
    $i = $i + 1 
}
 
# Compare Keyboard Layouts existing on the current system to layouts provided via OSDInputLocale Variable
Write-Log "Compare detected keyboard layouts with layouts set via OSDInputLocale"
$CompareSetToIs = Compare-Object -ReferenceObject ($InputLocale) -DifferenceObject ($KeyboardLayouts) -IncludeEqual
ForEach($Compare in $CompareSetToIs)
{
    $KeyboardComparison = $Compare.InputObject
    If($Compare.SideIndicator -eq "==")
    {
        $AddKeyboardLayouts = $AddKeyboardLayouts + $KeyboardComparison
		Write-Log "$KeyboardComparison already on System. Keyboard Layout will be InputLanguageID Action=`"add`""
    }
    If($Compare.SideIndicator -eq "=>")
    {
        $RemoveKeyboardLayouts = $RemoveKeyboardLayouts + $KeyboardComparison
		Write-Log "$KeyboardComparison already on System, but not part of OSDInputLocale. Keyboard Layout will be InputLanguageID Action=`"remove`""
    }
    If($Compare.SideIndicator -eq "<=")
    {
        $AddKeyboardLayouts = $AddKeyboardLayouts + $KeyboardComparison
		Write-Log "$KeyboardComparison is not present on System. Keyboard Layout will be InputLanguageID Action=`"add`""
    }
}

$DefaultLanguage = $tsenv.Value("OSDDefaultLanguage")
Write-Log "Importing DefaultLanguage: $DefaultLanguage"
REG ADD "HKLM\System\CurrentControlSet\Control\Nls\Language" /V "InstallLanguage" /T REG_SZ /D "$DefaultLanguage" /F

Start-Sleep 15

Write-Log "Command completed check eventlog for possible errors (Microsoft-Windows-International/Operational)"
Write-Log "Run Set-WinUILanguageOverride to enable $OSDUILanguage on Logon Screen"
Set-WinUILanguageOverride $OSDUILanguage
Write-Log "Script execution completed"
