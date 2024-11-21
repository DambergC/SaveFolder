Const BARWIDTH = 50

Dim sRetVal
sRetVal = ""

Dim oShell
Set oShell = CreateObject( "WScript.Shell" )


On Error Resume Next

Dim iTotalSteps
iTotalSteps = oShell.RegRead( "HKLM\Software\University of Hull\OSD\Branding\TotalSteps" )

Dim iCurrentStep
iCurrentStep = oShell.RegRead( "HKLM\Software\University of Hull\OSD\Branding\CurrentStep" )

Dim iStepsRemaining
iStepsRemaining = Round( BARWIDTH - ( ( BARWIDTH / iTotalSteps ) * iCurrentStep) )

For i = 1 to iStepsRemaining
	sRetVal = sRetVal + "f"
Next

On Error Goto 0

Echo sRetVal