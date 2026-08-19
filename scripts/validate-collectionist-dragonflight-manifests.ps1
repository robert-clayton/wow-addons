param(
    [string]$ResearchRoot = (Join-Path $PSScriptRoot "..\research\collectionist\dragonflight"),
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
    $actualValues = @($actualRows | ForEach-Object { [string]$_.$field } | Where-Object { $_ })
    $expectedValues = @($expectedRows | ForEach-Object { [string]$_.$field } | Where-Object { $_ })
    if ($actualValues.Count -ne $expectedCount) {
        throw "$label row count mismatch: expected $expectedCount, got $($actualValues.Count)"
    }
    if (@($actualValues | Sort-Object -Unique).Count -ne $actualValues.Count) {
        throw "$label contains duplicate or missing $field values"
    }
    $missing = @($expectedValues | Where-Object { $_ -notin $actualValues } | Sort-Object -Unique)
    $extra = @($actualValues | Where-Object { $_ -notin $expectedValues } | Sort-Object -Unique)
    if ($missing.Count -or $extra.Count) {
        throw "$label exact-set mismatch: missing [$($missing -join ', ')], extra [$($extra -join ', ')]"
    }
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
$decorationInventory = Read-Rows (Join-Path $idRoot "decorations.csv")
$achievementInventory = Read-Rows (Join-Path $idRoot "achievements.csv")
$criteriaInventory = Read-Rows (Join-Path $idRoot "achievement-criteria.csv")
$recipeInventory = Read-Rows (Join-Path $idRoot "recipes.csv")
$rareInventory = Read-Rows (Join-Path $idRoot "rares.csv")
$treasureInventory = Read-Rows (Join-Path $idRoot "treasures.csv")
$mapInventory = Read-Rows (Join-Path $idRoot "maps.csv")

$mountManifest = Read-Rows (Join-Path $manifestRoot "mounts.csv")
$petManifest = Read-Rows (Join-Path $manifestRoot "pets.csv")
$toyManifest = Read-Rows (Join-Path $manifestRoot "toys.csv")
$decorationManifest = Read-Rows (Join-Path $manifestRoot "decorations.csv")
$achievementManifest = Read-Rows (Join-Path $manifestRoot "achievements.csv")
$criteriaManifest = Read-Rows (Join-Path $manifestRoot "achievement-criteria.csv")
$recipeManifest = Read-Rows (Join-Path $manifestRoot "recipes.csv")
$rareManifest = Read-Rows (Join-Path $manifestRoot "rares.csv")
$treasureManifest = Read-Rows (Join-Path $manifestRoot "treasures.csv")
$currencyManifest = Read-Rows (Join-Path $manifestRoot "supporting-currencies.csv")
$factionManifest = Read-Rows (Join-Path $manifestRoot "supporting-factions.csv")
$mapManifest = Read-Rows (Join-Path $manifestRoot "supporting-maps.csv")

Assert-ExactSet $mountManifest @($mountInventory | Where-Object release_decision -eq "include_dragonflight") "mount_id" "Dragonflight mounts" 161
Assert-ExactSet $petManifest @($petInventory | Where-Object release_decision -eq "include_dragonflight") "species_id" "Dragonflight pets" 164
Assert-ExactSet $toyManifest @($toyInventory | Where-Object release_decision -eq "include_dragonflight") "toy_id" "Dragonflight toys" 171
Assert-IDValues @($toyInventory | Where-Object release_decision -eq "exclude_classic" | ForEach-Object toy_id) @("1340") "Dragonflight Classic-owned toy exclusions"
Assert-ExactSet $decorationManifest @($decorationInventory | Where-Object status -eq "acquisition_dragonflight_confirmed") "decor_id" "Dragonflight decorations" 76
Assert-ExactSet $achievementManifest @($achievementInventory | Where-Object status -eq "dragonflight_category_confirmed") "achievement_id" "Dragonflight achievements" 569
Assert-ExactSet $recipeManifest @($recipeInventory | Where-Object status -in @("named_recipe", "current_house_decor_recipe", "acquisition_dragonflight_ancient_zulgurub")) "recipe_spell_id" "Dragonflight recipes" 1004
Assert-IDValues @($recipeManifest | Where-Object status -eq "current_house_decor_recipe" | ForEach-Object recipe_spell_id) @(
    "1259195","1259233","1259247","1259369","1259384","1259386","1259404","1259422","1259429","1259433","1259441","1259451",
    "1259461","1260331","1260333","1261882","1261885","1261892","1261896","1261919","1261933","1261940","1263237","1266555","1272572"
) "Dragonflight house decor recipe IDs"
$ancientZulGurubRecipes = Read-Rows (Join-Path $sourceRoot "ancient-zulgurub-recipes.csv")
Assert-ExactSet @($recipeManifest | Where-Object status -eq "acquisition_dragonflight_ancient_zulgurub") $ancientZulGurubRecipes "recipe_spell_id" "Dragonflight Ancient Zul'Gurub recipes" 31
Assert-ExactSet $rareManifest $rareInventory "tree_id" "Dragonflight rare criteria" 197
Assert-ExactSet $treasureManifest $treasureInventory "tree_id" "Dragonflight treasure criteria" 57
Assert-ExactSet $mapManifest $mapInventory "map_id" "Dragonflight supporting maps" 9

$achievementIDs = Get-IDs $achievementManifest "achievement_id"
$expectedCriteria = @($criteriaInventory | Where-Object { [string]$_.achievement_id -in $achievementIDs })
Assert-ExactSet $criteriaManifest $expectedCriteria "tree_id" "Dragonflight achievement criteria" 3203

if (@($currencyManifest).Count -ne 8 -or (Get-IDs $currencyManifest "currency_id").Count -ne 8) {
    throw "Dragonflight supporting currency manifest count or uniqueness mismatch"
}
if (@($factionManifest).Count -ne 15 -or (Get-IDs $factionManifest "faction_id").Count -ne 15) {
    throw "Dragonflight supporting faction manifest count or uniqueness mismatch"
}

$overlapSpecs = @(
    @{ name = "mounts"; field = "mount_id" },
    @{ name = "pets"; field = "species_id" },
    @{ name = "toys"; field = "item_id" },
    @{ name = "decorations"; field = "decor_id" },
    @{ name = "achievements"; field = "achievement_id" },
    @{ name = "recipes"; field = "recipe_spell_id" }
)
foreach ($spec in $overlapSpecs) {
    $dragonflightRows = Read-Rows (Join-Path $manifestRoot "$($spec.name).csv")
    $twwRows = Read-Rows (Join-Path $TwwManifestRoot "$($spec.name).csv")
    $dragonflightIDs = Get-IDs $dragonflightRows $spec.field
    $twwIDs = Get-IDs $twwRows $spec.field
    $overlap = @($dragonflightIDs | Where-Object { $_ -in $twwIDs })
    if ($overlap.Count) {
        throw "Dragonflight/TWW $($spec.name) overlap: $($overlap -join ', ')"
    }
}

Import-Csv -LiteralPath (Join-Path $manifestRoot "summary.csv") | Format-Table -AutoSize
Write-Host "Collectionist Dragonflight manifest validation passed"
