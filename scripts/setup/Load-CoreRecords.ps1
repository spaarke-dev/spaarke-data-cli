<#
.SYNOPSIS
    Load core business records (Layer 2) into Dataverse.
.DESCRIPTION
    Loads accounts, contacts, matters, projects, budgets, budget buckets,
    invoices, and work assignments in dependency order.
.PARAMETER Scenario
    Scenario directory name. Default: scenario-1-meridian
#>

[CmdletBinding()]
param(
    [string] $Scenario = "scenario-1-meridian"
)

$ErrorActionPreference = 'Stop'

# Dot-source shared helpers
. "$PSScriptRoot/Helpers/Invoke-DataverseApi.ps1"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Loading Core Records (Layer 2)       " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$headers = Get-DataverseToken

$dataDir = Join-Path $PSScriptRoot "../../output/$Scenario"
if (-not (Test-Path $dataDir)) { throw "Scenario data not found: $dataDir" }

$totalLoaded = 0
$totalFailed = 0

# 1. Accounts
$result = Load-EntityFromFile -FilePath "$dataDir/accounts.json" -Headers $headers
$totalLoaded += $result.Loaded; $totalFailed += $result.Failed

# 2. Contacts
$result = Load-EntityFromFile -FilePath "$dataDir/contacts.json" -Headers $headers
$totalLoaded += $result.Loaded; $totalFailed += $result.Failed

# 3. Matters
$result = Load-EntityFromFile -FilePath "$dataDir/matters.json" -Headers $headers
$totalLoaded += $result.Loaded; $totalFailed += $result.Failed

# 4. Projects
$result = Load-EntityFromFile -FilePath "$dataDir/projects.json" -Headers $headers
$totalLoaded += $result.Loaded; $totalFailed += $result.Failed

# 5. Budgets + 6. Budget Buckets
$budgetFile = "$dataDir/budgets.json"
if (Test-Path $budgetFile) {
    $budgetData = Get-Content $budgetFile -Raw | ConvertFrom-Json

    $result = Load-EntityFromFile -FilePath $budgetFile -Headers $headers
    $totalLoaded += $result.Loaded; $totalFailed += $result.Failed

    if ($budgetData.related -and $budgetData.related.records) {
        $relatedEntity = $budgetData.related.entity
        Write-Host "`n=== Loading $relatedEntity ===" -ForegroundColor Cyan
        Write-Host "  Records: $($budgetData.related.records.Count)" -ForegroundColor DarkGray

        foreach ($record in $budgetData.related.records) {
            try {
                $resolved = Resolve-AllLookups -JsonRecord $record -Headers $headers
                $success  = Upsert-Record -EntitySet $relatedEntity -Record $resolved -Headers $headers
                if ($success) { $totalLoaded++ } else { $totalFailed++ }
            }
            catch {
                $totalFailed++
                $sid = if ($record.sprk_scenarioid) { $record.sprk_scenarioid } else { "unknown" }
                Write-Host "    [ERROR] Record $sid : $_" -ForegroundColor Red
            }
        }
    }
}

# 7. Invoices
$result = Load-EntityFromFile -FilePath "$dataDir/invoices.json" -Headers $headers
$totalLoaded += $result.Loaded; $totalFailed += $result.Failed

# 8. Work Assignments
$result = Load-EntityFromFile -FilePath "$dataDir/work-assignments.json" -Headers $headers
$totalLoaded += $result.Loaded; $totalFailed += $result.Failed

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Core Records Summary                 " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
$color = if ($totalFailed -gt 0) { 'Yellow' } else { 'Green' }
Write-Host "  Total Loaded: $totalLoaded" -ForegroundColor $color
Write-Host "  Total Failed: $totalFailed" -ForegroundColor $color
if ($totalFailed -gt 0) { exit 1 }
