@echo off
set MSYSTEM=MINGW64
set WD=%~dp0usr\bin\
set MSYSCON=mintty
start %WD%%MSYSCON% -c ~/.minttyrc -i /msys2.ico /usr/bin/bash --login %*
exit
