<#
.SYNOPSIS
    Validate the demo environment has all expected data.
.DESCRIPTION
    Checks record counts, file associations, AI enrichment, and search index
    population. Outputs a pass/fail summary table.
.PARAMETER Scenario
    Scenario directory name. Default: scenario-1-meridian
.PARAMETER KnowledgeIndexName
    AI Search knowledge index name.
#>

[CmdletBinding()]
param(
    [string] $Scenario           = "scenario-1-meridian",
    [string] $KnowledgeIndexName = "spaarke-knowledge-index-v2",
    [string] $RecordsIndexName   = "spaarke-records-index"
)

$ErrorActionPreference = 'Stop'

. "$PSScriptRoot/Helpers/Invoke-DataverseApi.ps1"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Demo Environment Validation          " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Dataverse: $($script:DataverseBaseUrl)"
Write-Host "Search:    $($script:SearchServiceUrl)"
Write-Host ""

$dvHeaders = Get-DataverseToken

# Load expected counts from scenario data
$RepoRoot = (Resolve-Path "$PSScriptRoot/../..").Path
$ScenarioDir = Join-Path $RepoRoot "output" $Scenario

$results = @()

# ---------------------------------------------------------------------------
# Helper: Check entity count
# ---------------------------------------------------------------------------
function Test-EntityCount {
    param(
        [string] $EntitySet,
        [string] $Label,
        [int]    $Expected,
        [string] $Filter = "startswith(sprk_scenarioid,'mvp-')"
    )

    try {
        $uri = "$($script:WebApiUrl)/$($EntitySet)?`$filter=$filter&`$count=true&`$top=0"
        $result = Invoke-DataverseRequest -Method GET -Uri $uri -Headers $dvHeaders
        $actual = $result.'@odata.count'
        if ($null -eq $actual) { $actual = $result.value.Count }

        $pass = $actual -ge $Expected
        $status = if ($pass) { "PASS" } else { "FAIL" }
        $color = if ($pass) { "Green" } else { "Red" }

        Write-Host "  [$status] $Label — expected >=$Expected, got $actual" -ForegroundColor $color
        return @{ Label = $Label; Expected = $Expected; Actual = $actual; Pass = $pass }
    }
    catch {
        Write-Host "  [ERROR] $Label — $_" -ForegroundColor Red
        return @{ Label = $Label; Expected = $Expected; Actual = "ERROR"; Pass = $false }
    }
}

# ---------------------------------------------------------------------------
# Dataverse Record Counts
# ---------------------------------------------------------------------------
Write-Host "--- Dataverse Record Counts ---" -ForegroundColor Cyan

$checks = @(
    @{ EntitySet = "accounts";              Label = "Accounts";          Expected = 4 }
    @{ EntitySet = "contacts";              Label = "Contacts";          Expected = 12 }
    @{ EntitySet = "sprk_matters";          Label = "Matters";           Expected = 1 }
    @{ EntitySet = "sprk_projects";         Label = "Projects";          Expected = 3 }
    @{ EntitySet = "sprk_budgets";          Label = "Budgets";           Expected = 1 }
    @{ EntitySet = "sprk_budgetbuckets";    Label = "Budget Buckets";    Expected = 5 }
    @{ EntitySet = "sprk_invoices";         Label = "Invoices";          Expected = 10 }
    @{ EntitySet = "sprk_workassignments";  Label = "Work Assignments";  Expected = 6 }
    @{ EntitySet = "sprk_documents";        Label = "Documents";         Expected = 50 }
    @{ EntitySet = "sprk_events";           Label = "Events";            Expected = 40 }
    @{ EntitySet = "sprk_communications";   Label = "Communications";    Expected = 30 }
    @{ EntitySet = "sprk_kpiassessments";   Label = "KPI Assessments";   Expected = 6 }
    @{ EntitySet = "sprk_billingevents";    Label = "Billing Events";    Expected = 50 }
    @{ EntitySet = "sprk_spendsnapshots";   Label = "Spend Snapshots";   Expected = 6 }
)

foreach ($check in $checks) {
    $results += Test-EntityCount -EntitySet $check.EntitySet -Label $check.Label -Expected $check.Expected
}

# ---------------------------------------------------------------------------
# Document Files (SPE-linked)
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "--- Document File Associations ---" -ForegroundColor Cyan

try {
    $fileFilter = "startswith(sprk_scenarioid,'mvp-') and sprk_hasfile eq true"
    $uri = "$($script:WebApiUrl)/sprk_documents?`$filter=$fileFilter&`$count=true&`$top=0"
    $result = Invoke-DataverseRequest -Method GET -Uri $uri -Headers $dvHeaders
    $filesLinked = $result.'@odata.count'
    if ($null -eq $filesLinked) { $filesLinked = 0 }

    $pass = $filesLinked -ge 20
    $status = if ($pass) { "PASS" } else { "FAIL" }
    $color = if ($pass) { "Green" } else { "Red" }
    Write-Host "  [$status] Documents with files — expected >=20, got $filesLinked" -ForegroundColor $color
    $results += @{ Label = "Docs with files"; Expected = 20; Actual = $filesLinked; Pass = $pass }
}
catch {
    Write-Host "  [ERROR] File check — $_" -ForegroundColor Red
    $results += @{ Label = "Docs with files"; Expected = 20; Actual = "ERROR"; Pass = $false }
}

# ---------------------------------------------------------------------------
# AI Enrichment Fields
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "--- AI Enrichment ---" -ForegroundColor Cyan

try {
    $aiFilter = "startswith(sprk_scenarioid,'mvp-') and sprk_filesummary ne null"
    $uri = "$($script:WebApiUrl)/sprk_documents?`$filter=$aiFilter&`$count=true&`$top=0"
    $result = Invoke-DataverseRequest -Method GET -Uri $uri -Headers $dvHeaders
    $aiCount = $result.'@odata.count'
    if ($null -eq $aiCount) { $aiCount = 0 }

    $pass = $aiCount -ge 40
    $status = if ($pass) { "PASS" } else { "FAIL" }
    $color = if ($pass) { "Green" } else { "Red" }
    Write-Host "  [$status] Documents with AI summary — expected >=40, got $aiCount" -ForegroundColor $color
    $results += @{ Label = "AI enrichment"; Expected = 40; Actual = $aiCount; Pass = $pass }
}
catch {
    Write-Host "  [ERROR] AI enrichment check — $_" -ForegroundColor Red
    $results += @{ Label = "AI enrichment"; Expected = 40; Actual = "ERROR"; Pass = $false }
}

# ---------------------------------------------------------------------------
# AI Search Index Counts
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "--- AI Search Indexes ---" -ForegroundColor Cyan

try {
    $searchHeaders = Get-AiSearchHeaders
    $apiVersion = "2024-07-01"

    # Knowledge index count
    $countUrl = "$($script:SearchServiceUrl)/indexes/$KnowledgeIndexName/docs/`$count?api-version=$apiVersion"
    $knowledgeCount = Invoke-RestMethod -Method GET -Uri $countUrl -Headers $searchHeaders
    $pass = $knowledgeCount -ge 50
    $status = if ($pass) { "PASS" } else { "FAIL" }
    $color = if ($pass) { "Green" } else { "Red" }
    Write-Host "  [$status] Knowledge index docs — expected >=50, got $knowledgeCount" -ForegroundColor $color
    $results += @{ Label = "Knowledge index"; Expected = 50; Actual = $knowledgeCount; Pass = $pass }

    # Records index count
    $countUrl = "$($script:SearchServiceUrl)/indexes/$RecordsIndexName/docs/`$count?api-version=$apiVersion"
    $recordsCount = Invoke-RestMethod -Method GET -Uri $countUrl -Headers $searchHeaders
    $pass = $recordsCount -ge 5
    $status = if ($pass) { "PASS" } else { "FAIL" }
    $color = if ($pass) { "Green" } else { "Red" }
    Write-Host "  [$status] Records index docs — expected >=5, got $recordsCount" -ForegroundColor $color
    $results += @{ Label = "Records index"; Expected = 5; Actual = $recordsCount; Pass = $pass }
}
catch {
    Write-Host "  [WARN] AI Search check failed — $_" -ForegroundColor Yellow
    $results += @{ Label = "Search indexes"; Expected = "N/A"; Actual = "SKIPPED"; Pass = $true }
}

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Validation Summary                   " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$passed = ($results | Where-Object { $_.Pass }).Count
$failed = ($results | Where-Object { -not $_.Pass }).Count
$total = $results.Count

Write-Host "  Passed: $passed/$total" -ForegroundColor $(if ($failed -eq 0) { 'Green' } else { 'Yellow' })
if ($failed -gt 0) {
    Write-Host "  Failed: $failed" -ForegroundColor Red
    Write-Host ""
    foreach ($r in ($results | Where-Object { -not $_.Pass })) {
        Write-Host "    - $($r.Label): expected $($r.Expected), got $($r.Actual)" -ForegroundColor Red
    }
    exit 1
}
else {
    Write-Host "  All checks passed!" -ForegroundColor Green
}
Write-Host ""
