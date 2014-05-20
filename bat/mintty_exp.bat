@echo off
set MSYSTEM=MINGW32
set WD=C:\msys2\bin\
set MSYSCON=mintty.exe
set CHERE_INVOKING=yes
start /d %1 /B %WD%mintty -p -1020,0 -i /msys.ico -
exit
