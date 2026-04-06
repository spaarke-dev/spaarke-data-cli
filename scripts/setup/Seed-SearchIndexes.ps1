<#
.SYNOPSIS
    Seed Azure AI Search indexes with document content and Dataverse records.

.DESCRIPTION
    Two indexing operations:
    A. Document content → spaarke-knowledge-index-v2 (chunked + embedded)
    B. Dataverse records → spaarke-records-index (matters, projects, invoices, accounts)

    Uses original markdown source text as content (not converted PDF/DOCX).
    Generates embeddings via Azure OpenAI text-embedding-3-large (3072 dims).
    Pushes documents to AI Search via REST API.

.PARAMETER Scenario
    Scenario directory name. Default: scenario-1-meridian

.PARAMETER KnowledgeIndexName
    AI Search knowledge index name.

.PARAMETER RecordsIndexName
    AI Search records index name.

.PARAMETER ChunkSize
    Characters per chunk. Default: 2048 (matches production pipeline).

.PARAMETER ChunkOverlap
    Character overlap between chunks. Default: 200.

.PARAMETER DryRun
    Preview indexing without executing.
#>

[CmdletBinding()]
param(
    [string] $Scenario           = "scenario-1-meridian",
    [string] $KnowledgeIndexName = "spaarke-knowledge-index-v2",
    [string] $RecordsIndexName   = "spaarke-records-index",
    [int]    $ChunkSize          = 2048,
    [int]    $ChunkOverlap       = 200,
    [string] $SpaarkeRepoPath    = "C:\code_files\spaarke",
    [switch] $DryRun
)

$ErrorActionPreference = 'Stop'

. "$PSScriptRoot/Helpers/Invoke-DataverseApi.ps1"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  AI Search Index Seeder               " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Search:    $($script:SearchServiceUrl)"
Write-Host "Knowledge: $KnowledgeIndexName"
Write-Host "Records:   $RecordsIndexName"
if ($DryRun) { Write-Host "Mode:      DRY RUN" -ForegroundColor Yellow }
Write-Host ""

# ---------------------------------------------------------------------------
# Paths and data
# ---------------------------------------------------------------------------
$RepoRoot = (Resolve-Path "$PSScriptRoot/../..").Path
$ScenarioDir = Join-Path $RepoRoot "output" $Scenario
$FilesDir = Join-Path $ScenarioDir "files"
$ManifestPath = Join-Path $ScenarioDir "file-manifest.json"
$DocumentsPath = Join-Path $ScenarioDir "documents.json"

$manifest = Get-Content $ManifestPath -Raw | ConvertFrom-Json
$documents = Get-Content $DocumentsPath -Raw | ConvertFrom-Json

# Build lookups
$docLookup = @{}
foreach ($doc in $documents.records) {
    $docLookup[$doc.sprk_scenarioid] = $doc
}

# Get auth
$dvHeaders = Get-DataverseToken
$searchHeaders = $null
$openAiKey = $null

if (-not $DryRun) {
    $searchHeaders = Get-AiSearchHeaders
    $openAiKey = Get-OpenAiApiKey
}

# ---------------------------------------------------------------------------
# Helper: Chunk text into overlapping segments
# ---------------------------------------------------------------------------
function Split-TextIntoChunks {
    param(
        [string] $Text,
        [int] $MaxChars = 2048,
        [int] $Overlap = 200
    )

    $chunks = @()
    if ([string]::IsNullOrWhiteSpace($Text)) { return $chunks }

    $pos = 0
    $textLength = $Text.Length

    while ($pos -lt $textLength) {
        $end = [Math]::Min($pos + $MaxChars, $textLength)

        # Try to break at a paragraph or sentence boundary
        if ($end -lt $textLength) {
            $searchStart = [Math]::Max($end - 200, $pos)
            $segment = $Text.Substring($searchStart, $end - $searchStart)

            # Prefer paragraph break
            $paraBreak = $segment.LastIndexOf("`n`n")
            if ($paraBreak -gt 0) {
                $end = $searchStart + $paraBreak + 2
            }
            else {
                # Fall back to sentence break
                $sentBreak = $segment.LastIndexOf(". ")
                if ($sentBreak -gt 0) {
                    $end = $searchStart + $sentBreak + 2
                }
            }
        }

        $chunk = $Text.Substring($pos, $end - $pos).Trim()
        if ($chunk.Length -gt 0) {
            $chunks += $chunk
        }

        $pos = [Math]::Max($pos + 1, $end - $Overlap)
    }

    return $chunks
}

# ---------------------------------------------------------------------------
# Helper: Generate embedding via Azure OpenAI
# ---------------------------------------------------------------------------
function Get-Embedding {
    param(
        [Parameter(Mandatory)] [string] $Text,
        [Parameter(Mandatory)] [string] $ApiKey
    )

    $embeddingUrl = "$($script:OpenAiEndpoint)/openai/deployments/text-embedding-3-large/embeddings?api-version=2023-05-15"

    # Truncate to ~8000 tokens (~32000 chars) to stay within model limits
    $truncated = if ($Text.Length -gt 32000) { $Text.Substring(0, 32000) } else { $Text }

    $body = @{
        input = $truncated
        dimensions = 3072
    } | ConvertTo-Json -Compress

    $response = Invoke-RestMethod -Method POST -Uri $embeddingUrl -Headers @{
        'api-key'      = $ApiKey
        'Content-Type' = 'application/json'
    } -Body ([System.Text.Encoding]::UTF8.GetBytes($body))

    return $response.data[0].embedding
}

# ---------------------------------------------------------------------------
# Helper: Push documents to AI Search index
# ---------------------------------------------------------------------------
function Push-ToSearchIndex {
    param(
        [Parameter(Mandatory)] [string] $IndexName,
        [Parameter(Mandatory)] [array]  $Documents,
        [Parameter(Mandatory)] [hashtable] $Headers
    )

    $apiVersion = "2024-07-01"
    $url = "$($script:SearchServiceUrl)/indexes/$IndexName/docs/index?api-version=$apiVersion"

    # Batch in groups of 100
    for ($i = 0; $i -lt $Documents.Count; $i += 100) {
        $batch = $Documents[$i..([Math]::Min($i + 99, $Documents.Count - 1))]

        $body = @{
            value = $batch
        } | ConvertTo-Json -Depth 20 -Compress

        $bodyBytes = [System.Text.Encoding]::UTF8.GetBytes($body)

        try {
            $response = Invoke-RestMethod -Method POST -Uri $url -Headers $Headers -Body $bodyBytes
            $succeeded = ($response.value | Where-Object { $_.status -eq $true -or $_.statusCode -eq 200 -or $_.statusCode -eq 201 }).Count
            Write-Host "    Batch $([Math]::Floor($i / 100) + 1): $succeeded/$($batch.Count) indexed" -ForegroundColor DarkGray
        }
        catch {
            Write-Host "    [ERROR] Batch $([Math]::Floor($i / 100) + 1) failed: $_" -ForegroundColor Red
        }
    }
}

# ===========================================================================
# PART A: Document content → Knowledge Index
# ===========================================================================
Write-Host ""
Write-Host "--- Part A: Knowledge Index ($KnowledgeIndexName) ---" -ForegroundColor Cyan

# Resolve matter GUID (needed for parent entity scoping)
$matterGuid = Find-RecordByScenarioId -EntitySet "sprk_matters" -ScenarioId "mvp-matter-001" -Headers $dvHeaders
$matterName = "Meridian Corp v. Pinnacle Industries"
Write-Host "  Matter GUID: $matterGuid" -ForegroundColor DarkGray

$totalChunks = 0
$totalDocs = 0
$allChunkDocs = @()

foreach ($entry in $manifest.files) {
    $docId = $entry.doc_id
    $sourcePath = Join-Path $FilesDir $entry.path
    $docRecord = $docLookup[$docId]

    if (-not $docRecord -or -not (Test-Path $sourcePath)) { continue }

    # Read source markdown content
    $content = Get-Content $sourcePath -Raw -Encoding UTF8

    if ([string]::IsNullOrWhiteSpace($content)) { continue }

    # Resolve document GUID from Dataverse
    $documentGuid = Find-RecordByScenarioId -EntitySet "sprk_documents" -ScenarioId $docId -Headers $dvHeaders

    # Get SPE file ID (graphItemId) if available
    $speFileId = $null
    if ($documentGuid) {
        try {
            $docCheck = Invoke-DataverseRequest -Method GET `
                -Uri "$($script:WebApiUrl)/sprk_documents($documentGuid)?`$select=sprk_graphitemid" `
                -Headers $dvHeaders
            $speFileId = $docCheck.sprk_graphitemid
        } catch { }
    }

    # Chunk the content
    $chunks = Split-TextIntoChunks -Text $content -MaxChars $ChunkSize -Overlap $ChunkOverlap
    $chunkCount = $chunks.Count

    $fileType = [System.IO.Path]::GetExtension($docRecord.sprk_filename).TrimStart('.').ToLower()
    $keywords = if ($docRecord.sprk_keywords) { $docRecord.sprk_keywords -split ',\s*' } else { @() }

    Write-Host "  $docId — $chunkCount chunks ($($content.Length) chars)" -ForegroundColor DarkGray

    for ($idx = 0; $idx -lt $chunkCount; $idx++) {
        $chunkText = $chunks[$idx]
        $chunkId = "${documentGuid}_${idx}"

        if (-not $documentGuid) { $chunkId = "${docId}_${idx}" }

        $chunkDoc = @{
            '@search.action' = 'upload'
            'id'                = $chunkId
            'documentId'        = $documentGuid
            'speFileId'         = $speFileId
            'fileName'          = $docRecord.sprk_filename
            'fileType'          = $fileType
            'chunkIndex'        = $idx
            'chunkCount'        = $chunkCount
            'content'           = $chunkText
            'parentEntityType'  = 'matter'
            'parentEntityId'    = $matterGuid
            'parentEntityname'  = $matterName
            'tags'              = $keywords
            'createdAt'         = (Get-Date -Format 'o')
            'updatedAt'         = (Get-Date -Format 'o')
        }

        # Generate embedding (skip in dry run)
        if (-not $DryRun) {
            try {
                $embedding = Get-Embedding -Text $chunkText -ApiKey $openAiKey
                $chunkDoc['contentVector3072'] = $embedding

                # Document-level embedding from first chunk
                if ($idx -eq 0) {
                    $chunkDoc['documentVector3072'] = $embedding
                }

                # Rate limit: ~100ms between embedding calls
                Start-Sleep -Milliseconds 100
            }
            catch {
                Write-Host "    [WARN] Embedding failed for chunk $idx of $docId : $_" -ForegroundColor Yellow
            }
        }

        $allChunkDocs += $chunkDoc
        $totalChunks++
    }

    $totalDocs++
}

Write-Host ""
Write-Host "  Total: $totalDocs documents → $totalChunks chunks" -ForegroundColor Cyan

if (-not $DryRun -and $allChunkDocs.Count -gt 0) {
    Write-Host "  Pushing to $KnowledgeIndexName..." -ForegroundColor DarkGray
    Push-ToSearchIndex -IndexName $KnowledgeIndexName -Documents $allChunkDocs -Headers $searchHeaders
    Write-Host "  [OK] Knowledge index seeded" -ForegroundColor Green
}
elseif ($DryRun) {
    Write-Host "  (DRY RUN — would push $totalChunks chunks)" -ForegroundColor Yellow
}

# ===========================================================================
# PART B: Dataverse Records → Records Index
# ===========================================================================
Write-Host ""
Write-Host "--- Part B: Records Index ($RecordsIndexName) ---" -ForegroundColor Cyan

# Delegate to existing Sync-RecordsToIndex.ps1 if available
$syncScript = Join-Path $SpaarkeRepoPath "scripts" "ai-search" "Sync-RecordsToIndex.ps1"

if (Test-Path $syncScript) {
    Write-Host "  Delegating to Sync-RecordsToIndex.ps1..." -ForegroundColor DarkGray

    if ($DryRun) {
        Write-Host "  (DRY RUN — would sync matters, projects, invoices, accounts)" -ForegroundColor Yellow
    }
    else {
        try {
            & $syncScript `
                -EnvironmentUrl $script:DataverseBaseUrl `
                -RecordTypes @("matter", "project", "invoice", "account") `
                -SearchServiceName ($script:SearchServiceUrl -replace 'https://|\.search\.windows\.net', '') `
                -SearchIndexName $RecordsIndexName
            Write-Host "  [OK] Records index seeded" -ForegroundColor Green
        }
        catch {
            Write-Host "  [WARN] Sync-RecordsToIndex.ps1 failed: $_" -ForegroundColor Yellow
            Write-Host "         Records index may need manual seeding." -ForegroundColor Yellow
        }
    }
}
else {
    Write-Host "  [WARN] Sync-RecordsToIndex.ps1 not found at: $syncScript" -ForegroundColor Yellow
    Write-Host "         Skipping records index seeding." -ForegroundColor Yellow
}

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Search Index Summary                 " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Documents indexed:  $totalDocs" -ForegroundColor Green
Write-Host "  Total chunks:       $totalChunks" -ForegroundColor Green
if ($DryRun) { Write-Host "  (DRY RUN — no data pushed)" -ForegroundColor Yellow }
Write-Host ""
