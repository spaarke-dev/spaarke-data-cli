<#
.SYNOPSIS
    Upload converted document files to SharePoint Embedded via BFF API.

.DESCRIPTION
    For each file in the converted directory, uploads to the demo SPE container
    via BFF API, then patches the corresponding Dataverse document record with
    graphItemId, graphDriveId, and hasFile=true.

.PARAMETER Scenario
    Scenario directory name. Default: scenario-1-meridian

.PARAMETER SpeContainerId
    SPE container ID (per business unit, flat structure).

.PARAMETER BffApiUrl
    BFF API base URL.

.PARAMETER DryRun
    Preview uploads without executing.
#>

[CmdletBinding()]
param(
    [string] $Scenario      = "scenario-1-meridian",
    [string] $SpeContainerId = "b!FzmtPrWQEEi1yPtUOXM4_h7X4udVbCVJgu1ClOi23elAbPdL3-EGQK-D8YZ9tcZp",
    [string] $BffApiUrl,
    [switch] $DryRun
)

$ErrorActionPreference = 'Stop'

# Dot-source shared helpers
. "$PSScriptRoot/Helpers/Invoke-DataverseApi.ps1"

if ($BffApiUrl) { Set-BffApiUrl -Url $BffApiUrl }

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  SPE File Upload (Layer 4)            " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "BFF API:   $($script:BffApiUrl)"
Write-Host "Container: $SpeContainerId"
if ($DryRun) { Write-Host "Mode:      DRY RUN" -ForegroundColor Yellow }
Write-Host ""

# ---------------------------------------------------------------------------
# Paths and data
# ---------------------------------------------------------------------------
$RepoRoot = (Resolve-Path "$PSScriptRoot/../..").Path
$ScenarioDir = Join-Path $RepoRoot "output" $Scenario
$ConvertedDir = Join-Path $ScenarioDir "converted"
$DocumentsPath = Join-Path $ScenarioDir "documents.json"

if (-not (Test-Path $ConvertedDir)) { throw "Converted files directory not found: $ConvertedDir. Run Convert-MarkdownFiles.ps1 first." }
if (-not (Test-Path $DocumentsPath)) { throw "Documents JSON not found: $DocumentsPath" }

$documents = (Get-Content $DocumentsPath -Raw | ConvertFrom-Json)

# Build lookup: sprk_filename → document record
$filenameLookup = @{}
foreach ($doc in $documents.records) {
    if ($doc.sprk_filename) {
        $filenameLookup[$doc.sprk_filename] = $doc
    }
}

# Get auth tokens
$dvHeaders = Get-DataverseToken
$bffToken = $null
if (-not $DryRun) {
    $bffToken = Get-BffToken
}

# ---------------------------------------------------------------------------
# Upload files
# ---------------------------------------------------------------------------
$files = Get-ChildItem -Path $ConvertedDir -File
Write-Host "  Found $($files.Count) files to upload" -ForegroundColor DarkGray
Write-Host ""

$uploaded = 0
$skipped = 0
$errors = 0

foreach ($file in $files) {
    $filename = $file.Name
    $docRecord = $filenameLookup[$filename]

    if (-not $docRecord) {
        Write-Host "  [SKIP] $filename — no matching document record" -ForegroundColor Yellow
        $skipped++
        continue
    }

    $scenarioId = $docRecord.sprk_scenarioid

    # Check if already uploaded (idempotent)
    if (-not $DryRun) {
        $existingId = Find-RecordByScenarioId -EntitySet "sprk_documents" -ScenarioId $scenarioId -Headers $dvHeaders
        if ($existingId) {
            # Check if file is already linked
            $checkUri = "$($script:WebApiUrl)/sprk_documents($existingId)?`$select=sprk_hasfile,sprk_graphitemid"
            try {
                $existing = Invoke-DataverseRequest -Method GET -Uri $checkUri -Headers $dvHeaders
                if ($existing.sprk_hasfile -eq $true -and $existing.sprk_graphitemid) {
                    Write-Host "  [SKIP] $scenarioId — already has file linked ($($existing.sprk_graphitemid))" -ForegroundColor DarkGray
                    $skipped++
                    continue
                }
            } catch { }
        }
    }

    if ($DryRun) {
        Write-Host "  [WOULD] Upload $filename → container ($([math]::Round($file.Length / 1KB, 1)) KB)" -ForegroundColor Gray
        $uploaded++
        continue
    }

    try {
        # Upload file to SPE via BFF API
        $uploadUrl = "$($script:BffApiUrl)/api/containers/$SpeContainerId/files/$filename"
        $fileBytes = [System.IO.File]::ReadAllBytes($file.FullName)

        $uploadHeaders = @{
            'Authorization' = "Bearer $bffToken"
            'Content-Type'  = 'application/octet-stream'
        }

        Write-Host "  Uploading $filename ($([math]::Round($file.Length / 1KB, 1)) KB)..." -ForegroundColor DarkGray

        $response = Invoke-RestMethod -Method PUT -Uri $uploadUrl -Headers $uploadHeaders -Body $fileBytes

        # Extract Graph identifiers from response
        $graphItemId = $null
        $graphDriveId = $null

        if ($response.id) {
            $graphItemId = $response.id
        }
        if ($response.parentReference -and $response.parentReference.driveId) {
            $graphDriveId = $response.parentReference.driveId
        }

        if (-not $graphItemId) {
            Write-Host "  [WARN] Upload succeeded but no graphItemId in response for $filename" -ForegroundColor Yellow
        }

        # Patch Dataverse document record with SPE references
        if ($existingId -and $graphItemId) {
            $patchUri = "$($script:WebApiUrl)/sprk_documents($existingId)"
            $patchBody = @{
                'sprk_graphitemid' = $graphItemId
                'sprk_hasfile'     = $true
            }
            if ($graphDriveId) {
                $patchBody['sprk_graphdriveid'] = $graphDriveId
            }

            Invoke-DataverseRequest -Method PATCH -Uri $patchUri -Headers $dvHeaders -Body $patchBody | Out-Null
            Write-Host "  [OK] $scenarioId → $filename (itemId: $graphItemId)" -ForegroundColor Green
        }
        elseif (-not $existingId) {
            Write-Host "  [WARN] $scenarioId — file uploaded but document record not found in Dataverse" -ForegroundColor Yellow
        }

        $uploaded++
    }
    catch {
        Write-Host "  [ERROR] $scenarioId ($filename) — $_" -ForegroundColor Red
        $errors++
    }
}

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  SPE Upload Summary                   " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Uploaded: $uploaded" -ForegroundColor Green
Write-Host "  Skipped:  $skipped" -ForegroundColor Yellow
Write-Host "  Errors:   $errors" -ForegroundColor $(if ($errors -gt 0) { 'Red' } else { 'Gray' })
if ($DryRun) { Write-Host "  (DRY RUN — no files uploaded)" -ForegroundColor Yellow }
Write-Host ""

if ($errors -gt 0) { exit 1 }
