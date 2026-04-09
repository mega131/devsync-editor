# DevSync — Start Script (PowerShell)
$Host.UI.RawUI.WindowTitle = "DevSync"

Write-Host ""
Write-Host "  ╔═══════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "  ║      DevSync v6  —  Collaborative IDE     ║" -ForegroundColor Cyan
Write-Host "  ╚═══════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Check Node.js
try {
    $nodeVer = node --version 2>&1
    Write-Host "  [OK] Node.js $nodeVer" -ForegroundColor Green
} catch {
    Write-Host "  [ERROR] Node.js not found. Install from https://nodejs.org" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Install server deps if missing
if (-not (Test-Path "server\node_modules")) {
    Write-Host ""
    Write-Host "  [*] Installing server dependencies..." -ForegroundColor Yellow
    Push-Location server
    npm install
    Pop-Location
    Write-Host "  [OK] Dependencies installed." -ForegroundColor Green
}

# Copy .env if missing
if (-not (Test-Path "server\.env") -and (Test-Path "server\.env.example")) {
    Copy-Item "server\.env.example" "server\.env"
    Write-Host ""
    Write-Host "  [*] Created server\.env from template." -ForegroundColor Yellow
    Write-Host "      Edit it to add DATABASE_URL or API keys (optional)." -ForegroundColor DarkYellow
}

Write-Host ""
Write-Host "  [*] Starting DevSync server..." -ForegroundColor Green
Write-Host ""
Write-Host "  ─────────────────────────────────────────────" -ForegroundColor DarkCyan
Write-Host "   Open in browser:  http://localhost:3000" -ForegroundColor White
Write-Host "   Multi-user test:  http://localhost:3000?room=test" -ForegroundColor White
Write-Host "  ─────────────────────────────────────────────" -ForegroundColor DarkCyan
Write-Host ""
Write-Host "  Press Ctrl+C to stop." -ForegroundColor DarkGray
Write-Host ""

node server\index.js
