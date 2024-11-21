# Preparing for TS environment
$tsenv = New-Object -ComObject Microsoft.SMS.TSEnvironment

# Prepare for Logging
$LogPath = $tsenv.Value("_SMSTSLogPath")
$LogFile = "$LogPath\UpgradeBranding.log"

$ScriptName = "[" + ([io.fileinfo]$MyInvocation.MyCommand.Definition).BaseName + "]"
if (Test-Path "$LogFile") { "$ScriptName Branding log started..." | Out-File -FilePath $LogFile -Append }
else { "$ScriptName Branding log started..." | Out-File -FilePath $LogFile -Force }

$ComputerName = $tsenv.Value("OSDComputerName")
"$ScriptName Computer Name from %OSDComputerName%: $ComputerName" | Out-File -FilePath $LogFile -Append
if (($ComputerName.Length -lt 4) -or ($ComputerName -eq $null))
{
	$ComputerName = $tsenv.Value("_SMSTSMachineName")
	"$ScriptName Computer Name from %OSDComputerName not valid using %_SMSTSMachineName%: $ComputerName" | Out-File -FilePath $LogFile -Append
}
$BuildString = "Installing, Please Wait..."

"$ScriptName Variables - Computer Name:            $ComputerName" | Out-File -FilePath $LogFile -Append
"$ScriptName Variables - Step Number:              $StepNumber" | Out-File -FilePath $LogFile -Append
"$ScriptName Variables - Step Name:                $StepName" | Out-File -FilePath $LogFile -Append

########################################################################## Install files if not done ##############################################################################

Remove-Item -Path "$env:windir\System32\*.bgi" -Force -ErrorAction SilentlyContinue

"$ScriptName OSD Copying files to %WINDIR%\System32" | Out-File -FilePath $LogFile -Append
Copy-Item -Path "$PSScriptRoot\Source\*.*" -Destination "$env:windir\System32" -Force
if (Test-Path "${env:ProgramFiles(x86)}")
{
	"$ScriptName x64 system, copying files to %WINDIR%\System32" | Out-File -FilePath $LogFile -Append
	Copy-Item -Path "$PSScriptRoot\x64\*.*" -Destination "$env:windir\System32" -Force
}
else
{
	"$ScriptName x86 system, copying files to %WINDIR%\System32" | Out-File -FilePath $LogFile -Append
	Copy-Item -Path "$PSScriptRoot\x86\*.*" -Destination "$env:windir\System32" -Force
}

############################################################################# Apply Branding #################################################################################

"$ScriptName Applying Branding" | Out-File -FilePath $LogFile -Append

"$ScriptName Setting Rundir to %WINDIR%\System32" | Out-File -FilePath $LogFile -Append
Push-Location -Path "$env:windir\System32" -ErrorAction SilentlyContinue -PassThru
"$ScriptName Starting BGInfo" | Out-File -FilePath $LogFile -Append

$Process = Start-Process -FilePath "$env:windir\System32\bginfo.exe" -ArgumentList "`"$env:windir\System32\OSDBranding.bgi`" /nolicprompt /silent /timer:0" -ErrorAction SilentlyContinue -PassThru -Wait
$ErrorCode = $Process.ExitCode
"$ScriptName BGInfo run with exit code: $ErrorCode" | Out-File -FilePath $LogFile -Append

"$ScriptName Starting Windowhide" | Out-File -FilePath $LogFile -Append
$Process = Start-Process -FilePath "$env:windir\System32\windowhide.exe" -ArgumentList "FirstUXWnd" -ErrorAction SilentlyContinue -PassThru -Wait
$ErrorCode = $Process.ExitCode
"$ScriptName WindowHide run with exit code: $ErrorCode" | Out-File -FilePath $LogFile -Append

$OSVersion = (Get-CimInstance Win32_OperatingSystem).Version
if ($OSVersion -like "*6.1.76*") { [string]$OSVersion = "Windows 7" }
if ($OSVersion -like "*6.2.*") { [string]$OSVersion = "Windows 8" }
if ($OSVersion -like "*6.3.*") { [string]$OSVersion = "Windows 8.1" }
if ($OSVersion -like "*10.0.*") { [string]$OSVersion = "Windows 10" }
"$ScriptName OS Version: $OSVersion" | Out-File -FilePath $LogFile -Append

if ( (($OSVersion -like "Windows 8*") -or ($OSVersion -eq "Windows 10")) -and ($tsenv.Value("_SMSTSInWinPE") -eq $false)   )
{
	"$ScriptName Running in full OS and OS is Windows 8 or 10" | Out-File -FilePath $LogFile -Append
	$ProcessRunning = Get-Process OSDBranding -ErrorAction SilentlyContinue
	if ($ProcessRunning -ne $null) { Start-Process -FilePath "taskkill.exe" -ArgumentList "/f /im OSDBranding.exe" -WindowStyle Hidden -ErrorAction SilentlyContinue -Wait }
	"$ScriptName Starting OSBranding" | Out-File -FilePath $LogFile -Append
	Start-Process -FilePath "OSDBranding.exe" -ErrorAction SilentlyContinue
}
Pop-Location -ErrorAction SilentlyContinue -PassThru

