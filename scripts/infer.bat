@echo off
setlocal
chcp 65001 >nul
echo ==========================================
echo  AI Singing Voice - Inference Script
echo ==========================================
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

set SOURCE=../../data/source_song.wav
set TARGET=../../data/raw/my_voice_sample.wav
set OUTPUT=../../data/processed
set CHECKPOINT=
set CONFIG=
set DIFFUSION_STEPS=30
set PITCH_SHIFT=0

cd /d "%REPO_ROOT%\external\seed-vc"

if "%SOURCE%"=="" (
    echo [ERROR] Please set SOURCE in this script.
    pause & exit /b 1
)
if "%TARGET%"=="" (
    echo [ERROR] Please set TARGET in this script.
    pause & exit /b 1
)

if "%CHECKPOINT%"=="" (
    uv run --no-sync --cache-dir "%REPO_ROOT%\.uv-cache" --python "%UV_PYTHON%" python inference.py ^
        --source %SOURCE% ^
        --target %TARGET% ^
        --output %OUTPUT% ^
        --diffusion-steps %DIFFUSION_STEPS% ^
        --f0-condition True ^
        --semi-tone-shift %PITCH_SHIFT%
) else (
    uv run --no-sync --cache-dir "%REPO_ROOT%\.uv-cache" --python "%UV_PYTHON%" python inference.py ^
        --source %SOURCE% ^
        --target %TARGET% ^
        --output %OUTPUT% ^
        --diffusion-steps %DIFFUSION_STEPS% ^
        --f0-condition True ^
        --semi-tone-shift %PITCH_SHIFT% ^
        --checkpoint %CHECKPOINT% ^
        --config %CONFIG%
)

set "APP_EXIT=%ERRORLEVEL%"
uv run --no-sync --cache-dir "%REPO_ROOT%\.uv-cache" --python "%UV_PYTHON%" python "%REPO_ROOT%\tools\restore_seed_vc.py"
if errorlevel 1 echo [WARN] Failed to restore seed-vc files to a clean state.

echo [INFO] Done! Output saved to: %OUTPUT%
pause
exit /b %APP_EXIT%
