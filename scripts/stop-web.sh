#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
STATE_DIR="$ROOT_DIR/.server"
PID_FILE="$STATE_DIR/web.pid"

if [ ! -f "$PID_FILE" ]; then
  echo "no tracked web playground server"
  exit 0
fi

PID=$(cat "$PID_FILE")

if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
  kill "$PID"
  echo "stopped web playground server: $PID"
else
  echo "tracked web playground server was not running: $PID"
fi

rm -f "$PID_FILE"
