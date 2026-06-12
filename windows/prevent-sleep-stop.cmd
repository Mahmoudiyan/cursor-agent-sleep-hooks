@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0prevent-sleep-stop.ps1"
exit /b %ERRORLEVEL%
