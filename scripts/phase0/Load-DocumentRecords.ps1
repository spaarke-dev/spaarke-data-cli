# =============================================================================
# Load-DocumentRecords.ps1
# Loads Layer 3 — document records with AI enrichment fields into Dataverse.
# Each document record may have lookups to matters and projects.
# Reports counts of records with/without AI enrichment fields.
# =============================================================================

$ErrorActionPreference = 'Stop'

# Dot-source shared helpers
. "$PSScriptRoot/Invoke-DataverseApi.ps1"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Loading Document Records (Layer 3)   " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Acquire auth token
$headers = Get-DataverseToken

# Data file path
$dataFile = Join-Path $PSScriptRoot "../../output/scenario-1-meridian/documents.json"

if (-not (Test-Path $dataFile)) {
    Write-Host "  [ERROR] File not found: $dataFile" -ForegroundColor Red
    exit 1
}

$data = Get-Content $dataFile -Raw | ConvertFrom-Json
$entitySet = $data.entity

Write-Host "`n=== Loading $entitySet ===" -ForegroundColor Cyan
Write-Host "  Source: $dataFile" -ForegroundColor DarkGray
Write-Host "  Records: $($data.records.Count)" -ForegroundColor DarkGray

# AI enrichment fields to check
$aiFields = @(
    'sprk_filesummary',
    'sprk_filetldr',
    'sprk_keywords',
    'sprk_extractorganization',
    'sprk_extractpeople',
    'sprk_extractfees',
    'sprk_extractdates',
    'sprk_extractreference',
    'sprk_extractdocumenttype'
)

$loaded = 0
$failed = 0
$withAiEnrichment = 0
$withoutAiEnrichment = 0

foreach ($record in $data.records) {
    try {
        # Check if this record has AI enrichment
        $hasAi = $false
        foreach ($field in $aiFields) {
            $val = $record.$field
            if ($null -ne $val -and "$val" -ne '' -and "$val" -ne 'null') {
                $hasAi = $true
                break
            }
        }
        if ($hasAi) { $withAiEnrichment++ } else { $withoutAiEnrichment++ }

        # Resolve all lookups (matter, project, invoice references)
        $resolved = Resolve-AllLookups -JsonRecord $record -Headers $headers

        # Upsert the document record
        $success = Upsert-Record -EntitySet $entitySet -Record $resolved -Headers $headers
        if ($success) { $loaded++ } else { $failed++ }
    }
    catch {
        $failed++
        $sid = if ($record.sprk_scenarioid) { $record.sprk_scenarioid } else { "unknown" }
        Write-Host "    [ERROR] Record $sid : $_" -ForegroundColor Red
    }
}

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Document Records Summary             " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$color = if ($failed -gt 0) { 'Yellow' } else { 'Green' }
Write-Host "  Loaded: $loaded" -ForegroundColor $color
Write-Host "  Failed: $failed" -ForegroundColor $color
Write-Host ""
Write-Host "  AI Enrichment:" -ForegroundColor Cyan
Write-Host "    With AI fields:    $withAiEnrichment" -ForegroundColor Green
Write-Host "    Without AI fields: $withoutAiEnrichment" -ForegroundColor $(if ($withoutAiEnrichment -gt 0) { 'Yellow' } else { 'Green' })

if ($failed -gt 0) {
    Write-Host ""
    Write-Host "  [WARN] Some document records failed. Review errors above." -ForegroundColor Yellow
}
