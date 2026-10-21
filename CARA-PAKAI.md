# Cara Pakai — HideMyEmail Generator

Tool Python buat generate & kelola alias iCloud **Hide My Email** lewat API iCloud.
Fork dari [rtunazzz/hidemyemail-generator](https://github.com/rtunazzz/hidemyemail-generator),
origin sudah diarahkan ke repo kamu (`muhrifqie`).

## Jalanin (tinggal klik)

Double-click **`jalan.cmd`**. Dia otomatis:
- set UTF-8 console (biar teks iCloud/Mandarin nggak error),
- bangun `.venv` sekali kalau belum ada (pakai `uv`, Python 3.12),
- buka menu interaktif.

Nggak perlu install ulang tiap kali — `.venv` cuma dibuat sekali.

Butuh akses CLI manual? Dari folder ini:

```bat
.venv\Scripts\python -m hidemyemail_generator.main --help
```

Command yang ada: `generate`, `list`, `deactivate`, `reactivate`, `update-metadata`,
`quota`, `whoami`, `batch`, `inbox`, `capture-cookie`.

## Yang WAJIB kamu isi dulu: cookie iCloud

Tool butuh cookie login iCloud **akun kamu sendiri**. Tanpa ini nggak bisa generate.
Cookie **tidak** ikut ke-commit (sudah di `.gitignore`).

Cara isi (ringkas, detail di `COOKIE_HELP.md`):
1. Buka `https://www.icloud.com/settings/`, login.
2. F12 → tab **Network** → refresh → filter cari `hme` atau `maildomainws`.
3. Klik kanan salah satu request `maildomainws`/`hme` → **Copy → Copy as cURL**.
4. Paste semua ke file **`cookies.txt`** di folder ini, simpan.

Atau pakai **auto-capture** (butuh playwright, lihat di bawah):
di menu `jalan.cmd` → `4. Manage iCloud cookie` → `3. Auto capture`.

## Opsional: fitur auto-capture cookie (playwright)

Kalau mau pakai auto-capture, install extra-nya sekali:

```bat
uv sync --extra capture
.venv\Scripts\python -m playwright install chromium
```

## Di mana nanti modif

Semua kode ada di `src/hidemyemail_generator/` (editable install, jadi edit langsung kepakai tanpa reinstall):
- `main.py` — entry CLI (click), semua command di sini.
- `launcher.py` — menu interaktif yang dibuka `jalan.cmd`.
- `hidemyemail.py` — logika API iCloud (generate/list/activate dll).
- `inbox.py` — inbox lokal & kode verifikasi.

Push perubahan: `git push origin main`. Narik update upstream: `git fetch upstream && git merge upstream/main`.

## Jalan di VPS (cron auto-generate + IMAP)

Sudah ter-deploy di **shopeeboosthelper** (`/srv/hidemyemail`, python3.12 venv, tanpa uv).
Cron generate 3 alias/hari jam 02:00 WIB. Detail ops: [`vps/OPS.md`](vps/OPS.md).

2 hal yang **wajib kamu isi** sebelum beneran jalan:
1. **IMAP** (sekali): bikin app-specific password di appleid.apple.com, lalu
   `ssh shopeeboosthelper 'cd /srv/hidemyemail && .venv/bin/hidemyemail inbox setup --host imap.mail.me.com --username <appleid> --password <app-pw>'`
2. **Cookie**: capture di lokal (`jalan.cmd` → menu 4), lalu double-click `push-cookie.cmd`.

Server kita (host sama) baca hasil dari SQLite `hidemyemail.db` atau
`.venv/bin/hidemyemail inbox codes --result-json ...`.

### Auto-refresh cookie (pyicloud) — biar nggak capture manual

Cookie web iCloud expire ~mingguan. Daripada capture manual, pakai auto-refresh lewat
**pyicloud**: login sekali, re-auth berikutnya **tanpa 2FA** pakai trust token. Jalanin di
**laptop** (IP rumah — login iCloud dari IP VPS rawan dicurigai Apple).

1. **Login sekali**: double-click `refresh-login.cmd` → Apple ID + password + kode 2FA.
   Password masuk **Windows Credential Manager** (keyring, bukan plaintext), device di-*trust*,
   `cookies.txt` keisi + auto-push ke VPS.
2. **Refresh berikutnya** (tanpa 2FA): `refresh-cookie.cmd` → re-auth pakai trust token, tulis
   ulang `cookies.txt` + push. Kalau trust expired, dia nyuruh jalanin `refresh-login.cmd` lagi.
3. **Otomatis berkala** (opsional, Task Scheduler):
   ```
   schtasks /create /tn "HME cookie refresh" /tr "C:\BOT\HideMyEmail\refresh-cookie.cmd" /sc DAILY /st 09:00
   ```

Jangan commit (udah di-ignore): `auth/.pyicloud-session/`, `auth/refresh_config.json`, `cookies.txt`.
Kode: [`auth/refresh_cookies.py`](auth/refresh_cookies.py). Dep: `uv sync --extra auth`.

## Catatan

- Jangan commit `cookies.txt`, `emails.txt`, `hidemyemail.db`, `inbox_config.json` (sudah di-ignore).
- Otomasi akun iCloud sendiri. Login & generate dilakukan kamu, bukan agent.
- Cookie web iCloud expire berkala → refresh lokal + `push-cookie.cmd`. Awas kuota Apple (~750 alias).
