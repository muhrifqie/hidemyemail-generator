#!/usr/bin/env python
"""Auto-refresh cookies.txt untuk hidemyemail-generator lewat pyicloud.

Alur:
  1x di laptop:  refresh-login.cmd  -> login (password + 2FA sekali), trust device,
                 password disimpan di Windows Credential Manager (keyring, BUKAN plaintext).
  Berikutnya:    refresh-cookie.cmd -> re-auth TANPA 2FA (pakai trust token tersimpan),
                 tulis ulang cookies.txt, (opsional) push ke VPS.

Agent nggak pernah pegang password: diketik owner saat --login, lalu dari keyring.
Jalanin dari LAPTOP (IP rumah) — login iCloud dari IP VPS rawan dicurigai Apple.

ponytail: pakai pyicloud (udah implement SRP+2FA+trust) daripada porting flow sendiri.
"""
from __future__ import annotations
import argparse, base64, json, os, re, subprocess, sys
from getpass import getpass
from pathlib import Path

from pyicloud import PyiCloudService
from pyicloud import utils as pyi

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent
SESSION_DIR = HERE / ".pyicloud-session"   # cached session + trust token (gitignored)
CONFIG = HERE / "refresh_config.json"       # {apple_id, region} — TANPA password (gitignored)
COOKIE_OUT = ROOT / "cookies.txt"

NEEDED = ("X-APPLE-WEBAUTH-TOKEN", "X-APPLE-WEBAUTH-USER")  # tool wajib punya ini


def load_cfg() -> dict:
    return json.loads(CONFIG.read_text()) if CONFIG.exists() else {}


def save_cfg(cfg: dict) -> None:
    CONFIG.write_text(json.dumps(cfg, indent=2))


def cookie_header(api: PyiCloudService) -> tuple[str, list[str]]:
    parts, names = [], []
    for c in api.session.cookies:
        if "icloud.com" in (c.domain or ""):
            parts.append(f"{c.name}={c.value}")
            names.append(c.name)
    return "; ".join(parts), names


def find_shard(api: PyiCloudService) -> str | None:
    blob = json.dumps(getattr(api, "_webservices", {}) or {})
    m = re.search(r"https://(p\d+)-", blob)
    return m.group(1) if m else None


def main() -> int:
    ap = argparse.ArgumentParser(description="Refresh cookies.txt iCloud via pyicloud")
    ap.add_argument("--login", action="store_true",
                    help="mode pertama: prompt password+2FA, simpan password ke keyring")
    ap.add_argument("--apple-id", help="Apple ID (email). Disimpan di refresh_config.json")
    ap.add_argument("--region", default=os.environ.get("HIDEMYEMAIL_REGION", "global"))
    ap.add_argument("--push", action="store_true", help="scp cookies.txt ke VPS setelah tulis")
    ap.add_argument("--vps-host", default="shopeeboosthelper")
    ap.add_argument("--vps-dest", default="/srv/hidemyemail/cookies.txt")
    args = ap.parse_args()

    cfg = load_cfg()
    apple_id = args.apple_id or cfg.get("apple_id")
    region = args.region or cfg.get("region", "global")
    china = region == "china"

    if args.login:
        if not apple_id:
            apple_id = input("Apple ID (email): ").strip()
        password = getpass("Password Apple ID (tidak disimpan plaintext): ")
        pyi.store_password_in_keyring(apple_id, password)
        cfg.update(apple_id=apple_id, region=region)
        save_cfg(cfg)
    else:
        if not apple_id:
            print("Belum ada apple_id. Jalankan dulu: refresh-login.cmd", file=sys.stderr)
            return 2
        if not pyi.password_exists_in_keyring(apple_id):
            print("Password belum di keyring. Jalankan dulu: refresh-login.cmd", file=sys.stderr)
            return 2
        password = pyi.get_password_from_keyring(apple_id)

    SESSION_DIR.mkdir(exist_ok=True)
    api = PyiCloudService(apple_id, password, cookie_directory=str(SESSION_DIR),
                          china_mainland=china)

    if api.requires_2fa:
        if not args.login:
            print("Butuh 2FA lagi (trust kedaluwarsa). Jalankan: refresh-login.cmd",
                  file=sys.stderr)
            return 3
        code = input("Kode 2FA dari device Apple kamu: ").strip()
        if not api.validate_2fa_code(code):
            print("Kode 2FA salah / ditolak.", file=sys.stderr)
            return 3

    if not api.is_trusted_session:
        try:
            api.trust_session()  # biar run berikutnya skip 2FA
        except Exception as e:  # noqa: BLE001
            print(f"warn: trust_session gagal: {e}", file=sys.stderr)

    cookie, names = cookie_header(api)
    missing = [n for n in NEEDED if n not in names]
    if missing:
        print(f"WARN: cookie wajib hilang: {missing}. Tool mungkin nolak.", file=sys.stderr)

    shard = find_shard(api)
    lines = []
    if shard:
        suffix = "com.cn" if china else "com"
        lines.append(f"HIDEMYEMAIL_MAILDOMAIN_HOST={shard}-maildomainws.icloud.{suffix}")
    lines.append("HIDEMYEMAIL_COOKIE_BASE64=" + base64.b64encode(cookie.encode()).decode())
    COOKIE_OUT.write_text("\n".join(lines) + "\n")
    print(f"[OK] cookies.txt ditulis: {len(names)} cookie, shard={shard or '-'}, "
          f"trusted={api.is_trusted_session}")

    if args.push:
        r = subprocess.run(["scp", str(COOKIE_OUT), f"{args.vps_host}:{args.vps_dest}"])
        print("[OK] cookies.txt dikirim ke VPS." if r.returncode == 0
              else "[ERR] scp gagal — cek SSH alias.", file=sys.stderr if r.returncode else sys.stdout)
        return r.returncode
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
