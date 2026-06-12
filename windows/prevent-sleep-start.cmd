@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0prevent-sleep-start.ps1"
exit /b %ERRORLEVEL%
