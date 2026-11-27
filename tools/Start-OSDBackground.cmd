@echo off
setlocal
set "ScriptPath=%~dp0..\osd-osd.ps1"
if not exist "%ScriptPath%" exit /b 2
if not exist "%~dp0..\config.json" exit /b 3
start "OSD-OSD" "%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -STA -File "%ScriptPath%"
exit /b 0
