# =============================================================================
# Remove-Scenario1Data.ps1
# Deletes all Scenario 1 (Meridian v. Pinnacle) data from Dataverse.
# Deletion proceeds in reverse dependency order to avoid referential errors.
#
# Usage:
#   .\Remove-Scenario1Data.ps1              # Dry-run (shows what would be deleted)
#   .\Remove-Scenario1Data.ps1 -Confirm     # Actually deletes records
# =============================================================================

param(
    [switch]$Confirm  # Must be specified to actually delete records
)

$ErrorActionPreference = 'Stop'

# Dot-source shared helpers
. "$PSScriptRoot/Invoke-DataverseApi.ps1"

Write-Host ""
Write-Host "========================================" -ForegroundColor Red
Write-Host "  Remove Scenario 1 Data               " -ForegroundColor Red
Write-Host "========================================" -ForegroundColor Red
Write-Host ""

if (-not $Confirm) {
    Write-Host "  WARNING: This will DELETE all Scenario 1 data from Dataverse!" -ForegroundColor Red
    Write-Host ""
    Write-Host "  This includes ALL records with sprk_scenarioid starting with 'mvp-'" -ForegroundColor Yellow
    Write-Host "  across all entity tables (accounts, contacts, matters, documents, etc.)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Target: https://spaarkedev1.crm.dynamics.com" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  To proceed, run:" -ForegroundColor White
    Write-Host "    .\Remove-Scenario1Data.ps1 -Confirm" -ForegroundColor Cyan
    Write-Host ""
    exit 0
}

# Acquire auth token
$headers = Get-DataverseToken

$prefix = "mvp-"
$totalDeleted = 0

# ---------------------------------------------------------------------------
# Deletion order: reverse dependency (children first, parents last)
# ---------------------------------------------------------------------------

# Layer 5: Activity records (no dependents)
$entityDeletionOrder = @(
    @{ EntitySet = "sprk_spendsnapshots";  Label = "Spend Snapshots" },
    @{ EntitySet = "sprk_billingevents";   Label = "Billing Events" },
    @{ EntitySet = "sprk_kpiassessments";  Label = "KPI Assessments" },
    @{ EntitySet = "sprk_communications";  Label = "Communications" },
    @{ EntitySet = "sprk_events";          Label = "Events" },

    # Layer 4/3: Documents (after activity records that may reference them)
    @{ EntitySet = "sprk_documents";       Label = "Documents" },

    # Layer 2: Dependent entities
    @{ EntitySet = "sprk_workassignments"; Label = "Work Assignments" },
    @{ EntitySet = "sprk_invoices";        Label = "Invoices" },
    @{ EntitySet = "sprk_budgetbuckets";   Label = "Budget Buckets" },
    @{ EntitySet = "sprk_budgets";         Label = "Budgets" },
    @{ EntitySet = "sprk_projects";        Label = "Projects" },

    # Layer 1: Core entities (parents last)
    @{ EntitySet = "sprk_matters";         Label = "Matters" },
    @{ EntitySet = "contacts";             Label = "Contacts" },
    @{ EntitySet = "accounts";             Label = "Accounts" }
)

Write-Host "Deleting records in reverse dependency order..." -ForegroundColor White
Write-Host ""

foreach ($entry in $entityDeletionOrder) {
    $entitySet = $entry.EntitySet
    $label     = $entry.Label

    Write-Host "--- Deleting $label ($entitySet) ---" -ForegroundColor Cyan

    try {
        $deleted = Delete-RecordsByScenarioPrefix `
            -EntitySet $entitySet `
            -Prefix $prefix `
            -Headers $headers

        $totalDeleted += $deleted
        Write-Host "  Deleted: $deleted record(s)" -ForegroundColor $(if ($deleted -gt 0) { 'Green' } else { 'DarkGray' })
    }
    catch {
        Write-Host "  [ERROR] Failed to process $entitySet : $_" -ForegroundColor Red
        Write-Host "  Continuing with next entity..." -ForegroundColor Yellow
    }

    Write-Host ""
}

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Deletion Complete                    " -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Total records deleted: $totalDeleted" -ForegroundColor White
Write-Host "  Prefix filter: '$prefix'" -ForegroundColor DarkGray
Write-Host "  Target: https://spaarkedev1.crm.dynamics.com" -ForegroundColor DarkGray
Write-Host ""

if ($totalDeleted -eq 0) {
    Write-Host "  No scenario records found. The environment may already be clean." -ForegroundColor DarkGray
}
else {
    Write-Host "  NOTE: SPE files (if uploaded) are NOT deleted by this script." -ForegroundColor Yellow
    Write-Host "  SPE container files must be removed separately via the BFF API" -ForegroundColor Yellow
    Write-Host "  or SharePoint Embedded admin tools." -ForegroundColor Yellow
}
Write-Host ""
