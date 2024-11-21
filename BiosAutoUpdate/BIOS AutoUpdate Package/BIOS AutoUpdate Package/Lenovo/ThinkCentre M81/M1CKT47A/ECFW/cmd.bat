@echo off
REM eSIO_Flash.exe /?
REM eSIO_Flash.exe /v
REM eSIO_Flash.exe /d:fw.bin
REM eSIO_Flash.exe /p:fw.bin

REM eSIO_Utility.exe /DP-S-D v_sf.bin
REM eSIO_Utility.exe /DP-S-P v_sf.bin

REM eSIO_Utility.exe /DP-HDMI-D v_hdmi.bin
REM eSIO_Utility.exe /DP-HDMI-P v_hdmi.bin

REM eSIO_Utility.exe /DP-DP-D v_dp.bin
REM eSIO_Utility.exe /DP-DP-P v_dp.bin

eSIO_Utility.exe /DP-V
REM eSIO_Utility.exe /DP-V -V:DP
REM eSIO_Utility.exe /DP-V -V:HDMI
REM eSIO_Utility.exe /DP-V -V:DP -V:HDMI

ECHO.
ECHO ErrorCode is %errorlevel%
IF %errorlevel%==0 ( echo PASS ) ELSE ( echo FAIL )
