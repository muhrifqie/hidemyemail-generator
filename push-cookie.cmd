@echo off
rem Push cookies.txt lokal -> VPS (Hybrid A). Jalanin setelah refresh cookie iCloud.
rem Ubah HOST/DEST kalau beda server.
setlocal
cd /d "%~dp0"
set "HOST=shopeeboosthelper"
set "DEST=/srv/hidemyemail/cookies.txt"

if not exist "cookies.txt" (
  echo [ERROR] cookies.txt belum ada. Capture dulu lewat jalan.cmd ^> menu 4.
  pause
  exit /b 1
)

echo [INFO] Kirim cookies.txt ke %HOST%:%DEST% ...
scp "cookies.txt" "%HOST%:%DEST%"
if errorlevel 1 (
  echo [ERROR] scp gagal. Cek SSH alias "%HOST%".
  pause
  exit /b 1
)
echo [OK] Cookie terkirim. Cron di VPS bakal pakai yang baru.
endlocal
