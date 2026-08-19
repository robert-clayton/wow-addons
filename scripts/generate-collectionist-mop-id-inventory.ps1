param(
    [string]$HistoricalRoot = (Join-Path $env:TEMP "collectionist-legion-db2\legion"),
    [string]$MopClassicRoot = (Join-Path $env:TEMP "collectionist-mop-classic-db2"),
    [string]$CurrentDb2Root = (Join-Path $env:TEMP "collectionist-df-db2\current"),
    [string]$CurrentTradeDb2Root = (Join-Path $env:TEMP "collectionist-tww-db2\current"),
    [string]$BlizzardCaptureJson = (Join-Path $env:TEMP "collectionist-mop-blizzard-tables.json"),
    [string]$OutputRoot = (Join-Path $PSScriptRoot "..\research\collectionist\mists-of-pandaria\ids"),
    [string]$ManifestRoot = (Join-Path $PSScriptRoot "..\research\collectionist\mists-of-pandaria\manifests")
)

$ErrorActionPreference = "Stop"
$decorAuditPath = Join-Path $PSScriptRoot "..\research\collectionist\mists-of-pandaria\sources\housing-wowdb-acquisition-audit.csv"
$blizzardSourcePath = Join-Path $PSScriptRoot "..\research\collectionist\mists-of-pandaria\sources\blizzard-mop-collectibles.csv"

foreach ($required in @($HistoricalRoot, $MopClassicRoot, $CurrentDb2Root, $CurrentTradeDb2Root, $BlizzardCaptureJson, $decorAuditPath)) {
    if (-not (Test-Path -LiteralPath $required)) { throw "Missing input: $required" }
}
New-Item -ItemType Directory -Force -Path $OutputRoot | Out-Null
New-Item -ItemType Directory -Force -Path $ManifestRoot | Out-Null

function Read-Table([string]$Root, [string]$Name) {
    $path = Join-Path $Root "$Name.csv"
    if (-not (Test-Path -LiteralPath $path)) { throw "Missing DB2 table: $path" }
    return @(Import-Csv -LiteralPath $path)
}
function New-Index($Rows, [string]$Field = "ID") {
    $index = @{}
    foreach ($row in $Rows) { $index[[string]$row.$Field] = $row }
    return $index
}
function New-IDSet($Rows, [string]$Field = "ID") {
    $set = @{}
    foreach ($row in $Rows) { $set[[string]$row.$Field] = $true }
    return $set
}
function Join-IDs($Values) { return (@($Values | Where-Object { $_ } | Sort-Object -Unique) -join ";") }
function Get-OrderPathSortKey([string]$Path) { return ((@($Path -split "/") | ForEach-Object { "{0:D8}" -f [int]$_ }) -join "/") }
function Write-CsvFile([string]$Path, $Rows) {
    $lines = @($Rows) | ConvertTo-Csv -NoTypeInformation
    $text = if ($lines.Count) { ($lines -join "`n") + "`n" } else { "" }
    [System.IO.File]::WriteAllText($Path, $text.Replace("`r`n", "`n").Replace("`r", "`n"), [System.Text.UTF8Encoding]::new($false))
}
function Export-Inventory([string]$Name, $Rows) {
    Write-CsvFile (Join-Path $OutputRoot "$Name.csv") @($Rows)
    return [pscustomobject]@{ file=$Name; rows=@($Rows).Count }
}
function Assert-Equal($Actual, $Expected, [string]$Label) {
    if ([int]$Actual -ne [int]$Expected) { throw "$Label mismatch: expected $Expected, got $Actual" }
}
function Assert-UniqueField($Rows, [string]$Field, [string]$Label) {
    $duplicates = @($Rows | Group-Object $Field | Where-Object Count -gt 1)
    if ($duplicates.Count) { throw "$Label contains duplicate ${Field}: $($duplicates.Name -join ', ')" }
}
function Assert-IDValues($ActualValues, $ExpectedValues, [string]$Label) {
    $actual = @($ActualValues | ForEach-Object { [string]$_ } | Sort-Object -Unique)
    $expected = @($ExpectedValues | ForEach-Object { [string]$_ } | Sort-Object -Unique)
    $missing = @($expected | Where-Object { $_ -notin $actual })
    $extra = @($actual | Where-Object { $_ -notin $expected })
    if ($missing.Count -or $extra.Count) { throw "$Label mismatch: missing [$($missing -join ', ')], extra [$($extra -join ', ')]" }
}

$mounts = Read-Table $HistoricalRoot "Mount"
$achievements = Read-Table $HistoricalRoot "Achievement"
$achievementCategories = Read-Table $HistoricalRoot "Achievement_Category"
$criteriaRows = Read-Table $HistoricalRoot "Criteria"
$criteriaTreeRows = Read-Table $HistoricalRoot "CriteriaTree"
$historicalCurrencies = Read-Table $HistoricalRoot "CurrencyTypes"
$historicalFactions = Read-Table $HistoricalRoot "Faction"

$currentMounts = Read-Table $CurrentDb2Root "Mount"
$currentPets = Read-Table $CurrentDb2Root "BattlePetSpecies"
$currentToys = Read-Table $CurrentDb2Root "Toy"
$currentAchievements = Read-Table $CurrentDb2Root "Achievement"
$currentCurrencies = Read-Table $CurrentDb2Root "CurrencyTypes"
$currentFactions = Read-Table $CurrentDb2Root "Faction"
$currentMaps = Read-Table $CurrentDb2Root "UiMap"
$currentCreatures = Read-Table $CurrentDb2Root "Creature"
$currentItemEffects = New-Index (Read-Table $CurrentTradeDb2Root "ItemEffect")
$currentItemRelations = Read-Table $CurrentTradeDb2Root "ItemXItemEffect"

$currentTradeCategories = Read-Table $CurrentTradeDb2Root "TradeSkillCategory"
$currentTradeAbilities = Read-Table $CurrentTradeDb2Root "SkillLineAbility"
$currentSpellNames = Read-Table $CurrentTradeDb2Root "SpellName"
$currentDecorByID = New-Index (Read-Table $CurrentTradeDb2Root "HouseDecor")
$currentItems = New-Index (Read-Table $CurrentTradeDb2Root "ItemSparse")
$mopClassicRecipeSpellIDs = New-IDSet (Read-Table $MopClassicRoot "SkillLineAbility") "Spell"

$currentMountByID = New-Index $currentMounts
$currentMountBySpell = New-Index $currentMounts "SourceSpellID"
$currentMountByName = @{}
foreach ($mount in $currentMounts) { $currentMountByName[$mount.Name_lang.ToLowerInvariant()] = $mount }
$currentPetByID = New-Index $currentPets
$currentPetByCreature = New-Index $currentPets "CreatureID"
$currentPetBySpell = New-Index $currentPets "SummonSpellID"
$currentToyByItem = New-Index $currentToys "ItemID"
$currentAchievementIDs = New-IDSet $currentAchievements
$currentCurrencyIDs = New-IDSet $currentCurrencies
$currentFactionIDs = New-IDSet $currentFactions
$currentMapByID = New-Index $currentMaps
$currentSpellNameByID = New-Index $currentSpellNames
$mopClassicSpellNameByID = New-Index (Read-Table $MopClassicRoot "SpellName")
$historicalMountByID = New-Index $mounts
$historicalMountBySpell = New-Index $mounts "SourceSpellID"
$historicalAchievementCategoryByID = New-Index $achievementCategories

$creatureByID = New-Index $currentCreatures
$petByName = @{}
foreach ($pet in $currentPets) {
    $creature = $creatureByID[[string]$pet.CreatureID]
    if ($creature -and $creature.Name_lang) { $petByName[$creature.Name_lang.ToLowerInvariant()] = $pet }
}
$spellsByItem = @{}
foreach ($relation in $currentItemRelations) {
    $effect = $currentItemEffects[[string]$relation.ItemEffectID]
    if (-not $effect -or -not $effect.SpellID -or $effect.SpellID -eq "0") { continue }
    if (-not $spellsByItem.ContainsKey([string]$relation.ItemID)) { $spellsByItem[[string]$relation.ItemID] = [System.Collections.Generic.List[string]]::new() }
    $spellsByItem[[string]$relation.ItemID].Add([string]$effect.SpellID)
}

$officialCapture = Get-Content -Raw -LiteralPath $BlizzardCaptureJson | ConvertFrom-Json
$officialRows = @()
$officialIDs = @{ mounts=@{}; pets=@{}; toys=@{} }
foreach ($kind in @("mounts","pets","toys")) {
    foreach ($row in @($officialCapture.$kind)) {
        $link = @($row.links)[0]
        if (-not $link -or -not $link.href) { continue }
        $href = [string]$link.href
        $sourceType = $null; $sourceID = $null
        if ($href -match "(spell|npc|item)=(\d+)") { $sourceType=$Matches[1]; $sourceID=$Matches[2] }
        $db2Row = $null
        $mapping = ""
        if ($kind -eq "mounts") {
            if ($link.text -eq "Purple Dragon Turtle") { $db2Row = $currentMountByID["495"]; $mapping="name_override_bad_guide_link" }
            elseif ($sourceType -eq "spell") { $db2Row=$currentMountBySpell[$sourceID]; $mapping="source_spell" }
            elseif ($sourceType -eq "item") {
                $itemSpells = if ($spellsByItem.ContainsKey($sourceID)) { @($spellsByItem[$sourceID]) } else { @() }
                foreach ($spellID in $itemSpells) { if ($currentMountBySpell[$spellID]) { $db2Row=$currentMountBySpell[$spellID]; $mapping="item_effect"; break } }
                if (-not $db2Row -and $link.text) { $db2Row=$currentMountByName[$link.text.ToLowerInvariant()]; $mapping="name_fallback" }
            }
        } elseif ($kind -eq "pets") {
            if ($sourceType -eq "npc") { $db2Row=$currentPetByCreature[$sourceID]; $mapping="creature" }
            elseif ($sourceType -eq "item") {
                $itemSpells = if ($spellsByItem.ContainsKey($sourceID)) { @($spellsByItem[$sourceID]) } else { @() }
                foreach ($spellID in $itemSpells) { if ($currentPetBySpell[$spellID]) { $db2Row=$currentPetBySpell[$spellID]; $mapping="item_effect"; break } }
                if (-not $db2Row -and $link.text) { $db2Row=$petByName[$link.text.ToLowerInvariant()]; $mapping="name_fallback" }
            }
        } elseif ($sourceType -eq "item") { $db2Row=$currentToyByItem[$sourceID]; $mapping="item_id" }
        if ($db2Row) { $officialIDs[$kind][[string]$db2Row.ID] = $true }
        $officialRows += [pscustomobject]@{
            collectible_type=$kind.TrimEnd("s"); source_id_type=$sourceType; source_id=$sourceID
            mapped_id=if($db2Row){$db2Row.ID}else{$null}; guide_name=$link.text; mapping=$mapping
            source_text=$row.text; source_url=$href; guide_url=$officialCapture.url
        }
    }
}
Write-CsvFile $blizzardSourcePath $officialRows
Assert-Equal @($officialRows | Where-Object collectible_type -eq "mount").Count 56 "Blizzard Pandaria mount guide row count"
Assert-Equal @($officialRows | Where-Object collectible_type -eq "mount" | Select-Object -ExpandProperty mapped_id -Unique).Count 55 "Blizzard Pandaria unique mapped mount count"
Assert-Equal @($officialRows | Where-Object { $_.collectible_type -eq "pet" -and $_.mapped_id }).Count 152 "Blizzard Pandaria mapped pet count"
Assert-Equal @($officialRows | Where-Object collectible_type -eq "toy").Count 59 "Blizzard Pandaria toy guide row count"

$mountExternalIDs = @("468","523","532","544","547","551","568")
$mountCrossExpansionIDs = @("454","455","467","488","552")
$mountUnobtainableCandidateIDs = @("462","484","485")
$mountUnavailableIDs = @("503","518","519","520","541","550","558","562","563","564")
$mountUnavailableNotes = @{
    "503"="Pandaria Challenge Mode phoenix; reward window ended"; "518"="Pandaria Challenge Mode phoenix; reward window ended"
    "519"="Pandaria Challenge Mode phoenix; reward window ended"; "520"="Pandaria Challenge Mode phoenix; reward window ended"
    "541"="Malevolent Gladiator season reward; season ended"; "550"="Pandaria Brawler's Guild rank reward; Brawler's Guild is unavailable"
    "558"="Ahead of the Curve: Garrosh Hellscream reward; removed with Warlords launch"
    "562"="Tyrannical Gladiator season reward; season ended"; "563"="Grievous Gladiator season reward; season ended"; "564"="Prideful Gladiator season reward; season ended"
}
$mountInventory = foreach ($mount in $mounts | Where-Object { [int]$_.ID -ge 448 -and [int]$_.ID -le 568 }) {
    $id = [string]$mount.ID
    $decision = if ($id -in $mountExternalIDs) { "exclude_policy_external" } elseif ($id -in $mountCrossExpansionIDs) { "exclude_cross_expansion" } elseif ($id -in $mountUnobtainableCandidateIDs) { "exclude_unobtainable_or_internal" } else { "include_mop" }
    [pscustomobject]@{
        status=if($decision -eq "include_mop"){"mop_boundary_confirmed"}else{$decision}; release_decision=$decision
        unavailable=$id -in $mountUnavailableIDs; availability_note=$mountUnavailableNotes[$id]
        current_exists=$currentMountByID.ContainsKey($id); official_guide_match=$officialIDs.mounts.ContainsKey($id)
        mount_id=$mount.ID; name=$mount.Name_lang; source_spell_id=$mount.SourceSpellID
        source_type_enum=$mount.SourceTypeEnum; flags=$mount.Flags; source_text=$mount.SourceText_lang
    }
}

$petInventory = foreach ($id in @($officialIDs.pets.Keys | Sort-Object { [int]$_ })) {
    $pet = $currentPetByID[$id]
    $creature = $creatureByID[[string]$pet.CreatureID]
    $source = @($officialRows | Where-Object { $_.collectible_type -eq "pet" -and [string]$_.mapped_id -eq $id })[0]
    [pscustomobject]@{
        status="blizzard_mop_acquisition_confirmed"; release_decision="include_mop"; unavailable=$false; current_exists=$true
        species_id=$pet.ID; name=if($creature){$creature.Name_lang}else{$source.guide_name}; creature_id=$pet.CreatureID; summon_spell_id=$pet.SummonSpellID
        pet_type_enum=$pet.PetTypeEnum; flags=$pet.Flags; source_type_enum=$pet.SourceTypeEnum; source_text=$source.source_text; guide_url=$source.guide_url
    }
}
$toyInventory = foreach ($id in @($officialIDs.toys.Keys | Sort-Object { [int]$_ })) {
    $toy = $currentToys | Where-Object { [string]$_.ID -eq $id } | Select-Object -First 1
    $source = @($officialRows | Where-Object { $_.collectible_type -eq "toy" -and [string]$_.mapped_id -eq $id })[0]
    [pscustomobject]@{
        status="blizzard_mop_acquisition_confirmed"; release_decision="include_mop"; unavailable=$false; current_exists=$true
        toy_id=$toy.ID; item_id=$toy.ItemID; name=$source.guide_name; source_type_enum=$toy.SourceTypeEnum; flags=$toy.Flags; source_text=$source.source_text; guide_url=$source.guide_url
    }
}

$mopAchievementCategoryIDs = @("15106","15107","15110","15113","15114","15162","15163","15218","15222","15229","15265")
$achievementInventory = foreach ($achievement in $achievements | Where-Object { [string]$_.Category -in $mopAchievementCategoryIDs }) {
    $category = $historicalAchievementCategoryByID[[string]$achievement.Category]
    [pscustomobject]@{
        status="mop_category_confirmed"; current_exists=$currentAchievementIDs.ContainsKey([string]$achievement.ID)
        achievement_id=$achievement.ID; title=$achievement.Title_lang; description=$achievement.Description_lang
        category_id=$achievement.Category; category_name=if($category){$category.Name_lang}else{$null}
        criteria_tree_id=$achievement.Criteria_tree; flags=$achievement.Flags; points=$achievement.Points
    }
}
$criteriaByID = New-Index $criteriaRows
$criteriaChildren = @{}
foreach ($node in $criteriaTreeRows) {
    if (-not $criteriaChildren.ContainsKey([string]$node.Parent)) { $criteriaChildren[[string]$node.Parent] = [System.Collections.Generic.List[object]]::new() }
    $criteriaChildren[[string]$node.Parent].Add($node)
}
function Get-CriteriaLeaves([string]$RootID) {
    if (-not $RootID -or $RootID -eq "0") { return }
    $queue = [System.Collections.Generic.Queue[object]]::new(); $queue.Enqueue(@($RootID,""))
    while ($queue.Count) {
        $pair=$queue.Dequeue()
        foreach ($node in @($criteriaChildren[[string]$pair[0]] | Sort-Object { [int]$_.OrderIndex })) {
            $path=if($pair[1]){"$($pair[1])/$($node.OrderIndex)"}else{[string]$node.OrderIndex}
            if ($node.CriteriaID -ne "0") {
                $criterion=$criteriaByID[[string]$node.CriteriaID]
                [pscustomobject]@{ order_path=$path; tree_id=$node.ID; description=$node.Description_lang; criteria_id=$node.CriteriaID; criteria_type=if($criterion){$criterion.Type}else{$null}; asset_id=if($criterion){$criterion.Asset}else{$null}; amount=$node.Amount; operator=$node.Operator }
            } else { $queue.Enqueue(@([string]$node.ID,$path)) }
        }
    }
}
$achievementCriteriaInventory = foreach ($achievement in $achievements | Where-Object { [string]$_.Category -in $mopAchievementCategoryIDs -and $_.Criteria_tree -ne "0" }) {
    foreach ($leaf in (Get-CriteriaLeaves ([string]$achievement.Criteria_tree))) {
        [pscustomobject]@{ achievement_id=$achievement.ID; title=$achievement.Title_lang; category_id=$achievement.Category; order_path=$leaf.order_path; tree_id=$leaf.tree_id; description=$leaf.description; criteria_id=$leaf.criteria_id; criteria_type=$leaf.criteria_type; asset_id=$leaf.asset_id; amount=$leaf.amount; operator=$leaf.operator }
    }
}

$achievementByID = New-Index $achievements
function Get-EncounterRows($AchievementIDs, [string]$Kind) {
    foreach ($achievementID in $AchievementIDs) {
        $achievement=$achievementByID[[string]$achievementID]
        if (-not $achievement) { throw "Missing Pandaria $Kind achievement $achievementID" }
        foreach ($leaf in (Get-CriteriaLeaves ([string]$achievement.Criteria_tree))) {
            [pscustomobject]@{
                achievement_id=$achievement.ID; achievement=$achievement.Title_lang; order_path=$leaf.order_path; tree_id=$leaf.tree_id; criterion=$leaf.description
                criteria_id=$leaf.criteria_id; criteria_type=$leaf.criteria_type; criteria_asset=$leaf.asset_id
                npc_id=if($Kind -eq "rare" -and $leaf.criteria_type -eq "0"){$leaf.asset_id}else{$null}
                completion_quest_id=if($Kind -eq "treasure" -and $leaf.criteria_type -eq "27"){$leaf.asset_id}else{$null}
                object_id=if($Kind -eq "treasure" -and $leaf.criteria_type -eq "68"){$leaf.asset_id}else{$null}
                selection_decision="include_mop"
            }
        }
    }
}
$rareInventory = @(Get-EncounterRows @("7439","7932","8103","8714") "rare")
$treasureInventory = @(Get-EncounterRows @("7284","7997","8726","8727","8729","8784") "treasure")

$tradeCategoryChildren = @{}; $tradeCategoryByID = New-Index $currentTradeCategories
foreach ($category in $currentTradeCategories) {
    if (-not $tradeCategoryChildren.ContainsKey([string]$category.ParentTradeSkillCategoryID)) { $tradeCategoryChildren[[string]$category.ParentTradeSkillCategoryID] = [System.Collections.Generic.List[string]]::new() }
    $tradeCategoryChildren[[string]$category.ParentTradeSkillCategoryID].Add([string]$category.ID)
}
$mopTradeRoots = @("596","553","90","656","713","763","809","876","950")
$allowedTradeCategories = @{}; $tradeQueue = [System.Collections.Generic.Queue[string]]::new()
foreach ($rootID in $mopTradeRoots) { $tradeQueue.Enqueue($rootID) }
while ($tradeQueue.Count) {
    $categoryID=$tradeQueue.Dequeue(); if($allowedTradeCategories.ContainsKey($categoryID)){continue}; $allowedTradeCategories[$categoryID]=$true
    foreach($childID in @($tradeCategoryChildren[$categoryID])){$tradeQueue.Enqueue($childID)}
}
$houseDecorTradeCategories = @{}
foreach($categoryID in $allowedTradeCategories.Keys){$category=$tradeCategoryByID[$categoryID];if($category -and $category.Name_lang -eq "House Decor"){$houseDecorTradeCategories[$categoryID]=$true}}
$professionNames = @{ "171"="Alchemy";"164"="Blacksmithing";"185"="Cooking";"333"="Enchanting";"202"="Engineering";"773"="Inscription";"755"="Jewelcrafting";"165"="Leatherworking";"197"="Tailoring" }
$recipeAbilities = @($currentTradeAbilities | Where-Object { $allowedTradeCategories.ContainsKey([string]$_.TradeSkillCategoryID) -and $professionNames.ContainsKey([string]$_.SkillLine) } | Sort-Object { [int]$_.ID } | Group-Object Spell | ForEach-Object { $_.Group[0] })
$recipeInventory = foreach($ability in $recipeAbilities | Where-Object { $mopClassicRecipeSpellIDs.ContainsKey([string]$_.Spell) -or $houseDecorTradeCategories.ContainsKey([string]$_.TradeSkillCategoryID) }){
    $currentSpell=$currentSpellNameByID[[string]$ability.Spell]
    $spell=if($currentSpell -and $currentSpell.Name_lang){$currentSpell}else{$mopClassicSpellNameByID[[string]$ability.Spell]}
    if(-not$spell -or -not$spell.Name_lang){throw "Pandaria recipe $($ability.Spell) has no current or Pandaria Classic name"}
    [pscustomobject]@{
        status=if($houseDecorTradeCategories.ContainsKey([string]$ability.TradeSkillCategoryID)){"current_house_decor_recipe"}else{"mop_classic_current_recipe"}
        current_ability_exists=$true;current_spell_name_exists=[bool]($currentSpell -and $currentSpell.Name_lang);profession=$professionNames[[string]$ability.SkillLine];profession_id=$ability.SkillLine
        recipe_spell_id=$ability.Spell;name=$spell.Name_lang;skill_line_ability_id=$ability.ID;trade_category_id=$ability.TradeSkillCategoryID
        acquire_method=$ability.AcquireMethod;supercedes_spell_id=$ability.SupercedesSpell
    }
}

$decorAuditRows = @(Import-Csv -LiteralPath $decorAuditPath)
$decorationInventory = foreach($audit in $decorAuditRows){
    $decor=$currentDecorByID[[string]$audit.decor_id];if(-not$decor){throw "Pandaria decor $($audit.decor_id) absent from current DB2"}
    $item=$currentItems[[string]$decor.ItemID]
    [pscustomobject]@{
        status=$audit.status;candidate_basis="live_catalog_acquisition_audit";acquisition_expansion=$audit.acquisition_expansion;catalog_scope=$audit.catalog_scope
        decor_id=$decor.ID;item_id=$decor.ItemID;decor_name=$decor.Name_lang.Trim();source_kind=$audit.source_kind;source_text=$audit.source_text
        achievement_ids=$audit.achievement_ids;quest_ids=$audit.quest_ids;npc_ids=$audit.npc_ids;source_spell_ids=$audit.source_spell_ids;currency_ids=$audit.currency_ids
        classification_note=$audit.classification_note;acquisition_source_url=$audit.acquisition_source_url;item_name=if($item){$item.Display_lang}else{$null};item_expansion_id=if($item){$item.ExpansionID}else{$null}
        flags=$decor.Flags;type=$decor.Type;model_type=$decor.ModelType;weight_cost=$decor.WeightCost
    }
}

$mapIDs = @("424","371","376","379","388","390","418","422","433","504","507","554")
$mapInventory = @($mapIDs | ForEach-Object {$map=$currentMapByID[$_];if(-not$map){throw "Missing Pandaria map $_"};[pscustomobject]@{status="primary_map_confirmed";current_exists=$true;map_id=$map.ID;name=$map.Name_lang;parent_map_id=$map.ParentUiMapID;system=$map.System;type=$map.Type;flags=$map.Flags}})
$historicalFactionByID=New-Index $historicalFactions;$currentFactionByID=New-Index $currentFactions
$factionIDs=@("1269","1270","1271","1272","1273","1275","1276","1277","1278","1279","1280","1281","1282","1283","1302","1337","1341","1345","1358","1359","1375","1376","1387","1388","1435","1492")
$factionInventory=@($factionIDs|ForEach-Object{$f=$historicalFactionByID[$_];if(-not$f){$f=$currentFactionByID[$_]};if(-not$f){throw "Missing Pandaria faction $_"};[pscustomobject]@{status="mop_collectible_requirement";current_exists=$currentFactionIDs.ContainsKey([string]$f.ID);faction_id=$f.ID;name=$f.Name_lang;parent_faction_id=$f.ParentFactionID;friendship_rep_id=$f.FriendshipRepID;flags=$f.Flags}})
$historicalCurrencyByID=New-Index $historicalCurrencies;$currentCurrencyByID=New-Index $currentCurrencies
$currencyIDs=@("402","676","677","697","738","752","754","776","777","789")
$currencyInventory=@($currencyIDs|ForEach-Object{$c=$historicalCurrencyByID[$_];if(-not$c){$c=$currentCurrencyByID[$_]};if(-not$c){throw "Missing Pandaria currency $_"};[pscustomobject]@{status="mop_collectible_requirement";current_exists=$currentCurrencyIDs.ContainsKey([string]$c.ID);currency_id=$c.ID;name=$c.Name_lang;description=$c.Description_lang;category_id=$c.CategoryID;faction_id=$c.FactionID;max_quantity=$c.MaxQty;flags=$c.Flags}})

$mountManifest=@($mountInventory|Where-Object release_decision -eq "include_mop"|Sort-Object{[int]$_.mount_id})
$petManifest=@($petInventory|Sort-Object{[int]$_.species_id});$toyManifest=@($toyInventory|Sort-Object{[int]$_.toy_id});$decorManifest=@($decorationInventory|Sort-Object{[int]$_.decor_id})
$achievementManifest=@($achievementInventory|Where-Object{$_.current_exists}|Sort-Object{[int]$_.achievement_id});$achievementManifestIDs=@($achievementManifest.achievement_id)
$criteriaManifest=@($achievementCriteriaInventory|Where-Object{[string]$_.achievement_id-in$achievementManifestIDs}|Sort-Object{[int]$_.achievement_id},{Get-OrderPathSortKey $_.order_path})
$recipeManifest=@($recipeInventory|Sort-Object profession,{[int]$_.recipe_spell_id});$rareManifest=@($rareInventory|Sort-Object{[int]$_.achievement_id},{Get-OrderPathSortKey $_.order_path});$treasureManifest=@($treasureInventory|Sort-Object{[int]$_.achievement_id},{Get-OrderPathSortKey $_.order_path})

Assert-Equal $mountInventory.Count 104 "Pandaria mount candidate count";Assert-Equal $mountManifest.Count 89 "Pandaria mount manifest count"
Assert-Equal $petManifest.Count 152 "Pandaria pet manifest count";Assert-Equal $toyManifest.Count 59 "Pandaria toy manifest count";Assert-Equal $decorManifest.Count 41 "Pandaria decoration manifest count"
Assert-Equal $achievementManifest.Count 407 "Pandaria achievement manifest count";Assert-Equal $criteriaManifest.Count 1563 "Pandaria achievement criteria count"
Assert-Equal $rareManifest.Count 104 "Pandaria rare criteria count";Assert-Equal $treasureManifest.Count 98 "Pandaria treasure criteria count"
Assert-Equal $recipeManifest.Count 978 "Pandaria recipe manifest count";Assert-Equal @($recipeManifest|Where-Object status -eq "current_house_decor_recipe").Count 21 "Pandaria house decor recipe count"
Assert-Equal $mapInventory.Count 12 "Pandaria map count";Assert-Equal $factionInventory.Count 26 "Pandaria faction count";Assert-Equal $currencyInventory.Count 10 "Pandaria currency count"
Assert-Equal @($mountManifest|Where-Object{-not$_.current_exists}).Count 0 "Pandaria mounts missing current retail";Assert-Equal @($achievementManifest|Where-Object{-not$_.current_exists}).Count 0 "Pandaria achievements missing current retail"
Assert-Equal @($rareManifest|Where-Object{-not$_.npc_id}).Count 0 "Pandaria rare criteria without NPC IDs";Assert-Equal @($treasureManifest|Where-Object{-not$_.completion_quest_id-and-not$_.object_id}).Count 0 "Pandaria treasure criteria without source IDs"
Assert-IDValues @($mountManifest|Where-Object unavailable -eq "True"|ForEach-Object mount_id) $mountUnavailableIDs "Pandaria unavailable mount IDs"
Assert-IDValues @($recipeManifest|Where-Object status -eq "current_house_decor_recipe"|ForEach-Object recipe_spell_id) @("1261233","1261234","1261235","1261236","1261237","1261238","1261239","1261240","1261241","1261242","1261243","1261244","1261245","1261248","1261250","1262302","1262306","1263548","1263551","1263553","1266563") "Pandaria house decor recipe IDs"
foreach($spec in @(@($mountInventory,"mount_id","Mount"),@($petInventory,"species_id","Pet"),@($toyInventory,"toy_id","Toy"),@($decorationInventory,"decor_id","Decoration"),@($achievementInventory,"achievement_id","Achievement"),@($achievementCriteriaInventory,"tree_id","Achievement criteria"),@($recipeInventory,"recipe_spell_id","Recipe"),@($rareInventory,"tree_id","Rare"),@($treasureInventory,"tree_id","Treasure"))){Assert-UniqueField $spec[0] $spec[1] $spec[2]}

$summary=@();$summary+=Export-Inventory "mounts" ($mountInventory|Sort-Object{[int]$_.mount_id});$summary+=Export-Inventory "pets" $petManifest;$summary+=Export-Inventory "toys" $toyManifest;$summary+=Export-Inventory "decorations" $decorManifest
$summary+=Export-Inventory "achievements" ($achievementInventory|Sort-Object{[int]$_.achievement_id});$summary+=Export-Inventory "achievement-criteria" ($achievementCriteriaInventory|Sort-Object{[int]$_.achievement_id},{Get-OrderPathSortKey $_.order_path})
$summary+=Export-Inventory "rare-candidates" $rareManifest;$summary+=Export-Inventory "treasure-candidates" $treasureManifest;$summary+=Export-Inventory "recipes" $recipeManifest;$summary+=Export-Inventory "maps" ($mapInventory|Sort-Object{[int]$_.map_id});$summary+=Export-Inventory "factions" ($factionInventory|Sort-Object{[int]$_.faction_id});$summary+=Export-Inventory "currencies" ($currencyInventory|Sort-Object{[int]$_.currency_id})
Write-CsvFile (Join-Path $OutputRoot "summary.csv") $summary

$manifests=[ordered]@{mounts=@($mountManifest);pets=@($petManifest);toys=@($toyManifest);decorations=@($decorManifest);achievements=@($achievementManifest);"achievement-criteria"=@($criteriaManifest);recipes=@($recipeManifest);rares=@($rareManifest);treasures=@($treasureManifest);"supporting-currencies"=@($currencyInventory|Sort-Object{[int]$_.currency_id});"supporting-factions"=@($factionInventory|Sort-Object{[int]$_.faction_id});"supporting-maps"=@($mapInventory|Sort-Object{[int]$_.map_id})}
$identifierByManifest=@{mounts="mount_id";pets="species_id";toys="toy_id";decorations="decor_id";achievements="achievement_id";"achievement-criteria"="tree_id";recipes="recipe_spell_id";rares="tree_id";treasures="tree_id";"supporting-currencies"="currency_id";"supporting-factions"="faction_id";"supporting-maps"="map_id"}
$manifestSummary=foreach($name in $manifests.Keys){Write-CsvFile (Join-Path $ManifestRoot "$name.csv") $manifests[$name];[pscustomobject]@{manifest=$name;rows=@($manifests[$name]).Count;identifier=$identifierByManifest[$name]}}
Write-CsvFile (Join-Path $ManifestRoot "summary.csv") $manifestSummary

$summary|Format-Table -AutoSize
Write-Host "Generated Collectionist Mists of Pandaria ID inventory and release manifests"
$manifestSummary|Format-Table -AutoSize
