# =============================================================================
# Upload-SpeFiles.ps1
# Loads Layer 4 — uploads files to SPE via BFF API and patches document
# records in Dataverse with SPE graph references.
#
# Flow per file:
#   1. Look up the document record in Dataverse by sprk_scenarioid
#   2. Determine the SPE container for the matter (via BFF API)
#   3. Upload the file to SPE via BFF API
#   4. PATCH the document record with graphItemId, graphDriveId, hasFile, status
#
# NOTE: The BFF API authentication and endpoint paths may need adjustment
#       based on the actual BFF API implementation. The auth token resource
#       may differ from the Dataverse resource URL. If the BFF API requires
#       a different Azure AD resource (e.g., api://<client-id>), update the
#       Get-BffToken function accordingly.
# =============================================================================

$ErrorActionPreference = 'Stop'

# Dot-source shared helpers
. "$PSScriptRoot/Invoke-DataverseApi.ps1"

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
$BffApiBaseUrl = "https://spe-api-dev-67e2xz.azurewebsites.net"

# ---------------------------------------------------------------------------
# Get-BffToken
#   Acquires a Bearer token for the BFF API.
#   NOTE: The resource URL may need adjustment. If the BFF API is registered
#   as a separate Azure AD app, use its Application ID URI instead.
# ---------------------------------------------------------------------------
function Get-BffToken {
    [CmdletBinding()]
    param()

    Write-Host "  Acquiring BFF API access token via Azure CLI..." -ForegroundColor DarkGray

    # Try the BFF API resource first; fall back to common resource
    # Adjust this resource URI based on your BFF API's Azure AD registration
    $bffResource = "api://spe-api-dev-67e2xz"

    try {
        $token = (az account get-access-token `
            --resource $bffResource `
            --query accessToken -o tsv 2>&1)
        if ($LASTEXITCODE -ne 0) { throw "BFF resource failed" }
    }
    catch {
        Write-Host "  [WARN] Could not get token for '$bffResource'. Trying default resource..." -ForegroundColor Yellow
        $token = (az account get-access-token `
            --resource "https://spe-api-dev-67e2xz.azurewebsites.net" `
            --query accessToken -o tsv 2>&1)
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to acquire BFF API token. Error: $token"
        }
    }

    return @{
        'Authorization' = "Bearer $token"
        'Accept'        = 'application/json'
    }
}

# ---------------------------------------------------------------------------
# Get-SpeContainerForMatter
#   Resolves the SPE container ID for a given matter.
#   NOTE: This endpoint path is assumed — adjust based on actual BFF API routes.
# ---------------------------------------------------------------------------
function Get-SpeContainerForMatter {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string]    $MatterGuid,
        [Parameter(Mandatory)] [hashtable] $BffHeaders
    )

    $uri = "$BffApiBaseUrl/api/matters/$MatterGuid/container"

    try {
        $response = Invoke-RestMethod -Method GET -Uri $uri -Headers $BffHeaders
        return $response.containerId
    }
    catch {
        Write-Host "    [ERROR] Failed to get SPE container for matter $MatterGuid : $_" -ForegroundColor Red
        return $null
    }
}

# ---------------------------------------------------------------------------
# Upload-FileToBff
#   Uploads a single file to SPE via the BFF API.
#   NOTE: The upload endpoint and method are assumed — adjust based on actual
#   BFF API routes.
#
#   Returns: hashtable with graphItemId and graphDriveId, or $null on failure
# ---------------------------------------------------------------------------
function Upload-FileToBff {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string]    $ContainerId,
        [Parameter(Mandatory)] [string]    $FilePath,
        [Parameter(Mandatory)] [string]    $TargetFileName,
        [Parameter(Mandatory)] [hashtable] $BffHeaders
    )

    $uri = "$BffApiBaseUrl/api/containers/$ContainerId/files/$TargetFileName"

    try {
        $fileBytes = [System.IO.File]::ReadAllBytes($FilePath)

        $uploadHeaders = $BffHeaders.Clone()
        $uploadHeaders['Content-Type'] = 'application/octet-stream'

        $response = Invoke-RestMethod -Method PUT `
            -Uri $uri `
            -Headers $uploadHeaders `
            -Body $fileBytes

        return @{
            graphItemId  = $response.graphItemId
            graphDriveId = $response.graphDriveId
        }
    }
    catch {
        Write-Host "    [ERROR] Failed to upload $TargetFileName : $_" -ForegroundColor Red
        return $null
    }
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Uploading Files to SPE (Layer 4)     " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Acquire tokens
$dvHeaders  = Get-DataverseToken
$bffHeaders = Get-BffToken

# Load document records to get file mappings
$dataFile = Join-Path $PSScriptRoot "../../output/scenario-1-meridian/documents.json"
$filesDir = Join-Path $PSScriptRoot "../../output/scenario-1-meridian/files"

if (-not (Test-Path $dataFile)) {
    Write-Host "  [ERROR] documents.json not found: $dataFile" -ForegroundColor Red
    exit 1
}

$data = Get-Content $dataFile -Raw | ConvertFrom-Json

# Also check for a file-manifest.json (optional, overrides document-based mapping)
$manifestFile = Join-Path $PSScriptRoot "../../output/scenario-1-meridian/file-manifest.json"
$manifest = $null
if (Test-Path $manifestFile) {
    Write-Host "  Using file-manifest.json for file mappings" -ForegroundColor DarkGray
    $manifest = Get-Content $manifestFile -Raw | ConvertFrom-Json
}

# Filter to documents that have a filename and are expected to have files
$docsWithFiles = $data.records | Where-Object {
    $_.sprk_filename -and $_.sprk_hasfile -eq $false
}

Write-Host "  Documents eligible for file upload: $($docsWithFiles.Count)" -ForegroundColor DarkGray

$uploaded = 0
$skipped  = 0
$failed   = 0

# Cache for matter -> container ID mapping
$containerCache = @{}

foreach ($doc in $docsWithFiles) {
    $scenarioId = $doc.sprk_scenarioid
    $filename   = $doc.sprk_filename
    Write-Host "`n  Processing $scenarioId ($filename)..." -ForegroundColor White

    # --- Step 1: Find the local file ---
    # Try to locate the file in the files subdirectories
    $localFile = $null
    $searchPaths = Get-ChildItem -Path $filesDir -Recurse -File -Filter $filename -ErrorAction SilentlyContinue
    if ($searchPaths) {
        $localFile = $searchPaths[0].FullName
    }

    if (-not $localFile -or -not (Test-Path $localFile)) {
        Write-Host "    [SKIP] Local file not found: $filename" -ForegroundColor Yellow
        $skipped++
        continue
    }

    # --- Step 2: Look up the document record GUID in Dataverse ---
    $docGuid = Find-RecordByScenarioId -EntitySet "sprk_documents" -ScenarioId $scenarioId -Headers $dvHeaders
    if (-not $docGuid) {
        Write-Host "    [ERROR] Document record not found in Dataverse: $scenarioId" -ForegroundColor Red
        $failed++
        continue
    }

    # --- Step 3: Resolve the matter and get SPE container ---
    $matterBind = $doc.'sprk_Matter@odata.bind'
    if (-not $matterBind) {
        Write-Host "    [ERROR] No matter reference for document $scenarioId" -ForegroundColor Red
        $failed++
        continue
    }

    # Extract matter scenario ID from the @odata.bind value
    $matterScenarioId = $null
    if ($matterBind -match "sprk_scenarioid='([^']+)'") {
        $matterScenarioId = $Matches[1]
    }

    $matterGuid = Find-RecordByScenarioId -EntitySet "sprk_matters" -ScenarioId $matterScenarioId -Headers $dvHeaders
    if (-not $matterGuid) {
        Write-Host "    [ERROR] Matter not found: $matterScenarioId" -ForegroundColor Red
        $failed++
        continue
    }

    # Get or cache the container ID
    if (-not $containerCache.ContainsKey($matterGuid)) {
        $containerId = Get-SpeContainerForMatter -MatterGuid $matterGuid -BffHeaders $bffHeaders
        if (-not $containerId) {
            Write-Host "    [ERROR] Could not resolve SPE container for matter $matterGuid" -ForegroundColor Red
            $failed++
            continue
        }
        $containerCache[$matterGuid] = $containerId
    }
    $containerId = $containerCache[$matterGuid]

    # --- Step 4: Upload file via BFF API ---
    Write-Host "    Uploading to container $containerId..." -ForegroundColor DarkGray
    $uploadResult = Upload-FileToBff `
        -ContainerId $containerId `
        -FilePath $localFile `
        -TargetFileName $filename `
        -BffHeaders $bffHeaders

    if (-not $uploadResult) {
        $failed++
        continue
    }

    # --- Step 5: PATCH the document record in Dataverse ---
    Write-Host "    Patching document record with SPE references..." -ForegroundColor DarkGray
    $patchBody = @{
        sprk_graphitemid  = $uploadResult.graphItemId
        sprk_graphdriveid = $uploadResult.graphDriveId
        sprk_hasfile      = $true
        statuscode        = 421500001   # Active (file uploaded)
    }

    try {
        $patchUri = "$($script:WebApiUrl)/sprk_documents($docGuid)"
        Invoke-DataverseRequest -Method PATCH -Uri $patchUri -Headers $dvHeaders -Body $patchBody | Out-Null
        Write-Host "    [OK] Uploaded and linked: $filename" -ForegroundColor Green
        $uploaded++
    }
    catch {
        Write-Host "    [ERROR] Failed to patch document record: $_" -ForegroundColor Red
        $failed++
    }
}

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  File Upload Summary                  " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$color = if ($failed -gt 0) { 'Yellow' } else { 'Green' }
Write-Host "  Uploaded: $uploaded" -ForegroundColor $color
Write-Host "  Skipped:  $skipped (file not found locally)" -ForegroundColor $(if ($skipped -gt 0) { 'Yellow' } else { 'Green' })
Write-Host "  Failed:   $failed" -ForegroundColor $(if ($failed -gt 0) { 'Red' } else { 'Green' })

if ($skipped -gt 0) {
    Write-Host ""
    Write-Host "  NOTE: Skipped files do not exist locally yet." -ForegroundColor Yellow
    Write-Host "  Place files in output/scenario-1-meridian/files/ subdirectories" -ForegroundColor Yellow
    Write-Host "  and re-run this script to upload them." -ForegroundColor Yellow
}

if ($failed -gt 0) {
    Write-Host ""
    Write-Host "  [WARN] Some uploads failed. Review errors above." -ForegroundColor Yellow
    Write-Host "  NOTE: BFF API auth and endpoints may need adjustment." -ForegroundColor Yellow
    Write-Host "  See script header comments for configuration guidance." -ForegroundColor Yellow
}
