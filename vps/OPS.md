# OPS — HideMyEmail (VPS shopeeboosthelper)

- **Host**: shopeeboosthelper (`ssh shopeeboosthelper`), app di `/srv/hidemyemail`, user `ubuntu`.
- **Runtime**: python3.12 + `.venv` (TANPA uv). CLI: `/srv/hidemyemail/.venv/bin/hidemyemail`.
- **Repo**: fork `muhrifqie/hidemyemail-generator`, branch `main`.
- **Auth** (Hybrid A): generate butuh `cookies.txt` (cookie web iCloud, expire berkala → refresh dari lokal via `push-cookie.cmd`). IMAP pakai app-specific password (stabil), config di `inbox_config.json`.

## Deploy / update
```bash
ssh shopeeboosthelper 'cd /srv/hidemyemail && bash vps/deploy.sh'
```
Rollback: lihat baris terakhir output deploy (`git reset --hard <PREV>`).

## Cron auto-generate (polling + top-up ke CAP)
Dua entry (lihat `crontab -l`):
- `*/10 * * * * HME_CAP=700 run-generate.sh` → POLL tiap 10 menit: top-up alias sampai
  `HME_CAP` (default 700), maks `HME_BATCH` (default 5) per run. Begitu window Apple reset,
  langsung ke-grab (nggak nunggu lama). Pas rate-limit (-41015) → di-log, poll berikutnya nyoba lagi.
- `*/30 * * * * hidemyemail inbox sync` → tarik email forward + kode verifikasi tiap 30 menit.
Catatan:
- Poll nggak nambah kecepatan (Apple tetap cap ~5/30menit), cuma mangkas delay.
- Cap tercapai → stop. Cookie absen/expired → SKIP, log `logs/cron.log`.
- Ubah cap: edit crontab `HME_CAP=NNN`. Lebih kalem: ganti `*/10` jadi `*/30`.
- ⚠️ Generate agresif = risiko Apple lock akun / HME disabled. Pantau `logs/cron.log` + `whoami`.

## Server kita manggil (same host)
Data di SQLite `hidemyemail.db`. Opsi:
- Baca langsung DB, atau
- `.venv/bin/hidemyemail inbox codes --result-json /tmp/codes.json` → baca JSON (kode verifikasi).
- `.venv/bin/hidemyemail list --result-json ...` → daftar alias.
- Hasil generate cron ada di `exports/gen_*.json`.

## Yang WAJIB diisi owner sebelum jalan
1. `inbox setup` (IMAP): `ssh shopeeboosthelper 'cd /srv/hidemyemail && .venv/bin/hidemyemail inbox setup --host imap.mail.me.com --username <appleid@...> --password <APP-SPECIFIC-PASSWORD>'`
   (app-specific password dibuat di appleid.apple.com → Sign-In and Security → App-Specific Passwords).
2. `cookies.txt`: capture di lokal (`jalan.cmd` → menu 4) lalu `push-cookie.cmd`.

## Jangan
- Jangan commit `cookies.txt`, `inbox_config.json`, `hidemyemail.db` (sudah di `.gitignore`).
- Generate agresif → mentok kuota Apple (~750 alias aktif). Cek `hidemyemail quota`.
