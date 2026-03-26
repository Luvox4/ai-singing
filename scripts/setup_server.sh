#!/bin/bash
# ==========================================
# AI Singing Voice - Server Setup Script
# For Linux servers with GPU (CUDA)
# ==========================================
set -e

echo "=========================================="
echo " AI Singing Voice - Server Setup (Linux)"
echo "=========================================="

# Check Python
python3 --version || { echo "[ERROR] Python3 not found"; exit 1; }

# Create virtual environment
if [ ! -d ".venv" ]; then
    echo "[INFO] Creating virtual environment..."
    python3 -m venv .venv
fi

source .venv/bin/activate

# Upgrade pip
pip install --upgrade pip

# Install PyTorch with CUDA 12.1
echo "[INFO] Installing PyTorch (CUDA 12.1)..."
pip install torch==2.4.0 torchvision==0.19.0 torchaudio==2.4.0 --index-url https://download.pytorch.org/whl/cu121

# Install seed-vc dependencies
echo "[INFO] Installing seed-vc dependencies..."
cd external/seed-vc
pip install -r requirements.txt
cd ../..

# Copy env
[ -f ".env" ] || cp .env.example .env

echo ""
echo "=========================================="
echo " Setup complete!"
echo " Run training: bash scripts/train_server.sh"
echo "=========================================="
