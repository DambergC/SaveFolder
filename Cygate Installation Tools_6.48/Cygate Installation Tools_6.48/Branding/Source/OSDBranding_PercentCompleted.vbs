Dim sRetVal
sRetVal = ""

Dim oShell
Set oShell = CreateObject( "WScript.Shell" )


On Error Resume Next

Dim iTotalSteps
iTotalSteps = oShell.RegRead( "HKLM\Software\University of Hull\OSD\Branding\TotalSteps" )

Dim iCurrentStep
iCurrentStep = oShell.RegRead( "HKLM\Software\University of Hull\OSD\Branding\CurrentStep" )

Dim iPercentCompleted
iPercentCompleted = Round( ( 100 / iTotalSteps ) * iCurrentStep )

sRetVal = iPercentCompleted
On Error Goto 0

Echo sRetVal