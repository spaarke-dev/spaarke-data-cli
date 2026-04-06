<#
.SYNOPSIS
    Convert markdown document files to PDF/DOCX for SPE upload.

.DESCRIPTION
    Reads file-manifest.json and documents.json, then converts each markdown
    source file to its target format (PDF or DOCX) using pandoc. EML files
    are copied as-is. Output goes to a 'converted' directory.

    Requires: pandoc (for DOCX and PDF via wkhtmltopdf or other engine)

.PARAMETER Scenario
    Scenario directory name under output/. Default: scenario-1-meridian

.PARAMETER OutputDir
    Override output directory. Default: output/{Scenario}/converted

.PARAMETER DryRun
    Preview conversions without executing.
#>

[CmdletBinding()]
param(
    [string] $Scenario = "scenario-1-meridian",
    [string] $OutputDir,
    [switch] $DryRun
)

$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
$RepoRoot = (Resolve-Path "$PSScriptRoot/../..").Path
$ScenarioDir = Join-Path $RepoRoot "output" $Scenario
$FilesDir = Join-Path $ScenarioDir "files"
$ManifestPath = Join-Path $ScenarioDir "file-manifest.json"
$DocumentsPath = Join-Path $ScenarioDir "documents.json"

if (-not $OutputDir) {
    $OutputDir = Join-Path $ScenarioDir "converted"
}

# ---------------------------------------------------------------------------
# Banner
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Markdown → PDF/DOCX Converter" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Scenario:  $Scenario"
Write-Host "Source:    $FilesDir"
Write-Host "Output:    $OutputDir"
if ($DryRun) { Write-Host "Mode:      DRY RUN" -ForegroundColor Yellow }
Write-Host ""

# ---------------------------------------------------------------------------
# Prerequisites
# ---------------------------------------------------------------------------
if (-not (Test-Path $ManifestPath)) { throw "File manifest not found: $ManifestPath" }
if (-not (Test-Path $DocumentsPath)) { throw "Documents JSON not found: $DocumentsPath" }

# Check pandoc
$pandocVersion = $null
try { $pandocVersion = (pandoc --version 2>&1 | Select-Object -First 1) } catch { }
if (-not $pandocVersion) {
    throw "pandoc not found. Install via: winget install --id JohnMacFarlane.Pandoc"
}
Write-Host "  [ok] $pandocVersion" -ForegroundColor Green

# Check PDF engine availability (include common install paths)
$pdfEngine = $null
$pdfEngineFlag = @()

# Well-known install paths for wkhtmltopdf
$wkhtmlPaths = @(
    "C:\Program Files\wkhtmltopdf\bin\wkhtmltopdf.exe",
    "C:\Program Files (x86)\wkhtmltopdf\bin\wkhtmltopdf.exe"
)

foreach ($engine in @('wkhtmltopdf', 'pdflatex', 'xelatex', 'tectonic', 'typst')) {
    try {
        $null = Get-Command $engine -ErrorAction Stop
        $pdfEngine = $engine
        $pdfEngineFlag = @("--pdf-engine=$engine")
        break
    } catch { }
}

# Fallback: check well-known install paths for wkhtmltopdf
if (-not $pdfEngine) {
    foreach ($path in $wkhtmlPaths) {
        if (Test-Path $path) {
            $pdfEngine = "wkhtmltopdf"
            $pdfEngineFlag = @("--pdf-engine=$path")
            break
        }
    }
}

if (-not $pdfEngine) {
    Write-Host "  [WARN] No PDF engine found. PDFs will be generated via HTML intermediate." -ForegroundColor Yellow
    Write-Host "         For better quality, install: winget install --id wkhtmltopdf.wkhtmltopdf" -ForegroundColor Yellow
    Write-Host "         Falling back to: pandoc MD → HTML → rename as PDF (viewable in browsers)" -ForegroundColor Yellow
    $pdfEngine = "html-fallback"
} else {
    Write-Host "  [ok] PDF engine: $pdfEngine" -ForegroundColor Green
}

# ---------------------------------------------------------------------------
# Load data
# ---------------------------------------------------------------------------
$manifest = (Get-Content $ManifestPath -Raw | ConvertFrom-Json)
$documents = (Get-Content $DocumentsPath -Raw | ConvertFrom-Json)

# Build lookup: doc_id → document record
$docLookup = @{}
foreach ($doc in $documents.records) {
    $docLookup[$doc.sprk_scenarioid] = $doc
}

# ---------------------------------------------------------------------------
# Create output directory
# ---------------------------------------------------------------------------
if (-not $DryRun -and -not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

# ---------------------------------------------------------------------------
# Process files
# ---------------------------------------------------------------------------
$converted = 0
$skipped = 0
$errors = 0

foreach ($entry in $manifest.files) {
    $docId = $entry.doc_id
    $sourcePath = Join-Path $FilesDir $entry.path

    # Get target filename from documents.json
    $docRecord = $docLookup[$docId]
    if (-not $docRecord) {
        Write-Host "  [SKIP] $docId — not found in documents.json" -ForegroundColor Yellow
        $skipped++
        continue
    }

    $targetFilename = $docRecord.sprk_filename
    $mimetype = $docRecord.sprk_mimetype
    $targetPath = Join-Path $OutputDir $targetFilename

    if (-not (Test-Path $sourcePath)) {
        Write-Host "  [SKIP] $docId — source file not found: $($entry.path)" -ForegroundColor Yellow
        $skipped++
        continue
    }

    # Determine conversion strategy
    $sourceExt = [System.IO.Path]::GetExtension($sourcePath).ToLower()
    $targetExt = [System.IO.Path]::GetExtension($targetFilename).ToLower()

    if ($DryRun) {
        Write-Host "  [WOULD] $($entry.path) → $targetFilename ($sourceExt → $targetExt)" -ForegroundColor Gray
        $converted++
        continue
    }

    try {
        if ($sourceExt -eq '.eml') {
            # EML files — copy as-is with target name
            Copy-Item -Path $sourcePath -Destination $targetPath -Force
            Write-Host "  [COPY] $docId → $targetFilename" -ForegroundColor Green
        }
        elseif ($targetExt -eq '.docx') {
            # Markdown → DOCX via pandoc (native, no extra engine needed)
            pandoc $sourcePath -o $targetPath --from=markdown --to=docx 2>&1
            if ($LASTEXITCODE -ne 0) { throw "pandoc exited with code $LASTEXITCODE" }
            Write-Host "  [DOCX] $docId → $targetFilename" -ForegroundColor Green
        }
        elseif ($targetExt -eq '.pdf') {
            if ($pdfEngine -eq 'html-fallback') {
                # Fallback: MD → standalone HTML (saved as .pdf extension)
                # This produces a self-contained HTML file that renders well
                # in browsers and many document viewers
                pandoc $sourcePath -o $targetPath --from=markdown --to=html5 --standalone --metadata title="$($docRecord.sprk_documentname)" 2>&1
                if ($LASTEXITCODE -ne 0) { throw "pandoc exited with code $LASTEXITCODE" }
                Write-Host "  [HTML→PDF] $docId → $targetFilename (HTML fallback)" -ForegroundColor Green
            }
            else {
                # Proper PDF via configured engine
                pandoc $sourcePath -o $targetPath --from=markdown @pdfEngineFlag 2>&1
                if ($LASTEXITCODE -ne 0) { throw "pandoc exited with code $LASTEXITCODE" }
                Write-Host "  [PDF] $docId → $targetFilename" -ForegroundColor Green
            }
        }
        else {
            # Unknown target format — copy as-is
            Copy-Item -Path $sourcePath -Destination $targetPath -Force
            Write-Host "  [COPY] $docId → $targetFilename (unknown format)" -ForegroundColor Yellow
        }

        $converted++
    }
    catch {
        Write-Host "  [ERROR] $docId — $_" -ForegroundColor Red
        $errors++
    }
}

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Conversion Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Converted: $converted" -ForegroundColor Green
Write-Host "  Skipped:   $skipped" -ForegroundColor Yellow
Write-Host "  Errors:    $errors" -ForegroundColor $(if ($errors -gt 0) { 'Red' } else { 'Gray' })
if ($DryRun) { Write-Host "  (DRY RUN — no files written)" -ForegroundColor Yellow }
Write-Host ""

if ($errors -gt 0) { exit 1 }
