<#
.SYNOPSIS
    Upload converted document files to SharePoint Embedded via Microsoft Graph
    DIRECTLY, using the BFF API's service principal credentials (bypasses BFF).

.DESCRIPTION
    Same outcome as Upload-SpeFiles.ps1, but skips the BFF API. Acquires a Graph
    token via client_credentials flow as the BFF SP (which is the container
    owner and has FileStorageContainer.ReadWrite.All), then PUTs each file to
    /drives/{containerId}/root:/{filename}:/content. Patches each sprk_document
    with graphItemId/graphDriveId/hasFile=true.

    Use this when the BFF App Service is unavailable.

.PARAMETER Scenario
    Scenario directory name. Default: scenario-1-meridian

.PARAMETER SpeContainerId
    SPE container ID.

.PARAMETER TenantId
    Entra tenant ID for the BFF SP.

.PARAMETER BffClientId
    BFF API app/client ID (the container owner).

.PARAMETER KeyVaultName
    Key Vault containing BFF-API-ClientSecret.

.PARAMETER DryRun
    Preview uploads without executing.
#>

[CmdletBinding()]
param(
    [string] $Scenario       = "scenario-1-meridian",
    [string] $SpeContainerId = "b!FzmtPrWQEEi1yPtUOXM4_h7X4udVbCVJgu1ClOi23elAbPdL3-EGQK-D8YZ9tcZp",
    [string] $TenantId       = "a221a95e-6abc-4434-aecc-e48338a1b2f2",
    [string] $BffClientId    = "da03fe1a-4b1d-4297-a4ce-4b83cae498a9",
    [string] $KeyVaultName   = "sprk-demo-kv",
    [switch] $DryRun
)

$ErrorActionPreference = 'Stop'

. "$PSScriptRoot/Helpers/Invoke-DataverseApi.ps1"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  SPE File Upload (Direct Graph)       " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Tenant:    $TenantId"
Write-Host "Client:    $BffClientId"
Write-Host "Container: $SpeContainerId"
if ($DryRun) { Write-Host "Mode:      DRY RUN" -ForegroundColor Yellow }
Write-Host ""

# ---------------------------------------------------------------------------
# Acquire Graph token via client_credentials as BFF SP
# ---------------------------------------------------------------------------
function Get-GraphAppToken {
    param(
        [Parameter(Mandatory)] [string] $TenantId,
        [Parameter(Mandatory)] [string] $ClientId,
        [Parameter(Mandatory)] [string] $ClientSecret
    )

    $tokenUrl = "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token"
    $body = @{
        client_id     = $ClientId
        client_secret = $ClientSecret
        grant_type    = 'client_credentials'
        scope         = 'https://graph.microsoft.com/.default'
    }

    $resp = Invoke-RestMethod -Method POST -Uri $tokenUrl `
        -ContentType 'application/x-www-form-urlencoded' -Body $body
    return $resp.access_token
}

# ---------------------------------------------------------------------------
# Paths and data
# ---------------------------------------------------------------------------
$RepoRoot      = (Resolve-Path "$PSScriptRoot/../..").Path
$ScenarioDir   = Join-Path $RepoRoot "output" $Scenario
$ConvertedDir  = Join-Path $ScenarioDir "converted"
$DocumentsPath = Join-Path $ScenarioDir "documents.json"

if (-not (Test-Path $ConvertedDir)) { throw "Converted files directory not found: $ConvertedDir" }
if (-not (Test-Path $DocumentsPath)) { throw "Documents JSON not found: $DocumentsPath" }

$documents = (Get-Content $DocumentsPath -Raw | ConvertFrom-Json)
$filenameLookup = @{}
foreach ($doc in $documents.records) {
    if ($doc.sprk_filename) { $filenameLookup[$doc.sprk_filename] = $doc }
}

# ---------------------------------------------------------------------------
# Auth
# ---------------------------------------------------------------------------
$dvHeaders = Get-DataverseToken
$graphToken = $null

if (-not $DryRun) {
    Write-Host "  Retrieving BFF client secret from Key Vault '$KeyVaultName'..." -ForegroundColor DarkGray
    $bffSecret = (az keyvault secret show --vault-name $KeyVaultName --name "BFF-API-ClientSecret" --query value -o tsv 2>&1)
    if ($LASTEXITCODE -ne 0 -or -not $bffSecret) {
        throw "Failed to retrieve BFF-API-ClientSecret: $bffSecret"
    }

    Write-Host "  Acquiring Graph token via client_credentials..." -ForegroundColor DarkGray
    $graphToken = Get-GraphAppToken -TenantId $TenantId -ClientId $BffClientId -ClientSecret $bffSecret
    Write-Host "  Graph token acquired (length=$($graphToken.Length))" -ForegroundColor DarkGray
}

# ---------------------------------------------------------------------------
# Upload loop
# ---------------------------------------------------------------------------
$files = Get-ChildItem -Path $ConvertedDir -File
Write-Host ""
Write-Host "  Found $($files.Count) files to upload" -ForegroundColor DarkGray
Write-Host ""

$uploaded = 0
$skipped  = 0
$errors   = 0

foreach ($file in $files) {
    $filename  = $file.Name
    $docRecord = $filenameLookup[$filename]

    if (-not $docRecord) {
        Write-Host "  [SKIP] $filename - no matching document record" -ForegroundColor Yellow
        $skipped++
        continue
    }

    $scenarioId = $docRecord.sprk_scenarioid

    # Idempotency: skip if already uploaded
    $existingId = $null
    if (-not $DryRun) {
        $existingId = Find-RecordByScenarioId -EntitySet "sprk_documents" -ScenarioId $scenarioId -Headers $dvHeaders
        if ($existingId) {
            try {
                $checkUri = "$($script:WebApiUrl)/sprk_documents($existingId)?`$select=sprk_hasfile,sprk_graphitemid"
                $existing = Invoke-DataverseRequest -Method GET -Uri $checkUri -Headers $dvHeaders
                if ($existing.sprk_hasfile -eq $true -and $existing.sprk_graphitemid) {
                    Write-Host "  [SKIP] $scenarioId already has file linked ($($existing.sprk_graphitemid))" -ForegroundColor DarkGray
                    $skipped++
                    continue
                }
            } catch { }
        }
    }

    if ($DryRun) {
        Write-Host "  [WOULD] Upload $filename ($([math]::Round($file.Length / 1KB, 1)) KB) -> $scenarioId" -ForegroundColor Gray
        $uploaded++
        continue
    }

    try {
        # Graph SPE upload (simple PUT for files < 4MB; all our files are tiny)
        $uploadUrl = "https://graph.microsoft.com/v1.0/drives/$SpeContainerId/root:/${filename}:/content"
        $fileBytes = [System.IO.File]::ReadAllBytes($file.FullName)

        Write-Host "  Uploading $filename ($([math]::Round($file.Length / 1KB, 1)) KB)..." -ForegroundColor DarkGray

        $resp = Invoke-RestMethod -Method PUT -Uri $uploadUrl -Headers @{
            'Authorization' = "Bearer $graphToken"
            'Content-Type'  = 'application/octet-stream'
        } -Body $fileBytes

        $graphItemId  = $resp.id
        $graphDriveId = $resp.parentReference.driveId

        if (-not $graphItemId) {
            Write-Host "  [WARN] Upload OK but no id in response for $filename" -ForegroundColor Yellow
        }

        # Patch the Dataverse record
        if ($existingId -and $graphItemId) {
            $patchUri = "$($script:WebApiUrl)/sprk_documents($existingId)"
            $patchBody = @{
                'sprk_graphitemid' = $graphItemId
                'sprk_hasfile'     = $true
            }
            if ($graphDriveId) { $patchBody['sprk_graphdriveid'] = $graphDriveId }

            Invoke-DataverseRequest -Method PATCH -Uri $patchUri -Headers $dvHeaders -Body $patchBody | Out-Null
            Write-Host "  [OK] $scenarioId -> $filename (itemId: $graphItemId)" -ForegroundColor Green
        }
        elseif (-not $existingId) {
            Write-Host "  [WARN] $scenarioId file uploaded but no Dataverse record found" -ForegroundColor Yellow
        }

        $uploaded++
    }
    catch {
        $errMsg = $_.Exception.Message
        try {
            if ($_.ErrorDetails -and $_.ErrorDetails.Message) {
                $parsed = $_.ErrorDetails.Message | ConvertFrom-Json
                if ($parsed.error -and $parsed.error.message) { $errMsg = $parsed.error.message }
            }
        } catch { }
        Write-Host "  [ERROR] $scenarioId ($filename) - $errMsg" -ForegroundColor Red
        $errors++
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  SPE Upload (Direct) Summary          " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Uploaded: $uploaded" -ForegroundColor Green
Write-Host "  Skipped:  $skipped" -ForegroundColor Yellow
Write-Host "  Errors:   $errors" -ForegroundColor $(if ($errors -gt 0) { 'Red' } else { 'Gray' })
if ($DryRun) { Write-Host "  (DRY RUN)" -ForegroundColor Yellow }
Write-Host ""

if ($errors -gt 0) { exit 1 }
