#!/usr/bin/env bash
ROOT="$(cd "$(dirname "$0")" && pwd)"
if [ "${1:-}" = "update" ]; then bash "$ROOT/scripts/setup.sh" update; exit; fi
[ -x "$ROOT/app/npm/bin/9router" ] || bash "$ROOT/scripts/setup.sh" || exit 1

export PATH="$ROOT/runtime/node/bin:$ROOT/app/npm/bin:$PATH"
export HOME="$ROOT/home" TMPDIR="$ROOT/temp"
export npm_config_prefix="$ROOT/app/npm" npm_config_cache="$ROOT/cache/npm"
export DATA_DIR="$ROOT/data"
export INITIAL_PASSWORD="$(cat "$ROOT/data/initial-password.txt" 2>/dev/null || echo 123456)"

node "$ROOT/scripts/sqlite-guard.js"

echo "9Router: http://localhost:20128  (password: $INITIAL_PASSWORD)"
exec 9router --no-browser --host 127.0.0.1
