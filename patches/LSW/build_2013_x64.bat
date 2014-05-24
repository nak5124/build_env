@echo off
call "%VS120COMNTOOLS%vsvars32.bat"
devenv LSMASHSourceVCX.sln /Build "Release|x64"
REM pause
