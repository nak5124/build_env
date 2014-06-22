@echo off
set MSYSTEM=MINGW64
set WD=C:\msys2\usr\bin\
set MSYSCON=mintty.exe
set MSYS=winsymlinks:nativestrict
set CHERE_INVOKING=yes
start /d %1 /B %WD%mintty -p -1020,0 -i /msys2.ico /usr/bin/bash --login %*
exit
