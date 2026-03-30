@echo off
chcp 65001 >nul
echo ==========================================
echo  AI Singing Voice - Training Script
echo ==========================================
echo.
echo [INFO] This script fine-tunes the singing voice model on your voice data.
echo [INFO] Place your voice audio files in: data\raw\
echo.

call "%~dp0..\venv\Scripts\activate.bat" 2>nul || call "%~dp0..\.venv\Scripts\activate.bat" 2>nul
python "%~dp0..\tools\patch_seed_vc.py" || (echo [ERROR] Failed to patch seed-vc & pause & exit /b 1)

if exist "%~dp0..\.env" (
    for /f "usebackq tokens=1,* delims==" %%a in ("%~dp0..\.env") do (
        if not "%%a"=="" if not "%%a:~0,1%"=="#" set "%%a=%%b"
    )
)

:: --- Configuration ---
:: 模型配置：用于歌声转换（推荐）
set CONFIG=../../configs/presets/config_dit_mel_seed_uvit_whisper_base_f0_44k.yml

:: 数据集目录（相对于 seed-vc 目录）
set DATASET_DIR=../../data/raw

:: 训练运行名称（用于保存模型）
set RUN_NAME=my_voice_model

:: 训练参数
set BATCH_SIZE=2
set MAX_STEPS=1000
set SAVE_EVERY=200
set NUM_WORKERS=0

:: --- Start Training ---
cd "%~dp0..\external\seed-vc"

echo [INFO] Config:       %CONFIG%
echo [INFO] Dataset:      %DATASET_DIR%
echo [INFO] Run name:     %RUN_NAME%
echo [INFO] Max steps:    %MAX_STEPS%
echo.

python train.py ^
    --config %CONFIG% ^
    --dataset-dir %DATASET_DIR% ^
    --run-name %RUN_NAME% ^
    --batch-size %BATCH_SIZE% ^
    --max-steps %MAX_STEPS% ^
    --max-epochs 1000 ^
    --save-every %SAVE_EVERY% ^
    --num-workers %NUM_WORKERS%

echo.
echo [INFO] Training complete! Checkpoint saved in: runs\%RUN_NAME%
pause
