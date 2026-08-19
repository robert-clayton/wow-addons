param(
    [string]$ThemeIndexJson = (Join-Path $env:TEMP "collectionist-classic-expansion-index.json"),
    [string]$GlobalCardJson = (Join-Path $env:TEMP "collectionist-all-decor-structured-sources.json"),
    [string]$CurrentDb2Root = (Join-Path $env:TEMP "collectionist-tww-db2\current"),
    [string]$OutputRoot = (Join-Path $PSScriptRoot "..\research\collectionist\classic\sources")
)

$ErrorActionPreference = "Stop"

function Assert-Equal($Actual, $Expected, [string]$Label) {
    if ([int]$Actual -ne [int]$Expected) { throw "$Label mismatch: expected $Expected, got $Actual" }
}
function Assert-IDValues($ActualValues, $ExpectedValues, [string]$Label) {
    $actual = @($ActualValues | ForEach-Object { [string]$_ } | Where-Object { $_ } | Sort-Object -Unique)
    $expected = @($ExpectedValues | ForEach-Object { [string]$_ } | Where-Object { $_ } | Sort-Object -Unique)
    $missing = @($expected | Where-Object { $_ -notin $actual })
    $extra = @($actual | Where-Object { $_ -notin $expected })
    if ($missing.Count -or $extra.Count) { throw "$Label mismatch: missing [$($missing -join ', ')], extra [$($extra -join ', ')]" }
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

foreach ($required in @($ThemeIndexJson, $GlobalCardJson, $CurrentDb2Root)) {
    if (-not (Test-Path -LiteralPath $required)) { throw "Missing input: $required" }
}
New-Item -ItemType Directory -Force -Path $OutputRoot | Out-Null

$themeIndex = @(Get-Content -Raw -LiteralPath $ThemeIndexJson | ConvertFrom-Json)
$globalCards = @(Get-Content -Raw -LiteralPath $GlobalCardJson | ConvertFrom-Json)
Assert-Equal $themeIndex.Count 53 "Classic housing theme row count"
Assert-Equal $globalCards.Count 2911 "Global housing catalog row count"

$decorByID = @{}
Import-Csv -LiteralPath (Join-Path $CurrentDb2Root "HouseDecor.csv") | ForEach-Object { $decorByID[[string]$_.ID] = $_ }
$globalByID = @{}
foreach ($card in $globalCards) { $globalByID[[string](Get-DecorID $card)] = $card }
$themeIDs = @{}
foreach ($card in $themeIndex) { $themeIDs[[string](Get-DecorID $card)] = $true }
Assert-Equal $themeIDs.Count 53 "Unique Classic housing theme IDs"
Assert-Equal $globalByID.Count 2911 "Unique global housing decor ID count"

# Housing was added in Midnight. Ownership follows the oldest content required
# by an acquisition, not the theme tag, item expansion field, creation build,
# or the location of a new housing vendor.
$confirmedIDs = @(
    # Classic profession recipes, including two outside the theme catalog.
    "854","922","1119","1282","2001","2227","2230","2237","2240","2331","2332","2452","2465",
    "9266","11376","11438","11755","11935","14816",
    # Classic achievement, quest, and encounter acquisitions.
    "2246","3893","11274"
)
$bfaIDs = @("1183","2238")
$cataIDs = @("923","924","1281","2226","2239","11433")
$legionIDs = @("1252")
$tbcIDs = @("3899")
$wrathIDs = @("1674","11722","11893")
$midnightIDs = @("725","3906","3907","9249","21857")
$vendorOnlyIDs = @("1998","2228","2229","2241","2242","2243","2333","2334","8982")
$internalIDs = @("129","518","2018","3888","17889","20170","27047")

$classificationByID = @{}
foreach ($id in $confirmedIDs) { $classificationByID[$id] = @{ status="acquisition_classic_confirmed"; expansion="classic"; note="Current acquisition requires original World of Warcraft content" } }
foreach ($id in $bfaIDs) { $classificationByID[$id] = @{ status="acquisition_bfa_confirmed"; expansion="battle_for_azeroth"; note="Current acquisition requires Battle for Azeroth content" } }
foreach ($id in $cataIDs) { $classificationByID[$id] = @{ status="acquisition_cata_confirmed"; expansion="cataclysm"; note="Current acquisition requires Cataclysm content" } }
foreach ($id in $legionIDs) { $classificationByID[$id] = @{ status="acquisition_legion_confirmed"; expansion="legion"; note="Current acquisition requires Legion content" } }
foreach ($id in $tbcIDs) { $classificationByID[$id] = @{ status="acquisition_tbc_confirmed"; expansion="the_burning_crusade"; note="Current acquisition requires Burning Crusade content" } }
foreach ($id in $wrathIDs) { $classificationByID[$id] = @{ status="acquisition_wrath_confirmed"; expansion="wrath"; note="Current acquisition requires Wrath of the Lich King content" } }
foreach ($id in $midnightIDs) { $classificationByID[$id] = @{ status="acquisition_midnight_confirmed"; expansion="midnight"; note="Current acquisition requires Midnight content" } }
foreach ($id in $vendorOnlyIDs) { $classificationByID[$id] = @{ status="vendor_location_only_unassigned"; expansion=""; note="New housing vendor stock in an older zone does not establish Classic ownership" } }
foreach ($id in $internalIDs) { $classificationByID[$id] = @{ status="internal_hidden"; expansion=""; note="Hidden, DNT, or source-less catalog row with no collectible acquisition" } }

Assert-IDValues $classificationByID.Keys @($themeIDs.Keys + @("1119","2465","11274")) "Classified Classic housing candidates"

function Convert-Card($Card, [bool]$IsThemeRow) {
    $id = [string](Get-DecorID $Card)
    $classification = $classificationByID[$id]
    if (-not $classification) { throw "Unclassified Classic housing candidate $id ($($Card.name))" }
    $decor = $decorByID[$id]
    if (-not $decor) { throw "Housing decor $id is absent from current retail DB2" }
    [pscustomobject]@{
        decor_id = $id
        item_id = $decor.ItemID
        catalog_name = $Card.name
        catalog_scope = if ($IsThemeRow) { "classic_theme" } else { "global_acquisition_match" }
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
Assert-Equal @($themeAudit | Where-Object status -eq "acquisition_classic_confirmed").Count 19 "Classic-owned themed decoration count"
Assert-Equal @($themeAudit | Where-Object status -ne "acquisition_classic_confirmed").Count 34 "Classic theme exclusion count"

$classicRecipeSpellIDs = @(
    "1261572","1261549","1261672","1261688","1261497","1261509","1261667","1261587","1261644","1261659",
    "1261499","1261695","1261504","1261501","1261495","1262829","1263633","1269495","1270459"
)
$classicAchievementIDs = @("1157")
$classicQuestIDs = @("7604")
$classicTextPattern = "Encounter: Emperor Dagran Thaurissan"

$globalAudit = foreach ($card in $globalCards) {
    $id = [string](Get-DecorID $card)
    $achievementIDs = @(Get-LinkedIDs $card "achievements" | Where-Object { [string]$_ -in $classicAchievementIDs })
    $questIDs = @(Get-LinkedIDs $card "quests" | Where-Object { [string]$_ -in $classicQuestIDs })
    $spellIDs = @(Get-LinkedIDs $card "spells" | Where-Object { [string]$_ -in $classicRecipeSpellIDs })
    $textSignal = [string]$card.text -match $classicTextPattern
    if (-not ($themeIDs.ContainsKey($id) -or $achievementIDs.Count -or $questIDs.Count -or $spellIDs.Count -or $textSignal)) { continue }
    $row = Convert-Card $card $themeIDs.ContainsKey($id)
    $row | Add-Member -NotePropertyName classic_achievement_ids -NotePropertyValue ($achievementIDs -join ";")
    $row | Add-Member -NotePropertyName classic_quest_ids -NotePropertyValue ($questIDs -join ";")
    $row | Add-Member -NotePropertyName classic_recipe_spell_ids -NotePropertyValue ($spellIDs -join ";")
    $row | Add-Member -NotePropertyName classic_text_signal -NotePropertyValue $textSignal
    $row
}

Assert-Equal $globalAudit.Count 56 "Global Classic acquisition signal count"
Assert-Equal @($globalAudit | Where-Object status -eq "acquisition_classic_confirmed").Count 22 "Globally confirmed Classic decoration count"
Assert-Equal @($globalAudit | Where-Object { $_.status -eq "acquisition_classic_confirmed" -and -not $themeIDs.ContainsKey([string]$_.decor_id) }).Count 3 "Non-themed Classic decoration count"

$confirmedRows = @($globalAudit | Where-Object status -eq "acquisition_classic_confirmed" | Sort-Object { [int]$_.decor_id })
$themeExclusions = @($themeAudit | Where-Object status -ne "acquisition_classic_confirmed" | Sort-Object { [int]$_.decor_id })
Write-CsvFile (Join-Path $OutputRoot "housing-wowdb-acquisition-audit.csv") $confirmedRows
Write-CsvFile (Join-Path $OutputRoot "housing-wowdb-theme-exclusions.csv") $themeExclusions
Write-CsvFile (Join-Path $OutputRoot "housing-wowdb-theme-catalog.csv") @($themeAudit | Sort-Object { [int]$_.decor_id })
Write-CsvFile (Join-Path $OutputRoot "housing-wowdb-global-acquisition-crosscheck.csv") @($globalAudit | Sort-Object { [int]$_.decor_id })

Write-Host "Generated Classic housing acquisition audit"
Write-Host "Confirmed: $($confirmedRows.Count); themed exclusions: $($themeExclusions.Count); global signals: $($globalAudit.Count)"
