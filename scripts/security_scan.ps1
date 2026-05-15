<#
.SYNOPSIS
    Local security scan script for SGA developers.
    Run before pushing to catch issues before CI does.

.DESCRIPTION
    Runs 3 security gates locally:
    1. SAST  — Bandit (finds SQL injection, XSS, hardcoded passwords)
    2. SCA   — pip-audit (checks dependencies for known CVEs)
    3. Secrets — basic pattern scan for leaked credentials

.EXAMPLE
    .\scripts\security_scan.ps1
#>

$ErrorActionPreference = "Continue"
$ProjectRoot = Split-Path -Parent $PSScriptRoot

Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "  SGA Security Scan — Local Pre-Push Check" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

$failures = 0

# ── Gate 1: SAST (Bandit) ──────────────────────────
Write-Host "🔐 [1/3] SAST — Running Bandit..." -ForegroundColor Yellow
Write-Host "─────────────────────────────────────────"

$banditInstalled = pip show bandit 2>$null
if (-not $banditInstalled) {
    Write-Host "  Installing bandit..." -ForegroundColor Gray
    pip install bandit -q
}

bandit -r "$ProjectRoot\sga_web" `
    --configfile "$ProjectRoot\.bandit.yaml" `
    --severity-level medium `
    --confidence-level high `
    -f screen

if ($LASTEXITCODE -ne 0) {
    Write-Host "  ❌ SAST: Issues found!" -ForegroundColor Red
    $failures++
} else {
    Write-Host "  ✅ SAST: Clean" -ForegroundColor Green
}

Write-Host ""

# ── Gate 2: SCA (pip-audit) ────────────────────────
Write-Host "📦 [2/3] SCA — Running pip-audit..." -ForegroundColor Yellow
Write-Host "─────────────────────────────────────────"

$pipAuditInstalled = pip show pip-audit 2>$null
if (-not $pipAuditInstalled) {
    Write-Host "  Installing pip-audit..." -ForegroundColor Gray
    pip install pip-audit -q
}

pip-audit -r "$ProjectRoot\requirements.txt"

if ($LASTEXITCODE -ne 0) {
    Write-Host "  ❌ SCA: Vulnerable dependencies found!" -ForegroundColor Red
    $failures++
} else {
    Write-Host "  ✅ SCA: All dependencies clean" -ForegroundColor Green
}

Write-Host ""

# ── Gate 3: Secret Scanning ────────────────────────
Write-Host "🔑 [3/3] Secrets — Scanning for leaked credentials..." -ForegroundColor Yellow
Write-Host "─────────────────────────────────────────"

# Basic regex patterns for common secrets
$patterns = @(
    "password\s*=\s*['\"][^'\"]+['\"]",
    "api[_-]?key\s*=\s*['\"][^'\"]+['\"]",
    "secret[_-]?key\s*=\s*['\"][^'\"]+['\"]",
    "token\s*=\s*['\"][^'\"]+['\"]"
)

$secretsFound = 0
$excludeDirs = @('.git', '.venv', 'node_modules', '__pycache__', 'ORIGINAL CODE', 'poppler-24.08.0')

foreach ($pattern in $patterns) {
    $results = Get-ChildItem -Path $ProjectRoot -Recurse -File -Include "*.py","*.json","*.yml","*.yaml","*.cfg","*.ini" |
        Where-Object {
            $path = $_.FullName
            $excluded = $false
            foreach ($dir in $excludeDirs) {
                if ($path -like "*\$dir\*") { $excluded = $true; break }
            }
            # Also exclude .env files (those SHOULD have secrets) and .example files
            if ($path -like "*.env" -or $path -like "*.example") { $excluded = $true }
            -not $excluded
        } |
        Select-String -Pattern $pattern -CaseSensitive:$false

    if ($results) {
        foreach ($result in $results) {
            # Skip known false positives
            $line = $result.Line.Trim()
            if ($line -like "*os.environ*" -or $line -like "*os.getenv*" -or
                $line -like "*your_*" -or $line -like "*_here*" -or
                $line -like "*#*" -or $line -like "*test*" -or
                $line -like "*example*" -or $line -like "*placeholder*") {
                continue
            }
            Write-Host "  ⚠️  $($result.Filename):$($result.LineNumber) — Possible secret" -ForegroundColor Yellow
            $secretsFound++
        }
    }
}

if ($secretsFound -gt 0) {
    Write-Host "  ❌ Secrets: $secretsFound potential secrets found!" -ForegroundColor Red
    $failures++
} else {
    Write-Host "  ✅ Secrets: No leaked credentials detected" -ForegroundColor Green
}

# ── Summary ────────────────────────────────────────
Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
if ($failures -eq 0) {
    Write-Host "  ✅ ALL GATES PASSED — Safe to push!" -ForegroundColor Green
} else {
    Write-Host "  ❌ $failures GATE(S) FAILED — Fix before pushing!" -ForegroundColor Red
}
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

exit $failures
