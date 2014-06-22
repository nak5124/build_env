@echo off
set MSYSTEM=MINGW64
set WD=%~dp0\usr\bin\
set MSYSCON=mintty.exe
set MSYS=winsymlinks:nativestrict
start %WD%mintty -c ~/.minttyrc -p -1020,0 -i /msys2.ico /usr/bin/bash --login %*
exit
