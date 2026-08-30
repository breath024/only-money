# Only Money - Local Server (PowerShell version)
# 실행 방법: 우클릭 -> "PowerShell로 실행" 또는 터미널에서 .\serve.ps1
# 만약 "실행 정책" 오류 나면: powershell -ExecutionPolicy Bypass -File .\serve.ps1

$ErrorActionPreference = 'Continue'
$Host.UI.RawUI.WindowTitle = 'Only Money - Local Server'

Set-Location -Path $PSScriptRoot

Write-Host ""
Write-Host "=============================================================" -ForegroundColor Yellow
Write-Host "  Only Money Dashboard - Local Server" -ForegroundColor Yellow
Write-Host "  Folder: $PSScriptRoot" -ForegroundColor Gray
Write-Host "=============================================================" -ForegroundColor Yellow
Write-Host ""

function Test-RealPython($cmd) {
    try {
        $result = & $cmd -c "import http.server; print('ok')" 2>$null
        return $result -eq 'ok'
    } catch { return $false }
}

$pyCmd = $null
if (Test-RealPython 'python') { $pyCmd = 'python' }
elseif (Test-RealPython 'py') { $pyCmd = 'py' }
elseif (Test-RealPython 'python3') { $pyCmd = 'python3' }

if ($pyCmd) {
    Write-Host "Found: $pyCmd" -ForegroundColor Green
    Write-Host ""
    Write-Host "Starting server at http://localhost:8000 ..." -ForegroundColor Cyan
    Write-Host "Press Ctrl+C to stop the server." -ForegroundColor Gray
    Write-Host ""
    Start-Process "http://localhost:8000"
    try {
        & $pyCmd -m http.server 8000
    } catch {
        Write-Host "[Error] $_" -ForegroundColor Red
    }
    Write-Host ""
    Write-Host "[Server stopped]" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 0
}

# Try Node fallback
if (Get-Command npx -ErrorAction SilentlyContinue) {
    Write-Host "Using Node.js (npx serve)" -ForegroundColor Green
    Start-Process "http://localhost:8000"
    npx --yes serve -p 8000 .
    Read-Host "Press Enter to exit"
    exit 0
}

# Nothing found
Write-Host "[ERROR] Python or Node.js not found." -ForegroundColor Red
Write-Host ""
Write-Host "Install Python from: https://python.org/downloads/" -ForegroundColor Yellow
Write-Host "  - During install: CHECK 'Add Python to PATH'" -ForegroundColor Yellow
Write-Host ""
Write-Host "If Python looks installed but not detected:" -ForegroundColor Yellow
Write-Host "  - You have Microsoft Store stub." -ForegroundColor Yellow
Write-Host "  - Settings > Apps > App execution aliases > turn OFF python.exe" -ForegroundColor Yellow
Write-Host ""
Read-Host "Press Enter to exit"
exit 1
