@echo off
setlocal
chcp 65001 >nul
echo ==========================================
echo  AI Singing Voice - Training Script
echo ==========================================
echo.
echo [INFO] This script fine-tunes the singing voice model on your voice data.
echo [INFO] Place your voice audio files in: data\raw\
echo.

set "REQUIRE_VENV=1"
call "%~dp0resolve_python.bat" || (pause & exit /b 1)
uv --version >nul 2>nul || (echo [ERROR] uv not found. Run setup.bat after installing uv. & pause & exit /b 1)

for %%I in ("%~dp0..") do set "REPO_ROOT=%%~fI"
set "UV_PYTHON=%PYTHON_CMD:"=%"

uv run --no-sync --cache-dir "%REPO_ROOT%\.uv-cache" --python "%UV_PYTHON%" python "%REPO_ROOT%\tools\patch_seed_vc.py" || (echo [ERROR] Failed to patch seed-vc & pause & exit /b 1)

if exist "%REPO_ROOT%\.env" (
    for /f "usebackq tokens=1,* delims==" %%a in ("%REPO_ROOT%\.env") do (
        if not "%%a"=="" if not "%%a:~0,1%"=="#" set "%%a=%%b"
    )
)

set CONFIG=../../configs/presets/config_dit_mel_seed_uvit_whisper_base_f0_44k.yml
set DATASET_DIR=../../data/raw
set RUN_NAME=my_voice_model
set BATCH_SIZE=2
set MAX_STEPS=1000
set SAVE_EVERY=200
set NUM_WORKERS=0

cd /d "%REPO_ROOT%\external\seed-vc"

echo [INFO] Config:       %CONFIG%
echo [INFO] Dataset:      %DATASET_DIR%
echo [INFO] Run name:     %RUN_NAME%
echo [INFO] Max steps:    %MAX_STEPS%
echo.

uv run --no-sync --cache-dir "%REPO_ROOT%\.uv-cache" --python "%UV_PYTHON%" python train.py ^
    --config %CONFIG% ^
    --dataset-dir %DATASET_DIR% ^
    --run-name %RUN_NAME% ^
    --batch-size %BATCH_SIZE% ^
    --max-steps %MAX_STEPS% ^
    --max-epochs 1000 ^
    --save-every %SAVE_EVERY% ^
    --num-workers %NUM_WORKERS%

set "APP_EXIT=%ERRORLEVEL%"
uv run --no-sync --cache-dir "%REPO_ROOT%\.uv-cache" --python "%UV_PYTHON%" python "%REPO_ROOT%\tools\restore_seed_vc.py"
if errorlevel 1 echo [WARN] Failed to restore seed-vc files to a clean state.

echo.
echo [INFO] Training complete! Checkpoint saved in: runs\%RUN_NAME%
pause
exit /b %APP_EXIT%
