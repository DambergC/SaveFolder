if not "%1"=="7" start /min cmd /c ""%~0" 7 %*" & exit /b
set Z=%TEMP%\ImDisk%TIME::=%
extrac32.exe /e /l "%Z%" "%~dp0files.cab"
"%Z%\config.exe" %2 %3 %4
rd /s /q "%Z%"