#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
WEB_DIR="$ROOT_DIR/playground/web"
STATE_DIR="$ROOT_DIR/.server"
PID_FILE="$STATE_DIR/web.pid"
LOG_FILE="$STATE_DIR/web.log"
HOST="${HOST:-0.0.0.0}"
PORT="${PORT:-8080}"
MODE="${1:-foreground}"

mkdir -p "$STATE_DIR"

if [ -f "$PID_FILE" ]; then
  PID=$(cat "$PID_FILE")
  if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
    echo "web playground server already tracked"
    echo "pid: $PID"
    echo "stop it first: scripts/stop-web.sh"
    exit 1
  fi
fi

if [ ! -d "$WEB_DIR" ]; then
  echo "missing web directory: $WEB_DIR" >&2
  exit 1
fi

if [ "$MODE" = "--background" ]; then
  nohup python3 -m http.server "$PORT" --bind "$HOST" --directory "$WEB_DIR" >"$LOG_FILE" 2>&1 &
  PID=$!
  echo "$PID" > "$PID_FILE"

  sleep 1

  if ! kill -0 "$PID" 2>/dev/null; then
    echo "failed to start web playground server" >&2
    echo "log: $LOG_FILE" >&2
    exit 1
  fi

  echo "web playground server started in background"
  echo "pid: $PID"
  echo "url: http://127.0.0.1:$PORT/"
  echo "log: $LOG_FILE"
  echo "stop it before ending the session: scripts/stop-web.sh"
  exit 0
fi

if [ "$MODE" != "foreground" ]; then
  echo "usage: scripts/serve-web.sh [--background]" >&2
  exit 1
fi

echo "$$" > "$PID_FILE"
CHILD_PID=""
cleanup() {
  if [ -n "$CHILD_PID" ] && kill -0 "$CHILD_PID" 2>/dev/null; then
    kill "$CHILD_PID" 2>/dev/null || true
  fi
  rm -f "$PID_FILE"
}
trap cleanup EXIT INT TERM

python3 -m http.server "$PORT" --bind "$HOST" --directory "$WEB_DIR" &
CHILD_PID=$!

echo "web playground server running in foreground"
echo "pid: $$"
echo "child pid: $CHILD_PID"
echo "url: http://127.0.0.1:$PORT/"
echo "log: stdout"
echo "press Ctrl-C or stop the Codex exec session to terminate"

wait "$CHILD_PID"
