@echo off
rem Starts the headless Pharo image with the SmalltalkInteropServer on port 8086.
rem Stop it with Ctrl+C (or close the console window).
cd /d "%~dp0"
pharo-vm\PharoConsole.exe --headless Pharo.image st keepalive.st
