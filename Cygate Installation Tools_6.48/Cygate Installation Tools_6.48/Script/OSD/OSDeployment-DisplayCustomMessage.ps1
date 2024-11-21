<#
# niall brady 2016/5/25
# simple script to allow for quick messages in a task sequence
#>

#Hide the progress dialog
$TSProgressUI = new-object -comobject Microsoft.SMS.TSProgressUI
$TSProgressUI.CloseProgressDialog()
#connect to Task Sequence environment
$tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment
# read variables set in the task sequence
$title = $tsenv.Value("title")
$message = $tsenv.Value("message")
$returncode = $tsenv.Value("returncode")

# now show a popup message to the end user
write-host $title $message 
[System.Reflection.Assembly]::LoadWithPartialName(“System.Windows.Forms”)
[Windows.Forms.MessageBox]::Show(“$message”, “$title”, [Windows.Forms.MessageBoxButtons]::OK, [Windows.Forms.MessageBoxIcon]::Warning)
Exit $returncode