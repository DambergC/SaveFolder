# Preparing for TS environment
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

# Prepare for Logging
if (!(Test-Path "$env:windir\Logs\Software")) { New-Item -Path "$env:windir\Logs\Software" -ItemType dir -Force }
$LogFile = "$env:windir\Logs\Software\WindowsUpgrade.log"
if ((!(Test-Path "$env:windir\Logs\Software\WindowsUpgrade.log")) -and (Test-Path "$env:SystemDrive\Windows.old\Logs\Software\WindowsUpgrade.log")) { $LogFile = "$env:SystemDrive\Windows.old\Logs\Software\WindowsUpgrade.log" }
$ScriptName = "[" + ([io.fileinfo]$MyInvocation.MyCommand.Definition).BaseName + "]"
if (Test-Path "$LogFile") { (Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName ############################### Debug ###############################" | Out-File -FilePath $LogFile -Append }
else { (Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName ############################### Debug ###############################" | Out-File -FilePath $LogFile -Force }

try
{
	$OSDUpgradeCompatibility = $tsenv.Value("OSDUpgradeCompatibility"); "OSDUpgradeCompatibility: $OSDUpgradeCompatibility" | Out-File -FilePath $LogFile -Append
	$OSDLogServer = $tsenv.Value("OSDLogServer"); "OSDLogServer: $OSDLogServer" | Out-File -FilePath $LogFile -Append
	$OSDFirstLogCopy = $tsenv.Value("OSDFirstLogCopy"); "OSDFirstLogCopy: $OSDFirstLogCopy" | Out-File -FilePath $LogFile -Append
	$OSVersion = $tsenv.Value("OSVersion"); "OSVersion: $OSVersion" | Out-File -FilePath $LogFile -Append
	$OSArchitecture = $tsenv.Value("OSArchitecture"); "OSArchitecture: $OSArchitecture" | Out-File -FilePath $LogFile -Append
	$OSSKU = $tsenv.Value("OSSKU"); "OSSKU: $OSSKU" | Out-File -FilePath $LogFile -Append
	$MUIdetected = $tsenv.Value("MUIdetected"); "MUIdetected: $MUIdetected" | Out-File -FilePath $LogFile -Append
	$CurrentOSLanguage = $tsenv.Value("CurrentOSLanguage"); "CurrentOSLanguage: $CurrentOSLanguage" | Out-File -FilePath $LogFile -Append
	$RegInstallValue = $tsenv.Value("RegInstallValue"); "RegInstallValue: $RegInstallValue" | Out-File -FilePath $LogFile -Append
	$RegDefaultValue = $tsenv.Value("RegDefaultValue"); "RegDefaultValue: $RegDefaultValue" | Out-File -FilePath $LogFile -Append
	$OSIndex = $tsenv.Value("OSIndex"); "OSIndex: $OSIndex" | Out-File -FilePath $LogFile -Append
	$OSDDefaultUILanguage = $tsenv.Value("OSDDefaultUILanguage"); "OSDDefaultUILanguage: $OSDDefaultUILanguage" | Out-File -FilePath $LogFile -Append
	$OSDRebootPending = $tsenv.Value("OSDRebootPending"); "OSDRebootPending: $OSDRebootPending" | Out-File -FilePath $LogFile -Append
	$OSDMUILanguage = $tsenv.Value("OSDMUILanguage"); "OSDMUILanguage: $OSDMUILanguage" | Out-File -FilePath $LogFile -Append
	$OSDMultilingual = $tsenv.Value("OSDMultilingual"); "OSDMultilingual: $OSDMultilingual" | Out-File -FilePath $LogFile -Append
	$OSDDefaultLanguage = $tsenv.Value("OSDDefaultLanguage"); "OSDDefaultLanguage: $OSDDefaultLanguage" | Out-File -FilePath $LogFile -Append
	$returncode = $tsenv.Value("returncode"); "returncode: $returncode" | Out-File -FilePath $LogFile -Append
	$OSDChangePowerPlan = $tsenv.Value("OSDChangePowerPlan"); "OSDChangePowerPlan: $OSDChangePowerPlan" | Out-File -FilePath $LogFile -Append
	$OSDRevertPowerPlan = $tsenv.Value("OSDRevertPowerPlan"); "OSDRevertPowerPlan: $OSDRevertPowerPlan" | Out-File -FilePath $LogFile -Append
	$OSDCurrentPowerPlan = $tsenv.Value("OSDCurrentPowerPlan"); "OSDCurrentPowerPlan: $OSDCurrentPowerPlan" | Out-File -FilePath $LogFile -Append
	$TaskSequenceVer = $tsenv.Value("TaskSequenceVer"); "TaskSequenceVer: $TaskSequenceVer" | Out-File -FilePath $LogFile -Append
	$SMSTSPackageName = $tsenv.Value("_SMSTSPackageName"); "SMSTSPackageName: $SMSTSPackageName" | Out-File -FilePath $LogFile -Append
	$SMSTSMachineName = $tsenv.Value("_SMSTSMachineName"); "SMSTSMachineName: $SMSTSMachineName" | Out-File -FilePath $LogFile -Append
	$OSDTargetBuild = $tsenv.Value("OSDTargetBuild"); "OSDTargetBuild: $OSDTargetBuild" | Out-File -FilePath $LogFile -Append
	$OSDWindowsUpgrade = $tsenv.Value("OSDWindowsUpgrade"); "OSDWindowsUpgrade: $OSDWindowsUpgrade" | Out-File -FilePath $LogFile -Append
	$postponeDisabled = $tsenv.Value("postponeDisabled"); "postponeDisabled: $postponeDisabled" | Out-File -FilePath $LogFile -Append
	$OSDInputLocale = $tsenv.Value("OSDInputLocale"); "OSDInputLocale: $OSDInputLocale" | Out-File -FilePath $LogFile -Append
	$OSDUILanguage = $tsenv.Value("OSDUILanguage"); "OSDUILanguage: $OSDUILanguage" | Out-File -FilePath $LogFile -Append
	
	(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName ############################### Debug ###############################" | Out-File -FilePath $LogFile -Append
	
}
catch {}