@echo off
call "%VS120COMNTOOLS%vsvars32.bat"

set TARGET_ARCH=%1

set MINGW32_INCLUDE_PATH=C:\msys2\mingw32\local\include
set MINGW64_INCLUDE_PATH=C:\msys2\mingw64\local\include
set MINGW32_LIB_PATH=C:\msys2\mingw32\local\bin
set MINGW64_LIB_PATH=C:\msys2\mingw64\local\bin

devenv LSMASHSourceVCX.sln /Build "Release|%TARGET_ARCH%"

exit /b %ERRORLEVEL%

REM pause
