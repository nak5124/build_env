@echo off
set MSYS2_DIR=C:\msys2
set HOME_DIR=%MSYS2_DIR%\home\K4095
copy /-Y .\bin\* %MSYS2_DIR%\bin\
copy /-Y .\dotfiles\* %HOME_DIR%\
copy /-Y .\etc\* %MSYS2_DIR%\etc\
copy /-Y .\bat\* %MSYS2_DIR%\
pause