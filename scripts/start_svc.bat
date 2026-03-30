@echo off
chcp 65001 >nul
echo [INFO] Starting Singing Voice Conversion Web UI...

call "%~dp0..\venv\Scripts\activate.bat" 2>nul || call "%~dp0..\.venv\Scripts\activate.bat" 2>nul
python "%~dp0..\tools\patch_seed_vc.py" || (echo [ERROR] Failed to patch seed-vc & pause & exit /b 1)

if exist "%~dp0..\.env" (
    for /f "usebackq tokens=1,* delims==" %%a in ("%~dp0..\.env") do (
        if not "%%a"=="" if not "%%a:~0,1%"=="#" set "%%a=%%b"
    )
)

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
