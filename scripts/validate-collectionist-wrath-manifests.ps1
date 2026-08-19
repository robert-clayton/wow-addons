param(
    [string]$ResearchRoot = (Join-Path $PSScriptRoot "..\research\collectionist\wrath-of-the-lich-king"),
    [string]$CataclysmManifestRoot = (Join-Path $PSScriptRoot "..\research\collectionist\cataclysm\manifests"),
    [string]$MopManifestRoot = (Join-Path $PSScriptRoot "..\research\collectionist\mists-of-pandaria\manifests"),
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

Assert-ExactSet $mountManifest @($mountInventory | Where-Object release_decision -eq "include_wrath") "mount_id" "Wrath mounts" 93
Assert-ExactSet $petManifest $petInventory "species_id" "Wrath pets" 52
Assert-ExactSet $toyManifest @($toyInventory | Where-Object release_decision -eq "include_wrath") "toy_id" "Wrath toys" 36
Assert-ExactSet $decorManifest $decorInventory "decor_id" "Wrath decorations" 27
Assert-ExactSet $achievementManifest $achievementInventory "achievement_id" "Wrath achievements" 384
Assert-ExactSet $criteriaManifest $criteriaInventory "tree_id" "Wrath achievement criteria" 1352
Assert-ExactSet $recipeManifest $recipeInventory "recipe_spell_id" "Wrath recipes" 860
Assert-ExactSet $rareManifest $rareInventory "tree_id" "Wrath rare criteria" 23
Assert-ExactSet $treasureManifest $treasureInventory "tree_id" "Wrath treasure criteria" 0
Assert-ExactSet $currencyManifest $currencyManifest "currency_id" "Wrath supporting currencies" 13
Assert-ExactSet $factionManifest $factionManifest "faction_id" "Wrath supporting factions" 19
Assert-ExactSet $mapManifest $mapManifest "map_id" "Wrath supporting maps" 13

Assert-Current $mountManifest "current_exists" "Wrath mount manifest"
Assert-Current $petManifest "current_exists" "Wrath pet manifest"
Assert-Current $toyManifest "current_exists" "Wrath toy manifest"
Assert-Current $decorManifest "current_exists" "Wrath decoration manifest"
Assert-Current $achievementManifest "current_exists" "Wrath achievement manifest"
Assert-Current $recipeManifest "current_ability_exists" "Wrath recipe manifest"
Assert-Current $currencyManifest "current_exists" "Wrath currency manifest"
Assert-Current $factionManifest "current_exists" "Wrath faction manifest"
Assert-Current $mapManifest "current_exists" "Wrath map manifest"

Assert-IDValues @($mountManifest | Where-Object unavailable -eq "True" | ForEach-Object mount_id) @("263","266","313","317","340","342","343","344","345","358") "Wrath unavailable mount IDs"
Assert-IDValues @($petManifest | Where-Object unavailable -eq "True" | ForEach-Object species_id) @() "Wrath unavailable pet IDs"
Assert-IDValues @($toyManifest | Where-Object unavailable -eq "True" | ForEach-Object toy_id) @() "Wrath unavailable toy IDs"
Assert-IDValues @($recipeManifest | Where-Object house_decor_recipe -eq "True" | ForEach-Object recipe_spell_id) @(
    "1261327","1262824","1262825","1269499","1263562","1263575","1263613","1263620","1263570","1263605","1263574",
    "1263564","1263577","1263558","1263559","1263627","1272662","1272707","1272688","1272614","1272676"
) "Wrath house decor recipe IDs"

Assert-GroupCounts $mountInventory "release_decision" @{ include_wrath=93; exclude_policy_external=13; exclude_unobtainable_or_internal=4 } "Wrath mount decisions"
Assert-GroupCounts $toyInventory "release_decision" @{ include_wrath=36; exclude_policy_external=7; exclude_cross_expansion=3 } "Wrath toy decisions"
Assert-GroupCounts $recipeManifest "profession" @{ Alchemy=69; Blacksmithing=128; Cooking=46; Enchanting=69; Engineering=51; Inscription=29; Jewelcrafting=217; Leatherworking=154; Tailoring=97 } "Wrath profession recipes"
Assert-GroupCounts $achievementManifest "category_id" @{ "14780"=12; "14806"=80; "14863"=21; "14866"=14; "14901"=19; "14922"=203; "14941"=35 } "Wrath achievement categories"
Assert-GroupCounts $decorManifest "source_kind" @{ achievement=2; crafted=21; drop=1; quest=3 } "Wrath decoration sources"
$taskGroups = @($criteriaManifest | Group-Object achievement_id | Where-Object { $_.Count -ge 2 -and $_.Count -le 30 })
if ($taskGroups.Count -ne 239 -or @($taskGroups.Group).Count -ne 1207) { throw "Wrath achievement task boundary mismatch" }

$blizzardRows = Read-Rows (Join-Path $sourceRoot "blizzard-wrath-collectibles.csv")
if ($blizzardRows.Count -ne 124) { throw "Blizzard Wrath source row count mismatch" }
foreach ($expectation in @(@("mount",49,49,49),@("pet",50,50,50),@("toy",25,25,25))) {
    $rows = @($blizzardRows | Where-Object collectible_type -eq $expectation[0])
    $mapped = @($rows | Where-Object mapped_id)
    $unique = @($mapped.mapped_id | Sort-Object -Unique)
    if ($rows.Count -ne $expectation[1] -or $mapped.Count -ne $expectation[2] -or $unique.Count -ne $expectation[3]) { throw "Blizzard Wrath $($expectation[0]) guide mapping count mismatch" }
}
Assert-IDValues @($blizzardRows | Where-Object collectible_type -eq "mount" | ForEach-Object mapped_id) @($mountManifest | Where-Object official_guide_match -eq "True" | ForEach-Object mount_id) "Wrath mount guide coverage"
Assert-IDValues @($petManifest | Where-Object status -eq "blizzard_wrath_acquisition_confirmed" | ForEach-Object species_id) @($blizzardRows | Where-Object collectible_type -eq "pet" | ForEach-Object mapped_id) "Wrath pet guide coverage"
Assert-IDValues @($petManifest | Where-Object status -eq "handynotes_wrath_acquisition_confirmed" | ForEach-Object species_id) @("199", "238") "Wrath HandyNotes acquisition additions"
Assert-IDValues @($blizzardRows | Where-Object collectible_type -eq "toy" | ForEach-Object mapped_id) @($toyInventory | Where-Object official_guide_match -eq "True" | ForEach-Object toy_id) "Wrath toy guide mapping"
Assert-IDValues @($blizzardRows | Where-Object { $_.collectible_type -eq "toy" -and $_.mapped_id -notin $toyManifest.toy_id } | ForEach-Object mapped_id) @("467") "Wrath guide cross-expansion toy exclusion"

$housingAudit = Read-Rows (Join-Path $sourceRoot "housing-wowdb-acquisition-audit.csv")
$housingTheme = Read-Rows (Join-Path $sourceRoot "housing-wowdb-theme-catalog.csv")
$housingExclusions = Read-Rows (Join-Path $sourceRoot "housing-wowdb-theme-exclusions.csv")
$housingGlobal = Read-Rows (Join-Path $sourceRoot "housing-wowdb-global-acquisition-crosscheck.csv")
if ($housingAudit.Count -ne 27 -or $housingTheme.Count -ne 22 -or $housingExclusions.Count -ne 3 -or $housingGlobal.Count -ne 30) { throw "Wrath housing audit row counts changed" }
Assert-IDValues $housingAudit.decor_id $decorManifest.decor_id "Wrath housing manifest ownership"
Assert-IDValues @($housingGlobal | Where-Object status -eq "acquisition_wrath_confirmed" | ForEach-Object decor_id) $decorManifest.decor_id "Wrath global housing ownership"
Assert-IDValues $housingExclusions.decor_id @("9475","25104","25336") "Wrath themed housing exclusions"
Assert-IDValues @($decorManifest | Where-Object catalog_scope -eq "global_acquisition_match" | ForEach-Object decor_id) @("1674","4448","4839","11722","11872","11893","11899","11906") "Non-themed Wrath decorations"

Assert-IDValues $rareManifest.achievement_id @("2257") "Wrath rare source achievement"
Assert-IDValues $rareManifest.npc_id @("32357","32358","32361","32377","32386","32398","32400","32409","32417","32422","32429","32438","32447","32471","32475","32481","32485","32487","32495","32500","32501","32517","32630") "Wrath rare NPC IDs"
if ($rareManifest.Count -ne 23) { throw "Wrath rare NPC list must preserve all 23 Frostbitten criteria" }
Assert-IDValues $mapManifest.map_id @("113","114","115","116","117","118","119","120","121","123","125","127","170") "Wrath supporting map IDs"
Assert-IDValues $factionManifest.faction_id @("1037","1050","1052","1064","1067","1068","1073","1085","1090","1091","1094","1098","1104","1105","1106","1119","1124","1126","1156") "Wrath supporting faction IDs"
Assert-IDValues $currencyManifest.currency_id @("61","81","101","102","124","126","161","201","221","241","301","321","341") "Wrath supporting currency IDs"

$laterExpansions = @(
    @{name="Cataclysm";root=$CataclysmManifestRoot},@{name="MoP";root=$MopManifestRoot},@{name="WOD";root=$WodManifestRoot},
    @{name="Legion";root=$LegionManifestRoot},@{name="BFA";root=$BfaManifestRoot},@{name="Shadowlands";root=$ShadowlandsManifestRoot},
    @{name="Dragonflight";root=$DragonflightManifestRoot},@{name="TWW";root=$TwwManifestRoot}
)
foreach ($spec in @(
    @{name="mounts";field="mount_id"},@{name="pets";field="species_id"},@{name="toys";field="toy_id"},@{name="toys";field="item_id"},
    @{name="decorations";field="decor_id"},@{name="achievements";field="achievement_id"},@{name="recipes";field="recipe_spell_id"}
)) {
    $wrathIDs = Get-IDs (Read-Rows (Join-Path $manifestRoot "$($spec.name).csv")) $spec.field
    foreach ($later in $laterExpansions) {
        $laterIDs = Get-IDs (Read-Rows (Join-Path $later.root "$($spec.name).csv")) $spec.field
        $overlap = @($wrathIDs | Where-Object { $_ -in $laterIDs })
        Assert-IDValues $overlap @() "Wrath/$($later.name) $($spec.name) $($spec.field) overlap"
    }
}

$summary = Read-Rows (Join-Path $manifestRoot "summary.csv")
if ($summary.Count -ne 12) { throw "Wrath manifest summary row count mismatch" }
$summary | Format-Table -AutoSize
Write-Host "Collectionist Wrath manifest validation passed"
