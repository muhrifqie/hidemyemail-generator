@echo off
rem Generate 5 alias HME di PC ini + kirim yang berhasil ke Telegram.
rem Dijadwal Windows Task Scheduler tiap 31 menit. Butuh cookies.txt valid
rem (refresh-cookie.cmd / refresh-login.cmd) + node (buat tg.mjs).
setlocal
cd /d "%~dp0"
set "PYTHONUTF8=1"
set "PYTHONIOENCODING=utf-8"
".venv\Scripts\python.exe" auth\gen_notify.py
endlocal
