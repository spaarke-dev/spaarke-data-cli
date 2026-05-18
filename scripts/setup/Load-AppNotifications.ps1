#requires -Version 7.0
<#
.SYNOPSIS
    Seed appnotification records for the Daily Briefing module in the demo environment.

.DESCRIPTION
    Pulls existing seeded data (matters, documents, events, communications, work
    assignments) from Dataverse, then generates ~40 appnotification records owned
    by the recipient user. Notifications are spread across the 7 Daily Briefing
    channels with realistic priority distribution and createdon spread over the
    last 72 hours.

    Channels: tasks-overdue, tasks-due-soon, new-documents, new-emails,
              new-events, matter-activity, work-assignments

.PARAMETER RecipientEmail
    UPN of the user the notifications are owned by. Default: ralph.schroeder@spaarke.com

.PARAMETER ClearExisting
    If set, deletes existing appnotifications owned by the recipient before seeding.
#>

[CmdletBinding()]
param(
    [string] $RecipientEmail = 'ralph.schroeder@spaarke.com',
    [switch] $ClearExisting
)

$ErrorActionPreference = 'Stop'

. "$PSScriptRoot/Helpers/Invoke-DataverseApi.ps1"

$baseUri = "https://spaarke-demo.crm.dynamics.com/api/data/v9.2"
$headers = Get-DataverseToken

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Daily Briefing — appnotification Seeder" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Recipient: $RecipientEmail"
Write-Host "  Target:    $baseUri"
Write-Host ""

# ---------------------------------------------------------------------------
# Step 1: Resolve recipient systemuserid
# ---------------------------------------------------------------------------
$filter = "domainname eq '$RecipientEmail' or internalemailaddress eq '$RecipientEmail'"
$encoded = [System.Uri]::EscapeDataString($filter)
$userUri = "$baseUri/systemusers?`$select=systemuserid,fullname&`$filter=$encoded"
$userRes = Invoke-DataverseRequest -Method GET -Uri $userUri -Headers $headers
if ($userRes.value.Count -eq 0) { throw "User $RecipientEmail not found." }
$userId = $userRes.value[0].systemuserid
$userName = $userRes.value[0].fullname
Write-Host "  Recipient resolved: $userName ($userId)" -ForegroundColor Green

# ---------------------------------------------------------------------------
# Step 2: Pull source records (filtered to mvp-* scenario)
# ---------------------------------------------------------------------------
function Fetch-Set {
    param([string]$Set, [string]$Select, [int]$Top = 100)
    $f = [System.Uri]::EscapeDataString("startswith(sprk_scenarioid,'mvp-')")
    $url = "$baseUri/$Set" + "?`$select=$Select&`$filter=$f&`$top=$Top"
    return (Invoke-DataverseRequest -Method GET -Uri $url -Headers $headers).value
}

Write-Host "  Loading source records..." -ForegroundColor DarkGray
$matters     = Fetch-Set 'sprk_matters'         'sprk_matterid,sprk_matternumber,sprk_matterdescription'
$documents   = Fetch-Set 'sprk_documents'       'sprk_documentid,sprk_documentname,sprk_filename,sprk_documenttype'
$events      = Fetch-Set 'sprk_events'          'sprk_eventid,sprk_eventname,sprk_duedate,sprk_eventtypecode'
$comms       = Fetch-Set 'sprk_communications'  'sprk_communicationid,sprk_subject,sprk_sentat'
$assigns     = Fetch-Set 'sprk_workassignments' 'sprk_workassignmentid,sprk_name,sprk_regardingrecordname,sprk_responseduedate'

Write-Host "    Matters: $($matters.Count) | Docs: $($documents.Count) | Events: $($events.Count) | Comms: $($comms.Count) | Assignments: $($assigns.Count)"
Write-Host ""

if ($matters.Count -eq 0) { throw "No matters found with sprk_scenarioid starting with 'mvp-'. Run core record loading first." }

# ---------------------------------------------------------------------------
# Step 3: Optionally clear existing notifications
# ---------------------------------------------------------------------------
if ($ClearExisting) {
    Write-Host "  Clearing existing appnotifications for $userName..." -ForegroundColor Yellow
    $listUri = "$baseUri/appnotifications?`$select=appnotificationid&`$filter=_ownerid_value eq $userId"
    $existing = (Invoke-DataverseRequest -Method GET -Uri $listUri -Headers $headers).value
    foreach ($n in $existing) {
        $delUri = "$baseUri/appnotifications($($n.appnotificationid))"
        Invoke-DataverseRequest -Method DELETE -Uri $delUri -Headers $headers | Out-Null
    }
    Write-Host "    Deleted $($existing.Count) existing notification(s)" -ForegroundColor DarkGray
    Write-Host ""
}

# ---------------------------------------------------------------------------
# Step 4: Build notification records across 7 channels
# ---------------------------------------------------------------------------

# Priority option set: 200000000=Normal, 200000001=High
# Icontype:            100000000=Info, 100000001=Success, 100000002=Failure, 100000003=Warning
# Toasttype:           200000001=Hidden (unread); 200000000=Timed (dismissed)

$matter = $matters[0]                         # Single matter (Meridian Corp v. Pinnacle)
$matterId = $matter.sprk_matterid
$matterName = "$($matter.sprk_matternumber): Meridian Corp v. Pinnacle Industries"

$rng = [System.Random]::new(20260504)         # Deterministic seed for reproducibility
$now = [DateTime]::UtcNow

function New-Notification {
    param(
        [string]$Title,
        [string]$Body,
        [string]$Category,
        [string]$NotifPriority,           # "urgent" | "high" | "normal"
        [int]$DvPriority,                 # 200000000 normal | 200000001 high
        [int]$IconType,
        [string]$ActionUrl,
        [string]$RegardingId,
        [string]$RegardingType,
        [string]$RegardingName,
        [int]$AgeMinutes
    )

    $customData = [ordered]@{
        category            = $Category
        priority            = $NotifPriority
        actionUrl           = $ActionUrl
        regardingName       = $RegardingName
        regardingEntityType = $RegardingType
        regardingId         = $RegardingId
        isAiGenerated       = $false
    }
    $dataPayload = [ordered]@{
        iconUrl    = ''
        customData = $customData
    } | ConvertTo-Json -Depth 5 -Compress

    $createdAt = $now.AddMinutes(-$AgeMinutes).ToString("yyyy-MM-ddTHH:mm:ssZ")

    [ordered]@{
        title                  = $Title
        body                   = $Body
        data                   = $dataPayload
        priority               = $DvPriority
        icontype               = $IconType
        toasttype              = 200000001     # Hidden / unread
        'ownerid@odata.bind'   = "/systemusers($userId)"
        overriddencreatedon    = $createdAt
    }
}

$notifications = [System.Collections.Generic.List[hashtable]]::new()

# --- Channel 1: tasks-overdue (6 records, urgent) ---
$overdueEvents = $events | Sort-Object sprk_duedate | Select-Object -First 6
$overdueAge = 30
foreach ($e in $overdueEvents) {
    $eventName = $e.sprk_eventname
    $dueDate = if ($e.sprk_duedate) { ([DateTime]$e.sprk_duedate).ToString('MMM d') } else { 'last week' }
    $url = "/main.aspx?pagetype=entityrecord&etn=sprk_event&id=$($e.sprk_eventid)"
    $notifications.Add( (New-Notification `
        -Title "Overdue: $eventName" `
        -Body "This task was due $dueDate and remains incomplete on $matterName. Update status or reassign." `
        -Category 'tasks-overdue' `
        -NotifPriority 'urgent' `
        -DvPriority 200000001 `
        -IconType 100000002 `
        -ActionUrl $url `
        -RegardingId $e.sprk_eventid `
        -RegardingType 'sprk_event' `
        -RegardingName $eventName `
        -AgeMinutes $overdueAge) )
    $overdueAge += $rng.Next(60, 240)
}

# --- Channel 2: tasks-due-soon (8 records, high priority) ---
$dueSoonEvents = $events | Where-Object { $_ -notin $overdueEvents } | Get-Random -Count 8
$dueSoonAge = 90
foreach ($e in $dueSoonEvents) {
    $eventName = $e.sprk_eventname
    $dueIn = $rng.Next(1, 7)
    $url = "/main.aspx?pagetype=entityrecord&etn=sprk_event&id=$($e.sprk_eventid)"
    $notifications.Add( (New-Notification `
        -Title "Due in $dueIn day(s): $eventName" `
        -Body "Upcoming deadline on $matterName. Estimated effort scheduled before deadline." `
        -Category 'tasks-due-soon' `
        -NotifPriority 'high' `
        -DvPriority 200000001 `
        -IconType 100000003 `
        -ActionUrl $url `
        -RegardingId $e.sprk_eventid `
        -RegardingType 'sprk_event' `
        -RegardingName $eventName `
        -AgeMinutes $dueSoonAge) )
    $dueSoonAge += $rng.Next(60, 200)
}

# --- Channel 3: new-documents (8 records, high priority) ---
$newDocs = $documents | Where-Object { $_.sprk_documentname } | Get-Random -Count 8
$docAge = 30
foreach ($d in $newDocs) {
    $docName = if ($d.sprk_documentname) { $d.sprk_documentname } else { $d.sprk_filename }
    $url = "/main.aspx?pagetype=entityrecord&etn=sprk_document&id=$($d.sprk_documentid)"
    $notifications.Add( (New-Notification `
        -Title "New document: $docName" `
        -Body "Added to $matterName. AI classification and indexing complete; document available for search and review." `
        -Category 'new-documents' `
        -NotifPriority 'high' `
        -DvPriority 200000001 `
        -IconType 100000001 `
        -ActionUrl $url `
        -RegardingId $d.sprk_documentid `
        -RegardingType 'sprk_document' `
        -RegardingName $docName `
        -AgeMinutes $docAge) )
    $docAge += $rng.Next(45, 180)
}

# --- Channel 4: new-emails (6 records, normal priority) ---
$newEmails = $comms | Where-Object { $_.sprk_subject } | Get-Random -Count 6
$mailAge = 45
foreach ($c in $newEmails) {
    $subj = $c.sprk_subject
    $url = "/main.aspx?pagetype=entityrecord&etn=sprk_communication&id=$($c.sprk_communicationid)"
    $notifications.Add( (New-Notification `
        -Title "New email: $subj" `
        -Body "Received on $matterName. Review for action items and update matter status accordingly." `
        -Category 'new-emails' `
        -NotifPriority 'normal' `
        -DvPriority 200000000 `
        -IconType 100000000 `
        -ActionUrl $url `
        -RegardingId $c.sprk_communicationid `
        -RegardingType 'sprk_communication' `
        -RegardingName $subj `
        -AgeMinutes $mailAge) )
    $mailAge += $rng.Next(60, 240)
}

# --- Channel 5: new-events (5 records, normal priority) ---
$newEventRecs = $events | Where-Object { $_ -notin $overdueEvents -and $_ -notin $dueSoonEvents } | Get-Random -Count 5
$evAge = 75
foreach ($e in $newEventRecs) {
    $eventName = $e.sprk_eventname
    $url = "/main.aspx?pagetype=entityrecord&etn=sprk_event&id=$($e.sprk_eventid)"
    $notifications.Add( (New-Notification `
        -Title "New event: $eventName" `
        -Body "Added to $matterName calendar. Review schedule and confirm attendance." `
        -Category 'new-events' `
        -NotifPriority 'normal' `
        -DvPriority 200000000 `
        -IconType 100000000 `
        -ActionUrl $url `
        -RegardingId $e.sprk_eventid `
        -RegardingType 'sprk_event' `
        -RegardingName $eventName `
        -AgeMinutes $evAge) )
    $evAge += $rng.Next(90, 280)
}

# --- Channel 6: matter-activity (4 records, mixed priority) ---
$matterActivities = @(
    @{ Title = "Budget update: $matterName"; Body = "Q2 budget revised upward by 15% pending approval. Variance analysis attached."; Pri = 'high'; DvPri = 200000001; Icon = 100000003 }
    @{ Title = "Status change: $matterName moved to Discovery phase"; Body = "Phase transition recorded. Discovery deadline set per case management plan."; Pri = 'normal'; DvPri = 200000000; Icon = 100000000 }
    @{ Title = "Team member added: $matterName"; Body = "Senior associate added to engagement team. Access and permissions provisioned."; Pri = 'normal'; DvPri = 200000000; Icon = 100000000 }
    @{ Title = "KPI flagged: Budget compliance below threshold on $matterName"; Body = "Current spend pace exceeds approved budget trajectory. Review forecast and adjust burn rate."; Pri = 'high'; DvPri = 200000001; Icon = 100000003 }
)
$maAge = 120
foreach ($a in $matterActivities) {
    $url = "/main.aspx?pagetype=entityrecord&etn=sprk_matter&id=$matterId"
    $notifications.Add( (New-Notification `
        -Title $a.Title `
        -Body $a.Body `
        -Category 'matter-activity' `
        -NotifPriority $a.Pri `
        -DvPriority $a.DvPri `
        -IconType $a.Icon `
        -ActionUrl $url `
        -RegardingId $matterId `
        -RegardingType 'sprk_matter' `
        -RegardingName $matterName `
        -AgeMinutes $maAge) )
    $maAge += $rng.Next(120, 360)
}

# --- Channel 7: work-assignments (3 records, normal priority) ---
$assignAge = 150
foreach ($w in ($assigns | Get-Random -Count ([Math]::Min(3, $assigns.Count)))) {
    $name = $w.sprk_name
    $regarding = if ($w.sprk_regardingrecordname) { $w.sprk_regardingrecordname } else { $matterName }
    $url = "/main.aspx?pagetype=entityrecord&etn=sprk_workassignment&id=$($w.sprk_workassignmentid)"
    $notifications.Add( (New-Notification `
        -Title "Work assignment: $name" `
        -Body "Assigned regarding $regarding. Response requested by due date — review scope and acknowledge." `
        -Category 'work-assignments' `
        -NotifPriority 'normal' `
        -DvPriority 200000000 `
        -IconType 100000000 `
        -ActionUrl $url `
        -RegardingId $w.sprk_workassignmentid `
        -RegardingType 'sprk_workassignment' `
        -RegardingName $name `
        -AgeMinutes $assignAge) )
    $assignAge += $rng.Next(180, 480)
}

Write-Host "  Generated $($notifications.Count) notifications across 7 channels" -ForegroundColor Green
Write-Host ""

# ---------------------------------------------------------------------------
# Step 5: POST each notification
# ---------------------------------------------------------------------------
Write-Host "  Creating notifications in Dataverse..." -ForegroundColor Cyan
$created = 0
$failed = 0
$failures = @()
foreach ($n in $notifications) {
    try {
        $body = $n | ConvertTo-Json -Depth 8 -Compress
        $createUri = "$baseUri/appnotifications"
        Invoke-DataverseRequest -Method POST -Uri $createUri -Headers $headers -RawBody $body | Out-Null
        $created++
        Write-Host "    [+] $($n.title.Substring(0, [Math]::Min(70, $n.title.Length)))" -ForegroundColor DarkGray
    } catch {
        $failed++
        $failures += [pscustomobject]@{ Title = $n.title; Error = $_.Exception.Message }
        Write-Host "    [x] FAILED: $($n.title) — $($_.Exception.Message.Substring(0, [Math]::Min(120, $_.Exception.Message.Length)))" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Result: Created=$created, Failed=$failed" -ForegroundColor $(if ($failed) { 'Yellow' } else { 'Green' })
Write-Host "============================================================" -ForegroundColor Cyan

if ($failures.Count -gt 0) {
    Write-Host ""
    Write-Host "  Failures:" -ForegroundColor Red
    $failures | ForEach-Object { Write-Host "    - $($_.Title): $($_.Error)" -ForegroundColor Red }
    exit 1
}
