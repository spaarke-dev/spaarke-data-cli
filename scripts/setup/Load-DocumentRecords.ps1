<#
.SYNOPSIS
    Load document records (Layer 3) into Dataverse with AI enrichment fields.
.PARAMETER Scenario
    Scenario directory name. Default: scenario-1-meridian
#>

[CmdletBinding()]
param(
    [string] $Scenario = "scenario-1-meridian"
)

$ErrorActionPreference = 'Stop'

. "$PSScriptRoot/Helpers/Invoke-DataverseApi.ps1"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Loading Document Records (Layer 3)   " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$headers = Get-DataverseToken

$dataFile = Join-Path $PSScriptRoot "../../output/$Scenario/documents.json"
if (-not (Test-Path $dataFile)) { throw "File not found: $dataFile" }

$data = Get-Content $dataFile -Raw | ConvertFrom-Json
$entitySet = $data.entity

Write-Host "`n=== Loading $entitySet ===" -ForegroundColor Cyan
Write-Host "  Source: $dataFile" -ForegroundColor DarkGray
Write-Host "  Records: $($data.records.Count)" -ForegroundColor DarkGray

$aiFields = @('sprk_filesummary','sprk_filetldr','sprk_keywords','sprk_extractorganization',
              'sprk_extractpeople','sprk_extractfees','sprk_extractdates','sprk_extractreference',
              'sprk_extractdocumenttype')

$loaded = 0; $failed = 0; $withAi = 0; $withoutAi = 0

foreach ($record in $data.records) {
    try {
        $hasAi = $false
        foreach ($field in $aiFields) {
            $val = $record.$field
            if ($null -ne $val -and "$val" -ne '' -and "$val" -ne 'null') { $hasAi = $true; break }
        }
        if ($hasAi) { $withAi++ } else { $withoutAi++ }

        $resolved = Resolve-AllLookups -JsonRecord $record -Headers $headers
        $success = Upsert-Record -EntitySet $entitySet -Record $resolved -Headers $headers
        if ($success) { $loaded++ } else { $failed++ }
    }
    catch {
        $failed++
        $sid = if ($record.sprk_scenarioid) { $record.sprk_scenarioid } else { "unknown" }
        Write-Host "    [ERROR] Record $sid : $_" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Document Records Summary             " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
$color = if ($failed -gt 0) { 'Yellow' } else { 'Green' }
Write-Host "  Loaded: $loaded" -ForegroundColor $color
Write-Host "  Failed: $failed" -ForegroundColor $color
Write-Host "  AI Enrichment: $withAi with / $withoutAi without" -ForegroundColor Cyan
if ($failed -gt 0) { exit 1 }
