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
Write-Log "Setting keyboard layout, time zone etc."

# If variable for MUI "UILanguage" is blank UILanguage is equal to OSDOSLanguage (variable for Country specific settings like keyboard layout)
$UILanguage = $tsenv.Value("UILanguage")
$LanguageFound = $false

if ($tsenv.Value("OSDOSLanguage") -eq "cs-CZ") # Czech Republic
{
	$tsenv.Value("UILanguage") = "cs-CZ"
	$tsenv.Value("InputLocale") = "0405:00000405"
	$tsenv.Value("KeyboardLocale") = "cs-CZ"
	$tsenv.Value("SystemLocale") = "cs-CZ"
	$tsenv.Value("UserLocale") = "cs-CZ"
	$tsenv.Value("TimeZoneName") = "Central European Standard Time"
	$LanguageFound = $true
}
if ($tsenv.Value("OSDOSLanguage") -eq "da-DK")
{
	$tsenv.Value("UILanguage") = "da-DK"
	$tsenv.Value("InputLocale") = "0406:00000406"
	$tsenv.Value("KeyboardLocale") = "da-DK"
	$tsenv.Value("SystemLocale") = "da-DK"
	$tsenv.Value("UserLocale") = "da-DK"
	$tsenv.Value("TimeZoneName") = "Romance Standard Time"
	$LanguageFound = $true
}
if ($tsenv.Value("OSDOSLanguage") -eq "de-CH") # Germany-Swizz
{
	$tsenv.Value("UILanguage") = "de-DE"
	$tsenv.Value("InputLocale") = "0807:00000807"
	$tsenv.Value("KeyboardLocale") = "de-CH"
	$tsenv.Value("SystemLocale") = "de-CH"
	$tsenv.Value("UserLocale") = "de-CH"
	$tsenv.Value("TimeZoneName") = "W. Europe Standard Time"
	$LanguageFound = $true
}
if ($tsenv.Value("OSDOSLanguage") -eq "de-DE")
{
	$tsenv.Value("UILanguage") = "de-DE"
	$tsenv.Value("InputLocale") = "0407:00000407"
	$tsenv.Value("KeyboardLocale") = "de-DE"
	$tsenv.Value("SystemLocale") = "de-DE"
	$tsenv.Value("UserLocale") = "de-DE"
	$tsenv.Value("TimeZoneName") = "W. Europe Standard Time"
	$LanguageFound = $true
}
if ($tsenv.Value("OSDOSLanguage") -eq "en-GB")
{
	$tsenv.Value("UILanguage") = "en-GB"
	$tsenv.Value("InputLocale") = "0809:00000809"
	$tsenv.Value("KeyboardLocale") = "en-GB"
	$tsenv.Value("SystemLocale") = "en-GB"
	$tsenv.Value("UserLocale") = "en-GB"
	$tsenv.Value("TimeZoneName") = "GMT Standard Time"
	$LanguageFound = $true
}
if ($tsenv.Value("OSDOSLanguage") -eq "en-US")
{
	$tsenv.Value("UILanguage") = "en-US"
	$tsenv.Value("InputLocale") = "0409:00000409"
	$tsenv.Value("KeyboardLocale") = "en-US"
	$tsenv.Value("SystemLocale") = "en-US"
	$tsenv.Value("UserLocale") = "en-US"
	$tsenv.Value("TimeZoneName") = "Pacific Standard Time"
	if ($tsenv.Value("OSDSite") -like "USJT*") { $tsenv.Value("TimeZoneName") = "Eastern Standard Time" } # US Johnstown
	if ($tsenv.Value("OSDSite") -like "USSC*") { $tsenv.Value("TimeZoneName") = "Eastern Standard Time" } # US Stony Creek
	$LanguageFound = $true
}
if ($tsenv.Value("OSDOSLanguage") -eq "es-CL") # Chile
{
	$tsenv.Value("UILanguage") = "es-ES"
	$tsenv.Value("InputLocale") = "340a:0000080a"
	$tsenv.Value("KeyboardLocale") = "es-CL"
	$tsenv.Value("SystemLocale") = "es-CL"
	$tsenv.Value("UserLocale") = "es-CL"
	$tsenv.Value("TimeZoneName") = "Pacific S.A. Standard Time"
	$LanguageFound = $true
}
if ($tsenv.Value("OSDOSLanguage") -eq "es-ES")
{
	$tsenv.Value("UILanguage") = "es-ES"
	$tsenv.Value("InputLocale") = "040a:0000040a"
	$tsenv.Value("KeyboardLocale") = "es-ES"
	$tsenv.Value("SystemLocale") = "es-ES"
	$tsenv.Value("UserLocale") = "es-ES"
	$tsenv.Value("TimeZoneName") = "Romance Standard Time"
	$LanguageFound = $true
}
if ($tsenv.Value("OSDOSLanguage") -eq "es-MX") # Mexico
{
	$tsenv.Value("UILanguage") = "es-MX"
	$tsenv.Value("InputLocale") = "080a:0000080a"
	$tsenv.Value("KeyboardLocale") = "es-MX"
	$tsenv.Value("SystemLocale") = "es-MX"
	$tsenv.Value("UserLocale") = "es-MX"
	$tsenv.Value("TimeZoneName") = "Central Standard Time"
	$LanguageFound = $true
}
If ($tsenv.Value("OSDOSLanguage") -eq "fi-FI")
{
	$tsenv.Value("UILanguage") = "fi-FI"
	$tsenv.Value("InputLocale") = "040b:0000040b"
	$tsenv.Value("KeyboardLocale") = "fi-FI"
	$tsenv.Value("SystemLocale") = "fi-FI"
	$tsenv.Value("UserLocale") = "fi-FI"
	$tsenv.Value("TimeZoneName") = "FLE Standard Time"
	$LanguageFound = $true
}
if ($tsenv.Value("OSDOSLanguage") -eq "fr-CH") # Switzerland
{
	$tsenv.Value("UILanguage") = "fr-FR"
	$tsenv.Value("InputLocale") = "100c:0000100c"
	$tsenv.Value("KeyboardLocale") = "fr-CH"
	$tsenv.Value("SystemLocale") = "fr-CH"
	$tsenv.Value("UserLocale") = "fr-CH"
	$tsenv.Value("TimeZoneName") = "Central European Standard Time"
	$LanguageFound = $true
}
if ($tsenv.Value("OSDOSLanguage") -eq "fr-FR")
{
	$tsenv.Value("UILanguage") = "fr-FR"
	$tsenv.Value("InputLocale") = "040c:0000040c"
	$tsenv.Value("KeyboardLocale") = "fr-FR"
	$tsenv.Value("SystemLocale") = "fr-FR"
	$tsenv.Value("UserLocale") = "fr-FR"
	$tsenv.Value("TimeZoneName") = "Romance Standard Time"
	$LanguageFound = $true
}
if ($tsenv.Value("OSDOSLanguage") -eq "hu-HU") # Hungary
{
	$tsenv.Value("UILanguage") = "hu-HU"
	$tsenv.Value("InputLocale") = "040e:0000040e"
	$tsenv.Value("KeyboardLocale") = "hu-HU"
	$tsenv.Value("SystemLocale") = "hu-HU"
	$tsenv.Value("UserLocale") = "hu-HU"
	$tsenv.Value("TimeZoneName") = "Central European Standard Time"
	$LanguageFound = $true
}
if ($tsenv.Value("OSDOSLanguage") -eq "en-IN") # India
{
	$tsenv.Value("UILanguage") = "en-IN"
	$tsenv.Value("InputLocale") = "4009:00004009"
	$tsenv.Value("KeyboardLocale") = "en-IN"
	$tsenv.Value("SystemLocale") = "en-IN"
	$tsenv.Value("UserLocale") = "en-IN"
	$tsenv.Value("TimeZoneName") = "India Standard Time"
	$LanguageFound = $true
}

if ($tsenv.Value("OSDOSLanguage") -eq "it-IT")
{
	$tsenv.Value("UILanguage") = "it-IT"
	$tsenv.Value("InputLocale") = "0410:00000410"
	$tsenv.Value("KeyboardLocale") = "it-IT"
	$tsenv.Value("SystemLocale") = "it-IT"
	$tsenv.Value("UserLocale") = "it-IT"
	$tsenv.Value("TimeZoneName") = "W. Europe Standard Time"
	$LanguageFound = $true
}
if ($tsenv.Value("OSDOSLanguage") -eq "ja-JP") # Japan
{
	$tsenv.Value("UILanguage") = "ja-JP"
	$tsenv.Value("InputLocale") = "0411:{03B5835F-F03C-411B-9CE2-AA23E1171E36}{A76C93D9-5523-4E90-AAFA-4DB112F9AC76}"
	$tsenv.Value("KeyboardLocale") = "ja-JP"
	$tsenv.Value("SystemLocale") = "ja-JP"
	$tsenv.Value("UserLocale") = "ja-JP"
	$tsenv.Value("TimeZoneName") = "Tokyo Standard Time"
	$LanguageFound = $true
}
if ($tsenv.Value("OSDOSLanguage") -eq "ko-KR") # Korea
{
	$tsenv.Value("UILanguage") = "ko-KR"
	$tsenv.Value("InputLocale") = "0x00000412"
	$tsenv.Value("KeyboardLocale") = "ko-KR"
	$tsenv.Value("SystemLocale") = "ko-KR"
	$tsenv.Value("UserLocale") = "ko-KR"
	$tsenv.Value("TimeZoneName") = "Korea Standard Time"
	$LanguageFound = $true
}
if ($tsenv.Value("OSDOSLanguage") -eq "lv-LV") # Latvia
{
	$tsenv.Value("UILanguage") = "lv-LV"
	$tsenv.Value("InputLocale") = "0426:00020426"
	$tsenv.Value("KeyboardLocale") = "lv-LV"
	$tsenv.Value("SystemLocale") = "lv-LV"
	$tsenv.Value("UserLocale") = "lv-LV"
	$tsenv.Value("TimeZoneName") = "E. Europe Standard Time"
	$LanguageFound = $true
}
if ($tsenv.Value("OSDOSLanguage") -eq "nb-NO")
{
	$tsenv.Value("UILanguage") = "nb-NO"
	$tsenv.Value("InputLocale") = "0414:00000414"
	$tsenv.Value("KeyboardLocale") = "nb-NO"
	$tsenv.Value("SystemLocale") = "nb-NO"
	$tsenv.Value("UserLocale") = "nb-NO"
	$tsenv.Value("TimeZoneName") = "W. Europe Standard Time"
	$LanguageFound = $true
}
if ($tsenv.Value("OSDOSLanguage") -eq "nl-BE") # Belgium / Dutch
{
	$tsenv.Value("UILanguage") = "nl-BE"
	$tsenv.Value("InputLocale") = "0813:00000813"
	$tsenv.Value("KeyboardLocale") = "nl-BE"
	$tsenv.Value("SystemLocale") = "nl-BE"
	$tsenv.Value("UserLocale") = "nl-BE"
	$tsenv.Value("TimeZoneName") = "Central European Standard Time"
	$LanguageFound = $true
}
if ($tsenv.Value("OSDOSLanguage") -eq "fr-BE") # Belgium / French
{
	$tsenv.Value("UILanguage") = "fr-BE"
	$tsenv.Value("InputLocale") = "080c:0000080c"
	$tsenv.Value("KeyboardLocale") = "fr-BE"
	$tsenv.Value("SystemLocale") = "fr-BE"
	$tsenv.Value("UserLocale") = "fr-BE"
	$tsenv.Value("TimeZoneName") = "Central European Standard Time"
	$LanguageFound = $true
}
if ($tsenv.Value("OSDOSLanguage") -eq "nl-NL")
{
	$tsenv.Value("UILanguage") = "nl-NL"
	$tsenv.Value("InputLocale") = "0409:00020409"
	$tsenv.Value("KeyboardLocale") = "nl-NL"
	$tsenv.Value("SystemLocale") = "nl-NL"
	$tsenv.Value("UserLocale") = "nl-NL"
	$tsenv.Value("TimeZoneName") = "W. Europe Standard Time"
	$LanguageFound = $true
}
if ($tsenv.Value("OSDOSLanguage") -eq "pl-PL") # Poland
{
	$tsenv.Value("UILanguage") = "pl-PL"
	$tsenv.Value("InputLocale") = "0415:00000415"
	$tsenv.Value("KeyboardLocale") = "pl-PL"
	$tsenv.Value("SystemLocale") = "pl-PL"
	$tsenv.Value("UserLocale") = "pl-PL"
	$tsenv.Value("TimeZoneName") = "Central European Standard Time"
	$LanguageFound = $true
}
if ($tsenv.Value("OSDOSLanguage") -eq "pt-BR") # Brazil
{
	$tsenv.Value("UILanguage") = "pt-BR"
	$tsenv.Value("InputLocale") = "0416:00000416"
	$tsenv.Value("KeyboardLocale") = "pt-BR"
	$tsenv.Value("SystemLocale") = "pt-BR"
	$tsenv.Value("UserLocale") = "pt-BR"
	$tsenv.Value("TimeZoneName") = "Central Brazilian Standard Time"
	$LanguageFound = $true
}
if ($tsenv.Value("OSDOSLanguage") -eq "ro-RO") # Romania
{
	$tsenv.Value("UILanguage") = "ro-RO"
	$tsenv.Value("InputLocale") = "0418:00010418"
	$tsenv.Value("KeyboardLocale") = "ro-RO"
	$tsenv.Value("SystemLocale") = "ro-RO"
	$tsenv.Value("UserLocale") = "ro-RO"
	$tsenv.Value("TimeZoneName") = "E. Europe Standard Time"
	$LanguageFound = $true
}
if ($tsenv.Value("OSDOSLanguage") -eq "ru-RU") # Russia
{
	$tsenv.Value("UILanguage") = "ru-RU"
	$tsenv.Value("InputLocale") = "0419:00000419"
	$tsenv.Value("KeyboardLocale") = "ru-RU"
	$tsenv.Value("SystemLocale") = "ru-RU"
	$tsenv.Value("UserLocale") = "ru-RU"
	$tsenv.Value("TimeZoneName") = "Russian Standard Time"
	$LanguageFound = $true
}
if ($tsenv.Value("OSDOSLanguage") -eq "sk-SK") # Slovakia
{
	$tsenv.Value("UILanguage") = "sk-SK"
	$tsenv.Value("InputLocale") = "041b:0000041b"
	$tsenv.Value("KeyboardLocale") = "sk-SK"
	$tsenv.Value("SystemLocale") = "sk-SK"
	$tsenv.Value("UserLocale") = "sk-SK"
	$tsenv.Value("TimeZoneName") = "Central European Standard Time"
	$LanguageFound = $true
}
if ($tsenv.Value("OSDOSLanguage") -eq "sv-SE")
{
	$tsenv.Value("UILanguage") = "sv-SE"
	$tsenv.Value("InputLocale") = "041d:0000041d"
	$tsenv.Value("KeyboardLocale") = "sv-SE"
	$tsenv.Value("SystemLocale") = "sv-SE"
	$tsenv.Value("UserLocale") = "sv-SE"
	$tsenv.Value("TimeZoneName") = "W. Europe Standard Time"
	$LanguageFound = $true
}
if ($tsenv.Value("OSDOSLanguage") -eq "tr-TR") # Turkey
{
	$tsenv.Value("UILanguage") = "tr-TR"
	$tsenv.Value("InputLocale") = "041f:0000041f"
	$tsenv.Value("KeyboardLocale") = "tr-TR"
	$tsenv.Value("SystemLocale") = "tr-TR"
	$tsenv.Value("UserLocale") = "tr-TR"
	$tsenv.Value("TimeZoneName") = "GTB Standard Time"
	$LanguageFound = $true
}
if ($tsenv.Value("OSDOSLanguage") -eq "uk-UA") # Ukraine
{
	$tsenv.Value("UILanguage") = "uk-UA"
	$tsenv.Value("InputLocale") = "0422:00020422"
	$tsenv.Value("KeyboardLocale") = "uk-UA"
	$tsenv.Value("SystemLocale") = "uk-UA"
	$tsenv.Value("UserLocale") = "uk-UA"
	$tsenv.Value("TimeZoneName") = "E. Europe Standard Time"
	$LanguageFound = $true
}
if ($tsenv.Value("OSDOSLanguage") -eq "zh-CN") # China
{
	$tsenv.Value("UILanguage") = "zh-CN"
	$tsenv.Value("InputLocale") = "0804:{81D4E9C9-1D3B-41BC-9E6C-4B40BF79E35E}{FA550B04-5AD7-411f-A5AC-CA038EC515D7}"
	$tsenv.Value("KeyboardLocale") = "zh-CN"
	$tsenv.Value("SystemLocale") = "zh-CN"
	$tsenv.Value("UserLocale") = "zh-CN"
	$tsenv.Value("TimeZoneName") = "China Standard Time"
	$LanguageFound = $true
}
if ($tsenv.Value("OSDOSLanguage") -eq "zh-TW") # Taiwan
{
	$tsenv.Value("UILanguage") = "zh-TW"
	$tsenv.Value("InputLocale") = "0404:{B115690A-EA02-48D5-A231-E3578D2FDF80}{B2F9C502-1742-11D4-9790-0080C882687E}"
	$tsenv.Value("KeyboardLocale") = "zh-TW"
	$tsenv.Value("SystemLocale") = "zh-TW"
	$tsenv.Value("UserLocale") = "zh-TW"
	$tsenv.Value("TimeZoneName") = "Taipei Standard Time"
	$LanguageFound = $true
}


# If using Sites in OU structure - base language on first letter of OU
if ($tsenv.Value("OSDUseSiteOU") -eq $true)
{
	Write-Log "Regional settings will be based on OU site ($($tsenv.Value("OSDSite")))"
	
	if ($tsenv.Value("OSDSite") -like "AE*") # United Arab Emirates
	{
		$tsenv.Value("UILanguage") = "en-US"
		$tsenv.Value("InputLocale") = "3801:00000401"
		$tsenv.Value("KeyboardLocale") = "ar-AE"
		$tsenv.Value("SystemLocale") = "ar-AE"
		$tsenv.Value("UserLocale") = "ar-AE"
		$tsenv.Value("TimeZoneName") = "Arabian Standard Time"
		$LanguageFound = $true
	}
	if ($tsenv.Value("OSDSite") -like "AT*") # Austria
	{
		$tsenv.Value("UILanguage") = "de-DE"
		$tsenv.Value("InputLocale") = "0c07:00000407"
		$tsenv.Value("KeyboardLocale") = "de-AT"
		$tsenv.Value("SystemLocale") = "de-AT"
		$tsenv.Value("UserLocale") = "de-AT"
		$tsenv.Value("TimeZoneName") = "Central European Standard Time"
		$LanguageFound = $true
	}
	if ($tsenv.Value("OSDSite") -like "BE*") # Belgium
	{
		$tsenv.Value("UILanguage") = "nl-BE"
		$tsenv.Value("InputLocale") = "0813:00000813"
		$tsenv.Value("KeyboardLocale") = "nl-BE"
		$tsenv.Value("SystemLocale") = "nl-BE"
		$tsenv.Value("UserLocale") = "nl-BE"
		$tsenv.Value("TimeZoneName") = "Central European Standard Time"
		$LanguageFound = $true
	}
	if ($tsenv.Value("OSDSite") -like "BR*") # Brazil
	{
		$tsenv.Value("UILanguage") = "pt-BR"
		$tsenv.Value("InputLocale") = "0416:00000416"
		$tsenv.Value("KeyboardLocale") = "pt-BR"
		$tsenv.Value("SystemLocale") = "pt-BR"
		$tsenv.Value("UserLocale") = "pt-BR"
		$tsenv.Value("TimeZoneName") = "Central Brazilian Standard Time"
		$LanguageFound = $true
	}
	if ($tsenv.Value("OSDSite") -like "CH*") # Switzerland
	{
		$tsenv.Value("UILanguage") = "fr-FR"
		$tsenv.Value("InputLocale") = "100c:0000100c"
		$tsenv.Value("KeyboardLocale") = "fr-CH"
		$tsenv.Value("SystemLocale") = "fr-CH"
		$tsenv.Value("UserLocale") = "fr-CH"
		$tsenv.Value("TimeZoneName") = "Central European Standard Time"
		$LanguageFound = $true
	}
	if ($tsenv.Value("OSDSite") -like "CL*") # Chile
	{
		$tsenv.Value("UILanguage") = "es-ES"
		$tsenv.Value("InputLocale") = "340a:0000080a"
		$tsenv.Value("KeyboardLocale") = "es-CL"
		$tsenv.Value("SystemLocale") = "es-CL"
		$tsenv.Value("UserLocale") = "es-CL"
		$tsenv.Value("TimeZoneName") = "Pacific S.A. Standard Time"
		$LanguageFound = $true
	}
	if ($tsenv.Value("OSDSite") -like "CN*") # China
	{
		$tsenv.Value("UILanguage") = "zh-CN"
		$tsenv.Value("InputLocale") = "0804:{81D4E9C9-1D3B-41BC-9E6C-4B40BF79E35E}{FA550B04-5AD7-411f-A5AC-CA038EC515D7}"
		$tsenv.Value("KeyboardLocale") = "zh-CN"
		$tsenv.Value("SystemLocale") = "zh-CN"
		$tsenv.Value("UserLocale") = "zh-CN"
		$tsenv.Value("TimeZoneName") = "China Standard Time"
		$LanguageFound = $true
	}
	if ($tsenv.Value("OSDSite") -like "CZ*") # Czech Republic
	{
		$tsenv.Value("UILanguage") = "cs-CZ"
		$tsenv.Value("InputLocale") = "0405:00000405"
		$tsenv.Value("KeyboardLocale") = "cs-CZ"
		$tsenv.Value("SystemLocale") = "cs-CZ"
		$tsenv.Value("UserLocale") = "cs-CZ"
		$tsenv.Value("TimeZoneName") = "Central European Standard Time"
		$LanguageFound = $true
	}
	if ($tsenv.Value("OSDSite") -like "DK*") # Denmark
	{
		$tsenv.Value("UILanguage") = "da-DK"
		$tsenv.Value("InputLocale") = "0406:00000406"
		$tsenv.Value("KeyboardLocale") = "da-DK"
		$tsenv.Value("SystemLocale") = "da-DK"
		$tsenv.Value("UserLocale") = "da-DK"
		$tsenv.Value("TimeZoneName") = "Romance Standard Time"
		$LanguageFound = $true
	}
	if ($tsenv.Value("OSDSite") -like "DE*") # Germany
	{
		$tsenv.Value("UILanguage") = "de-DE"
		$tsenv.Value("InputLocale") = "0407:00000407"
		$tsenv.Value("KeyboardLocale") = "de-DE"
		$tsenv.Value("SystemLocale") = "de-DE"
		$tsenv.Value("UserLocale") = "de-DE"
		$tsenv.Value("TimeZoneName") = "W. Europe Standard Time"
		$LanguageFound = $true
	}
	if ($tsenv.Value("OSDSite") -like "ES*") # Spain
	{
		$tsenv.Value("UILanguage") = "es-ES"
		$tsenv.Value("InputLocale") = "040a:0000040a"
		$tsenv.Value("KeyboardLocale") = "es-ES"
		$tsenv.Value("SystemLocale") = "es-ES"
		$tsenv.Value("UserLocale") = "es-ES"
		$tsenv.Value("TimeZoneName") = "Romance Standard Time"
		$LanguageFound = $true
	}
	if ($tsenv.Value("OSDSite") -like "FI*") # Finland
	{
		$tsenv.Value("UILanguage") = "fi-FI"
		$tsenv.Value("InputLocale") = "040b:0000040b"
		$tsenv.Value("KeyboardLocale") = "fi-FI"
		$tsenv.Value("SystemLocale") = "fi-FI"
		$tsenv.Value("UserLocale") = "fi-FI"
		$tsenv.Value("TimeZoneName") = "FLE Standard Time"
		$LanguageFound = $true
	}
	if ($tsenv.Value("OSDSite") -like "FR*") # France
	{
		$tsenv.Value("UILanguage") = "fr-FR"
		$tsenv.Value("InputLocale") = "040c:0000040c"
		$tsenv.Value("KeyboardLocale") = "fr-FR"
		$tsenv.Value("SystemLocale") = "fr-FR"
		$tsenv.Value("UserLocale") = "fr-FR"
		$tsenv.Value("TimeZoneName") = "Romance Standard Time"
		$LanguageFound = $true
	}
	if ($tsenv.Value("OSDSite") -like "GB*") # Great Britain
	{
		$tsenv.Value("UILanguage") = "en-GB"
		$tsenv.Value("InputLocale") = "0809:00000809"
		$tsenv.Value("KeyboardLocale") = "en-GB"
		$tsenv.Value("SystemLocale") = "en-GB"
		$tsenv.Value("UserLocale") = "en-GB"
		$tsenv.Value("TimeZoneName") = "GMT Standard Time"
		$LanguageFound = $true
	}
	if ($tsenv.Value("OSDSite") -like "HU*") # Hungary
	{
		$tsenv.Value("UILanguage") = "hu-HU"
		$tsenv.Value("InputLocale") = "040e:0000040e"
		$tsenv.Value("KeyboardLocale") = "hu-HU"
		$tsenv.Value("SystemLocale") = "hu-HU"
		$tsenv.Value("UserLocale") = "hu-HU"
		$tsenv.Value("TimeZoneName") = "Central European Standard Time"
		$LanguageFound = $true
	}
	if ($tsenv.Value("OSDSite") -like "IN*") # India
	{
		$tsenv.Value("UILanguage") = "en-IN"
		$tsenv.Value("InputLocale") = "4009:00004009"
		$tsenv.Value("KeyboardLocale") = "en-IN"
		$tsenv.Value("SystemLocale") = "en-IN"
		$tsenv.Value("UserLocale") = "en-IN"
		$tsenv.Value("TimeZoneName") = "India Standard Time"
		$LanguageFound = $true
	}
	if ($tsenv.Value("OSDSite") -like "IT*") # Italy
	{
		$tsenv.Value("UILanguage") = "it-IT"
		$tsenv.Value("InputLocale") = "0410:00000410"
		$tsenv.Value("KeyboardLocale") = "it-IT"
		$tsenv.Value("SystemLocale") = "it-IT"
		$tsenv.Value("UserLocale") = "it-IT"
		$tsenv.Value("TimeZoneName") = "W. Europe Standard Time"
		$LanguageFound = $true
	}
	if ($tsenv.Value("OSDSite") -like "JP*") # Japan
	{
		$tsenv.Value("UILanguage") = "ja-JP"
		$tsenv.Value("InputLocale") = "0411:{03B5835F-F03C-411B-9CE2-AA23E1171E36}{A76C93D9-5523-4E90-AAFA-4DB112F9AC76}"
		$tsenv.Value("KeyboardLocale") = "ja-JP"
		$tsenv.Value("SystemLocale") = "ja-JP"
		$tsenv.Value("UserLocale") = "ja-JP"
		$tsenv.Value("TimeZoneName") = "Tokyo Standard Time"
		$LanguageFound = $true
	}
	if ($tsenv.Value("OSDSite") -like "KR*") # Korea
	{
		$tsenv.Value("UILanguage") = "ko-KR"
		$tsenv.Value("InputLocale") = "0x00000412"
		$tsenv.Value("KeyboardLocale") = "ko-KR"
		$tsenv.Value("SystemLocale") = "ko-KR"
		$tsenv.Value("UserLocale") = "ko-KR"
		$tsenv.Value("TimeZoneName") = "Korea Standard Time"
		$LanguageFound = $true
	}
	if ($tsenv.Value("OSDSite") -like "LV*") # Latvia
	{
		$tsenv.Value("UILanguage") = "lv-LV"
		$tsenv.Value("InputLocale") = "0426:00020426"
		$tsenv.Value("KeyboardLocale") = "lv-LV"
		$tsenv.Value("SystemLocale") = "lv-LV"
		$tsenv.Value("UserLocale") = "lv-LV"
		$tsenv.Value("TimeZoneName") = "E. Europe Standard Time"
		$LanguageFound = $true
	}
	if ($tsenv.Value("OSDSite") -like "MX*") # Mexico
	{
		$tsenv.Value("UILanguage") = "es-MX"
		$tsenv.Value("InputLocale") = "080a:0000080a"
		$tsenv.Value("KeyboardLocale") = "es-MX"
		$tsenv.Value("SystemLocale") = "es-MX"
		$tsenv.Value("UserLocale") = "es-MX"
		$tsenv.Value("TimeZoneName") = "Central Standard Time"
		$LanguageFound = $true
	}
	if ($tsenv.Value("OSDSite") -like "NL*") # Netherlands
	{
		$tsenv.Value("UILanguage") = "nl-NL"
		$tsenv.Value("InputLocale") = "0409:00020409"
		$tsenv.Value("KeyboardLocale") = "nl-NL"
		$tsenv.Value("SystemLocale") = "nl-NL"
		$tsenv.Value("UserLocale") = "nl-NL"
		$tsenv.Value("TimeZoneName") = "W. Europe Standard Time"
		$LanguageFound = $true
	}
	if ($tsenv.Value("OSDSite") -like "NO*") # Norway
	{
		$tsenv.Value("UILanguage") = "nb-NO"
		$tsenv.Value("InputLocale") = "0414:00000414"
		$tsenv.Value("KeyboardLocale") = "nb-NO"
		$tsenv.Value("SystemLocale") = "nb-NO"
		$tsenv.Value("UserLocale") = "nb-NO"
		$tsenv.Value("TimeZoneName") = "W. Europe Standard Time"
		$LanguageFound = $true
	}
	if ($tsenv.Value("OSDSite") -like "PL*") # Poland
	{
		$tsenv.Value("UILanguage") = "pl-PL"
		$tsenv.Value("InputLocale") = "0415:00000415"
		$tsenv.Value("KeyboardLocale") = "pl-PL"
		$tsenv.Value("SystemLocale") = "pl-PL"
		$tsenv.Value("UserLocale") = "pl-PL"
		$tsenv.Value("TimeZoneName") = "Central European Standard Time"
		$LanguageFound = $true
	}
	if ($tsenv.Value("OSDSite") -like "RO*") # Romania
	{
		$tsenv.Value("UILanguage") = "ro-RO"
		$tsenv.Value("InputLocale") = "0418:00010418"
		$tsenv.Value("KeyboardLocale") = "ro-RO"
		$tsenv.Value("SystemLocale") = "ro-RO"
		$tsenv.Value("UserLocale") = "ro-RO"
		$tsenv.Value("TimeZoneName") = "E. Europe Standard Time"
		$LanguageFound = $true
	}
	if ($tsenv.Value("OSDSite") -like "RU*") # Russia
	{
		$tsenv.Value("UILanguage") = "ru-RU"
		$tsenv.Value("InputLocale") = "0419:00000419"
		$tsenv.Value("KeyboardLocale") = "ru-RU"
		$tsenv.Value("SystemLocale") = "ru-RU"
		$tsenv.Value("UserLocale") = "ru-RU"
		$tsenv.Value("TimeZoneName") = "Russian Standard Time"
		$LanguageFound = $true
	}
	if ($tsenv.Value("OSDSite") -like "SE*") # Sweden
	{
		$tsenv.Value("UILanguage") = "sv-SE"
		$tsenv.Value("InputLocale") = "041d:0000041d"
		$tsenv.Value("KeyboardLocale") = "sv-SE"
		$tsenv.Value("SystemLocale") = "sv-SE"
		$tsenv.Value("UserLocale") = "sv-SE"
		$tsenv.Value("TimeZoneName") = "W. Europe Standard Time"
		$LanguageFound = $true
	}
	if ($tsenv.Value("OSDSite") -like "SK*") # Slovakia
	{
		$tsenv.Value("UILanguage") = "sk-SK"
		$tsenv.Value("InputLocale") = "041b:0000041b"
		$tsenv.Value("KeyboardLocale") = "sk-SK"
		$tsenv.Value("SystemLocale") = "sk-SK"
		$tsenv.Value("UserLocale") = "sk-SK"
		$tsenv.Value("TimeZoneName") = "Central European Standard Time"
		$LanguageFound = $true
	}
	if ($tsenv.Value("OSDSite") -like "TR*") # Turkey
	{
		$tsenv.Value("UILanguage") = "tr-TR"
		$tsenv.Value("InputLocale") = "041f:0000041f"
		$tsenv.Value("KeyboardLocale") = "tr-TR"
		$tsenv.Value("SystemLocale") = "tr-TR"
		$tsenv.Value("UserLocale") = "tr-TR"
		$tsenv.Value("TimeZoneName") = "GTB Standard Time"
		$LanguageFound = $true
	}
	if ($tsenv.Value("OSDSite") -like "TW*") # Taiwan
	{
		$tsenv.Value("UILanguage") = "zh-TW"
		$tsenv.Value("InputLocale") = "0404:{B115690A-EA02-48D5-A231-E3578D2FDF80}{B2F9C502-1742-11D4-9790-0080C882687E}"
		$tsenv.Value("KeyboardLocale") = "zh-TW"
		$tsenv.Value("SystemLocale") = "zh-TW"
		$tsenv.Value("UserLocale") = "zh-TW"
		$tsenv.Value("TimeZoneName") = "Taipei Standard Time"
		$LanguageFound = $true
	}
	if ($tsenv.Value("OSDSite") -like "UA*") # Ukraine
	{
		$tsenv.Value("UILanguage") = "uk-UA"
		$tsenv.Value("InputLocale") = "0422:00020422"
		$tsenv.Value("KeyboardLocale") = "uk-UA"
		$tsenv.Value("SystemLocale") = "uk-UA"
		$tsenv.Value("UserLocale") = "uk-UA"
		$tsenv.Value("TimeZoneName") = "E. Europe Standard Time"
		$LanguageFound = $true
	}
	if ($tsenv.Value("OSDSite") -like "USBS*") # US Blue Springs
	{
		$tsenv.Value("UILanguage") = "en-US"
		$tsenv.Value("InputLocale") = "0409:00000409"
		$tsenv.Value("KeyboardLocale") = "en-US"
		$tsenv.Value("SystemLocale") = "en-US"
		$tsenv.Value("UserLocale") = "en-US"
		$tsenv.Value("TimeZoneName") = "Central Standard Time"
		$LanguageFound = $true
	}
	if ($tsenv.Value("OSDSite") -like "USCHI*") # US Chicago
	{
		$tsenv.Value("UILanguage") = "en-US"
		$tsenv.Value("InputLocale") = "0409:00000409"
		$tsenv.Value("KeyboardLocale") = "en-US"
		$tsenv.Value("SystemLocale") = "en-US"
		$tsenv.Value("UserLocale") = "en-US"
		$tsenv.Value("TimeZoneName") = "Central Standard Time"
		$LanguageFound = $true
	}
	if ($tsenv.Value("OSDSite") -like "USKC*") # US Kansas City
	{
		$tsenv.Value("UILanguage") = "en-US"
		$tsenv.Value("InputLocale") = "0409:00000409"
		$tsenv.Value("KeyboardLocale") = "en-US"
		$tsenv.Value("SystemLocale") = "en-US"
		$tsenv.Value("UserLocale") = "en-US"
		$tsenv.Value("TimeZoneName") = "Central Standard Time"
		$LanguageFound = $true
	}
	if ($tsenv.Value("OSDSite") -like "USMA*") # US Marion
	{
		$tsenv.Value("UILanguage") = "en-US"
		$tsenv.Value("InputLocale") = "0409:00000409"
		$tsenv.Value("KeyboardLocale") = "en-US"
		$tsenv.Value("SystemLocale") = "en-US"
		$tsenv.Value("UserLocale") = "en-US"
		$tsenv.Value("TimeZoneName") = "Central Standard Time"
		$LanguageFound = $true
	}
	if ($tsenv.Value("OSDSite") -like "USMCI*") # US Detroit
	{
		$tsenv.Value("UILanguage") = "en-US"
		$tsenv.Value("InputLocale") = "0409:00000409"
		$tsenv.Value("KeyboardLocale") = "en-US"
		$tsenv.Value("SystemLocale") = "en-US"
		$tsenv.Value("UserLocale") = "en-US"
		$tsenv.Value("TimeZoneName") = "Eastern Standard Time"
		$LanguageFound = $true
	}
	if ($tsenv.Value("OSDSite") -like "USPHX*") # US Phoenix
	{
		$tsenv.Value("UILanguage") = "en-US"
		$tsenv.Value("InputLocale") = "0409:00000409"
		$tsenv.Value("KeyboardLocale") = "en-US"
		$tsenv.Value("SystemLocale") = "en-US"
		$tsenv.Value("UserLocale") = "en-US"
		$tsenv.Value("TimeZoneName") = "Mountain Standard Time"
		$LanguageFound = $true
	}
	if ($tsenv.Value("OSDSite") -like "USJT*") # US Johnstown
	{
		$tsenv.Value("UILanguage") = "en-US"
		$tsenv.Value("InputLocale") = "0409:00000409"
		$tsenv.Value("KeyboardLocale") = "en-US"
		$tsenv.Value("SystemLocale") = "en-US"
		$tsenv.Value("UserLocale") = "en-US"
		$tsenv.Value("TimeZoneName") = "Eastern Standard Time"
		$LanguageFound = $true
	}
	if ($tsenv.Value("OSDSite") -like "USSC*") # US Stony Creek
	{
		$tsenv.Value("UILanguage") = "en-US"
		$tsenv.Value("InputLocale") = "0409:00000409"
		$tsenv.Value("KeyboardLocale") = "en-US"
		$tsenv.Value("SystemLocale") = "en-US"
		$tsenv.Value("UserLocale") = "en-US"
		$tsenv.Value("TimeZoneName") = "Eastern Standard Time"
		$LanguageFound = $true
	}
	
}

# If UI Language was blank NOT blank from TS - UI language forced to TS value
if (($UILanguage -ne $null) -and ($UILanguage.Length -gt 3))
{
	Write-Log "UI Language from TS is set: $UILanguage, will be forced."
	$tsenv.Value("UILanguage") = $UILanguage
}
else
{
	$UILanguage = $tsenv.Value("UILanguage")
	Write-Log "UI Language from TS blank, calculated value: $UILanguage"
}

$OSLanguage = $tsenv.Value("OSDOSLanguage")
$InputLocale = $tsenv.Value("InputLocale")
$KeyboardLocale = $tsenv.Value("KeyboardLocale")
$SystemLocale = $tsenv.Value("SystemLocale")
$UserLocale = $tsenv.Value("UserLocale")
$TimeZoneName = $tsenv.Value("TimeZoneName")
$UILanguage = $tsenv.Value("UILanguage")

if ($TimeZoneName.Length -gt 5)
{
	Write-Log "OSDOSLanguage:  $OSLanguage"
	Write-Log "InputLocale:    $InputLocale"
	Write-Log "KeyboardLocale: $KeyboardLocale"
	Write-Log "SystemLocale:   $SystemLocale"
	Write-Log "UserLocale:     $UserLocale"
	Write-Log "TimeZoneName:   $TimeZoneName"
	Write-Log "UILanguage:     $UILanguage"
}
else
{
	Write-Log "Error: OSDOSLanguage chosen ($OSLanguage) is not configured, please add to script and content to image"
}
