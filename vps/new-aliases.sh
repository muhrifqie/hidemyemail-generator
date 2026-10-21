#!/usr/bin/env bash
# Cetak alias HME yang BELUM pernah dilaporkan (satu email per baris), lalu
# tandai sebagai sudah (exports/_reported_emails.txt). Dipakai task pengawas
# buat kirim alias baru yang siap pakai ke Telegram tanpa dobel.
#   --seed : tandai semua alias SAAT INI sebagai "sudah dilaporkan" tanpa nyetak
#            (dipakai sekali di awal biar alias lama nggak kedump).
set -uo pipefail
cd "${APP_DIR:-/srv/hidemyemail}" || exit 1
HME=".venv/bin/hidemyemail"; PY=".venv/bin/python"
SEEN="exports/_reported_emails.txt"
mkdir -p exports; touch "$SEEN"

"$HME" list --result-json exports/_na.json >/dev/null 2>&1 || exit 0
"$PY" - "$SEEN" "${1:-}" <<'PY'
import json, sys
seen_path, mode = sys.argv[1], (sys.argv[2] if len(sys.argv) > 2 else "")
seen = set(open(seen_path, encoding="utf-8").read().split())
d = json.load(open("exports/_na.json", encoding="utf-8"))
new = [a["email"] for a in (d.get("addresses") or [])
       if a.get("email") and a["email"] not in seen and a.get("is_active", True)]
if mode != "--seed":
    print("\n".join(new))
if new:
    with open(seen_path, "a", encoding="utf-8") as f:
        f.write("".join(e + "\n" for e in new))
PY
rm -f exports/_na.json
