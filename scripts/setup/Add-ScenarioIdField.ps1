<#
.SYNOPSIS
    Add sprk_scenarioid field to all entities that need it for demo data loading.

.DESCRIPTION
    Creates a sprk_scenarioid (String, 100 chars) attribute on each entity
    that participates in scenario-based data loading. This field is used for
    idempotent upserts — records are matched by scenario ID to avoid duplicates.

    Safe to re-run: skips entities that already have the field.

.PARAMETER DataverseUrl
    Target Dataverse environment. Default: https://spaarke-demo.crm.dynamics.com
#>

[CmdletBinding()]
param(
    [string] $DataverseUrl = "https://spaarke-demo.crm.dynamics.com"
)

$ErrorActionPreference = 'Stop'

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Add sprk_scenarioid Field            " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Environment: $DataverseUrl"
Write-Host ""

# Get token
$token = az account get-access-token --resource $DataverseUrl --query accessToken -o tsv 2>&1
if ($LASTEXITCODE -ne 0) { throw "Failed to get token: $token" }

$headers = @{
    'Authorization'    = "Bearer $token"
    'OData-MaxVersion' = '4.0'
    'OData-Version'    = '4.0'
    'Content-Type'     = 'application/json; charset=utf-8'
    'Accept'           = 'application/json'
}

$webApiUrl = "$DataverseUrl/api/data/v9.2"

# All entities that need sprk_scenarioid
$entities = @(
    'account',
    'contact',
    'sprk_matter',
    'sprk_project',
    'sprk_budget',
    'sprk_budgetbucket',
    'sprk_invoice',
    'sprk_workassignment',
    'sprk_document',
    'sprk_event',
    'sprk_communication',
    'sprk_kpiassessment',
    'sprk_billingevent',
    'sprk_spendsnapshot'
)

$added = 0
$skipped = 0
$errors = 0

foreach ($entity in $entities) {
    # Check if field already exists
    $checkUri = "$webApiUrl/EntityDefinitions(LogicalName='$entity')/Attributes(LogicalName='sprk_scenarioid')"
    $exists = $false
    try {
        $null = Invoke-RestMethod -Uri $checkUri -Headers $headers -Method Get
        $exists = $true
    }
    catch {
        $statusCode = $null
        if ($_.Exception.Response) { $statusCode = [int]$_.Exception.Response.StatusCode }
        if ($statusCode -ne 404) {
            Write-Host "  [ERROR] $entity — unexpected error checking field: $_" -ForegroundColor Red
            $errors++
            continue
        }
    }

    if ($exists) {
        Write-Host "  [SKIP] $entity — sprk_scenarioid already exists" -ForegroundColor DarkGray
        $skipped++
        continue
    }

    # Create the attribute
    $attrBody = @{
        '@odata.type'       = 'Microsoft.Dynamics.CRM.StringAttributeMetadata'
        'SchemaName'        = 'sprk_scenarioid'
        'DisplayName'       = @{
            '@odata.type'   = 'Microsoft.Dynamics.CRM.Label'
            'LocalizedLabels' = @(
                @{
                    '@odata.type' = 'Microsoft.Dynamics.CRM.LocalizedLabel'
                    'Label'       = 'Scenario ID'
                    'LanguageCode' = 1033
                }
            )
        }
        'Description'       = @{
            '@odata.type'   = 'Microsoft.Dynamics.CRM.Label'
            'LocalizedLabels' = @(
                @{
                    '@odata.type' = 'Microsoft.Dynamics.CRM.LocalizedLabel'
                    'Label'       = 'Identifier for demo/test scenario data loading. Used for idempotent upserts.'
                    'LanguageCode' = 1033
                }
            )
        }
        'RequiredLevel'     = @{
            'Value'         = 'None'
        }
        'MaxLength'         = 100
        'FormatName'        = @{ 'Value' = 'Text' }
        'ImeMode'           = 'Auto'
        'IsSearchable'      = $true
    } | ConvertTo-Json -Depth 10

    $createUri = "$webApiUrl/EntityDefinitions(LogicalName='$entity')/Attributes"

    try {
        $null = Invoke-RestMethod -Uri $createUri -Headers $headers -Method Post `
            -Body ([System.Text.Encoding]::UTF8.GetBytes($attrBody))
        Write-Host "  [OK] $entity — sprk_scenarioid created" -ForegroundColor Green
        $added++
    }
    catch {
        $errorDetail = $_.Exception.Message
        try {
            if ($_.ErrorDetails -and $_.ErrorDetails.Message) {
                $parsed = $_.ErrorDetails.Message | ConvertFrom-Json
                if ($parsed.error -and $parsed.error.message) { $errorDetail = $parsed.error.message }
            }
        } catch {}
        Write-Host "  [ERROR] $entity — $errorDetail" -ForegroundColor Red
        $errors++
    }
}

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Summary                              " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Added:   $added" -ForegroundColor Green
Write-Host "  Skipped: $skipped (already exist)" -ForegroundColor DarkGray
Write-Host "  Errors:  $errors" -ForegroundColor $(if ($errors -gt 0) { 'Red' } else { 'Gray' })
Write-Host ""

if ($errors -gt 0) { exit 1 }
