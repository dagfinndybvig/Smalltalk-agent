@echo off
rem Whole-world snapshot of the live Pharo image.
rem Copies Pharo.image + Pharo.changes into snapshots\Pharo-<timestamp>.*
rem The image may keep running while this executes.
setlocal
cd /d "%~dp0"
for /f %%i in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd-HHmmss"') do set TS=%%i
if not exist snapshots mkdir snapshots
copy /y Pharo.image "snapshots\Pharo-%TS%.image" >nul
copy /y Pharo.changes "snapshots\Pharo-%TS%.changes" >nul
echo Snapshot saved: snapshots\Pharo-%TS%.image/.changes
