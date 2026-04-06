<#
.SYNOPSIS
    Master orchestrator — populates a Spaarke demo environment end-to-end.

.DESCRIPTION
    Runs all pipeline steps in order:
      1. Prerequisites check
      2. AI Seed Data (playbooks, actions, skills, tools, knowledge)
      3. Core Dataverse records (accounts → work assignments)
      4. Document records (with AI enrichment fields)
      5. File conversion (markdown → PDF/DOCX)
      6. SPE file upload + Dataverse patching
      7. Activity records (events, communications, KPIs, billing, spend)
      8. AI Search index seeding (knowledge + records indexes)
      9. Validation

    Use -StepOnly to run a single step. Use -DryRun to preview.

.EXAMPLE
    .\Setup-DemoEnvironment.ps1 -DryRun
    # Preview all steps without making changes

.EXAMPLE
    .\Setup-DemoEnvironment.ps1
    # Run full pipeline against demo environment

.EXAMPLE
    .\Setup-DemoEnvironment.ps1 -StepOnly 6
    # Run only SPE file upload step
#>

[CmdletBinding()]
param(
    [string] $DataverseUrl    = "https://spaarke-demo.crm.dynamics.com",
    [string] $BffApiUrl       = "https://spaarke-bff-demo.azurewebsites.net",
    [string] $BffClientId     = "da03fe1a-4b1d-4297-a4ce-4b83cae498a9",
    [string] $SpeContainerId  = "b!FzmtPrWQEEi1yPtUOXM4_h7X4udVbCVJgu1ClOi23elAbPdL3-EGQK-D8YZ9tcZp",
    [string] $SearchEndpoint  = "https://spaarke-search-demo.search.windows.net",
    [string] $OpenAiEndpoint  = "https://spaarke-openai-demo.openai.azure.com",
    [string] $Scenario        = "scenario-1-meridian",
    [string] $SpaarkeRepoPath = "C:\code_files\spaarke",
    [int]    $StepOnly        = 0,
    [switch] $DryRun
)

$ErrorActionPreference = 'Stop'
$scriptDir = $PSScriptRoot

# ---------------------------------------------------------------------------
# Set environment variables for helper module
# ---------------------------------------------------------------------------
$env:SPAARKE_DV_URL        = $DataverseUrl
$env:SPAARKE_BFF_URL       = $BffApiUrl
$env:SPAARKE_BFF_CLIENT_ID = $BffClientId
$env:SPAARKE_SEARCH_URL    = $SearchEndpoint
$env:AZURE_OPENAI_ENDPOINT = $OpenAiEndpoint

# ---------------------------------------------------------------------------
# Banner
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Spaarke Demo Environment Setup" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Dataverse:  $DataverseUrl"
Write-Host "  BFF API:    $BffApiUrl"
Write-Host "  SPE:        $SpeContainerId"
Write-Host "  AI Search:  $SearchEndpoint"
Write-Host "  OpenAI:     $OpenAiEndpoint"
Write-Host "  Scenario:   $Scenario"
Write-Host "  Spaarke:    $SpaarkeRepoPath"
if ($StepOnly -gt 0) { Write-Host "  Step Only:  $StepOnly" -ForegroundColor Yellow }
if ($DryRun)         { Write-Host "  Mode:       DRY RUN" -ForegroundColor Yellow }
Write-Host ""

$startTime = Get-Date

function Should-RunStep([int]$step) {
    return ($StepOnly -eq 0) -or ($StepOnly -eq $step)
}

function Write-StepHeader([int]$step, [string]$title) {
    Write-Host ""
    Write-Host "------------------------------------------------------------" -ForegroundColor DarkCyan
    Write-Host "  Step $step : $title" -ForegroundColor Cyan
    Write-Host "------------------------------------------------------------" -ForegroundColor DarkCyan
}

# ===========================================================================
# STEP 1: Prerequisites
# ===========================================================================
if (Should-RunStep 1) {
    Write-StepHeader 1 "Prerequisites Check"

    # Azure CLI
    try {
        $acct = az account show 2>&1 | ConvertFrom-Json
        Write-Host "  [ok] Azure CLI: $($acct.user.name)" -ForegroundColor Green
    }
    catch {
        throw "Azure CLI not authenticated. Run 'az login' first."
    }

    # Pandoc
    try {
        $pv = pandoc --version 2>&1 | Select-Object -First 1
        Write-Host "  [ok] $pv" -ForegroundColor Green
    }
    catch {
        throw "pandoc not found. Install via: winget install --id JohnMacFarlane.Pandoc"
    }

    # Scenario data
    $scenarioDir = Join-Path $scriptDir "../../output/$Scenario"
    if (Test-Path $scenarioDir) {
        $jsonCount = (Get-ChildItem -Path $scenarioDir -Filter "*.json").Count
        Write-Host "  [ok] Scenario data: $jsonCount JSON files in $Scenario" -ForegroundColor Green
    }
    else {
        throw "Scenario data not found: $scenarioDir"
    }

    # Spaarke repo
    if (Test-Path $SpaarkeRepoPath) {
        Write-Host "  [ok] Spaarke repo: $SpaarkeRepoPath" -ForegroundColor Green
    }
    else {
        Write-Host "  [WARN] Spaarke repo not found at $SpaarkeRepoPath — AI seed data step will be skipped" -ForegroundColor Yellow
    }

    # OpenAI API key
    if ($env:AZURE_OPENAI_API_KEY) {
        Write-Host "  [ok] AZURE_OPENAI_API_KEY is set" -ForegroundColor Green
    }
    else {
        Write-Host "  [WARN] AZURE_OPENAI_API_KEY not set — AI Search seeding will fail" -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host "  Prerequisites check complete." -ForegroundColor Green
}

# ===========================================================================
# STEP 2: AI Seed Data
# ===========================================================================
if (Should-RunStep 2) {
    Write-StepHeader 2 "AI Seed Data (Layer 1)"

    $aiSeedScript = Join-Path $SpaarkeRepoPath "scripts" "seed-data" "Deploy-All-AI-SeedData.ps1"

    if (Test-Path $aiSeedScript) {
        $aiParams = @{
            EnvironmentUrl   = $DataverseUrl
            SkipVerification = $true
        }
        if ($DryRun) { $aiParams['DryRun'] = $true }

        try {
            & $aiSeedScript @aiParams
            Write-Host "  [ok] AI seed data deployed" -ForegroundColor Green
        }
        catch {
            Write-Host "  [WARN] AI seed data deployment failed: $_" -ForegroundColor Yellow
            Write-Host "         Continuing — seed data may already exist." -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "  [SKIP] Deploy-All-AI-SeedData.ps1 not found at $aiSeedScript" -ForegroundColor Yellow
    }
}

# ===========================================================================
# STEP 3: Core Records (Layer 2)
# ===========================================================================
if (Should-RunStep 3) {
    Write-StepHeader 3 "Core Business Records (Layer 2)"
    & "$scriptDir/Load-CoreRecords.ps1" -Scenario $Scenario
}

# ===========================================================================
# STEP 4: Document Records (Layer 3)
# ===========================================================================
if (Should-RunStep 4) {
    Write-StepHeader 4 "Document Records (Layer 3)"
    & "$scriptDir/Load-DocumentRecords.ps1" -Scenario $Scenario
}

# ===========================================================================
# STEP 5: File Conversion
# ===========================================================================
if (Should-RunStep 5) {
    Write-StepHeader 5 "File Conversion (MD → PDF/DOCX)"

    $convertParams = @{ Scenario = $Scenario }
    if ($DryRun) { $convertParams['DryRun'] = $true }

    & "$scriptDir/Convert-MarkdownFiles.ps1" @convertParams
}

# ===========================================================================
# STEP 6: SPE File Upload (Layer 4)
# ===========================================================================
if (Should-RunStep 6) {
    Write-StepHeader 6 "SPE File Upload (Layer 4)"

    $uploadParams = @{
        Scenario       = $Scenario
        SpeContainerId = $SpeContainerId
        BffApiUrl      = $BffApiUrl
    }
    if ($DryRun) { $uploadParams['DryRun'] = $true }

    & "$scriptDir/Upload-SpeFiles.ps1" @uploadParams
}

# ===========================================================================
# STEP 7: Activity Records (Layer 5)
# ===========================================================================
if (Should-RunStep 7) {
    Write-StepHeader 7 "Activity Records (Layer 5)"
    & "$scriptDir/Load-ActivityRecords.ps1" -Scenario $Scenario
}

# ===========================================================================
# STEP 8: AI Search Index Seeding
# ===========================================================================
if (Should-RunStep 8) {
    Write-StepHeader 8 "AI Search Index Seeding"

    $seedParams = @{
        Scenario        = $Scenario
        SpaarkeRepoPath = $SpaarkeRepoPath
    }
    if ($DryRun) { $seedParams['DryRun'] = $true }

    & "$scriptDir/Seed-SearchIndexes.ps1" @seedParams
}

# ===========================================================================
# STEP 9: Validation
# ===========================================================================
if (Should-RunStep 9) {
    Write-StepHeader 9 "Validation"
    & "$scriptDir/Test-DemoEnvironment.ps1" -Scenario $Scenario
}

# ===========================================================================
# Done
# ===========================================================================
$elapsed = (Get-Date) - $startTime

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "  Setup Complete!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host "  Duration: $([Math]::Round($elapsed.TotalMinutes, 1)) minutes"
Write-Host "  Environment: $DataverseUrl"
if ($DryRun) { Write-Host "  (DRY RUN — no changes made)" -ForegroundColor Yellow }
Write-Host ""
