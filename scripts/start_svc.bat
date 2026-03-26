@echo off
chcp 65001 >nul
echo [INFO] Starting Singing Voice Conversion Web UI...

call "%~dp0..\venv\Scripts\activate.bat" 2>nul || call "%~dp0..\.venv\Scripts\activate.bat" 2>nul

:: Optional: custom checkpoint
set CHECKPOINT=
set CONFIG=

cd "%~dp0..\external\seed-vc"
echo [INFO] Open browser at: http://localhost:7860

if "%CHECKPOINT%"=="" (
    python app_svc.py
) else (
    python app_svc.py --checkpoint %CHECKPOINT% --config %CONFIG%
)

pause
