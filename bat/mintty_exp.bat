@echo off
set MSYSTEM=MINGW64
set WD=C:\msys2\usr\bin\
set MSYSCON=mintty.exe
set CHERE_INVOKING=yes
start /d %1 /B %WD%mintty -p -1020,0 -i /msys.ico /bin/bash --login %*
exit
