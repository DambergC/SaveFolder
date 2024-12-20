'hide the Task Sequence Progress window
Set TsProgressUI = CreateObject("Microsoft.SMS.TsProgressUI")
TsProgressUI.CloseProgressDialog

Set env = CreateObject("Microsoft.SMS.TSEnvironment") 
strtitle = env("title")
strmessage = env("message")
strreturncode = env("returncode")

'Popup Message
MsgBox strmessage, 16, strTitle

'Shutdown computer
If strreturncode <> 0 Then
	Set WshShell = WScript.CreateObject("WScript.Shell")
	WshShell.Run "Wpeutil shutdown", 0, True
End If

wscript.quit(0)
