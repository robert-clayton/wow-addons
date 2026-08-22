param(
    [string]$ResearchRoot = (Join-Path $PSScriptRoot "..\research\collectionist\warlords-of-draenor"),
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
function Get-IDs($Rows, [string]$Field) { return @($Rows | ForEach-Object { [string]$_.$Field } | Where-Object { $_ } | Sort-Object -Unique) }
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
    $actual = @($ActualValues | ForEach-Object { [string]$_ } | Sort-Object -Unique)
    $expected = @($ExpectedValues | ForEach-Object { [string]$_ } | Sort-Object -Unique)
    $missing = @($expected | Where-Object { $_ -notin $actual })
    $extra = @($actual | Where-Object { $_ -notin $expected })
    if ($missing.Count -or $extra.Count) { throw "$Label mismatch: missing [$($missing -join ', ')], extra [$($extra -join ', ')]" }
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

Assert-ExactSet $mountManifest @($mountInventory | Where-Object release_decision -eq "include_wod") "mount_id" "Warlords mounts" 68
Assert-ExactSet $petManifest @($petInventory | Where-Object release_decision -eq "include_wod") "species_id" "Warlords pets" 84
Assert-IDValues @($petInventory | Where-Object release_decision -eq "exclude_tbc" | ForEach-Object species_id) @("1622", "1623", "1624", "1625", "1626", "1627", "1628", "1629", "1631", "1632", "1633", "1634", "1635") "Warlords TBC-owned pet exclusions"
Assert-ExactSet $toyManifest @($toyInventory | Where-Object release_decision -eq "include_wod") "toy_id" "Warlords toys" 91
Assert-ExactSet $decorManifest @($decorInventory | Where-Object status -eq "acquisition_wod_confirmed") "decor_id" "Warlords decorations" 80
Assert-ExactSet $achievementManifest @($achievementInventory | Where-Object status -eq "wod_category_confirmed") "achievement_id" "Warlords achievements" 402
Assert-ExactSet $criteriaManifest $criteriaInventory "tree_id" "Warlords achievement criteria" 3035
Assert-ExactSet $recipeManifest @($recipeInventory | Where-Object status -in @("current_named_recipe", "current_house_decor_recipe")) "recipe_spell_id" "Warlords recipes" 337
Assert-IDValues @($recipeManifest | Where-Object status -eq "current_house_decor_recipe" | ForEach-Object recipe_spell_id) @(
    "1260985","1260987","1260988","1260990","1261008","1261025","1261027","1261032","1261045","1261066","1261071",
    "1261075","1261081","1261122","1261231","1261232","1262011","1263360","1266560","1269500","1269501"
) "Warlords house decor recipe IDs"
Assert-ExactSet $rareManifest @($rareInventory | Where-Object selection_decision -eq "include_wod") "tree_id" "Warlords rare criteria" 72
Assert-ExactSet $treasureManifest @($treasureInventory | Where-Object selection_decision -eq "include_wod") "tree_id" "Warlords treasure criteria" 368
Assert-ExactSet $currencyManifest $currencyManifest "currency_id" "Warlords supporting currencies" 17
Assert-ExactSet $factionManifest $factionManifest "faction_id" "Warlords supporting factions" 20
Assert-ExactSet $mapManifest $mapManifest "map_id" "Warlords supporting maps" 9

Assert-Current $mountManifest "current_exists" "Warlords mount manifest"
Assert-Current $petManifest "current_exists" "Warlords pet manifest"
Assert-Current $toyManifest "current_exists" "Warlords toy manifest"
Assert-Current $achievementManifest "current_exists" "Warlords achievement manifest"
Assert-Current $recipeManifest "current_ability_exists" "Warlords recipe manifest"
Assert-Current $recipeManifest "current_spell_name_exists" "Warlords recipe names"
Assert-Current $currencyManifest "current_exists" "Warlords currency manifest"
Assert-Current $factionManifest "current_exists" "Warlords faction manifest"
Assert-Current $mapManifest "current_exists" "Warlords map manifest"
if (@($rareManifest | Where-Object { -not $_.npc_id }).Count) { throw "Warlords rare manifest contains criteria without NPC IDs" }
if (@($treasureManifest | Where-Object { -not $_.completion_quest_id }).Count) { throw "Warlords treasure manifest contains criteria without quest IDs" }
Assert-IDValues @($mountManifest | Where-Object unavailable -eq "True" | ForEach-Object mount_id) @("606","651","654","759","760","761","764") "Warlords unavailable mount IDs"
Assert-IDValues @($achievementInventory | Where-Object status -eq "wod_decoration_acquisition_support" | ForEach-Object achievement_id) @("9415") "Warlords decoration achievement support IDs"

$blizzardRows = Read-Rows (Join-Path $sourceRoot "blizzard-wod-collectibles.csv")
$housingAudit = Read-Rows (Join-Path $sourceRoot "housing-wowdb-acquisition-audit.csv")
$housingGlobal = Read-Rows (Join-Path $sourceRoot "housing-wowdb-global-acquisition-crosscheck.csv")
if ($blizzardRows.Count -ne 190) { throw "Blizzard Warlords source row count mismatch" }
if ($housingAudit.Count -ne 80) { throw "Warlords housing acquisition audit count mismatch" }
if ($housingGlobal.Count -ne 83) { throw "Warlords global housing cross-check count mismatch" }
Assert-IDValues @($housingGlobal | Where-Object status -eq "acquisition_wod_confirmed" | ForEach-Object decor_id) @($housingAudit.decor_id) "Warlords global housing ownership IDs"
Assert-IDValues @($housingGlobal | Where-Object status -ne "acquisition_wod_confirmed" | ForEach-Object decor_id) @("126","3835","21889") "Warlords global housing exclusions"

foreach ($spec in @(
    @{name="mounts";field="mount_id"},@{name="pets";field="species_id"},@{name="toys";field="toy_id"},@{name="toys";field="item_id"},
    @{name="decorations";field="decor_id"},@{name="achievements";field="achievement_id"},@{name="recipes";field="recipe_spell_id"}
)) {
    $wodIDs = Get-IDs (Read-Rows (Join-Path $manifestRoot "$($spec.name).csv")) $spec.field
    foreach ($later in @(
        @{name="Legion";root=$LegionManifestRoot},@{name="BFA";root=$BfaManifestRoot},@{name="Shadowlands";root=$ShadowlandsManifestRoot},
        @{name="Dragonflight";root=$DragonflightManifestRoot},@{name="TWW";root=$TwwManifestRoot}
    )) {
        $laterIDs = Get-IDs (Read-Rows (Join-Path $later.root "$($spec.name).csv")) $spec.field
        $overlap = @($wodIDs | Where-Object { $_ -in $laterIDs })
        if ($overlap.Count) { throw "Warlords/$($later.name) $($spec.name) $($spec.field) overlap: $($overlap -join ', ')" }
    }
}

$summary = Read-Rows (Join-Path $manifestRoot "summary.csv")
if ($summary.Count -ne 12) { throw "Warlords manifest summary row count mismatch" }
$summary | Format-Table -AutoSize
Write-Host "Collectionist Warlords manifest validation passed"
