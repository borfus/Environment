@echo off
call w:\handmade\misc\shell.bat
mkdir ..\build
pushd ..\build
cl -FC -Zi W:\handmade\code\win32_handmade.cpp user32.lib Gdi32.lib
popd
