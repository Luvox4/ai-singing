#!/bin/bash
# ==========================================
# AI Singing Voice - Server Setup Script
# For Linux servers with GPU (CUDA)
# ==========================================
set -e

export PATH="$HOME/.local/bin:$PATH"

echo "=========================================="
echo " AI Singing Voice - Server Setup (Linux)"
echo "=========================================="

PIP_INDEX_URL="${PIP_INDEX_URL:-https://pypi.tuna.tsinghua.edu.cn/simple}"
PYTORCH_INDEX_URL="${PYTORCH_INDEX_URL:-https://download.pytorch.org/whl/cu121}"

# Check Python
python3 --version || { echo "[ERROR] Python3 not found"; exit 1; }

# Install uv if needed
if ! command -v uv >/dev/null 2>&1; then
    echo "[INFO] Installing uv..."
    if python3 -m pip --version >/dev/null 2>&1; then
        python3 -m pip install --user uv -i "$PIP_INDEX_URL"
    elif command -v curl >/dev/null 2>&1; then
        curl -LsSf https://astral.sh/uv/install.sh | sh
    elif command -v wget >/dev/null 2>&1; then
        wget -qO- https://astral.sh/uv/install.sh | sh
    else
        echo "[ERROR] Neither pip nor curl/wget is available to install uv"
        exit 1
    fi
    export PATH="$HOME/.local/bin:$PATH"
fi

uv --version

# Ensure submodule is available
if command -v git >/dev/null 2>&1; then
    echo "[INFO] Syncing git submodules..."
    git submodule update --init --recursive
elif [ ! -f "external/seed-vc/requirements.txt" ]; then
    echo "[ERROR] Git is not available and external/seed-vc is missing"
    exit 1
fi

# Create virtual environment
if [ ! -d ".venv" ]; then
    echo "[INFO] Creating uv virtual environment..."
    uv venv --python python3.10 .venv
fi

UV_PYTHON=".venv/bin/python"

echo "[INFO] Applying local seed-vc patches..."
"$UV_PYTHON" tools/patch_seed_vc.py

# Install PyTorch with CUDA 12.1
echo "[INFO] Installing PyTorch (CUDA 12.1)..."
uv pip install --python "$UV_PYTHON" torch==2.4.0 torchvision==0.19.0 torchaudio==2.4.0 --index-url "$PYTORCH_INDEX_URL" --extra-index-url "$PIP_INDEX_URL"

# Install seed-vc dependencies
echo "[INFO] Installing seed-vc dependencies..."
TMP_REQUIREMENTS="$(mktemp)"
grep -Ev '^(torch|torchvision|torchaudio)(==| --pre)' external/seed-vc/requirements.txt > "$TMP_REQUIREMENTS"
uv pip install --python "$UV_PYTHON" -r "$TMP_REQUIREMENTS" --index-url "$PIP_INDEX_URL"
rm -f "$TMP_REQUIREMENTS"

echo "[INFO] Installing local project tools..."
uv pip install --python "$UV_PYTHON" -r requirements-local.txt --index-url "$PIP_INDEX_URL"

# Copy env
[ -f ".env" ] || cp .env.example .env

echo ""
echo "=========================================="
echo " Setup complete!"
echo " Run training: bash scripts/train_server.sh"
echo "=========================================="
