@echo off
set MSYSTEM=MINGW64
set WD=C:\\\\msys2\\\\usr\\\\bin\\\\
set MSYSCON=mintty
set CHERE_INVOKING=yes
start /d %1 /B %WD%%MSYSCON% -c ~/.minttyrc -i /msys2.ico /usr/bin/bash -c ^
    "export WD=%WD%; export MSYSCON=%MSYSCON%; export CHERE_INVOKING=%CHERE_INVOKING%; exec /usr/bin/bash --login"
REM start /d %1 /B %WD%%MSYSCON% -c ~/.minttyrc -p -1220,80 -i /msys2.ico /usr/bin/bash --login
exit
