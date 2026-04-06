<#
.SYNOPSIS
    Load activity records (Layer 5) into Dataverse.
.DESCRIPTION
    Loads events, communications, KPI assessments, billing events,
    and spend snapshots in dependency order.
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
Write-Host "  Loading Activity Records (Layer 5)   " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$headers = Get-DataverseToken

$dataDir = Join-Path $PSScriptRoot "../../output/$Scenario"
if (-not (Test-Path $dataDir)) { throw "Scenario data not found: $dataDir" }

$totalLoaded = 0
$totalFailed = 0

# 1. Events
$result = Load-EntityFromFile -FilePath "$dataDir/events.json" -Headers $headers
$totalLoaded += $result.Loaded; $totalFailed += $result.Failed

# 2. Communications
$result = Load-EntityFromFile -FilePath "$dataDir/communications.json" -Headers $headers
$totalLoaded += $result.Loaded; $totalFailed += $result.Failed

# 3. KPI Assessments
$result = Load-EntityFromFile -FilePath "$dataDir/kpi-assessments.json" -Headers $headers
$totalLoaded += $result.Loaded; $totalFailed += $result.Failed

# 4. Billing Events
$result = Load-EntityFromFile -FilePath "$dataDir/billing-events.json" -Headers $headers
$totalLoaded += $result.Loaded; $totalFailed += $result.Failed

# 5. Spend Snapshots
$result = Load-EntityFromFile -FilePath "$dataDir/spend-snapshots.json" -Headers $headers
$totalLoaded += $result.Loaded; $totalFailed += $result.Failed

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Activity Records Summary             " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
$color = if ($totalFailed -gt 0) { 'Yellow' } else { 'Green' }
Write-Host "  Total Loaded: $totalLoaded" -ForegroundColor $color
Write-Host "  Total Failed: $totalFailed" -ForegroundColor $color
if ($totalFailed -gt 0) { exit 1 }
