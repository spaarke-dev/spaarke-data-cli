# =============================================================================
# Load-AllScenario1.ps1
# Master orchestrator — loads all Scenario 1 (Meridian v. Pinnacle) data
# into Dataverse in full dependency order.
#
# Usage:
#   .\Load-AllScenario1.ps1              # Full load including SPE file upload
#   .\Load-AllScenario1.ps1 -SkipFiles   # Data-only load (skip SPE uploads)
# =============================================================================

param(
    [switch]$SkipFiles  # Skip SPE file upload (for data-only loading)
)

$ErrorActionPreference = 'Stop'

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Phase 0: Loading Meridian v. Pinnacle" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ---------------------------------------------------------------------------
# Prerequisites check
# ---------------------------------------------------------------------------
Write-Host "Checking prerequisites..." -ForegroundColor White

# Verify Azure CLI login
try {
    az account show 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Not logged in" }
    Write-Host "  [OK] Azure CLI authenticated" -ForegroundColor Green
}
catch {
    Write-Host "  [ERROR] Not logged in to Azure CLI." -ForegroundColor Red
    Write-Host "  Run 'az login' first, then retry." -ForegroundColor Yellow
    exit 1
}

# Verify data files exist
$dataDir = Join-Path $PSScriptRoot "../../output/scenario-1-meridian"
if (-not (Test-Path $dataDir)) {
    Write-Host "  [ERROR] Data directory not found: $dataDir" -ForegroundColor Red
    Write-Host "  Generate scenario data first." -ForegroundColor Yellow
    exit 1
}
Write-Host "  [OK] Data directory found: $dataDir" -ForegroundColor Green

# Check for required JSON files
$requiredFiles = @(
    "accounts.json", "contacts.json", "matters.json", "projects.json",
    "budgets.json", "invoices.json", "work-assignments.json",
    "documents.json", "events.json", "communications.json",
    "kpi-assessments.json", "billing-events.json", "spend-snapshots.json"
)

$missingFiles = @()
foreach ($f in $requiredFiles) {
    if (-not (Test-Path "$dataDir/$f")) {
        $missingFiles += $f
    }
}
if ($missingFiles.Count -gt 0) {
    Write-Host "  [WARN] Missing data files:" -ForegroundColor Yellow
    foreach ($mf in $missingFiles) {
        Write-Host "    - $mf" -ForegroundColor Yellow
    }
    Write-Host "  Proceeding with available files..." -ForegroundColor Yellow
}
else {
    Write-Host "  [OK] All $($requiredFiles.Count) data files present" -ForegroundColor Green
}

Write-Host ""

$scriptDir = $PSScriptRoot
$startTime = Get-Date

# ---------------------------------------------------------------------------
# Step 1: Core Records (Layers 1-2)
# ---------------------------------------------------------------------------
Write-Host "Step 1 of 4: Core Records (accounts, contacts, matters, projects, budgets, invoices, work assignments)" -ForegroundColor White
Write-Host "------------------------------------------------------------------------" -ForegroundColor DarkGray
& "$scriptDir/Load-CoreRecords.ps1"

# ---------------------------------------------------------------------------
# Step 2: Document Records (Layer 3)
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "Step 2 of 4: Document Records (documents with AI enrichment)" -ForegroundColor White
Write-Host "------------------------------------------------------------------------" -ForegroundColor DarkGray
& "$scriptDir/Load-DocumentRecords.ps1"

# ---------------------------------------------------------------------------
# Step 3: File Upload (Layer 4) — optional
# ---------------------------------------------------------------------------
if (-not $SkipFiles) {
    Write-Host ""
    Write-Host "Step 3 of 4: File Upload (SPE file upload + Dataverse patching)" -ForegroundColor White
    Write-Host "------------------------------------------------------------------------" -ForegroundColor DarkGray
    & "$scriptDir/Upload-SpeFiles.ps1"
}
else {
    Write-Host ""
    Write-Host "Step 3 of 4: File Upload — SKIPPED (-SkipFiles)" -ForegroundColor Yellow
}

# ---------------------------------------------------------------------------
# Step 4: Activity Records (Layer 5)
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "Step 4 of 4: Activity Records (events, communications, KPIs, billing, spend)" -ForegroundColor White
Write-Host "------------------------------------------------------------------------" -ForegroundColor DarkGray
& "$scriptDir/Load-ActivityRecords.ps1"

# ---------------------------------------------------------------------------
# Final Summary
# ---------------------------------------------------------------------------
$endTime  = Get-Date
$duration = $endTime - $startTime

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Loading Complete!                    " -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Duration: $($duration.ToString('mm\:ss'))" -ForegroundColor White
Write-Host "  Target:   https://spaarkedev1.crm.dynamics.com" -ForegroundColor White
if ($SkipFiles) {
    Write-Host "  Files:    Skipped (use without -SkipFiles to upload)" -ForegroundColor Yellow
}
Write-Host ""
Write-Host "  To verify: Open the Spaarke Dev1 environment and check" -ForegroundColor DarkGray
Write-Host "  the Matters area for 'Meridian Corp v. Pinnacle Industries'" -ForegroundColor DarkGray
Write-Host ""
