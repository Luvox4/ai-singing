@echo off
setlocal
chcp 65001 >nul
echo ==========================================
echo  AI Singing Voice - Setup Script (Windows)
echo ==========================================
echo.

call "%~dp0scripts\resolve_python.bat" || (pause && exit /b 1)
set "BOOTSTRAP_PYTHON=%PYTHON_CMD:"=%"
"%BOOTSTRAP_PYTHON%" --version 2>nul || (echo [ERROR] Python 3.10 not found. Install Python 3.10 and reopen the terminal. && pause && exit /b 1)
echo [OK] Python found

uv --version >nul 2>nul || (echo [ERROR] uv not found. Install uv and reopen the terminal. && pause && exit /b 1)
echo [OK] uv found

git --version >nul 2>nul
if errorlevel 1 (
    if not exist "external\seed-vc\requirements.txt" (
        echo [ERROR] Git not found and external\seed-vc is missing. Install Git or clone with submodules.
        pause
        exit /b 1
    )
) else (
    echo [INFO] Syncing git submodules...
    git submodule update --init --recursive || (echo [ERROR] Failed to initialize git submodules && pause && exit /b 1)
)

if not exist ".venv" (
    echo [INFO] Creating uv virtual environment...
    uv venv --python "%BOOTSTRAP_PYTHON%" .venv || (echo [ERROR] Failed to create .venv && pause && exit /b 1)
)
echo [OK] Virtual environment ready

set "UV_PYTHON=%~dp0.venv\Scripts\python.exe"
if not exist "%UV_PYTHON%" (
    echo [ERROR] Virtual environment python not found: %UV_PYTHON%
    pause
    exit /b 1
)

echo [INFO] Syncing project dependencies from uv.lock...
uv sync --frozen --no-install-project --python "%UV_PYTHON%" --cache-dir .uv-cache --system-certs || (echo [ERROR] uv sync failed && pause && exit /b 1)

echo [INFO] Preparing filtered seed-vc requirements...
"%UV_PYTHON%" tools\prepare_seed_vc_requirements.py || (echo [ERROR] Failed to prepare seed-vc requirements && pause && exit /b 1)

echo [INFO] Installing seed-vc dependencies with uv...
uv pip install --python "%UV_PYTHON%" --cache-dir .uv-cache --system-certs -r .tmp\seed-vc.requirements.filtered.txt --excludes .tmp\seed-vc.exclude.txt webrtcvad-wheels || (echo [ERROR] Failed to install seed-vc dependencies && pause && exit /b 1)

echo [INFO] Applying Windows torch compatibility fix...
"%UV_PYTHON%" tools\fix_torch_windows.py || (echo [ERROR] Failed to apply torch DLL fix && pause && exit /b 1)

echo [INFO] Applying local compatibility patches to seed-vc...
"%UV_PYTHON%" tools\patch_seed_vc.py || (echo [ERROR] Failed to patch external\seed-vc && pause && exit /b 1)

if not exist ".env" (
    copy .env.example .env
    echo [INFO] .env file created. Edit it to add your HuggingFace token.
)

echo.
echo ==========================================
echo  Setup Complete!
echo  Next steps:
echo  1. Edit .env and add your HuggingFace token
echo  2. Read docs\new_computer_setup.md for the current workflow
echo  3. Run: scripts\start_webui.bat to launch web UI
echo ==========================================
endlocal
pause
