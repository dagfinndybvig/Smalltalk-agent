@echo off
rem Health-check helper for the headless Pharo image server (port 8086).
rem If the server answers, reports up and exits. If not, starts the image
rem detached (minimized) and waits for SIS to come up. Safe to run anytime.
rem Never starts a VM while another Pharo process already holds the image.
setlocal
cd /d "%~dp0"

curl -sS -m 5 -X POST http://localhost:8086/eval/ -H "Content-Type: application/json" -d "{\"code\":\"Smalltalk version\"}" >nul 2>&1 && (
  echo Server is up on port 8086.
  exit /b 0
)

tasklist /FI "IMAGENAME eq PharoConsole.exe" 2>nul | findstr /I "PharoConsole.exe" >nul && (
  echo A Pharo VM is running but the server is not answering on port 8086.
  echo Not starting another VM - two VMs on the same image files corrupt state.
  echo Investigate or stop it first with: taskkill /IM PharoConsole.exe
  exit /b 1
)
tasklist /FI "IMAGENAME eq Pharo.exe" 2>nul | findstr /I "Pharo.exe" >nul && (
  echo The Pharo desktop is running but the server is not answering on port 8086.
  echo Not starting another VM - two VMs on the same image files corrupt state.
  echo Investigate or stop it first with: taskkill /IM Pharo.exe
  exit /b 1
)

echo Server is down - starting the headless image...
rem The >nul 2>&1 on start breaks handle inheritance: without it a piped
rem caller (an agent shell) blocks forever because the VM holds its stdout.
start "Pharo SIS server" /min pharo-vm\PharoConsole.exe --headless Pharo.image st keepalive.st >nul 2>&1

set /a tries=0
:waitloop
set /a tries+=1
if %tries% gtr 20 (
  echo Server did not come up within about 40 seconds.
  echo Check the minimized console window for errors.
  exit /b 1
)
ping -n 3 127.0.0.1 >nul
curl -sS -m 5 -X POST http://localhost:8086/eval/ -H "Content-Type: application/json" -d "{\"code\":\"Smalltalk version\"}" >nul 2>&1 && (
  echo Server is up on port 8086.
  exit /b 0
)
goto waitloop
