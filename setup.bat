@echo off
chcp 65001 >nul
echo ==========================================
echo  AI Singing Voice - Setup Script (Windows)
echo ==========================================
echo.

:: Check Python version
python --version 2>nul || (echo [ERROR] Python not found. Install Python 3.10 from https://python.org && pause && exit /b 1)
echo [OK] Python found

:: Create virtual environment
if not exist ".venv" (
    echo [INFO] Creating virtual environment...
    python -m venv .venv
)
echo [OK] Virtual environment ready

:: Activate venv
call .venv\Scripts\activate.bat

:: Upgrade pip
python -m pip install --upgrade pip

:: Install PyTorch with CUDA (CUDA 12.1 compatible)
echo [INFO] Installing PyTorch with CUDA support...
pip install torch==2.4.0 torchvision==0.19.0 torchaudio==2.4.0 --index-url https://download.pytorch.org/whl/cu121

:: Install seed-vc dependencies
echo [INFO] Installing seed-vc dependencies...
cd external\seed-vc
pip install -r requirements.txt
cd ..\..

:: Install project tools
pip install python-dotenv

:: Copy env file
if not exist ".env" (
    copy .env.example .env
    echo [INFO] .env file created. Edit it to add your HuggingFace token.
)

echo.
echo ==========================================
echo  Setup Complete!
echo  Next steps:
echo  1. Edit .env and add your HuggingFace token
echo  2. Read GUIDE.md for full instructions
echo  3. Run: scripts\start_webui.bat to launch web UI
echo ==========================================
pause
