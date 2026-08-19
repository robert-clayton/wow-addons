param(
    [string]$ThemeIndexJson = (Join-Path $env:TEMP "collectionist-tbc-expansion-index.json"),
    [string]$GlobalCardJson = (Join-Path $env:TEMP "collectionist-all-decor-structured-sources.json"),
    [string]$CurrentDb2Root = (Join-Path $env:TEMP "collectionist-tww-db2\current"),
    [string]$OutputRoot = (Join-Path $PSScriptRoot "..\research\collectionist\the-burning-crusade\sources")
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
Assert-Equal $themeIndex.Count 51 "TBC housing theme row count"

$decorRows = @(Import-Csv -LiteralPath (Join-Path $CurrentDb2Root "HouseDecor.csv"))
$decorByID = @{}
foreach ($decor in $decorRows) { $decorByID[[string]$decor.ID] = $decor }
$globalByID = @{}
foreach ($card in $globalCards) { $globalByID[[string](Get-DecorID $card)] = $card }
$themeIDs = @{}
foreach ($card in $themeIndex) { $themeIDs[[string](Get-DecorID $card)] = $true }
Assert-Equal $themeIDs.Count 51 "Unique TBC housing theme IDs"

$confirmedIDs = @(
    # Outland profession recipes in the themed catalog.
    "11370","11371","11372","11373","11374","11431","11878","11879","11880","11881","11882","11883",
    "11884","11885","11886","11887","11888","11889","11890","11903","14553","16082","16083","16086",
    # Outland profession recipes outside the themed catalog.
    "16219","16220",
    # Eye of the Storm achievements and the Nalorakk encounter.
    "3898","3899","15570"
)
$midnightIDs = @("3913","4157","14467","14829","14830","14831","14832","14833","14834","26477")
$wrathIDs = @("11899")
$internalIDs = @("2505","3908","3909","3910","3911","3912","3914","3915","3916","3917","3918","3919","3920","3921","16754","18482")

$classificationByID = @{}
foreach ($id in $confirmedIDs) { $classificationByID[$id] = @{ status="acquisition_tbc_confirmed"; expansion="the_burning_crusade"; note="Current acquisition requires Burning Crusade content" } }
foreach ($id in $midnightIDs) { $classificationByID[$id] = @{ status="acquisition_midnight_confirmed"; expansion="midnight"; note="Current acquisition requires Midnight content" } }
foreach ($id in $wrathIDs) { $classificationByID[$id] = @{ status="acquisition_wrath_confirmed"; expansion="wrath"; note="Current acquisition requires Wrath of the Lich King content" } }
foreach ($id in $internalIDs) { $classificationByID[$id] = @{ status="internal_hidden"; expansion=""; note="Hidden or DNT catalog row with no collectible acquisition source" } }

Assert-IDValues $classificationByID.Keys @($themeIDs.Keys + @("3898","3899","15570","16219","16220")) "Classified TBC housing candidates"

function Convert-Card($Card, [bool]$IsThemeRow) {
    $id = [string](Get-DecorID $Card)
    $classification = $classificationByID[$id]
    if (-not $classification) { throw "Unclassified TBC housing candidate $id ($($Card.name))" }
    $decor = $decorByID[$id]
    if (-not $decor) { throw "Housing decor $id is absent from current retail DB2" }
    [pscustomobject]@{
        decor_id = $id
        item_id = $decor.ItemID
        catalog_name = $Card.name
        catalog_scope = if ($IsThemeRow) { "tbc_theme" } else { "global_acquisition_match" }
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
Assert-Equal @($themeAudit | Where-Object status -eq "acquisition_tbc_confirmed").Count 24 "TBC-owned themed decoration count"
Assert-Equal @($themeAudit | Where-Object status -ne "acquisition_tbc_confirmed").Count 27 "TBC theme exclusion count"

$tbcRecipeSpellIDs = @(
    "1261347","1261383","1261331","1261340","1261359","1262828","1263819","1263818","1263814","1263654",
    "1263643","1263692","1263663","1263813","1263811","1263810","1263817","1263815","1263669","1263812",
    "1269496","1272712","1272723","1272715","1273064","1273070"
)
$tbcAchievementIDs = @("212","213")
$tbcTextPattern = "Encounter: Nalorakk"

$globalAudit = foreach ($card in $globalCards) {
    $id = [string](Get-DecorID $card)
    $achievementIDs = @(Get-LinkedIDs $card "achievements" | Where-Object { [string]$_ -in $tbcAchievementIDs })
    $spellIDs = @(Get-LinkedIDs $card "spells" | Where-Object { [string]$_ -in $tbcRecipeSpellIDs })
    $textSignal = [string]$card.text -match $tbcTextPattern
    if (-not ($themeIDs.ContainsKey($id) -or $achievementIDs.Count -or $spellIDs.Count -or $textSignal)) { continue }
    $row = Convert-Card $card $themeIDs.ContainsKey($id)
    $row | Add-Member -NotePropertyName tbc_achievement_ids -NotePropertyValue ($achievementIDs -join ";")
    $row | Add-Member -NotePropertyName tbc_recipe_spell_ids -NotePropertyValue ($spellIDs -join ";")
    $row | Add-Member -NotePropertyName tbc_text_signal -NotePropertyValue $textSignal
    $row
}

Assert-Equal $globalAudit.Count 56 "Global TBC acquisition signal count"
Assert-Equal @($globalAudit | Where-Object status -eq "acquisition_tbc_confirmed").Count 29 "Globally confirmed TBC decoration count"
Assert-Equal @($globalAudit | Where-Object { $_.status -eq "acquisition_tbc_confirmed" -and -not $themeIDs.ContainsKey([string]$_.decor_id) }).Count 5 "Non-themed TBC decoration count"

$confirmedRows = @($globalAudit | Where-Object status -eq "acquisition_tbc_confirmed" | Sort-Object { [int]$_.decor_id })
$themeExclusions = @($themeAudit | Where-Object status -ne "acquisition_tbc_confirmed" | Sort-Object { [int]$_.decor_id })
Write-CsvFile (Join-Path $OutputRoot "housing-wowdb-acquisition-audit.csv") $confirmedRows
Write-CsvFile (Join-Path $OutputRoot "housing-wowdb-theme-exclusions.csv") $themeExclusions
Write-CsvFile (Join-Path $OutputRoot "housing-wowdb-theme-catalog.csv") @($themeAudit | Sort-Object { [int]$_.decor_id })
Write-CsvFile (Join-Path $OutputRoot "housing-wowdb-global-acquisition-crosscheck.csv") @($globalAudit | Sort-Object { [int]$_.decor_id })

Write-Host "Generated TBC housing acquisition audit"
Write-Host "Confirmed: $($confirmedRows.Count); themed exclusions: $($themeExclusions.Count); global signals: $($globalAudit.Count)"
