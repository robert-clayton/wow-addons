param(
    [string]$ResearchRoot = (Join-Path $PSScriptRoot "..\research\collectionist\classic"),
    [string]$TbcManifestRoot = (Join-Path $PSScriptRoot "..\research\collectionist\the-burning-crusade\manifests"),
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
$idRoot=Join-Path $ResearchRoot "ids";$manifestRoot=Join-Path $ResearchRoot "manifests";$sourceRoot=Join-Path $ResearchRoot "sources"
function Read-Rows([string]$Path){if(-not(Test-Path -LiteralPath $Path)){throw "Missing CSV: $Path"};return @(Import-Csv -LiteralPath $Path)}
function Get-IDs($Rows,[string]$Field){return @($Rows|ForEach-Object{[string]$_.$Field}|Where-Object{$_}|Sort-Object -Unique)}
function Assert-ExactSet($ActualRows,$ExpectedRows,[string]$Field,[string]$Label,[int]$ExpectedCount){$actual=@($ActualRows|ForEach-Object{[string]$_.$Field}|Where-Object{$_});$expected=@($ExpectedRows|ForEach-Object{[string]$_.$Field}|Where-Object{$_});if($actual.Count-ne$ExpectedCount){throw "$Label count mismatch: expected $ExpectedCount, got $($actual.Count)"};if(@($actual|Sort-Object -Unique).Count-ne$actual.Count){throw "$Label contains duplicate or missing $Field values"};$missing=@($expected|Where-Object{$_-notin$actual}|Sort-Object -Unique);$extra=@($actual|Where-Object{$_-notin$expected}|Sort-Object -Unique);if($missing.Count-or$extra.Count){throw "$Label exact-set mismatch: missing [$($missing-join', ')], extra [$($extra-join', ')]"}}
function Assert-Current($Rows,[string]$Field,[string]$Label){$missing=@($Rows|Where-Object{[string]$_.$Field-ne"True"});if($missing.Count){throw "$Label contains $($missing.Count) IDs absent from current retail"}}
function Assert-IDValues($ActualValues,$ExpectedValues,[string]$Label){$actual=@($ActualValues|ForEach-Object{[string]$_}|Where-Object{$_}|Sort-Object -Unique);$expected=@($ExpectedValues|ForEach-Object{[string]$_}|Where-Object{$_}|Sort-Object -Unique);$missing=@($expected|Where-Object{$_-notin$actual});$extra=@($actual|Where-Object{$_-notin$expected});if($missing.Count-or$extra.Count){throw "$Label mismatch: missing [$($missing-join', ')], extra [$($extra-join', ')]"}}
function Assert-GroupCounts($Rows,[string]$Field,$Expected,[string]$Label){$actual=@{};foreach($group in @($Rows|Group-Object $Field)){$actual[[string]$group.Name]=$group.Count};foreach($key in $Expected.Keys){if([int]$actual[[string]$key]-ne[int]$Expected[$key]){throw "$Label $key count mismatch: expected $($Expected[$key]), got $($actual[[string]$key])"}};$extra=@($actual.Keys|Where-Object{-not$Expected.ContainsKey($_)});if($extra.Count){throw "$Label has unexpected groups: $($extra-join', ')"}}

$mountInventory=Read-Rows (Join-Path $idRoot "mounts.csv");$petInventory=Read-Rows (Join-Path $idRoot "pets.csv");$toyInventory=Read-Rows (Join-Path $idRoot "toys.csv");$decorInventory=Read-Rows (Join-Path $idRoot "decorations.csv");$achievementInventory=Read-Rows (Join-Path $idRoot "achievements.csv");$criteriaInventory=Read-Rows (Join-Path $idRoot "achievement-criteria.csv");$recipeInventory=Read-Rows (Join-Path $idRoot "recipes.csv");$rareInventory=Read-Rows (Join-Path $idRoot "rares.csv");$treasureInventory=Read-Rows (Join-Path $idRoot "treasures.csv")
$mountManifest=Read-Rows (Join-Path $manifestRoot "mounts.csv");$petManifest=Read-Rows (Join-Path $manifestRoot "pets.csv");$toyManifest=Read-Rows (Join-Path $manifestRoot "toys.csv");$decorManifest=Read-Rows (Join-Path $manifestRoot "decorations.csv");$achievementManifest=Read-Rows (Join-Path $manifestRoot "achievements.csv");$criteriaManifest=Read-Rows (Join-Path $manifestRoot "achievement-criteria.csv");$recipeManifest=Read-Rows (Join-Path $manifestRoot "recipes.csv");$rareManifest=Read-Rows (Join-Path $manifestRoot "rares.csv");$treasureManifest=Read-Rows (Join-Path $manifestRoot "treasures.csv");$currencyManifest=Read-Rows (Join-Path $manifestRoot "supporting-currencies.csv");$factionManifest=Read-Rows (Join-Path $manifestRoot "supporting-factions.csv");$mapManifest=Read-Rows (Join-Path $manifestRoot "supporting-maps.csv")

Assert-ExactSet $mountManifest @($mountInventory|Where-Object release_decision -eq "include_classic") "mount_id" "Classic mounts" 85
Assert-ExactSet $petManifest @($petInventory|Where-Object release_decision -eq "include_classic") "species_id" "Classic pets" 59
Assert-ExactSet $toyManifest @($toyInventory|Where-Object release_decision -eq "include_classic") "toy_id" "Classic toys" 10
Assert-ExactSet $decorManifest $decorInventory "decor_id" "Classic decorations" 22
Assert-ExactSet $achievementManifest $achievementInventory "achievement_id" "Classic achievements" 199
Assert-ExactSet $criteriaManifest $criteriaInventory "tree_id" "Classic achievement criteria" 1268
Assert-ExactSet $recipeManifest $recipeInventory "recipe_spell_id" "Classic recipes" 1223
Assert-ExactSet $rareManifest $rareInventory "tree_id" "Classic rares" 0
Assert-ExactSet $treasureManifest $treasureInventory "tree_id" "Classic treasures" 0
Assert-ExactSet $currencyManifest $currencyManifest "currency_id" "Classic supporting currencies" 5
Assert-ExactSet $factionManifest $factionManifest "faction_id" "Classic supporting factions" 33
Assert-ExactSet $mapManifest $mapManifest "map_id" "Classic supporting maps" 52

foreach($check in @(@($mountManifest,"current_exists","mount"),@($petManifest,"current_exists","pet"),@($toyManifest,"current_exists","toy"),@($decorManifest,"current_exists","decoration"),@($achievementManifest,"current_exists","achievement"),@($recipeManifest,"current_ability_exists","recipe"),@($currencyManifest,"current_exists","currency"),@($factionManifest,"current_exists","faction"),@($mapManifest,"current_exists","map"))){Assert-Current $check[0] $check[1] "Classic $($check[2]) manifest"}

Assert-GroupCounts $mountInventory "release_decision" @{include_classic=85;exclude_unobtainable_or_internal=14} "Classic mount decisions"
Assert-GroupCounts $petInventory "release_decision" @{include_classic=59;exclude_cross_expansion=4;exclude_policy_external=7} "Classic pet decisions"
Assert-GroupCounts $toyInventory "release_decision" @{include_classic=10;exclude_cross_expansion=10} "Classic toy decisions"
Assert-GroupCounts $recipeManifest "profession" @{Alchemy=114;Blacksmithing=248;Cooking=81;Enchanting=135;Engineering=158;Inscription=5;Jewelcrafting=2;Leatherworking=231;Tailoring=249} "Classic profession recipes"
Assert-GroupCounts $achievementManifest "category_id" @{"14777"=22;"14778"=19;"14801"=19;"14802"=16;"14804"=19;"14808"=24;"14821"=25;"14861"=24;"14864"=4;"15081"=27} "Classic achievement categories"
Assert-GroupCounts $decorManifest "source_kind" @{achievement=1;crafted=19;drop=1;quest=1} "Classic decoration sources"
$taskGroups=@($criteriaManifest|Group-Object achievement_id|Where-Object{$_.Count-ge2-and$_.Count-le30});if($taskGroups.Count-ne115-or@($taskGroups.Group).Count-ne1149){throw "Classic achievement task boundary mismatch"}

Assert-IDValues @($recipeManifest|Where-Object house_decor_recipe -eq "True"|ForEach-Object recipe_spell_id) @("1261495","1261497","1261499","1261501","1261504","1261509","1261549","1261572","1261587","1261644","1261659","1261667","1261672","1261688","1261695","1262829","1263633","1269495","1270459") "Classic house decor recipe IDs"
Assert-IDValues @($petInventory|Where-Object release_decision -eq "exclude_policy_external"|ForEach-Object species_id) @("92","93","94","107","124","757","758") "Classic external pet exclusions"
Assert-IDValues @($petInventory|Where-Object release_decision -eq "exclude_cross_expansion"|ForEach-Object species_id) @("266","277","309","310") "Classic cross-expansion pet exclusions"
Assert-IDValues @($toyInventory|Where-Object release_decision -eq "exclude_cross_expansion"|ForEach-Object item_id) @("64358","64361","64373","64383","64488","64646","64651","69776","69777","88566") "Classic cross-expansion toy exclusions"
Assert-IDValues @($achievementInventory.achievement_id+$achievementManifest.achievement_id) @($achievementManifest.achievement_id) "Classic achievement inventory exactness"
Assert-IDValues @($achievementManifest|Where-Object achievement_id -in @("858","859","860","861","868","4908","4926")|ForEach-Object achievement_id) @() "TBC starter-zone achievement exclusions"

$housingAudit=Read-Rows (Join-Path $sourceRoot "housing-wowdb-acquisition-audit.csv");$housingTheme=Read-Rows (Join-Path $sourceRoot "housing-wowdb-theme-catalog.csv");$housingExclusions=Read-Rows (Join-Path $sourceRoot "housing-wowdb-theme-exclusions.csv");$housingGlobal=Read-Rows (Join-Path $sourceRoot "housing-wowdb-global-acquisition-crosscheck.csv")
if($housingAudit.Count-ne22-or$housingTheme.Count-ne53-or$housingExclusions.Count-ne34-or$housingGlobal.Count-ne56){throw "Classic housing audit row counts changed"}
Assert-IDValues $housingAudit.decor_id $decorManifest.decor_id "Classic housing manifest ownership"
Assert-IDValues @($housingGlobal|Where-Object status -eq "acquisition_classic_confirmed"|ForEach-Object decor_id) $decorManifest.decor_id "Classic global housing ownership"
Assert-IDValues $housingExclusions.decor_id @("129","518","725","923","924","1183","1252","1281","1674","1998","2018","2226","2228","2229","2238","2239","2241","2242","2243","2333","2334","3888","3899","3906","3907","8982","9249","11433","11722","11893","17889","20170","21857","27047") "Classic themed housing exclusions"
Assert-IDValues @($decorManifest|Where-Object catalog_scope -eq "global_acquisition_match"|ForEach-Object decor_id) @("1119","2465","11274") "Non-themed Classic decorations"

Assert-IDValues $mapManifest.map_id @("1","7","10","12","13","14","15","17","18","21","22","23","25","26","27","32","36","37","42","47","48","49","50","51","52","56","57","62","63","64","65","66","69","70","71","76","77","78","80","81","83","84","85","87","88","89","90","91","92","93","199","224") "Classic supporting map IDs"
Assert-IDValues $factionManifest.faction_id @("21","47","54","59","68","69","70","72","76","81","87","92","93","270","349","369","470","509","510","529","530","576","577","589","609","729","730","749","809","889","890","909","910") "Classic supporting faction IDs"
Assert-IDValues $currencyManifest.currency_id @("121","122","125","1166","1792") "Classic supporting currency IDs"

$laterExpansions=@(@{name="TBC";root=$TbcManifestRoot},@{name="Wrath";root=$WrathManifestRoot},@{name="Cataclysm";root=$CataclysmManifestRoot},@{name="MoP";root=$MopManifestRoot},@{name="WOD";root=$WodManifestRoot},@{name="Legion";root=$LegionManifestRoot},@{name="BFA";root=$BfaManifestRoot},@{name="Shadowlands";root=$ShadowlandsManifestRoot},@{name="Dragonflight";root=$DragonflightManifestRoot},@{name="TWW";root=$TwwManifestRoot})
foreach($spec in @(@{name="mounts";field="mount_id"},@{name="pets";field="species_id"},@{name="toys";field="toy_id"},@{name="toys";field="item_id"},@{name="decorations";field="decor_id"},@{name="achievements";field="achievement_id"},@{name="recipes";field="recipe_spell_id"})){$classicIDs=Get-IDs (Read-Rows (Join-Path $manifestRoot "$($spec.name).csv")) $spec.field;foreach($later in $laterExpansions){$laterIDs=Get-IDs (Read-Rows (Join-Path $later.root "$($spec.name).csv")) $spec.field;$overlap=@($classicIDs|Where-Object{$_-in$laterIDs});Assert-IDValues $overlap @() "Classic/$($later.name) $($spec.name) $($spec.field) overlap"}}

$summary=Read-Rows (Join-Path $manifestRoot "summary.csv");if($summary.Count-ne12){throw "Classic manifest summary row count mismatch"};$summary|Format-Table -AutoSize
Write-Host "Collectionist Classic manifest validation passed"
