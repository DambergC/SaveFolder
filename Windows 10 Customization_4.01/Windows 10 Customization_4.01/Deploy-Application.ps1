<#
.SYNOPSIS
	This script performs the installation or uninstallation of an application(s).
	# LICENSE #
	PowerShell App Deployment Toolkit - Provides a set of functions to perform common application deployment tasks on Windows.
	Copyright (C) 2017 - Sean Lillis, Dan Cunningham, Muhammad Mashwani, Aman Motazedian.
	This program is free software: you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the Free Software Foundation, either version 3 of the License, or any later version. This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
	You should have received a copy of the GNU Lesser General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.
.DESCRIPTION
	The script is provided as a template to perform an install or uninstall of an application(s).
	The script either performs an "Install" deployment type or an "Uninstall" deployment type.
	The install deployment type is broken down into 3 main sections/phases: Pre-Install, Install, and Post-Install.
	The script dot-sources the AppDeployToolkitMain.ps1 script which contains the logic and functions required to install or uninstall an application.
.PARAMETER DeploymentType
	The type of deployment to perform. Default is: Install.
.PARAMETER DeployMode
	Specifies whether the installation should be run in Interactive, Silent, or NonInteractive mode. Default is: Interactive. Options: Interactive = Shows dialogs, Silent = No dialogs, NonInteractive = Very silent, i.e. no blocking apps. NonInteractive mode is automatically set if it is detected that the process is not user interactive.
.PARAMETER AllowRebootPassThru
	Allows the 3010 return code (requires restart) to be passed back to the parent process (e.g. SCCM) if detected from an installation. If 3010 is passed back to SCCM, a reboot prompt will be triggered.
.PARAMETER TerminalServerMode
	Changes to "user install mode" and back to "user execute mode" for installing/uninstalling applications for Remote Destkop Session Hosts/Citrix servers.
.PARAMETER DisableLogging
	Disables logging to file for the script. Default is: $false.
.EXAMPLE
    powershell.exe -Command "& { & '.\Deploy-Application.ps1' -DeployMode 'Silent'; Exit $LastExitCode }"
.EXAMPLE
    powershell.exe -Command "& { & '.\Deploy-Application.ps1' -AllowRebootPassThru; Exit $LastExitCode }"
.EXAMPLE
    powershell.exe -Command "& { & '.\Deploy-Application.ps1' -DeploymentType 'Uninstall'; Exit $LastExitCode }"
.EXAMPLE
    Deploy-Application.exe -DeploymentType "Install" -DeployMode "Silent"
.NOTES
	Toolkit Exit Code Ranges:
	60000 - 68999: Reserved for built-in exit codes in Deploy-Application.ps1, Deploy-Application.exe, and AppDeployToolkitMain.ps1
	69000 - 69999: Recommended for user customized exit codes in Deploy-Application.ps1
	70000 - 79999: Recommended for user customized exit codes in AppDeployToolkitExtensions.ps1
.LINK
	http://psappdeploytoolkit.com
#>
[CmdletBinding()]
Param (
	[Parameter(Mandatory=$false)]
	[ValidateSet('Install','Uninstall','Repair')]
	[string]$DeploymentType = 'Install',
	[Parameter(Mandatory=$false)]
	[ValidateSet('Interactive','Silent','NonInteractive')]
	[string]$DeployMode = 'Interactive',
	[Parameter(Mandatory=$false)]
	[switch]$AllowRebootPassThru = $false,
	[Parameter(Mandatory=$false)]
	[switch]$TerminalServerMode = $false,
	[Parameter(Mandatory=$false)]
	[switch]$DisableLogging = $false,
	[switch]$Retry = $false # On 1803 and 1809 the removal of appx packages hangs causing the script to exit and fail - introducing retry step in TS to run second time if failed
)

Try {
	## Set the script execution policy for this process
	Try { Set-ExecutionPolicy -ExecutionPolicy 'ByPass' -Scope 'Process' -Force -ErrorAction 'Stop' } Catch {}

	##*===============================================
	##* VARIABLE DECLARATION
	##*===============================================
	## Variables: Application
	[string]$appVendor = 'Cygate'
	[string]$appName = 'Windows 10 Customization'
	[string]$appVersion = '4.01'
	[string]$appArch = ''
	[string]$appLang = 'EN'
	[string]$appRevision = '01'
	[string]$appScriptVersion = '1.0.0'
	[string]$appScriptDate = '20210608'
	[string]$appScriptAuthor = 'Ulf Säfstrand, Cygate'
	[string]$appRegDisplayName = "$appName"
	[string]$ApplicationsToClose = 'dummy' # process name WITHOUT .exe extension
	[string]$AppRegName = $appName
	[switch]$AllowUserWebAssociationChange = $false # When true, the association file will not contain IE settings leaving them open to change for users
	##*===============================================
	## Variables: Install Titles (Only set here to override defaults set by the toolkit)
	[string]$installName = ''
	[string]$installTitle = ''

	##* Do not modify section below
	#region DoNotModify

	## Variables: Exit Code
	[int32]$mainExitCode = 0

	## Variables: Script
	[string]$deployAppScriptFriendlyName = 'Deploy Application'
	[version]$deployAppScriptVersion = [version]'3.8.4'
	[string]$deployAppScriptDate = '26/01/2021'
	[hashtable]$deployAppScriptParameters = $psBoundParameters

	## Variables: Environment
	If (Test-Path -LiteralPath 'variable:HostInvocation') { $InvocationInfo = $HostInvocation } Else { $InvocationInfo = $MyInvocation }
	[string]$scriptDirectory = Split-Path -Path $InvocationInfo.MyCommand.Definition -Parent

	## Dot source the required App Deploy Toolkit Functions
	Try {
		[string]$moduleAppDeployToolkitMain = "$scriptDirectory\AppDeployToolkit\AppDeployToolkitMain.ps1"
		If (-not (Test-Path -LiteralPath $moduleAppDeployToolkitMain -PathType 'Leaf')) { Throw "Module does not exist at the specified location [$moduleAppDeployToolkitMain]." }
		If ($DisableLogging) { . $moduleAppDeployToolkitMain -DisableLogging } Else { . $moduleAppDeployToolkitMain }
	}
	Catch {
		If ($mainExitCode -eq 0){ [int32]$mainExitCode = 60008 }
		Write-Error -Message "Module [$moduleAppDeployToolkitMain] failed to load: `n$($_.Exception.Message)`n `n$($_.InvocationInfo.PositionMessage)" -ErrorAction 'Continue'
		## Exit the script, returning the exit code to SCCM
		If (Test-Path -LiteralPath 'variable:HostInvocation') { $script:ExitCode = $mainExitCode; Exit } Else { Exit $mainExitCode }
	}

	#endregion
	##* Do not modify section above
	##*===============================================
	##* END VARIABLE DECLARATION
	##*===============================================

	If ($deploymentType -ine 'Uninstall' -and $deploymentType -ine 'Repair') {
		##*===============================================
		##* PRE-INSTALLATION
		##*===============================================
		[string]$installPhase = 'Pre-Installation'
		
		# Check if application already is installed, then exit
		if ((Get-InstalledApplication -Name "$appRegDisplayName*" -WildCard) -eq $null)
		{
			Write-Log "Application not installed, installing..."
		}
		Else
		{
			# Get Application Version
			Write-Log "Application installed, version to be checked"
			$ApplicationVersion = Get-InstalledApplication -Name "$appRegDisplayName*" -WildCard | Select DisplayVersion -ExpandProperty DisplayVersion
			
			if (($ApplicationVersion -ne $null) -and ($ApplicationVersion.length -gt 0))
			{
				
				# Check if multiple variables
				if ($ApplicationVersion -is [System.Array])
				{
					Write-Log "Version variable contains multiple variables (Array)"
					# $ApplicationVersion = $ApplicationVersion[0]
					
					# Get highest value from array
					$ApplicationVersion = ($ApplicationVersion | Measure -Max).Maximum
				}
				
				# Check if version string is correctly formatted eg. 0.0.0 includes at least one dot and no letters
				$charDotOK = 0
				$charLetterOK = 1
				$Count = 0
				
				Do
				{
					$char = $ApplicationVersion.Substring($Count, 1)
					# Check for other than numbers and dots
					if (([int][char]$char -gt 57) -or ([int][char]$char -lt 48))
					{
						if ([int][char]$char -eq 46)
						{
							$charDotOK = 1
						}
						else
						{
							$charLetterOK = 0
						}
					}
					$Count = $Count + 1
				}
				While ($Count -lt $ApplicationVersion.Length)
				
				
				if (($ApplicationVersion.IndexOf(" ") -ne $null) -and ($ApplicationVersion.IndexOf(" ") -ge 0))
				{
					$pos = $ApplicationVersion.IndexOf(" ")
					$ApplicationVersion = $ApplicationVersion.Substring(0, $pos)
				}
				
				Write-Log ("Application Version installed: " + $ApplicationVersion)
				if (($charDotOK -eq 1) -and ($charLetterOK -eq 1))
				{
					try
					{
						if ([version]"$ApplicationVersion" -lt [Version]"$appVersion") { Write-Log "Application version to low, upgrading...." }
						else { Write-Log "Application with this version (or higher) already installed, exiting..."; Set-RegistryKey -Key "HKLM:\SOFTWARE\Cygate\Detection\$AppRegName" -Name 'Version' -Type 'String' -Value "$appVersion"; Exit-Script -ExitCode 0 }
					}
					catch
					{
						if ($ApplicationVersion -lt $appVersion) { Write-Log "Application version to low, upgrading...." }
						else { Write-Log "Application with this version (or higher) already installed, exiting..."; Set-RegistryKey -Key "HKLM:\SOFTWARE\Cygate\Detection\$AppRegName" -Name 'Version' -Type 'String' -Value "$appVersion"; Exit-Script -ExitCode 0 }
					}
				}
				
				if (($charDotOK -eq 0) -or ($charLetterOK -eq 0))
				{
					if ($ApplicationVersion -lt $appVersion)
					{
						Write-Log "Application version to low, upgrading...."
					}
					else
					{
						Write-Log "Application with this version (or higher) already installed, exiting..."
						Set-RegistryKey -Key "HKLM:\SOFTWARE\Cygate\Detection\$AppRegName" -Name 'Version' -Type 'String' -Value "$appVersion"
						Exit-Script -ExitCode 0
					}
				}
			}
		}

		## Show Welcome Message, close Internet Explorer if required, allow up to 3 deferrals, verify there is enough disk space to complete the install, and persist the prompt
		Show-InstallationWelcome -CloseApps "$ApplicationsToClose" -AllowDefer -DeferTimes 3 -CheckDiskSpace -PersistPrompt

		## Show Progress Message (with the default message)
		Show-InstallationProgress
		
		## <Perform Pre-Installation tasks here>
		
		try
		{
			$tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment
			$RunningInTs = $True
			if ($($tsenv.Value("OSDTSType")) -ne $null)	{ $TSType = $tsenv.Value("OSDTSType")}
			Write-Log "$appRegDisplayName is Running in TS"
			if ($tsenv.Value("_SMSTSLastActionSucceeded") -eq $false)
			{
				Write-Log "_SMSTSLastActionSucceeded is found false, last TS step was failing"
				$Retry = $true
			}
		}
		Catch
		{
			$RunningInTs = $false
			Write-Log "$appRegDisplayName is NOT Running in TS"
		}


		##*===============================================
		##* INSTALLATION
		##*===============================================
		[string]$installPhase = 'Installation'

		## <Perform Installation tasks here>
		
		if ($Retry -eq $false)
		{
			Write-Log "Retry variable is false, running full script"
			
			# Get bitness for Office
			try { $bitness = (get-itemproperty HKLM:\Software\Microsoft\Office\14.0\Outlook -name Bitness).Bitness }
			catch { }
			try { if ($bitness -eq $null) { $bitness = (get-itemproperty HKLM:\Software\Microsoft\Office\15.0\Outlook -name Bitness).Bitness } }
			catch { }
			try { if ($bitness -eq $null) { $bitness = (get-itemproperty HKLM:\Software\Microsoft\Office\16.0\Outlook -name Bitness).Bitness } }
			catch { }
			try { if ($bitness -eq $null) { $bitness = (get-itemproperty HKLM:\SOFTWARE\WOW6432Node\Microsoft\Office\14.0\Outlook -name Bitness).Bitness } }
			catch { }
			try { if ($bitness -eq $null) { $bitness = (get-itemproperty HKLM:\SOFTWARE\WOW6432Node\Microsoft\Office\15.0\Outlook -name Bitness).Bitness } }
			catch { }
			try { if ($bitness -eq $null) { $bitness = (get-itemproperty HKLM:\SOFTWARE\WOW6432Node\Microsoft\Office\16.0\Outlook -name Bitness).Bitness } }
			catch { }
			
			if ($bitness -ne $null) { Write-Log "Outlook bitness found to be: $bitness" }
			else { Write-Log "Outlook bitness NOT found, Office assumed not installed" }
			If ($bitness -like "*64*") { $ProgramFiles = $env:ProgramFiles }
			Else { $ProgramFiles = ${env:ProgramFiles(x86)} }
			
			#  Disable User First Sign-in Animation
			Write-Log "Disable User First Sign-in Animation"
			New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name 'EnableFirstLogonAnimation' -Value '0' -PropertyType DWORD -Force | Out-Null
			
			# Create shortcut for Internet Explorer and Lync (contains swedish characters in name) to work with start menu layout
			Write-Log "Create shortcut for Internet Explorer and Lync"
			$WebBrowserLinkFound = $false
			if (Test-Path -Path "${env:ProgramFiles(x86)}\Internet Explorer\iexplore.exe")
			{
				$WebBrowserLinkFound = $true
				Write-Log "Internet Explorer executable found, creating shortcut"
				$AppLocation = "${env:ProgramFiles(x86)}\Internet Explorer\iexplore.exe"
				$WshShell = New-Object -ComObject WScript.Shell
				$Shortcut = $WshShell.CreateShortcut("$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Accessories\Internet Explorer.lnk")
				$Shortcut.TargetPath = $AppLocation
				$Shortcut.Arguments = ""
				$Shortcut.IconLocation = "${env:ProgramFiles(x86)}\Internet Explorer\iexplore.exe,0"
				$Shortcut.Description = "Finds and displays information and Web sites on the Internet."
				$Shortcut.Save()
				Start-Sleep -Seconds 5
			}
			else { Write-Log "Internet Explorer executable NOT found, will not create shortcut" }
			
			# Check if Edge Chromium is installed
			$EdgeChromiumInstalled = $false
			if ((Get-InstalledApplication -Name "Microsoft Edge" -Exact) -ne $null) { $EdgeChromiumInstalled = $true }
			
			$OfficeVersion = "NoOffice"
			$LyncInstalled = $false
			
			# Check Add/Remove Programs for Office version
			Write-Log "Check Add/Remove Programs for Office version"
			if (Get-InstalledApplication -Name "*Office Standard 2019*" -WildCard)
			{
				Write-Log "Office 2019 Standard found"
				$OfficeVersion = "2019"
				$OfficeSubVersion = "Standard"
			}
			if (Get-InstalledApplication -Name "*Office Professional Plus 2019*" -WildCard)
			{
				Write-Log "Office 2019 Professional Plus found"
				$OfficeVersion = "2019"
				$OfficeSubVersion = "ProPlus"
			}
			if (Get-InstalledApplication -Name "*Office Standard 2016*" -WildCard)
			{
				Write-Log "Office 2016 Standard found"
				$OfficeVersion = "2016"
				$OfficeSubVersion = "Standard"
			}
			if (Get-InstalledApplication -Name "*Office Professional Plus 2016*" -WildCard)
			{
				Write-Log "Office 2016 Professional Plus found"
				$OfficeVersion = "2016"
				$OfficeSubVersion = "ProPlus"
			}
			
			if (Test-Path "$ProgramFiles\Microsoft Office\root\Office16\winword.exe")
			{
				Write-Log "Office 365 Found"
				$OfficeVersion = "365"
				if (Test-Path "$ProgramFiles\Microsoft Office\root\Office16\lync.exe")
				{
					Write-Log "Skype executable found: $ProgramFiles\Microsoft Office\root\Office16\lync.exe"
					
					Write-Log "Getting path for Skype icon"
					try { $SkypeIconPath = (Get-ChildItem "$ProgramFiles\lyncicon.exe" -recurse -ErrorAction SilentlyContinue).Fullname; Write-Log "Skype icon path: $SkypeIconPath" }
					catch { Write-Log "Failed to find Skype Icon Path" }
					
					$LyncInstalled = $true
					Write-Log "Creating Skype shortcut: $ProgramFiles\Microsoft Office\root\Office16\Skype for Business.lnk"
					$AppLocation = "$ProgramFiles\Microsoft Office\root\Office16\lync.exe"
					$WshShell = New-Object -ComObject WScript.Shell
					$Shortcut = $WshShell.CreateShortcut("$ProgramFiles\Microsoft Office\root\Office16\Skype for Business.lnk")
					$Shortcut.TargetPath = $AppLocation
					$Shortcut.Arguments = ""
					$Shortcut.IconLocation = "$SkypeIconPath,0"
					$Shortcut.Description = ""
					$Shortcut.Save()
				}
				else { Write-Log "Skype executable not found - will not create shortcut" }
			}
			if (Test-Path "$ProgramFiles\Microsoft Office\Office16\winword.exe")
			{
				Write-Log "Office 2016 MSI found"
				if (Test-Path "$ProgramFiles\Microsoft Office\Office16\lync.exe")
				{
					Write-Log "Office 2016 Pro Plus found, Skype link: $ProgramFiles\Microsoft Office\Office16\lync.exe"
					$LyncInstalled = $true
					$AppLocation = "$ProgramFiles\Microsoft Office\Office16\lync.exe"
					$WshShell = New-Object -ComObject WScript.Shell
					$Shortcut = $WshShell.CreateShortcut("$ProgramFiles\Microsoft Office\Office16\Skype for Business.lnk")
					$Shortcut.TargetPath = $AppLocation
					$Shortcut.Arguments = ""
					$Shortcut.IconLocation = "$ProgramFiles\Microsoft Office\Office16\lync.exe,0"
					$Shortcut.Description = ""
					$Shortcut.Save()
				}
				else { Write-Log "Skype executable not found - will not create shortcut" }
			}
			
			# Get Office Links
			Write-Log "Getting Office Links"
			$OneNote = "DesktopApp"
			$Exclude = @("Wordpad*.*", "Wordfinder*.*")
			try { $WordLink = ((Get-ChildItem "$env:ALLUSERSPROFILE\Microsoft\Windows\Start Menu\Word*.lnk" -recurse -Exclude $Exclude -ErrorAction SilentlyContinue).Fullname).Replace("C:\ProgramData", "%ALLUSERSPROFILE%"); Write-Log "Word Link: $WordLink"; $WordInstalled = $true }
			catch { Write-Log "Failed to find Word Link"; $WordInstalled = $false }
			try { $ExcelLink = ((Get-ChildItem "$env:ALLUSERSPROFILE\Microsoft\Windows\Start Menu\Excel*.lnk" -recurse -ErrorAction SilentlyContinue).Fullname).Replace("C:\ProgramData", "%ALLUSERSPROFILE%"); Write-Log "Excel Link: $ExcelLink"; $ExcelInstalled = $true }
			catch { Write-Log "Failed to find Excel Link"; $ExcelInstalled = $false }
			try { $OutlookLink = ((Get-ChildItem "$env:ALLUSERSPROFILE\Microsoft\Windows\Start Menu\Outlook*.lnk" -recurse -ErrorAction SilentlyContinue).Fullname).Replace("C:\ProgramData", "%ALLUSERSPROFILE%"); Write-Log "Outlook Link: $OutlookLink"; $OutlookInstalled = $true }
			catch { Write-Log "Failed to find Outlook Link"; $OutlookInstalled = $false }
			try { $PowerPointLink = ((Get-ChildItem "$env:ALLUSERSPROFILE\Microsoft\Windows\Start Menu\PowerPoint*.lnk" -recurse -ErrorAction SilentlyContinue).Fullname).Replace("C:\ProgramData", "%ALLUSERSPROFILE%"); Write-Log "PowerPoint Link: $PowerPointLink"; $PowerpointInstalled = $true }
			catch { Write-Log "Failed to find PowerPoint Link"; $PowerpointInstalled = $false }
			try { $OneNoteLink = ((Get-ChildItem "$env:ALLUSERSPROFILE\Microsoft\Windows\Start Menu\OneNote*.lnk" -recurse -ErrorAction SilentlyContinue).Fullname).Replace("C:\ProgramData", "%ALLUSERSPROFILE%"); Write-Log "OneNote Link (DesktopApp): $OneNoteLink"; $OneNoteInstalled = $true }
			catch
			{
				try
				{
					$OneNoteLink = ((Get-ChildItem "$env:ProgramFiles\WindowsApps\OneNoteim.exe" -recurse -ErrorAction SilentlyContinue).Fullname)
					$OneNote = "AppUserModel"
					Write-Log "OneNote Link (AppUserModel): $OneNoteLink"; $OneNoteInstalled = $true
				}
				catch { Write-Log "Failed to find OneNote Link"; $OneNoteInstalled = $false }
			}
			
			# Get Software Center Link
			Write-Log "Get Software Center Link"
			try
			{
				$SoftwareCenterLink = (Get-ChildItem "$env:ALLUSERSPROFILE\Microsoft\Windows\Start Menu\Software Center*.lnk" -recurse -ErrorAction SilentlyContinue | Where-Object { $_.FullName -notMatch "vfs" }).Fullname
				if ($SoftwareCenterLink -notlike "*Software Center*") { $SoftwareCenterLink = $null; Write-Log "Failed to find Software Center Link" }
				else { Write-Log "Software Center Link: $SoftwareCenterLink" }
			}
			catch { Write-Log "Failed to find Software Center Link"; $SoftwareCenterLink = $null }
			
			try
			{
				Start-Sleep -Seconds 2
				Write-Log "Searching for Skype link in: ${env:ProgramFiles(x86)}\Skype*.lnk"
				$SkypeLink = (Get-ChildItem "${env:ProgramFiles(x86)}\Skype*.lnk" -recurse -ErrorAction SilentlyContinue | Where-Object { $_.FullName -notMatch "vfs" }).Fullname
				if (($SkypeLink -eq $null) -or ($SkypeLink -notlike "*program*"))
				{
					Write-Log "Skype link not found in ${env:ProgramFiles(x86)}\Skype*.lnk, trying $env:ProgramFiles\Skype*.lnk"
					$SkypeLink = (Get-ChildItem "$env:ProgramFiles\Skype*.lnk" -recurse -ErrorAction SilentlyContinue | Where-Object { $_.FullName -notMatch "vfs" }).Fullname
					if ($SkypeLink.Count -gt 1) { $SkypeLink = $SkypeLink | Select-Object -First 1 }
				}
				if ($SkypeLink -notlike "*Skype*") { $SkypeLink = $null; Write-Log "Failed to find Skype Link" }
				else { Write-Log "Skype Link: $SkypeLink" }
			}
			catch { Write-Log "Failed to find Skype Link"; $SkypeLink = $null }
			
			# Check if Internet Explorer is installed
			Write-Log "Check if Internet Explorer is installed"
			if ((Test-Path -Path "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Accessories\Internet Explorer.lnk") -and ($WebBrowserLinkFound = $true))
			{
				$WebBrowserLink = "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Accessories\Internet Explorer.lnk"
				Write-Log "IE link found: $WebBrowserLink"
			}
			elseif (Test-Path -Path "$env:ALLUSERSPROFILE\Microsoft\Windows\Start Menu\Programs\Google Chrome.lnk")
			{
				$WebBrowserLinkFound = $true
				$WebBrowserLink = "$env:ALLUSERSPROFILE\Microsoft\Windows\Start Menu\Programs\Google Chrome.lnk"
				Write-Log "Google Chrome link found: $WebBrowserLink"
			}
			else { Write-Log "No Web Browser link found"; $WebBrowserLinkFound = $false }
			
			# Teams shortcut (Not installed during Office installation - activated when user logged on)
			$TeamsLink = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Microsoft Teams.lnk"
			if ((Test-Path "$env:ProgramFiles\Teams Installer\Teams.exe") -or (Test-Path "${env:ProgramFiles(x86)}\Teams Installer\Teams.exe")) { $TeamsInstalled = $true; Write-Log "Teams Installer found - consider installed" }
			else { $TeamsInstalled = $false; Write-Log "Teams Installer NOT found - consider not installed" }
			
			# Create start menu layout file
			Write-Log "Creating start menu layout file"
			$StartMenuLayoutFile = "$env:windir\StartMenuLayout.xml"
			
			"<?xml version=`"1.0`" encoding=`"utf-8`"?>" | Out-File "$StartMenuLayoutFile" -Force
			"<LayoutModificationTemplate" | Out-File "$StartMenuLayoutFile" -Append
			"    xmlns=`"http://schemas.microsoft.com/Start/2014/LayoutModification`"" | Out-File "$StartMenuLayoutFile" -Append
			"    xmlns:defaultlayout=`"http://schemas.microsoft.com/Start/2014/FullDefaultLayout`"" | Out-File "$StartMenuLayoutFile" -Append
			"    xmlns:start=`"http://schemas.microsoft.com/Start/2014/StartLayout`"" | Out-File "$StartMenuLayoutFile" -Append
			"    xmlns:taskbar=`"http://schemas.microsoft.com/Start/2014/TaskbarLayout`"" | Out-File "$StartMenuLayoutFile" -Append
			"    Version=`"1`">" | Out-File "$StartMenuLayoutFile" -Append
			"<LayoutOptions StartTileGroupsColumnCount=`"1`" />" | Out-File "$StartMenuLayoutFile" -Append
			"  <DefaultLayoutOverride LayoutCustomizationRestrictionType=`"OnlySpecifiedGroups`">" | Out-File "$StartMenuLayoutFile" -Append
			"    <StartLayoutCollection>" | Out-File "$StartMenuLayoutFile" -Append
			"      <defaultlayout:StartLayout GroupCellWidth=`"6`" xmlns:defaultlayout=`"http://schemas.microsoft.com/Start/2014/FullDefaultLayout`">" | Out-File "$StartMenuLayoutFile" -Append
			
			if ($WeatherOnStartMenu -eq $true)
			{
				"        <start:Group Name=`"`" xmlns:start=`"http://schemas.microsoft.com/Start/2014/StartLayout`">" | Out-File "$StartMenuLayoutFile" -Append
				"           <start:Tile Size=`"4x4`" Column=`"0`" Row=`"0`" AppUserModelID=`"Microsoft.BingWeather_8wekyb3d8bbwe!App`" />" | Out-File "$StartMenuLayoutFile" -Append
				"        </start:Group>" | Out-File "$StartMenuLayoutFile" -Append
			}
			
			if ($OfficeVersion -ne "NoOffice")
			{
				"        <start:Group Name=`"Office`" xmlns:start=`"http://schemas.microsoft.com/Start/2014/StartLayout`">" | Out-File "$StartMenuLayoutFile" -Append
				if (($OutlookInstalled -eq $true) -and ($OutlookLink -ne $null)) { "          <start:DesktopApplicationTile Size=`"2x2`" Column=`"0`" Row=`"0`" DesktopApplicationLinkPath=`"$OutlookLink`" />" | Out-File "$StartMenuLayoutFile" -Append }
				if (($LyncInstalled -eq $true) -and ($SkypeLink -ne $null)) { "          <start:DesktopApplicationTile Size=`"2x2`" Column=`"2`" Row=`"0`" DesktopApplicationLinkPath=`"$SkypeLink`" />" | Out-File "$StartMenuLayoutFile" -Append }
				elseif ($TeamsInstalled -eq $true) { "          <start:DesktopApplicationTile Size=`"2x2`" Column=`"2`" Row=`"0`" DesktopApplicationID=`"com.squirrel.Teams.Teams`" />" | Out-File "$StartMenuLayoutFile" -Append }
				if (($WordInstalled -eq $true) -and ($WordLink -ne $null)) { "          <start:DesktopApplicationTile Size=`"1x1`" Column=`"0`" Row=`"2`" DesktopApplicationLinkPath=`"$WordLink`" />" | Out-File "$StartMenuLayoutFile" -Append }
				if (($ExcelInstalled -eq $true) -and ($ExcelLink -ne $null)) { "          <start:DesktopApplicationTile Size=`"1x1`" Column=`"1`" Row=`"2`" DesktopApplicationLinkPath=`"$ExcelLink`" />" | Out-File "$StartMenuLayoutFile" -Append }
				if (($PowerpointInstalled -eq $true) -and ($PowerPointLink -ne $null)) { "          <start:DesktopApplicationTile Size=`"1x1`" Column=`"2`" Row=`"2`" DesktopApplicationLinkPath=`"$PowerPointLink`" />" | Out-File "$StartMenuLayoutFile" -Append }
				if ($OneNote -eq "DesktopApp") { "          <start:DesktopApplicationTile Size=`"1x1`" Column=`"3`" Row=`"2`" DesktopApplicationLinkPath=`"$OneNoteLink`" />" | Out-File "$StartMenuLayoutFile" -Append }
				if ($OneNote -eq "AppUserModel") { "          <start:Tile Size=`"1x1`" Column=`"3`" Row=`"2`" AppUserModelID=`"Microsoft.Office.OneNote_8wekyb3d8bbwe!microsoft.onenoteim`" />" | Out-File "$StartMenuLayoutFile" -Append }
				"        </start:Group>" | Out-File "$StartMenuLayoutFile" -Append
			}
			
			"        <start:Group Name=`"Web`" xmlns:start=`"http://schemas.microsoft.com/Start/2014/StartLayout`">" | Out-File "$StartMenuLayoutFile" -Append
			"          <start:Tile Size=`"2x2`" Column=`"2`" Row=`"0`" AppUserModelID=`"Microsoft.MicrosoftEdge_8wekyb3d8bbwe!MicrosoftEdge`" />" | Out-File "$StartMenuLayoutFile" -Append
			if ($WebBrowserLinkFound -eq $true) { "          <start:DesktopApplicationTile Size=`"2x2`" Column=`"0`" Row=`"0`" DesktopApplicationLinkPath=`"$WebBrowserLink`" />" | Out-File "$StartMenuLayoutFile" -Append }
			"        </start:Group>" | Out-File "$StartMenuLayoutFile" -Append
			"        <start:Group Name=`"Tools`">" | Out-File "$StartMenuLayoutFile" -Append
			"          <start:DesktopApplicationTile Size=`"2x2`" Column=`"2`" Row=`"0`" DesktopApplicationLinkPath=`"%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\Accessories\Snipping Tool.lnk`" />" | Out-File "$StartMenuLayoutFile" -Append
			"          <start:DesktopApplicationTile Size=`"2x2`" Column=`"0`" Row=`"0`" DesktopApplicationLinkPath=`"$SoftwareCenterLink`" />" | Out-File "$StartMenuLayoutFile" -Append
			"        </start:Group>" | Out-File "$StartMenuLayoutFile" -Append
			"      </defaultlayout:StartLayout>" | Out-File "$StartMenuLayoutFile" -Append
			"    </StartLayoutCollection>" | Out-File "$StartMenuLayoutFile" -Append
			"  </DefaultLayoutOverride>" | Out-File "$StartMenuLayoutFile" -Append
			"  <CustomTaskbarLayoutCollection PinListPlacement=`"Replace`">" | Out-File "$StartMenuLayoutFile" -Append
			"    <defaultlayout:TaskbarLayout>" | Out-File "$StartMenuLayoutFile" -Append
			"      <taskbar:TaskbarPinList>" | Out-File "$StartMenuLayoutFile" -Append
			"        <taskbar:DesktopApp DesktopApplicationLinkPath=`"%APPDATA%\Microsoft\Windows\Start Menu\Programs\System Tools\File Explorer.lnk`" />" | Out-File "$StartMenuLayoutFile" -Append
			"      </taskbar:TaskbarPinList>" | Out-File "$StartMenuLayoutFile" -Append
			"    </defaultlayout:TaskbarLayout>" | Out-File "$StartMenuLayoutFile" -Append
			"  </CustomTaskbarLayoutCollection>" | Out-File "$StartMenuLayoutFile" -Append
			"</LayoutModificationTemplate>" | Out-File "$StartMenuLayoutFile" -Append
			
			(Get-Content "$StartMenuLayoutFile") | Out-File -Encoding ascii "$StartMenuLayoutFile"
			
			if (Test-Path "$env:windir\StartMenuLayout.xml")
			{
				Write-Log "Import Start Menu Layout"
				try { Import-StartLayout -LayoutPath "$env:windir\StartMenuLayout.xml" -MountPath "$env:SystemDrive\" }
				catch { Write-Log "Failed to import Start Menu Layout" }
			}
			else { Write-Log "No StartMenuLayout.xml found, skipping..." }
			
			
			if ($TSType -eq "Upgrade") { Write-Log "TS Type is upgrade - will not copy DefaultApps.xml" }
			else
			{
				Write-Log "TS Type is Installation - will copy DefaultApps.xml"
				
				# Import Application Associations
				Write-Log "Import Application Associations"
				$DefaultAppsXML = "DefaultApps.xml"
				if ($WebBrowserLinkFound -eq $false) { $DefaultAppsXML = "DefaultApps_NoIE.xml" }
				if ($AllowUserWebAssociationChange -eq $true) { $DefaultAppsXML = "DefaultApps_NoIE.xml" }
				if ($EdgeChromiumInstalled -eq $true) { $DefaultAppsXML = "DefaultApps_EdgeChromium.xml" }
				Execute-Process -Path "$env:windir\System32\dism.exe" -Parameters "/online /Import-DefaultAppAssociations:`"$dirsupportfiles\$DefaultAppsXML`"" -WindowStyle "Hidden" -ContinueOnError $true -Passthru
				$ErrorCode = $LastExitCode
				Write-Log "Imported application associations ($DefaultAppsXML) using DISM with exit code: $ErrorCode"
				# Copy DefaultApps.xml to local disk preparing for GPO control of associations
				Copy-Item -Path "$dirsupportfiles\$DefaultAppsXML" -Destination "$env:windir\DefaultApps.xml" -Force -ErrorAction SilentlyContinue
			}
			
			
			# Remove Videos folder in my documents
			Write-Log "Remove Videos folder in my documents"
			New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderDescriptions\{35286a68-3c57-41a1-bbb1-0eae73d76c95}\PropertyBag" -Name 'ThisPCPolicy' -Value 'Hide' -PropertyType String -Force | Out-Null
			New-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\FolderDescriptions\{35286a68-3c57-41a1-bbb1-0eae73d76c95}\PropertyBag" -Name 'ThisPCPolicy' -Value 'Hide' -PropertyType String -Force | Out-Null
			
			# Remove Music folder in my documents
			Write-Log "Remove Music folder in my documents"
			New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderDescriptions\{a0c69a99-21c8-4671-8703-7934162fcf1d}\PropertyBag" -Name 'ThisPCPolicy' -Value 'Hide' -PropertyType String -Force | Out-Null
			New-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\FolderDescriptions\{a0c69a99-21c8-4671-8703-7934162fcf1d}\PropertyBag" -Name 'ThisPCPolicy' -Value 'Hide' -PropertyType String -Force | Out-Null
			
			# Show drives and not quick access when opening explorer
			Write-Debug "Show drives and not quick access when opening explorer"
			New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name 'LaunchTo' -Value '1' -PropertyType DWord -Force | Out-Null
			
			# Get "old" Photoviewer back
			Write-Log "Get 'old' Photoviewer back"
			Start-Process -FilePath "regedit.exe" -ArgumentList "/s `"$dirsupportfiles\Restore_Windows_Photo_Viewer.reg`"" -NoNewWindow -Wait -PassThru -ErrorAction SilentlyContinue
			
			# Prevent Windows 10 to change app associations on some file extensions
			Write-Log "Prevent Windows 10 to change app associations on some file extensions"
			$OSVersion = (Get-CimInstance Win32_OperatingSystem).Version
			if ($OSVersion -like "*10.0.*")
			{
				[scriptblock]$HKCURegistrySettings = {
					Set-RegistryKey -Key 'HKCU\SOFTWARE\Classes\AppXd4nrz8ff68srnhf9t5a8sbjyar1cr723\' -Name 'NoOpenWith' -Value '' -Type String -SID $UserProfile.SID
					Set-RegistryKey -Key 'HKCU\SOFTWARE\Classes\AppXvhc4p7vz4b485xfp46hhk3fq3grkdgjg\' -Name 'NoOpenWith' -Value '' -Type String -SID $UserProfile.SID
					Set-RegistryKey -Key 'HKCU\SOFTWARE\Classes\AppX4hxtad77fbk3jkkeerkrm0ze94wjf3s9\' -Name 'NoOpenWith' -Value '' -Type String -SID $UserProfile.SID
					Set-RegistryKey -Key 'HKCU\SOFTWARE\Classes\AppXde74bfzw9j31bzhcvsrxsyjnhhbq66cs\' -Name 'NoOpenWith' -Value '' -Type String -SID $UserProfile.SID
					Set-RegistryKey -Key 'HKCU\SOFTWARE\Classes\AppXcc58vyzkbjbs4ky0mxrmxf8278rk9b3t\' -Name 'NoOpenWith' -Value '' -Type String -SID $UserProfile.SID
					Set-RegistryKey -Key 'HKCU\SOFTWARE\Classes\AppX43hnxtbyyps62jhe9sqpdzxn1790zetc\' -Name 'NoOpenWith' -Value '' -Type String -SID $UserProfile.SID
					Set-RegistryKey -Key 'HKCU\SOFTWARE\Classes\AppXqj98qxeaynz6dv4459ayz6bnqxbyaqcs\' -Name 'NoOpenWith' -Value '' -Type String -SID $UserProfile.SID
					Set-RegistryKey -Key 'HKCU\SOFTWARE\Classes\AppX6eg8h5sxqq90pv53845wmnbewywdqq5h\' -Name 'NoOpenWith' -Value '' -Type String -SID $UserProfile.SID
				}
				Invoke-HKCURegistrySettingsForAllUsers -RegistrySettings $HKCURegistrySettings
			}
			
			Write-Log "Allow Telemetry"
			New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name 'AllowTelemetry' -Value '1' -PropertyType DWord -Force | Out-Null
			New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name 'Enabled' -Value '0' -PropertyType DWord -Force | Out-Null
			
			# Network Discovery - Turn On or Off in Windows 10
			Write-Log "Network Discovery - Turn On or Off in Windows 10"
			Start-Process -FilePath "netsh" -ArgumentList "advfirewall firewall set rule group=`"Network Discovery`" new enable=Yes" -NoNewWindow -ErrorAction SilentlyContinue -PassThru -Wait
			
			# The Group Policy Client service failed the sign-in. The universal unique identifier (UUID) type is not supported
			Write-Log "The Group Policy Client service failed the sign-in. The universal unique identifier (UUID) type is not supported"
			New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\gpsvc" -Name 'Type' -Value '0x10' -PropertyType DWord -Force | Out-Null
			
			# Removing the "Do you want to allow your PC to be discoverable"
			Write-Log "Removing the 'Do you want to allow your PC to be discoverable'"
			New-Item -Path "HKLM:\System\CurrentControlSet\Control\Network" -Name "NewNetworkWindowOff" -Force | Out-Null
			
			# Remove Windows 10 Creators Update message in Windows Update
			Write-Log "Remove Windows 10 Creators Update message in Windows Update"
			New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name 'HideMCTLink' -Value '1' -PropertyType DWord -Force | Out-Null
			
			# Disabling Xbox DVR in Windows 10
			Write-Log "Disabling Xbox DVR in Windows 10"
			New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows" -Name 'GameDVR' -Value '0' -PropertyType DWord -Force | Out-Null
			
			[scriptblock]$HKCURegistrySettings = {
				Set-RegistryKey -Key 'HKCU\System\GameConfigStore\' -Name 'GameDVR_Enabled' -Value '0' -Type DWord -SID $UserProfile.SID
			}
			Invoke-HKCURegistrySettingsForAllUsers -RegistrySettings $HKCURegistrySettings
			
			# Remove People Button from Taskbar
			Write-Log "Remove People Button from Taskbar"
			[scriptblock]$HKCURegistrySettings = {
				Set-RegistryKey -Key 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People\' -Name 'PeopleBand' -Value '0' -Type DWord -SID $UserProfile.SID
			}
			Invoke-HKCURegistrySettingsForAllUsers -RegistrySettings $HKCURegistrySettings
			
			# Add permissions for user to install Thunderbolt driver
			Write-Log "Add permissions for user to install Thunderbolt driver"
			New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\ThunderboltService\TbtServiceSettings" -Name 'ApprovalLevel' -Value '1' -PropertyType DWord -Force | Out-Null
			
			# Disable Peer-to-Peer (P2P) Apps & Updates Download from More Than One Place
			Write-Log "Disable Peer-to-Peer (P2P) Apps & Updates Download from More Than One Place"
			New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" -Name 'DODownloadMode' -Value '0' -PropertyType DWord -Force | Out-Null
			
			# Turn off automatic device driver update
			Write-Log "Turn off automatic device driver update"
			New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching" -Name 'SearchOrderConfig' -Value '0' -PropertyType DWord -Force | Out-Null
			
			# Enable the Microsoft Consumer Experience
			Write-Log "Enable the Microsoft Consumer Experience"
			New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name 'DisableWindowsConsumerFeatures' -Value '0' -PropertyType DWord -Force | Out-Null
			
			# Enable Status bar in Notepad
			Write-Log "Enable Status bar in Notepad"
			[scriptblock]$HKCURegistrySettings = {
				Set-RegistryKey -Key 'HKCU\Software\Microsoft\Notepad\' -Name 'StatusBar' -Value '1' -Type DWord -SID $UserProfile.SID
			}
			Invoke-HKCURegistrySettingsForAllUsers -RegistrySettings $HKCURegistrySettings
			
			# Enable Location provider - for weather autoconfig etc
			Write-Log "Enable Location provider - for weather autoconfig etc"
			New-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\LocationAndSensors" -Name 'DisableWindowsLocationProvider' -Value '0' -PropertyType DWord -Force | Out-Null
			New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\lfsvc\Service\Configuration" -Name 'Status' -Value '1' -PropertyType DWord -Force | Out-Null
			
			[scriptblock]$HKCURegistrySettings = {
				Set-RegistryKey -Key 'HKCU\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Sensor\Permissions\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}\' -Name 'SensorPermissionState' -Value '1' -Type DWord -SID $UserProfile.SID
				Set-RegistryKey -Key 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}\' -Name 'Value' -Value 'Allow' -Type String -SID $UserProfile.SID
			}
			Invoke-HKCURegistrySettingsForAllUsers -RegistrySettings $HKCURegistrySettings
			
			# Add cmtrace to OS as default log viewer
			Write-Log "Add cmtrace to OS as default log viewer"
			if (!(Test-Path "$env:windir\CCM\CMTrace.exe")) { Copy-Item -Path "$dirfiles\cmtrace.exe" -Destination "$env:windir\System32" -Force -ErrorAction SilentlyContinue; $CmTraceLocation = "$env:windir\System32\CMTrace.exe" }
			else { $CmTraceLocation = "$env:windir\CCM\CMTrace.exe" }
			New-Item -Path 'HKLM:\Software\Classes\.lo_' -type Directory -Force -ErrorAction SilentlyContinue | Out-Null
			New-Item -Path 'HKLM:\Software\Classes\.log' -type Directory -Force -ErrorAction SilentlyContinue | Out-Null
			New-Item -Path 'HKLM:\Software\Classes\.log.File' -type Directory -Force -ErrorAction SilentlyContinue | Out-Null
			New-Item -Path 'HKLM:\Software\Classes\.Log.File\shell' -type Directory -Force -ErrorAction SilentlyContinue | Out-Null
			New-Item -Path 'HKLM:\Software\Classes\Log.File\shell\Open' -type Directory -Force -ErrorAction SilentlyContinue | Out-Null
			New-Item -Path 'HKLM:\Software\Classes\Log.File\shell\Open\Command' -type Directory -Force -ErrorAction SilentlyContinue | Out-Null
			New-Item -Path 'HKLM:\Software\Microsoft\Trace32' -type Directory -Force -ErrorAction SilentlyContinue | Out-Null
			
			# Create the properties to make CMtrace the default log viewer
			New-ItemProperty -LiteralPath 'HKLM:\Software\Classes\.lo_' -Name '(default)' -Value "Log.File" -PropertyType String -Force -ErrorAction SilentlyContinue | Out-Null
			New-ItemProperty -LiteralPath 'HKLM:\Software\Classes\.log' -Name '(default)' -Value "Log.File" -PropertyType String -Force -ErrorAction SilentlyContinue | Out-Null
			New-ItemProperty -LiteralPath 'HKLM:\Software\Classes\Log.File\shell\open\command' -Name '(default)' -Value "`"$CmTraceLocation`" `"%1`"" -PropertyType String -Force -ErrorAction SilentlyContinue | Out-Null
			
			# Create an ActiveSetup that will remove the initial question in CMtrace if it should be the default reader
			New-Item -Path "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\CMtrace" -type Directory -Force -ErrorAction SilentlyContinue | Out-Null
			new-itemproperty "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\CMtrace" -Name "Version" -Value 1 -PropertyType String -Force -ErrorAction SilentlyContinue | Out-Null
			new-itemproperty "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\CMtrace" -Name "StubPath" -Value "reg.exe add HKCU\Software\Microsoft\Trace32 /v ""Register File Types"" /d 0 /f" -PropertyType ExpandString -Force -ErrorAction SilentlyContinue | Out-Null
			
			# Remove Edge Desktop shortcut
			Write-Log "Remove Edge Desktop shortcut"
			New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" -Name 'DisableEdgeDesktopShortcutCreation' -Value '1' -PropertyType DWord -Force -ErrorAction SilentlyContinue | Out-Null
			
			# Remove suggestions in time line
			Write-Log "Remove suggestions in time line"
			[scriptblock]$HKCURegistrySettings = {
				Set-RegistryKey -Key 'HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\' -Name 'SubscribedContent-353698Enabled' -Value '0' -Type DWord -SID $UserProfile.SID # 1709
				Set-RegistryKey -Key 'HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\' -Name 'SubscribedContent-338388Enabled' -Value '0' -Type DWord -SID $UserProfile.SID # 1803
				Set-RegistryKey -Key 'HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\' -Name 'SystemPaneSuggestionsEnabled' -Value '0' -Type DWord -SID $UserProfile.SID
			}
			Invoke-HKCURegistrySettingsForAllUsers -RegistrySettings $HKCURegistrySettings
			
			# Disable Automatically Installing Suggested Apps
			Write-Log "Disable Automatically Installing Suggested Apps"
			[scriptblock]$HKCURegistrySettings = {
				Set-RegistryKey -Key 'HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\' -Name 'SilentInstalledAppsEnabled' -Value '0' -Type DWord -SID $UserProfile.SID
				Set-RegistryKey -Key 'HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\' -Name 'ContentDeliveryAllowed' -Value '0' -Type DWord -SID $UserProfile.SID
				Set-RegistryKey -Key 'HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\' -Name 'OemPreInstalledAppsEnabled' -Value '0' -Type DWord -SID $UserProfile.SID
				Set-RegistryKey -Key 'HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\' -Name 'PreInstalledAppsEnabled' -Value '0' -Type DWord -SID $UserProfile.SID
				Set-RegistryKey -Key 'HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\' -Name 'PreInstalledAppsEverEnabled' -Value '0' -Type DWord -SID $UserProfile.SID
				Set-RegistryKey -Key 'HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\' -Name 'SubscribedContentEnabled' -Value '0' -Type DWord -SID $UserProfile.SID
				Remove-RegistryKey -Key 'HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\SuggestedApps' -SID $UserProfile.SID
			}
			Invoke-HKCURegistrySettingsForAllUsers -RegistrySettings $HKCURegistrySettings
			
			# Turn On or Off Tips, Tricks, and Suggestions Notifications
			Write-Log "Turn On or Off Tips, Tricks, and Suggestions Notifications"
			[scriptblock]$HKCURegistrySettings = {
				Set-RegistryKey -Key 'HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\' -Name 'SubscribedContent-338389Enabled' -Value '0' -Type DWord -SID $UserProfile.SID
			}
			Invoke-HKCURegistrySettingsForAllUsers -RegistrySettings $HKCURegistrySettings
			New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name 'DisableSoftLanding' -Value '1' -PropertyType DWord -Force | Out-Null
			
			# Allow Connection to Windows Update locations - must be enabled for downloading from Microsoft Store
			Write-Log "Allow Connection to Windows Update locations - must be enabled for downloading from Microsoft Store"
			New-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate" -Name 'DoNotConnectToWindowsUpdateInternetLocations' -Value '0' -PropertyType DWord -Force | Out-Null
			
			# Remove Searchbar in 1903
			Write-Log "Remove Searchbar in 1903+"
			# 0 = Hidden
			# 1 = Show search or Cortana icon
			# 2 = Show search box
			[scriptblock]$HKCURegistrySettings = {
				Set-RegistryKey -Key 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search\' -Name 'SearchboxTaskbarMode' -Value '0' -Type DWord -SID $UserProfile.SID
			}
			Invoke-HKCURegistrySettingsForAllUsers -RegistrySettings $HKCURegistrySettings
			
			# Fix Network connectivity exclamation mark
			Write-Log "Fix Network connectivity exclamation mark"
			# New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\NlaSvc\Parameters\Internet" -Name "EnableActiveProbing" -Value '0' -PropertyType DWORD -Force -ErrorAction SilentlyContinue | Out-Null
			New-ItemProperty -Path "HKLM:\SOFTWARE\POLICIES\MICROSOFT\Windows\NetworkConnectivityStatusIndicator" -Name "UseGlobalDNS" -Value '1' -PropertyType DWORD -Force -ErrorAction SilentlyContinue | Out-Null
			
			# Set visual effects to 'Best Appearance'
			Write-Log "Set visual effects to 'Best Appearance'"
			[scriptblock]$HKCURegistrySettings = {
				Set-RegistryKey -Key 'HKCU\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects\' -Name 'VisualFXSetting' -Value '1' -Type DWord -SID $UserProfile.SID
			}
			Invoke-HKCURegistrySettingsForAllUsers -RegistrySettings $HKCURegistrySettings
			
		}
		
		
		
		################################################################################################  Removing APPX ###############################################################################
		If ($Retry -eq $false) { Write-Log "Removing Unwanted apps during full run of script" }
		else { Write-Log "Retrying removing unwanted apps since last try failed" }
		# Remove redundant Apps
		# Disable Microsoft Consumer Experiences (Additional Apps Auto Installed )
		New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name 'DisableWindowsConsumerFeatures' -Value '1' -PropertyType DWORD -Force | Out-Null
		New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore" -Name 'AutoDownload' -Value '2' -PropertyType DWORD -Force | Out-Null
		New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsStore\WindowsUpdate" -Name 'AutoDownload' -Value '2' -PropertyType DWORD -Force | Out-Null
		
		Get-Service dmwappushservice | Stop-Service -Force -ErrorAction SilentlyContinue
		Get-Service AppReadiness | Stop-Service -Force -ErrorAction SilentlyContinue
		Get-Service AppXSvc | Stop-Service -Force -ErrorAction SilentlyContinue
		Get-Service DiagTrack | Stop-Service -Force -ErrorAction SilentlyContinue
		Get-Service tiledatamodelsvc | Stop-Service -Force -ErrorAction SilentlyContinue
		Get-Service UsoSvc | Stop-Service -Force -ErrorAction SilentlyContinue
		Get-Service wuauserv | Stop-Service -Force -ErrorAction SilentlyContinue
		# Start-Sleep -Seconds 60
		
		# Get a list of all apps
		Write-Log "Get a list of all apps"
		$AppArrayList = Get-AppxPackage -PackageTypeFilter Bundle | Select-Object -Property Name, PackageFullName | Sort-Object -Property Name
		
		# Loop through the list of apps
		Write-Log "Loop through the list of apps"
		foreach ($App in $AppArrayList)
		{
			# Exclude essential Windows apps
			if (($App.Name -in "Microsoft.WindowsCalculator", "Microsoft.WindowsStore", "Microsoft.WindowsMaps", "Microsoft.Appconnector", "Microsoft.WindowsCommunicationsApps", "Microsoft.WindowsSoundRecorder", "Microsoft.DesktopAppInstaller", "Microsoft.Messaging", "Microsoft.StorePurchaseApp", "Microsoft.BingWeather", "Microsoft.Microsoft3DViewer", "Microsoft.3DBuilder", "Microsoft.MicrosoftStickyNotes", "Microsoft.MSPaint", "Microsoft.Windows.Photos", "Microsoft.WindowsCamera", "Microsoft.Office.OneNote", "Microsoft.NET.Native.Framework", "Microsoft.NET.Native.Runtime", "Microsoft.Services.Store.Engagement", "Microsoft.Windows.SecureAssessmentBrowser", "Microsoft.Windows.SecHealthUI", "Microsoft.Windows.CloudExperienceHost", "Microsoft.MicrosoftEdge", "Microsoft.YourPhone"))
			{
				Write-Log "Skipping essential Windows app: $($App.Name)"
			}
			
			# Remove AppxPackage and AppxProvisioningPackage
			else
			{
				# Gather package names
				$AppPackageFullName = Get-AppxPackage -Name $App.Name | Select-Object -ExpandProperty PackageFullName
				$AppProvisioningPackageName = Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -like $App.Name } | Select-Object -ExpandProperty PackageName
				
				# Attempt to remove AppxPackage
				try
				{
					Write-Log "Removing AppxPackage: $($AppPackageFullName)"
					Remove-AppxPackage -Package $AppPackageFullName -AllUsers -ErrorAction Stop
				}
				catch [System.Exception] {
					Write-Warning -Message $_.Exception.Message
				}
			}
		}
		
		$Capabilities = Get-Content "$($PSScriptRoot)\Capabilities$($Buildnr).txt"
		$Capabilities = New-Object -TypeName System.Collections.ArrayList
		$Capabilities.AddRange(@(
				"App.Support.ContactSupport~~~~0.0.1.0",
				"App.Support.QuickAssist~~~~0.0.1.0"
			))
		
		ForEach ($Capability in $Capabilities)
		{
			Write-Log "`r`nRemoving capability: $Capability"
			Remove-WindowsCapability -online -name $Capability
		}
		
		# Re-enable Access to store updates
		Write-Log "Re-enable Access to store updates"
		New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore" -Name 'AutoDownload' -Value '4' -PropertyType DWord -Force | Out-Null
		New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsStore\WindowsUpdate" -Name 'AutoDownload' -Value '4' -PropertyType DWord -Force | Out-Null
		New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name 'DisableWindowsConsumerFeatures' -Value '0' -PropertyType DWORD -Force | Out-Null
		

		##*===============================================
		##* POST-INSTALLATION
		##*===============================================
		[string]$installPhase = 'Post-Installation'

		## <Perform Post-Installation tasks here>
		
		# Remove desktop icon
		if (Test-Path "$env:PUBLIC\Desktop\Dummy.lnk")
		{
			Remove-File -Path "$env:PUBLIC\Desktop\Dummy.lnk"
		}
		
	}
	ElseIf ($deploymentType -ieq 'Uninstall')
	{
		##*===============================================
		##* PRE-UNINSTALLATION
		##*===============================================
		[string]$installPhase = 'Pre-Uninstallation'
		
		## Show Welcome Message, close Internet Explorer with a 60 second countdown before automatically closing
		Show-InstallationWelcome -CloseApps "$ApplicationsToClose" -CloseAppsCountdown 60
		
		## Show Progress Message (with the default message)
		Show-InstallationProgress
		
		## <Perform Pre-Uninstallation tasks here>
		
		
		##*===============================================
		##* UNINSTALLATION
		##*===============================================
		[string]$installPhase = 'Uninstallation'
		
		# <Perform Uninstallation tasks here>
		
		Remove-MSIApplications -Name "$appRegDisplayName"
		
		##*===============================================
		##* POST-UNINSTALLATION
		##*===============================================
		[string]$installPhase = 'Post-Uninstallation'
		
		## <Perform Post-Uninstallation tasks here>
		Remove-RegistryKey -Key "HKLM:\SOFTWARE\Cygate\Applications\$AppRegName" -ContinueOnError:$True
		Remove-RegistryKey -Key "HKLM:\SOFTWARE\Cygate\Detection\$AppRegName" -ContinueOnError:$True
		
	}
	ElseIf ($deploymentType -ieq 'Repair')
	{
		##*===============================================
		##* PRE-REPAIR
		##*===============================================
		[string]$installPhase = 'Pre-Repair'
		
		## Show Progress Message (with the default message)
		Show-InstallationProgress
		
		## <Perform Pre-Repair tasks here>
		
		##*===============================================
		##* REPAIR
		##*===============================================
		[string]$installPhase = 'Repair'
		
		## Handle Zero-Config MSI Repairs
		If ($useDefaultMsi)
		{
			[hashtable]$ExecuteDefaultMSISplat = @{ Action = 'Repair'; Path = $defaultMsiFile; }; If ($defaultMstFile) { $ExecuteDefaultMSISplat.Add('Transform', $defaultMstFile) }
			Execute-MSI @ExecuteDefaultMSISplat
		}
		# <Perform Repair tasks here>
		
		##*===============================================
		##* POST-REPAIR
		##*===============================================
		[string]$installPhase = 'Post-Repair'
		
		## <Perform Post-Repair tasks here>
		
		
	}
	##*===============================================
	##* END SCRIPT BODY
	##*===============================================
	
	## Call the Exit-Script function to perform final cleanup operations
	If ($deploymentType -ne 'Uninstall')
	{
		Set-RegistryKey -Key "HKLM:\SOFTWARE\Cygate\Applications\$AppRegName" -Name "InstallStatus" -Value '1' -Type String -ContinueOnError:$True
		# Set Intune detection regkey
		Set-RegistryKey -Key "HKLM:\SOFTWARE\Cygate\Detection\$AppRegName" -Name 'Version' -Type 'String' -Value "$appVersion"
	}
	Exit-Script -ExitCode $mainExitCode
}
Catch {
	Set-RegistryKey -Key "HKLM:\SOFTWARE\Cygate\Applications\$AppRegName" -Name "InstallStatus" -Value '0' -Type String -ContinueOnError:$True
	[int32]$mainExitCode = 60001
	[string]$mainErrorMessage = "$(Resolve-Error)"
	Write-Log -Message $mainErrorMessage -Severity 3 -Source $deployAppScriptFriendlyName
	Show-DialogBox -Text $mainErrorMessage -Icon 'Stop'
	Exit-Script -ExitCode $mainExitCode
}
