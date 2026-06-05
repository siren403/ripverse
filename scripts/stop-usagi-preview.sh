#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
STATE_DIR="$ROOT_DIR/.server"
PID_FILE="$STATE_DIR/usagi-preview.pid"

if [ ! -f "$PID_FILE" ]; then
  echo "no tracked Usagi preview server"
  exit 0
fi

PID=$(cat "$PID_FILE")
if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
  kill "$PID" 2>/dev/null || true
  echo "stopped Usagi preview server: $PID"
fi

rm -f "$PID_FILE"
