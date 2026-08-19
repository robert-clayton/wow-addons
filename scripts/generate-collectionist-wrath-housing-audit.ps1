param(
    [string]$ThemeIndexJson = (Join-Path $env:TEMP "collectionist-wrath-expansion-index.json"),
    [string]$GlobalCardJson = (Join-Path $env:TEMP "collectionist-all-decor-structured-sources.json"),
    [string]$CurrentDb2Root = (Join-Path $env:TEMP "collectionist-tww-db2\current"),
    [string]$OutputRoot = (Join-Path $PSScriptRoot "..\research\collectionist\wrath-of-the-lich-king\sources")
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
    if (@(Get-LinkedIDs $Row "quests").Count -or [string]$Row.text -match "Cheese for Glowergold") { return "quest" }
    if ([string]$Row.text -match "Treasure:|Encounter:|Drop:") { return "drop" }
    return "vendor"
}

foreach ($required in @($ThemeIndexJson, $GlobalCardJson, $CurrentDb2Root)) {
    if (-not (Test-Path -LiteralPath $required)) { throw "Missing input: $required" }
}
New-Item -ItemType Directory -Force -Path $OutputRoot | Out-Null

$themeIndex = @(Get-Content -Raw -LiteralPath $ThemeIndexJson | ConvertFrom-Json)
$globalCards = @(Get-Content -Raw -LiteralPath $GlobalCardJson | ConvertFrom-Json)
Assert-Equal $themeIndex.Count 22 "Wrath theme catalog row count"
Assert-Equal $globalCards.Count 2911 "Global housing catalog row count"

$themeIDs = @{}
foreach ($row in $themeIndex) { $themeIDs[[string](Get-DecorID $row)] = $true }
$globalByID = @{}
foreach ($row in $globalCards) { $globalByID[[string](Get-DecorID $row)] = $row }
Assert-Equal $globalByID.Count 2911 "Unique global housing decor ID count"

$decorByID = @{}
Import-Csv -LiteralPath (Join-Path $CurrentDb2Root "HouseDecor.csv") | ForEach-Object { $decorByID[[string]$_.ID] = $_ }

# Housing was added after Wrath. Ownership is based on the content required by
# the current acquisition, not theme, record creation, item expansion metadata,
# or the physical location of a later vendor.
$confirmedIDs = @(
    # Northrend profession recipes.
    "11375","11432","11439","11722","11891","11892","11893","11894","11895","11896","11897",
    "11898","11899","11900","11901","11941","16012","16084","16085","16087","16088",
    # Wrath quests, achievement, daily, and encounter.
    "1674","4448","4839","11872","11906","18483"
)
$midnightIDs = @("9475","25336")
$internalIDs = @("25104")

$classificationByID = @{}
foreach ($id in $confirmedIDs) { $classificationByID[$id] = @{ status="acquisition_wrath_confirmed"; expansion="wrath"; note="Current acquisition requires Wrath of the Lich King content" } }
foreach ($id in $midnightIDs) { $classificationByID[$id] = @{ status="acquisition_midnight_confirmed"; expansion="midnight"; note="Current acquisition requires Midnight content" } }
foreach ($id in $internalIDs) { $classificationByID[$id] = @{ status="internal_hidden"; expansion=""; note="Hidden catalog row with no collectible acquisition source" } }

Assert-IDValues $classificationByID.Keys @($themeIDs.Keys + @("1674","4448","4839","11722","11872","11893","11899","11906")) "Classified Wrath housing candidates"

function Convert-Card($Card, [bool]$IsThemeRow) {
    $id = [string](Get-DecorID $Card)
    $classification = $classificationByID[$id]
    if (-not $classification) { throw "Unclassified Wrath housing candidate $id ($($Card.name))" }
    $decor = $decorByID[$id]
    if (-not $decor) { throw "Housing decor $id is absent from current retail DB2" }
    [pscustomobject]@{
        decor_id = $id
        item_id = $decor.ItemID
        catalog_name = $Card.name
        catalog_scope = if ($IsThemeRow) { "wrath_theme" } else { "global_acquisition_match" }
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
Assert-Equal @($themeAudit | Where-Object status -eq "acquisition_wrath_confirmed").Count 19 "Wrath-owned themed decoration count"
Assert-Equal @($themeAudit | Where-Object status -ne "acquisition_wrath_confirmed").Count 3 "Wrath theme exclusion count"

$wrathRecipeSpellIDs = @(
    "1261327","1262824","1262825","1269499","1263562","1263575","1263613","1263620","1263570","1263605","1263574",
    "1263564","1263577","1263558","1263559","1263627","1272662","1272707","1272688","1272614","1272676"
)
$wrathQuestIDs = @("11566","12227")
$wrathAchievementIDs = @("938","4405")
$wrathTextPattern = "Encounter: Scourgelord Tyrannus|Cheese for Glowergold"

$globalAudit = foreach ($card in $globalCards) {
    $id = [string](Get-DecorID $card)
    $questIDs = @(Get-LinkedIDs $card "quests" | Where-Object { [string]$_ -in $wrathQuestIDs })
    $achievementIDs = @(Get-LinkedIDs $card "achievements" | Where-Object { [string]$_ -in $wrathAchievementIDs })
    $spellIDs = @(Get-LinkedIDs $card "spells" | Where-Object { [string]$_ -in $wrathRecipeSpellIDs })
    $textSignal = [string]$card.text -match $wrathTextPattern
    if (-not ($themeIDs.ContainsKey($id) -or $questIDs.Count -or $achievementIDs.Count -or $spellIDs.Count -or $textSignal)) { continue }
    $row = Convert-Card $card $themeIDs.ContainsKey($id)
    $row | Add-Member -NotePropertyName wrath_quest_ids -NotePropertyValue ($questIDs -join ";")
    $row | Add-Member -NotePropertyName wrath_achievement_ids -NotePropertyValue ($achievementIDs -join ";")
    $row | Add-Member -NotePropertyName wrath_recipe_spell_ids -NotePropertyValue ($spellIDs -join ";")
    $row | Add-Member -NotePropertyName wrath_text_signal -NotePropertyValue $textSignal
    $row
}

Assert-Equal $globalAudit.Count 30 "Global Wrath acquisition signal count"
Assert-Equal @($globalAudit | Where-Object status -eq "acquisition_wrath_confirmed").Count 27 "Globally confirmed Wrath decoration count"
Assert-Equal @($globalAudit | Where-Object { $_.status -eq "acquisition_wrath_confirmed" -and -not $themeIDs.ContainsKey([string]$_.decor_id) }).Count 8 "Non-themed Wrath decoration count"

$confirmedRows = @($globalAudit | Where-Object status -eq "acquisition_wrath_confirmed" | Sort-Object { [int]$_.decor_id })
$themeExclusions = @($themeAudit | Where-Object status -ne "acquisition_wrath_confirmed" | Sort-Object { [int]$_.decor_id })
Write-CsvFile (Join-Path $OutputRoot "housing-wowdb-acquisition-audit.csv") $confirmedRows
Write-CsvFile (Join-Path $OutputRoot "housing-wowdb-theme-exclusions.csv") $themeExclusions
Write-CsvFile (Join-Path $OutputRoot "housing-wowdb-theme-catalog.csv") @($themeAudit | Sort-Object { [int]$_.decor_id })
Write-CsvFile (Join-Path $OutputRoot "housing-wowdb-global-acquisition-crosscheck.csv") @($globalAudit | Sort-Object { [int]$_.decor_id })

Write-Host "Generated Wrath housing acquisition audit"
Write-Host "Confirmed: $($confirmedRows.Count); themed exclusions: $($themeExclusions.Count); global signals: $($globalAudit.Count)"
