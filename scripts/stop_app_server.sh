#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PID_FILE="$ROOT_DIR/logs/app-webui.pid"

if [ ! -f "$PID_FILE" ]; then
    echo "[INFO] No PID file found"
    exit 0
fi

pid="$(cat "$PID_FILE" 2>/dev/null || true)"
if [ -n "${pid:-}" ] && kill -0 "$pid" 2>/dev/null; then
    kill "$pid"
    echo "[INFO] Stopped App Web UI (PID $pid)"
else
    echo "[INFO] Process not running"
fi

rm -f "$PID_FILE"
