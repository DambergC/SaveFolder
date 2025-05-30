rem DELL PROPRIETARY INFORMATION
rem
rem This software is confidential.  Dell Inc., or one of its subsidiaries, has supplied this
rem software to you under the terms of a license agreement,nondisclosure agreement or both.
rem You may not copy, disclose, or use this software except in accordance with those terms.
rem
rem Copyright 2020 - 2021 Dell Inc. or its subsidiaries.  All Rights Reserved.
rem
rem DELL INC. MAKES NO REPRESENTATIONS OR WARRANTIES ABOUT THE SUITABILITY OF THE SOFTWARE,
rem EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF
rem MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR NON-INFRINGEMENT.
rem DELL SHALL NOT BE LIABLE FOR ANY DAMAGES SUFFERED BY LICENSEE AS A RESULT OF USING,
rem MODIFYING OR DISTRIBUTING THIS SOFTWARE OR ITS DERIVATIVES.

@echo off
:: ***************************************************************************
:: *                         WARRANTY DISCLAIMER
:: ***************************************************************************
:: * THIS SCRIPT IS BEING PROVIDED TO YOU "AS IS".  DELL DISCLAIMS ANY
:: * AND ALL WARRANTIES, EXPRESS, IMPLIED OR STATUTORY, WITH RESPECT TO THE
:: * SCRIPT, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
:: * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, TITLE AND ANY WARRANTY
:: * OF NON-INFRINGEMENT. YOU WILL USE THIS SCRIPT AT YOUR OWN RISK.
:: * DELL SHALL NOT BE LIABLE TO YOU FOR ANY DIRECT OR INDIRECT DAMAGES
:: * INCURRED IN USING THE SCRIPT. IN NO EVENT SHALL DELL OR ITS
:: * SUPPLIERS BE RESPONSIBLE FOR ANY DIRECT OR INDIRECT DAMAGES WHATSOEVER
:: * (INCLUDING, WITHOUT LIMITATION, DAMAGES FOR LOSS OF PROFITS, LOSS OF USE,
:: * LOSS OF DATA, BUSINESS INTERRUPTION, OR OTHER PECUNIARY LOSS, NOR FOR
:: * PUNITIVE, INCIDENTAL, CONSEQUENTIAL, OR SPECIAL DAMAGES OF ANY KIND,
:: * UNDER ANY PART OF THIS AGREEMENT, EVEN IF ADVISED OR AWARE OF THE
:: * POSSIBILITY OF SUCH DAMAGES).
:: ***************************************************************************

:: ***************************************************************************
REM Name: cctk_x86_64_winpe.bat
REM
REM Purpose:
REM    This script installs Dell drivers into a base Windows PE 2.0 image offline.
REM    Most of these drivers are essential for Command Configure tools to work correctly.
REM  
REM Arguments:
REM    %1 Path to local directory for Windows PE 2.0
REM    %2 Path to extracted Command Configure toolkit

:: ***************************************************************************
if "%1%" == "" goto usage

if "%2%" == "" goto usage

Set AIKTOOLS="C:\Program files\Windows AIK\Tools"

@echo ----------------------------------------
@echo ~~1(cctk_x86_64_winpe.bat)-Check the Paths
@echo ----------------------------------------

if not exist %2% (
	echo CCTKPATH %2% does not exist. Exiting.....
	goto done
)

if not exist %AIKTOOLS% (
	echo %AIKTOOLS%  does not exist. Exiting.....
	goto done
)

REM WINPEPATH is the Path to the WinPE 2.0

Set WINPEPATH=%1%
Set CCTKPATH=%2%

echo %WINPEPATH%
echo %CCTKPATH%

@echo -------------------------------------
@echo ~~2-Setup a WinPE 2.0 build environment
@echo -------------------------------------

::rd /s/q %WINPEPATH%

if not exist %WINPEPATH% call %AIKTOOLS%\PETools\copype.cmd amd64 %WINPEPATH%


@echo --------------------------------------------
@echo ~~3-Mount the base WinPE Image (winpe.wim) 
@echo --------------------------------------------
REM Mount the base WINPE image (1=Image Number) locally to add or remove packages
%AIKTOOLS%\X86\imagex /mountrw %WINPEPATH%\WinPE.wim 1 %WINPEPATH%\mount\

REM List the packages in the base WinPE Image
%AIKTOOLS%\PETools\peimg /list %WINPEPATH%\mount\windows

@echo ------------------------------------
@echo ~~4-Add additional customizations
@echo ------------------------------------
REM Add Windows WMI package
%AIKTOOLS%\PETOOLS\peimg /install=WinPE-WMI-Package %WINPEPATH%\mount\Windows
 
REM Add ImageX
copy %AIKTOOLS%\amd64\imagex.exe %WINPEPATH%\iso\
copy %AIKTOOLS%\amd64\imagex.exe %WINPEPATH%\mount\Windows\system32

REM Add Package Manager(Pkgmgr.exe) AND MSXML6 binaries
xcopy %AIKTOOLS%\amd64\Servicing\*.* %WINPEPATH%\iso\Servicing /S /E /i /Y
xcopy %windir%\system32\msxml6*.dll %WINPEPATH%\iso\Servicing /Y /i

@echo --------------------------------------------------------------
@echo ~~5 -Copy TOOLKIT Files to the mounted image 6
@echo --------------------------------------------------------------

::copy /Y %CCTKPATH%\*.dll    %WINPEPATH%\mount\Command_Configure\X86_64\HAPI
::xcopy %CCTKPATH%\HAPI\*.*    %WINPEPATH%\mount\Command_Configure\X86_64\HAPI /S /E /i /Y
xcopy %CCTKPATH%\X86_64\*.*	   %WINPEPATH%\mount\Command_Configure\X86_64 /S /E /i /Y
rem copy /Y %CCTKPATH%\Readme.txt    %WINPEPATH%\mount\Command_Configure\X86_64


@echo ------------------------
@echo ~~6-Add the Services 9
@echo ------------------------
::echo net start msiscsi >> %WINPEPATH%\mount\windows\system32\STARTNET.CMD
echo echo Starting WMI Services >> %WINPEPATH%\mount\windows\system32\STARTNET.CMD
echo net start winmgmt >> %WINPEPATH%\mount\windows\system32\STARTNET.CMD
echo echo ******************** >> %WINPEPATH%\mount\windows\system32\STARTNET.CMD

@echo --------------------------------------
@echo ~~7-Prepare the image for deployment 11
@echo --------------------------------------
%AIKTOOLS%\PETOOLS\peimg.exe /prep %WINPEPATH%\mount\Windows /f

@echo ---------------------------------------------
@echo ~~8-Commit the customization to base image 12
@echo ---------------------------------------------
::Commit Changes to the Standard Image (winpe.wim)

%AIKTOOLS%\x86\imagex.exe /unmount /commit %WINPEPATH%\mount\ 

goto done
:usage
echo.
echo cctk_x86_64_winpe.bat
echo.
echo Copyright 2009 - 2017 Dell Inc. All rights reserved.
echo.
echo Usage : cctk_x86_64_winpe.bat WINPEPATH CCTKPATH
echo 
echo Where:
echo   WINPEPATH   path where the Windows PE 2.0 contents are located
echo   CCTKPATH     path where Command Configure is installed
echo.
echo Example: cctk_x86_64_WinPE.bat C:\vistape_x64 C:\Progra~2\Dell\Comman~1\
echo.
echo.

goto done
:done
@echo -------------------------------
@echo ~~9(cctk_x86_64_winpe.bat)-DONE. 12
@echo -------------------------------
set WINPEPATH=
set CCTKPATH=
set AIKTOOLS=
echo.
