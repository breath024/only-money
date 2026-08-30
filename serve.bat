@echo off
chcp 65001 >nul 2>nul
cd /d "%~dp0"
title Only Money - Local Server

echo.
echo ============================================================
echo   Only Money Dashboard - Local Server
echo   Folder: %CD%
echo ============================================================
echo.

REM === Test Python (rejects Microsoft Store stub) ===
python -c "import http.server" >nul 2>nul
if not errorlevel 1 (
    set "PY=python"
    goto :run
)

py -c "import http.server" >nul 2>nul
if not errorlevel 1 (
    set "PY=py"
    goto :run
)

REM === Try Node fallback ===
where npx >nul 2>nul
if not errorlevel 1 (
    echo Using Node.js (npx serve)
    echo.
    echo Opening browser at http://localhost:8000 ...
    echo Press Ctrl+C in this window to stop.
    echo.
    start "" http://localhost:8000
    call npx --yes serve -p 8000 .
    echo.
    echo [Server stopped]
    pause
    exit /b 0
)

REM === Nothing found - clear instructions + KEEP WINDOW OPEN ===
echo [ERROR] Python or Node.js not found on PATH.
echo.
echo  How to fix:
echo  ----------
echo  Option 1: Install Python (recommended)
echo    1. https://python.org/downloads/
echo    2. Download Python 3.x for Windows
echo    3. CHECK "Add Python to PATH" during install
echo.
echo  Option 2: If Python "installed" but not detected,
echo    you probably have Microsoft Store stub.
echo    Settings ^> Apps ^> App execution aliases
echo    ^> Turn OFF "python.exe" and "python3.exe"
echo    Then run a real installer from python.org
echo.
echo  Option 3: Install Node.js from https://nodejs.org/
echo.
pause
exit /b 1

:run
echo Found: %PY%
echo.
echo Starting server at http://localhost:8000 ...
echo Press Ctrl+C in this window to stop the server.
echo (Keep this window open while using the dashboard)
echo.
start "" http://localhost:8000
%PY% -m http.server 8000
echo.
echo [Server stopped or crashed - check messages above]
pause
exit /b 0
