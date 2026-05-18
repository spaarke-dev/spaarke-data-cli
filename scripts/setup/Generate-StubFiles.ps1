<#
.SYNOPSIS
    Generate substantive markdown / EML source files for sprk_document
    records that have metadata but no source file (stub documents).

.DESCRIPTION
    For each "stub" document (a record in documents.json with no
    corresponding entry in file-manifest.json):

      1. Detect document type from sprk_extractdocumenttype + filename hints.
      2. Dispatch to a type-specific template function (New-<Type>Content).
      3. Write the file under output/{Scenario}/files/{category}/{filename}.
      4. Append an entry to file-manifest.json for downstream pipeline steps.

    Type templates draw on the document's existing metadata (summary, tldr,
    extracted entities, keywords) plus per-scenario context (matter caption,
    parties, case number) to produce realistic legal-document content.

    To add a new document type:
      - Add a New-<Type>Content function (returns markdown or EML string).
      - Register it in the $TypeDispatch table at the top of "Main".
      - The script picks it up automatically.

    To add a new scenario:
      - Define matter context (caption / case number / parties) inside
        Get-MatterContext, keyed by scenario name.

.PARAMETER Scenario
    Scenario directory name. Default: scenario-1-meridian.

.PARAMETER DocIds
    Optional list of sprk_scenarioid values to process (for incremental runs
    or testing). If omitted, all stub docs are processed.

.PARAMETER Force
    Overwrite source files that already exist. Default: skip existing files.

.PARAMETER DryRun
    Plan only; do not write files or update manifest.
#>

[CmdletBinding()]
param(
    [string]   $Scenario = "scenario-1-meridian",
    [string[]] $DocIds,
    [switch]   $Force,
    [switch]   $DryRun
)

$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
$RepoRoot      = (Resolve-Path "$PSScriptRoot/../..").Path
$ScenarioDir   = Join-Path $RepoRoot "output" $Scenario
$FilesDir      = Join-Path $ScenarioDir "files"
$DocumentsPath = Join-Path $ScenarioDir "documents.json"
$ManifestPath  = Join-Path $ScenarioDir "file-manifest.json"

if (-not (Test-Path $DocumentsPath)) { throw "documents.json not found: $DocumentsPath" }
if (-not (Test-Path $ManifestPath))  { throw "file-manifest.json not found: $ManifestPath" }

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Stub File Generator                  " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Scenario: $Scenario"
Write-Host "Files:    $FilesDir"
Write-Host "Manifest: $ManifestPath"
if ($DryRun) { Write-Host "Mode:     DRY RUN" -ForegroundColor Yellow }
if ($Force)  { Write-Host "Mode:     FORCE OVERWRITE" -ForegroundColor Yellow }
Write-Host ""

# ===========================================================================
# Per-scenario matter context
#   Add a new scenario by adding an entry keyed by scenario directory name.
# ===========================================================================
function Get-MatterContext {
    param([string] $Scenario)

    switch ($Scenario) {
        'scenario-1-meridian' {
            return @{
                Caption        = 'MERIDIAN CORPORATION v. PINNACLE INDUSTRIES, INC.'
                CaseNumber     = '3:2025-cv-04892-WHA'
                Court          = 'UNITED STATES DISTRICT COURT, NORTHERN DISTRICT OF CALIFORNIA, SAN FRANCISCO DIVISION'
                Plaintiff      = 'MERIDIAN CORPORATION'
                Defendant      = 'PINNACLE INDUSTRIES, INC.'
                Patent         = 'United States Patent No. 9,876,543'
                PatentTitle    = 'Thermal Compression Molding Process for Precision Manufacturing'
                PlaintiffFirm  = 'Baker & Associates LLP'
                DefendantFirm  = 'Chen Law Group'
                LeadCounselP   = @{ Name = 'Rachel M. Torres'; Title = 'Lead Partner, IP Litigation'; Firm = 'Baker & Associates LLP'; Address = '555 Market Street, Suite 2400, San Francisco, CA 94105'; Phone = '(415) 555-7800'; Email = 'rachel.torres@example.com' }
                LeadCounselD   = @{ Name = 'David Kim';        Title = 'Managing Partner';            Firm = 'Chen Law Group';        Address = '101 California Street, Suite 1800, San Francisco, CA 94111';  Phone = '(415) 555-2300'; Email = 'david.kim@example.com' }
                ClientContact  = @{ Name = 'Sarah Chen';       Title = 'General Counsel';             Org  = 'Meridian Corporation'; Address = '4500 Technology Drive, Suite 300, San Jose, CA 95134';      Phone = '(408) 555-9100'; Email = 'sarah.chen@example.com' }
                JudgeName      = 'Hon. William H. Alsup'
            }
        }
        default { throw "No matter context defined for scenario '$Scenario'. Add an entry to Get-MatterContext." }
    }
}
$Ctx = Get-MatterContext -Scenario $Scenario

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
function Format-CaseCaption {
    param([string] $Title)

    @"
<div style="font-size: 0.85em; color: #888;">SAMPLE DATA - FOR DEMO PURPOSES ONLY</div>

                  IN THE $($Ctx.Court)

$($Ctx.Plaintiff),

                       Plaintiff,

       v.                                          Case No. $($Ctx.CaseNumber)
                                                   $($Ctx.JudgeName), presiding
$($Ctx.Defendant),

                       Defendant.
________________________________________________________________________________

                          $Title
________________________________________________________________________________
"@
}

function Format-EntityList {
    # Newline-or-comma delimited string -> bullet list of "- item"
    param([string] $Text)
    if (-not $Text) { return '- *(none on file)*' }
    $items = $Text -split "[`n,]" | ForEach-Object { $_.Trim() } | Where-Object { $_ }
    return ($items | ForEach-Object { "- $_" }) -join "`n"
}

function Get-ExtractField {
    param([object]$Doc, [string]$Field)
    if ($Doc.PSObject.Properties[$Field]) { return $Doc.$Field }
    return $null
}

# ---------------------------------------------------------------------------
# Type dispatch — map sprk_extractdocumenttype + filename hint -> generator
# ---------------------------------------------------------------------------
function Get-TemplateName {
    param([object] $Doc)

    $dtype = (Get-ExtractField -Doc $Doc -Field 'sprk_extractdocumenttype') ?? ''
    $fname = ($Doc.sprk_filename ?? '').ToLower()

    # File-extension check first — a .eml is always an email regardless of content keywords
    if ($fname.EndsWith('.eml'))                          { return 'Email' }

    # Filename heuristics — order matters; more specific patterns first.
    # Word-boundary anchors on shorter tokens (nda-, sow-) prevent substring matches
    # like "amanda-" matching "nda-".
    if ($fname -match 'deposition-')                      { return 'Deposition' }    # before nda- (deponent names may contain "anda")
    if ($fname -match '(^|[/_-])sow-|statement-of-work')  { return 'Sow' }
    if ($fname -match 'amendment')                        { return 'Amendment' }
    if ($fname -match 'msa-termination|termination-notice'){ return 'TerminationNotice' }
    if ($fname -match '(^|[/_-])nda-')                    { return 'Nda' }
    if ($fname -match 'answer|counterclaim')              { return 'Answer' }
    if ($fname -match 'motion-')                          { return 'Motion' }
    if ($fname -match 'claim-construction|markman')       { return 'ClaimConstructionBrief' }
    if ($fname -match 'interrog')                         { return 'Interrogatories' }
    if ($fname -match 'rfp-|request-for-prod|production-request') { return 'RequestForProduction' }
    if ($fname -match 'privilege-log')                    { return 'PrivilegeLog' }
    if ($fname -match 'production-cover|cover-letter')    { return 'ProductionCoverLetter' }
    if ($fname -match 'expert-report-.*damages')          { return 'ExpertReportDamages' }
    if ($fname -match 'rebuttal')                         { return 'ExpertReportRebuttal' }
    if ($fname -match 'litigation-hold')                  { return 'LitigationHold' }
    if ($fname -match 'budget-review|budget-memo')        { return 'BudgetMemo' }
    if ($fname -match 'invoice-')                         { return 'Invoice' }
    if ($fname -match 'timeline|chronology')              { return 'CaseTimeline' }
    if ($fname -match 'exhibit-list')                     { return 'ExhibitList' }

    # Document type fallback
    switch -Wildcard ($dtype) {
        'Contract'                                  { return 'Contract' }
        'NDA'                                       { return 'Nda' }
        'Pleading'                                  { return 'Motion' }
        'Discovery'                                 { return 'RequestForProduction' }
        'Deposition Transcript'                     { return 'Deposition' }
        'Expert Report'                             { return 'ExpertReport' }
        'Expert Report*Rebuttal'                    { return 'ExpertReportRebuttal' }
        'Internal Memorandum'                       { return 'LitigationHold' }
        'Email*'                                    { return 'Email' }
        'Invoice'                                   { return 'Invoice' }
        'Case Timeline'                             { return 'CaseTimeline' }
        'Exhibit List'                              { return 'ExhibitList' }
        default                                     { return 'Generic' }
    }
}

# ---------------------------------------------------------------------------
# Determine target subdirectory under files/
# ---------------------------------------------------------------------------
function Get-CategoryFolder {
    param([string] $TemplateName)
    switch ($TemplateName) {
        { $_ -in 'Contract','Sow','Amendment','TerminationNotice','Nda' } { return 'contracts' }
        { $_ -in 'Answer','Motion','ClaimConstructionBrief' }              { return 'pleadings' }
        { $_ -in 'Interrogatories','RequestForProduction','PrivilegeLog','ProductionCoverLetter' } { return 'discovery' }
        { $_ -in 'Deposition' }                                            { return 'depositions' }
        { $_ -in 'ExpertReport','ExpertReportDamages','ExpertReportRebuttal' } { return 'expert-reports' }
        { $_ -in 'LitigationHold','BudgetMemo','CaseTimeline','ExhibitList','Generic' } { return 'memos' }
        { $_ -in 'Email' }                                                 { return 'emails' }
        { $_ -in 'Invoice' }                                               { return 'invoices' }
        default { return 'misc' }
    }
}

# ---------------------------------------------------------------------------
# File extension based on extension in sprk_filename, with template fallback
# ---------------------------------------------------------------------------
function Get-OutputExtension {
    param([object] $Doc, [string] $TemplateName)
    $declared = ($Doc.sprk_filename ?? '').Split('.')[-1].ToLower()
    if ($declared -in @('pdf','docx','eml','xlsx')) {
        # Source format: markdown for PDF/DOCX; eml for EML
        if ($declared -eq 'eml') { return 'eml' }
        return 'md'
    }
    if ($TemplateName -eq 'Email') { return 'eml' }
    return 'md'
}

# ===========================================================================
# Template functions: New-<Type>Content
# Each returns a string (markdown or EML body) suitable for writing to file.
# Templates use $Doc (the documents.json record) and $Ctx (matter context).
# ===========================================================================

. "$PSScriptRoot/Generators/Templates-Contracts.ps1"
. "$PSScriptRoot/Generators/Templates-Pleadings.ps1"
. "$PSScriptRoot/Generators/Templates-Discovery.ps1"
. "$PSScriptRoot/Generators/Templates-Depositions.ps1"
. "$PSScriptRoot/Generators/Templates-Experts.ps1"
. "$PSScriptRoot/Generators/Templates-Memos.ps1"
. "$PSScriptRoot/Generators/Templates-Emails.ps1"
. "$PSScriptRoot/Generators/Templates-Misc.ps1"

# ===========================================================================
# Main
# ===========================================================================

# Load source data
$documentsRoot = Get-Content $DocumentsPath -Raw | ConvertFrom-Json
$documents     = $documentsRoot.records
$manifestRaw   = Get-Content $ManifestPath -Raw | ConvertFrom-Json
# Manifest is { scenario, generated, total_files, files: [...] }.
# Track the wrapper so we can preserve it on save; load files into a true
# resizable List<object> (PSCustomObject[] is fixed-size and Add fails).
$manifestIsWrapped = ($manifestRaw -isnot [System.Array]) -and ($null -ne $manifestRaw.files)
$manifest = New-Object 'System.Collections.Generic.List[object]'
$rawItems = if ($manifestIsWrapped) { $manifestRaw.files }
            elseif ($manifestRaw -is [System.Array]) { $manifestRaw }
            else { @($manifestRaw) }
foreach ($item in $rawItems) { $manifest.Add($item) | Out-Null }

$existingIds = @{}
foreach ($m in $manifest) { if ($m.doc_id) { $existingIds[$m.doc_id] = $m } }

# Filter to stubs that need a file. With -Force, also reprocess docs already in
# the manifest so template changes propagate to existing files.
$stubs = $documents | Where-Object {
    $sid = $_.sprk_scenarioid
    $sid -and ($Force -or -not $existingIds.ContainsKey($sid))
}
if ($DocIds -and $DocIds.Count -gt 0) {
    $stubs = $stubs | Where-Object { $DocIds -contains $_.sprk_scenarioid }
}

Write-Host "Stub documents needing files: $($stubs.Count)" -ForegroundColor DarkGray
Write-Host ""

$generated = 0; $skipped = 0; $errors = 0
$newManifestEntries = New-Object System.Collections.Generic.List[object]

foreach ($doc in $stubs) {
    $sid    = $doc.sprk_scenarioid
    $fname  = $doc.sprk_filename
    if (-not $fname) {
        Write-Host "  [SKIP] $sid - no sprk_filename" -ForegroundColor Yellow
        $skipped++; continue
    }

    $template  = Get-TemplateName -Doc $doc
    $category  = Get-CategoryFolder -TemplateName $template
    $srcExt    = Get-OutputExtension -Doc $doc -TemplateName $template
    $stem      = [System.IO.Path]::GetFileNameWithoutExtension($fname)
    $srcName   = "${sid}_${stem}.${srcExt}"
    $relPath   = "$category/$srcName"
    $absPath   = Join-Path $FilesDir $relPath

    if (-not $Force -and (Test-Path $absPath)) {
        Write-Host "  [SKIP] $sid -> $relPath (exists; pass -Force to overwrite)" -ForegroundColor DarkGray
        # Still register in manifest if missing
        if (-not $existingIds.ContainsKey($sid)) {
            $newManifestEntries.Add([PSCustomObject]@{
                doc_id = $sid; path = $relPath; type = $template.ToLower(); format = $(if ($srcExt -eq 'eml') { 'eml' } else { 'markdown' })
                description = ($doc.sprk_filesummary ?? $doc.sprk_documentname ?? '')
            }) | Out-Null
        }
        $skipped++; continue
    }

    try {
        $funcName = "New-${template}Content"
        if (-not (Get-Command $funcName -ErrorAction SilentlyContinue)) {
            Write-Host "  [WARN] $sid - no template '$funcName'; using Generic" -ForegroundColor Yellow
            $funcName = 'New-GenericContent'
        }

        $content = & $funcName -Doc $doc -Ctx $Ctx
        if (-not $content) { throw "template returned empty content" }

        if (-not $DryRun) {
            $parentDir = Split-Path $absPath -Parent
            if (-not (Test-Path $parentDir)) { New-Item -ItemType Directory -Force -Path $parentDir | Out-Null }
            [System.IO.File]::WriteAllText($absPath, $content, [System.Text.UTF8Encoding]::new($false))
        }

        $newManifestEntries.Add([PSCustomObject]@{
            doc_id      = $sid
            path        = $relPath
            type        = $template.ToLower()
            format      = $(if ($srcExt -eq 'eml') { 'eml' } else { 'markdown' })
            description = ($doc.sprk_filesummary ?? $doc.sprk_documentname ?? '')
        }) | Out-Null

        Write-Host "  [OK]   $sid -> $relPath  ($($content.Length) chars, template=$template)" -ForegroundColor Green
        $generated++
    }
    catch {
        Write-Host "  [ERROR] $sid - $_" -ForegroundColor Red
        $errors++
    }
}

# Update manifest
if ($newManifestEntries.Count -gt 0 -and -not $DryRun) {
    foreach ($e in $newManifestEntries) {
        if (-not $existingIds.ContainsKey($e.doc_id)) {
            $manifest.Add($e) | Out-Null
            $existingIds[$e.doc_id] = $e
        }
    }

    # Preserve original manifest shape — write back the wrapper if the source
    # was wrapped, or a bare array if not. Update total_files in the wrapper.
    if ($manifestIsWrapped) {
        $manifestRaw.files = $manifest.ToArray()
        if ($manifestRaw.PSObject.Properties['total_files']) {
            $manifestRaw.total_files = $manifest.Count
        }
        $output = $manifestRaw
    } else {
        $output = $manifest.ToArray()
    }
    $output | ConvertTo-Json -Depth 10 | Set-Content -Path $ManifestPath -Encoding UTF8
    Write-Host ""
    Write-Host "  Manifest updated: $ManifestPath  (now $($manifest.Count) entries)" -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Stub File Generation Summary         " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Generated: $generated" -ForegroundColor Green
Write-Host "  Skipped:   $skipped" -ForegroundColor Yellow
Write-Host "  Errors:    $errors" -ForegroundColor $(if ($errors -gt 0) { 'Red' } else { 'Gray' })
if ($DryRun) { Write-Host "  (DRY RUN — no files written, manifest unchanged)" -ForegroundColor Yellow }
Write-Host ""

if ($errors -gt 0) { exit 1 }
