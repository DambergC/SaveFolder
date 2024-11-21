
 --CONTENTS--
 1 - Installation Instructions
 2 - Flash under Operating System
 3 - Flash Program Options
 4 - Flashing Back to an Older Level of BIOS
 5 - AMIDEWIN - AMIBIOS DMI Editor for Windows

Note:
1. ReadGPIO.exe and SPIW032.exe are secure, and please don't delete them.
2. If you receive a 0211 error "keyboard not found" then:
    2.1. Move the keyboard from the USB port that it is in to another USB port.
    2.2. Apply BIOS 73A or higher.
    2.3. After BIOS update, you can move the keyboard back to its original USB port.


*****************************************************************************
*                       1. Installation Instructions                        *
*                                                                           *
*     Please print out these instructions or write them down before         *
*     starting this flash update utility.                                   *
*                                                                           *
*     This flash under operating system (32-bit/64-bit) utility provides    *
*     the ability to update the system flash from a windows application.    *
*                                                                           *
*     The utility may be downloaded from the internet and unpacked into     *
*     the default path: "C:\SWTOOLS\FLASH\FBJYxxUSA", where "xx"            *
*     represents the two digit flash level. After unpacking the utility,    *
*     please follow steps in section 2 to launch the windows based flash    *
*     application to update your system.                                    *
*                                                                           *
*****************************************************************************


*****************************************************************************
*                     2. Flash Under Operating System                       *
*                                                                           *
*     1.  Please make note of any settings you have changed in the BIOS     *
*         Setup utility. They may have to be re-entered after updating      *
*         the BIOS.                                                         *
*                                                                           *
*     2.  Open folder "C:\Windows\System32", locate the file "cmd.exe".     *
*         Right-click on this application, select "Run as administrator"    *
*         to open the "Command Prompt" with Administrator privilege.        *
*                                                                           *
*     3.  Input command "cd C:\SWTOOLS\FLASH\FBJYxxUSA\", where "xx"        *
*         represents the two digit flash level.                             *
*                                                                           *
*     4.  Then input command "flash.cmd" to start flash process.            *
*                                                                           *
*     5.  You will see the prompt "Would you like to update the Serial      *
*         Number?". Input "n" and press Enter.                              *
*                                                                           *
*     6.  Then you will see the prompt "Would you like to update the        *
*         Machine Type and Model?". Input "n" and press Enter again.        *
*         Then the BIOS update process will start.                          *
*                                                                           *
*     7.  Update may take up to 2 minutes. Do not power off or restart      *
*         the system during this procedure! After Windows update process    *
*         ends, the system will automatically reboot to continue the flash  *
*         process.                                                          *
*                                                                           *
*     8.  After system reboot, the BIOS update process will continue with   *
*         a graphic UI. When the BIOS update process ends, the system       *
*         will reboot automatically.                                        *
*                                                                           *
*     9.  You may see a POST error "0162: Setup data integrity check        *
*         failure" after reboot. It is a normal behavior. Press F1 to       *
*         enter BIOS Setup Utility. If you are using WIN8 64-bit OS,        *
*         change the Exit->OS Optimized Defaults to "Enabled", otherwise,   *
*         please change it to "Disabled". At last, press F10 to save        *
*         your settings.                                                    *
*                                                                           *
*     10. The BIOS update process ends with the above nine steps.           *
*                                                                           *
*****************************************************************************


*****************************************************************************
*                          3. Flash Program Options                         *
*                                                                           *
*     wflash2.exe [option1] [option2] ... [optionX]                         *
*                                                                           *
*     [OPTIONS]                                                             *
*     /h               Show help messages.                                  *
*     /rsmb            Preserve all SMBIOS structures.                      *
*     /clr             Clear BIOS settings.                                 *
*     /ign             Ingore BIOS version check.                           *
*     /sn:nnnnnnn      Update system serial number (up to 20 characters).   *
*     /csn:nnnnnnn     Update chassis serial number (up to 20 characters).  *
*     /mtm:nnnnnnn     Update machine type and model number (up to 25       *
*                      characters).                                         *
*     /tag:nnnnnnn     Update system asset tag (up to 25 characters).       *
*     /uuid            The flash utility will generate an Universally       *
*                      Unique Identifier (UUID), replacing the one that     *
*                      is currently in the system.                          *
*     /logo:<filename> Change logo. The max supported size of logo file     *
*                      is displayed on the screen during the compressing.   *
*     /cpu             Update Intel CPU microcode.                          *
*     /reboot          Automatic reboot after all requests done.            *
*     /pass:nnnnnnn    Input current system password.                       *
*     /quiet           Operating without physical presence.                 *
*                                                                           *
*     The following example shows how to update system asset tag number     *
*     to "1234567" use command line:                                        *
*       wflash2.exe /tag:1234567                                            *
*                                                                           *
*     The following example shows how to update bios and update system      *
*     asset tag number by one command:                                      *
*       wflash2.exe bios.rom /tag:1234567                                   *
*                                                                           *
*     The following example shows how to change the power-on logo.          *
*       wflash2.exe /logo:myfav.bmp                                         *
*                                                                           *
*     Note: A flash update image using these program options should be      *
*           tested carefully before widespread usage.                       *
*                                                                           *
*****************************************************************************


*****************************************************************************
*                 4. Flashing Back to an Older Level of BIOS                *
*                                                                           *
*     In order to flash back to an older level of BIOS, the following       *
*     steps should be used to insure the latest flash utility is used.      *
*                                                                           *
*     1.  Obtain the latest level of BIOS update program from the Lenovo    *
*         web site.                                                         *
*     2.  Copy wflash2.exe, lecrud.sys, lecrud64.sys, afuwin.exe,           *
*         amifldrv32.sys, amifldrv64.sys, Ucoredll.dll, AMIDEWIN.exe,       *
*         UCORESYS.sys, UCOREW64.sys and Flash.cmd                          *
*         from the latest bios update program folder to the older level     *
*         bios update program folder. Replace the same files in the older   *
*         level bios update program folder.                                 *
*     3.  Follow steps in section 2 to flash back to an older level BIOS.   *
*                                                                           *
*****************************************************************************


*****************************************************************************
*                 5. AMIDEWIN - AMIBIOS DMI Editor for Windows              *
*                                                                           *
*     AMIDEWIN.exe [option1] [option2] ... [optionX]                        *
*                                                                           *
*     Options:                                                              *
*     /SP  "String" 	Update the System Machine Type and Model Number.    *
*     /SS  "String" 	Update the System Serial Number.                    *
*     /CS  "String"     Update the Chassis Serial Number.                   *
*     /SU  auto         Update the System UUID.                             *
*     /SV  "String"     update the System Brand ID.                         *
*     /CA  "String"     update the Chassis Asset Tag Number.                *
*                                                                           *
*                                                                           *
*****************************************************************************