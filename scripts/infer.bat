@echo off
chcp 65001 >nul
echo ==========================================
echo  AI Singing Voice - Inference Script
echo ==========================================
echo.

call "%~dp0..\venv\Scripts\activate.bat" 2>nul || call "%~dp0..\.venv\Scripts\activate.bat" 2>nul

:: --- Configuration ---
:: 要转换的歌声文件（源音频）
set SOURCE=../../data/source_song.wav

:: 你的声音参考文件（目标声音）
set TARGET=../../data/raw/my_voice_sample.wav

:: 输出目录
set OUTPUT=../../data/processed

:: 可选：如果已微调，设置你的检查点路径
:: set CHECKPOINT=../../models/checkpoints/my_voice_model/model_final.pth
:: set CONFIG=../../configs/presets/config_dit_mel_seed_uvit_whisper_base_f0_44k.yml
set CHECKPOINT=
set CONFIG=

:: 歌声转换参数
set DIFFUSION_STEPS=30
set PITCH_SHIFT=0

:: --- Run Inference ---
cd "%~dp0..\external\seed-vc"

if "%SOURCE%"=="" (
    echo [ERROR] Please set SOURCE in this script.
    pause & exit /b 1
)
if "%TARGET%"=="" (
    echo [ERROR] Please set TARGET in this script.
    pause & exit /b 1
)

if "%CHECKPOINT%"=="" (
    python inference.py ^
        --source %SOURCE% ^
        --target %TARGET% ^
        --output %OUTPUT% ^
        --diffusion-steps %DIFFUSION_STEPS% ^
        --f0-condition True ^
        --semi-tone-shift %PITCH_SHIFT%
) else (
    python inference.py ^
        --source %SOURCE% ^
        --target %TARGET% ^
        --output %OUTPUT% ^
        --diffusion-steps %DIFFUSION_STEPS% ^
        --f0-condition True ^
        --semi-tone-shift %PITCH_SHIFT% ^
        --checkpoint %CHECKPOINT% ^
        --config %CONFIG%
)

echo [INFO] Done! Output saved to: %OUTPUT%
pause
