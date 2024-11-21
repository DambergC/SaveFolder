New-Item -Path "$env:SystemDrive\RemoveModernApps" -ItemType dir -Force
Copy-Item -Path "$PSScriptRoot\*" -Destination "$env:SystemDrive\RemoveModernApps" -Force -Recurse