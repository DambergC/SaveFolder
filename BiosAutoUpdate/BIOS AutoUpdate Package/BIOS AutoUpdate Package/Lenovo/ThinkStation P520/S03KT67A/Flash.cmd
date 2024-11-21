@echo off
IF EXIST "%programfiles(x86)%" (
	 wFlashGUIX64.exe %*
	) ELSE ( 
	 wFlashGUI.exe %*
	)
