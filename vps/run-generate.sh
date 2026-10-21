#!/usr/bin/env bash
# Cron wrapper: generate batch kecil alias HME + tarik email forward (IMAP).
# Aman kalau cookie belum ada -> SKIP, nggak error. Log ke logs/cron.log.
# Pakai: run-generate.sh [count]   (default 3)
set -uo pipefail

APP_DIR="${APP_DIR:-/srv/hidemyemail}"
COUNT="${1:-3}"
export HIDEMYEMAIL_REGION="${HIDEMYEMAIL_REGION:-global}"
cd "$APP_DIR" || exit 1

HME=".venv/bin/hidemyemail"
TS="$(date +%F_%H%M%S)"
mkdir -p exports logs
log() { echo "[$TS] $*" >> logs/cron.log; }

# Cookie iCloud wajib buat generate. Refresh dari lokal (push-cookie.cmd) kalau expire.
if [ ! -s cookies.txt ]; then
  log "SKIP generate: cookies.txt kosong/absen. Refresh cookie dari mesin lokal."
else
  if "$HME" generate --count "$COUNT" --result-json "exports/gen_$TS.json" >> logs/cron.log 2>&1; then
    log "generate OK: $COUNT alias -> exports/gen_$TS.json"
  else
    log "generate GAGAL (kemungkinan cookie expired / kuota Apple penuh). Cek: $HME quota"
  fi
fi

# Tarik email forward + kode verifikasi kalau IMAP sudah dikonfigur (inbox_config.json).
if [ -s inbox_config.json ]; then
  "$HME" inbox sync >> logs/cron.log 2>&1 && log "inbox sync OK" || log "inbox sync gagal"
fi

# ponytail: generate COUNT tetap per run. Kalau mau "top-up ke N spare",
# tambah cek `hidemyemail list` jumlah unused dulu di sini.
