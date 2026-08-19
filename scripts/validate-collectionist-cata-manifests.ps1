param(
    [string]$ResearchRoot = (Join-Path $PSScriptRoot "..\research\collectionist\cataclysm"),
    [string]$WodManifestRoot = (Join-Path $PSScriptRoot "..\research\collectionist\warlords-of-draenor\manifests"),
    [string]$LegionManifestRoot = (Join-Path $PSScriptRoot "..\research\collectionist\legion\manifests"),
    [string]$BfaManifestRoot = (Join-Path $PSScriptRoot "..\research\collectionist\battle-for-azeroth\manifests"),
    [string]$ShadowlandsManifestRoot = (Join-Path $PSScriptRoot "..\research\collectionist\shadowlands\manifests"),
    [string]$DragonflightManifestRoot = (Join-Path $PSScriptRoot "..\research\collectionist\dragonflight\manifests"),
    [string]$TwwManifestRoot = (Join-Path $PSScriptRoot "..\research\collectionist\tww\manifests")
)

$ErrorActionPreference = "Stop"
$idRoot = Join-Path $ResearchRoot "ids"
$manifestRoot = Join-Path $ResearchRoot "manifests"
$sourceRoot = Join-Path $ResearchRoot "sources"

function Read-Rows([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) { throw "Missing CSV: $Path" }
    return @(Import-Csv -LiteralPath $Path)
}
function Get-IDs($Rows, [string]$Field) {
    return @($Rows | ForEach-Object { [string]$_.$Field } | Where-Object { $_ } | Sort-Object -Unique)
}
function Assert-ExactSet($ActualRows, $ExpectedRows, [string]$Field, [string]$Label, [int]$ExpectedCount) {
    $actual = @($ActualRows | ForEach-Object { [string]$_.$Field } | Where-Object { $_ })
    $expected = @($ExpectedRows | ForEach-Object { [string]$_.$Field } | Where-Object { $_ })
    if ($actual.Count -ne $ExpectedCount) { throw "$Label count mismatch: expected $ExpectedCount, got $($actual.Count)" }
    if (@($actual | Sort-Object -Unique).Count -ne $actual.Count) { throw "$Label contains duplicate or missing $Field values" }
    $missing = @($expected | Where-Object { $_ -notin $actual } | Sort-Object -Unique)
    $extra = @($actual | Where-Object { $_ -notin $expected } | Sort-Object -Unique)
    if ($missing.Count -or $extra.Count) { throw "$Label exact-set mismatch: missing [$($missing -join ', ')], extra [$($extra -join ', ')]" }
}
function Assert-Current($Rows, [string]$Field, [string]$Label) {
    $missing = @($Rows | Where-Object { [string]$_.$Field -ne "True" })
    if ($missing.Count) { throw "$Label contains $($missing.Count) IDs absent from current retail" }
}
function Assert-IDValues($ActualValues, $ExpectedValues, [string]$Label) {
    $actual = @($ActualValues | ForEach-Object { [string]$_ } | Where-Object { $_ } | Sort-Object -Unique)
    $expected = @($ExpectedValues | ForEach-Object { [string]$_ } | Where-Object { $_ } | Sort-Object -Unique)
    $missing = @($expected | Where-Object { $_ -notin $actual })
    $extra = @($actual | Where-Object { $_ -notin $expected })
    if ($missing.Count -or $extra.Count) { throw "$Label mismatch: missing [$($missing -join ', ')], extra [$($extra -join ', ')]" }
}
function Assert-GroupCounts($Rows, [string]$Field, $Expected, [string]$Label) {
    $actual = @{}
    foreach ($group in @($Rows | Group-Object $Field)) { $actual[[string]$group.Name] = $group.Count }
    foreach ($key in $Expected.Keys) {
        if ([int]$actual[[string]$key] -ne [int]$Expected[$key]) { throw "$Label $key count mismatch: expected $($Expected[$key]), got $($actual[[string]$key])" }
    }
    $extra = @($actual.Keys | Where-Object { -not $Expected.ContainsKey($_) })
    if ($extra.Count) { throw "$Label has unexpected groups: $($extra -join ', ')" }
}

$mountInventory = Read-Rows (Join-Path $idRoot "mounts.csv")
$petInventory = Read-Rows (Join-Path $idRoot "pets.csv")
$toyInventory = Read-Rows (Join-Path $idRoot "toys.csv")
$decorInventory = Read-Rows (Join-Path $idRoot "decorations.csv")
$achievementInventory = Read-Rows (Join-Path $idRoot "achievements.csv")
$criteriaInventory = Read-Rows (Join-Path $idRoot "achievement-criteria.csv")
$recipeInventory = Read-Rows (Join-Path $idRoot "recipes.csv")
$rareInventory = Read-Rows (Join-Path $idRoot "rares.csv")
$treasureInventory = Read-Rows (Join-Path $idRoot "treasures.csv")

$mountManifest = Read-Rows (Join-Path $manifestRoot "mounts.csv")
$petManifest = Read-Rows (Join-Path $manifestRoot "pets.csv")
$toyManifest = Read-Rows (Join-Path $manifestRoot "toys.csv")
$decorManifest = Read-Rows (Join-Path $manifestRoot "decorations.csv")
$achievementManifest = Read-Rows (Join-Path $manifestRoot "achievements.csv")
$criteriaManifest = Read-Rows (Join-Path $manifestRoot "achievement-criteria.csv")
$recipeManifest = Read-Rows (Join-Path $manifestRoot "recipes.csv")
$rareManifest = Read-Rows (Join-Path $manifestRoot "rares.csv")
$treasureManifest = Read-Rows (Join-Path $manifestRoot "treasures.csv")
$currencyManifest = Read-Rows (Join-Path $manifestRoot "supporting-currencies.csv")
$factionManifest = Read-Rows (Join-Path $manifestRoot "supporting-factions.csv")
$mapManifest = Read-Rows (Join-Path $manifestRoot "supporting-maps.csv")

Assert-ExactSet $mountManifest @($mountInventory | Where-Object release_decision -eq "include_cataclysm") "mount_id" "Cataclysm mounts" 48
Assert-ExactSet $petManifest $petInventory "species_id" "Cataclysm pets" 43
Assert-ExactSet $toyManifest @($toyInventory | Where-Object release_decision -eq "include_cataclysm") "toy_id" "Cataclysm toys" 40
Assert-ExactSet $decorManifest $decorInventory "decor_id" "Cataclysm decorations" 46
Assert-ExactSet $achievementManifest $achievementInventory "achievement_id" "Cataclysm achievements" 233
Assert-ExactSet $criteriaManifest $criteriaInventory "tree_id" "Cataclysm achievement criteria" 707
Assert-ExactSet $recipeManifest $recipeInventory "recipe_spell_id" "Cataclysm recipes" 690
Assert-ExactSet $rareManifest $rareInventory "tree_id" "Cataclysm rare criteria" 0
Assert-ExactSet $treasureManifest $treasureInventory "tree_id" "Cataclysm treasure criteria" 0
Assert-ExactSet $currencyManifest $currencyManifest "currency_id" "Cataclysm supporting currencies" 15
Assert-ExactSet $factionManifest $factionManifest "faction_id" "Cataclysm supporting factions" 11
Assert-ExactSet $mapManifest $mapManifest "map_id" "Cataclysm supporting maps" 15

Assert-Current $mountManifest "current_exists" "Cataclysm mount manifest"
Assert-Current $petManifest "current_exists" "Cataclysm pet manifest"
Assert-Current $toyManifest "current_exists" "Cataclysm toy manifest"
Assert-Current $decorManifest "current_exists" "Cataclysm decoration manifest"
Assert-Current $achievementManifest "current_exists" "Cataclysm achievement manifest"
Assert-Current $recipeManifest "current_ability_exists" "Cataclysm recipe manifest"
Assert-Current $currencyManifest "current_exists" "Cataclysm currency manifest"
Assert-Current $factionManifest "current_exists" "Cataclysm faction manifest"
Assert-Current $mapManifest "current_exists" "Cataclysm map manifest"

Assert-IDValues @($mountManifest | Where-Object unavailable -eq "True" | ForEach-Object mount_id) @("424","428","467") "Cataclysm unavailable mount IDs"
Assert-IDValues @($petManifest | Where-Object unavailable -eq "True" | ForEach-Object species_id) @() "Cataclysm unavailable pet IDs"
Assert-IDValues @($toyManifest | Where-Object unavailable -eq "True" | ForEach-Object toy_id) @("109","168","180") "Cataclysm unavailable toy IDs"
Assert-IDValues @($recipeManifest | Where-Object house_decor_recipe -eq "True" | ForEach-Object recipe_spell_id) @(
    "1261255","1269506","1261256","1262308","1262318","1262331","1261258","1262340","1261259","1261278",
    "1261288","1269534","1269540","1261305","1262357","1269550","1272580","1272588","1261317","1262370"
) "Cataclysm house decor recipe IDs"

Assert-GroupCounts $mountInventory "release_decision" @{ include_cataclysm=48; exclude_policy_external=13; exclude_unobtainable_or_internal=1; exclude_cross_expansion=1 } "Cataclysm mount decisions"
Assert-GroupCounts $toyInventory "release_decision" @{ include_cataclysm=40; exclude_policy_external=7; exclude_unobtainable_or_internal=14 } "Cataclysm toy decisions"
Assert-GroupCounts $recipeManifest "profession" @{ Alchemy=47; Blacksmithing=91; Cooking=33; Enchanting=53; Engineering=38; Inscription=38; Jewelcrafting=225; Leatherworking=95; Tailoring=70 } "Cataclysm profession recipes"
Assert-GroupCounts $achievementManifest "category_id" @{ "15067"=62; "15068"=62; "15069"=8; "15070"=43; "15072"=9; "15073"=15; "15074"=20; "15075"=14 } "Cataclysm achievement categories"
Assert-GroupCounts $decorManifest "source_kind" @{ achievement=2; crafted=20; drop=2; quest=20; vendor=2 } "Cataclysm decoration sources"
$taskGroups = @($criteriaManifest | Group-Object achievement_id | Where-Object { $_.Count -ge 2 -and $_.Count -le 30 })
if ($taskGroups.Count -ne 90 -or @($taskGroups.Group).Count -ne 500) { throw "Cataclysm achievement task boundary mismatch" }

$blizzardRows = Read-Rows (Join-Path $sourceRoot "blizzard-cataclysm-collectibles.csv")
if ($blizzardRows.Count -ne 72) { throw "Blizzard Cataclysm source row count mismatch" }
foreach ($expectation in @(@("mount",23,23,22),@("pet",40,40,40),@("toy",9,9,9))) {
    $rows = @($blizzardRows | Where-Object collectible_type -eq $expectation[0])
    $mapped = @($rows | Where-Object mapped_id)
    $unique = @($mapped.mapped_id | Sort-Object -Unique)
    if ($rows.Count -ne $expectation[1] -or $mapped.Count -ne $expectation[2] -or $unique.Count -ne $expectation[3]) { throw "Blizzard Cataclysm $($expectation[0]) guide mapping count mismatch" }
}
Assert-IDValues @($blizzardRows | Where-Object collectible_type -eq "mount" | ForEach-Object mapped_id) @($mountManifest | Where-Object official_guide_match -eq "True" | ForEach-Object mount_id) "Cataclysm mount guide coverage"
Assert-IDValues @($petManifest | Where-Object status -eq "blizzard_cataclysm_acquisition_confirmed" | ForEach-Object species_id) @($blizzardRows | Where-Object collectible_type -eq "pet" | ForEach-Object mapped_id) "Cataclysm pet guide coverage"
Assert-IDValues @($petManifest | Where-Object status -eq "cataclysm_archaeology_confirmed" | ForEach-Object species_id) @("309","310") "Cataclysm additional Archaeology pets"
Assert-IDValues @($petManifest | Where-Object status -eq "handynotes_cataclysm_acquisition_confirmed" | ForEach-Object species_id) @("306") "Cataclysm HandyNotes acquisition additions"
Assert-IDValues @($blizzardRows | Where-Object collectible_type -eq "toy" | ForEach-Object mapped_id) @($toyManifest | Where-Object official_guide_match -eq "True" | ForEach-Object toy_id) "Cataclysm toy guide coverage"
Assert-IDValues @($blizzardRows | Where-Object { $_.collectible_type -eq "mount" -and $_.mapping -eq "name_override_bad_guide_link" } | ForEach-Object source_id) @("94230") "Cataclysm bad camel guide link"

$housingAudit = Read-Rows (Join-Path $sourceRoot "housing-wowdb-acquisition-audit.csv")
$housingTheme = Read-Rows (Join-Path $sourceRoot "housing-wowdb-theme-catalog.csv")
$housingExclusions = Read-Rows (Join-Path $sourceRoot "housing-wowdb-theme-exclusions.csv")
$housingGlobal = Read-Rows (Join-Path $sourceRoot "housing-wowdb-global-acquisition-crosscheck.csv")
if ($housingAudit.Count -ne 46 -or $housingTheme.Count -ne 58 -or $housingExclusions.Count -ne 25 -or $housingGlobal.Count -ne 71) { throw "Cataclysm housing audit row counts changed" }
Assert-IDValues $housingAudit.decor_id $decorManifest.decor_id "Cataclysm housing manifest ownership"
Assert-IDValues @($housingGlobal | Where-Object status -eq "acquisition_cataclysm_confirmed" | ForEach-Object decor_id) $decorManifest.decor_id "Cataclysm global housing ownership"
Assert-IDValues $housingExclusions.decor_id @("856","857","859","860","1795","1802","1826","1828","2019","9248","11319","11484","11489","11493","11495","11944","15740","16219","16220","21081","21082","21083","21084","26478","27044") "Cataclysm themed housing exclusions"
Assert-IDValues @($decorManifest | Where-Object catalog_scope -eq "global_acquisition_match" | ForEach-Object decor_id) @("923","924","1281","1315","2226","2239","4401","4444","4447","4814","4819","11131","11433") "Non-themed Cataclysm decorations"

Assert-IDValues $mapManifest.map_id @("174","179","194","198","201","202","203","204","205","207","241","244","245","249","338") "Cataclysm supporting map IDs"
Assert-IDValues $factionManifest.faction_id @("1133","1134","1135","1158","1171","1172","1173","1174","1177","1178","1204") "Cataclysm supporting faction IDs"
Assert-IDValues $currencyManifest.currency_id @("361","384","385","391","393","394","397","398","399","400","401","416","515","614","615") "Cataclysm supporting currency IDs"

# Cataclysm owns acquisition content directly; later expansion manifests must not retain it.
$laterExpansions = @(
    @{name="WOD";root=$WodManifestRoot},@{name="Legion";root=$LegionManifestRoot},@{name="BFA";root=$BfaManifestRoot},
    @{name="Shadowlands";root=$ShadowlandsManifestRoot},@{name="Dragonflight";root=$DragonflightManifestRoot},@{name="TWW";root=$TwwManifestRoot}
)
foreach ($spec in @(
    @{name="mounts";field="mount_id"},@{name="pets";field="species_id"},@{name="toys";field="toy_id"},@{name="toys";field="item_id"},
    @{name="decorations";field="decor_id"},@{name="achievements";field="achievement_id"},@{name="recipes";field="recipe_spell_id"}
)) {
    $cataclysmIDs = Get-IDs (Read-Rows (Join-Path $manifestRoot "$($spec.name).csv")) $spec.field
    foreach ($later in $laterExpansions) {
        $laterIDs = Get-IDs (Read-Rows (Join-Path $later.root "$($spec.name).csv")) $spec.field
        $overlap = @($cataclysmIDs | Where-Object { $_ -in $laterIDs })
        Assert-IDValues $overlap @() "Cataclysm/$($later.name) $($spec.name) $($spec.field) overlap"
    }
}

$summary = Read-Rows (Join-Path $manifestRoot "summary.csv")
if ($summary.Count -ne 12) { throw "Cataclysm manifest summary row count mismatch" }
$summary | Format-Table -AutoSize
Write-Host "Collectionist Cataclysm manifest validation passed"
