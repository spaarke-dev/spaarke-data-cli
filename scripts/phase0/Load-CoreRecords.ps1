# =============================================================================
# Load-CoreRecords.ps1
# Loads Layers 1-2 data into Dataverse in dependency order:
#   1. Accounts
#   2. Contacts        (depends on accounts)
#   3. Matters         (depends on accounts, contacts)
#   4. Projects        (depends on matters)
#   5. Budgets         (depends on matters)
#   6. Budget Buckets  (depends on budgets)
#   7. Invoices        (depends on matters, accounts, contacts)
#   8. Work Assignments(depends on matters, projects, contacts)
# =============================================================================

$ErrorActionPreference = 'Stop'

# Dot-source shared helpers
. "$PSScriptRoot/Invoke-DataverseApi.ps1"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Loading Core Records (Layers 1-2)    " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Acquire auth token
$headers = Get-DataverseToken

# Base path for data files
$dataDir = Join-Path $PSScriptRoot "../../output/scenario-1-meridian"

# Track totals
$totalLoaded = 0
$totalFailed = 0

# ---------------------------------------------------------------------------
# 1. Accounts (no dependencies)
# ---------------------------------------------------------------------------
$result = Load-EntityFromFile -FilePath "$dataDir/accounts.json" -Headers $headers
$totalLoaded += $result.Loaded
$totalFailed += $result.Failed

# ---------------------------------------------------------------------------
# 2. Contacts (depends on accounts via parentcustomerid_account@odata.bind)
# ---------------------------------------------------------------------------
$result = Load-EntityFromFile -FilePath "$dataDir/contacts.json" -Headers $headers
$totalLoaded += $result.Loaded
$totalFailed += $result.Failed

# ---------------------------------------------------------------------------
# 3. Matters (depends on accounts, contacts)
# ---------------------------------------------------------------------------
$result = Load-EntityFromFile -FilePath "$dataDir/matters.json" -Headers $headers
$totalLoaded += $result.Loaded
$totalFailed += $result.Failed

# ---------------------------------------------------------------------------
# 4. Projects (depends on matters)
# ---------------------------------------------------------------------------
$result = Load-EntityFromFile -FilePath "$dataDir/projects.json" -Headers $headers
$totalLoaded += $result.Loaded
$totalFailed += $result.Failed

# ---------------------------------------------------------------------------
# 5. Budgets (depends on matters)
# ---------------------------------------------------------------------------
$budgetFile = "$dataDir/budgets.json"
if (Test-Path $budgetFile) {
    $budgetData = Get-Content $budgetFile -Raw | ConvertFrom-Json

    # Load the main budget records
    $result = Load-EntityFromFile -FilePath $budgetFile -Headers $headers
    $totalLoaded += $result.Loaded
    $totalFailed += $result.Failed

    # ---------------------------------------------------------------------------
    # 6. Budget Buckets (depends on budgets — nested in budgets.json under "related")
    # ---------------------------------------------------------------------------
    if ($budgetData.related -and $budgetData.related.records) {
        $relatedEntity = $budgetData.related.entity
        Write-Host "`n=== Loading $relatedEntity ===" -ForegroundColor Cyan
        Write-Host "  Source: $budgetFile (related section)" -ForegroundColor DarkGray
        Write-Host "  Records: $($budgetData.related.records.Count)" -ForegroundColor DarkGray

        $bucketLoaded = 0
        $bucketFailed = 0

        foreach ($record in $budgetData.related.records) {
            try {
                $resolved = Resolve-AllLookups -JsonRecord $record -Headers $headers
                $success  = Upsert-Record -EntitySet $relatedEntity -Record $resolved -Headers $headers
                if ($success) { $bucketLoaded++ } else { $bucketFailed++ }
            }
            catch {
                $bucketFailed++
                $sid = if ($record.sprk_scenarioid) { $record.sprk_scenarioid } else { "unknown" }
                Write-Host "    [ERROR] Record $sid : $_" -ForegroundColor Red
            }
        }

        $color = if ($bucketFailed -gt 0) { 'Yellow' } else { 'Green' }
        Write-Host "  Result: Loaded=$bucketLoaded, Failed=$bucketFailed" -ForegroundColor $color
        $totalLoaded += $bucketLoaded
        $totalFailed += $bucketFailed
    }
}

# ---------------------------------------------------------------------------
# 7. Invoices (depends on matters, accounts, contacts)
# ---------------------------------------------------------------------------
$result = Load-EntityFromFile -FilePath "$dataDir/invoices.json" -Headers $headers
$totalLoaded += $result.Loaded
$totalFailed += $result.Failed

# ---------------------------------------------------------------------------
# 8. Work Assignments (depends on matters, projects, contacts)
# ---------------------------------------------------------------------------
$result = Load-EntityFromFile -FilePath "$dataDir/work-assignments.json" -Headers $headers
$totalLoaded += $result.Loaded
$totalFailed += $result.Failed

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Core Records Summary                 " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
$summaryColor = if ($totalFailed -gt 0) { 'Yellow' } else { 'Green' }
Write-Host "  Total Loaded: $totalLoaded" -ForegroundColor $summaryColor
Write-Host "  Total Failed: $totalFailed" -ForegroundColor $summaryColor

if ($totalFailed -gt 0) {
    Write-Host "  [WARN] Some records failed. Review errors above." -ForegroundColor Yellow
}
