param(
    [string]$ResearchRoot = (Join-Path $PSScriptRoot "..\research\collectionist\legion"),
    [string]$BfaManifestRoot = (Join-Path $PSScriptRoot "..\research\collectionist\battle-for-azeroth\manifests"),
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
function Get-IDs($rows, [string]$field) { return @($rows | ForEach-Object { [string]$_.$field } | Where-Object { $_ } | Sort-Object -Unique) }
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

Assert-ExactSet $mountManifest @($mountInventory | Where-Object release_decision -eq "include_legion") "mount_id" "Legion mounts" 124
Assert-ExactSet $petManifest @($petInventory | Where-Object release_decision -eq "include_legion") "species_id" "Legion pets" 106
Assert-ExactSet $toyManifest @($toyInventory | Where-Object release_decision -eq "include_legion") "toy_id" "Legion toys" 154
Assert-IDValues @($toyInventory | Where-Object release_decision -eq "exclude_classic" | ForEach-Object toy_id) @("480", "482", "582") "Legion Classic-owned toy exclusions"
Assert-IDValues @($toyInventory | Where-Object release_decision -eq "exclude_tbc" | ForEach-Object toy_id) @("436", "481", "483", "487", "489", "501", "502", "528", "529", "530", "539", "640", "646") "Legion TBC-owned toy exclusions"
Assert-IDValues @($petInventory | Where-Object release_decision -eq "exclude_wrath" | ForEach-Object species_id) @("1727", "1952", "1953", "1954", "1955", "1956", "1957", "1958", "1959", "1960", "1961", "1962", "1963", "1964", "1965", "1966", "1967", "1968", "1969") "Legion Wrath-owned pet exclusions"
Assert-IDValues @($toyInventory | Where-Object release_decision -eq "exclude_wrath" | ForEach-Object toy_id) @("465", "472", "476", "477", "514", "515", "607") "Legion Wrath-owned toy exclusions"
Assert-IDValues @($petInventory | Where-Object release_decision -eq "exclude_cataclysm" | ForEach-Object species_id) @("2078", "2079", "2082", "2083", "2085", "2086", "2087", "2089", "2090") "Legion Cataclysm-owned pet exclusions"
Assert-IDValues @($toyInventory | Where-Object release_decision -eq "exclude_cataclysm" | ForEach-Object toy_id) @("444", "445", "455", "473", "484", "488", "490", "491") "Legion Cataclysm-owned toy exclusions"
Assert-IDValues @($petInventory | Where-Object release_decision -eq "exclude_mop" | ForEach-Object species_id) @("2017", "2018") "Legion Pandaria-owned pet exclusions"
Assert-IDValues @($toyInventory | Where-Object release_decision -eq "exclude_mop" | ForEach-Object toy_id) @("442", "451", "452", "453", "454", "456", "457", "462", "463", "464", "467", "468", "470", "486", "497", "498", "619", "633") "Legion Pandaria-owned toy exclusions"
Assert-ExactSet $decorManifest @($decorInventory | Where-Object status -eq "acquisition_legion_confirmed") "decor_id" "Legion decorations" 211
Assert-ExactSet $achievementManifest @($achievementInventory | Where-Object status -eq "legion_category_confirmed") "achievement_id" "Legion achievements" 305
Assert-ExactSet $criteriaManifest $criteriaInventory "tree_id" "Legion achievement criteria" 2407
Assert-ExactSet $recipeManifest @($recipeInventory | Where-Object status -in @("named_recipe", "current_house_decor_recipe")) "recipe_spell_id" "Legion recipes" 773
Assert-IDValues @($recipeManifest | Where-Object status -eq "current_house_decor_recipe" | ForEach-Object recipe_spell_id) @(
    "1260693","1260695","1260698","1260700","1260704","1260711","1260719","1260730","1260737","1260757","1260762","1260765",
    "1260769","1260774","1262152","1262154","1262238","1262273","1263319","1263338","1263344","1263351","1263858"
) "Legion house decor recipe IDs"
Assert-ExactSet $rareManifest @($rareInventory | Where-Object selection_decision -eq "include_legion") "tree_id" "Legion rare criteria" 185
Assert-ExactSet $treasureManifest @($treasureInventory | Where-Object selection_decision -eq "include_legion") "tree_id" "Legion treasure criteria" 314
Assert-ExactSet $currencyManifest $currencyManifest "currency_id" "Legion supporting currencies" 12
Assert-ExactSet $factionManifest $factionManifest "faction_id" "Legion supporting factions" 18
Assert-ExactSet $mapManifest $mapManifest "map_id" "Legion supporting maps" 11

if (@($rareManifest | Where-Object { -not $_.npc_ids -and -not $_.object_ids }).Count) { throw "Legion rare manifest contains criteria without entity IDs" }
if (@($rareManifest | Where-Object object_ids).Count -ne 7) { throw "Legion rare object-provider count mismatch" }
Assert-ExactSet $rareNPCAudit @($rareManifest | Where-Object criteria_type -eq "27") "tree_id" "Legion quest-criteria rare entity audit" 105
foreach ($audit in $rareNPCAudit) {
    $manifestRow = @($rareManifest | Where-Object tree_id -eq $audit.tree_id)
    if ($manifestRow.Count -ne 1 -or [string]$manifestRow[0].npc_ids -ne [string]$audit.npc_id -or [string]$manifestRow[0].object_ids -ne [string]$audit.object_id) { throw "Legion rare entity audit mismatch for tree $($audit.tree_id)" }
}

Assert-Current $mountManifest "current_exists" "Legion mount manifest"
Assert-Current $petManifest "current_exists" "Legion pet manifest"
Assert-Current $toyManifest "current_exists" "Legion toy manifest"
Assert-Current $achievementManifest "current_exists" "Legion achievement manifest"
Assert-Current $recipeManifest "current_ability_exists" "Legion recipe manifest"
Assert-Current $recipeManifest "current_spell_name_exists" "Legion recipe names"
Assert-Current $currencyManifest "current_exists" "Legion currency manifest"
Assert-Current $factionManifest "current_exists" "Legion faction manifest"
Assert-Current $mapManifest "current_exists" "Legion map manifest"
Assert-IDValues @($mountManifest | Where-Object unavailable -eq "True" | ForEach-Object mount_id) @("848", "849", "850", "851", "852", "853", "878", "948", "978") "Legion unavailable mount IDs"
Assert-IDValues @($petManifest | Where-Object unavailable -eq "True" | ForEach-Object species_id) @("1889", "2022") "Legion unavailable pet IDs"
Assert-IDValues @($toyManifest | Where-Object unavailable -eq "True" | ForEach-Object toy_id) @() "Legion unavailable toy IDs"

foreach ($spec in @(
    @{ name = "mounts"; field = "mount_id" }, @{ name = "pets"; field = "species_id" },
    @{ name = "toys"; field = "toy_id" }, @{ name = "toys"; field = "item_id" },
    @{ name = "decorations"; field = "decor_id" }, @{ name = "achievements"; field = "achievement_id" },
    @{ name = "recipes"; field = "recipe_spell_id" }
)) {
    $legionIDs = Get-IDs (Read-Rows (Join-Path $manifestRoot "$($spec.name).csv")) $spec.field
    foreach ($later in @(
        @{ name = "BFA"; root = $BfaManifestRoot }, @{ name = "Shadowlands"; root = $ShadowlandsManifestRoot },
        @{ name = "Dragonflight"; root = $DragonflightManifestRoot }, @{ name = "TWW"; root = $TwwManifestRoot }
    )) {
        $laterIDs = Get-IDs (Read-Rows (Join-Path $later.root "$($spec.name).csv")) $spec.field
        $overlap = @($legionIDs | Where-Object { $_ -in $laterIDs })
        if ($overlap.Count) { throw "Legion/$($later.name) $($spec.name) $($spec.field) overlap: $($overlap -join ', ')" }
    }
}

$summary = Read-Rows (Join-Path $manifestRoot "summary.csv")
if ($summary.Count -ne 12) { throw "Legion manifest summary row count mismatch" }
$summary | Format-Table -AutoSize
Write-Host "Collectionist Legion manifest validation passed"
