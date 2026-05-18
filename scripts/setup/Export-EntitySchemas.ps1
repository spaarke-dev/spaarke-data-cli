<#
.SYNOPSIS
    Export field names and navigation properties for all demo data entities.
#>
param(
    [string] $DataverseUrl = "https://spaarke-demo.crm.dynamics.com"
)

$ErrorActionPreference = 'Stop'
$token = az account get-access-token --resource $DataverseUrl --query accessToken -o tsv
$headers = @{ 'Authorization' = "Bearer $token"; 'Accept' = 'application/json' }
$api = "$DataverseUrl/api/data/v9.2"

$entities = @(
    'account','contact',
    'sprk_matter','sprk_project','sprk_budget','sprk_budgetbucket',
    'sprk_invoice','sprk_workassignment','sprk_document',
    'sprk_event','sprk_communication','sprk_kpiassessment',
    'sprk_billingevent','sprk_spendsnapshot'
)

$allSchemas = @{}

foreach ($entity in $entities) {
    Write-Host "--- $entity ---" -ForegroundColor Cyan

    # Get all attributes
    $attrUrl = "$api/EntityDefinitions(LogicalName='$entity')/Attributes?`$select=LogicalName,AttributeType,IsValidForCreate"
    $allAttrs = (Invoke-RestMethod -Uri $attrUrl -Headers $headers).value

    # Get navigation properties for lookups
    $navUrl = "$api/EntityDefinitions(LogicalName='$entity')/ManyToOneRelationships?`$select=ReferencingAttribute,ReferencingEntityNavigationPropertyName,ReferencedEntity"
    $navs = (Invoke-RestMethod -Uri $navUrl -Headers $headers).value

    # Filter to writable sprk_ fields + key standard fields
    $standardFields = @('name','firstname','lastname','emailaddress1','jobtitle','telephone1',
        'mobilephone','description','fullname','revenue','numberofemployees','industrycode',
        'websiteurl','address1_line1','address1_city','address1_stateorprovince',
        'address1_postalcode','address1_country','statuscode','statecode','company')

    $fields = @{}
    foreach ($a in $allAttrs) {
        if (-not $a.IsValidForCreate) { continue }
        if ($a.AttributeType -eq 'Virtual') { continue }
        if ($a.LogicalName.StartsWith('sprk_') -or $a.LogicalName -in $standardFields) {
            $fields[$a.LogicalName] = $a.AttributeType
        }
    }

    $lookups = @{}
    foreach ($n in $navs) {
        $attr = $n.ReferencingAttribute
        if ($attr.StartsWith('sprk_') -or $attr -eq 'parentcustomerid') {
            $lookups[$attr] = @{
                nav = $n.ReferencingEntityNavigationPropertyName
                target = $n.ReferencedEntity
            }
        }
    }

    $allSchemas[$entity] = @{ fields = $fields; lookups = $lookups }

    Write-Host "  Fields ($($fields.Count)): $(($fields.Keys | Where-Object { $_.StartsWith('sprk_') } | Sort-Object) -join ', ')" -ForegroundColor DarkGray
    foreach ($lk in ($lookups.GetEnumerator() | Sort-Object Key)) {
        Write-Host "  Lookup: $($lk.Key) → nav=$($lk.Value.nav) → $($lk.Value.target)" -ForegroundColor DarkGray
    }
}

$outPath = Join-Path $PSScriptRoot "../../schemas/demo-entity-schemas.json"
$outDir = Split-Path $outPath -Parent
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }
$allSchemas | ConvertTo-Json -Depth 5 | Set-Content $outPath -Encoding UTF8
Write-Host "`nSchema exported to: $outPath" -ForegroundColor Green
