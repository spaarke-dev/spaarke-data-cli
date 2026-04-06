<#
.SYNOPSIS
    Remove all demo scenario data from the environment.
.DESCRIPTION
    Deletes Dataverse records in reverse dependency order, clears AI Search
    index entries, and optionally removes SPE files.
.PARAMETER Scenario
    Scenario directory name. Default: scenario-1-meridian
.PARAMETER Prefix
    Scenario ID prefix for matching records. Default: mvp-
.PARAMETER SkipSearch
    Skip AI Search index cleanup.
.PARAMETER SkipSpe
    Skip SPE file cleanup.
.PARAMETER Confirm
    Required safety switch. Must be passed to execute deletion.
#>

[CmdletBinding()]
param(
    [string] $Scenario  = "scenario-1-meridian",
    [string] $Prefix    = "mvp-",
    [string] $SpeContainerId = "b!FzmtPrWQEEi1yPtUOXM4_h7X4udVbCVJgu1ClOi23elAbPdL3-EGQK-D8YZ9tcZp",
    [string] $KnowledgeIndexName = "spaarke-knowledge-index-v2",
    [switch] $SkipSearch,
    [switch] $SkipSpe,
    [switch] $Confirm
)

$ErrorActionPreference = 'Stop'

. "$PSScriptRoot/Helpers/Invoke-DataverseApi.ps1"

Write-Host ""
Write-Host "========================================" -ForegroundColor Red
Write-Host "  REMOVE Demo Data                     " -ForegroundColor Red
Write-Host "========================================" -ForegroundColor Red
Write-Host "Dataverse: $($script:DataverseBaseUrl)"
Write-Host "Prefix:    $Prefix"
Write-Host ""

if (-not $Confirm) {
    Write-Host "  Safety check: pass -Confirm to execute deletion." -ForegroundColor Yellow
    Write-Host "  Example: .\Remove-DemoData.ps1 -Confirm" -ForegroundColor Yellow
    Write-Host ""
    exit 0
}

$dvHeaders = Get-DataverseToken
$totalDeleted = 0

# ---------------------------------------------------------------------------
# Step 1: Delete AI Search index entries
# ---------------------------------------------------------------------------
if (-not $SkipSearch) {
    Write-Host "--- Step 1: AI Search Cleanup ---" -ForegroundColor Cyan
    try {
        $searchHeaders = Get-AiSearchHeaders
        $apiVersion = "2024-07-01"

        # Query all documents in knowledge index that belong to our scenario
        # Delete by querying for documents where documentId matches our records
        $searchUrl = "$($script:SearchServiceUrl)/indexes/$KnowledgeIndexName/docs/search?api-version=$apiVersion"
        $searchBody = @{
            search = "*"
            filter = "parentEntityname eq 'Meridian Corp v. Pinnacle Industries'"
            top    = 1000
            select = "id"
        } | ConvertTo-Json -Compress

        $searchResult = Invoke-RestMethod -Method POST -Uri $searchUrl -Headers $searchHeaders `
            -Body ([System.Text.Encoding]::UTF8.GetBytes($searchBody))

        if ($searchResult.value -and $searchResult.value.Count -gt 0) {
            $deleteActions = $searchResult.value | ForEach-Object {
                @{ '@search.action' = 'delete'; 'id' = $_.id }
            }

            $deleteBody = @{ value = @($deleteActions) } | ConvertTo-Json -Depth 5 -Compress
            $deleteUrl = "$($script:SearchServiceUrl)/indexes/$KnowledgeIndexName/docs/index?api-version=$apiVersion"
            $null = Invoke-RestMethod -Method POST -Uri $deleteUrl -Headers $searchHeaders `
                -Body ([System.Text.Encoding]::UTF8.GetBytes($deleteBody))

            Write-Host "  Deleted $($deleteActions.Count) chunks from $KnowledgeIndexName" -ForegroundColor Green
        }
        else {
            Write-Host "  No chunks found in $KnowledgeIndexName" -ForegroundColor DarkGray
        }
    }
    catch {
        Write-Host "  [WARN] Search cleanup failed: $_" -ForegroundColor Yellow
    }
}
else {
    Write-Host "--- Step 1: AI Search Cleanup --- SKIPPED" -ForegroundColor Yellow
}

# ---------------------------------------------------------------------------
# Step 2: Delete Dataverse records (reverse dependency order)
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "--- Step 2: Dataverse Record Cleanup ---" -ForegroundColor Cyan

# Reverse order: activities first, then documents, then core, then foundation
$entityOrder = @(
    'sprk_spendsnapshots'
    'sprk_billingevents'
    'sprk_kpiassessments'
    'sprk_communications'
    'sprk_events'
    'sprk_documents'
    'sprk_workassignments'
    'sprk_invoices'
    'sprk_budgetbuckets'
    'sprk_budgets'
    'sprk_projects'
    'sprk_matters'
    'contacts'
    'accounts'
)

foreach ($entitySet in $entityOrder) {
    Write-Host ""
    Write-Host "  Deleting from $entitySet..." -ForegroundColor DarkGray
    $deleted = Delete-RecordsByScenarioPrefix -EntitySet $entitySet -Prefix $Prefix -Headers $dvHeaders
    $totalDeleted += $deleted
}

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Removal Summary                      " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Total records deleted: $totalDeleted" -ForegroundColor Green
Write-Host ""
