@echo off
cd ECFW
call EC.bat
cd ..

wflash2.exe IMAGEM1C.bin /bb /rsmb %*
