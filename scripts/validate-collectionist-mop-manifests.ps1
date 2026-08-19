param(
    [string]$ResearchRoot = (Join-Path $PSScriptRoot "..\research\collectionist\mists-of-pandaria"),
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
$rareInventory = Read-Rows (Join-Path $idRoot "rare-candidates.csv")
$treasureInventory = Read-Rows (Join-Path $idRoot "treasure-candidates.csv")

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

Assert-ExactSet $mountManifest @($mountInventory | Where-Object release_decision -eq "include_mop") "mount_id" "Pandaria mounts" 89
Assert-ExactSet $petManifest $petInventory "species_id" "Pandaria pets" 152
Assert-ExactSet $toyManifest $toyInventory "toy_id" "Pandaria toys" 59
Assert-ExactSet $decorManifest @($decorInventory | Where-Object status -eq "acquisition_mop_confirmed") "decor_id" "Pandaria decorations" 41
Assert-ExactSet $achievementManifest @($achievementInventory | Where-Object current_exists -eq "True") "achievement_id" "Pandaria achievements" 407
Assert-ExactSet $criteriaManifest $criteriaInventory "tree_id" "Pandaria achievement criteria" 1563
Assert-ExactSet $recipeManifest $recipeInventory "recipe_spell_id" "Pandaria recipes" 978
Assert-ExactSet $rareManifest $rareInventory "tree_id" "Pandaria rare criteria" 104
Assert-ExactSet $treasureManifest $treasureInventory "tree_id" "Pandaria treasure criteria" 98
Assert-ExactSet $currencyManifest $currencyManifest "currency_id" "Pandaria supporting currencies" 10
Assert-ExactSet $factionManifest $factionManifest "faction_id" "Pandaria supporting factions" 26
Assert-ExactSet $mapManifest $mapManifest "map_id" "Pandaria supporting maps" 12

Assert-Current $mountManifest "current_exists" "Pandaria mount manifest"
Assert-Current $petManifest "current_exists" "Pandaria pet manifest"
Assert-Current $toyManifest "current_exists" "Pandaria toy manifest"
Assert-Current $achievementManifest "current_exists" "Pandaria achievement manifest"
Assert-Current $recipeManifest "current_ability_exists" "Pandaria recipe manifest"
Assert-Current $currencyManifest "current_exists" "Pandaria currency manifest"
Assert-Current $factionManifest "current_exists" "Pandaria faction manifest"
Assert-Current $mapManifest "current_exists" "Pandaria map manifest"

Assert-IDValues @($mountManifest | Where-Object unavailable -eq "True" | ForEach-Object mount_id) @("503","518","519","520","541","550","558","562","563","564") "Pandaria unavailable mount IDs"
Assert-IDValues @($petManifest | Where-Object unavailable -eq "True" | ForEach-Object species_id) @() "Pandaria unavailable pet IDs"
Assert-IDValues @($toyManifest | Where-Object unavailable -eq "True" | ForEach-Object toy_id) @() "Pandaria unavailable toy IDs"
Assert-IDValues @($recipeManifest | Where-Object current_spell_name_exists -ne "True" | ForEach-Object recipe_spell_id) @("122600","122601","122602","122603","122604","122605","122606","122607") "Pandaria recipes using historical names"
Assert-IDValues @($recipeManifest | Where-Object status -eq "current_house_decor_recipe" | ForEach-Object recipe_spell_id) @(
    "1261233","1261234","1261235","1261236","1261237","1261238","1261239","1261240","1261241","1261242","1261243",
    "1261244","1261245","1261248","1261250","1262302","1262306","1263548","1263551","1263553","1266563"
) "Pandaria house decor recipe IDs"

Assert-GroupCounts $recipeManifest "profession" @{
    Alchemy=37; Blacksmithing=196; Cooking=34; Enchanting=37; Engineering=48; Inscription=44; Jewelcrafting=200; Leatherworking=252; Tailoring=130
} "Pandaria profession recipes"
Assert-GroupCounts $achievementManifest "category_id" @{
    "15106"=44; "15107"=106; "15110"=64; "15113"=48; "15114"=20; "15162"=11; "15163"=10; "15218"=10; "15222"=19; "15229"=69; "15265"=6
} "Pandaria achievement categories"
Assert-GroupCounts $decorManifest "source_kind" @{ achievement=2; crafted=21; drop=2; quest=5; vendor=11 } "Pandaria decoration sources"
Assert-GroupCounts $treasureManifest "criteria_type" @{ "27"=46; "68"=52 } "Pandaria treasure criteria types"
if (@($rareManifest | Where-Object { $_.criteria_type -ne "0" -or -not $_.npc_id }).Count) { throw "Pandaria rare manifest contains criteria without direct NPC IDs" }
if (@($treasureManifest | Where-Object { -not $_.completion_quest_id -and -not $_.object_id }).Count) { throw "Pandaria treasure manifest contains criteria without quest or object IDs" }
$taskGroups = @($criteriaManifest | Group-Object achievement_id | Where-Object { $_.Count -ge 2 -and $_.Count -le 30 })
if ($taskGroups.Count -ne 127 -or @($taskGroups.Group).Count -ne 1002) { throw "Pandaria achievement task boundary mismatch" }

$blizzardRows = Read-Rows (Join-Path $sourceRoot "blizzard-mop-collectibles.csv")
if ($blizzardRows.Count -ne 268) { throw "Blizzard Pandaria source row count mismatch" }
foreach ($expectation in @(@("mount",56,56,55),@("pet",153,152,152),@("toy",59,59,59))) {
    $rows = @($blizzardRows | Where-Object collectible_type -eq $expectation[0])
    $mapped = @($rows | Where-Object mapped_id)
    $unique = @($mapped.mapped_id | Sort-Object -Unique)
    if ($rows.Count -ne $expectation[1] -or $mapped.Count -ne $expectation[2] -or $unique.Count -ne $expectation[3]) { throw "Blizzard Pandaria $($expectation[0]) guide mapping count mismatch" }
}
Assert-IDValues @($blizzardRows | Where-Object { $_.collectible_type -eq "pet" -and -not $_.mapped_id } | ForEach-Object source_id) @("94230") "Blizzard guide non-pet row embedded in pet table"
$officialMountIDs = @($blizzardRows | Where-Object collectible_type -eq "mount" | ForEach-Object mapped_id | Sort-Object -Unique)
Assert-IDValues @($officialMountIDs | Where-Object { $_ -notin $mountManifest.mount_id }) @("864") "Blizzard guide mounts outside Pandaria ownership"
Assert-IDValues @($petManifest.species_id) @($blizzardRows | Where-Object { $_.collectible_type -eq "pet" -and $_.mapped_id } | ForEach-Object mapped_id) "Pandaria pet guide coverage"
Assert-IDValues @($toyManifest.toy_id) @($blizzardRows | Where-Object { $_.collectible_type -eq "toy" -and $_.mapped_id } | ForEach-Object mapped_id) "Pandaria toy guide coverage"

$housingAudit = Read-Rows (Join-Path $sourceRoot "housing-wowdb-acquisition-audit.csv")
$housingTheme = Read-Rows (Join-Path $sourceRoot "housing-wowdb-theme-catalog.csv")
$housingExclusions = Read-Rows (Join-Path $sourceRoot "housing-wowdb-theme-exclusions.csv")
$housingGlobal = Read-Rows (Join-Path $sourceRoot "housing-wowdb-global-acquisition-crosscheck.csv")
if ($housingAudit.Count -ne 41 -or $housingTheme.Count -ne 64 -or $housingExclusions.Count -ne 24 -or $housingGlobal.Count -ne 70) { throw "Pandaria housing audit row counts changed" }
Assert-IDValues $housingAudit.decor_id $decorManifest.decor_id "Pandaria housing manifest ownership"
Assert-IDValues @($housingGlobal | Where-Object status -eq "acquisition_mop_confirmed" | ForEach-Object decor_id) $decorManifest.decor_id "Pandaria global housing ownership"
Assert-IDValues $housingExclusions.decor_id @("2453","2495","3834","3879","3882","3883","4048","4424","4425","5112","5113","5114","5119","5126","8179","8987","8988","9250","12263","14815","16091","16962","26196","26651") "Pandaria themed housing exclusions"

# Pandaria owns acquisition content directly; later expansion manifests must not retain it.
$laterExpansions = @(
    @{name="WOD";root=$WodManifestRoot},@{name="Legion";root=$LegionManifestRoot},@{name="BFA";root=$BfaManifestRoot},
    @{name="Shadowlands";root=$ShadowlandsManifestRoot},@{name="Dragonflight";root=$DragonflightManifestRoot},@{name="TWW";root=$TwwManifestRoot}
)
foreach ($spec in @(
    @{name="mounts";field="mount_id"},@{name="pets";field="species_id"},@{name="toys";field="toy_id"},@{name="toys";field="item_id"},
    @{name="decorations";field="decor_id"},@{name="achievements";field="achievement_id"},@{name="recipes";field="recipe_spell_id"}
)) {
    $mopIDs = Get-IDs (Read-Rows (Join-Path $manifestRoot "$($spec.name).csv")) $spec.field
    foreach ($later in $laterExpansions) {
        $laterIDs = Get-IDs (Read-Rows (Join-Path $later.root "$($spec.name).csv")) $spec.field
        $overlap = @($mopIDs | Where-Object { $_ -in $laterIDs })
        Assert-IDValues $overlap @() "Pandaria/$($later.name) $($spec.name) $($spec.field) overlap"
    }
}

$summary = Read-Rows (Join-Path $manifestRoot "summary.csv")
if ($summary.Count -ne 12) { throw "Pandaria manifest summary row count mismatch" }
$summary | Format-Table -AutoSize
Write-Host "Collectionist Mists of Pandaria manifest validation passed"
