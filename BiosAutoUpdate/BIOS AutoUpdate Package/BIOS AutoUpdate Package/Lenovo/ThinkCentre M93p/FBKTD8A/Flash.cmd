@echo off
ReadGPIO.exe
if errorlevel 15 goto message
if not errorlevel 15 goto flashBIOS
:message
echo *** Your Embedded Controller Firmware is being updated.The BIOS update will continue after the firmware update completes.Please do not turn the system off while the updates are in progress***
SPIW0323.exe FBCT32A.bin /V 29A

:flashBIOS
wflash2.exe imagefb.rom /bb /rsmb %1
echo ***These changes will not take effect until the system is restarted.***
