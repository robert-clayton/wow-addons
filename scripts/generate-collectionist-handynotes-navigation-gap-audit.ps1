param(
    [string]$HandyNotesRoot = "X:\Program Files\World of Warcraft\_retail_\Interface\AddOns",
    [string]$CurrentDb2Root = (Join-Path $env:TEMP "collectionist-tww-db2\current"),
    [string]$AuditRoot = (Join-Path $PSScriptRoot "..\research\collectionist\sources"),
    [string]$AddonRoot = (Join-Path $PSScriptRoot "..\addons\Collectionist"),
    [string]$ResearchRoot = (Join-Path $PSScriptRoot "..\research\collectionist")
)

$ErrorActionPreference = "Stop"

function Write-Utf8File([string]$path, [string]$text) {
    $directory = Split-Path -Parent $path
    if (-not (Test-Path -LiteralPath $directory)) {
        New-Item -ItemType Directory -Force -Path $directory | Out-Null
    }
    [System.IO.File]::WriteAllText($path, $text, [System.Text.UTF8Encoding]::new($false))
}

function Write-CsvFile([string]$path, $rows) {
    $csv = @($rows | ConvertTo-Csv -NoTypeInformation) -join "`n"
    Write-Utf8File $path ($csv + "`n")
}

if (-not (Test-Path -LiteralPath $HandyNotesRoot)) {
    throw "Missing installed HandyNotes root: $HandyNotesRoot"
}

$trackedNPCs = [System.Collections.Generic.HashSet[string]]::new()
foreach ($path in @(Get-ChildItem -LiteralPath (Join-Path $AddonRoot "Modules\Rares\Data") -File -Filter "*.lua")) {
    $content = Get-Content -Raw -LiteralPath $path.FullName
    foreach ($match in [regex]::Matches($content, '\b(?:criteriaNPCIDs|npcIDs)\s*=\s*\{([^}]*)\}')) {
        foreach ($idMatch in [regex]::Matches($match.Groups[1].Value, '\d+')) {
            [void]$trackedNPCs.Add($idMatch.Value)
        }
    }
    foreach ($match in [regex]::Matches($content, '\bnpcID\s*=\s*(\d+)')) {
        [void]$trackedNPCs.Add($match.Groups[1].Value)
    }
}

$trackedTreasureQuests = [System.Collections.Generic.HashSet[string]]::new()
foreach ($path in @(Get-ChildItem -LiteralPath (Join-Path $AddonRoot "Modules\Treasures\Data") -File -Filter "*.lua")) {
    foreach ($match in [regex]::Matches((Get-Content -Raw -LiteralPath $path.FullName), '\bquestID\s*=\s*(\d+)')) {
        [void]$trackedTreasureQuests.Add($match.Groups[1].Value)
    }
}

$trackedTreasureCriteria = [System.Collections.Generic.HashSet[string]]::new()
foreach ($path in @(Get-ChildItem -LiteralPath $ResearchRoot -Recurse -File -Filter "treasures.csv" | Where-Object FullName -match '\\manifests\\')) {
    foreach ($row in @(Import-Csv -LiteralPath $path.FullName)) {
        if ($row.criteria_id) { [void]$trackedTreasureCriteria.Add([string]$row.criteria_id) }
        if ($row.completion_quest_id) { [void]$trackedTreasureQuests.Add([string]$row.completion_quest_id) }
    }
}

$creatureByID = @{}
$creaturePath = Join-Path $CurrentDb2Root "Creature.csv"
if (Test-Path -LiteralPath $creaturePath) {
    foreach ($row in @(Import-Csv -LiteralPath $creaturePath)) { $creatureByID[[string]$row.ID] = $row }
}

# These plugins use coordinate-keyed zone tables rather than the Rare({...})
# and Treasure({...}) constructors counted by the earlier audit.
$tableAddons = [ordered]@{
    HandyNotes_BattleForAzerothTreasures = "battle_for_azeroth"
    HandyNotes_DragonflightTreasures = "dragonflight"
    HandyNotes_LegionTreasures = "legion"
    HandyNotes_MidnightTreasures = "midnight"
    HandyNotes_MistsOfPandariaTreasures = "mists_of_pandaria"
    HandyNotes_TreasureHunter = "wod"
    HandyNotes_WarWithin = "tww"
}

$nodes = [System.Collections.Generic.List[object]]::new()
foreach ($pair in $tableAddons.GetEnumerator()) {
    $zoneRoot = Join-Path (Join-Path $HandyNotesRoot $pair.Key) "zones"
    if (-not (Test-Path -LiteralPath $zoneRoot)) { continue }
    foreach ($path in @(Get-ChildItem -LiteralPath $zoneRoot -Recurse -File -Filter "*.lua")) {
        $content = Get-Content -Raw -LiteralPath $path.FullName
        foreach ($match in [regex]::Matches($content, '(?ms)^\s*\[(\d{8})\]\s*=\s*\{(.*?)(?=^\s*\[\d{8}\]\s*=|\z)')) {
            $coordinate = $match.Groups[1].Value
            $body = $match.Groups[2].Value
            $npcMatch = [regex]::Match($body, '\bnpc\s*=\s*(\d+)')
            $questMatch = [regex]::Match($body, '\bquest\s*=\s*(\d+)')
            $criteriaMatch = [regex]::Match($body, '\bcriteria\s*=\s*(\d+)')
            if (-not $npcMatch.Success -and -not $questMatch.Success) { continue }
            $commentMatch = [regex]::Match($body, '(?m)--\s*([^\r\n]+)\s*$')
            $nodes.Add([pscustomobject]@{
                expansion = $pair.Value
                addon = $pair.Key
                file = $path.Name
                coordinate = $coordinate
                npc_id = if ($npcMatch.Success) { $npcMatch.Groups[1].Value } else { "" }
                quest_id = if ($questMatch.Success) { $questMatch.Groups[1].Value } else { "" }
                criteria_id = if ($criteriaMatch.Success) { $criteriaMatch.Groups[1].Value } else { "" }
                comment = if ($commentMatch.Success) { $commentMatch.Groups[1].Value.Trim() } else { "" }
            })
        }
    }
}

$rareAudit = foreach ($group in @($nodes | Where-Object npc_id | Group-Object npc_id)) {
    $rows = @($group.Group)
    $id = [string]$group.Name
    $creature = $creatureByID[$id]
    [pscustomobject][ordered]@{
        decision        = if ($trackedNPCs.Contains($id)) { "already_achievement_backed" } else { "navigation_candidate_needs_dedup" }
        decision_basis  = if ($trackedNPCs.Contains($id)) { "npc_already_present_in_collectionist_rare_data" } else { "stable_npc_in_installed_handynotes_table_provider" }
        expansion       = @($rows.expansion | Sort-Object -Unique) -join ";"
        npc_id          = $id
        name            = if ($creature) { $creature.Name_lang } else { @($rows.comment | Where-Object { $_ } | Select-Object -First 1) }
        node_count      = $rows.Count
        source_addons   = @($rows.addon | Sort-Object -Unique) -join ";"
        source_files    = @($rows.file | Sort-Object -Unique) -join ";"
        coordinates     = @($rows.coordinate | Sort-Object -Unique) -join ";"
        quest_ids       = @($rows.quest_id | Where-Object { $_ } | Sort-Object -Unique) -join ";"
        criteria_ids    = @($rows.criteria_id | Where-Object { $_ } | Sort-Object -Unique) -join ";"
    }
}

$treasureAudit = foreach ($group in @($nodes | Where-Object { -not $_.npc_id -and $_.quest_id } | Group-Object quest_id)) {
    $rows = @($group.Group)
    $id = [string]$group.Name
    $criteriaIDs = @($rows.criteria_id | Where-Object { $_ } | Sort-Object -Unique)
    $coveredCriteria = @($criteriaIDs | Where-Object { $trackedTreasureCriteria.Contains([string]$_) })
    $covered = $trackedTreasureQuests.Contains($id) -or $coveredCriteria.Count -gt 0
    [pscustomobject][ordered]@{
        decision        = if ($covered) { "already_achievement_or_quest_backed" } else { "quest_identity_navigation_candidate" }
        decision_basis  = if ($covered) { "quest_or_criteria_already_present_in_collectionist_treasure_data" } else { "stable_quest_flag_in_installed_handynotes_table_provider" }
        expansion       = @($rows.expansion | Sort-Object -Unique) -join ";"
        quest_id        = $id
        node_count      = $rows.Count
        source_addons   = @($rows.addon | Sort-Object -Unique) -join ";"
        source_files    = @($rows.file | Sort-Object -Unique) -join ";"
        coordinates     = @($rows.coordinate | Sort-Object -Unique) -join ";"
        criteria_ids    = $criteriaIDs -join ";"
        comments        = @($rows.comment | Where-Object { $_ } | Sort-Object -Unique) -join ";"
    }
}

$rareAudit = @($rareAudit | Sort-Object { [int]$_.npc_id })
$treasureAudit = @($treasureAudit | Sort-Object { [int]$_.quest_id })
Write-CsvFile (Join-Path $AuditRoot "handynotes-table-rare-gap-audit.csv") $rareAudit
Write-CsvFile (Join-Path $AuditRoot "handynotes-table-treasure-gap-audit.csv") $treasureAudit

$rareCandidates = @($rareAudit | Where-Object decision -eq "navigation_candidate_needs_dedup")
$treasureCandidates = @($treasureAudit | Where-Object decision -eq "quest_identity_navigation_candidate")
$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add("# HandyNotes table-provider navigation gap audit")
$lines.Add("")
$lines.Add("The prior 1,707 Rare and 771 Treasure constructor counts cover one HandyNotes publisher family. Seven additional installed plugins use coordinate-keyed zone tables, so their stable NPC, quest, and criteria IDs require a separate scan.")
$lines.Add("")
$lines.Add("## Result")
$lines.Add("")
$lines.Add("- Unique table-provider rare NPCs: $($rareAudit.Count)")
$lines.Add("- Already represented by Collectionist rare data: $(@($rareAudit | Where-Object decision -eq 'already_achievement_backed').Count)")
$lines.Add("- Additional rare navigation candidates: $($rareCandidates.Count)")
$lines.Add("- Unique quest-identified treasure nodes: $($treasureAudit.Count)")
$lines.Add("- Already represented by Collectionist treasure criteria/quests: $(@($treasureAudit | Where-Object decision -eq 'already_achievement_or_quest_backed').Count)")
$lines.Add("- Additional quest-identity treasure candidates: $($treasureCandidates.Count)")
$lines.Add("")
$lines.Add("## Additional candidates by expansion")
$lines.Add("")
$lines.Add("| Expansion | Rare NPCs | Treasure quests |")
$lines.Add("| --- | ---: | ---: |")
foreach ($expansion in @("classic", "tbc", "wrath", "cataclysm", "mists_of_pandaria", "wod", "legion", "battle_for_azeroth", "shadowlands", "dragonflight", "tww", "midnight")) {
    $rareCount = @($rareCandidates | Where-Object { $_.expansion -split ";" -contains $expansion }).Count
    $treasureCount = @($treasureCandidates | Where-Object { $_.expansion -split ";" -contains $expansion }).Count
    if ($rareCount -or $treasureCount) { $lines.Add("| $expansion | $rareCount | $treasureCount |") }
}
$lines.Add("")
$lines.Add("## Interpretation")
$lines.Add("")
$lines.Add("These are normalized provider identities, not an ingestion list. Rare NPCs still need alias/phasing and coordinate review. Quest-only treasures need an explicit data-contract decision because the current navigation-only policy names objectID/itemID, while these providers supply a stable quest completion flag instead.")
Write-Utf8File (Join-Path $AuditRoot "handynotes-table-navigation-gap-audit.md") ((@($lines) -join "`n") + "`n")

Write-Host "Wrote $($rareAudit.Count) rare NPC decisions and $($treasureAudit.Count) treasure quest decisions"
