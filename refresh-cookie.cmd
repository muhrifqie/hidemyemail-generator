@echo off
rem REFRESH tanpa 2FA (pakai trust token tersimpan) + push ke VPS.
rem Cocok buat Windows Task Scheduler (jalan berkala tanpa dijaga).
rem Kalau trust expired, dia bakal bilang suruh jalanin refresh-login.cmd.
setlocal
cd /d "%~dp0"
set "PYTHONUTF8=1"
set "PYTHONIOENCODING=utf-8"
chcp 65001 >nul

".venv\Scripts\python.exe" auth\refresh_cookies.py --push
endlocal
