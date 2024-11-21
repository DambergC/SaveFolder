@echo off
IF EXIST "%programfiles(x86)%" (
	wFlashGUIX64.exe /quiet /sccm %*
	) ELSE ( 
	wFlashGUI.exe /quiet /sccm %*
	)