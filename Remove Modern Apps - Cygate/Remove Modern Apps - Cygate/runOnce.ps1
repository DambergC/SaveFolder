$logFile = 'c:\windows\logs\software\RemoveModernApps.log'

Add-Content -Path $logFile "Running Remove Modern Apps runOnce"

$registryPath = "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce"

$Name = "RemoveModernApps"

$Value = '"C:\Windows\System32\cmd.exe" /c "C:\RemoveModernApps\Deploy-Application.exe -DeploymentType Install"'


New-ItemProperty -Path $registryPath -Name $Name -Value $Value -PropertyType String -Force

Add-Content -Path $logFile "Done.."
