# Naming variables
# SITE derives from TS variable OSDSite
# TYPE is calculated from chassistype eg. LT (for laptop) DT (for desktop) and VM (for virtual machine)
# Number is either of 2 FREENUMBER (first available number available in AD - will use gap number) or LASTNUMBER (next available number in AD - will not use gap number)
# Ex. %FREENUMBER3% - where first available number is picked (even if in gap) - "3" is the number of characters numbering is using in this case example 002
# SERIAL is the serial number from BIOS
# Total name is composed like CY+%TYPE%+-+%SERIAL% - will be like CYLT-1234567
# Total name is composed like CY+%TYPE%+-+%S/N% - will be like CYLT-1234567

$global:ScriptName = "[" + ([io.fileinfo]$MyInvocation.MyCommand.Definition).BaseName + "]"

#region Source: Main Functions
Try
{
	$tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment
	$RunningInTs = $true
}
Catch
{
	$RunningInTs = $false
}
function Write-Log ($text)
{
	$LogPath = $tsenv.Value("_SMSTSLogPath")
	$LogFile = "$LogPath\Installation.log"
	(Get-Date).ToString("yy-MM-dd HH:mm:ss") + "   " + "$ScriptName $text" | Out-File -FilePath $LogFile -Append
}
function Mount-ISO ($Image)
{
	if (Test-Path "$Image")
	{
		try
		{
			$MountResult = Mount-DiskImage -ImagePath "$Image" -StorageType ISO -PassThru
			Start-Sleep -Seconds 3
			$DriveLetter = ($MountResult | Get-Volume).DriveLetter
			$DriveLetterFixed = $DriveLetter + ":"
		}
		catch { }
	}
	else { }
	return $DriveLetterFixed
}
function Dismount-ISO ($Image)
{
	try
	{
		$DismountResult = Dismount-DiskImage -ImagePath "$Image"
	}
	catch { }
	return
}
#endregion Main Function

# Prepare for Logging
Write-Log " "
Write-Log "Calculating Computer Name"

$Username = $tsenv.Value("OSDLogUser")
$Password = $tsenv.Value("OSDLogUserPassword")
$ParentDirectory = (Get-Item $PSScriptRoot).parent.parent.FullName

if ($tsenv.Value("OSDCustomerPrefix") -eq $null) { $tsenv.Value("OSDCustomerPrefix") = ""; Write-Log "No customer prefix set in TS, value is empty" }

# Connect to Log Share
if (Test-Path "T:")
{
	try
	{
		$Process = Start-Process -FilePath "NET.exe" -ArgumentList "USE T: /DELETE /Y" -NoNewWindow -Wait -PassThru -ErrorAction SilentlyContinue
		Write-Log "Disconnecting mapped drive to log share"
	}
	catch { Write-Log "Error: Failed disconnecting mapped drive to log share, " }
}
# Disconnect all shares
try
{
	$Process = Start-Process -FilePath "NET.exe" -ArgumentList "USE * /DELETE /Y" -NoNewWindow -Wait -PassThru -ErrorAction Stop
	Write-Log "Disconnecting mapped drive to log share"
}
catch { Write-Log "Error: Failed disconnecting mapped drive to log share, " }

$LogShare = "\\" + $tsenv.Value("OSDLogServer") + "\Logs$"
$UsernameFull = $tsenv.Value("OSDLogServer") + "\" + $Username

try
{
	Write-Log "Mapping Network Drive T: to Log Share $LogShare"
	$net = New-Object -comobject Wscript.Network
	$net.MapNetworkDrive("T:", "$LogShare", 0, "$UsernameFull", "$Password")
}
catch [System.Exception]{
	Write-Log "Connecting to log share $LogShare, exit code: $_.Exception.Message"
	Write-Log "Trying to map T: with NET USE command: Net Use T: $LogShare /user:$UsernameFull $Password"
	$Process = Start-Process -FilePath "NET.exe" -ArgumentList "USE T: $LogShare /user:$UsernameFull $Password" -NoNewWindow -Wait -PassThru -ErrorAction SilentlyContinue
	$ErrorCode = $Process.ExitCode
	Write-Log "Mapped T: with NET USE with exit code: $ErrorCode"
	if ($ErrorCode -ne 0)
	{
		Write-Log "Error: Failed mapping log share using NET USE"
		# exit 
	}
}

$tsenv.Value("NameReservationResult") = $false
$OSDOSVersion = $tsenv.Value("OSDOSVersion")
$OSDDomainOUName = $tsenv.Value("OSDDomainOUName")
$OUPathFromWebService = $tsenv.Value("OSDDomainOUNameFromWebService")
$OSDComputerNaming = $tsenv.Value("OSDComputerNaming")
$WebServiceAD = $tsenv.Value("OSDWebServiceAD")
$ADWeb = New-WebServiceProxy -Uri $WebServiceAD

Write-Log "OSDOSVersion: $OSDOSVersion"
Write-Log "OSDDomainOUName: $OSDDomainOUName"
# Write-Log "OSDComputerNaming: $OSDComputerNaming"

# Gather Current BIOS settings
$Bios_Settings = "$env:TEMP\BIOS_Settings.txt"

$Manufacturer = (Get-WmiObject win32_bios).Manufacturer.Trim()
if ($Manufacturer -like "*American Megatrends*") { $Manufacturer = (Get-WmiObject Win32_ComputerSystem).Manufacturer.TrimEnd() }
Write-Log "Manufacturer: $Manufacturer"
$Model = (Get-WmiObject Win32_ComputerSystem).Model.Trim()

if ($Manufacturer -like "*Lenovo*")
{
	Write-Log "Lenovo: Getting BIOS setting using gwmi"
	gwmi -Class lenovo_Biossetting -Namespace root\wmi | select currentsetting | Out-File $Bios_Settings -Force -ErrorAction SilentlyContinue
	$Model = (Get-WmiObject Win32_ComputerSystemProduct).Version.TrimEnd()
	$ModelNumber = (Get-WmiObject Win32_ComputerSystem).Model.TrimEnd()
	$SerialNumber = (gwmi win32_bios | Select -ExpandProperty SerialNumber).Trim()
	$BIOSVersion = (gwmi win32_bios | Select -ExpandProperty SMBIOSBIOSVersion).Trim()
	if ($BIOSVersion -like "*(*") { $BIOSVersion = $BIOSVersion.Substring($BIOSVersion.IndexOf("(") + 1) }
	if ($BIOSVersion -like "*)*") { $BIOSVersion = $BIOSVersion.Substring(0, $BIOSVersion.IndexOf(")")).Trim() }
	if ($BIOSVersion -like "*Ver.*") { $BIOSVersion = $BIOSVersion.Substring($BIOSVersion.IndexOf("Ver.") + 4).Trim() }
	if ($BIOSVersion -like "*Ver*") { $BIOSVersion = $BIOSVersion.Substring($BIOSVersion.IndexOf("Ver") + 3).Trim() }
	Write-Log "Manufacturer: $Manufacturer"
	Write-Log "Model: $Model"
	Write-Log "Model Number: $ModelNumber"
	Write-Log "Serial Number: $SerialNumber"
	Write-Log "BIOS Version: $BIOSVersion"
}

if ($Manufacturer -like "*Dell*")
{
	$ToolPath = "$ParentDirectory\Tools\Dell\X86_64\cctk.exe"
	$Process = Start-Process -FilePath "$ToolPath" -ArgumentList "--outfile `"$Bios_Settings`"" -NoNewWindow -PassThru -ErrorAction SilentlyContinue
	$ErrorCode = $Process.ExitCode
	Write-Log "Running Dell C&C tool $ToolPath with exit code: $ErrorCode"
	
	$Model = (Get-WmiObject Win32_ComputerSystem).Model.TrimEnd()
	$SerialNumber = (gwmi win32_bios | Select -ExpandProperty SerialNumber).Trim()
	$BIOSVersion = (gwmi win32_bios | Select -ExpandProperty SMBIOSBIOSVersion).Trim()
	if ($BIOSVersion -like "*(*") { $BIOSVersion = $BIOSVersion.Substring($BIOSVersion.IndexOf("(") + 1) }
	if ($BIOSVersion -like "*)*") { $BIOSVersion = $BIOSVersion.Substring(0, $BIOSVersion.IndexOf(")")).Trim() }
	if ($BIOSVersion -like "*Ver.*") { $BIOSVersion = $BIOSVersion.Substring($BIOSVersion.IndexOf("Ver.") + 4).Trim() }
	if ($BIOSVersion -like "*Ver*") { $BIOSVersion = $BIOSVersion.Substring($BIOSVersion.IndexOf("Ver") + 3).Trim() }
	Write-Log "Manufacturer: $Manufacturer"
	Write-Log "Model: $Model"
	Write-Log "Serial Number: $SerialNumber"
	Write-Log "BIOS Version: $BIOSVersion"
}

if (($Manufacturer -like "*HP*") -or ($Manufacturer -like "*Hewlett*"))
{
	$ToolPath = "$ParentDirectory\Tools\HP\BiosConfigUtility64.exe"
	$Process = Start-Process -FilePath "$ToolPath" -ArgumentList "/Get:`"$Bios_Settings`"" -NoNewWindow -PassThru -ErrorAction SilentlyContinue
	$ErrorCode = $Process.ExitCode
	Write-Log "Running HP BIOS configuration tool $ToolPath with exit code: $ErrorCode"
	
	$Model = (Get-WmiObject Win32_ComputerSystem).Model.TrimEnd()
	$SerialNumber = (gwmi win32_bios | Select -ExpandProperty SerialNumber).Trim()
	$BIOSVersion = (gwmi win32_bios | Select -ExpandProperty SMBIOSBIOSVersion).Trim()
	if ($BIOSVersion -like "*(*") { $BIOSVersion = $BIOSVersion.Substring($BIOSVersion.IndexOf("(") + 1) }
	if ($BIOSVersion -like "*)*") { $BIOSVersion = $BIOSVersion.Substring(0, $BIOSVersion.IndexOf(")")).Trim() }
	if ($BIOSVersion -like "*Ver.*") { $BIOSVersion = $BIOSVersion.Substring($BIOSVersion.IndexOf("Ver.") + 4).Trim() }
	if ($BIOSVersion -like "*Ver*") { $BIOSVersion = $BIOSVersion.Substring($BIOSVersion.IndexOf("Ver") + 3).Trim() }
	Write-Log "Manufacturer: $Manufacturer"
	Write-Log "Model: $Model"
	Write-Log "Serial Number: $SerialNumber"
	Write-Log "BIOS Version: $BIOSVersion"
	# If serial number is 8 or more character in length, must be chopped. Use 9 last characters.
	if ($SerialNumber.Length -gt 8)
	{
		Write-Log "Serial number greater then 9 in length, chopping..."
		$SerialNumber = $SerialNumber.Substring($SerialNumber.Length - 8)
	}
}

if ($Manufacturer -like "*Xen*")
{
	Write-Log "Manufacturer: $Manufacturer"
	$VirtualMachine = $true
	$Type = "VM"
	$SerialNumber = "VDI-MASTER"
}

if ($Manufacturer -like "*Intel*")
{
	$Model = (Get-WmiObject Win32_BaseBoard).Product.TrimEnd()
	$SerialNumber = (gwmi win32_bios | Select -ExpandProperty SerialNumber).Trim()
	$BIOSVersion = (gwmi win32_bios | Select -ExpandProperty SMBIOSBIOSVersion).Trim()
	Write-Log "Manufacturer: $Manufacturer"
	Write-Log "Model: $Model"
	Write-Log "Serial Number: $SerialNumber"
	Write-Log "BIOS Version: $BIOSVersion"
}

if ($Model -like "*A8X*")
{
	$SerialNumber = (gwmi win32_bios | Select -ExpandProperty SerialNumber).Trim()
	$BIOSVersion = (gwmi win32_bios | Select -ExpandProperty CSMBIOSBIOSVersion).Trim()
	Write-Log "Manufacturer: $Manufacturer"
	Write-Log "Model: $Model"
	Write-Log "Serial Number: $SerialNumber"
	Write-Log "BIOS Version: $BIOSVersion"
	$Type = "TP" # Tablet PC
	$tsenv.Value("OSDComputerType") = $Type
}

if ((Get-WmiObject win32_ComputerSystem).Manufacturer.Trim() -like "*Getac*") # Getac Tablet, model example EX80
{
	$SerialNumber = (Get-WmiObject win32_bios).SerialNumber.Trim()
	$Manufacturer = (Get-WmiObject win32_ComputerSystem).Manufacturer.Trim()
	$BIOSVersion = (Get-WmiObject win32_bios).SMBIOSBIOSVersion.Trim()
	$Model = (Get-WmiObject Win32_ComputerSystem).Model.TrimEnd()
	Write-Log "Manufacturer: $Manufacturer"
	Write-Log "Model: $Model"
	Write-Log "Serial Number: $SerialNumber"
	Write-Log "BIOS Version: $BIOSVersion"
	$Type = "TP" # Tablet PC
	$tsenv.Value("OSDComputerType") = $Type
}

if ((Get-WmiObject win32_ComputerSystem).Manufacturer.Trim() -like "*Durabook*") # Durabook Tablet, model example Pad-Ex 01 ()
{
	$SerialNumber = (Get-WmiObject win32_bios).SerialNumber.Trim()
	$Manufacturer = (Get-WmiObject win32_ComputerSystem).Manufacturer.Trim()
	$BIOSVersion = (Get-WmiObject win32_bios).SMBIOSBIOSVersion.Trim()
	Write-Log "Manufacturer: $Manufacturer"
	Write-Log "Model: $Model"
	Write-Log "Serial Number: $SerialNumber"
	Write-Log "BIOS Version: $BIOSVersion"
	$Type = "TP" # Tablet PC
	$tsenv.Value("OSDComputerType") = $Type
	if ($SerialNumber.Length -gt 9)
	{
		Write-Log "Serial number greater then 9 in length, chopping..."
		$SerialNumber = $SerialNumber.Substring($SerialNumber.Length - 9)
	}
}

# Check if Virtual Machine
$VirtualMachine = $false
$Manufacturer = (Get-WmiObject Win32_ComputerSystem).Manufacturer.Trim()
if ($Manufacturer -like "*Microsoft*")
{
	$ModelFriendlyName = (Get-WmiObject Win32_ComputerSystem).Model.TrimEnd()
	if ($ModelFriendlyName -like "*Virtual*")
	{
		Write-Log "This is a Hyper-V host, type will be VM"
		$VirtualMachine = $true
		$Type = "VM"
	}
}
if ($Manufacturer -like "*VMware*")
{
	$ModelFriendlyName = (Get-WmiObject Win32_ComputerSystem).Model.TrimEnd()
	if (($ModelFriendlyName -like "*VMware Virtual*") -or ($ModelFriendlyName -like "*VMware*"))
	{
		Write-Log "This is a VMware host, type will be VM"
		$VirtualMachine = $true
		$Type = "VM"
	}
}
if ($Manufacturer -like "*innotek*")
{
	$ModelFriendlyName = (Get-WmiObject Win32_ComputerSystem).Model.TrimEnd()
	if ($ModelFriendlyName -like "*VirtualBox*")
	{
		Write-Log "This is a VirtualBox host, type will be VM"
		$VirtualMachine = $true
		$Type = "VM"
	}
}
if ($Manufacturer -like "*Parallels Software*")
{
	$ModelFriendlyName = (Get-WmiObject Win32_ComputerSystem).Model.TrimEnd()
	if ($ModelFriendlyName -like "*Virtual Platform*")
	{
		Write-Log "This is a Parallels Virtual Platform host, type will be VM"
		$VirtualMachine = $true
		$Type = "VM"
	}
}
if (($Manufacturer -like "*Microsoft*") -and ($VirtualMachine -eq $false))
{
	Write-Log "Microsoft: Getting BIOS setting using gwmi"
	$Model = (Get-WmiObject Win32_ComputerSystem).Model.TrimEnd()
	$SerialNumber = (gwmi win32_bios | Select -ExpandProperty SerialNumber).Trim()
	$BIOSVersion = (gwmi win32_bios | Select -ExpandProperty SMBIOSBIOSVersion).Trim()
	Write-Log "Manufacturer: $Manufacturer"
	Write-Log "Model: $Model"
	Write-Log "Serial Number: $SerialNumber"
	Write-Log "BIOS Version: $BIOSVersion"
	# If serial number is 10 or more character in length, must be chopped. Use 9 last characters.
	if ($SerialNumber.Length -gt 9)
	{
		Write-Log "Serial number greater then 9 in length, chopping..."
		$SerialNumber = $SerialNumber.Substring($SerialNumber.Length - 9)
	}
	if ($ModelFriendlyName -like "*Surface Pro 7*") { Write-Log "Model is: $ModelFriendlyName which is considered tablet, setting type to 'TP'"; $tsenv.Value("OSDComputerType") = "TP" }
}

if ($Manufacturer -like "*ASUS*")
{
	$Model = (Get-WmiObject Win32_BaseBoard).Product.TrimEnd()
	$SerialNumber = (Get-WmiObject Win32_BaseBoard).SerialNumber.TrimEnd()
	$BIOSVersion = (gwmi win32_bios | Select -ExpandProperty SMBIOSBIOSVersion).Trim()
	Write-Log "Manufacturer: $Manufacturer"
	Write-Log "Model: $Model"
	Write-Log "Serial Number: $SerialNumber"
	Write-Log "BIOS Version: $BIOSVersion"
	# If serial number is 10 or more character in length, must be chopped. Use 9 last characters.
	if ($SerialNumber.Length -gt 9)
	{
		Write-Log "Serial number greater then 9 in length, chopping..."
		$SerialNumber = $SerialNumber.Substring($SerialNumber.Length - 9)
	}
}

function Name-Reservation
{
	$MACaddress = $tsenv.Value("MacAddress001")
	$ReservationName = ""
	# Check if reservation already exist - and cleanup failed older reservation files
	Get-ChildItem -Path "T:\*.txt" | Where-Object {
		$ReservationMACAdress = (Get-Content $_.FullName)
		$ReservationFileName = $_.Name
		$ReservationFullFileName = $_.FullName
		
		if ($ReservationMACAdress -eq $MACaddress) { $ReservationName = $_.BaseName  }
		
		# Remove file if older than 5 hours
		$LastWrite = (Get-Childitem $ReservationFullFileName).LastWriteTime
		$TimeSpan = New-TimeSpan -Days 0 -Hours 5 -Minutes 0 -Seconds 0
		if (((get-date) - $LastWrite) -gt $TimeSpan)
		{
			Write-Host "Deleting file: $ReservationFileName"
			Get-ChildItem $ReservationFullFileName | Remove-Item
		}
		
		Write-Host $ReservationName  $ReservationMACAdress
	}
	
	if (($ReservationName.length -lt 4) -or ($ReservationName -eq $null)) { $ReservationName = $tsenv.Value("ComputerTempName") }
	if (Test-Path "T:\$ReservationName.txt")
	{
		$MACaddressTemp = (Get-Content "T:\$ReservationName.txt")
		if ($MACaddressTemp -eq "$MACaddress")
		{
			$Result = $true # Already created reservation file - name OK
			Write-Log "Reserving Computer Name, Reservation of Name: $ReservationName already created by this PC"
		}
		else
		{
			$Result = $false # Reservation exist, taken by other computer
			Write-Log "Reserving Computer Name, Name: $ReservationName taken by other device with MAC: $MACaddressTemp"
		}
	}
	else
	{
		$MACaddress | Out-File "T:\$ReservationName.txt" # Computer found available name - creating reservation
		$Result = $true
		Write-Log "Reserving Computer Name, Reservation of Name: $ReservationName created successfully"
		$tsenv.Value("OSDReservationName") = $ReservationName
	}
	Return $Result
}

function Name-TYPE
{
	# Set Machine Type
	if ($VirtualMachine -eq $false)
	{
		if ($tsenv.Value("isLaptop") -ne $true)
		{
			$Global:Type = "DT"; Write-Log "Type variable (default) is set to: $Type"
			if (($($tsenv.Value("OSDComputerNamingDesktop")) -ne $null) -and ($($tsenv.Value("OSDComputerNamingDesktop")).Length -gt 1))
			{
				$global:Type = $($tsenv.Value("OSDComputerNamingDesktop"))
				Write-Log "OSDComputerNamingDesktop variable set in TS, new Type value: $Type"
			}
		}
		else
		{
			$global:Type = "LT"; Write-Log "Type variable (default) is set to: $Type"
			if (($($tsenv.Value("OSDComputerNamingLaptop")) -ne $null) -and ($($tsenv.Value("OSDComputerNamingLaptop")).Length -gt 1))
			{
				$global:Type = $($tsenv.Value("OSDComputerNamingLaptop"))
				Write-Log "OSDComputerNamingLaptop variable set in TS, new Type value: $Type"
			}
		}
	}
	if (($tsenv.Value("isLaptop") -eq $false) -and ($tsenv.Value("isDesktop") -eq $false)) { $tsenv.Value("isLaptop") = $true }
	if ($tsenv.Value("OSDComputerType") -eq "TP") { $Global:Type = "TP" }
	if ($VirtualMachine -eq $true) { $global:Type = "VM" }
	Return $Type
}
function Name-FREENUMBER
{
	try { $NumberOfCharacters = [convert]::ToInt32($Variable.Substring($Variable.IndexOf("FREENUMBER") + 10)) }
	catch { $NumberOfCharacters = 1 }
	$Computers = $ADWeb.SearchComputers("$NameArray")
	$Outfile = $tsenv.Value("_SMSTSLogPath") + "\Computers.txt"
	$Computers | Out-File $Outfile -Encoding "ASCII"
	
	# Read File into Array
	$ComputerArray = @()
	if (Test-Path $Outfile)
	{
		$objFile = [System.IO.File]::OpenText("$Outfile")
		if ([String]::IsNullOrWhiteSpace((Get-content "$Outfile"))) { Write-Host "Error: No computers found in AD - Check web service account" }
		while ($null -ne ($line = $objFile.ReadLine()))
		{
			$line = $line.Substring($line.IndexOf("CN=") + 3)
			$ComputerName = $line.Substring(0, $line.IndexOf(","))
			# Check if characters after number
			$ComputerNumberTemp = $ComputerName -replace "[^0-9]", ''
			$Pos = $ComputerName.IndexOf($ComputerNumberTemp)
			$NumberLength = $ComputerNumberTemp.Length
			$NameTemp = $ComputerName.Substring(0, $Pos + $NumberLength)
			if ($NameTemp.Length -ne $ComputerName.Length)
			{
				$NameRightPart = $ComputerName.Substring($Pos + $NumberLength)
				$ComputerName = $NameTemp
			}
			$ComputerArray += $ComputerName
		}
		
		# Find avaliable number
		$Counter = 1
		while ($Counter -lt 5000)
		{
			$Number = $Counter.ToString("D$NumberOfCharacters")
			$TempName = $NameArray + $Number
			if ($ComputerArray -like "*$TempName*") { }
			else
			{
				# Checking reserved names (text files in log share) - this is to handle multiple parallell installations where otherwise many computers would find the same name available in AD
				$tsenv.Value("ComputerTempName") = $TempName
				$Result = Name-Reservation
				$tsenv.Value("NameReservationResult") = $Result
				if ($Result -eq $true) { break }
			}
			$Counter = $Counter + 1
		}
	}
	Write-Log "Calculating Computer Name, Free Number: $Number"
	Return $Number
}
function Name-LASTNUMBER
{
	$Number = 3
	try { $NumberOfCharacters = [convert]::ToInt32($Variable.Substring($Variable.IndexOf("LASTNUMBER") + 10)) }
	catch { $NumberOfCharacters = 1 }
	
	$Computers = $ADWeb.SearchComputers("$NameArray")
	$Outfile = $tsenv.Value("_SMSTSLogPath") + "\Computers.txt"
	$Computers | Out-File $Outfile -Encoding "ASCII"
	
	# Read File into Array
	$ComputerArray = @()
	if (Test-Path $Outfile)
	{
		if ([String]::IsNullOrWhiteSpace((Get-content "$Outfile"))) { Write-Host "Error: No computers found in AD - Check web service account" }
		$objFile = [System.IO.File]::OpenText("$Outfile")
		while ($null -ne ($line = $objFile.ReadLine()))
		{
			$line = $line.Substring($line.IndexOf("CN=") + 3)
			$ComputerArray += $line.Substring(0, $line.IndexOf(","))
		}
		
		# Find avaliable number
		$Counter = $ComputerArray.Length
		$ComputerNumber = $ComputerArray[$Counter - 1]
		
		# Check if characters after number
		$ComputerNumberTemp = $ComputerNumber -replace "[^0-9]", ''
		$Pos = $ComputerNumber.IndexOf($ComputerNumberTemp)
		$NumberLength = $ComputerNumberTemp.Length
		$NameTemp = $ComputerNumber.Substring(0, $Pos + $NumberLength)
		if ($NameTemp.Length -ne $ComputerNumber.Length)
		{
			$NameRightPart = $ComputerNumber.Substring($Pos + $NumberLength)
			$ComputerNumber = $NameTemp
		}
		
		$ComputerNumber = $FullComputerName -replace "[^0-9]", ''
		# $ComputerNumber = $ComputerNumber.Substring($ComputerNumber.IndexOf("$NameArray") + $NameArray.Length)
		$ComputerNumber = [convert]::ToInt32($ComputerNumber.Substring(0, $NumberOfCharacters)) + 1
		$Number = $ComputerNumber.ToString("D$NumberOfCharacters")
		
		# Make Name reservation
		$tsenv.Value("ComputerTempName") = $NameTemp
		$Result = Name-Reservation
		$tsenv.Value("NameReservationResult") = $Result
	}
	Write-Log "Calculating Computer Name, Last Number: $Number"
	Return $Number
}
function Name-SERIAL
{
	# Get MAC adress as serial number if Virtual machine or if serial number is blank (ex. Intel NUC has no serial in BIOS)
	if (($VirtualMachine -eq $true) -or ($SerialNumber.Length -lt 2) -or ($SerialNumber -eq $null)) { $SerialNumber = $tsenv.Value("MacAddress001") -replace ":" }
	
	# If serial number is 10 or more character in length, must be chopped. Use 9 last characters.
	$MaxLength = (15 - $NameArray.length)
	Write-Log "Debug: function serial - MaxLength: $MaxLength"
	Write-Log "Debug: function serial - SerialNumber: $SerialNumber"
	Write-Log "Debug: function serial - NameArray: $NameArray"
	
	if ($SerialNumber.Length -gt $MaxLength)
	{
		Write-Log "Serial number greater then Max: $MaxLength in length, chopping $($SerialNumber.Length - $MaxLength)"
		$SerialNumber = $SerialNumber.Substring($SerialNumber.Length - $MaxLength)
	}
	else { Write-Log "Serial number within length limits, no chopping neccessary" }
	Write-Log "Calculating Computer Name, Serial Number: $SerialNumber"
	Return $SerialNumber
}
function Name-SITE
{
	if ($tsenv.Value("OSDSite") -ne $null) { $OSDSite = $tsenv.Value("OSDSite") }
	$tsenv.Value("OSDUseSiteOU") = $true
	Write-Log "Calculating Computer Name, Site: $OSDSite"
	Return $OSDSite
}

# Get naming components and check availability
$TestComputerNaming = $OSDComputerNaming
Write-Log "Calculating Computer Name, Get naming from variable OSDComputerNaming: $OSDComputerNaming"
while ($TestComputerNaming.Length -gt 1)
{
	$Position = $TestComputerNaming.IndexOf("%")
	if ($TestComputerNaming.IndexOf("+") -eq 0) { $TestComputerNaming = $TestComputerNaming.Substring($TestComputerNaming.IndexOf("+") + 1) }
	if ($TestComputerNaming.IndexOf("%") -gt 0)
	{
		$NameArray += $TestComputerNaming.Substring(0, $TestComputerNaming.IndexOf("%")) -replace '[^0-9a-zA-Z-]+'
		$TestComputerNaming = $TestComputerNaming.Substring($TestComputerNaming.IndexOf("%"))
	}
	elseif ($TestComputerNaming.IndexOf("%") -eq 0)
	{
		$TestComputerNaming = $TestComputerNaming.Substring(1, $TestComputerNaming.Length - 1)
		$Variable = $TestComputerNaming.Substring(0, $TestComputerNaming.IndexOf("%"))
		$TestComputerNaming = $TestComputerNaming.Substring($TestComputerNaming.IndexOf("%") + 1)
		$Type = Name-TYPE
		if ($Variable -like "*type*") { Write-Log "Calculating Computer Name, found variable *type* in naming";  $NameArray += Name-TYPE }
		if ($Variable -like "*freenumber*")
		{
			$MaxRetryCount = 1
			$NameReservationResult = $false
			do 
			{
				Write-Log "Calculating Computer Name, found variable *freenumber* in naming. Try name count: $MaxRetryCount"
				$Number = Name-FREENUMBER
				$MaxRetryCount = $MaxRetryCount + 1
				$NameReservationResult = $tsenv.Value("NameReservationResult")
				if ($NameReservationResult -eq $true) { $NameArray += $Number }
			}
			until (($NameReservationResult -eq $true) -or ($MaxRetryCount -gt 50))
		}
		if ($Variable -like "*lastnumber*")
		{
			$MaxRetryCount = 1
			$NameReservationResult = $false
			do 
			{
				Write-Log "Calculating Computer Name, found variable *lastnumber* in naming. Try name count: $MaxRetryCount"
				$Number = Name-LASTNUMBER
				$MaxRetryCount = $MaxRetryCount + 1
				$NameReservationResult = $tsenv.Value("NameReservationResult")
				if ($NameReservationResult -eq $true) { $NameArray += $Number }
			}
			until (($NameReservationResult -eq $true) -or ($MaxRetryCount -gt 50))
		}
		if ($Variable -like "*serial*") { Write-Log "Calculating Computer Name, found variable *serial* in naming"; $NameArray += Name-SERIAL }
		if ($Variable -like "*site*") { Write-Log "Calculating Computer Name, found variable *site* in naming"; $NameArray += Name-SITE }
		if ($Variable -like "*MANUAL*")	{ Write-Log "Calculating Computer Name, found variable *MANUAL* in naming - will not set name"; break }
	}
	elseif ($TestComputerNaming.IndexOf("%") -lt 0)
	{
		$NameArray += $TestComputerNaming
		$TestComputerNaming = ""
	}
	else
	{
		$NameArray += $TestComputerNaming.Substring(0, $TestComputerNaming.IndexOf("+"))
	}
}
if ($Variable -notlike "*MANUAL*")
{
	$ComputerName = $NameArray -replace '[^0-9a-zA-Z-]+'
	$tsenv.Value("OSDComputerName") = $ComputerName
	Write-Log "Computer Name calculated based on TS variable OSDComputerNaming: $ComputerName"
}

# Check if Computer exist in old Computer name
Write-Log "Check if Computer exist in old Computer name"
$tsenv.Value("OSDNameChange") = $false
if ($($tsenv.Value("OSDWebServiceADOperational")) -eq $true)
{
	Write-Log "AD Web Service is operational, OSDWebServiceADOperational = $($tsenv.Value("OSDWebServiceADOperational"))"
	if ($tsenv.Value("_SMSTSMachineName") -notlike "MININT*")
	{
		$ComputerNameTS = $tsenv.Value("_SMSTSMachineName")
		Write-Log "Getting current name from _SMSTSMachineName variable: $ComputerNameTS"
		
		# Check if old Computername matches naming standard - eg. reusing same computername
		Write-Log "Check if old computername matches naming standard to keep same name"
		$KeepComputerName = $false
		Write-Log "Variable for naming is:   $Variable"
		Write-Log "Computer Name from TS:    $ComputerNameTS"
		Write-Log "Computer Name calculated: $ComputerName"
		if (($Variable -like "*serial*") -and ($ComputerNameTS -ne $ComputerName))
		{
			Write-Log "*Serial* is used in Computer name + Calculated Computer name: $ComputerName is not the same as TS Computer name - name changed needed"
			$KeepComputerName = $false
			$tsenv.Value("OSDComputerName") = $ComputerName
		}
		else
		{
			$ComputerNameOld = $ComputerNameTS -replace '[^a-zA-Z-]+'
			$ComputerNameNew = $ComputerName -replace '[^a-zA-Z-]+'
			if ($ComputerNameOld -eq $ComputerNameNew)
			{
				$KeepComputerName = $true
				$tsenv.Value("OSDComputerName") = $tsenv.Value("_SMSTSMachineName")
				Write-Log "Old Computer Name matches naming standard, keeping old name"
				
				#Check if calculated name is different from current - then change is needed
				if (($ComputerName -ne $ComputerNameTS) -and ($KeepComputerName -eq $false))
				{
					Write-Log "Calculated Computer Name ($ComputerName) is not equal to TS Computer Name ($ComputerNameTS) - change needed"
					$KeepComputerName = $false
					$tsenv.Value("OSDComputerName") = $ComputerName
				}
				
				# Remove reservation if exists
				$ReservationName = $tsenv.Value("ComputerTempName")
				if ($ReservationName -ne $null)
				{
					if (Test-Path "T:\$ReservationName.txt") { Remove-Item -Path "T:\$ReservationName.txt" -Force; Write-Log "Removing reserved name file: T:\$ReservationName.txt" }
				}
			}
			else { Write-Log "old Computer Name does not match naming standard, calculating new" }
		}
		
		if (($ComputerNameTS -ne $ComputerName) -and ($KeepComputerName -ne $true))
		{
			Write-Log "Old Computer name ($ComputerNameTS) different from calculated ($ComputerName), name change will occur"
			$tsenv.Value("OSDNameChange") = $true
			
			# Check if force name change - force name change can cause problems with devices installed using shared adapter/docking whe same MAC adress is known for multiple clients 
			if (($tsenv.Value("OSDNameChangeForce") -eq $false) -and ($ComputerName -like "TP*"))
			{
				Write-Log "OSDNameChangeForce is false and model is tablet - do not force name change"
				$tsenv.Value("OSDNameChange") = $false
			}
			$tsenv.Value("OSDOldComputerName") = $ComputerNameTS
		}
		else
		{
			Write-Log "Retreived and calculated computer name is same - no name change needed"
			
			# Remove reservation if exists
			$ReservationName = $tsenv.Value("ComputerTempName")
			if ($ReservationName -ne $null)
			{
				if (Test-Path "T:\$ReservationName.txt") { Remove-Item -Path "T:\$ReservationName.txt" -Force; Write-Log "Removing reserved name file: T:\$ReservationName.txt" }
			}
		}
	}
	else { Write-Log "_SMSTSMachineName is $($tsenv.Value("_SMSTSMachineName"))" }
	
	# Remove object if exist due to new constraints
	Write-Log "Initiate removal of computer object in AD due to new security constraints preventing overwriting object creating and updating with differents accounts"
	Write-Log "WebService used: $WebServiceAD"
	$ADWeb = New-WebServiceProxy -Uri $WebServiceAD
	$ComputerExist = $ADWeb.DoesComputerExist("$ComputerName")
	Write-Log "Result after testing if computer $ComputerName exist: $ComputerExist"
	if ($ComputerExist -eq $true)
	{
		Write-Log "Computer $ComputerName found in AD"
		$RemoveComputer = $ADWeb.DeleteComputerForced("$ComputerName")
		if ($RemoveComputer -eq $true) { Write-Log "Computer $ComputerName removed successfully from AD" }
		else { Write-Log "Error: failed to remove $ComputerName from AD" }
	}
	else { Write-Log "Computer $ComputerName not found in AD - assuming new computer" }
}
else { Write-Log "Warning: AD Web Service is NOT operational, OSDWebServiceADOperational = $($tsenv.Value("OSDWebServiceADOperational"))" }

# Calculate OU Path
Write-Log "Calculate OU path"
$OUPathFromTS = $tsenv.Value("OSDDomainOUName")
$OUPathFromWebService = $tsenv.Value("OSDDomainOUNameFromWebService")
$OSDDomainOUNameLaptop = $tsenv.Value("OSDDomainNameOULaptop")
$OSDDomainOUNameDesktop = $tsenv.Value("OSDDomainNameOUDesktop")
Write-Log "OSDDomainOUName              : $OUPathFromTS"
Write-Log "OSDDomainOUNameFromWebService: $OUPathFromWebService"
Write-Log "OSDDomainNameOULaptop        : $OSDDomainOUNameLaptop"
Write-Log "OSDDomainNameOUDesktop       : $OSDDomainOUNameDesktop"
if ($OUPathFromWebService -ne $null)
{
	# Calculate OU Path
	if (($tsenv.Value("OSDUseSiteOU") -eq $true) -and ($tsenv.Value("OSDSite") -ne $null))
	{
		Write-Log "Site is part of computername - calculating OU path"
		$OUPath = $tsenv.Value("OSDDomainOUName")
		$OSDSite = $tsenv.Value("OSDSite")
		if ($OUPath -like "LDAP://*") { $OUPath = $OUPath.Substring($OUPath.IndexOf("LDAP://") + 7) }
		$OUPath = "LDAP://OU=Computers,OU=" + $OSDSite + "," + $OUPath
		Write-Log "Site OU path calculated: $OUPath"
		$OSDDomainOUName = $OUPath
	}
	# Get subfolders in OU path (Check if "Laptop" and "Desktop" folder exist), relative to the path configured as variable in TS
	Write-Log "Getting Subfolders on parent OU: $OSDDomainOUName"
	if ($OSDDomainOUName -ne $null)
	{
		# Extract string - LDAP:// from OUPath
		$Index = $OSDDomainOUName.IndexOf("/")
		$OSDDomainOUNameConverted = $OSDDomainOUName.Substring($Index + 2, $OSDDomainOUName.Length - ($Index + 2))
		Write-Log "LDAP path converted: $OSDDomainOUName"
		
		$ADWeb = New-WebServiceProxy -Uri $WebServiceAD
		$OUCheckFolders = $ADWeb.GetOUs("$OSDDomainOUNameConverted", "0")
		$Length = $OUCheckFolders.Length
		Write-Log "Number of subfolder(s) under $OSDDomainOUNameConverted : $Length"
			
		if (($OUCheckFolders -ne $null) -or ($OUCheckFolders.Length -gt 1))
		{
			$LaptopDesktopFolder = $false
			$Outfile = $tsenv.Value("_SMSTSLogPath") + "\OUFolders.txt"
			$OUCheckFolders.Path | Out-File $Outfile -Encoding "ASCII"
			Write-Log "Enumerating OU Folder(s) below $OSDDomainOUNameConverted"
			$objFile = [System.IO.File]::OpenText("$Outfile")
			while ($null -ne ($line = $objFile.ReadLine()))
			{
				if ($line -like "*OU=*")
				{
					$Index = $line.IndexOf("OU=")
					$OUTemp = ($line.Substring($Index, $line.Length - $Index)).Trim()
					$Index = $OUTemp.IndexOf(",")
					$OUTemp = ($OUTemp.Substring(0, $Index)).Trim()
					$Index = $OUTemp.IndexOf("=")
					$OUTemp = $OUTemp.Substring($Index + 1, $OUTemp.Length - ($Index + 1))
					Write-Log "OU Folder: $OUTemp"
						
					if ((($OUTemp -eq "Laptop") -or ($OUTemp -eq "Laptops")) -and (($Type -eq "LT") -or ($Type -eq "TP")))
					{
						$tsenv.Value("OSDDomainNameOULaptop") = "LDAP://OU=" + $OUTemp + "," + $OSDDomainOUNameConverted
						$OSDDomainOUNameLaptop = $tsenv.Value("OSDDomainNameOULaptop")
						$tsenv.Value("OSDDomainOUName") = $tsenv.Value("OSDDomainNameOULaptop")
						Write-Log "Laptop OU found, full path: $OSDDomainOUNameLaptop"
						$LaptopDesktopFolder = $true
					}
					elseif ((($OUTemp -eq "Desktop") -or ($OUTemp -eq "Desktops")) -and (($Type -eq "DT") -or ($Type -eq "VM")))
					{
						$tsenv.Value("OSDDomainNameOUDesktop") = "LDAP://OU=" + $OUTemp + "," + $OSDDomainOUNameConverted
						$OSDDomainOUNameDesktop = $tsenv.Value("OSDDomainNameOUDesktop")
						$tsenv.Value("OSDDomainOUName") = $tsenv.Value("OSDDomainNameOUDesktop")
						Write-Log "Desktop OU found, full path: $OSDDomainOUNameDesktop"
						$LaptopDesktopFolder = $true
					}
				}
			}
			if ($LaptopDesktopFolder -ne $true){ Write-Log "No Desktop/Laptop subfolder found" }
		}
		
		# If Desktop/Laptop OU not exist under SITE/Computers - check if exist directly under SITE
		if (($LaptopDesktopFolder -ne $true) -and ($OSDDomainOUName -ne $null))
		{
			if (($tsenv.Value("OSDUseSiteOU") -eq $true) -and ($tsenv.Value("OSDSite") -ne $null))
			{
				Write-Log "No Computers/Desktops (Laptops) folder try find directly under root"
				Write-Log "Site is part of computername - calculating OU path"
				$OUPath = $tsenv.Value("OSDDomainOUName")
				$OSDSite = $tsenv.Value("OSDSite")
				if ($OUPath -like "LDAP://*") { $OUPath = $OUPath.Substring($OUPath.IndexOf("LDAP://") + 7) }
				$OUPath = "LDAP://OU=" + $OSDSite + "," + $OUPath
				Write-Log "Site OU path calculated: $OUPath"
				$OSDDomainOUName = $OUPath
			}
			
			# Extract string - LDAP:// from OUPath
			$Index = $OSDDomainOUName.IndexOf("/")
			$OSDDomainOUNameConverted = $OSDDomainOUName.Substring($Index + 2, $OSDDomainOUName.Length - ($Index + 2))
			Write-Log "LDAP path converted: $OSDDomainOUName"
			
			$ADWeb = New-WebServiceProxy -Uri $WebServiceAD
			$OUCheckFolders = $ADWeb.GetOUs("$OSDDomainOUNameConverted", "0")
			$Length = $OUCheckFolders.Length
			Write-Log "Number of subfolder(s) under $OSDDomainOUNameConverted : $Length"
			
			if (($OUCheckFolders -ne $null) -or ($OUCheckFolders.Length -gt 1))
			{
				$LaptopDesktopFolder = $false
				$Outfile = $tsenv.Value("_SMSTSLogPath") + "\OUFolders.txt"
				$OUCheckFolders.Path | Out-File $Outfile -Encoding "ASCII"
				Write-Log "Enumerating OU Folder(s) below $OSDDomainOUNameConverted"
				$objFile = [System.IO.File]::OpenText("$Outfile")
				while ($null -ne ($line = $objFile.ReadLine()))
				{
					if ($line -like "*OU=*")
					{
						$Index = $line.IndexOf("OU=")
						$OUTemp = ($line.Substring($Index, $line.Length - $Index)).Trim()
						$Index = $OUTemp.IndexOf(",")
						$OUTemp = ($OUTemp.Substring(0, $Index)).Trim()
						$Index = $OUTemp.IndexOf("=")
						$OUTemp = $OUTemp.Substring($Index + 1, $OUTemp.Length - ($Index + 1))
						Write-Log "OU Folder: $OUTemp"
						
						if (($OUTemp -like "Laptop*") -and (($Type -eq "LT") -or ($Type -eq "TP")))
						{
							$tsenv.Value("OSDDomainNameOULaptop") = "LDAP://OU=" + $OUTemp + "," + $OSDDomainOUNameConverted
							$OSDDomainOUNameLaptop = $tsenv.Value("OSDDomainNameOULaptop")
							$tsenv.Value("OSDDomainOUName") = $tsenv.Value("OSDDomainNameOULaptop")
							Write-Log "Laptop OU found, full path: $OSDDomainOUNameLaptop"
							$LaptopDesktopFolder = $true
						}
						elseif (($OUTemp -like "Desktop*") -and (($Type -eq "DT") -or ($Type -eq "VM")))
						{
							$tsenv.Value("OSDDomainNameOUDesktop") = "LDAP://OU=" + $OUTemp + "," + $OSDDomainOUNameConverted
							$OSDDomainOUNameDesktop = $tsenv.Value("OSDDomainNameOUDesktop")
							$tsenv.Value("OSDDomainOUName") = $tsenv.Value("OSDDomainNameOUDesktop")
							Write-Log "Desktop OU found, full path: $OSDDomainOUNameDesktop"
							$LaptopDesktopFolder = $true
						}
					}
				}
				if ($LaptopDesktopFolder -ne $true) { Write-Log "No Desktop/Laptop subfolder found" }
			}
		}
		
		if (($OSDDomainOUNameLaptop -ne $null) -and ($OSDDomainOUNameLaptop.Length -gt 10) -and ($Type -eq "LT")) # From GetInfoFromWebService
		{
			$tsenv.Value("OSDDomainOUName") = $tsenv.Value("OSDDomainNameOULaptop")
			$OUPathNew = $tsenv.Value("OSDDomainOUName")
			Write-Log "Calculated new Laptop OU Path: $OUPathNew"
		}
		elseif (($OSDDomainOUNameDesktop -ne $null) -and ($OSDDomainOUNameDesktop.Length -gt 10) -and (($Type -eq "DT") -or ($Type -eq "VM"))) # From GetInfoFromWebService
		{
			$tsenv.Value("OSDDomainOUName") = $tsenv.Value("OSDDomainNameOUDesktop")
			$OUPathNew = $tsenv.Value("OSDDomainOUName")
			Write-Log "Calculated new Desktop/VM OU Path: $OUPathNew"
		}
		else
		{
			Write-Log "No Desktop/Laptop subfolder found, keeping OU path: $OUPathFromTS"
		}
	}
	
	# Check if Object placed in correct OU
	$OSDDomainOUName = $tsenv.Value("OSDDomainOUName")
	Write-Log "Check if correct OU: Current OU Path: $OUPathFromWebService"
	Write-Log "Check if correct OU: Target OU Path: $OSDDomainOUName"
	if ($OUPathFromWebService -eq $OSDDomainOUName)
	{
		Write-Log "Check if correct OU: Object placed in correct OU, no change needed"
		$tsenv.Value("OSDDomainMove") = $false
	}
	else
	{
		if (($tsenv.Value("OSDNameChange") -eq $false) -and ($OUPathFromWebService -ne $null))
		{
			$tsenv.Value("OSDDomainMove") = $true
			Write-Log "Check if correct OU: Object is not placed in correct OU, will be moved"
		}
		elseif ($tsenv.Value("OSDOldComputerName") -eq $null)
		{
			Write-Log "Check if correct OU: Object does not exist, treat as new computer"
			$tsenv.Value("OSDDomainMove") = $false
		}
		elseif ($tsenv.Value("OSDNameChange") -eq $true) { Write-Log "Computer Name will change, no move needed - join domain will place object in target OU" }
	}
}
else
{
	# No SCCM object found, leave $tsenv.Value("OSDDomainOUName") as is from custom TS variable
	Write-Log "No SCCM object found, leaving OU path is per custom TS variable"
}
