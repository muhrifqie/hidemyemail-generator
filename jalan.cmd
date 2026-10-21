@echo off
setlocal
cd /d "%~dp0"

rem Region: "global" (default) atau "china" untuk iCloud China
if not defined HIDEMYEMAIL_REGION set "HIDEMYEMAIL_REGION=global"

rem Paksa UTF-8 biar menu & teks iCloud nggak error di console Windows
set "PYTHONUTF8=1"
set "PYTHONIOENCODING=utf-8"
chcp 65001 >nul

rem Kalau .venv belum ada (misal baru clone / kehapus), bangun sekali pakai uv
if not exist ".venv\Scripts\python.exe" (
  echo [INFO] Menyiapkan environment sekali jalan, tunggu sebentar...
  where uv >nul 2>nul
  if errorlevel 1 (
    echo [ERROR] uv tidak ditemukan. Install dulu:
    echo   powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 ^| iex"
    pause
    exit /b 1
  )
  uv sync --python 3.12
  if errorlevel 1 (
    echo [ERROR] Setup dependency gagal.
    pause
    exit /b 1
  )
)

rem Jalankan menu interaktif pakai python di .venv (nggak perlu uv lagi)
".venv\Scripts\python.exe" -m hidemyemail_generator.launcher
endlocal
