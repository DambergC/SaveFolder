@echo off
IF EXIST "%programfiles(x86)%" (
	wFlashGuiX64.exe /quiet /sccm %*
	) ELSE ( 
	wFlashGui.exe /quiet /sccm %*
	)
