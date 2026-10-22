#!/usr/bin/env python
"""Generate N alias HME di PC ini, lalu kirim yang BERHASIL di-reserve ke Telegram.
Dipakai Windows Task Scheduler tiap 31 menit (lewat gas-local.cmd).

Tiap run cuma kirim email dari `emails` di hasil generate (yang beneran ter-reserve),
jadi nggak ada dobel. Kalau kena rate-limit Apple (-41015) → skip diam, nggak kirim.

Env opsional: HME_COUNT (default 5), HME_LABEL (default toko).
"""
from __future__ import annotations
import json, os, subprocess, sys, tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
VENV_PY = ROOT / ".venv" / "Scripts" / "python.exe"
TG = Path(r"C:\BOT\Waroengku Corp\scripts\tg.mjs")
COUNT = os.environ.get("HME_COUNT", "5")
LABEL = os.environ.get("HME_LABEL", "toko")


def send_tg(msg: str) -> None:
    if not TG.exists():
        print("[warn] tg.mjs nggak ketemu, skip Telegram"); return
    try:
        subprocess.run(["node", str(TG)], input=msg.encode("utf-8"), check=False)
    except Exception as e:  # noqa: BLE001
        print("[warn] kirim Telegram gagal:", e)


def main() -> int:
    if not VENV_PY.exists():
        print("[err] .venv belum ada. Jalankan jalan.cmd / refresh-login.cmd dulu.", file=sys.stderr)
        return 2
    if not (ROOT / "cookies.txt").exists():
        print("[err] cookies.txt nggak ada. Jalankan refresh-login.cmd dulu.", file=sys.stderr)
        return 2

    env = {**os.environ, "PYTHONUTF8": "1", "PYTHONIOENCODING": "utf-8"}
    with tempfile.TemporaryDirectory() as d:
        out = Path(d) / "gen.json"
        subprocess.run([str(VENV_PY), "-m", "hidemyemail_generator.main",
                        "generate", "--count", COUNT, "--label", LABEL,
                        "--result-json", str(out)],
                       cwd=str(ROOT), env=env, check=False)
        try:
            res = json.loads(out.read_text(encoding="utf-8"))
        except Exception:
            print("[skip] nggak ada hasil generate (cookie/jaringan?)"); return 0

    emails = []
    for e in (res.get("emails") or []):
        emails.append(e if isinstance(e, str) else (e.get("email") or ""))
    emails = [e for e in emails if e]

    if not emails:
        err = (res.get("error") or {}).get("message", "belum ada yang ter-reserve")
        print(f"[skip] {err}")
        return 0

    msg = "🗝️ HideMyEmail — alias baru siap pakai:\n" + "\n".join("- " + e for e in emails)
    send_tg(msg)
    print(f"[ok] {len(emails)} alias dikirim ke Telegram")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
