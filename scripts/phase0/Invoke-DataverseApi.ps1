# =============================================================================
# Invoke-DataverseApi.ps1
# Reusable helper module for Dataverse Web API operations.
# Dot-source this script to get shared functions for auth, CRUD, and lookups.
#
# Usage:  . "$PSScriptRoot/Invoke-DataverseApi.ps1"
# =============================================================================

$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
$script:DataverseBaseUrl = "https://spaarkedev1.crm.dynamics.com"
$script:WebApiUrl        = "$($script:DataverseBaseUrl)/api/data/v9.2"
$script:ThrottleDelayMs  = 500          # ms between API calls
$script:MaxRetries       = 3            # retry count on 429

# Cache for resolved scenario IDs -> GUIDs  (entity -> scenarioid -> guid)
$script:LookupCache = @{}

# ---------------------------------------------------------------------------
# Get-DataverseToken
#   Acquires a Bearer token via Azure CLI and returns a headers hashtable.
# ---------------------------------------------------------------------------
function Get-DataverseToken {
    [CmdletBinding()]
    param()

    Write-Host "  Acquiring Dataverse access token via Azure CLI..." -ForegroundColor DarkGray
    $token = (az account get-access-token `
        --resource $script:DataverseBaseUrl `
        --query accessToken -o tsv 2>&1)

    if ($LASTEXITCODE -ne 0) {
        throw "Failed to acquire token. Ensure you are logged in with 'az login'. Error: $token"
    }

    $headers = @{
        'Authorization'  = "Bearer $token"
        'OData-MaxVersion' = '4.0'
        'OData-Version'    = '4.0'
        'Content-Type'     = 'application/json; charset=utf-8'
        'Accept'           = 'application/json'
        'Prefer'           = 'return=representation'
    }

    return $headers
}

# ---------------------------------------------------------------------------
# Invoke-DataverseRequest
#   Wraps Invoke-RestMethod with auth, throttling, and retry on HTTP 429.
#
#   Parameters:
#     -Method     HTTP method (GET, POST, PATCH, DELETE)
#     -Uri        Full request URI
#     -Headers    Auth headers from Get-DataverseToken
#     -Body       (optional) Request body as hashtable — will be serialized
#     -RawBody    (optional) Already-serialized JSON string
# ---------------------------------------------------------------------------
function Invoke-DataverseRequest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string]   $Method,
        [Parameter(Mandatory)] [string]   $Uri,
        [Parameter(Mandatory)] [hashtable]$Headers,
        [hashtable] $Body,
        [string]    $RawBody
    )

    $jsonPayload = $null
    if ($Body) {
        $jsonPayload = $Body | ConvertTo-Json -Depth 10 -Compress
    }
    elseif ($RawBody) {
        $jsonPayload = $RawBody
    }

    $attempt = 0
    while ($true) {
        $attempt++
        try {
            Start-Sleep -Milliseconds $script:ThrottleDelayMs

            $params = @{
                Method  = $Method
                Uri     = $Uri
                Headers = $Headers
            }
            if ($jsonPayload -and $Method -ne 'GET' -and $Method -ne 'DELETE') {
                $params['Body'] = [System.Text.Encoding]::UTF8.GetBytes($jsonPayload)
            }

            $response = Invoke-RestMethod @params
            return $response
        }
        catch {
            $statusCode = $null
            if ($_.Exception.Response) {
                $statusCode = [int]$_.Exception.Response.StatusCode
            }

            # Retry on 429 (Too Many Requests)
            if ($statusCode -eq 429 -and $attempt -le $script:MaxRetries) {
                $retryAfter = 5   # default 5 seconds
                try {
                    $retryHeader = $_.Exception.Response.Headers |
                        Where-Object { $_.Key -eq 'Retry-After' } |
                        Select-Object -ExpandProperty Value -First 1
                    if ($retryHeader) { $retryAfter = [int]$retryHeader }
                } catch { }

                Write-Host "    [429] Rate limited. Retrying in ${retryAfter}s (attempt $attempt/$($script:MaxRetries))..." -ForegroundColor Yellow
                Start-Sleep -Seconds $retryAfter
                continue
            }

            # Extract detailed error from response body
            $errorDetail = $_.Exception.Message
            try {
                if ($_.ErrorDetails -and $_.ErrorDetails.Message) {
                    $parsed = $_.ErrorDetails.Message | ConvertFrom-Json
                    if ($parsed.error -and $parsed.error.message) {
                        $errorDetail = $parsed.error.message
                    }
                }
            } catch { }

            throw "Dataverse API error ($Method $Uri): HTTP $statusCode - $errorDetail"
        }
    }
}

# ---------------------------------------------------------------------------
# Find-RecordByScenarioId
#   Queries an entity collection by sprk_scenarioid and returns the primary
#   key GUID, or $null if not found.
#
#   Parameters:
#     -EntitySet    Plural entity set name (e.g. "sprk_matters")
#     -ScenarioId   The sprk_scenarioid value to look up
#     -Headers      Auth headers
# ---------------------------------------------------------------------------
function Find-RecordByScenarioId {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string]    $EntitySet,
        [Parameter(Mandatory)] [string]    $ScenarioId,
        [Parameter(Mandatory)] [hashtable] $Headers
    )

    # Check cache first
    $cacheKey = "$EntitySet|$ScenarioId"
    if ($script:LookupCache.ContainsKey($cacheKey)) {
        return $script:LookupCache[$cacheKey]
    }

    # Determine primary key column name from entity set
    $pkColumn = Get-PrimaryKeyColumn -EntitySet $EntitySet

    $filter = "sprk_scenarioid eq '$ScenarioId'"
    $uri = "$($script:WebApiUrl)/$($EntitySet)?`$filter=$filter&`$select=$pkColumn"

    try {
        $result = Invoke-DataverseRequest -Method GET -Uri $uri -Headers $Headers

        if ($result.value -and $result.value.Count -gt 0) {
            $guid = $result.value[0].$pkColumn
            $script:LookupCache[$cacheKey] = $guid
            return $guid
        }
        return $null
    }
    catch {
        Write-Host "    [WARN] Lookup failed for $EntitySet/$ScenarioId : $_" -ForegroundColor Yellow
        return $null
    }
}

# ---------------------------------------------------------------------------
# Get-PrimaryKeyColumn
#   Returns the primary key column name for a given entity set.
# ---------------------------------------------------------------------------
function Get-PrimaryKeyColumn {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string] $EntitySet
    )

    # Standard Dataverse entities use their own PK naming
    switch ($EntitySet) {
        'accounts'    { return 'accountid' }
        'contacts'    { return 'contactid' }
        default {
            # Custom entities: sprk_matters -> sprk_matterid (strip trailing 's')
            $singular = $EntitySet.TrimEnd('s')
            return "${singular}id"
        }
    }
}

# ---------------------------------------------------------------------------
# Resolve-LookupReference
#   Takes an @odata.bind value like:
#     "/sprk_matters(sprk_scenarioid='mvp-matter-001')"
#   Looks up the actual GUID and returns:
#     "/sprk_matters(00000000-0000-0000-0000-000000000001)"
#
#   Returns $null if the input is null or the lookup fails.
# ---------------------------------------------------------------------------
function Resolve-LookupReference {
    [CmdletBinding()]
    param(
        [string]    $ODataBind,
        [Parameter(Mandatory)] [hashtable] $Headers
    )

    if ([string]::IsNullOrWhiteSpace($ODataBind) -or $ODataBind -eq 'null') {
        return $null
    }

    # Parse: /entitySet(sprk_scenarioid='value')
    if ($ODataBind -match "^/([^(]+)\(sprk_scenarioid='([^']+)'\)$") {
        $entitySet  = $Matches[1]
        $scenarioId = $Matches[2]

        $guid = Find-RecordByScenarioId -EntitySet $entitySet -ScenarioId $scenarioId -Headers $Headers
        if (-not $guid) {
            Write-Host "    [WARN] Could not resolve lookup: $ODataBind" -ForegroundColor Yellow
            return $null
        }

        return "/$entitySet($guid)"
    }
    else {
        # Already a GUID reference or unknown format — return as-is
        return $ODataBind
    }
}

# ---------------------------------------------------------------------------
# Upsert-Record
#   Creates or updates a record using Find-by-ScenarioId then POST or PATCH.
#
#   Parameters:
#     -EntitySet    Plural entity set name
#     -Record       Hashtable of field values (already resolved lookups)
#     -Headers      Auth headers
#
#   Returns: $true on success, $false on failure
# ---------------------------------------------------------------------------
function Upsert-Record {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string]    $EntitySet,
        [Parameter(Mandatory)] [hashtable] $Record,
        [Parameter(Mandatory)] [hashtable] $Headers
    )

    $scenarioId = $Record['sprk_scenarioid']
    if (-not $scenarioId) {
        Write-Host "    [ERROR] Record missing sprk_scenarioid — skipping" -ForegroundColor Red
        return $false
    }

    try {
        $existingId = Find-RecordByScenarioId -EntitySet $EntitySet -ScenarioId $scenarioId -Headers $Headers

        if ($existingId) {
            # PATCH (update)
            $pkColumn = Get-PrimaryKeyColumn -EntitySet $EntitySet
            $uri = "$($script:WebApiUrl)/$EntitySet($existingId)"
            Write-Host "    Updating $scenarioId ($existingId)..." -ForegroundColor DarkGray
            Invoke-DataverseRequest -Method PATCH -Uri $uri -Headers $Headers -Body $Record | Out-Null
        }
        else {
            # POST (create)
            $uri = "$($script:WebApiUrl)/$EntitySet"
            Write-Host "    Creating $scenarioId..." -ForegroundColor DarkGray
            $created = Invoke-DataverseRequest -Method POST -Uri $uri -Headers $Headers -Body $Record

            # Cache the new GUID
            if ($created) {
                $pkColumn = Get-PrimaryKeyColumn -EntitySet $EntitySet
                if ($created.$pkColumn) {
                    $cacheKey = "$EntitySet|$scenarioId"
                    $script:LookupCache[$cacheKey] = $created.$pkColumn
                }
            }
        }
        return $true
    }
    catch {
        Write-Host "    [ERROR] Failed to upsert $scenarioId : $_" -ForegroundColor Red
        return $false
    }
}

# ---------------------------------------------------------------------------
# Resolve-AllLookups
#   Iterates over a PSCustomObject (from JSON), finds all properties ending
#   in @odata.bind, resolves them via Resolve-LookupReference, and returns
#   a clean hashtable ready for the Web API.
#
#   Also strips null-valued @odata.bind properties and converts null values
#   of other properties to actual nulls.
# ---------------------------------------------------------------------------
function Resolve-AllLookups {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [PSCustomObject] $JsonRecord,
        [Parameter(Mandatory)] [hashtable]      $Headers
    )

    $result = @{}

    foreach ($prop in $JsonRecord.PSObject.Properties) {
        $name  = $prop.Name
        $value = $prop.Value

        if ($name -like '*@odata.bind') {
            # Resolve lookup reference
            if ($null -eq $value -or $value -eq '' -or "$value" -eq 'null') {
                # Skip null lookups — don't include them in the payload
                continue
            }

            $resolved = Resolve-LookupReference -ODataBind "$value" -Headers $Headers
            if ($resolved) {
                $result[$name] = $resolved
            }
            else {
                Write-Host "    [WARN] Dropping unresolvable lookup: $name = $value" -ForegroundColor Yellow
            }
        }
        else {
            # Regular field — include as-is
            $result[$name] = $value
        }
    }

    return $result
}

# ---------------------------------------------------------------------------
# Load-EntityFromFile
#   High-level helper that loads a JSON data file and upserts all records.
#
#   Parameters:
#     -FilePath     Path to the JSON file
#     -Headers      Auth headers
#     -EntitySet    (optional) Override the entity set name from the file
#
#   Returns: hashtable with keys 'Loaded' and 'Failed'
# ---------------------------------------------------------------------------
function Load-EntityFromFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string]    $FilePath,
        [Parameter(Mandatory)] [hashtable] $Headers,
        [string] $EntitySet
    )

    if (-not (Test-Path $FilePath)) {
        Write-Host "  [ERROR] File not found: $FilePath" -ForegroundColor Red
        return @{ Loaded = 0; Failed = 0 }
    }

    $data = Get-Content $FilePath -Raw | ConvertFrom-Json

    if (-not $EntitySet) {
        $EntitySet = $data.entity
    }

    Write-Host "`n=== Loading $EntitySet ===" -ForegroundColor Cyan
    Write-Host "  Source: $FilePath" -ForegroundColor DarkGray
    Write-Host "  Records: $($data.records.Count)" -ForegroundColor DarkGray

    $loaded = 0
    $failed = 0

    foreach ($record in $data.records) {
        try {
            $resolved = Resolve-AllLookups -JsonRecord $record -Headers $Headers
            $success  = Upsert-Record -EntitySet $EntitySet -Record $resolved -Headers $Headers
            if ($success) { $loaded++ } else { $failed++ }
        }
        catch {
            $failed++
            $sid = "unknown"
            if ($record.sprk_scenarioid) { $sid = $record.sprk_scenarioid }
            Write-Host "    [ERROR] Record $sid : $_" -ForegroundColor Red
        }
    }

    $color = if ($failed -gt 0) { 'Yellow' } else { 'Green' }
    Write-Host "  Result: Loaded=$loaded, Failed=$failed" -ForegroundColor $color

    return @{ Loaded = $loaded; Failed = $failed }
}

# ---------------------------------------------------------------------------
# Delete-RecordsByScenarioPrefix
#   Queries all records in an entity set whose sprk_scenarioid starts with
#   a given prefix, then deletes each one.
#
#   Parameters:
#     -EntitySet    Plural entity set name
#     -Prefix       Scenario ID prefix (e.g. "mvp-")
#     -Headers      Auth headers
#
#   Returns: count of deleted records
# ---------------------------------------------------------------------------
function Delete-RecordsByScenarioPrefix {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string]    $EntitySet,
        [Parameter(Mandatory)] [string]    $Prefix,
        [Parameter(Mandatory)] [hashtable] $Headers
    )

    $pkColumn = Get-PrimaryKeyColumn -EntitySet $EntitySet

    # Use startswith filter
    $filter = "startswith(sprk_scenarioid,'$Prefix')"
    $uri = "$($script:WebApiUrl)/$($EntitySet)?`$filter=$filter&`$select=$pkColumn,sprk_scenarioid"

    Write-Host "  Querying $EntitySet for scenario prefix '$Prefix'..." -ForegroundColor DarkGray

    try {
        $result = Invoke-DataverseRequest -Method GET -Uri $uri -Headers $Headers
    }
    catch {
        Write-Host "  [ERROR] Failed to query $EntitySet : $_" -ForegroundColor Red
        return 0
    }

    if (-not $result.value -or $result.value.Count -eq 0) {
        Write-Host "  No records found in $EntitySet" -ForegroundColor DarkGray
        return 0
    }

    Write-Host "  Found $($result.value.Count) record(s) to delete" -ForegroundColor DarkGray
    $deleted = 0

    foreach ($rec in $result.value) {
        $guid = $rec.$pkColumn
        $sid  = $rec.sprk_scenarioid
        try {
            $deleteUri = "$($script:WebApiUrl)/$EntitySet($guid)"
            Invoke-DataverseRequest -Method DELETE -Uri $deleteUri -Headers $Headers | Out-Null
            Write-Host "    Deleted $sid ($guid)" -ForegroundColor DarkGray
            $deleted++
        }
        catch {
            Write-Host "    [ERROR] Failed to delete $sid ($guid): $_" -ForegroundColor Red
        }
    }

    return $deleted
}

Write-Host "  Invoke-DataverseApi.ps1 loaded." -ForegroundColor DarkGray
