param(
    [string]$ResearchRoot = (Join-Path $PSScriptRoot "..\research\collectionist\battle-for-azeroth"),
    [string]$ShadowlandsManifestRoot = (Join-Path $PSScriptRoot "..\research\collectionist\shadowlands\manifests"),
    [string]$DragonflightManifestRoot = (Join-Path $PSScriptRoot "..\research\collectionist\dragonflight\manifests"),
    [string]$TwwManifestRoot = (Join-Path $PSScriptRoot "..\research\collectionist\tww\manifests")
)

$ErrorActionPreference = "Stop"
$idRoot = Join-Path $ResearchRoot "ids"
$manifestRoot = Join-Path $ResearchRoot "manifests"
$sourceRoot = Join-Path $ResearchRoot "sources"

function Read-Rows([string]$path) {
    if (-not (Test-Path -LiteralPath $path)) { throw "Missing CSV: $path" }
    return @(Import-Csv -LiteralPath $path)
}
function Get-IDs($rows, [string]$field) {
    return @($rows | ForEach-Object { [string]$_.$field } | Where-Object { $_ } | Sort-Object -Unique)
}
function Assert-ExactSet($actualRows, $expectedRows, [string]$field, [string]$label, [int]$expectedCount) {
    $actual = @($actualRows | ForEach-Object { [string]$_.$field } | Where-Object { $_ })
    $expected = @($expectedRows | ForEach-Object { [string]$_.$field } | Where-Object { $_ })
    if ($actual.Count -ne $expectedCount) { throw "$label count mismatch: expected $expectedCount, got $($actual.Count)" }
    if (@($actual | Sort-Object -Unique).Count -ne $actual.Count) { throw "$label contains duplicate or missing $field values" }
    $missing = @($expected | Where-Object { $_ -notin $actual } | Sort-Object -Unique)
    $extra = @($actual | Where-Object { $_ -notin $expected } | Sort-Object -Unique)
    if ($missing.Count -or $extra.Count) { throw "$label exact-set mismatch: missing [$($missing -join ', ')], extra [$($extra -join ', ')]" }
}
function Assert-Current($rows, [string]$field, [string]$label) {
    $missing = @($rows | Where-Object { [string]$_.$field -ne "True" })
    if ($missing.Count) { throw "$label contains $($missing.Count) IDs absent from current retail" }
}
function Assert-IDValues($actualValues, $expectedValues, [string]$label) {
    $actual = @($actualValues | ForEach-Object { [string]$_ } | Sort-Object -Unique)
    $expected = @($expectedValues | ForEach-Object { [string]$_ } | Sort-Object -Unique)
    $missing = @($expected | Where-Object { $_ -notin $actual })
    $extra = @($actual | Where-Object { $_ -notin $expected })
    if ($missing.Count -or $extra.Count) { throw "$label mismatch: missing [$($missing -join ', ')], extra [$($extra -join ', ')]" }
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
$rareNPCAudit = Read-Rows (Join-Path $sourceRoot "rare-npc-audit.csv")

Assert-ExactSet $mountManifest @($mountInventory | Where-Object release_decision -eq "include_bfa") "mount_id" "BFA mounts" 140
Assert-ExactSet $petManifest @($petInventory | Where-Object release_decision -eq "include_bfa") "species_id" "BFA pets" 236
Assert-IDValues @($petInventory | Where-Object release_decision -eq "exclude_mop" | ForEach-Object species_id) @("2579", "2580", "2581", "2582", "2583", "2584", "2585", "2586", "2587", "2589", "2590") "BFA Pandaria-owned pet exclusions"
Assert-ExactSet $toyManifest @($toyInventory | Where-Object release_decision -eq "include_bfa") "toy_id" "BFA toys" 135
Assert-ExactSet $decorManifest @($decorInventory | Where-Object status -eq "acquisition_bfa_confirmed") "decor_id" "BFA decorations" 136
Assert-ExactSet $achievementManifest @($achievementInventory | Where-Object status -eq "bfa_category_confirmed") "achievement_id" "BFA achievements" 452
Assert-ExactSet $recipeManifest @($recipeInventory | Where-Object status -in @("named_recipe", "current_house_decor_recipe")) "recipe_spell_id" "BFA recipes" 1253
Assert-IDValues @($recipeManifest | Where-Object status -eq "current_house_decor_recipe" | ForEach-Object recipe_spell_id) @(
    "1260337","1260349","1260352","1260425","1260458","1260475","1260485","1260492","1260501","1260508","1260564",
    "1260577","1260583","1260593","1260596","1260691","1260692","1262005","1262151","1263859","1263870","1263877"
) "BFA house decor recipe IDs"
Assert-ExactSet $rareManifest @($rareInventory | Where-Object selection_decision -eq "include_bfa") "tree_id" "BFA rare criteria" 254
Assert-ExactSet $treasureManifest @($treasureInventory | Where-Object selection_decision -eq "include_bfa") "tree_id" "BFA treasure criteria" 98
$achievementIDs = Get-IDs $achievementManifest "achievement_id"
Assert-ExactSet $criteriaManifest @($criteriaInventory | Where-Object { [string]$_.achievement_id -in $achievementIDs }) "tree_id" "BFA achievement criteria" 2851
Assert-ExactSet $currencyManifest $currencyManifest "currency_id" "BFA supporting currencies" 14
Assert-ExactSet $factionManifest $factionManifest "faction_id" "BFA supporting factions" 19
Assert-ExactSet $mapManifest $mapManifest "map_id" "BFA supporting maps" 10

if (@($rareManifest | Where-Object { -not $_.npc_ids -and -not $_.object_ids }).Count) { throw "BFA rare manifest contains criteria without entity IDs" }
if (@($rareManifest | Where-Object object_ids).Count -ne 5) { throw "BFA rare object-provider count mismatch" }
Assert-ExactSet $rareNPCAudit @($rareManifest | Where-Object criteria_type -eq "27") "tree_id" "BFA quest-criteria rare entity audit" 158
foreach ($audit in $rareNPCAudit) {
    $manifestRow = @($rareManifest | Where-Object tree_id -eq $audit.tree_id)
    if ($manifestRow.Count -ne 1 -or [string]$manifestRow[0].npc_ids -ne [string]$audit.npc_id -or [string]$manifestRow[0].object_ids -ne [string]$audit.object_id) {
        throw "BFA rare entity audit mismatch for tree $($audit.tree_id)"
    }
}

Assert-Current $mountManifest "current_exists" "BFA mount manifest"
Assert-Current $petManifest "current_exists" "BFA pet manifest"
Assert-Current $toyManifest "current_exists" "BFA toy manifest"
Assert-Current $achievementManifest "current_exists" "BFA achievement manifest"
Assert-Current $recipeManifest "current_ability_exists" "BFA recipe manifest"
Assert-Current $recipeManifest "current_spell_name_exists" "BFA recipe names"
Assert-Current $currencyManifest "current_exists" "BFA currency manifest"
Assert-Current $factionManifest "current_exists" "BFA faction manifest"
Assert-Current $mapManifest "current_exists" "BFA map manifest"
Assert-IDValues @($mountManifest | Where-Object unavailable -eq "True" | ForEach-Object mount_id) @("1030", "1031", "1032", "1035", "1220", "1265", "1326") "BFA unavailable mount IDs"
Assert-IDValues @($petManifest | Where-Object unavailable -eq "True" | ForEach-Object species_id) @() "BFA unavailable pet IDs"
Assert-IDValues @($toyManifest | Where-Object unavailable -eq "True" | ForEach-Object toy_id) @() "BFA unavailable toy IDs"

foreach ($spec in @(
    @{ name = "mounts"; field = "mount_id" }, @{ name = "pets"; field = "species_id" },
    @{ name = "toys"; field = "toy_id" }, @{ name = "toys"; field = "item_id" },
    @{ name = "decorations"; field = "decor_id" }, @{ name = "achievements"; field = "achievement_id" },
    @{ name = "recipes"; field = "recipe_spell_id" }
)) {
    $bfaIDs = Get-IDs (Read-Rows (Join-Path $manifestRoot "$($spec.name).csv")) $spec.field
    foreach ($later in @(
        @{ name = "Shadowlands"; root = $ShadowlandsManifestRoot },
        @{ name = "Dragonflight"; root = $DragonflightManifestRoot },
        @{ name = "TWW"; root = $TwwManifestRoot }
    )) {
        $laterIDs = Get-IDs (Read-Rows (Join-Path $later.root "$($spec.name).csv")) $spec.field
        $overlap = @($bfaIDs | Where-Object { $_ -in $laterIDs })
        if ($overlap.Count) { throw "BFA/$($later.name) $($spec.name) $($spec.field) overlap: $($overlap -join ', ')" }
    }
}

$summary = Read-Rows (Join-Path $manifestRoot "summary.csv")
if ($summary.Count -ne 12) { throw "BFA manifest summary row count mismatch" }
$summary | Format-Table -AutoSize
Write-Host "Collectionist Battle for Azeroth manifest validation passed"
