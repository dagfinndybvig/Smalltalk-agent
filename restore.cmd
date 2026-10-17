@echo off
rem Whole-world restore: roll the live Pharo image back to a snapshot.
rem Usage:    restore.cmd snapshots\Pharo-20260101-120000
rem WARNING:  stop the running image first (close its console / Ctrl+C).
setlocal
cd /d "%~dp0"
if "%~1"=="" (
  echo Usage: restore.cmd snapshots\Pharo-^<timestamp^>
  echo Available snapshots:
  for %%f in (snapshots\*.image) do echo   %%~nf
  exit /b 1
)
if not exist "%~1.image" (
  echo Not found: %~1.image
  exit /b 1
)
tasklist /FI "IMAGENAME eq PharoConsole.exe" 2>nul | findstr /I "PharoConsole.exe" >nul && (
  echo PharoConsole.exe is still running. Stop it before restoring.
  exit /b 1
)
copy /y "%~1.image" Pharo.image
copy /y "%~1.changes" Pharo.changes
echo Restored image from %~1
