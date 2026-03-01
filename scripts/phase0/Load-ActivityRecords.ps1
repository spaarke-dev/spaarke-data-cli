# =============================================================================
# Load-ActivityRecords.ps1
# Loads Layer 5 — activity and analytical records into Dataverse.
# Loading order (dependency-driven):
#   1. Events              (depends on matters)
#   2. Communications      (depends on contacts, matters, projects)
#   3. KPI Assessments     (depends on matters)
#   4. Billing Events      (depends on invoices)
#   5. Spend Snapshots     (depends on budgets, matters)
# =============================================================================

$ErrorActionPreference = 'Stop'

# Dot-source shared helpers
. "$PSScriptRoot/Invoke-DataverseApi.ps1"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Loading Activity Records (Layer 5)   " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Acquire auth token
$headers = Get-DataverseToken

# Base path for data files
$dataDir = Join-Path $PSScriptRoot "../../output/scenario-1-meridian"

# Track totals
$totalLoaded = 0
$totalFailed = 0

# ---------------------------------------------------------------------------
# 1. Events (depends on matters)
# ---------------------------------------------------------------------------
$result = Load-EntityFromFile -FilePath "$dataDir/events.json" -Headers $headers
$totalLoaded += $result.Loaded
$totalFailed += $result.Failed

# ---------------------------------------------------------------------------
# 2. Communications (depends on contacts, matters, projects)
# ---------------------------------------------------------------------------
$result = Load-EntityFromFile -FilePath "$dataDir/communications.json" -Headers $headers
$totalLoaded += $result.Loaded
$totalFailed += $result.Failed

# ---------------------------------------------------------------------------
# 3. KPI Assessments (depends on matters)
# ---------------------------------------------------------------------------
$result = Load-EntityFromFile -FilePath "$dataDir/kpi-assessments.json" -Headers $headers
$totalLoaded += $result.Loaded
$totalFailed += $result.Failed

# ---------------------------------------------------------------------------
# 4. Billing Events (depends on invoices)
# ---------------------------------------------------------------------------
$result = Load-EntityFromFile -FilePath "$dataDir/billing-events.json" -Headers $headers
$totalLoaded += $result.Loaded
$totalFailed += $result.Failed

# ---------------------------------------------------------------------------
# 5. Spend Snapshots (depends on budgets, matters)
# ---------------------------------------------------------------------------
$result = Load-EntityFromFile -FilePath "$dataDir/spend-snapshots.json" -Headers $headers
$totalLoaded += $result.Loaded
$totalFailed += $result.Failed

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Activity Records Summary             " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
$summaryColor = if ($totalFailed -gt 0) { 'Yellow' } else { 'Green' }
Write-Host "  Total Loaded: $totalLoaded" -ForegroundColor $summaryColor
Write-Host "  Total Failed: $totalFailed" -ForegroundColor $summaryColor

if ($totalFailed -gt 0) {
    Write-Host "  [WARN] Some records failed. Review errors above." -ForegroundColor Yellow
}
