#!/bin/bash
# ==========================================
# AI Singing Voice - Server Training Script
# Run this on your GPU server
# ==========================================
set -e

export PATH="$HOME/.local/bin:$PATH"

source .venv/bin/activate 2>/dev/null || source venv/bin/activate
python tools/patch_seed_vc.py

# Load env variables
if [ -f ".env" ]; then
    set -a
    . ./.env
    set +a
fi

# ============ Configuration ============
# 模型配置（歌声转换推荐此配置）
CONFIG="configs/presets/config_dit_mel_seed_uvit_whisper_base_f0_44k.yml"

# 数据集目录
DATASET_DIR="../../data/raw"

# 训练名称
RUN_NAME="my_voice_svc_$(date +%Y%m%d_%H%M)"

# 根据你的GPU显存调整 batch size
# 4GB VRAM -> batch_size=1, 8GB -> 2, 16GB -> 4
BATCH_SIZE=2
MAX_STEPS=2000
SAVE_EVERY=500
NUM_WORKERS=4
# =======================================

cd external/seed-vc

echo "[INFO] Starting training: $RUN_NAME"
echo "[INFO] Config: $CONFIG"
echo "[INFO] Dataset: $DATASET_DIR"
echo "[INFO] Batch size: $BATCH_SIZE, Steps: $MAX_STEPS"
echo ""

python train.py \
    --config "$CONFIG" \
    --dataset-dir "$DATASET_DIR" \
    --run-name "$RUN_NAME" \
    --batch-size "$BATCH_SIZE" \
    --max-steps "$MAX_STEPS" \
    --max-epochs 1000 \
    --save-every "$SAVE_EVERY" \
    --num-workers "$NUM_WORKERS"

echo ""
echo "[INFO] Training complete! Model saved in: external/seed-vc/runs/$RUN_NAME"
