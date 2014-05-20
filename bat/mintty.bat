@echo off
set MSYSTEM=MINGW32
set WD=%~dp0\bin\
set MSYSCON=mintty.exe
REM set CHERE_INVOKING=yes
start %WD%mintty -c ~/.minttyrc -p -1020,0 -i /msys.ico -
exit
