@echo off
title DevSync — Real-Time Collaborative Code Editor
color 0A

echo.
echo  ╔═══════════════════════════════════════════╗
echo  ║      DevSync v6  —  Collaborative IDE     ║
echo  ╚═══════════════════════════════════════════╝
echo.

REM Check Node.js
node --version >nul 2>&1
if errorlevel 1 (
    echo  [ERROR] Node.js not found. Please install Node.js 18+ from nodejs.org
    pause
    exit /b 1
)

REM Install server deps if missing
if not exist "server\node_modules" (
    echo  [*] Installing server dependencies...
    cd server
    call npm install
    cd ..
    echo  [OK] Dependencies installed.
    echo.
)

REM Copy .env if missing
if not exist "server\.env" (
    if exist "server\.env.example" (
        copy "server\.env.example" "server\.env" >nul
        echo  [*] Created server\.env from template.
        echo      Edit it to add DATABASE_URL or API keys.
        echo.
    )
)

echo  [*] Starting DevSync server...
echo.
echo  ─────────────────────────────────────────────
echo   Open in browser:  http://localhost:3000
echo   Multi-user test:  http://localhost:3000?room=test
echo  ─────────────────────────────────────────────
echo.
echo  Press Ctrl+C to stop the server.
echo.

node server\index.js
