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

## Catatan

- Jangan commit `cookies.txt`, `emails.txt`, `hidemyemail.db` (sudah di-ignore).
- Otomasi akun iCloud sendiri. Login & generate dilakukan kamu, bukan agent.
