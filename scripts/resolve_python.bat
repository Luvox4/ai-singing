@echo off
set "PYTHON_CMD="
for %%I in ("%~dp0..") do set "REPO_ROOT=%%~fI"

if exist "%REPO_ROOT%\.venv\Scripts\python.exe" (
    set "PYTHON_CMD="%REPO_ROOT%\.venv\Scripts\python.exe""
)

if not defined PYTHON_CMD if exist "%REPO_ROOT%\venv\Scripts\python.exe" (
    set "PYTHON_CMD="%REPO_ROOT%\venv\Scripts\python.exe""
)

if defined REQUIRE_VENV if not defined PYTHON_CMD (
    echo [ERROR] Project virtual environment not found. Run setup.bat first.
    exit /b 1
)

if not defined PYTHON_CMD if exist "D:\Program Files\python310\python.exe" (
    set "PYTHON_CMD="D:\Program Files\python310\python.exe""
)

if not defined PYTHON_CMD if exist "%LocalAppData%\Programs\Python\Python310\python.exe" (
    set "PYTHON_CMD="%LocalAppData%\Programs\Python\Python310\python.exe""
)

if not defined PYTHON_CMD (
    py -3.10 --version >nul 2>nul && set "PYTHON_CMD=py -3.10"
)

if not defined PYTHON_CMD (
    python --version >nul 2>nul && set "PYTHON_CMD=python"
)

if not defined PYTHON_CMD (
    echo [ERROR] Python 3.10 not found. Install Python 3.10 and ensure either py -3.10 or python works.
    exit /b 1
)

exit /b 0
