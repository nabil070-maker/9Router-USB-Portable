#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
NODE_VER="26.13.1"   # latest Node.js LTS ("Lithium") as of Nov 2026
UPDATE="${1:-}"

mkdir -p "$ROOT"/{runtime,app/npm,data,cache/npm,temp,home}

case "$(uname -m)" in
  x86_64) ARCH=x64 ;; aarch64|arm64) ARCH=arm64 ;;
  *) echo "Unsupported arch"; exit 1 ;;
esac

if [ ! -x "$ROOT/runtime/node/bin/node" ]; then
  NAME="node-v$NODE_VER-linux-$ARCH"
  BASE="https://nodejs.org/dist/v$NODE_VER"
  dl() { if command -v curl >/dev/null; then curl -fL "$1" -o "$2"; else wget -O "$2" "$1"; fi; }
  echo "Downloading Node $NODE_VER..."
  dl "$BASE/$NAME.tar.xz" "$ROOT/temp/node.tar.xz"
  dl "$BASE/SHASUMS256.txt" "$ROOT/temp/SHASUMS256.txt"
  EXPECTED="$(grep " $NAME.tar.xz\$" "$ROOT/temp/SHASUMS256.txt" | cut -d' ' -f1 || true)"
  if [ -n "$EXPECTED" ]; then
    ACTUAL="$(sha256sum "$ROOT/temp/node.tar.xz" | cut -d' ' -f1)"
    [ "$EXPECTED" = "$ACTUAL" ] || { echo "Node download checksum mismatch"; rm -f "$ROOT/temp/node.tar.xz"; exit 1; }
  fi
  tar -xJf "$ROOT/temp/node.tar.xz" -C "$ROOT/temp"
  rm -rf "$ROOT/runtime/node"; mv "$ROOT/temp/$NAME" "$ROOT/runtime/node"
  rm -f "$ROOT/temp/node.tar.xz" "$ROOT/temp/SHASUMS256.txt"
fi

export PATH="$ROOT/runtime/node/bin:$PATH"
export HOME="$ROOT/home" TMPDIR="$ROOT/temp" DATA_DIR="$ROOT/data"
export npm_config_prefix="$ROOT/app/npm" npm_config_cache="$ROOT/cache/npm"
export npm_config_update_notifier=false npm_config_fund=false

if ! "$ROOT/runtime/node/bin/node" -v >/dev/null 2>&1; then
  echo "Node failed to start. Node 25+ Linux builds need libatomic (e.g. apt install libatomic1)."
  exit 1
fi

if [ "$UPDATE" = "update" ] || [ ! -x "$ROOT/app/npm/bin/9router" ]; then
  npm install -g 9router@latest
fi

node "$ROOT/scripts/sqlite-guard.js"

[ -f "$ROOT/data/initial-password.txt" ] || printf '123456' > "$ROOT/data/initial-password.txt"
echo "Setup complete."
