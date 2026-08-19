param(
    [string]$ThemeIndexJson = (Join-Path $env:TEMP "collectionist-mop-expansion-index.json"),
    [string]$GlobalCardJson = (Join-Path $env:TEMP "collectionist-all-decor-structured-sources.json"),
    [string]$CurrentDb2Root = (Join-Path $env:TEMP "collectionist-tww-db2\current"),
    [string]$AttRoot = (Join-Path $env:TEMP "collectionist-att-12007"),
    [string]$OutputRoot = (Join-Path $PSScriptRoot "..\research\collectionist\mists-of-pandaria\sources")
)

$ErrorActionPreference = "Stop"

function Assert-Equal($Actual, $Expected, [string]$Label) {
    if ([int]$Actual -ne [int]$Expected) { throw "$Label mismatch: expected $Expected, got $Actual" }
}
function Write-CsvFile([string]$Path, $Rows) {
    $lines = @($Rows) | ConvertTo-Csv -NoTypeInformation
    $text = if ($lines.Count) { ($lines -join "`n") + "`n" } else { "" }
    [System.IO.File]::WriteAllText($Path, $text.Replace("`r`n", "`n").Replace("`r", "`n"), [System.Text.UTF8Encoding]::new($false))
}
function Get-DecorID($Row) {
    if ([string]$Row.href -notmatch "/decor/(\d+)/") { throw "Could not parse decor ID from '$($Row.href)'" }
    return $Matches[1]
}
function Get-LinkedIDs($Row, [string]$Kind) {
    return @($Row.sourceLinks | ForEach-Object {
        if ([string]$_.href -match "wowdb\.com/$Kind/(\d+)") { $Matches[1] }
    } | Sort-Object -Unique)
}
function Get-NormalizedText([string]$Value) { return (($Value -replace "\s+", " ").Trim()) }
function Get-SourceKind($Row) {
    if (@(Get-LinkedIDs $Row "spells").Count) { return "crafted" }
    if (@(Get-LinkedIDs $Row "achievements").Count) { return "achievement" }
    if (@(Get-LinkedIDs $Row "quests").Count) { return "quest" }
    if ([string]$Row.text -match "Treasure:|Encounter:|Drop:") { return "drop" }
    return "vendor"
}

foreach ($required in @($ThemeIndexJson, $GlobalCardJson, $CurrentDb2Root, $AttRoot)) {
    if (-not (Test-Path -LiteralPath $required)) { throw "Missing input: $required" }
}
New-Item -ItemType Directory -Force -Path $OutputRoot | Out-Null

$themeIndex = @(Get-Content -Raw -LiteralPath $ThemeIndexJson | ConvertFrom-Json)
$globalCards = @(Get-Content -Raw -LiteralPath $GlobalCardJson | ConvertFrom-Json)
Assert-Equal $themeIndex.Count 64 "Pandaria theme catalog row count"
Assert-Equal $globalCards.Count 2911 "Global housing catalog row count"

$themeIDs = @{}
foreach ($row in $themeIndex) { $themeIDs[[string](Get-DecorID $row)] = $true }
$globalByID = @{}
foreach ($row in $globalCards) { $globalByID[[string](Get-DecorID $row)] = $row }
Assert-Equal $globalByID.Count 2911 "Unique global housing decor ID count"

$decorByID = @{}
Import-Csv -LiteralPath (Join-Path $CurrentDb2Root "HouseDecor.csv") | ForEach-Object { $decorByID[[string]$_.ID] = $_ }

$confirmedIDs = @(
    "1169","1172","1187","1194","1201","2512","2591","3831","3832","3833","3839","3840","3868","3869","3870","3871",
    "3872","3873","3874","3875","3876","3877","3878","3880","3881","3892","3904","3993","3994","3995","4488",
    "5111","11378","11434","11435","11873","11902","11904","11945","15595","15605"
)
$hiddenIDs = @("3834","3882","4048","5114")
$internalIDs = @("3879","3883","16091")
$legionIDs = @("5112","5113","5119","5126")
$twwIDs = @("767","11453","11456","11457","12263","14815")
$midnightIDs = @("2453","2495","4424","4425","8179","8987","8988","9250","16962","21857","26196","26651")

$classificationByID = @{}
foreach ($id in $confirmedIDs) { $classificationByID[$id] = @{ status="acquisition_mop_confirmed"; expansion="mop"; note="Current acquisition requires Mists of Pandaria content" } }
foreach ($id in $hiddenIDs) { $classificationByID[$id] = @{ status="catalog_hidden_unobtainable"; expansion=""; note="Hidden catalog row with no current acquisition source" } }
foreach ($id in $internalIDs) { $classificationByID[$id] = @{ status="internal_dnt"; expansion=""; note="Internal DNT or duplicate row" } }
foreach ($id in $legionIDs) { $classificationByID[$id] = @{ status="acquisition_legion_confirmed"; expansion="legion"; note="Legion class-hall acquisition; Pandaria theme does not assign ownership" } }
foreach ($id in $twwIDs) { $classificationByID[$id] = @{ status="acquisition_tww_confirmed"; expansion="tww"; note="The War Within acquisition; Pandaria location or theme alone does not assign ownership" } }
foreach ($id in $midnightIDs) { $classificationByID[$id] = @{ status="acquisition_midnight_confirmed"; expansion="midnight"; note="Midnight acquisition; Pandaria theme or vendor location alone does not assign ownership" } }

function Convert-Card($Card, [bool]$IsThemeRow) {
    $id = [string](Get-DecorID $Card)
    $classification = $classificationByID[$id]
    if (-not $classification) { throw "Unclassified Pandaria housing candidate $id ($($Card.name))" }
    $decor = $decorByID[$id]
    if (-not $decor) { throw "Housing decor $id is absent from current retail DB2" }
    [pscustomobject]@{
        decor_id = $id
        item_id = $decor.ItemID
        catalog_name = $Card.name
        catalog_scope = if ($IsThemeRow) { "mop_theme" } else { "global_acquisition_match" }
        status = $classification.status
        acquisition_expansion = $classification.expansion
        source_kind = Get-SourceKind $Card
        source_text = Get-NormalizedText $Card.text
        achievement_ids = (@(Get-LinkedIDs $Card "achievements") -join ";")
        quest_ids = (@(Get-LinkedIDs $Card "quests") -join ";")
        npc_ids = (@(Get-LinkedIDs $Card "npcs") -join ";")
        source_spell_ids = (@(Get-LinkedIDs $Card "spells") -join ";")
        currency_ids = (@(Get-LinkedIDs $Card "currencies") -join ";")
        source_item_ids = (@(Get-LinkedIDs $Card "items") -join ";")
        classification_note = $classification.note
        acquisition_source_url = "https://housing.wowdb.com$($Card.href)"
    }
}

$themeAudit = foreach ($id in $themeIDs.Keys) { Convert-Card $globalByID[$id] $true }
Assert-Equal @($themeAudit | Where-Object status -eq "acquisition_mop_confirmed").Count 40 "Pandaria-owned themed decoration count"
Assert-Equal @($themeAudit | Where-Object status -ne "acquisition_mop_confirmed").Count 24 "Pandaria theme exclusion count"

$attRoots = @(
    (Join-Path $AttRoot ".contrib\Parser\DATAS\01 - Dungeons Raids\05 - Mists of Pandaria"),
    (Join-Path $AttRoot ".contrib\Parser\DATAS\02 - Outdoor Zones\06 Pandaria"),
    (Join-Path $AttRoot ".contrib\Parser\DATAS\06 - Expansion Features\05 - Mists of Pandaria")
)
$attFiles = @()
foreach ($root in $attRoots) {
    if (-not (Test-Path -LiteralPath $root)) { throw "Missing Pandaria ATT source root: $root" }
    $attFiles += @(Get-ChildItem -LiteralPath $root -Recurse -File -Filter "*.lua")
}
foreach ($path in @(
    (Join-Path $AttRoot ".contrib\Parser\DATAS\03 - World Drops\05 - Mists of Pandaria.lua"),
    (Join-Path $AttRoot ".contrib\Parser\DATAS\08 - PvP\05 Mists of Pandaria PvP Seasons.lua"),
    (Join-Path $AttRoot ".contrib\Parser\DATAS\09 - Crafted Items\05 - Mists of Pandaria.lua")
)) { $attFiles += @(Get-Item -LiteralPath $path) }

$mopQuestIDs = [System.Collections.Generic.HashSet[int]]::new()
$mopNpcIDs = [System.Collections.Generic.HashSet[int]]::new()
foreach ($file in $attFiles) {
    $text = Get-Content -Raw -LiteralPath $file.FullName
    foreach ($match in [regex]::Matches($text, '(?m)(?:^|[^A-Za-z])q\((\d+)|questID\s*=\s*(\d+)')) {
        $id = if ($match.Groups[1].Success) { $match.Groups[1].Value } else { $match.Groups[2].Value }
        [void]$mopQuestIDs.Add([int]$id)
    }
    foreach ($pattern in @('(?:cr|n)\((\d+)', '(?:npcID|creatureID)\s*=\s*(\d+)', '["'']n["'']\s*,\s*(\d+)')) {
        foreach ($match in [regex]::Matches($text, $pattern)) { [void]$mopNpcIDs.Add([int]$match.Groups[1].Value) }
    }
    foreach ($match in [regex]::Matches($text, '(?:crs|qgs)\s*=\s*\{([^}]*)\}')) {
        foreach ($number in [regex]::Matches($match.Groups[1].Value, '\d+')) { [void]$mopNpcIDs.Add([int]$number.Value) }
    }
}

$mopCurrencyIDs = @("402","676","677","697","738","752","754","776","777","789")
$mopRecipeSpellIDs = @("1261233","1261234","1261235","1261236","1261237","1261238","1261239","1261240","1261241","1261242","1261243","1261244","1261245","1261248","1261250","1262302","1262306","1263548","1263551","1263553","1266563")
$mopTextSignal = "Pandaria|Pandaren|Mogu|Mantid|Klaxxi|Shado-Pan|Cloud Serpent|Golden Lotus|Tillers|Lorewalkers|August Celestials|Timeless Isle|Timeless Coin|Ironpaw|Jade Forest|Valley of the Four Winds|Kun-Lai|Townlong|Vale of Eternal Blossoms|Krasarang|Dread Wastes|Veiled Stair|Isle of Thunder|Isle of Giants|Temple of the Jade Serpent|Temple of Kotmogu|Shaohao|Stormstout|Halfhill|Grummle|Order of the Cloud Serpent"

$globalAudit = foreach ($card in $globalCards) {
    $id = [string](Get-DecorID $card)
    $questIDs = @(Get-LinkedIDs $card "quests" | Where-Object { $mopQuestIDs.Contains([int]$_) })
    $npcIDs = @(Get-LinkedIDs $card "npcs" | Where-Object { $mopNpcIDs.Contains([int]$_) })
    $currencyIDs = @(Get-LinkedIDs $card "currencies" | Where-Object { [string]$_ -in $mopCurrencyIDs })
    $spellIDs = @(Get-LinkedIDs $card "spells" | Where-Object { [string]$_ -in $mopRecipeSpellIDs })
    $textSignal = [string]$card.text -match $mopTextSignal
    if (-not ($themeIDs.ContainsKey($id) -or $questIDs.Count -or $npcIDs.Count -or $currencyIDs.Count -or $spellIDs.Count -or $textSignal)) { continue }
    $row = Convert-Card $card $themeIDs.ContainsKey($id)
    $row | Add-Member -NotePropertyName text_signal -NotePropertyValue $textSignal
    $row | Add-Member -NotePropertyName mop_quest_ids -NotePropertyValue ($questIDs -join ";")
    $row | Add-Member -NotePropertyName mop_npc_ids -NotePropertyValue ($npcIDs -join ";")
    $row | Add-Member -NotePropertyName mop_currency_ids -NotePropertyValue ($currencyIDs -join ";")
    $row | Add-Member -NotePropertyName mop_recipe_spell_ids -NotePropertyValue ($spellIDs -join ";")
    $row
}

Assert-Equal $globalAudit.Count 70 "Global Pandaria acquisition signal count"
Assert-Equal @($globalAudit | Where-Object status -eq "acquisition_mop_confirmed").Count 41 "Globally confirmed Pandaria decoration count"
Assert-Equal @($globalAudit | Where-Object { $_.status -eq "acquisition_mop_confirmed" -and -not $themeIDs.ContainsKey([string]$_.decor_id) }).Count 1 "Non-themed Pandaria decoration count"

$confirmedRows = @($globalAudit | Where-Object status -eq "acquisition_mop_confirmed" | Sort-Object { [int]$_.decor_id })
$themeExclusions = @($themeAudit | Where-Object status -ne "acquisition_mop_confirmed" | Sort-Object { [int]$_.decor_id })
Write-CsvFile (Join-Path $OutputRoot "housing-wowdb-acquisition-audit.csv") $confirmedRows
Write-CsvFile (Join-Path $OutputRoot "housing-wowdb-theme-exclusions.csv") $themeExclusions
Write-CsvFile (Join-Path $OutputRoot "housing-wowdb-theme-catalog.csv") @($themeAudit | Sort-Object { [int]$_.decor_id })
Write-CsvFile (Join-Path $OutputRoot "housing-wowdb-global-acquisition-crosscheck.csv") @($globalAudit | Sort-Object { [int]$_.decor_id })

Write-Host "Generated Mists of Pandaria housing acquisition audit"
Write-Host "Confirmed: $($confirmedRows.Count); themed exclusions: $($themeExclusions.Count); global signals: $($globalAudit.Count)"
