Set ECIO=M1CCT11A

:CheckECVer
if exist ecio.txt del ecio.txt
eSIO_Flash.exe /v >ecio.txt
if not exist ecio.txt ping 127.0.0.1 -n 2 > nul&&goto CheckECVer
find /i /n "%ECIO%" ecio.txt
if not errorlevel 1 goto pass

:FlashEC
WinRWA64.exe IO W 66 31
WinRWA64.exe IO W 62 11
WinRWA64.exe IO W 62 22
WinRWA64.exe IO W 62 33
WinRWA64.exe IO W 62 44
WinRWA64.exe IO W 66 32
WinRWA64.exe IO W 62 11
WinRWA64.exe IO W 62 22
WinRWA64.exe IO R 62
WinRWA64.exe IO R 62
eSIO_Flash.exe /p:%ECIO%.bin

:pass