#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
STATE_DIR="$ROOT_DIR/.server"
PID_FILE="$STATE_DIR/usagi-preview.pid"
LOG_FILE="$STATE_DIR/usagi-preview.log"
HOST="${HOST:-127.0.0.1}"
PORT="${PORT:-8090}"
PREVIEW_DIR="${PREVIEW_DIR:-$ROOT_DIR/.preview/usagi-demo-web}"

mkdir -p "$STATE_DIR"

if [ -f "$PID_FILE" ]; then
  PID=$(cat "$PID_FILE")
  if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
    echo "Usagi preview server already tracked"
    echo "pid: $PID"
    echo "stop it first: scripts/stop-usagi-preview.sh"
    exit 1
  fi
fi

if [ ! -d "$PREVIEW_DIR" ]; then
  echo "missing preview directory: $PREVIEW_DIR" >&2
  exit 1
fi

setsid nohup python3 -m http.server "$PORT" --bind "$HOST" --directory "$PREVIEW_DIR" >"$LOG_FILE" 2>&1 &
PID=$!
echo "$PID" > "$PID_FILE"

sleep 1

if ! kill -0 "$PID" 2>/dev/null; then
  echo "failed to start Usagi preview server" >&2
  echo "log: $LOG_FILE" >&2
  exit 1
fi

echo "Usagi preview server started"
echo "pid: $PID"
echo "url: http://$HOST:$PORT/"
echo "directory: $PREVIEW_DIR"
echo "log: $LOG_FILE"
echo "stop: scripts/stop-usagi-preview.sh"
