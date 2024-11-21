@echo off
cd ECFW
call EC.bat
cd ..

wflash2x64.exe IMAGEM1C.BIN /bb /rsmb %*
