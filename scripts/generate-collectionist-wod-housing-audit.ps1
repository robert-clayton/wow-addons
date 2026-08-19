param(
    [string]$SourceJson = (Join-Path $env:TEMP "collectionist-wod-decor-details.json"),
    [string]$GlobalCardJson = (Join-Path $env:TEMP "collectionist-all-decor-structured-sources.json"),
    [string]$AttRoot = (Join-Path $env:TEMP "collectionist-att-12007"),
    [string]$OutputRoot = (Join-Path $PSScriptRoot "..\research\collectionist\warlords-of-draenor\sources")
)

$ErrorActionPreference = "Stop"

function Assert-Equal($Actual, $Expected, [string]$Label) {
    if ($Actual -ne $Expected) {
        throw "$Label mismatch: expected $Expected, got $Actual"
    }
}

function Get-LinkedIDs($Links, [string]$Kind) {
    $ids = foreach ($link in @($Links)) {
        if ([string]$link.href -match "/$Kind/(\d+)") { $Matches[1] }
    }
    return (@($ids | Select-Object -Unique) -join ";")
}

function Get-DecorID($Row) {
    if ([string]$Row.href -notmatch "/decor/(\d+)/") {
        throw "Could not parse decor ID from '$($Row.href)'"
    }
    return $Matches[1]
}

function Get-CardDecorID($Row) {
    if ([string]$Row.href -notmatch "/decor/(\d+)/") {
        throw "Could not parse decor ID from global catalog card '$($Row.href)'"
    }
    return $Matches[1]
}

function Get-CardLinkedIDs($Row, [string]$Kind) {
    $ids = foreach ($link in @($Row.sourceLinks)) {
        if ([string]$link.href -match "wowdb\.com/$Kind/(\d+)") { $Matches[1] }
    }
    return @($ids | Select-Object -Unique)
}

function Get-NormalizedText([string]$Value) {
    return (($Value -replace "\s+", " ").Trim())
}

function Get-SourceKind($Row) {
    $achievementIDs = Get-LinkedIDs $Row.sourceLinks "achievements"
    $questIDs = Get-LinkedIDs $Row.sourceLinks "quests"
    if ([string]$Row.sourceText -match "Crafting:|Profession:") { return "crafted" }
    if ($achievementIDs) { return "achievement" }
    if ($questIDs) { return "quest" }
    if ([string]$Row.sourceText -match "Vendor:|Reputation") { return "vendor" }
    return "drop"
}

function Convert-CatalogRow($Row, [string]$Status, [string]$Expansion, [string]$Note) {
    $decorID = Get-DecorID $Row
    [pscustomobject]@{
        decor_id               = $decorID
        catalog_name           = $Row.name
        catalog_scope          = "wod_theme"
        status                 = $Status
        acquisition_expansion  = $Expansion
        source_kind            = Get-SourceKind $Row
        source_text            = Get-NormalizedText $Row.sourceText
        achievement_ids        = Get-LinkedIDs $Row.sourceLinks "achievements"
        quest_ids              = Get-LinkedIDs $Row.sourceLinks "quests"
        npc_ids                = Get-LinkedIDs $Row.sourceLinks "npcs"
        source_spell_ids       = Get-LinkedIDs $Row.sourceLinks "spells"
        currency_ids           = Get-LinkedIDs $Row.sourceLinks "currencies"
        source_item_ids        = Get-LinkedIDs $Row.sourceLinks "items"
        decor_spell_id         = Get-LinkedIDs $Row.itemLinks "spells"
        item_id                = Get-LinkedIDs $Row.itemLinks "items"
        classification_note    = $Note
        acquisition_source_url = "https://housing.wowdb.com$($Row.href)"
    }
}

if (-not (Test-Path -LiteralPath $SourceJson)) {
    throw "Missing Warlords housing detail capture: $SourceJson"
}
if (-not (Test-Path -LiteralPath $GlobalCardJson)) {
    throw "Missing global housing card capture: $GlobalCardJson"
}
if (-not (Test-Path -LiteralPath $AttRoot)) {
    throw "Missing All The Things source checkout: $AttRoot"
}

$rows = @(Get-Content -Raw -LiteralPath $SourceJson | ConvertFrom-Json)
Assert-Equal $rows.Count 142 "Warlords theme catalog row count"

$wodSignal = "Draenor|Garrison Resources|Apexis Crystal|Iron Horde Scraps|Warlords of Draenor|Arakkoa Outcasts|Laughing Skulls|Council of Exarchs|Hand of the Prophet|Order of the Awakened|Vol'jin's Headhunters|Steamwheedle Preservation|Sha'tari Defense|Secrets of Skettis"
$explicitWodIDs = @(
    "925", "1323", "1324", "8178", "8187", "8238",
    "12201", "12202", "12204", "12205", "12208", "12209"
)

$expansionExclusions = [ordered]@{
    legion      = @("750", "926", "930", "8189")
    bfa         = @("1118", "2322", "2323")
    shadowlands = @("4405")
    midnight    = @("126", "23548", "23549", "2513", "2514", "3900", "3902", "3903", "3905", "9439", "9440", "9441", "22006", "22007", "25101", "25102", "25103", "26363")
    mop         = @("4488", "8180")
    wrath       = @("3896", "3897", "3898", "4448")
    cata        = @("1216", "1315", "4401", "4444", "4447", "4813", "4814")
    vanilla     = @("4402", "4443", "4445", "4446", "4487", "4490", "4811", "4812", "4815", "5115", "5116", "9424", "11274")
}
$hiddenIDs = @("519", "1319", "1320", "3835", "4449", "4489", "24888")
$internalIDs = @("14353", "18826", "21889")

$exclusionByID = @{}
foreach ($expansion in $expansionExclusions.Keys) {
    foreach ($id in $expansionExclusions[$expansion]) {
        $exclusionByID[$id] = [pscustomobject]@{
            status = "acquisition_${expansion}_confirmed"
            expansion = $expansion
            note = "Displayed acquisition belongs to $expansion content, not Warlords of Draenor"
        }
    }
}
foreach ($id in $hiddenIDs) {
    $exclusionByID[$id] = [pscustomobject]@{
        status = "catalog_hidden_unobtainable"
        expansion = ""
        note = "No current acquisition source is displayed"
    }
}
foreach ($id in $internalIDs) {
    $exclusionByID[$id] = [pscustomobject]@{
        status = "internal_dnt"
        expansion = ""
        note = "Internal or autogenerated DNT catalog row"
    }
}

$auditRows = @()
$excludedRows = @()
$catalogRows = @()
foreach ($row in $rows) {
    $id = Get-DecorID $row
    $isWod = ([string]$row.sourceText -match $wodSignal) -or ($id -in $explicitWodIDs)
    if ($isWod) {
        $classified = Convert-CatalogRow $row "acquisition_wod_confirmed" "wod" "Displayed acquisition uses Warlords of Draenor content"
        $auditRows += $classified
        $catalogRows += $classified
        continue
    }

    $exclusion = $exclusionByID[$id]
    if (-not $exclusion) { throw "Unclassified Warlords-theme decor $id ($($row.name))" }
    $classified = Convert-CatalogRow $row $exclusion.status $exclusion.expansion $exclusion.note
    $excludedRows += $classified
    $catalogRows += $classified
}

Assert-Equal $auditRows.Count 80 "Warlords-owned decoration count"
Assert-Equal $excludedRows.Count 62 "Warlords-theme exclusion count"
Assert-Equal @($excludedRows | Where-Object status -eq "catalog_hidden_unobtainable").Count 7 "Hidden/source-less exclusion count"
Assert-Equal @($excludedRows | Where-Object status -eq "internal_dnt").Count 3 "Internal exclusion count"

$allIDs = @($catalogRows | ForEach-Object { [string]$_.decor_id })
$duplicateIDs = @($allIDs | Group-Object | Where-Object Count -gt 1)
Assert-Equal $duplicateIDs.Count 0 "Duplicate decor ID count"

New-Item -ItemType Directory -Force -Path $OutputRoot | Out-Null
$catalogRows | Sort-Object { [int]$_.decor_id } | Export-Csv -LiteralPath (Join-Path $OutputRoot "housing-wowdb-theme-catalog.csv") -NoTypeInformation -Encoding utf8
$auditRows | Sort-Object { [int]$_.decor_id } | Export-Csv -LiteralPath (Join-Path $OutputRoot "housing-wowdb-acquisition-audit.csv") -NoTypeInformation -Encoding utf8
$excludedRows | Sort-Object { [int]$_.decor_id } | Export-Csv -LiteralPath (Join-Path $OutputRoot "housing-wowdb-theme-exclusions.csv") -NoTypeInformation -Encoding utf8

# Decoration ownership is acquisition-first. The expansion/theme filter is only
# a candidate source: it cannot prove ownership, and a vendor's location alone
# is not an expansion requirement. Reverse-scan the entire live catalog for
# linked Warlords quests, NPCs, currencies, Draenor professions, and explicit
# Warlords source text so a differently themed decoration cannot be missed.
$globalCards = @(Get-Content -Raw -LiteralPath $GlobalCardJson | ConvertFrom-Json)
Assert-Equal $globalCards.Count 2911 "Global housing catalog card count"
Assert-Equal @($globalCards | ForEach-Object { Get-CardDecorID $_ } | Select-Object -Unique).Count 2911 "Unique global housing decor ID count"

$attRoots = @(
    (Join-Path $AttRoot ".contrib\Parser\DATAS\01 - Dungeons Raids\06 - Warlords of Draenor"),
    (Join-Path $AttRoot ".contrib\Parser\DATAS\02 - Outdoor Zones\07 Draenor"),
    (Join-Path $AttRoot ".contrib\Parser\DATAS\06 - Expansion Features\06 - Warlords of Draenor")
)
foreach ($root in $attRoots) {
    if (-not (Test-Path -LiteralPath $root)) { throw "Missing Warlords ATT source root: $root" }
}

$wodQuestIDs = [System.Collections.Generic.HashSet[int]]::new()
$wodNpcIDs = [System.Collections.Generic.HashSet[int]]::new()
foreach ($file in @($attRoots | ForEach-Object { Get-ChildItem -LiteralPath $_ -Recurse -File -Filter "*.lua" })) {
    $text = Get-Content -Raw -LiteralPath $file.FullName
    foreach ($match in [regex]::Matches($text, '(?m)(?:^|[^A-Za-z])q\((\d+)|questID\s*=\s*(\d+)')) {
        $id = if ($match.Groups[1].Success) { $match.Groups[1].Value } else { $match.Groups[2].Value }
        [void]$wodQuestIDs.Add([int]$id)
    }
    foreach ($pattern in @('(?:cr|n)\((\d+)', '(?:npcID|creatureID)\s*=\s*(\d+)', '["'']n["'']\s*,\s*(\d+)')) {
        foreach ($match in [regex]::Matches($text, $pattern)) { [void]$wodNpcIDs.Add([int]$match.Groups[1].Value) }
    }
    foreach ($match in [regex]::Matches($text, '(?:crs|qgs)\s*=\s*\{([^}]*)\}')) {
        foreach ($number in [regex]::Matches($match.Groups[1].Value, '\d+')) { [void]$wodNpcIDs.Add([int]$number.Value) }
    }
}

$wodCurrencyIDs = @("810", "821", "823", "824", "828", "829", "910", "944", "980", "994", "999", "1008", "1017", "1020", "1101", "1129", "1191")
$globalTextSignal = "Draenor|Garrison|Apexis|Iron Horde|Frostfire Ridge|Tanaan Jungle|Gorgrond|Talador|Spires of Arak|Ashran|Stormshield|Warspear|Lunarfall|Frostwall|Bloodmaul Slag Mines|Iron Docks|Skyreach|Grimrail Depot|Everbloom|Shadowmoon Burial Grounds|Upper Blackrock Spire|Highmaul|Blackrock Foundry|Hellfire Citadel|Warlord Zaela|Teron.gor|Frostwolf Orcs|Council of Exarchs|Arakkoa Outcasts|Laughing Skull|Sha.tari Defense|Steamwheedle Preservation|Vol.jin.s (Spear|Headhunters)|Hand of the Prophet|Order of the Awakened|Saberstalkers"

$classificationByID = @{}
foreach ($row in @($auditRows) + @($excludedRows)) { $classificationByID[[string]$row.decor_id] = $row }
$globalAuditRows = foreach ($card in $globalCards) {
    $id = Get-CardDecorID $card
    $questIDs = @(Get-CardLinkedIDs $card "quests" | Where-Object { $wodQuestIDs.Contains([int]$_) })
    $npcIDs = @(Get-CardLinkedIDs $card "npcs" | Where-Object { $wodNpcIDs.Contains([int]$_) })
    $currencyIDs = @(Get-CardLinkedIDs $card "currencies" | Where-Object { [string]$_ -in $wodCurrencyIDs })
    $hasTextSignal = [string]$card.text -match $globalTextSignal
    $hasProfessionSignal = [string]$card.text -match "Profession: Draenor"
    if (-not ($hasTextSignal -or $hasProfessionSignal -or $questIDs.Count -gt 0 -or $npcIDs.Count -gt 0 -or $currencyIDs.Count -gt 0)) { continue }

    $classification = $classificationByID[$id]
    if (-not $classification) { throw "Unclassified global Warlords acquisition candidate $id ($($card.name))" }
    [pscustomobject]@{
        decor_id                  = $id
        catalog_name              = $card.name
        card_source_text          = Get-NormalizedText $card.text
        text_signal               = $hasTextSignal
        draenor_profession_signal = $hasProfessionSignal
        wod_quest_ids             = ($questIDs -join ";")
        wod_npc_ids               = ($npcIDs -join ";")
        wod_currency_ids          = ($currencyIDs -join ";")
        status                    = $classification.status
        acquisition_expansion     = $classification.acquisition_expansion
        classification_note       = $classification.classification_note
        acquisition_source_url    = $classification.acquisition_source_url
    }
}

Assert-Equal @($globalAuditRows).Count 83 "Global Warlords acquisition signal row count"
Assert-Equal @($globalAuditRows | Where-Object status -eq "acquisition_wod_confirmed").Count 80 "Globally confirmed Warlords decoration count"
Assert-Equal @($globalAuditRows | Where-Object text_signal -eq $true).Count 81 "Global Warlords text-signal count"
Assert-Equal @($globalAuditRows | Where-Object wod_quest_ids).Count 27 "Global Warlords quest-linked decoration count"
Assert-Equal @($globalAuditRows | Where-Object wod_npc_ids).Count 48 "Global Warlords NPC-linked decoration count"
Assert-Equal @($globalAuditRows | Where-Object wod_currency_ids).Count 41 "Global Warlords currency-linked decoration count"
Assert-Equal @($globalAuditRows | Where-Object draenor_profession_signal -eq $true).Count 21 "Global Draenor-profession decoration count"
Assert-Equal @($auditRows | Where-Object { [string]$_.decor_id -notin @($globalAuditRows.decor_id) }).Count 0 "Warlords audit rows absent from global reverse scan"
$globalExclusionIDs = @($globalAuditRows | Where-Object status -ne "acquisition_wod_confirmed" | Sort-Object { [int]$_.decor_id } | ForEach-Object { [string]$_.decor_id })
Assert-Equal ($globalExclusionIDs -join ";") "126;3835;21889" "Global Warlords signal exclusion IDs"
$globalAuditRows | Sort-Object { [int]$_.decor_id } | Export-Csv -LiteralPath (Join-Path $OutputRoot "housing-wowdb-global-acquisition-crosscheck.csv") -NoTypeInformation -Encoding utf8

[pscustomobject]@{ set = "theme catalog"; rows = $catalogRows.Count }
[pscustomobject]@{ set = "Warlords acquisition manifest"; rows = $auditRows.Count }
[pscustomobject]@{ set = "theme exclusions"; rows = $excludedRows.Count }
[pscustomobject]@{ set = "global acquisition cross-check"; rows = $globalAuditRows.Count }
