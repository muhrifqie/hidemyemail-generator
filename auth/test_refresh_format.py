"""Cek kontrak: output format refresh_cookies.py kebaca load_cookie_context tool.
Jalanin: .venv\\Scripts\\python auth\\test_refresh_format.py  (tanpa login Apple)."""
import base64, sys, tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "src"))
from hidemyemail_generator.main import load_cookie_context  # noqa: E402

def test_base64_and_shard_roundtrip():
    cookie = 'X-APPLE-WEBAUTH-USER="v=1:s=0:d=19107172683"; X-APPLE-WEBAUTH-TOKEN="v=2:t=abc"'
    content = (
        "HIDEMYEMAIL_MAILDOMAIN_HOST=p54-maildomainws.icloud.com\n"
        "HIDEMYEMAIL_COOKIE_BASE64=" + base64.b64encode(cookie.encode()).decode() + "\n"
    )
    with tempfile.TemporaryDirectory() as d:
        f = Path(d) / "cookies.txt"
        f.write_text(content)
        got_cookie, host = load_cookie_context(str(f), "global")
    assert got_cookie == cookie, f"cookie mismatch: {got_cookie!r}"
    assert host == "p54-maildomainws.icloud.com", f"host mismatch: {host!r}"

if __name__ == "__main__":
    test_base64_and_shard_roundtrip()
    print("OK: format cookies.txt (base64 + shard) kebaca tool dengan benar.")
