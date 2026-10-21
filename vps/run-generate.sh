#!/usr/bin/env bash
# Cron wrapper: top-up alias HME sampai CAP + tarik email forward (IMAP).
# Tiap run bikin maks BATCH alias (batas window Apple ~5/30menit). Pas kena
# rate-limit Apple (-41015), cuma di-log; run berikutnya nyoba lagi (auto-backoff).
# Aman kalau cookie absen -> SKIP. Log: logs/cron.log
#
# Env: HME_CAP (default 700), HME_BATCH (default 5)
set -uo pipefail

APP_DIR="${APP_DIR:-/srv/hidemyemail}"
CAP="${HME_CAP:-700}"
BATCH="${HME_BATCH:-${1:-5}}"
export HIDEMYEMAIL_REGION="${HIDEMYEMAIL_REGION:-global}"
cd "$APP_DIR" || exit 1

HME=".venv/bin/hidemyemail"
PY=".venv/bin/python"
TS="$(date +%F_%H%M%S)"
mkdir -p exports logs
log() { echo "[$TS] $*" >> logs/cron.log; }

if [ ! -s cookies.txt ]; then
  log "SKIP: cookies.txt kosong/absen. Refresh cookie (refresh-cookie.cmd di laptop)."
else
  # hitung alias aktif sekarang
  if "$HME" list --result-json exports/_list.json >> logs/cron.log 2>&1; then
    CUR=$("$PY" -c "import json;print(len(json.load(open('exports/_list.json')).get('addresses') or []))" 2>/dev/null || echo -1)
  else
    CUR=-1
  fi
  rm -f exports/_list.json

  if [ "$CUR" -lt 0 ]; then
    log "list gagal (cookie expired?) — skip generate. Cek: $HME whoami"
  elif [ "$CUR" -ge "$CAP" ]; then
    log "cap tercapai ($CUR/$CAP) — stop generate."
  else
    WANT=$((CAP - CUR)); [ "$WANT" -gt "$BATCH" ] && WANT=$BATCH
    OUT="$("$HME" generate --count "$WANT" --label auto --result-json "exports/gen_$TS.json" 2>&1)"
    echo "$OUT" >> logs/cron.log
    if echo "$OUT" | grep -qiE "reached the limit|-41015|try again later"; then
      log "RATE-LIMIT Apple ($CUR/$CAP) — nunggu window berikutnya."
    else
      RES=$(echo "$OUT" | grep -ci "Successfully reserved" || true)
      log "generate: $RES ter-reserve (cur=$CUR -> target $CAP, minta=$WANT)."
    fi
  fi
fi

# Tarik email forward + kode verifikasi kalau IMAP sudah dikonfigur.
if [ -s inbox_config.json ]; then
  "$HME" inbox sync >> logs/cron.log 2>&1 && log "inbox sync OK" || log "inbox sync gagal"
fi
