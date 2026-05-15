# ============================================================
#  SGA Development Server Launcher (PowerShell)
#  Isolated from production (port 5004)
# ============================================================

$ErrorActionPreference = "Stop"
$Host.UI.RawUI.WindowTitle = "SGA Development Server (Port 5004)"

Set-Location $PSScriptRoot

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  SGA DEVELOPMENT SERVER" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Environment: DEVELOPMENT"
Write-Host "  Port:        5004"
Write-Host "  Database:    SGA_Development (isolated from production)"
Write-Host "  SAP:         Throttled (1 conn, 2s cooldown)"
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# Activate virtual environment
& "$PSScriptRoot\.venv\Scripts\Activate.ps1"

# Ensure logs directory exists
New-Item -ItemType Directory -Force -Path "logs" | Out-Null

# Set environment
$env:SGA_ENV = "development"
$env:FLASK_ENV = "development"

# Navigate to sga_web and start
Set-Location sga_web
Write-Host "Starting dev server..." -ForegroundColor Yellow
Write-Host "Press CTRL+C to stop." -ForegroundColor Yellow
Write-Host ""

try {
    python run_development.py
} catch {
    Write-Host ""
    Write-Host "Server crashed: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "Server stopped. Press Enter to exit." -ForegroundColor Yellow
Read-Host
