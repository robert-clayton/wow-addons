param(
    [string]$ResearchRoot = (Join-Path $PSScriptRoot "..\research\collectionist\the-burning-crusade"),
    [string]$WrathManifestRoot = (Join-Path $PSScriptRoot "..\research\collectionist\wrath-of-the-lich-king\manifests"),
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

Assert-ExactSet $mountManifest @($mountInventory | Where-Object release_decision -eq "include_tbc") "mount_id" "TBC mounts" 68
Assert-ExactSet $petManifest @($petInventory | Where-Object release_decision -eq "include_tbc") "species_id" "TBC pets" 65
Assert-ExactSet $toyManifest @($toyInventory | Where-Object release_decision -eq "include_tbc") "toy_id" "TBC toys" 22
Assert-ExactSet $decorManifest $decorInventory "decor_id" "TBC decorations" 29
Assert-ExactSet $achievementManifest $achievementInventory "achievement_id" "TBC achievements" 99
Assert-ExactSet $criteriaManifest $criteriaInventory "tree_id" "TBC achievement criteria" 842
Assert-ExactSet $recipeManifest $recipeInventory "recipe_spell_id" "TBC recipes" 755
Assert-ExactSet $rareManifest $rareInventory "tree_id" "TBC rares" 20
Assert-ExactSet $treasureManifest $treasureInventory "tree_id" "TBC treasures" 0
Assert-ExactSet $currencyManifest $currencyManifest "currency_id" "TBC supporting currencies" 5
Assert-ExactSet $factionManifest $factionManifest "faction_id" "TBC supporting factions" 22
Assert-ExactSet $mapManifest $mapManifest "map_id" "TBC supporting maps" 16

Assert-Current $mountManifest "current_exists" "TBC mount manifest"
Assert-Current $petManifest "current_exists" "TBC pet manifest"
Assert-Current $toyManifest "current_exists" "TBC toy manifest"
Assert-Current $decorManifest "current_exists" "TBC decoration manifest"
Assert-Current $achievementManifest "current_exists" "TBC achievement manifest"
Assert-Current $recipeManifest "current_ability_exists" "TBC recipe manifest"
Assert-Current $currencyManifest "current_exists" "TBC currency manifest"
Assert-Current $factionManifest "current_exists" "TBC faction manifest"
Assert-Current $mapManifest "current_exists" "TBC map manifest"
if (@($toyManifest | Where-Object { -not $_.source_text }).Count) { throw "TBC toy manifest contains blank acquisition sources" }

Assert-IDValues @($mountManifest | Where-Object unavailable -eq "True" | ForEach-Object mount_id) @("169","199","201","207","223","241") "TBC unavailable mount IDs"
Assert-IDValues @($petManifest | Where-Object unavailable -eq "True" | ForEach-Object species_id) @() "TBC unavailable pet IDs"
Assert-IDValues @($toyManifest | Where-Object unavailable -eq "True" | ForEach-Object toy_id) @() "TBC unavailable toy IDs"
Assert-IDValues @($recipeManifest | Where-Object house_decor_recipe -eq "True" | ForEach-Object recipe_spell_id) @(
    "1261331","1261340","1261347","1261359","1261383","1262828","1263643","1263654","1263663","1263669",
    "1263692","1263810","1263811","1263812","1263813","1263814","1263815","1263817","1263818","1263819",
    "1269496","1272712","1272715","1272723","1273064","1273070"
) "TBC house decor recipe IDs"

Assert-GroupCounts $mountInventory "release_decision" @{include_tbc=68;exclude_cross_expansion=8;exclude_policy_external=9;exclude_unobtainable_or_internal=5} "TBC mount decisions"
Assert-GroupCounts $petInventory "release_decision" @{include_tbc=65;exclude_cross_expansion=5;exclude_policy_external=15} "TBC pet decisions"
Assert-GroupCounts $toyInventory "release_decision" @{include_tbc=22;exclude_cross_expansion=2;exclude_policy_external=8} "TBC toy decisions"
Assert-GroupCounts $recipeManifest "profession" @{Alchemy=75;Blacksmithing=129;Cooking=24;Enchanting=67;Engineering=76;Inscription=5;Jewelcrafting=157;Leatherworking=128;Tailoring=94} "TBC profession recipes"
Assert-GroupCounts $achievementManifest "category_id" @{"14777"=3;"14778"=2;"14779"=9;"14803"=13;"14805"=40;"14861"=1;"14862"=14;"14865"=16;"15081"=1} "TBC achievement categories"
Assert-GroupCounts $decorManifest "source_kind" @{achievement=2;crafted=26;drop=1} "TBC decoration sources"
$taskGroups = @($criteriaManifest | Group-Object achievement_id | Where-Object { $_.Count -ge 2 -and $_.Count -le 30 })
if ($taskGroups.Count -ne 65 -or @($taskGroups.Group).Count -ne 648) { throw "TBC achievement task boundary mismatch" }
Assert-IDValues @($achievementManifest | Where-Object achievement_id -in @("858","859","860","861","868","4908","4926") | ForEach-Object achievement_id) @("858","859","860","861","868","4908","4926") "TBC starter-zone achievements"

$blizzardRows = Read-Rows (Join-Path $sourceRoot "blizzard-tbc-collectibles.csv")
if ($blizzardRows.Count -ne 93) { throw "Blizzard TBC source row count mismatch" }
foreach ($expectation in @(@("mount",35),@("pet",47),@("toy",11))) {
    $rows=@($blizzardRows | Where-Object collectible_type -eq $expectation[0]);$mapped=@($rows|Where-Object mapped_id);$unique=@($mapped.mapped_id|Sort-Object -Unique)
    if($rows.Count-ne$expectation[1]-or$mapped.Count-ne$expectation[1]-or$unique.Count-ne$expectation[1]){throw "Blizzard TBC $($expectation[0]) guide mapping count mismatch"}
}
Assert-IDValues @($blizzardRows | Where-Object collectible_type -eq "mount" | ForEach-Object mapped_id) @($mountManifest | Where-Object official_guide_match -eq "True" | ForEach-Object mount_id) "TBC mount guide coverage"
Assert-IDValues @($blizzardRows | Where-Object collectible_type -eq "pet" | ForEach-Object mapped_id) @($petInventory | Where-Object official_guide_match -eq "True" | ForEach-Object species_id) "TBC pet guide mapping"
Assert-IDValues @($blizzardRows | Where-Object { $_.collectible_type -eq "pet" -and $_.mapped_id -notin $petManifest.species_id } | ForEach-Object mapped_id) @("44","51","55") "TBC guide Classic pet exclusions"
Assert-IDValues @($blizzardRows | Where-Object collectible_type -eq "toy" | ForEach-Object mapped_id) @($toyManifest | Where-Object official_guide_match -eq "True" | ForEach-Object toy_id) "TBC toy guide coverage"

$housingAudit = Read-Rows (Join-Path $sourceRoot "housing-wowdb-acquisition-audit.csv")
$housingTheme = Read-Rows (Join-Path $sourceRoot "housing-wowdb-theme-catalog.csv")
$housingExclusions = Read-Rows (Join-Path $sourceRoot "housing-wowdb-theme-exclusions.csv")
$housingGlobal = Read-Rows (Join-Path $sourceRoot "housing-wowdb-global-acquisition-crosscheck.csv")
if($housingAudit.Count-ne29-or$housingTheme.Count-ne51-or$housingExclusions.Count-ne27-or$housingGlobal.Count-ne56){throw "TBC housing audit row counts changed"}
Assert-IDValues $housingAudit.decor_id $decorManifest.decor_id "TBC housing manifest ownership"
Assert-IDValues @($housingGlobal | Where-Object status -eq "acquisition_tbc_confirmed" | ForEach-Object decor_id) $decorManifest.decor_id "TBC global housing ownership"
Assert-IDValues $housingExclusions.decor_id @("2505","3908","3909","3910","3911","3912","3913","3914","3915","3916","3917","3918","3919","3920","3921","4157","11899","14467","14829","14830","14831","14832","14833","14834","16754","18482","26477") "TBC themed housing exclusions"
Assert-IDValues @($decorManifest | Where-Object catalog_scope -eq "global_acquisition_match" | ForEach-Object decor_id) @("3898","3899","15570","16219","16220") "Non-themed TBC decorations"

Assert-IDValues $rareManifest.achievement_id @("1312") "TBC rare source achievement"
Assert-IDValues $rareManifest.npc_id @("17144","18677","18678","18679","18680","18681","18682","18683","18685","18686","18689","18690","18692","18693","18694","18695","18696","18697","18698","20932") "TBC rare NPC IDs"
Assert-IDValues $mapManifest.map_id @("94","95","97","100","101","102","103","104","105","106","107","108","109","110","111","122") "TBC supporting map IDs"
Assert-IDValues $factionManifest.faction_id @("911","922","930","932","933","934","935","941","942","946","947","967","970","978","989","990","1011","1012","1015","1031","1038","1077") "TBC supporting faction IDs"
Assert-IDValues $currencyManifest.currency_id @("42","103","123","1166","1704") "TBC supporting currency IDs"

$laterExpansions = @(
    @{name="Wrath";root=$WrathManifestRoot},@{name="Cataclysm";root=$CataclysmManifestRoot},@{name="MoP";root=$MopManifestRoot},
    @{name="WOD";root=$WodManifestRoot},@{name="Legion";root=$LegionManifestRoot},@{name="BFA";root=$BfaManifestRoot},
    @{name="Shadowlands";root=$ShadowlandsManifestRoot},@{name="Dragonflight";root=$DragonflightManifestRoot},@{name="TWW";root=$TwwManifestRoot}
)
foreach($spec in @(
    @{name="mounts";field="mount_id"},@{name="pets";field="species_id"},@{name="toys";field="toy_id"},@{name="toys";field="item_id"},
    @{name="decorations";field="decor_id"},@{name="achievements";field="achievement_id"},@{name="recipes";field="recipe_spell_id"}
)){
    $tbcIDs=Get-IDs (Read-Rows (Join-Path $manifestRoot "$($spec.name).csv")) $spec.field
    foreach($later in $laterExpansions){
        $laterIDs=Get-IDs (Read-Rows (Join-Path $later.root "$($spec.name).csv")) $spec.field
        $overlap=@($tbcIDs|Where-Object{$_-in$laterIDs})
        Assert-IDValues $overlap @() "TBC/$($later.name) $($spec.name) $($spec.field) overlap"
    }
}

$summary=Read-Rows (Join-Path $manifestRoot "summary.csv")
if($summary.Count-ne12){throw "TBC manifest summary row count mismatch"}
$summary|Format-Table -AutoSize
Write-Host "Collectionist TBC manifest validation passed"
