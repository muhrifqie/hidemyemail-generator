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

## Cron auto-generate
Entry (lihat `crontab -l`): tiap hari 02:00 WIB jalanin `vps/run-generate.sh`.
- Aman kalau cookie absen → SKIP, log di `logs/cron.log`.
- Ubah frekuensi/jumlah: `crontab -e`, arg = jumlah alias per run.
- Matikan: `crontab -e` lalu comment barisnya.

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
