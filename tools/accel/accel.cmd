@echo off
setlocal
set "SH=pwsh"
where pwsh >nul 2>nul || set "SH=powershell"
"%SH%" -NoProfile -ExecutionPolicy Bypass -File "%~dp0accel.ps1" %*
if "%~1"=="" pause
