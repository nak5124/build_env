@echo off
set MSYSTEM=MINGW64
set WD=%~dp0\usr\bin\
set MSYSCON=mintty.exe
start %WD%mintty -c ~/.minttyrc -p -1020,0 -i /msys.ico /bin/bash --login %*
exit
