#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PATH="$HOME/.local/bin:$PATH"

if [ -f "$ROOT_DIR/.env" ]; then
    set -a
    . "$ROOT_DIR/.env"
    set +a
fi

"$ROOT_DIR/.venv/bin/python" "$ROOT_DIR/tools/patch_seed_vc.py"

HOST="${HOST:-0.0.0.0}"
PORT="${PORT:-7860}"
LOG_DIR="${ROOT_DIR}/logs"
LOG_FILE="${LOG_DIR}/svc-webui.log"
PID_FILE="${LOG_DIR}/svc-webui.pid"

mkdir -p "$LOG_DIR"

if [ -f "$PID_FILE" ]; then
    old_pid="$(cat "$PID_FILE" 2>/dev/null || true)"
    if [ -n "${old_pid:-}" ] && kill -0 "$old_pid" 2>/dev/null; then
        echo "[INFO] SVC Web UI is already running with PID $old_pid"
        echo "[INFO] Log: $LOG_FILE"
        exit 0
    fi
fi

cd "$ROOT_DIR/external/seed-vc"

nohup env \
    GRADIO_SERVER_NAME="$HOST" \
    GRADIO_SERVER_PORT="$PORT" \
    PYTHONUNBUFFERED=1 \
    "$ROOT_DIR/.venv/bin/python" app_svc.py --fp16 False \
    >"$LOG_FILE" 2>&1 &

echo $! > "$PID_FILE"

echo "[INFO] Started SVC Web UI"
echo "[INFO] PID: $(cat "$PID_FILE")"
echo "[INFO] URL: http://$HOST:$PORT"
echo "[INFO] Log: $LOG_FILE"
