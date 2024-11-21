# Change Time stamp on file to avoid antivirus blocks becuase of "New file"

(Get-Item "$PSScriptRoot\bin\x64\InPlaceUpgrade-ReadyTool.exe").LastWriteTime = ("12 December 2016 14:00:00")
(Get-Item "$PSScriptRoot\bin\x64\InPlaceUpgrade-ReadyTool.exe").CreationTime = ("12 December 2016 14:00:00")
