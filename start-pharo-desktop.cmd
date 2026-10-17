@echo off
rem Opens the Pharo desktop (GUI) on the live image.
rem IMPORTANT: stop the headless server first (close its console or
rem taskkill /IM PharoConsole.exe) - two VMs on the same image files
rem corrupt state. SIS still auto-starts on 8086 in GUI mode, so the
rem agent bridge remains usable while the desktop is open.
cd /d "%~dp0"
start "" "pharo-vm\Pharo.exe" Pharo.image
