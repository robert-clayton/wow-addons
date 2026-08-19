param(
    [string]$ResearchRoot = (Join-Path $PSScriptRoot "..\research\collectionist\shadowlands"),
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

function Assert-Current($rows, [string]$label) {
    $missing = @($rows | Where-Object { [string]$_.current_exists -ne "True" })
    if ($missing.Count) {
        throw "$label contains IDs absent from current retail"
    }
}

function Assert-IDValues($actualValues, $expectedValues, [string]$label) {
    $actual = @($actualValues | ForEach-Object { [string]$_ } | Sort-Object -Unique)
    $expected = @($expectedValues | ForEach-Object { [string]$_ } | Sort-Object -Unique)
    $missing = @($expected | Where-Object { $_ -notin $actual })
    $extra = @($actual | Where-Object { $_ -notin $expected })
    if ($missing.Count -or $extra.Count) {
        throw "$label mismatch: missing [$($missing -join ', ')], extra [$($extra -join ', ')]"
    }
}

$mountInventory = Read-Rows (Join-Path $idRoot "mounts.csv")
$petInventory = Read-Rows (Join-Path $idRoot "pets.csv")
$toyInventory = Read-Rows (Join-Path $idRoot "toys.csv")
$decorationInventory = Read-Rows (Join-Path $idRoot "decorations.csv")
$achievementInventory = Read-Rows (Join-Path $idRoot "achievements.csv")
$criteriaInventory = Read-Rows (Join-Path $idRoot "achievement-criteria.csv")
$recipeInventory = Read-Rows (Join-Path $idRoot "recipes.csv")
$rareInventory = Read-Rows (Join-Path $idRoot "rare-candidates.csv")
$treasureInventory = Read-Rows (Join-Path $idRoot "treasure-candidates.csv")

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
$bastionRareNPCAudit = Read-Rows (Join-Path $sourceRoot "bastion-rare-npc-audit.csv")

Assert-ExactSet $mountManifest @($mountInventory | Where-Object release_decision -eq "include_shadowlands") "mount_id" "Shadowlands mounts" 180
Assert-ExactSet $petManifest @($petInventory | Where-Object release_decision -eq "include_shadowlands") "species_id" "Shadowlands pets" 176
Assert-IDValues @($mountManifest | Where-Object status -eq "snapshot_candidate" | Where-Object mount_id -eq "293" | ForEach-Object mount_id) @("293") "Shadowlands reused Illidari Doomhawk mount ID"
Assert-IDValues @($petManifest | Where-Object status -eq "collectible_wild_pet" | ForEach-Object species_id) @("3215") "Shadowlands collectible wild-pet overrides"
Assert-ExactSet $toyManifest @($toyInventory | Where-Object release_decision -eq "include_shadowlands") "toy_id" "Shadowlands toys" 115
Assert-ExactSet $decorationManifest @($decorationInventory | Where-Object status -eq "acquisition_shadowlands_confirmed") "decor_id" "Shadowlands decorations" 26
Assert-ExactSet $achievementManifest @($achievementInventory | Where-Object status -eq "shadowlands_category_confirmed") "achievement_id" "Shadowlands achievements" 419
Assert-ExactSet $recipeManifest @($recipeInventory | Where-Object status -in @("named_recipe", "current_house_decor_recipe")) "recipe_spell_id" "Shadowlands recipes" 634
Assert-IDValues @($recipeManifest | Where-Object status -eq "current_house_decor_recipe" | ForEach-Object recipe_spell_id) @(
    "1260334","1261958","1261972","1261980","1261982","1261998","1263238","1263239","1263240","1263241","1263243","1263247",
    "1263272","1263278","1263285","1263293","1263308","1263313","1263853","1269502","1269504","1272575","1272578"
) "Shadowlands house decor recipe IDs"
Assert-ExactSet $rareManifest @($rareInventory | Where-Object selection_decision -eq "include_shadowlands") "tree_id" "Shadowlands rare criteria" 211
Assert-ExactSet $treasureManifest @($treasureInventory | Where-Object selection_decision -eq "include_shadowlands") "tree_id" "Shadowlands treasure criteria" 103
if (@($rareManifest | Where-Object { -not $_.npc_ids }).Count) {
    throw "Shadowlands rare manifest contains criteria without NPC IDs"
}
Assert-ExactSet @($rareManifest | Where-Object achievement_id -eq "14307") $bastionRareNPCAudit "criterion" "Bastion rare NPC mappings" 29
foreach ($audit in $bastionRareNPCAudit) {
    $manifestRow = @($rareManifest | Where-Object criterion -eq $audit.criterion)
    if ($manifestRow.Count -ne 1 -or [string]$manifestRow[0].npc_ids -ne [string]$audit.npc_id) {
        throw "Bastion rare NPC mapping mismatch for $($audit.criterion)"
    }
}

$achievementIDs = Get-IDs $achievementManifest "achievement_id"
$expectedCriteria = @($criteriaInventory | Where-Object { [string]$_.achievement_id -in $achievementIDs })
Assert-ExactSet $criteriaManifest $expectedCriteria "tree_id" "Shadowlands achievement criteria" 2489
Assert-ExactSet $currencyManifest $currencyManifest "currency_id" "Shadowlands supporting currencies" 9
Assert-ExactSet $factionManifest $factionManifest "faction_id" "Shadowlands supporting factions" 12
Assert-ExactSet $mapManifest $mapManifest "map_id" "Shadowlands supporting maps" 8

Assert-Current $mountManifest "Shadowlands mount manifest"
Assert-Current $petManifest "Shadowlands pet manifest"
Assert-Current $toyManifest "Shadowlands toy manifest"
Assert-Current $currencyManifest "Shadowlands currency manifest"
Assert-Current $factionManifest "Shadowlands faction manifest"
Assert-Current $mapManifest "Shadowlands map manifest"
Assert-IDValues @($mountManifest | Where-Object unavailable -eq "True" | ForEach-Object mount_id) @("1363", "1405", "1419", "1480", "1520", "1544", "1552", "1572", "1576", "1599") "Shadowlands unavailable mount IDs"
Assert-IDValues @($petManifest | Where-Object unavailable -eq "True" | ForEach-Object species_id) @("3046") "Shadowlands unavailable pet IDs"
Assert-IDValues @($toyManifest | Where-Object unavailable -eq "True" | ForEach-Object toy_id) @() "Shadowlands unavailable toy IDs"

foreach ($spec in @(
    @{ name = "mounts"; field = "mount_id" },
    @{ name = "pets"; field = "species_id" },
    @{ name = "toys"; field = "toy_id" },
    @{ name = "toys"; field = "item_id" },
    @{ name = "decorations"; field = "decor_id" },
    @{ name = "achievements"; field = "achievement_id" },
    @{ name = "recipes"; field = "recipe_spell_id" }
)) {
    $shadowlandsIDs = Get-IDs (Read-Rows (Join-Path $manifestRoot "$($spec.name).csv")) $spec.field
    foreach ($later in @(
        @{ name = "Dragonflight"; root = $DragonflightManifestRoot },
        @{ name = "TWW"; root = $TwwManifestRoot }
    )) {
        $laterIDs = Get-IDs (Read-Rows (Join-Path $later.root "$($spec.name).csv")) $spec.field
        $overlap = @($shadowlandsIDs | Where-Object { $_ -in $laterIDs })
        if ($overlap.Count) {
            throw "Shadowlands/$($later.name) $($spec.name) $($spec.field) overlap: $($overlap -join ', ')"
        }
    }
}

$summary = Read-Rows (Join-Path $manifestRoot "summary.csv")
if ($summary.Count -ne 12) { throw "Shadowlands manifest summary row count mismatch" }
$summary | Format-Table -AutoSize
Write-Host "Collectionist Shadowlands manifest validation passed"
