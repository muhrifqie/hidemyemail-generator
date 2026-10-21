#!/usr/bin/env bash
# Deploy/update HideMyEmail di VPS (Linux, python3.12 + venv, TANPA uv).
# Idempotent: aman dijalankan berkali-kali. Backup dulu, siapkan rollback.
set -euo pipefail

APP_DIR="${APP_DIR:-/srv/hidemyemail}"
REPO="${REPO:-https://github.com/muhrifqie/hidemyemail-generator.git}"
BRANCH="${BRANCH:-main}"

echo "[deploy] APP_DIR=$APP_DIR BRANCH=$BRANCH"

if [ ! -d "$APP_DIR/.git" ]; then
  echo "[deploy] clone pertama..."
  git clone -b "$BRANCH" "$REPO" "$APP_DIR"
fi

cd "$APP_DIR"
PREV=$(git rev-parse --short HEAD 2>/dev/null || echo none)
git fetch --quiet origin "$BRANCH"
git checkout --quiet "$BRANCH"
git reset --hard --quiet "origin/$BRANCH"   # rollback: git reset --hard <PREV>
NOW=$(git rev-parse --short HEAD)
echo "[deploy] $PREV -> $NOW"

# venv + install (editable biar gampang dimodif)
if [ ! -x ".venv/bin/python" ]; then
  python3 -m venv .venv
fi
.venv/bin/pip install -q --upgrade pip
.venv/bin/pip install -q -e .

mkdir -p exports logs
echo "[deploy] OK. CLI: $APP_DIR/.venv/bin/hidemyemail"
echo "[deploy] rollback: cd $APP_DIR && git reset --hard $PREV && .venv/bin/pip install -q -e ."
