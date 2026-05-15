<#
.SYNOPSIS
    SGA Deployment Script — DEV → PRE-PRODUCTION (same machine)

.DESCRIPTION
    Deploys from SGA_dev to SGAv1.01 on this machine.
    
    Architecture:
      DEV:      SGA_dev     → http://127.0.0.2:5001/
      PRE-PROD: SGAv1.01    → http://192.168.2.218:5000/
      SQL DB:   192.168.2.237 (separate server)
    
    Steps:
      1. Pre-flight tests (ensures code is safe to deploy)
      2. Backup current pre-prod with timestamp
      3. Stop NSSM service
      4. Sync files (robocopy with exclusions)
      5. Restart service + health check
      6. Auto-rollback if health check fails

.EXAMPLE
    .\scripts\deploy.ps1               # Full deploy
    .\scripts\deploy.ps1 -SkipTests    # Skip tests (emergencies only)
    .\scripts\deploy.ps1 -DryRun       # Preview without changes

.PARAMETER SkipTests
    Skip pytest pre-flight check (emergencies only)

.PARAMETER DryRun
    Show what would be deployed without actually doing it
#>

param(
    [switch]$SkipTests,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

# ── Configuration ──
$SourceDir = Split-Path -Parent $PSScriptRoot
$DestDir = Join-Path (Split-Path -Parent $SourceDir) "SGAv1.01"
$ServiceName = "SGA_PreProd"
$HealthUrl = "http://192.168.2.218:5000/health"
$DashboardUrl = "http://192.168.2.218:5000/dashboard"
$BackupRoot = Join-Path (Split-Path -Parent $SourceDir) "SGAv1.01_Backups"

# Get git version for logging
try {
    $gitVersion = (git -C $SourceDir rev-parse --short HEAD 2>$null)
}
catch {
    $gitVersion = "unknown"
}

# Exclusions (matches original deploy_to_preprod.bat + CI additions)
$ExcludeDirs = @('.git', '.venv', '.vscode', '__pycache__', 'unified_db',
    'generated_labels', 'logs', 'data', 'ORIGINAL CODE',
    'original_data', 'poppler-24.08.0', 'node_modules',
    '.pytest_cache', 'tests', '.github')
$ExcludeFiles = @('.env', 'working.json', 'sga_sql_config.json',
    'db_client_config.json', '*.log', '.gitignore',
    'requirements-dev.txt', '.bandit.yaml', '.coverage',
    'bandit_audit_report.txt')

Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "  SGA Deploy: DEV → PRE-PRODUCTION" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "  Version:     $gitVersion"
Write-Host "  Source:      $SourceDir"
Write-Host "  Destination: $DestDir"
Write-Host "  Service:     $ServiceName"
Write-Host "  Health URL:  $HealthUrl"
if ($DryRun) { Write-Host "  Mode:        DRY RUN (no changes)" -ForegroundColor Yellow }
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

# ── Validate Destination ──
if (-not (Test-Path $DestDir)) {
    Write-Host "ERROR: Destination directory does not exist: $DestDir" -ForegroundColor Red
    Write-Host "   Ensure the SGAv1.01 folder is located at the same level as SGA_dev." -ForegroundColor Gray
    exit 1
}

# ── Step 1: Pre-flight Tests ──
if (-not $SkipTests) {
    Write-Host "[1/5] Running pre-flight tests..." -ForegroundColor Yellow
    Push-Location $SourceDir
    try {
        python -m pytest tests/ -x --tb=short -q
        if ($LASTEXITCODE -ne 0) {
            Write-Host "  FAILED - Tests did not pass! Deployment aborted." -ForegroundColor Red
            Write-Host "   Fix the failing tests or use -SkipTests (not recommended)." -ForegroundColor Gray
            exit 1
        }
        Write-Host "  PASSED - All tests green" -ForegroundColor Green
    }
    finally {
        Pop-Location
    }
}
else {
    Write-Host "[1/5] Tests SKIPPED (emergency mode)" -ForegroundColor Yellow
}
Write-Host ""

# ── Step 2: Backup ──
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupDir = Join-Path $BackupRoot "SGAv1.01_$timestamp"
Write-Host "[2/5] Creating backup..." -ForegroundColor Yellow
Write-Host "   -> $backupDir"
if (-not $DryRun) {
    if (-not (Test-Path $BackupRoot)) { New-Item -ItemType Directory -Path $BackupRoot -Force | Out-Null }
    robocopy $DestDir $backupDir /E /NFL /NDL /NJH /NJS /MT:4 /R:1 /W:1 | Out-Null
}
Write-Host "  Backup created" -ForegroundColor Green
Write-Host ""

# ── Step 3: Stop Service ──
Write-Host "[3/5] Stopping service '$ServiceName'..." -ForegroundColor Yellow
if (-not $DryRun) {
    $svcStatus = nssm status $ServiceName 2>$null
    if ($svcStatus -match "SERVICE_RUNNING") {
        nssm stop $ServiceName 2>$null | Out-Null
        Start-Sleep -Seconds 3
        Write-Host "  Service stopped" -ForegroundColor Green
    }
    else {
        Write-Host "  Service was not running" -ForegroundColor Gray
    }
}
else {
    Write-Host "  [DRY RUN] Would stop $ServiceName"
}
Write-Host ""

# ── Step 4: Sync Files ──
Write-Host "[4/5] Syncing files..." -ForegroundColor Yellow
if ($DryRun) {
    Write-Host "  [DRY RUN] Would robocopy from $SourceDir to $DestDir"
    Write-Host "  Excluding dirs: $($ExcludeDirs -join ', ')"
    Write-Host "  Excluding files: $($ExcludeFiles -join ', ')"
}
else {
    $robocopyArgs = @($SourceDir, $DestDir, "/E", "/R:1", "/W:1")
    foreach ($d in $ExcludeDirs) { $robocopyArgs += "/XD"; $robocopyArgs += $d }
    foreach ($f in $ExcludeFiles) { $robocopyArgs += "/XF"; $robocopyArgs += $f }
    & robocopy @robocopyArgs | Out-Null
    # robocopy exit codes 0-7 are success
    if ($LASTEXITCODE -le 7) {
        Write-Host "  Files synced successfully" -ForegroundColor Green
    }
    else {
        Write-Host "  WARNING: robocopy returned exit code $LASTEXITCODE" -ForegroundColor Yellow
    }
}
Write-Host ""

# ── Step 5: Start Service + Health Check ──
Write-Host "[5/5] Starting service and running health check..." -ForegroundColor Yellow
if (-not $DryRun) {
    nssm start $ServiceName 2>$null | Out-Null
    Write-Host "  Service starting... waiting 10s for warmup" -ForegroundColor Gray
    Start-Sleep -Seconds 10

    # Health check with retries
    $maxRetries = 3
    $healthy = $false
    for ($i = 1; $i -le $maxRetries; $i++) {
        try {
            $response = Invoke-RestMethod -Uri $HealthUrl -TimeoutSec 10 -ErrorAction Stop
            if ($response.status -eq 'ok') {
                $healthy = $true
                Write-Host "  Health check PASSED" -ForegroundColor Green
                Write-Host "    Version:  $($response.version)" -ForegroundColor Gray
                Write-Host "    Env:      $($response.environment)" -ForegroundColor Gray
                Write-Host "    Products: $($response.products_loaded)" -ForegroundColor Gray
                Write-Host "    SAP:      $($response.sap_available)" -ForegroundColor Gray
                break
            }
        }
        catch {
            Write-Host "  Health check attempt $i/$maxRetries failed: $($_.Exception.Message)" -ForegroundColor Gray
            if ($i -lt $maxRetries) { Start-Sleep -Seconds 5 }
        }
    }

    if (-not $healthy) {
        Write-Host ""
        Write-Host "  HEALTH CHECK FAILED! Rolling back..." -ForegroundColor Red
        nssm stop $ServiceName 2>$null | Out-Null
        Start-Sleep -Seconds 2
        robocopy $backupDir $DestDir /E /NFL /NDL /NJH /NJS /MT:4 | Out-Null
        nssm start $ServiceName 2>$null | Out-Null
        Write-Host "  Rollback complete. Previous version restored." -ForegroundColor Yellow
        Write-Host "  Check logs at: $DestDir\logs\" -ForegroundColor Gray
        exit 1
    }
}
else {
    Write-Host "  [DRY RUN] Would start $ServiceName and check $HealthUrl"
}

# ── Done ──
Write-Host ""
Write-Host "==================================================" -ForegroundColor Green
Write-Host "  DEPLOYMENT COMPLETE" -ForegroundColor Green
Write-Host "  Version:   $gitVersion" -ForegroundColor Green
Write-Host "  Pre-prod:  $DashboardUrl" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Green
Write-Host ""
