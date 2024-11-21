
 --CONTENTS--
 1 - Installation Instructions
 2 - Flash under Operating System
 3 - Flash Program Options
 4 - Flashing Back to an Older Level of BIOS
 5 - Delaying Reboot in BIOS Update
 6 - AMIDEWIN - AMI SMBIOS Editor for Windows


*****************************************************************************
*                       1. Installation Instructions                        *
*                                                                           *
*     Please print out these instructions or write them down before         *
*     starting this flash update utility.                                   *
*                                                                           *
*     This flash under operating system (32-bit/64-bit) utility provides    *
*     the ability to update the system BIOS from a Windows application.     *
*                                                                           *
*     The utility may be downloaded from the internet and unpacked into     *
*     the default path: "C:\SWTOOLS\FLASH\FWJYnnUSA", where "nn"            *
*     represents the two-digit BIOS level. Please follow steps in           *
*     section 2 to launch the Windows based flash application to update     *
*     your system BIOS.                                                     *
*                                                                           *
*****************************************************************************


*****************************************************************************
*                     2. Flash Under Operating System                       *
*                                                                           *
*     1.  Please make note of any settings you have changed in the BIOS     *
*         Setup utility. They may have to be re-entered after updating      *
*         the BIOS.                                                         *
*                                                                           *
*     2.  Click on the Start button and type cmd.exe,  Right-click on       *
*         the cmd.exe application and select run as administrator to        *
*         open the Command Prompt with Administrator privilege.             *
*                                                                           *
*     3.  In the "Command Prompt" window, change to the directory where the *
*         above files were extracted.  The command to go to the location is *
*         "cd C:\SWTOOLS\FLASH\FWJYnnUSA", where "nn" represents the two   *
*         digit flash level.                                                *
*                                                                           *
*     4.  Enter the command "flash.cmd" and press the Enter key to start    *
*         the flashing process.                                             *
*                                                                           *
*     5.  You may first see a confirmation prompt "Proceed with BIOS        *
*         update now?". Click "Yes" to continue.                            *
*                                                                           *
*     6.  You will see the prompt "Would you like to update the Serial      *
*         Number?". Input "n" and press Enter.                              *
*                                                                           *
*     7.  Then you will see the prompt "Would you like to update the        *
*         Machine Type and Model?". Input "n" and press Enter again.        *
*         Then the BIOS update process will start.                          *
*                                                                           *
*     8.  The update may take up to 2 minutes. Do not power off or restart  *
*         the system during this procedure! After the Windows update        *
*         process ends, the system will automatically reboot to continue    *
*         the flash process.                                                *
*                                                                           *
*     9.  After the system reboots, the BIOS update process will continue   *
*         with a simple graphic UI. When the BIOS update process ends,      *
*         the system will reboot automatically.                             *
*                                                                           *
*    10.  The BIOS update process ends with above nine steps.               *
*                                                                           *
*     Notes:                                                                * 
*           - You may see a POST error "0162: Setup data integrity check    *
*         failure" after step 9.Press F1 to enter BIOS Setup Utility,       *
*         and then press F10 to save your settings                          *
*****************************************************************************


*****************************************************************************
*                          3. Flash Program Options                         *
*                                                                           *
*     To deploy this application, please open the Windows Command Prompt    *
*     with Administrator privilege. Then run "FWJYnnUSA.EXE -s -e"          *
*     to unpack the installation files into the default path:               *
*     "C:\SWTOOLS\FLASH\FWJYnnUSA". After that, run "flash.cmd /quiet"      *
*     to start the update process. If you like to customize the update      *
*     options, please edit the wflash2.exe command line in the flash.cmd    *
*     file to make changes to the flash program options.                    *
*     Note that "flash64.cmd" and wflash2x64.exe are provided to be used    *
*     in an environment without WOW64 support such as Windows               *
*     Preinstallation Environment (Windows PE) 64bit.                       *
*                                                                           *
*     Command options:                                                      *
*                                                                           *
*     wflash2.exe [option1] [option2] ... [optionX]                         *
*                                                                           *
*     [OPTIONS]                                                             *
*     /h               Show help messages.                                  *
*     /rsmb            Preserve all SMBIOS structures.                      *
*     /clr             Clear BIOS settings.                                 *
*     /ign             Ignore BIOS version check.                           *
*     /sccm            Support SCCM deployment                              *
*                        - see "Delaying Reboot in BIOS Update" below.      *
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
*     /pass:nnnnnnn    Input current system password.                       *
*     /quiet           Operating without physical presence.                 *
*     /autobin         Used to support multiple systems from one BIOS       *
*                      folder. Before using this option, please copy the    *
*                      BIOS bin or rom files from the different BIOS        *
*                      packages into the one folder where the BIOS update   *
*                      is located. This one BIOS update folder could        *
*                      contain multiple BIOS images in addition to the      *
*                      existing flash program files including:              *
*                      imageFW.bin, imageFV.bin, imageM05.bin.              *
*                      This example would support M900, M800z, and M700     *
*                                                                           *
*     The following example shows how to update system asset tag number     *
*     to "1234567" use command line:                                        *
*       wflash2.exe /tag:1234567                                            *
*                                                                           *
*     The following example shows how to update bios and update system      *
*     asset tag number by one command:                                      *
*       wflash2.exe imagefw.rom /tag:1234567                                *
*          Or                                                               *
*       wflash2.exe /tag:1234567 /autobin                                   *
*                                                                           *
*     The following example shows how to change the power-on logo.          *
*       wflash2.exe /logo:myfav.bmp                                         *
*                                                                           *
*     Notes:                                                                * 
*           - A flash update image using these program options should be    *
*           tested carefully before widespread usage.                       *
*           - wflash2x64.exe's options are the same as wflash2.exe          *
*                                                                           *
*****************************************************************************


*****************************************************************************
*                 4. Flashing Back to an Older Level of BIOS                *
*                                                                           *
*     In order to flash back to an older level of BIOS, the following       *
*     steps should be used to insure the latest flash utility is used.      *
*                                                                           *
*     1.  Obtain the older level and latest level BIOS update programs      *
*         from the Lenovo website.                                          *
*     2.  Use the method described in section 3 to unpack the program into  *
*         "C:\SWTOOLS\FLASH\FWJYnnUSA".                                     *
*     3.  Copy imagefw.rom from the older BIOS update program folder,       *
*         paste it and replace the same file in the latest level BIOS       *
*         update program folder.                                            *
*     4.  In the latest level BIOS update program folder, run flash.cmd     *
*         to flash back to an older level BIOS.                             *
*                                                                           *
*****************************************************************************


*****************************************************************************
*                     5. Delaying Reboot in BIOS Update                     *
*                                                                           *
*     The BIOS update process consists of two phases. The first phase       *
*     happens in the OS. After the first flashing phase is complete, the    *
*     system will automatically reboot to perform the secondary             *
*     BIOS update phase.                                                    *
*                                                                           *
*     /sccm is designed for BIOS update deployment when the administrator   *
*     wants to manually control the system reboot after first BIOS phase    *
*     update has finished. With the parameter "/sccm", the system won't     *
*     reboot immediately after applying the first phase of the BIOS update. *
*     The administrator must SHUTDOWN the system later to trigger the       *
*     secondary phase of the BIOS update.                                   *
*                                                                           *
*     Important Notes:                                                      *
*                                                                           *
*     1. After the first phase of the BIOS update is complete, the          *
*        administrator must SHUTDOWN the system to trigger the secondary    *
*        phase. A reboot instead of a shutdown won't work.                  *
*     2. The shutdown mentioned in Note 1 must be an actual                 *
*        S5 (System Power Off). The default shutdown behavior in            *
*        modern OS (WIN8/WIN8.1/WIN10 etc.) is S4 (Hibernate). To change    *
*        these modern OS shutdown behavior to S5, you need to turn off      *
*        the "Fast Startup" from "Control Panel -> Power options". If your  *
*        deployment software supports S5 shutdown, you can send a sleep S5  *
*        command by software to trigger the secondary BIOS update phase.    *
*     3. If the system is not shut down using the S5 shutdown, the flash    *
*        process will not continue, and will need to be restarted from      *
*        phase 1.                                                           *
*                                                                           *
*     The following example shows how to use /sccm to implement first phase *
*     BIOS update with deployment software:                                 *
*                                                                           *
*        flash.cmd /quiet /sccm                                             *
*                                                                           *
*****************************************************************************


*****************************************************************************
*                 6. AMIDEWIN - AMI SMBIOS Editor for Windows               *
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
*****************************************************************************