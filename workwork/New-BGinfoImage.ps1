param (
    [int]$MonitorIndex = 0,
    [string]$FontFamilyName = 'Arial',
    [int]$FontSize = 40,
    [string]$OutputDirectory = "$PSScriptRoot\Output",
    [string]$BackgroundImage = "$PSScriptRoot\files\Background.jpg"
)

# Ensure output directory exists
if (!(Test-Path -Path $OutputDirectory)) {
    New-Item -ItemType Directory -Path $OutputDirectory -Force
}

# Validate background image path
if (!(Test-Path -Path $BackgroundImage)) {
    Write-Error "Background image not found at $BackgroundImage"
    exit
}

# Dynamic value for last reboot
$lastReboot = (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime

# Create BGInfo configuration
New-BGInfo -MonitorIndex $MonitorIndex {
    New-BGInfoValue -BuiltinValue HostName -Name "Systemname:" -Color white -FontSize 80 -FontFamilyName $FontFamilyName
    New-BGInfoValue -BuiltinValue FullUserName -Name "Loggedonuser:" -Color white -FontSize $FontSize -FontFamilyName $FontFamilyName
    New-BGInfoValue -Name "Last reboot:" -Value $lastReboot -Color white -FontSize $FontSize -FontFamilyName $FontFamilyName
} -FilePath $BackgroundImage -ConfigurationDirectory $OutputDirectory -PositionX 300 -PositionY 600 -WallpaperFit Fill
