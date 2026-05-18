<#
.SYNOPSIS
    Sync Dataverse records to an Azure AI Search index, generating embeddings.
    Replaces the dev-environment-hardcoded spaarke/scripts/ai-search/Sync-RecordsToIndex.ps1.

.DESCRIPTION
    For each configured record type:
      1. Query Dataverse for records (configurable $select projection).
      2. Build content text (name + description + reference + keywords).
      3. Generate embedding via Azure OpenAI text-embedding-3-large.
      4. Push as one document per record to the target AI Search index.

    Each entity is described by an entry in $RecordTypeConfig (in the script
    body). Adding new entity types or extending existing ones is just an
    edit to the hashtable — no code changes elsewhere. The mapping handles
    inconsistent field naming (sprk_mattername vs sprk_name vs name) by
    declaring the source field per type.

.PARAMETER IndexName
    Target AI Search index. Default: spaarke-records-index.

.PARAMETER RecordTypes
    Subset of types to sync. Default: all configured ones.

.PARAMETER ScenarioPrefix
    Optional sprk_scenarioid prefix filter (e.g. "mvp-"). Standard entities
    (account/contact) are not filtered since they lack sprk_scenarioid.

.PARAMETER BatchSize
    Records per AI Search push batch. Default: 100 (the API max).

.PARAMETER SkipEmbeddings
    Push records without embeddings. Index docs will lack contentVector.

.PARAMETER DryRun
    Preview what would be pushed without making changes.
#>

[CmdletBinding()]
param(
    [string]   $IndexName       = "spaarke-records-index",
    [string[]] $RecordTypes,
    [string]   $ScenarioPrefix,
    [int]      $BatchSize       = 100,
    [switch]   $SkipEmbeddings,
    [switch]   $DryRun
)

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/Helpers/Invoke-DataverseApi.ps1"

# ---------------------------------------------------------------------------
# Record type configurations
# Each entry maps a Dataverse entity → AI Search records-index document.
# To add a new type: append an entry. The key is the friendly recordType.
#
# Required keys:
#   entitySet       Dataverse collection name (used in URL)
#   entityName      Logical name (stored in dataverseEntityName)
#   idField         Primary key column
#   nameField       Source for index recordName
#
# Optional keys:
#   descField       Source for recordDescription
#   refNumberField  Source for referenceNumbers (single value → 1-element array)
#   keywordsField   Source for keywords (string)
#   peopleField     Source for people collection (newline-delimited string OK)
#   organizationsField  Source for organizations collection
#   selectExtra     Extra columns to include in $select beyond defaults
# ---------------------------------------------------------------------------
$RecordTypeConfig = @{
    'matter' = @{
        entitySet      = 'sprk_matters'
        entityName     = 'sprk_matter'
        idField        = 'sprk_matterid'
        nameField      = 'sprk_mattername'
        descField      = 'sprk_matterdescription'
        refNumberField = 'sprk_matternumber'
    }
    'project' = @{
        entitySet      = 'sprk_projects'
        entityName     = 'sprk_project'
        idField        = 'sprk_projectid'
        nameField      = 'sprk_projectname'
        descField      = 'sprk_projectdescription'
        refNumberField = 'sprk_projectnumber'
    }
    'invoice' = @{
        entitySet      = 'sprk_invoices'
        entityName     = 'sprk_invoice'
        idField        = 'sprk_invoiceid'
        nameField      = 'sprk_name'                 # invoice uses sprk_name (not sprk_invoicename)
        descField      = 'sprk_description'
        refNumberField = 'sprk_invoicenumber'
    }
    'account' = @{
        entitySet      = 'accounts'
        entityName     = 'account'
        idField        = 'accountid'
        nameField      = 'name'
        descField      = 'description'
        refNumberField = 'accountnumber'
    }
}

# ---------------------------------------------------------------------------
# Resolve which record types to process
# ---------------------------------------------------------------------------
if (-not $RecordTypes -or $RecordTypes.Count -eq 0) {
    $RecordTypes = $RecordTypeConfig.Keys | Sort-Object
}

foreach ($rt in $RecordTypes) {
    if (-not $RecordTypeConfig.ContainsKey($rt)) {
        throw "Unknown record type '$rt'. Configured types: $(($RecordTypeConfig.Keys | Sort-Object) -join ', ')"
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Sync Dataverse Records to AI Search  " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Search service: $($script:SearchServiceUrl)"
Write-Host "Index:          $IndexName"
Write-Host "Record types:   $($RecordTypes -join ', ')"
if ($ScenarioPrefix) { Write-Host "Filter:         sprk_scenarioid startswith '$ScenarioPrefix'" }
if ($SkipEmbeddings) { Write-Host "Embeddings:     SKIPPED" -ForegroundColor Yellow }
if ($DryRun)         { Write-Host "Mode:           DRY RUN" -ForegroundColor Yellow }
Write-Host ""

# ---------------------------------------------------------------------------
# Auth
# ---------------------------------------------------------------------------
$dvHeaders     = Get-DataverseToken
$searchHeaders = Get-AiSearchHeaders
$openAiKey     = $null
if (-not $SkipEmbeddings) { $openAiKey = Get-OpenAiApiKey }

# ---------------------------------------------------------------------------
# Helper: Generate a 3072-dim embedding for arbitrary text
# ---------------------------------------------------------------------------
function Get-Embedding {
    param(
        [Parameter(Mandatory)] [string] $Text,
        [Parameter(Mandatory)] [string] $ApiKey
    )

    $url = "$($script:OpenAiEndpoint)/openai/deployments/text-embedding-3-large/embeddings?api-version=2023-05-15"
    $truncated = if ($Text.Length -gt 32000) { $Text.Substring(0, 32000) } else { $Text }
    $body = @{ input = $truncated; dimensions = 3072 } | ConvertTo-Json -Compress

    $resp = Invoke-RestMethod -Method POST -Uri $url -Headers @{
        'api-key'      = $ApiKey
        'Content-Type' = 'application/json'
    } -Body ([System.Text.Encoding]::UTF8.GetBytes($body))

    return $resp.data[0].embedding
}

# ---------------------------------------------------------------------------
# Helper: Push documents to AI Search index in batches
# ---------------------------------------------------------------------------
function Push-Batch {
    param(
        [Parameter(Mandatory)] [string]    $IndexName,
        [Parameter(Mandatory)] [array]     $Documents,
        [Parameter(Mandatory)] [hashtable] $Headers,
        [int] $BatchSize = 100
    )

    $apiVersion = '2024-07-01'
    $url = "$($script:SearchServiceUrl)/indexes/$IndexName/docs/index?api-version=$apiVersion"
    $totalSucceeded = 0
    $totalFailed    = 0

    for ($i = 0; $i -lt $Documents.Count; $i += $BatchSize) {
        $end   = [Math]::Min($i + $BatchSize - 1, $Documents.Count - 1)
        $batch = $Documents[$i..$end]
        $body  = @{ value = $batch } | ConvertTo-Json -Depth 20 -Compress
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($body)

        try {
            $resp = Invoke-RestMethod -Method POST -Uri $url -Headers $Headers -Body $bytes
            $ok = ($resp.value | Where-Object { $_.status -eq $true }).Count
            $bad = $batch.Count - $ok
            $totalSucceeded += $ok
            $totalFailed    += $bad
            Write-Host "    Batch $([Math]::Floor($i / $BatchSize) + 1): $ok/$($batch.Count) indexed" `
                -ForegroundColor $(if ($bad -gt 0) { 'Yellow' } else { 'DarkGray' })

            if ($bad -gt 0) {
                # Show first failure detail for diagnosis
                $firstFail = $resp.value | Where-Object { $_.status -ne $true } | Select-Object -First 1
                if ($firstFail) {
                    Write-Host "      first failure: $($firstFail.errorMessage)" -ForegroundColor Red
                }
            }
        }
        catch {
            $errMsg = $_.Exception.Message
            try {
                if ($_.ErrorDetails -and $_.ErrorDetails.Message) {
                    $parsed = $_.ErrorDetails.Message | ConvertFrom-Json
                    if ($parsed.error -and $parsed.error.message) { $errMsg = $parsed.error.message }
                }
            } catch {}
            Write-Host "    [ERROR] Batch $([Math]::Floor($i / $BatchSize) + 1): $errMsg" -ForegroundColor Red
            $totalFailed += $batch.Count
        }
    }

    return @{ Succeeded = $totalSucceeded; Failed = $totalFailed }
}

# ---------------------------------------------------------------------------
# Helper: Empty-array factory that survives ConvertTo-Json as []
# (PowerShell's @() and [string[]]@() both serialize as null — known quirk)
# ---------------------------------------------------------------------------
function New-StringList {
    param([string[]] $Items = $null)
    $list = New-Object 'System.Collections.Generic.List[string]'
    if ($Items) {
        foreach ($i in $Items) { if ($i) { $list.Add($i) } }
    }
    return ,$list
}

# ---------------------------------------------------------------------------
# Helper: Split newline-or-comma-delimited text into a List[string]
# ---------------------------------------------------------------------------
function Split-MultiValue {
    param([string] $Text)
    $list = New-Object 'System.Collections.Generic.List[string]'
    if (-not $Text) { return ,$list }
    foreach ($p in ($Text -split "[`n,]")) {
        $t = $p.Trim()
        if ($t) { $list.Add($t) }
    }
    return ,$list
}

# ---------------------------------------------------------------------------
# Helper: Map a Dataverse record → AI Search index document
# ---------------------------------------------------------------------------
function ConvertTo-IndexDocument {
    param(
        [Parameter(Mandatory)] [string]    $RecordType,
        [Parameter(Mandatory)] [hashtable] $Config,
        [Parameter(Mandatory)] [object]    $DvRecord
    )

    $id        = $DvRecord.($Config.idField)
    $docKey    = "$($Config.entityName)_$id"
    $name      = if ($Config.nameField)      { $DvRecord.($Config.nameField) }      else { $null }
    $desc      = if ($Config.descField)      { $DvRecord.($Config.descField) }      else { $null }
    $refNum    = if ($Config.refNumberField) { $DvRecord.($Config.refNumberField) } else { $null }
    $keywords  = if ($Config.keywordsField)  { $DvRecord.($Config.keywordsField) }  else { $null }
    $people    = if ($Config.peopleField)        { Split-MultiValue $DvRecord.($Config.peopleField) }        else { New-StringList }
    $orgs      = if ($Config.organizationsField) { Split-MultiValue $DvRecord.($Config.organizationsField) } else { New-StringList }
    $modified  = if ($DvRecord.modifiedon)   { $DvRecord.modifiedon } else { $null }

    $refNumbers = if ($refNum) { New-StringList -Items @($refNum) } else { New-StringList }

    $doc = @{
        '@search.action'      = 'upload'
        'id'                  = $docKey
        'recordType'          = $RecordType
        'recordName'          = if ($name) { $name } else { '(unnamed)' }
        'recordDescription'   = if ($desc) { $desc } else { '' }
        'organizations'       = $orgs
        'people'              = $people
        'referenceNumbers'    = $refNumbers
        'keywords'            = if ($keywords) { $keywords } else { '' }
        'lastModified'        = $modified
        'dataverseRecordId'   = $id
        'dataverseEntityName' = $Config.entityName
    }

    return $doc
}

# ---------------------------------------------------------------------------
# Helper: Build embedding input text from index doc
# ---------------------------------------------------------------------------
function Build-EmbeddingText {
    param([Parameter(Mandatory)] [hashtable] $Doc)

    $parts = @($Doc.recordType, $Doc.recordName)
    if ($Doc.recordDescription) { $parts += $Doc.recordDescription }
    if ($Doc.keywords)          { $parts += $Doc.keywords }
    if ($Doc.referenceNumbers -and $Doc.referenceNumbers.Count -gt 0) { $parts += ($Doc.referenceNumbers -join ' ') }
    if ($Doc.organizations -and $Doc.organizations.Count -gt 0)       { $parts += ($Doc.organizations -join ' ') }
    if ($Doc.people -and $Doc.people.Count -gt 0)                     { $parts += ($Doc.people -join ' ') }

    return ($parts -join "`n`n")
}

# ===========================================================================
# Main loop — one record type at a time
# ===========================================================================
$grandTotal      = 0
$grandSucceeded  = 0
$grandFailed     = 0

foreach ($rt in $RecordTypes) {
    $cfg = $RecordTypeConfig[$rt]
    Write-Host "--- $rt ($($cfg.entitySet)) ---" -ForegroundColor Cyan

    # Build $select list
    $selectFields = New-Object System.Collections.Generic.List[string]
    $selectFields.Add($cfg.idField) | Out-Null
    foreach ($k in @('nameField','descField','refNumberField','keywordsField','peopleField','organizationsField')) {
        if ($cfg.$k) { $selectFields.Add($cfg.$k) | Out-Null }
    }
    $selectFields.Add('modifiedon') | Out-Null
    $selectQ = ($selectFields | Select-Object -Unique) -join ','

    # Build query
    $uri = "$($script:WebApiUrl)/$($cfg.entitySet)?`$select=$selectQ"
    if ($ScenarioPrefix -and -not (Test-IsStandardEntity -EntitySet $cfg.entitySet)) {
        $uri += "&`$filter=startswith(sprk_scenarioid,'$ScenarioPrefix')"
    }

    # Fetch (pagination)
    $allRecords = New-Object System.Collections.Generic.List[object]
    $next = $uri
    while ($next) {
        try {
            $page = Invoke-DataverseRequest -Method GET -Uri $next -Headers $dvHeaders
        }
        catch {
            Write-Host "  [ERROR] Fetch failed: $_" -ForegroundColor Red
            break
        }
        if ($page.value) {
            foreach ($r in $page.value) { $allRecords.Add($r) | Out-Null }
        }
        $next = $page.'@odata.nextLink'
    }

    Write-Host "  Fetched $($allRecords.Count) records" -ForegroundColor DarkGray

    if ($allRecords.Count -eq 0) { continue }

    # Map to index docs (+ optional embeddings)
    $indexDocs = @()
    $idx = 0
    foreach ($r in $allRecords) {
        $idx++
        $doc = ConvertTo-IndexDocument -RecordType $rt -Config $cfg -DvRecord $r

        if (-not $SkipEmbeddings -and -not $DryRun) {
            $embedText = Build-EmbeddingText -Doc $doc
            if ($embedText) {
                try {
                    $vec = Get-Embedding -Text $embedText -ApiKey $openAiKey
                    $doc['contentVector'] = $vec
                    Start-Sleep -Milliseconds 80
                }
                catch {
                    Write-Host "    [WARN] Embedding failed for $($doc.id): $_" -ForegroundColor Yellow
                }
            }
        }
        $indexDocs += $doc
    }

    if ($DryRun) {
        Write-Host "  (DRY RUN — would push $($indexDocs.Count) docs)" -ForegroundColor Yellow
        $grandTotal += $indexDocs.Count
        Write-Host ""
        continue
    }

    # Push
    Write-Host "  Pushing $($indexDocs.Count) docs to $IndexName..." -ForegroundColor DarkGray
    $result = Push-Batch -IndexName $IndexName -Documents $indexDocs -Headers $searchHeaders -BatchSize $BatchSize

    Write-Host "  $rt : succeeded=$($result.Succeeded) failed=$($result.Failed)" -ForegroundColor $(if ($result.Failed -gt 0) { 'Yellow' } else { 'Green' })
    Write-Host ""

    $grandTotal     += $indexDocs.Count
    $grandSucceeded += $result.Succeeded
    $grandFailed    += $result.Failed
}

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Records Index Sync Summary           " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Total docs prepared: $grandTotal"
if (-not $DryRun) {
    Write-Host "  Indexed:             $grandSucceeded" -ForegroundColor Green
    Write-Host "  Failed:              $grandFailed" -ForegroundColor $(if ($grandFailed -gt 0) { 'Red' } else { 'Gray' })
}
Write-Host ""

if ($grandFailed -gt 0) { exit 1 }
