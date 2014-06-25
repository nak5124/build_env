@echo off
call "%VS120COMNTOOLS%vsvars32.bat"
devenv LSMASHSourceVCX.sln /Build "Release|Win32"
REM pause
