param(
    [string]$HistoricalRoot = (Join-Path $env:TEMP "collectionist-legion-db2\legion"),
    [string]$CataclysmClassicRoot = (Join-Path $env:TEMP "collectionist-cata-classic-db2"),
    [string]$WrathClassicRoot = (Join-Path $env:TEMP "collectionist-wrath-classic-db2"),
    [string]$CurrentDb2Root = (Join-Path $env:TEMP "collectionist-tww-db2\current"),
    [string]$CurrentSupportDb2Root = (Join-Path $env:TEMP "collectionist-df-db2\current"),
    [string]$AttRoot = (Join-Path $env:TEMP "collectionist-att-12007"),
    [string]$BlizzardCaptureJson = (Join-Path $env:TEMP "collectionist-cata-blizzard-tables.json"),
    [string]$OutputRoot = (Join-Path $PSScriptRoot "..\research\collectionist\cataclysm\ids"),
    [string]$ManifestRoot = (Join-Path $PSScriptRoot "..\research\collectionist\cataclysm\manifests")
)

$ErrorActionPreference = "Stop"
$decorAuditPath = Join-Path $PSScriptRoot "..\research\collectionist\cataclysm\sources\housing-wowdb-acquisition-audit.csv"
$blizzardSourcePath = Join-Path $PSScriptRoot "..\research\collectionist\cataclysm\sources\blizzard-cataclysm-collectibles.csv"
$attToyDbPath = Join-Path $AttRoot ".contrib\Parser\DATAS\00 - DB\ToyDB.lua"

foreach ($required in @($HistoricalRoot, $CataclysmClassicRoot, $WrathClassicRoot, $CurrentDb2Root, $CurrentSupportDb2Root, $BlizzardCaptureJson, $decorAuditPath, $attToyDbPath)) {
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

$historicalAchievements = Read-Table $HistoricalRoot "Achievement"
$historicalAchievementCategories = Read-Table $HistoricalRoot "Achievement_Category"
$historicalCriteria = Read-Table $HistoricalRoot "Criteria"
$historicalCriteriaTrees = Read-Table $HistoricalRoot "CriteriaTree"

$cataclysmMounts = Read-Table $CataclysmClassicRoot "Mount"
$wrathMountIDs = New-IDSet (Read-Table $WrathClassicRoot "Mount")
$cataclysmRecipeSpellIDs = New-IDSet (Read-Table $CataclysmClassicRoot "SkillLineAbility") "Spell"

$currentMounts = Read-Table $CurrentDb2Root "Mount"
$currentPets = Read-Table $CurrentDb2Root "BattlePetSpecies"
$currentToys = Read-Table $CurrentDb2Root "Toy"
$currentCreatures = Read-Table $CurrentDb2Root "Creature"
$currentItemEffects = New-Index (Read-Table $CurrentDb2Root "ItemEffect")
$currentItemRelations = Read-Table $CurrentDb2Root "ItemXItemEffect"
$currentTradeCategories = Read-Table $CurrentDb2Root "TradeSkillCategory"
$currentTradeAbilities = Read-Table $CurrentDb2Root "SkillLineAbility"
$currentSpellNames = Read-Table $CurrentDb2Root "SpellName"
$currentItems = New-Index (Read-Table $CurrentDb2Root "ItemSparse")

$currentAchievements = Read-Table $CurrentSupportDb2Root "Achievement"
$currentCurrencies = Read-Table $CurrentSupportDb2Root "CurrencyTypes"
$currentFactions = Read-Table $CurrentSupportDb2Root "Faction"
$currentMaps = Read-Table $CurrentSupportDb2Root "UiMap"

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
$historicalAchievementCategoryByID = New-Index $historicalAchievementCategories

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
$tolBaradGuideIndex = 0
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
            if ($link.text -eq "Brown Riding Camel") { $db2Row=$currentMountByID["398"]; $mapping="name_override_bad_guide_link" }
            elseif ($sourceType -eq "spell") { $db2Row=$currentMountBySpell[$sourceID]; $mapping="source_spell" }
            elseif ($sourceType -eq "item") {
                foreach ($spellID in @($spellsByItem[$sourceID])) { if ($currentMountBySpell[$spellID]) { $db2Row=$currentMountBySpell[$spellID]; $mapping="item_effect"; break } }
                if (-not $db2Row -and $link.text) { $db2Row=$currentMountByName[$link.text.ToLowerInvariant()]; $mapping="name_fallback" }
            }
        } elseif ($kind -eq "pets") {
            if ($sourceType -eq "npc") { $db2Row=$currentPetByCreature[$sourceID]; $mapping="creature" }
            elseif ($sourceType -eq "spell") { $db2Row=$currentPetBySpell[$sourceID]; $mapping="summon_spell" }
            elseif ($sourceType -eq "item") {
                foreach ($spellID in @($spellsByItem[$sourceID])) { if ($currentPetBySpell[$spellID]) { $db2Row=$currentPetBySpell[$spellID]; $mapping="item_effect"; break } }
            }
            if (-not $db2Row -and $link.text) { $db2Row=$petByName[$link.text.ToLowerInvariant()]; $mapping="name_fallback" }
        } else {
            if ($link.text -eq "Mylune's Call" -or $link.text -eq "Mylune’s Call") { $db2Row=$currentToyByItem["70159"]; $mapping="name_override_bad_guide_link" }
            elseif ($link.text -eq "Tol Barad Searchlight") {
                $tolBaradGuideIndex++
                $db2Row = if ($tolBaradGuideIndex -eq 1) { $currentToyByItem["64997"] } else { $currentToyByItem["63141"] }
                $mapping="faction_override_bad_guide_link"
            } elseif ($sourceType -eq "item") { $db2Row=$currentToyByItem[$sourceID]; $mapping="item_id" }
        }
        if ($db2Row) { $officialIDs[$kind][[string]$db2Row.ID] = $true }
        $officialRows += [pscustomobject]@{
            collectible_type=$kind.TrimEnd("s"); source_id_type=$sourceType; source_id=$sourceID
            mapped_id=if($db2Row){$db2Row.ID}else{$null}; guide_name=$link.text; mapping=$mapping
            source_text=$row.text; source_url=$href; guide_url=$officialCapture.url
        }
    }
}
Write-CsvFile $blizzardSourcePath $officialRows
Assert-Equal @($officialRows | Where-Object collectible_type -eq "mount").Count 23 "Blizzard Cataclysm nonblank mount guide row count"
Assert-Equal @($officialRows | Where-Object collectible_type -eq "mount" | Select-Object -ExpandProperty mapped_id -Unique).Count 22 "Blizzard Cataclysm unique mapped mount count"
Assert-Equal @($officialRows | Where-Object collectible_type -eq "pet").Count 40 "Blizzard Cataclysm pet guide row count"
Assert-Equal @($officialRows | Where-Object { $_.collectible_type -eq "pet" -and $_.mapped_id }).Count 40 "Blizzard Cataclysm mapped pet count"
Assert-Equal @($officialRows | Where-Object collectible_type -eq "toy").Count 9 "Blizzard Cataclysm toy guide row count"
Assert-Equal @($officialRows | Where-Object { $_.collectible_type -eq "toy" -and $_.mapped_id }).Count 9 "Blizzard Cataclysm mapped toy count"

$mountExternalIDs = @("408","412","418","421","426","432","433","439","440","441","446","447","455")
$mountInternalIDs = @("32")
$mountCrossExpansionIDs = @("416")
$mountUnavailableIDs = @("424","428","467")
$mountUnavailableNotes = @{
    "424"="Vicious Gladiator season reward; season ended"
    "428"="Ruthless Gladiator season reward; season ended"
    "467"="Cataclysmic Gladiator season reward; season ended"
}
$cataclysmMountCandidates = @($cataclysmMounts | Where-Object { -not $wrathMountIDs.ContainsKey([string]$_.ID) -and [int]$_.SourceSpellID -lt 200000 })
# The current Cataclysm Classic snapshot omits the original season-three reward
# even though its item, achievement, and retail Mount record are preserved.
$cataclysmMountCandidates += $currentMountByID["467"]
Assert-Equal $cataclysmMountCandidates.Count 63 "Cataclysm-era mount snapshot candidate count"
$mountInventory = foreach ($historicalMount in $cataclysmMountCandidates) {
    $mount = $currentMountBySpell[[string]$historicalMount.SourceSpellID]
    if (-not $mount) { throw "Current Mount row missing for Cataclysm spell $($historicalMount.SourceSpellID)" }
    $id = [string]$mount.ID
    $decision = if ($id -in $mountExternalIDs) { "exclude_policy_external" } elseif ($id -in $mountInternalIDs) { "exclude_unobtainable_or_internal" } elseif ($id -in $mountCrossExpansionIDs) { "exclude_cross_expansion" } else { "include_cataclysm" }
    [pscustomobject]@{
        status=if($decision -eq "include_cataclysm"){"cataclysm_boundary_confirmed"}else{$decision}; release_decision=$decision
        unavailable=$id -in $mountUnavailableIDs; availability_note=$mountUnavailableNotes[$id]
        current_exists=$currentMountByID.ContainsKey($id); official_guide_match=$officialIDs.mounts.ContainsKey($id)
        mount_id=$mount.ID; name=$mount.Name_lang; source_spell_id=$mount.SourceSpellID
        source_type_enum=$mount.SourceTypeEnum; flags=$mount.Flags; source_text=$mount.SourceText_lang
        cataclysm_classic_mount_id=$historicalMount.ID
    }
}
Assert-Equal @($mountInventory | Where-Object release_decision -eq "include_cataclysm").Count 48 "Cataclysm mount manifest count"

$cataclysmArchaeologyPetIDs = @("309","310")
$cataclysmAdditionalPetIDs = @("306") + $cataclysmArchaeologyPetIDs
$petInventory = foreach ($id in @($officialIDs.pets.Keys + $cataclysmAdditionalPetIDs | Sort-Object -Unique { [int]$_ })) {
    $pet = $currentPetByID[$id]
    $creature = $creatureByID[[string]$pet.CreatureID]
    $source = @($officialRows | Where-Object { $_.collectible_type -eq "pet" -and [string]$_.mapped_id -eq $id })[0]
    [pscustomobject]@{
        status=if($source){"blizzard_cataclysm_acquisition_confirmed"}elseif($id -in $cataclysmArchaeologyPetIDs){"cataclysm_archaeology_confirmed"}else{"handynotes_cataclysm_acquisition_confirmed"}; release_decision="include_cataclysm"; unavailable=$false; current_exists=$true
        species_id=$pet.ID; name=if($creature){$creature.Name_lang}else{$source.guide_name}; creature_id=$pet.CreatureID; summon_spell_id=$pet.SummonSpellID
        pet_type_enum=$pet.PetTypeEnum; flags=$pet.Flags; source_type_enum=$pet.SourceTypeEnum; source_text=if($source){$source.source_text}else{$pet.SourceText_lang}; guide_url=if($source){$source.guide_url}else{""}
    }
}

$toyPatchRows = @()
$patch = ""
foreach ($line in Get-Content -LiteralPath $attToyDbPath) {
    if ($line -match "-- PATCH ([0-9.]+) --") { $patch = $Matches[1] }
    if ($patch -match "^4\." -and $line -match "i\((\d+)\);\s*--\s*(.*)$") {
        $toyPatchRows += [pscustomobject]@{ patch=$patch; original_item_id=$Matches[1]; source_name=$Matches[2] }
    }
}
Assert-Equal $toyPatchRows.Count 55 "ATT Cataclysm patch toy row count"
$toyInternalItemIDs = @("72220","72221","72222","72223","72224","72225","72226","72227","72228","72229","72230","72231","72232","72233")
$toyExternalItemIDs = @("67097","69227","69215","71628","72159","72161","79769")
$toyReplacementItems = @{ "65665"="134022"; "69262"="133997"; "65357"="133998" }
$toyAdditionalItems = @(
    [pscustomobject]@{ patch="3.3.5"; original_item_id="54653"; source_name="Darkspear Pride" },
    [pscustomobject]@{ patch="3.3.5"; original_item_id="54651"; source_name="Gnomeregan Pride" },
    [pscustomobject]@{ patch="4.0.3"; original_item_id="64457"; source_name="The Last Relic of Argus" },
    [pscustomobject]@{ patch="6.1.0"; original_item_id="122304"; source_name="Fandral's Seed Pouch" },
    [pscustomobject]@{ patch="6.2.3"; original_item_id="133511"; source_name="Gurboggle's Gleaming Bauble" },
    [pscustomobject]@{ patch="6.2.3"; original_item_id="133542"; source_name="Tosselwrench's Mega-Accurate Simulation Viewfinder" }
)
$toyInventory = foreach ($candidate in @($toyPatchRows + $toyAdditionalItems)) {
    $originalItemID = [string]$candidate.original_item_id
    $itemID = if ($toyReplacementItems.ContainsKey($originalItemID)) { $toyReplacementItems[$originalItemID] } else { $originalItemID }
    $toy = $currentToyByItem[$itemID]
    if (-not $toy) { throw "Current Toy row missing for Cataclysm source item $originalItemID (current item $itemID)" }
    $item = $currentItems[$itemID]
    $decision = if ($originalItemID -in $toyInternalItemIDs) { "exclude_unobtainable_or_internal" } elseif ($originalItemID -in $toyExternalItemIDs) { "exclude_policy_external" } else { "include_cataclysm" }
    [pscustomobject]@{
        status=if($decision -eq "include_cataclysm"){"cataclysm_source_confirmed"}else{$decision}; release_decision=$decision
        unavailable=[string]$toy.ID -in @("109","168","180"); current_exists=$true; official_guide_match=$officialIDs.toys.ContainsKey([string]$toy.ID)
        toy_id=$toy.ID; item_id=$toy.ItemID; original_item_id=$originalItemID; name=if($item){$item.Display_lang}else{$candidate.source_name}
        source_patch=$candidate.patch; source_type_enum=$toy.SourceTypeEnum; flags=$toy.Flags; source_text=$toy.SourceText_lang
    }
}
Assert-UniqueField @($toyInventory | Where-Object release_decision -eq "include_cataclysm") "toy_id" "Cataclysm toy manifest"
Assert-Equal @($toyInventory | Where-Object release_decision -eq "include_cataclysm").Count 40 "Cataclysm toy manifest count"
Assert-IDValues @($officialIDs.toys.Keys) @($toyInventory | Where-Object official_guide_match | ForEach-Object toy_id) "Cataclysm official toy guide set"

$cataclysmAchievementCategoryIDs = @("15067","15068","15069","15070","15072","15073","15074","15075")
$achievementInventory = foreach ($achievement in $historicalAchievements | Where-Object { [string]$_.Category -in $cataclysmAchievementCategoryIDs }) {
    $category = $historicalAchievementCategoryByID[[string]$achievement.Category]
    [pscustomobject]@{
        status="cataclysm_category_confirmed"; current_exists=$currentAchievementIDs.ContainsKey([string]$achievement.ID)
        achievement_id=$achievement.ID; title=$achievement.Title_lang; description=$achievement.Description_lang
        category_id=$achievement.Category; category_name=if($category){$category.Name_lang}else{$null}
        criteria_tree_id=$achievement.Criteria_tree; flags=$achievement.Flags; points=$achievement.Points
    }
}
$criteriaByID = New-Index $historicalCriteria
$criteriaChildren = @{}
foreach ($node in $historicalCriteriaTrees) {
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
$achievementCriteriaInventory = foreach ($achievement in $historicalAchievements | Where-Object { [string]$_.Category -in $cataclysmAchievementCategoryIDs -and $_.Criteria_tree -ne "0" }) {
    foreach ($leaf in (Get-CriteriaLeaves ([string]$achievement.Criteria_tree))) {
        [pscustomobject]@{ achievement_id=$achievement.ID; title=$achievement.Title_lang; category_id=$achievement.Category; order_path=$leaf.order_path; tree_id=$leaf.tree_id; description=$leaf.description; criteria_id=$leaf.criteria_id; criteria_type=$leaf.criteria_type; asset_id=$leaf.asset_id; amount=$leaf.amount; operator=$leaf.operator }
    }
}

# Cataclysm has no canonical expansion-wide rare or treasure checklist
# achievement equivalent to the dedicated trackers used by later expansions.
$rareInventory = @()
$treasureInventory = @()

$tradeCategoryChildren = @{}; $tradeCategoryByID = New-Index $currentTradeCategories
foreach ($category in $currentTradeCategories) {
    $parent=[string]$category.ParentTradeSkillCategoryID
    if (-not $tradeCategoryChildren.ContainsKey($parent)) { $tradeCategoryChildren[$parent]=[System.Collections.Generic.List[string]]::new() }
    $tradeCategoryChildren[$parent].Add([string]$category.ID)
}
$cataclysmTradeRoots = @("75","569","598","661","715","765","811","878","952")
$allowedTradeCategories=@{}; $tradeQueue=[System.Collections.Generic.Queue[string]]::new(); foreach($root in $cataclysmTradeRoots){$tradeQueue.Enqueue($root)}
while($tradeQueue.Count){$id=$tradeQueue.Dequeue();if($allowedTradeCategories.ContainsKey($id)){continue};$allowedTradeCategories[$id]=$true;foreach($child in @($tradeCategoryChildren[$id])){$tradeQueue.Enqueue($child)}}
$houseDecorTradeCategories=@{}
foreach($id in $allowedTradeCategories.Keys){if($tradeCategoryByID[$id] -and $tradeCategoryByID[$id].Name_lang -eq "House Decor"){$houseDecorTradeCategories[$id]=$true}}
$professionNames=@{"171"="Alchemy";"164"="Blacksmithing";"185"="Cooking";"333"="Enchanting";"202"="Engineering";"773"="Inscription";"755"="Jewelcrafting";"165"="Leatherworking";"197"="Tailoring"}
$recipeInventory = foreach($ability in $currentTradeAbilities | Where-Object {
    $allowedTradeCategories.ContainsKey([string]$_.TradeSkillCategoryID) -and ($cataclysmRecipeSpellIDs.ContainsKey([string]$_.Spell) -or $houseDecorTradeCategories.ContainsKey([string]$_.TradeSkillCategoryID))
}) {
    $spell=$currentSpellNameByID[[string]$ability.Spell];$category=$tradeCategoryByID[[string]$ability.TradeSkillCategoryID]
    [pscustomobject]@{
        status="named_recipe"; current_ability_exists=$true; current_spell_name_exists=[bool]($spell -and $spell.Name_lang)
        profession=$professionNames[[string]$ability.SkillLine]; profession_id=$ability.SkillLine; recipe_spell_id=$ability.Spell
        name=if($spell){$spell.Name_lang}else{$null}; skill_line_ability_id=$ability.ID; trade_category_id=$ability.TradeSkillCategoryID
        trade_category_name=if($category){$category.Name_lang}else{$null}; house_decor_recipe=$houseDecorTradeCategories.ContainsKey([string]$ability.TradeSkillCategoryID)
        acquire_method=$ability.AcquireMethod; supercedes_spell_id=$ability.SupercedesSpell
    }
}

$decorInventory = foreach($row in Import-Csv -LiteralPath $decorAuditPath) {
    [pscustomobject]@{
        status=$row.status; current_exists=$true; decor_id=$row.decor_id; item_id=$row.item_id; name=$row.catalog_name
        catalog_scope=$row.catalog_scope; acquisition_expansion=$row.acquisition_expansion
        source_kind=$row.source_kind; source_text=$row.source_text; achievement_ids=$row.achievement_ids; quest_ids=$row.quest_ids
        npc_ids=$row.npc_ids; source_spell_ids=$row.source_spell_ids; currency_ids=$row.currency_ids; acquisition_source_url=$row.acquisition_source_url
    }
}

$mapIDs = @("174","179","194","198","201","202","203","204","205","207","241","244","245","249","338")
$mapInventory = foreach($id in $mapIDs){$map=$currentMapByID[$id];if(-not$map){throw "Missing current Cataclysm map $id"};[pscustomobject]@{status="cataclysm_support_confirmed";current_exists=$true;map_id=$map.ID;name=$map.Name_lang;parent_map_id=$map.ParentUiMapID;map_type=$map.Type;flags=$map.Flags}}
$factionNames = @{"1133"="Bilgewater Cartel";"1134"="Gilneas";"1135"="The Earthen Ring";"1158"="Guardians of Hyjal";"1171"="Therazane";"1172"="Dragonmaw Clan";"1173"="Ramkahen";"1174"="Wildhammer Clan";"1177"="Baradin's Wardens";"1178"="Hellscream's Reach";"1204"="Avengers of Hyjal"}
$currentFactionByID=New-Index $currentFactions
$factionInventory=foreach($id in $factionNames.Keys|Sort-Object {[int]$_}){$f=$currentFactionByID[$id];if(-not$f){throw "Missing current Cataclysm faction $id"};if($f.Name_lang-ne$factionNames[$id]){throw "Cataclysm faction $id name mismatch"};[pscustomobject]@{status="cataclysm_support_confirmed";current_exists=$currentFactionIDs.ContainsKey($id);faction_id=$f.ID;name=$f.Name_lang;parent_faction_id=$f.ParentFactionID}}
$currencyNames=@{"361"="Illustrious Jewelcrafter's Token";"384"="Dwarf Archaeology Fragment";"385"="Troll Archaeology Fragment";"391"="Tol Barad Commendation";"393"="Fossil Archaeology Fragment";"394"="Night Elf Archaeology Fragment";"397"="Orc Archaeology Fragment";"398"="Draenei Archaeology Fragment";"399"="Vrykul Archaeology Fragment";"400"="Nerubian Archaeology Fragment";"401"="Tol'vir Archaeology Fragment";"416"="Mark of the World Tree";"515"="Darkmoon Prize Ticket";"614"="Mote of Darkness";"615"="Essence of Corrupted Deathwing"}
$currentCurrencyByID=New-Index $currentCurrencies
$currencyInventory=foreach($id in $currencyNames.Keys|Sort-Object {[int]$_}){$c=$currentCurrencyByID[$id];if(-not$c){throw "Missing current Cataclysm currency $id"};if($c.Name_lang-ne$currencyNames[$id]){throw "Cataclysm currency $id name mismatch: '$($c.Name_lang)'"};[pscustomobject]@{status="cataclysm_support_confirmed";current_exists=$currentCurrencyIDs.ContainsKey($id);currency_id=$c.ID;name=$c.Name_lang;category_id=$c.CategoryID;flags=$c.Flags}}

Assert-Equal $mountInventory.Count 63 "Cataclysm mount inventory count"
Assert-Equal $petInventory.Count 43 "Cataclysm pet inventory count"
Assert-Equal $toyInventory.Count 61 "Cataclysm toy inventory count"
Assert-Equal $decorInventory.Count 46 "Cataclysm decoration inventory count"
Assert-Equal $achievementInventory.Count 233 "Cataclysm achievement inventory count"
Assert-Equal $achievementCriteriaInventory.Count 707 "Cataclysm achievement criteria inventory count"
Assert-Equal $recipeInventory.Count 690 "Cataclysm recipe inventory count"
Assert-Equal @($recipeInventory | Where-Object house_decor_recipe).Count 20 "Cataclysm house decor recipe count"
Assert-Equal $mapInventory.Count 15 "Cataclysm map count"
Assert-Equal $factionInventory.Count 11 "Cataclysm faction count"
Assert-Equal $currencyInventory.Count 15 "Cataclysm currency count"
Assert-Equal @($achievementInventory | Where-Object { -not $_.current_exists }).Count 0 "Cataclysm missing current achievement count"
Assert-Equal @($recipeInventory | Where-Object { -not $_.current_spell_name_exists }).Count 0 "Cataclysm unnamed recipe count"

$taskAchievementIDs = @($achievementCriteriaInventory | Group-Object achievement_id | Where-Object { $_.Count -ge 2 -and $_.Count -le 30 } | ForEach-Object Name)
Assert-Equal $taskAchievementIDs.Count 90 "Cataclysm eligible task achievement count"
Assert-Equal @($achievementCriteriaInventory | Where-Object { [string]$_.achievement_id -in $taskAchievementIDs }).Count 500 "Cataclysm eligible task criteria count"

$summary=@()
$summary+=Export-Inventory "mounts" $mountInventory
$summary+=Export-Inventory "pets" $petInventory
$summary+=Export-Inventory "toys" $toyInventory
$summary+=Export-Inventory "decorations" $decorInventory
$summary+=Export-Inventory "achievements" $achievementInventory
$summary+=Export-Inventory "achievement-criteria" @($achievementCriteriaInventory|Sort-Object {[int]$_.achievement_id},{Get-OrderPathSortKey $_.order_path})
$summary+=Export-Inventory "rares" $rareInventory
$summary+=Export-Inventory "treasures" $treasureInventory
$summary+=Export-Inventory "recipes" @($recipeInventory|Sort-Object profession,{[int]$_.recipe_spell_id})
$summary+=Export-Inventory "maps" $mapInventory
$summary+=Export-Inventory "factions" $factionInventory
$summary+=Export-Inventory "currencies" $currencyInventory
Write-CsvFile (Join-Path $OutputRoot "summary.csv") $summary

$manifests=[ordered]@{
    mounts=@{rows=@($mountInventory|Where-Object release_decision -eq "include_cataclysm"|Sort-Object {[int]$_.mount_id});expected=48;id="mount_id"}
    pets=@{rows=@($petInventory|Sort-Object {[int]$_.species_id});expected=43;id="species_id"}
    toys=@{rows=@($toyInventory|Where-Object release_decision -eq "include_cataclysm"|Sort-Object {[int]$_.toy_id});expected=40;id="toy_id"}
    decorations=@{rows=@($decorInventory|Sort-Object {[int]$_.decor_id});expected=46;id="decor_id"}
    achievements=@{rows=@($achievementInventory|Sort-Object {[int]$_.achievement_id});expected=233;id="achievement_id"}
    "achievement-criteria"=@{rows=@($achievementCriteriaInventory|Sort-Object {[int]$_.achievement_id},{Get-OrderPathSortKey $_.order_path});expected=707;id="tree_id"}
    recipes=@{rows=@($recipeInventory|Sort-Object profession,{[int]$_.recipe_spell_id});expected=690;id="recipe_spell_id"}
    rares=@{rows=$rareInventory;expected=0;id="tree_id"}
    treasures=@{rows=$treasureInventory;expected=0;id="tree_id"}
    "supporting-maps"=@{rows=$mapInventory;expected=15;id="map_id"}
    "supporting-factions"=@{rows=$factionInventory;expected=11;id="faction_id"}
    "supporting-currencies"=@{rows=$currencyInventory;expected=15;id="currency_id"}
}
$manifestSummary=@()
foreach($name in $manifests.Keys){$entry=$manifests[$name];Assert-Equal @($entry.rows).Count $entry.expected "Cataclysm $name manifest";Assert-UniqueField @($entry.rows) $entry.id "Cataclysm $name manifest";Write-CsvFile (Join-Path $ManifestRoot "$name.csv") @($entry.rows);$manifestSummary+=[pscustomobject]@{manifest=$name;rows=@($entry.rows).Count;identifier=$entry.id}}
Write-CsvFile (Join-Path $ManifestRoot "summary.csv") $manifestSummary

Write-Host "Generated Collectionist Cataclysm ID inventory"
$summary | Format-Table -AutoSize
Write-Host "Release manifests"
$manifestSummary | Format-Table -AutoSize
