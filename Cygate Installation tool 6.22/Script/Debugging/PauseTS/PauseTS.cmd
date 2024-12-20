@echo off
Set App_Path=%~dp0

"%App_Path%serviceUI.exe" -process:TSProgressUI.exe %SYSTEMROOT%\System32\wscript.exe "%App_Path%PauseTS.vbs"