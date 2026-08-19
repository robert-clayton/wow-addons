param(
    [string]$ThemeIndexJson = (Join-Path $env:TEMP "collectionist-cata-expansion-index.json"),
    [string]$GlobalCardJson = (Join-Path $env:TEMP "collectionist-all-decor-structured-sources.json"),
    [string]$CurrentDb2Root = (Join-Path $env:TEMP "collectionist-tww-db2\current"),
    [string]$CataclysmClassicRoot = (Join-Path $env:TEMP "collectionist-cata-classic-db2"),
    [string]$WrathClassicRoot = (Join-Path $env:TEMP "collectionist-wrath-classic-db2"),
    [string]$OutputRoot = (Join-Path $PSScriptRoot "..\research\collectionist\cataclysm\sources")
)

$ErrorActionPreference = "Stop"

function Assert-Equal($Actual, $Expected, [string]$Label) {
    if ([int]$Actual -ne [int]$Expected) { throw "$Label mismatch: expected $Expected, got $Actual" }
}
function Assert-IDValues($ActualValues, $ExpectedValues, [string]$Label) {
    $actual = @($ActualValues | ForEach-Object { [string]$_ } | Sort-Object -Unique)
    $expected = @($ExpectedValues | ForEach-Object { [string]$_ } | Sort-Object -Unique)
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

foreach ($required in @($ThemeIndexJson, $GlobalCardJson, $CurrentDb2Root, $CataclysmClassicRoot, $WrathClassicRoot)) {
    if (-not (Test-Path -LiteralPath $required)) { throw "Missing input: $required" }
}
New-Item -ItemType Directory -Force -Path $OutputRoot | Out-Null

$themeIndex = @(Get-Content -Raw -LiteralPath $ThemeIndexJson | ConvertFrom-Json)
$globalCards = @(Get-Content -Raw -LiteralPath $GlobalCardJson | ConvertFrom-Json)
Assert-Equal $themeIndex.Count 58 "Cataclysm theme catalog row count"
Assert-Equal $globalCards.Count 2911 "Global housing catalog row count"

$themeIDs = @{}
foreach ($row in $themeIndex) { $themeIDs[[string](Get-DecorID $row)] = $true }
$globalByID = @{}
foreach ($row in $globalCards) { $globalByID[[string](Get-DecorID $row)] = $row }
Assert-Equal $globalByID.Count 2911 "Unique global housing decor ID count"

$decorByID = @{}
Import-Csv -LiteralPath (Join-Path $CurrentDb2Root "HouseDecor.csv") | ForEach-Object { $decorByID[[string]$_.ID] = $_ }

# Housing arrived after Cataclysm. Ownership here is intentionally based on
# the current acquisition requirement, never on visual theme, record creation,
# item expansion fields, or a vendor's location by itself.
$confirmedIDs = @(
    # Cataclysm profession recipes.
    "855","11723","11725","11377","11724","1793","1832","16089","1831","1830",
    "11494","16013","11779","11718","11496","5342","11497","1827","11433","11492",
    # Cataclysm quest unlocks and rewards.
    "4814","2244","11301","1829","923","924","2245","2226","11131","1315",
    "11305","11498","4447","4819","1481","1281","2239","1833","4444","858",
    # Cataclysm achievements, reputation vendor, dungeon, and raid content.
    "3867","11296","1794","1796","1445","4401"
)
$classicIDs = @("11495")
$tbcIDs = @("16219","16220")
$legionIDs = @("1802","11493")
$bfaIDs = @("11489","11319","11484")
$dragonflightIDs = @("857","859","860","1795","1826","11944")
$midnightIDs = @("9248","26478","27044")
$internalIDs = @("856","1828","2019","15740","21081","21082","21083","21084")

$classificationByID = @{}
foreach ($id in $confirmedIDs) { $classificationByID[$id] = @{ status="acquisition_cataclysm_confirmed"; expansion="cataclysm"; note="Current acquisition requires Cataclysm content" } }
foreach ($id in $classicIDs) { $classificationByID[$id] = @{ status="acquisition_classic_confirmed"; expansion="classic"; note="Current acquisition uses a Classic vendor; Cataclysm theme does not assign ownership" } }
foreach ($id in $tbcIDs) { $classificationByID[$id] = @{ status="acquisition_tbc_confirmed"; expansion="tbc"; note="Current acquisition requires Outland Alchemy" } }
foreach ($id in $legionIDs) { $classificationByID[$id] = @{ status="acquisition_legion_confirmed"; expansion="legion"; note="Current acquisition requires Legion content" } }
foreach ($id in $bfaIDs) { $classificationByID[$id] = @{ status="acquisition_bfa_confirmed"; expansion="bfa"; note="Current acquisition requires Battle for Azeroth content" } }
foreach ($id in $dragonflightIDs) { $classificationByID[$id] = @{ status="acquisition_dragonflight_confirmed"; expansion="dragonflight"; note="Current acquisition requires Reclamation of Gilneas content added in Dragonflight" } }
foreach ($id in $midnightIDs) { $classificationByID[$id] = @{ status="acquisition_midnight_confirmed"; expansion="midnight"; note="Current acquisition requires Midnight content" } }
foreach ($id in $internalIDs) { $classificationByID[$id] = @{ status="internal_dnt"; expansion=""; note="Internal DNT, duplicate, or do-not-use catalog row" } }

Assert-IDValues $classificationByID.Keys @($themeIDs.Keys + $confirmedIDs) "Classified Cataclysm housing candidates"

function Convert-Card($Card, [bool]$IsThemeRow) {
    $id = [string](Get-DecorID $Card)
    $classification = $classificationByID[$id]
    if (-not $classification) { throw "Unclassified Cataclysm housing candidate $id ($($Card.name))" }
    $decor = $decorByID[$id]
    if (-not $decor) { throw "Housing decor $id is absent from current retail DB2" }
    [pscustomobject]@{
        decor_id = $id
        item_id = $decor.ItemID
        catalog_name = $Card.name
        catalog_scope = if ($IsThemeRow) { "cataclysm_theme" } else { "global_acquisition_match" }
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
Assert-Equal @($themeAudit | Where-Object status -eq "acquisition_cataclysm_confirmed").Count 33 "Cataclysm-owned themed decoration count"
Assert-Equal @($themeAudit | Where-Object status -ne "acquisition_cataclysm_confirmed").Count 25 "Cataclysm theme exclusion count"

$cataclysmQuestIDs = @{}
$wrathQuestIDs = @{}
Import-Csv -LiteralPath (Join-Path $CataclysmClassicRoot "QuestV2.csv") | ForEach-Object { $cataclysmQuestIDs[[string]$_.ID] = $true }
Import-Csv -LiteralPath (Join-Path $WrathClassicRoot "QuestV2.csv") | ForEach-Object { $wrathQuestIDs[[string]$_.ID] = $true }
$cataclysmAddedQuestIDs = @{}
foreach ($id in $cataclysmQuestIDs.Keys) {
    if (-not $wrathQuestIDs.ContainsKey($id)) { $cataclysmAddedQuestIDs[$id] = $true }
}
Assert-Equal $cataclysmAddedQuestIDs.Count 5522 "Cataclysm-added quest ID count"

$cataclysmRecipeSpellIDs = @(
    "1261255","1269506","1261256","1262308","1262318","1262331","1261258","1262340","1261259","1261278",
    "1261288","1269534","1269540","1261305","1262357","1269550","1272580","1272588","1261317","1262370"
)
$cataclysmAchievementIDs = @("5223","5245")
$cataclysmVendorNPCIDs = @("50307")
$cataclysmDropPattern = "Encounter: Lord Godfrey|Drop: Deadmines|Encounter: Vanessa VanCleef"

$globalAudit = foreach ($card in $globalCards) {
    $id = [string](Get-DecorID $card)
    $questIDs = @(Get-LinkedIDs $card "quests" | Where-Object { $cataclysmAddedQuestIDs.ContainsKey([string]$_) })
    $achievementIDs = @(Get-LinkedIDs $card "achievements" | Where-Object { [string]$_ -in $cataclysmAchievementIDs })
    $npcIDs = @(Get-LinkedIDs $card "npcs" | Where-Object { [string]$_ -in $cataclysmVendorNPCIDs })
    $spellIDs = @(Get-LinkedIDs $card "spells" | Where-Object { [string]$_ -in $cataclysmRecipeSpellIDs })
    $dropSignal = [string]$card.text -match $cataclysmDropPattern
    if (-not ($themeIDs.ContainsKey($id) -or $questIDs.Count -or $achievementIDs.Count -or $npcIDs.Count -or $spellIDs.Count -or $dropSignal)) { continue }
    $row = Convert-Card $card $themeIDs.ContainsKey($id)
    $row | Add-Member -NotePropertyName cataclysm_quest_ids -NotePropertyValue ($questIDs -join ";")
    $row | Add-Member -NotePropertyName cataclysm_achievement_ids -NotePropertyValue ($achievementIDs -join ";")
    $row | Add-Member -NotePropertyName cataclysm_npc_ids -NotePropertyValue ($npcIDs -join ";")
    $row | Add-Member -NotePropertyName cataclysm_recipe_spell_ids -NotePropertyValue ($spellIDs -join ";")
    $row | Add-Member -NotePropertyName cataclysm_drop_signal -NotePropertyValue $dropSignal
    $row
}

Assert-Equal $globalAudit.Count 71 "Global Cataclysm acquisition signal count"
Assert-Equal @($globalAudit | Where-Object status -eq "acquisition_cataclysm_confirmed").Count 46 "Globally confirmed Cataclysm decoration count"
Assert-Equal @($globalAudit | Where-Object { $_.status -eq "acquisition_cataclysm_confirmed" -and -not $themeIDs.ContainsKey([string]$_.decor_id) }).Count 13 "Non-themed Cataclysm decoration count"

$confirmedRows = @($globalAudit | Where-Object status -eq "acquisition_cataclysm_confirmed" | Sort-Object { [int]$_.decor_id })
$themeExclusions = @($themeAudit | Where-Object status -ne "acquisition_cataclysm_confirmed" | Sort-Object { [int]$_.decor_id })
Write-CsvFile (Join-Path $OutputRoot "housing-wowdb-acquisition-audit.csv") $confirmedRows
Write-CsvFile (Join-Path $OutputRoot "housing-wowdb-theme-exclusions.csv") $themeExclusions
Write-CsvFile (Join-Path $OutputRoot "housing-wowdb-theme-catalog.csv") @($themeAudit | Sort-Object { [int]$_.decor_id })
Write-CsvFile (Join-Path $OutputRoot "housing-wowdb-global-acquisition-crosscheck.csv") @($globalAudit | Sort-Object { [int]$_.decor_id })

Write-Host "Generated Cataclysm housing acquisition audit"
Write-Host "Confirmed: $($confirmedRows.Count); themed exclusions: $($themeExclusions.Count); global signals: $($globalAudit.Count)"
