param(
    [string]$HistoricalRoot = (Join-Path $env:TEMP "collectionist-legion-db2\legion"),
    [string]$ClassicEraRoot = (Join-Path $env:TEMP "collectionist-classic-era-db2"),
    [string]$CurrentDb2Root = (Join-Path $env:TEMP "collectionist-tww-db2\current"),
    [string]$CurrentSupportDb2Root = (Join-Path $env:TEMP "collectionist-df-db2\current"),
    [string]$AttRoot = (Join-Path $env:TEMP "collectionist-att-12007"),
    [string]$OutputRoot = (Join-Path $PSScriptRoot "..\research\collectionist\classic\ids"),
    [string]$ManifestRoot = (Join-Path $PSScriptRoot "..\research\collectionist\classic\manifests")
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "collectionist-current-criteria.ps1")
$decorAuditPath = Join-Path $PSScriptRoot "..\research\collectionist\classic\sources\housing-wowdb-acquisition-audit.csv"
$attDataRoot = Join-Path $AttRoot ".contrib\Parser\DATAS"
$attMountDbPath = Join-Path $attDataRoot "00 - DB\MountDB.lua"
$attPetDbPath = Join-Path $attDataRoot "00 - DB\PetDB.lua"
$attToyDbPath = Join-Path $attDataRoot "00 - DB\ToyDB.lua"

foreach ($required in @($HistoricalRoot,$ClassicEraRoot,$CurrentDb2Root,$CurrentSupportDb2Root,$AttRoot,$decorAuditPath,$attMountDbPath,$attPetDbPath,$attToyDbPath)) {
    if (-not (Test-Path -LiteralPath $required)) { throw "Missing input: $required" }
}
New-Item -ItemType Directory -Force -Path $OutputRoot | Out-Null
New-Item -ItemType Directory -Force -Path $ManifestRoot | Out-Null

function Read-Table([string]$Root,[string]$Name) { $path=Join-Path $Root "$Name.csv";if(-not(Test-Path -LiteralPath $path)){throw "Missing DB2 table: $path"};return @(Import-Csv -LiteralPath $path) }
function New-Index($Rows,[string]$Field="ID") { $index=@{};foreach($row in $Rows){$index[[string]$row.$Field]=$row};return $index }
function New-IDSet($Rows,[string]$Field="ID") { $set=@{};foreach($row in $Rows){$set[[string]$row.$Field]=$true};return $set }
function Join-IDs($Values) { return (@($Values|Where-Object{$_}|Sort-Object -Unique)-join ";") }
function Get-OrderPathSortKey([string]$Path) { return ((@($Path-split "/")|ForEach-Object{"{0:D8}"-f[int]$_})-join "/") }
function Write-CsvFile([string]$Path,$Rows) { $lines=@($Rows)|ConvertTo-Csv -NoTypeInformation;$text=if($lines.Count){($lines-join"`n")+"`n"}else{""};[IO.File]::WriteAllText($Path,$text.Replace("`r`n","`n").Replace("`r","`n"),[Text.UTF8Encoding]::new($false)) }
function Export-Inventory([string]$Name,$Rows) { Write-CsvFile (Join-Path $OutputRoot "$Name.csv") @($Rows);return [pscustomobject]@{file=$Name;rows=@($Rows).Count} }
function Assert-Equal($Actual,$Expected,[string]$Label) { if([int]$Actual-ne[int]$Expected){throw "$Label mismatch: expected $Expected, got $Actual"} }
function Assert-UniqueField($Rows,[string]$Field,[string]$Label) { $duplicates=@($Rows|Group-Object $Field|Where-Object Count -gt 1);if($duplicates.Count){throw "$Label contains duplicate ${Field}: $($duplicates.Name-join', ')"} }
function Assert-IDValues($ActualValues,$ExpectedValues,[string]$Label) { $actual=@($ActualValues|ForEach-Object{[string]$_}|Where-Object{$_}|Sort-Object -Unique);$expected=@($ExpectedValues|ForEach-Object{[string]$_}|Where-Object{$_}|Sort-Object -Unique);$missing=@($expected|Where-Object{$_-notin$actual});$extra=@($actual|Where-Object{$_-notin$expected});if($missing.Count-or$extra.Count){throw "$Label mismatch: missing [$($missing-join', ')], extra [$($extra-join', ')]"} }

$historicalAchievements=Read-Table $HistoricalRoot "Achievement"
$historicalAchievementCategories=Read-Table $HistoricalRoot "Achievement_Category"
$historicalCriteria=Read-Table $HistoricalRoot "Criteria"
$historicalCriteriaTrees=Read-Table $HistoricalRoot "CriteriaTree"
$classicRecipeSpellIDs=New-IDSet (Read-Table $ClassicEraRoot "SkillLineAbility") "Spell"

$currentMounts=Read-Table $CurrentDb2Root "Mount"
$currentPets=Read-Table $CurrentDb2Root "BattlePetSpecies"
$currentToys=Read-Table $CurrentDb2Root "Toy"
$currentCreatures=Read-Table $CurrentDb2Root "Creature"
$currentTradeCategories=Read-Table $CurrentDb2Root "TradeSkillCategory"
$currentTradeAbilities=Read-Table $CurrentDb2Root "SkillLineAbility"
$currentSpellNames=Read-Table $CurrentDb2Root "SpellName"
$currentItems=New-Index (Read-Table $CurrentDb2Root "ItemSparse")
$currentAchievements=Read-Table $CurrentSupportDb2Root "Achievement"
$currentCurrencies=Read-Table $CurrentSupportDb2Root "CurrencyTypes"
$currentFactions=Read-Table $CurrentSupportDb2Root "Faction"
$currentMaps=Read-Table $CurrentSupportDb2Root "UiMap"

$currentMountByID=New-Index $currentMounts;$currentMountBySpell=New-Index $currentMounts "SourceSpellID"
$currentPetByID=New-Index $currentPets;$currentToyByItem=New-Index $currentToys "ItemID"
$creatureByID=New-Index $currentCreatures;$currentAchievementIDs=New-IDSet $currentAchievements
$currentCurrencyIDs=New-IDSet $currentCurrencies;$currentFactionIDs=New-IDSet $currentFactions
$currentMapByID=New-Index $currentMaps;$currentSpellNameByID=New-Index $currentSpellNames
$historicalAchievementCategoryByID=New-Index $historicalAchievementCategories

# ATT's VANILLA block is the chronology boundary. Its NYI subsection is kept in
# the audit inventory but never promoted to the release manifest.
$mountRows=@();$active=$false;$nyi=$false
foreach($line in Get-Content -LiteralPath $attMountDbPath){
    if($line-match"^--\s+VANILLA\s+--"){$active=$true;continue}
    if($line-match"^-- PATCH 2\.0\.0 --"){$active=$false}
    if(-not$active){continue}
    if($line-match"^--- NYI ---"){$nyi=$true;continue}
    if($line-match"^i\((\d+),\s*(\d+)\);\s*--\s*(.*)$"){$mount=$currentMountBySpell[$Matches[2]];$mountRows+=[pscustomobject]@{item_id=$Matches[1];source_spell_id=$Matches[2];source_name=$Matches[3];nyi=$nyi;mount=$mount}}
}
Assert-Equal $mountRows.Count 120 "ATT Classic mount row count"
Assert-Equal @($mountRows|Where-Object mount).Count 100 "ATT Classic current mapped mount row count"
$mountGroups=@($mountRows|Where-Object mount|Group-Object{[string]$_.mount.ID})
Assert-Equal $mountGroups.Count 99 "ATT Classic current mount candidate count"
$mountInventory=foreach($group in $mountGroups|Sort-Object{[int]$_.Name}){
    $rows=@($group.Group);$mount=$rows[0].mount;$isNYI=-not[bool]@($rows|Where-Object{-not$_.nyi}).Count
    $decision=if($isNYI){"exclude_unobtainable_or_internal"}else{"include_classic"}
    [pscustomobject]@{status=if($decision -eq "include_classic"){"classic_boundary_confirmed"}else{$decision};release_decision=$decision;acquisition_expansion=if($decision -eq "include_classic"){"classic"}else{""};unavailable=$false;availability_note="";current_exists=$true;mount_id=$mount.ID;name=$mount.Name_lang;source_spell_id=$mount.SourceSpellID;source_type_enum=$mount.SourceTypeEnum;flags=$mount.Flags;source_text=$mount.SourceText_lang;original_item_ids=Join-IDs @($rows.item_id);att_nyi=$isNYI}
}

$petItemToSpecies=@{}
foreach($line in Get-Content -LiteralPath $attPetDbPath){if($line-match"^i\((\d+),\s*(\d+)\);"){$petItemToSpecies[$Matches[1]]=$Matches[2]}}
$petRows=@();$active=$false;$nyi=$false
foreach($line in Get-Content -LiteralPath $attPetDbPath){
    if($line-match"^--\s+CLASSIC\s+--"){$active=$true;continue}
    if($line-match"^-- PATCH 2\.0\.5 --"){$active=$false}
    if(-not$active){continue}
    if($line-match"^--- NYI ---"){$nyi=$true;continue}
    if($line-match"^i\((\d+),\s*(\d+)\);\s*--\s*(.*)$"){$petRows+=[pscustomobject]@{item_id=$Matches[1];species_id=$Matches[2];source_name=$Matches[3];nyi=$nyi}}
}
Assert-Equal $petRows.Count 58 "ATT Classic pet row count"
$petPatchByID=@{}
foreach($group in @($petRows|Where-Object{$_.species_id -ne "0"}|Group-Object species_id)){if($currentPetByID.ContainsKey([string]$group.Name)){$petPatchByID[[string]$group.Name]=@($group.Group)}}
Assert-Equal $petPatchByID.Count 54 "ATT Classic current pet candidate count"

$classicSourceRoots=@(
    (Join-Path $attDataRoot "01 - Dungeons Raids\01 - Classic"),
    (Join-Path $attDataRoot "03 - World Drops\01 Rooted\1 - Classic.lua"),
    (Join-Path $attDataRoot "08 - PvP\01 Classic PvP.lua"),
    (Join-Path $attDataRoot "09 - Crafted Items\01 - Classic.lua")
)
$petSourceTreeIDs=@{};$toySourceTreeItems=@{}
foreach($root in $classicSourceRoots){
    $source=Get-Item -LiteralPath $root;$files=if($source.PSIsContainer){@(Get-ChildItem -LiteralPath $root -Recurse -File -Filter "*.lua")}else{@($source)}
    foreach($file in $files){foreach($line in Get-Content -LiteralPath $file.FullName){
        foreach($match in [regex]::Matches($line,"\bi\((\d+)")){$itemID=$match.Groups[1].Value;$speciesID=$petItemToSpecies[$itemID];if($speciesID-and$currentPetByID.ContainsKey([string]$speciesID)){$petSourceTreeIDs[[string]$speciesID]=$true};if($currentToyByItem.ContainsKey($itemID)){$toySourceTreeItems[$itemID]=$true}}
        foreach($match in [regex]::Matches($line,"\bp\((\d+)")){$speciesID=$match.Groups[1].Value;if($currentPetByID.ContainsKey([string]$speciesID)){$petSourceTreeIDs[[string]$speciesID]=$true}}
    }}
}
Assert-Equal $petSourceTreeIDs.Count 27 "ATT Classic source-tree pet candidate count"
$petCandidateIDs=@($petPatchByID.Keys+$petSourceTreeIDs.Keys|Sort-Object -Unique)
Assert-Equal $petCandidateIDs.Count 70 "Classic pet inventory candidate count"
$petExternalIDs=@("92","93","94","107","124","757","758")
$petCataclysmIDs=@("266","277","309","310")
$petInventory=foreach($id in $petCandidateIDs|Sort-Object{[int]$_}){
    $pet=$currentPetByID[$id];$creature=$creatureByID[[string]$pet.CreatureID];$patchRows=@($petPatchByID[$id])
    $decision=if($id-in$petExternalIDs){"exclude_policy_external"}elseif($id-in$petCataclysmIDs){"exclude_cross_expansion"}else{"include_classic"}
    [pscustomobject]@{status=if($decision -eq "include_classic"){"classic_acquisition_confirmed"}else{$decision};release_decision=$decision;acquisition_expansion=if($decision -eq "include_classic"){"classic"}elseif($id -in $petCataclysmIDs){"cataclysm"}else{""};unavailable=$false;availability_note="";current_exists=$true;classic_source_tree_match=$petSourceTreeIDs.ContainsKey($id);att_patch_match=$petPatchByID.ContainsKey($id);species_id=$pet.ID;name=if($creature){$creature.Name_lang}else{""};creature_id=$pet.CreatureID;summon_spell_id=$pet.SummonSpellID;pet_type_enum=$pet.PetTypeEnum;flags=$pet.Flags;source_type_enum=$pet.SourceTypeEnum;source_text=$pet.SourceText_lang;original_item_ids=Join-IDs @($patchRows.item_id);att_nyi=[bool]@($patchRows|Where-Object nyi).Count}
}

$toyRows=@();$active=$false;$seasonal=$false
foreach($line in Get-Content -LiteralPath $attToyDbPath){
    if($line-match"^--\s+CLASSIC\s+--"){$active=$true;continue}
    if($line-match"^-- PATCH 2\.0\.1 --"){$active=$false}
    if($active-and$line-match"^-- #if SEASON_OF_DISCOVERY"){$seasonal=$true;continue}
    if($active-and$seasonal-and$line-match"^-- #endif"){$seasonal=$false;continue}
    if($active-and-not$seasonal-and$line-match"^i\((\d+)\);\s*--\s*(.*)$"){$toyRows+=[pscustomobject]@{item_id=$Matches[1];source_name=$Matches[2];source_boundary="att_classic"}}
}
Assert-Equal $toyRows.Count 8 "ATT Classic toy row count"
foreach($itemID in $toySourceTreeItems.Keys){if($itemID-notin$toyRows.item_id){$item=$currentItems[$itemID];$toyRows+=[pscustomobject]@{item_id=$itemID;source_name=if($item){$item.Display_lang}else{""};source_boundary="att_classic_source_tree"}}}
Assert-Equal $toyRows.Count 20 "Classic toy inventory candidate count"
$toyCataclysmItems=@("64358","64361","64373","64383","64488","64646","64651","69776","69777")
$toyMopItems=@("88566")
$toyInventory=foreach($candidate in $toyRows|Sort-Object{[int]$_.item_id}){
    $itemID=[string]$candidate.item_id;$toy=$currentToyByItem[$itemID];if(-not$toy){throw "Missing current Classic toy item $itemID"};$item=$currentItems[$itemID]
    $decision=if($itemID-in$toyCataclysmItems-or$itemID-in$toyMopItems){"exclude_cross_expansion"}else{"include_classic"}
    [pscustomobject]@{status=if($decision -eq "include_classic"){"classic_source_confirmed"}else{$decision};release_decision=$decision;acquisition_expansion=if($decision -eq "include_classic"){"classic"}elseif($itemID -in $toyCataclysmItems){"cataclysm"}else{"mists_of_pandaria"};unavailable=$false;current_exists=$true;toy_id=$toy.ID;item_id=$toy.ItemID;name=if($item){$item.Display_lang}else{$candidate.source_name};source_boundary=$candidate.source_boundary;source_type_enum=$toy.SourceTypeEnum;flags=$toy.Flags;source_text=$toy.SourceText_lang}
}

$classicAchievementCategoryIDs=@("14777","14778","14801","14802","14804","14808","14821","14861","14864","15081")
$tbcAchievementIDs=@("858","859","860","861","868","4908","4926")
$selectedAchievements=@($historicalAchievements|Where-Object{[string]$_.Category-in$classicAchievementCategoryIDs-and[string]$_.ID-notin$tbcAchievementIDs})
$achievementInventory=foreach($achievement in $selectedAchievements){$category=$historicalAchievementCategoryByID[[string]$achievement.Category];[pscustomobject]@{status="classic_category_confirmed";current_exists=$currentAchievementIDs.ContainsKey([string]$achievement.ID);achievement_id=$achievement.ID;title=$achievement.Title_lang;description=$achievement.Description_lang;category_id=$achievement.Category;category_name=if($category){$category.Name_lang}else{$null};criteria_tree_id=$achievement.Criteria_tree;flags=$achievement.Flags;points=$achievement.Points}}
$criteriaByID=New-Index $historicalCriteria;$criteriaChildren=@{}
foreach($node in $historicalCriteriaTrees){if(-not$criteriaChildren.ContainsKey([string]$node.Parent)){$criteriaChildren[[string]$node.Parent]=[Collections.Generic.List[object]]::new()};$criteriaChildren[[string]$node.Parent].Add($node)}
function Get-CriteriaLeaves([string]$RootID){if(-not $RootID -or $RootID -eq "0"){return};$queue=[Collections.Generic.Queue[object]]::new();$queue.Enqueue(@($RootID,""));while($queue.Count){$pair=$queue.Dequeue();foreach($node in @($criteriaChildren[[string]$pair[0]]|Sort-Object{[int]$_.OrderIndex})){$path=if($pair[1]){"$($pair[1])/$($node.OrderIndex)"}else{[string]$node.OrderIndex};if($node.CriteriaID -ne "0"){$criterion=$criteriaByID[[string]$node.CriteriaID];[pscustomobject]@{order_path=$path;tree_id=$node.ID;description=$node.Description_lang;criteria_id=$node.CriteriaID;criteria_type=if($criterion){$criterion.Type}else{$null};asset_id=if($criterion){$criterion.Asset}else{$null};amount=$node.Amount;operator=$node.Operator}}else{$queue.Enqueue(@([string]$node.ID,$path))}}}}
$achievementCriteriaInventory=foreach($achievement in $selectedAchievements|Where-Object Criteria_tree -ne "0"){foreach($leaf in Get-CriteriaLeaves([string]$achievement.Criteria_tree)){[pscustomobject]@{achievement_id=$achievement.ID;title=$achievement.Title_lang;category_id=$achievement.Category;order_path=$leaf.order_path;tree_id=$leaf.tree_id;description=$leaf.description;criteria_id=$leaf.criteria_id;criteria_type=$leaf.criteria_type;asset_id=$leaf.asset_id;amount=$leaf.amount;operator=$leaf.operator}}}
$achievementCriteriaInventory=@(Sync-CollectionistAchievementCriteria $achievementCriteriaInventory $CurrentDb2Root)
$rareInventory=@();$treasureInventory=@()

$tradeCategoryChildren=@{};$tradeCategoryByID=New-Index $currentTradeCategories
foreach($category in $currentTradeCategories){$parent=[string]$category.ParentTradeSkillCategoryID;if(-not$tradeCategoryChildren.ContainsKey($parent)){$tradeCategoryChildren[$parent]=[Collections.Generic.List[string]]::new()};$tradeCategoryChildren[$parent].Add([string]$category.ID)}
$classicTradeRoots=@("603","589","72","666","720","770","816","874","957")
$allowedTradeCategories=@{};$tradeQueue=[Collections.Generic.Queue[string]]::new();foreach($root in $classicTradeRoots){$tradeQueue.Enqueue($root)}
while($tradeQueue.Count){$id=$tradeQueue.Dequeue();if($allowedTradeCategories.ContainsKey($id)){continue};$allowedTradeCategories[$id]=$true;foreach($child in @($tradeCategoryChildren[$id])){$tradeQueue.Enqueue($child)}}
$houseDecorTradeCategories=@{};foreach($id in $allowedTradeCategories.Keys){if($tradeCategoryByID[$id] -and $tradeCategoryByID[$id].Name_lang -eq "House Decor"){$houseDecorTradeCategories[$id]=$true}}
$professionNames=@{"171"="Alchemy";"164"="Blacksmithing";"185"="Cooking";"333"="Enchanting";"202"="Engineering";"773"="Inscription";"755"="Jewelcrafting";"165"="Leatherworking";"197"="Tailoring"}
$recipeInventory=foreach($ability in $currentTradeAbilities|Where-Object{$allowedTradeCategories.ContainsKey([string]$_.TradeSkillCategoryID)-and($classicRecipeSpellIDs.ContainsKey([string]$_.Spell)-or$houseDecorTradeCategories.ContainsKey([string]$_.TradeSkillCategoryID))}){$spell=$currentSpellNameByID[[string]$ability.Spell];$category=$tradeCategoryByID[[string]$ability.TradeSkillCategoryID];[pscustomobject]@{status="named_recipe";current_ability_exists=$true;current_spell_name_exists=[bool]($spell-and$spell.Name_lang);profession=$professionNames[[string]$ability.SkillLine];profession_id=$ability.SkillLine;recipe_spell_id=$ability.Spell;name=if($spell){$spell.Name_lang}else{$null};skill_line_ability_id=$ability.ID;trade_category_id=$ability.TradeSkillCategoryID;trade_category_name=if($category){$category.Name_lang}else{$null};house_decor_recipe=$houseDecorTradeCategories.ContainsKey([string]$ability.TradeSkillCategoryID);acquire_method=$ability.AcquireMethod;supercedes_spell_id=$ability.SupercedesSpell}}
$decorInventory=foreach($row in Import-Csv -LiteralPath $decorAuditPath){[pscustomobject]@{status=$row.status;current_exists=$true;decor_id=$row.decor_id;item_id=$row.item_id;name=$row.catalog_name;catalog_scope=$row.catalog_scope;acquisition_expansion=$row.acquisition_expansion;source_kind=$row.source_kind;source_text=$row.source_text;achievement_ids=$row.achievement_ids;quest_ids=$row.quest_ids;npc_ids=$row.npc_ids;source_spell_ids=$row.source_spell_ids;currency_ids=$row.currency_ids;acquisition_source_url=$row.acquisition_source_url}}

$mapIDs=@("1","7","10","12","13","14","15","17","18","21","22","23","25","26","27","32","36","37","42","47","48","49","50","51","52","56","57","62","63","64","65","66","69","70","71","76","77","78","80","81","83","84","85","87","88","89","90","91","92","93","199","224")
$mapInventory=foreach($id in $mapIDs){$map=$currentMapByID[$id];if(-not$map){throw "Missing current Classic map $id"};[pscustomobject]@{status="classic_support_confirmed";current_exists=$true;map_id=$map.ID;name=$map.Name_lang;parent_map_id=$map.ParentUiMapID;map_type=$map.Type;flags=$map.Flags}}
$factionNames=@{
    "21"="Booty Bay";"47"="Ironforge";"54"="Gnomeregan";"59"="Thorium Brotherhood";"68"="Undercity";"69"="Darnassus";"70"="Syndicate";"72"="Stormwind";"76"="Orgrimmar";"81"="Thunder Bluff";"87"="Bloodsail Buccaneers";"92"="Gelkis Clan Centaur";"93"="Magram Clan Centaur";"270"="Zandalar Tribe";"349"="Ravenholdt";"369"="Gadgetzan";"470"="Ratchet";"509"="The League of Arathor";"510"="The Defilers";"529"="Argent Dawn";"530"="Darkspear Trolls";"576"="Timbermaw Hold";"577"="Everlook";"589"="Wintersaber Trainers";"609"="Cenarion Circle";"729"="Frostwolf Clan";"730"="Stormpike Guard";"749"="Hydraxian Waterlords";"809"="Shen'dralar";"889"="Warsong Outriders";"890"="Silverwing Sentinels";"909"="Darkmoon Faire";"910"="Brood of Nozdormu"
}
$currentFactionByID=New-Index $currentFactions
$factionInventory=foreach($id in $factionNames.Keys|Sort-Object{[int]$_}){$f=$currentFactionByID[$id];if(-not$f){throw "Missing current Classic faction $id"};if($f.Name_lang-ne$factionNames[$id]){throw "Classic faction $id name mismatch: '$($f.Name_lang)'"};[pscustomobject]@{status="classic_support_confirmed";current_exists=$currentFactionIDs.ContainsKey($id);faction_id=$f.ID;name=$f.Name_lang;parent_faction_id=$f.ParentFactionID}}
$currencyNames=@{"121"="Alterac Valley Mark of Honor";"122"="Arathi Basin Mark of Honor";"125"="Warsong Gulch Mark of Honor";"1166"="Timewarped Badge";"1792"="Honor"}
$currentCurrencyByID=New-Index $currentCurrencies
$currencyInventory=foreach($id in $currencyNames.Keys|Sort-Object{[int]$_}){$c=$currentCurrencyByID[$id];if(-not$c){throw "Missing current Classic currency $id"};if($c.Name_lang-ne$currencyNames[$id]){throw "Classic currency $id name mismatch: '$($c.Name_lang)'"};[pscustomobject]@{status="classic_support_confirmed";current_exists=$currentCurrencyIDs.ContainsKey($id);currency_id=$c.ID;name=$c.Name_lang;category_id=$c.CategoryID;flags=$c.Flags}}

Assert-Equal $mountInventory.Count 99 "Classic mount inventory count";Assert-Equal @($mountInventory|Where-Object release_decision -eq "include_classic").Count 85 "Classic mount manifest count"
Assert-Equal $petInventory.Count 70 "Classic pet inventory count";Assert-Equal @($petInventory|Where-Object release_decision -eq "include_classic").Count 59 "Classic pet manifest count"
Assert-Equal $toyInventory.Count 20 "Classic toy inventory count";Assert-Equal @($toyInventory|Where-Object release_decision -eq "include_classic").Count 10 "Classic toy manifest count"
Assert-Equal $decorInventory.Count 22 "Classic decoration inventory count"
Assert-Equal $achievementInventory.Count 199 "Classic achievement inventory count";Assert-Equal $achievementCriteriaInventory.Count 1268 "Classic achievement criteria inventory count"
Assert-Equal $recipeInventory.Count 1223 "Classic recipe inventory count";Assert-Equal @($recipeInventory|Where-Object house_decor_recipe).Count 19 "Classic house decor recipe count"
Assert-Equal $mapInventory.Count 52 "Classic map count";Assert-Equal $factionInventory.Count 33 "Classic faction count";Assert-Equal $currencyInventory.Count 5 "Classic currency count"
Assert-Equal @($achievementInventory|Where-Object{-not$_.current_exists}).Count 0 "Classic missing current achievement count";Assert-Equal @($recipeInventory|Where-Object{-not$_.current_spell_name_exists}).Count 0 "Classic unnamed recipe count"
$taskAchievementIDs=@($achievementCriteriaInventory|Group-Object achievement_id|Where-Object{$_.Count-ge2-and$_.Count-le30}|ForEach-Object Name)
Assert-Equal $taskAchievementIDs.Count 115 "Classic eligible task achievement count";Assert-Equal @($achievementCriteriaInventory|Where-Object{[string]$_.achievement_id-in$taskAchievementIDs}).Count 1149 "Classic eligible task criteria count"

$summary=@();$summary+=Export-Inventory "mounts" $mountInventory;$summary+=Export-Inventory "pets" $petInventory;$summary+=Export-Inventory "toys" $toyInventory;$summary+=Export-Inventory "decorations" $decorInventory;$summary+=Export-Inventory "achievements" $achievementInventory;$summary+=Export-Inventory "achievement-criteria" @($achievementCriteriaInventory|Sort-Object{[int]$_.achievement_id},{Get-OrderPathSortKey $_.order_path});$summary+=Export-Inventory "rares" $rareInventory;$summary+=Export-Inventory "treasures" $treasureInventory;$summary+=Export-Inventory "recipes" @($recipeInventory|Sort-Object profession,{[int]$_.recipe_spell_id});$summary+=Export-Inventory "maps" $mapInventory;$summary+=Export-Inventory "factions" $factionInventory;$summary+=Export-Inventory "currencies" $currencyInventory;Write-CsvFile (Join-Path $OutputRoot "summary.csv") $summary
$manifests=[ordered]@{
    mounts=@{rows=@($mountInventory|Where-Object release_decision -eq "include_classic"|Sort-Object{[int]$_.mount_id});expected=85;id="mount_id"};pets=@{rows=@($petInventory|Where-Object release_decision -eq "include_classic"|Sort-Object{[int]$_.species_id});expected=59;id="species_id"};toys=@{rows=@($toyInventory|Where-Object release_decision -eq "include_classic"|Sort-Object{[int]$_.toy_id});expected=10;id="toy_id"};decorations=@{rows=@($decorInventory|Sort-Object{[int]$_.decor_id});expected=22;id="decor_id"};achievements=@{rows=@($achievementInventory|Sort-Object{[int]$_.achievement_id});expected=199;id="achievement_id"};"achievement-criteria"=@{rows=@($achievementCriteriaInventory|Sort-Object{[int]$_.achievement_id},{Get-OrderPathSortKey $_.order_path});expected=1268;id="tree_id"};recipes=@{rows=@($recipeInventory|Sort-Object profession,{[int]$_.recipe_spell_id});expected=1223;id="recipe_spell_id"};rares=@{rows=$rareInventory;expected=0;id="tree_id"};treasures=@{rows=$treasureInventory;expected=0;id="tree_id"};"supporting-maps"=@{rows=$mapInventory;expected=52;id="map_id"};"supporting-factions"=@{rows=$factionInventory;expected=33;id="faction_id"};"supporting-currencies"=@{rows=$currencyInventory;expected=5;id="currency_id"}
}
$manifestSummary=@();foreach($name in $manifests.Keys){$entry=$manifests[$name];Assert-Equal @($entry.rows).Count $entry.expected "Classic $name manifest";Assert-UniqueField @($entry.rows) $entry.id "Classic $name manifest";Write-CsvFile (Join-Path $ManifestRoot "$name.csv") @($entry.rows);$manifestSummary+=[pscustomobject]@{manifest=$name;rows=@($entry.rows).Count;identifier=$entry.id}};Write-CsvFile (Join-Path $ManifestRoot "summary.csv") $manifestSummary
Write-Host "Generated Collectionist Classic ID inventory";$summary|Format-Table -AutoSize;Write-Host "Release manifests";$manifestSummary|Format-Table -AutoSize
