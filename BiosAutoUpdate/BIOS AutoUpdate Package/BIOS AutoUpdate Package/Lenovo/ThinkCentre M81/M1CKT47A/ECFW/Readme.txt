*.System Requirements
  .Operating System: Windows 7 x86/x64, Windows 8 x86/x64
  .Software Requirement: Microsoft .Net Framework 4.0

//-------------------------------------------------------------------------------------------------
// Program/Dump eSIO firmware
//-------------------------------------------------------------------------------------------------
*.Update Options: Use eSIO_Utility.exe to update *.xml for options.

*.Program/Dump step:
  .Open command prompt with Administrator privilege.
  .View help       "eSIO_Flash.exe /?"
  .Program Image   "eSIO_Flash.exe /p:FileName"
  .Dump Image      "eSIO_Flash.exe /d:FileName"
  .Show Version    "eSIO_Flash.exe /v"

*. Return Code
  .A return code of 0 indicates success. Any other return code indicates failure.

//-------------------------------------------------------------------------------------------------
// DP Refresher
//-------------------------------------------------------------------------------------------------
*.Update Options: Use eSIO_Utility.exe to update *.xml for options.

*.Program/Dump step:
  .Open command prompt with Administrator privilege.
  .Program Scaler FW               "eSIO_Utility.exe /DP-S-P filename"
  .Dump Scaler FW                  "eSIO_Utility.exe /DP-S-D filename"
  
  .Program HDMI/DVI EDID           "eSIO_Utility.exe /DP-HDMI-P filename"
  .Dump HDMI/DVI EDID (256 bytes)  "eSIO_Utility.exe /DP-HDMI-D filename"
  
  .Program DP EDID                 "eSIO_Utility.exe /DP-DP-P filename"
  .Dump DP EDID (256 bytes)        "eSIO_Utility.exe /DP-DP-D filename"
  
  .Show Version                    "eSIO_Utility.exe /DP-V -V:DP -V:HDMI"
    . Save eSIO and Scaler version to file ver.txt
       (NCT6681 eSIO version: Page3, Index 0x00 ~ 0x0F)
       (NCT6683 eSIO version: Page6, Index 0x00 ~ 0x1F)
    . -V:DP     Save DP_EDID version to file ver.txt
    . -V:HDMI   Save HDMI_DVI_EDID version to file ver.txt

//-------------------------------------------------------------------------------------------------
// CfgESIO.xml: <CfgESIO Args="">
//-------------------------------------------------------------------------------------------------
  Args="troy"
    *. Display a window to show DP Scaler and eSIO version for Wistron

  Args="troy0"
    *. Save eSIO version and Scaler version to file ver.txt
    *. Dump DP_EDID to file ver_DP_EDID.bin
    *. Dump HDMI_DVI_EDID to file ver_HDMI_DVI_EDID.bin

  Args="esio -v1"
    *. Save eSIO version and OEM version to file ver.txt

//-------------------------------------------------------------------------------------------------
// DBG Device
//-------------------------------------------------------------------------------------------------
*.Function Pin Configuration
  Switch          | Debug Interface | SPI_1        | PB0/RX0, PB1/TX0
  ---------------------------------------------------------------------------------
	Reset           | GPIO IN         | Config SPI_1 | UART
	SPI             | Config SPI_0    |              | GPIO IN
	JTAG            | GPIO            |              | GPIO IN
	UART/UART_Reset | GPIO IN         |              | UART
	KM/KM_Reset     | GPIO IN         |              | GPIO IN
	SPI Switch      | GPIO IN         |              | GPIO IN

*.Program Debug Code to Flash
  BTN_0: Short Press BTN_0 to start programming debug code to flash.
		step1: Get Flash ID to retrieve capacity
		step2: Chip Erase
		step3: Start programming debug code to flash
  LED_0:
		Flash once after programming some bytes to flash.
		Blinking(3Hz)/2 times ¡V 1sec off ¡V loop: Identify failed
		Blinking(3Hz)/3 times ¡V 1sec off ¡V loop: Get Status Register failed
		Blinking(3Hz)/4 times ¡V 1sec off ¡V loop: Chip Erase
		Blinking(3Hz)/5 times ¡V 1sec off ¡V loop: Data Full	

*.Switch Debug Interface
  LED_1: Solid On to indicate pin status of Debug Interface is error. (must pull high)
