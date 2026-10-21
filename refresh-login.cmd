@echo off
rem LOGIN SEKALI di laptop: password + 2FA, trust device, simpan password di keyring.
rem Jalanin ini pas pertama kali ATAU kalau diminta 2FA lagi. Habis ini tinggal refresh-cookie.cmd.
setlocal
cd /d "%~dp0"
set "PYTHONUTF8=1"
set "PYTHONIOENCODING=utf-8"
chcp 65001 >nul

where uv >nul 2>nul || ( echo [ERROR] uv tidak ada. Install dulu. & pause & exit /b 1 )
if not exist ".venv\Scripts\python.exe" ( uv sync --python 3.12 )
echo [INFO] Pastikan pyicloud terpasang...
uv sync --python 3.12 --extra auth

".venv\Scripts\python.exe" auth\refresh_cookies.py --login --push
echo.
pause
endlocal
