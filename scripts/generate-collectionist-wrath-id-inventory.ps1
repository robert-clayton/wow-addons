param(
    [string]$HistoricalRoot = (Join-Path $env:TEMP "collectionist-legion-db2\legion"),
    [string]$WrathClassicRoot = (Join-Path $env:TEMP "collectionist-wrath-classic-db2"),
    [string]$CurrentDb2Root = (Join-Path $env:TEMP "collectionist-tww-db2\current"),
    [string]$CurrentSupportDb2Root = (Join-Path $env:TEMP "collectionist-df-db2\current"),
    [string]$AttRoot = (Join-Path $env:TEMP "collectionist-att-12007"),
    [string]$BlizzardCaptureJson = (Join-Path $env:TEMP "collectionist-wrath-blizzard-tables.json"),
    [string]$OutputRoot = (Join-Path $PSScriptRoot "..\research\collectionist\wrath-of-the-lich-king\ids"),
    [string]$ManifestRoot = (Join-Path $PSScriptRoot "..\research\collectionist\wrath-of-the-lich-king\manifests")
)

$ErrorActionPreference = "Stop"
$decorAuditPath = Join-Path $PSScriptRoot "..\research\collectionist\wrath-of-the-lich-king\sources\housing-wowdb-acquisition-audit.csv"
$blizzardSourcePath = Join-Path $PSScriptRoot "..\research\collectionist\wrath-of-the-lich-king\sources\blizzard-wrath-collectibles.csv"
$attMountDbPath = Join-Path $AttRoot ".contrib\Parser\DATAS\00 - DB\MountDB.lua"
$attToyDbPath = Join-Path $AttRoot ".contrib\Parser\DATAS\00 - DB\ToyDB.lua"

foreach ($required in @($HistoricalRoot, $WrathClassicRoot, $CurrentDb2Root, $CurrentSupportDb2Root, $AttRoot, $BlizzardCaptureJson, $decorAuditPath, $attMountDbPath, $attToyDbPath)) {
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
    $actual = @($ActualValues | ForEach-Object { [string]$_ } | Where-Object { $_ } | Sort-Object -Unique)
    $expected = @($ExpectedValues | ForEach-Object { [string]$_ } | Where-Object { $_ } | Sort-Object -Unique)
    $missing = @($expected | Where-Object { $_ -notin $actual })
    $extra = @($actual | Where-Object { $_ -notin $expected })
    if ($missing.Count -or $extra.Count) { throw "$Label mismatch: missing [$($missing -join ', ')], extra [$($extra -join ', ')]" }
}

$historicalAchievements = Read-Table $HistoricalRoot "Achievement"
$historicalAchievementCategories = Read-Table $HistoricalRoot "Achievement_Category"
$historicalCriteria = Read-Table $HistoricalRoot "Criteria"
$historicalCriteriaTrees = Read-Table $HistoricalRoot "CriteriaTree"

$wrathMounts = Read-Table $WrathClassicRoot "Mount"
$wrathRecipeSpellIDs = New-IDSet (Read-Table $WrathClassicRoot "SkillLineAbility") "Spell"

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
$wrathMountBySpell = New-Index $wrathMounts "SourceSpellID"

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
        $db2Row = $null; $mapping = ""
        if ($kind -eq "mounts") {
            if ($sourceType -eq "spell") { $db2Row=$currentMountBySpell[$sourceID]; $mapping="source_spell" }
            elseif ($sourceType -eq "item") {
                foreach ($spellID in @($spellsByItem[$sourceID])) {
                    if ($currentMountBySpell[$spellID]) { $db2Row=$currentMountBySpell[$spellID]; $mapping="item_effect"; break }
                }
                if (-not $db2Row -and $link.text) { $db2Row=$currentMountByName[$link.text.ToLowerInvariant()]; $mapping="name_fallback" }
            }
        } elseif ($kind -eq "pets") {
            if ($sourceType -eq "npc") { $db2Row=$currentPetByCreature[$sourceID]; $mapping="creature" }
            elseif ($sourceType -eq "spell") { $db2Row=$currentPetBySpell[$sourceID]; $mapping="summon_spell" }
            elseif ($sourceType -eq "item") {
                foreach ($spellID in @($spellsByItem[$sourceID])) {
                    if ($currentPetBySpell[$spellID]) { $db2Row=$currentPetBySpell[$spellID]; $mapping="item_effect"; break }
                }
            }
            if (-not $db2Row -and $link.text) { $db2Row=$petByName[$link.text.ToLowerInvariant()]; $mapping="name_fallback" }
        } elseif ($sourceType -eq "item") {
            $db2Row=$currentToyByItem[$sourceID]; $mapping="item_id"
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
Assert-Equal @($officialRows | Where-Object collectible_type -eq "mount").Count 49 "Blizzard Wrath mount guide row count"
Assert-Equal @($officialRows | Where-Object { $_.collectible_type -eq "mount" -and $_.mapped_id }).Count 49 "Blizzard Wrath mapped mount count"
Assert-Equal @($officialRows | Where-Object collectible_type -eq "mount" | Select-Object -ExpandProperty mapped_id -Unique).Count 49 "Blizzard Wrath unique mount guide count"
Assert-Equal @($officialRows | Where-Object collectible_type -eq "pet").Count 50 "Blizzard Wrath pet guide row count"
Assert-Equal @($officialRows | Where-Object { $_.collectible_type -eq "pet" -and $_.mapped_id }).Count 50 "Blizzard Wrath mapped pet count"
Assert-Equal @($officialRows | Where-Object collectible_type -eq "pet" | Select-Object -ExpandProperty mapped_id -Unique).Count 50 "Blizzard Wrath unique pet guide count"
Assert-Equal @($officialRows | Where-Object collectible_type -eq "toy").Count 25 "Blizzard Wrath toy guide row count"
Assert-Equal @($officialRows | Where-Object { $_.collectible_type -eq "toy" -and $_.mapped_id }).Count 25 "Blizzard Wrath mapped toy count"
Assert-Equal @($officialRows | Where-Object collectible_type -eq "toy" | Select-Object -ExpandProperty mapped_id -Unique).Count 25 "Blizzard Wrath unique toy guide count"

$mountPatchRows = @()
$patch = ""; $nyi = $false
foreach ($line in Get-Content -LiteralPath $attMountDbPath) {
    if ($line -match "-- PATCH ([0-9.]+) --") { $patch=$Matches[1]; $nyi=$false; continue }
    if ($line -match "^--- NYI ---") { $nyi=$true; continue }
    if ($patch -match "^3\." -and $line -match "^i\((\d+),\s*(\d+)\);\s*--\s*(.*)$") {
        $mountPatchRows += [pscustomobject]@{ patch=$patch; item_id=$Matches[1]; source_spell_id=$Matches[2]; source_name=$Matches[3]; nyi=$nyi }
    }
}
Assert-Equal $mountPatchRows.Count 143 "ATT Wrath patch mount row count"
Assert-Equal @($mountPatchRows.source_spell_id | Sort-Object -Unique).Count 131 "ATT Wrath unique patch mount spell count"

$mappedMountRows = @()
foreach ($candidate in $mountPatchRows) {
    $mount = $currentMountBySpell[[string]$candidate.source_spell_id]
    if ($mount) { $mappedMountRows += [pscustomobject]@{ candidate=$candidate; mount=$mount } }
}
Assert-Equal $mappedMountRows.Count 122 "ATT Wrath current mapped mount row count"
$mountCandidateGroups = @($mappedMountRows | Group-Object { [string]$_.mount.ID })
Assert-Equal $mountCandidateGroups.Count 110 "ATT Wrath unique current mount candidate count"

$mountExternalIDs = @("196","197","211","212","230","328","333","334","335","371","372","376","382")
$mountInternalIDs = @("251","273","274","308")
$mountUnavailableIDs = @("263","266","313","317","340","342","343","344","345","358")
$mountUnavailableNotes = @{
    "263"="Removed Wrath raid meta reward"; "266"="Removed Wrath raid meta reward"
    "313"="Deadly Gladiator season reward; season ended"; "317"="Furious Gladiator season reward; season ended"
    "340"="Relentless Gladiator season reward; season ended"; "358"="Wrathful Gladiator season reward; season ended"
    "342"="Trial of the Crusader tribute reward removed"; "343"="Trial of the Crusader tribute reward removed"
    "344"="Trial of the Crusader tribute reward removed"; "345"="Trial of the Crusader tribute reward removed"
}
$mountInventory = foreach ($group in $mountCandidateGroups | Sort-Object { [int]$_.Name }) {
    $rows = @($group.Group); $mount=$rows[0].mount; $id=[string]$mount.ID
    $decision = if ($id -in $mountExternalIDs) { "exclude_policy_external" } elseif ($id -in $mountInternalIDs) { "exclude_unobtainable_or_internal" } else { "include_wrath" }
    [pscustomobject]@{
        status=if($decision -eq "include_wrath"){"wrath_boundary_confirmed"}else{$decision}; release_decision=$decision
        unavailable=$id -in $mountUnavailableIDs; availability_note=$mountUnavailableNotes[$id]
        current_exists=$currentMountByID.ContainsKey($id); official_guide_match=$officialIDs.mounts.ContainsKey($id)
        mount_id=$mount.ID; name=$mount.Name_lang; source_spell_id=$mount.SourceSpellID
        source_type_enum=$mount.SourceTypeEnum; flags=$mount.Flags; source_text=$mount.SourceText_lang
        source_patches=Join-IDs @($rows.candidate.patch); original_item_ids=Join-IDs @($rows.candidate.item_id)
        att_nyi=[bool]@($rows | Where-Object { $_.candidate.nyi }).Count
        wrath_classic_exists=$wrathMountBySpell.ContainsKey([string]$mount.SourceSpellID)
    }
}
Assert-Equal @($mountInventory | Where-Object release_decision -eq "include_wrath").Count 93 "Wrath mount manifest count"
Assert-IDValues @($officialIDs.mounts.Keys) @($mountInventory | Where-Object official_guide_match | ForEach-Object mount_id) "Wrath official mount guide set"

$petInventory = foreach ($id in @($officialIDs.pets.Keys | Sort-Object { [int]$_ })) {
    $pet = $currentPetByID[$id]
    $creature = $creatureByID[[string]$pet.CreatureID]
    $source = @($officialRows | Where-Object { $_.collectible_type -eq "pet" -and [string]$_.mapped_id -eq $id })[0]
    [pscustomobject]@{
        status="blizzard_wrath_acquisition_confirmed"; release_decision="include_wrath"; unavailable=$false; current_exists=$true
        species_id=$pet.ID; name=if($creature){$creature.Name_lang}else{$source.guide_name}; creature_id=$pet.CreatureID; summon_spell_id=$pet.SummonSpellID
        pet_type_enum=$pet.PetTypeEnum; flags=$pet.Flags; source_type_enum=$pet.SourceTypeEnum; source_text=$source.source_text; guide_url=$source.guide_url
    }
}

$toyPatchRows = @()
$patch = ""
foreach ($line in Get-Content -LiteralPath $attToyDbPath) {
    if ($line -match "-- PATCH ([0-9.]+) --") { $patch = $Matches[1] }
    if ($patch -match "^3\." -and $line -match "^i\((\d+)\);\s*--\s*(.*)$") {
        $toyPatchRows += [pscustomobject]@{ patch=$patch; original_item_id=$Matches[1]; source_name=$Matches[2] }
    }
}
Assert-Equal $toyPatchRows.Count 44 "ATT Wrath patch toy row count"
$toyReplacementItems = @{ "46349"="134020" }
$toyUnmappedItemIDs = @()
$toyMappedCandidates = @()
foreach ($candidate in $toyPatchRows) {
    $originalItemID=[string]$candidate.original_item_id
    $itemID=if($toyReplacementItems.ContainsKey($originalItemID)){$toyReplacementItems[$originalItemID]}else{$originalItemID}
    $toy=$currentToyByItem[$itemID]
    if (-not $toy) { $toyUnmappedItemIDs += $originalItemID; continue }
    $toyMappedCandidates += [pscustomobject]@{ patch=$candidate.patch; original_item_id=$originalItemID; item_id=$itemID; source_name=$candidate.source_name; toy=$toy }
}
Assert-IDValues $toyUnmappedItemIDs @("49040","52251") "ATT Wrath intentionally unmapped toy-like items"
Assert-Equal $toyMappedCandidates.Count 42 "ATT Wrath current mapped toy candidate count"
$toyMappedCandidates += @(
    [pscustomobject]@{ patch="7.0.3"; original_item_id="129965"; item_id="129965"; source_name="Grizzlesnout's Fang"; toy=$currentToyByItem["129965"] },
    [pscustomobject]@{ patch="7.0.3"; original_item_id="129952"; item_id="129952"; source_name="Hourglass of Eternity"; toy=$currentToyByItem["129952"] },
    [pscustomobject]@{ patch="7.0.3"; original_item_id="129938"; item_id="129938"; source_name="Will of Northrend"; toy=$currentToyByItem["129938"] },
    [pscustomobject]@{ patch="5.4.0"; original_item_id="102467"; item_id="102467"; source_name="Censer of Eternal Agony"; toy=$currentToyByItem["102467"] }
)
$toyExternalItemIDs = @("38578","45063","46780","49704","49703","54212","54452")
$toyCataclysmPrelaunchItemIDs = @("54651","54653")
$toyCrossExpansionItemIDs = @("102467") + $toyCataclysmPrelaunchItemIDs
$toyInventory = foreach ($candidate in $toyMappedCandidates) {
    if (-not $candidate.toy) { throw "Current Toy row missing for Wrath source item $($candidate.original_item_id)" }
    $originalItemID=[string]$candidate.original_item_id; $toy=$candidate.toy; $item=$currentItems[[string]$toy.ItemID]
    $decision = if ($originalItemID -in $toyExternalItemIDs) { "exclude_policy_external" } elseif ($originalItemID -in $toyCrossExpansionItemIDs) { "exclude_cross_expansion" } else { "include_wrath" }
    $crossExpansion = if ($originalItemID -in $toyCataclysmPrelaunchItemIDs) { "cataclysm" } elseif ($originalItemID -eq "102467") { "mists_of_pandaria" } else { "" }
    [pscustomobject]@{
        status=if($decision -eq "include_wrath"){"wrath_source_confirmed"}else{$decision}; release_decision=$decision
        acquisition_expansion=if($decision -eq "include_wrath"){"wrath"}else{$crossExpansion}
        unavailable=$originalItemID -in $toyCataclysmPrelaunchItemIDs; current_exists=$true; official_guide_match=$officialIDs.toys.ContainsKey([string]$toy.ID)
        toy_id=$toy.ID; item_id=$toy.ItemID; original_item_id=$originalItemID; name=if($item){$item.Display_lang}else{$candidate.source_name}
        source_patch=$candidate.patch; source_type_enum=$toy.SourceTypeEnum; flags=$toy.Flags; source_text=$toy.SourceText_lang
    }
}
Assert-UniqueField @($toyInventory | Where-Object release_decision -eq "include_wrath") "toy_id" "Wrath toy manifest"
Assert-Equal @($toyInventory | Where-Object release_decision -eq "include_wrath").Count 36 "Wrath toy manifest count"
Assert-IDValues @($officialIDs.toys.Keys) @($toyInventory | Where-Object official_guide_match | ForEach-Object toy_id) "Wrath official toy guide set"

$wrathAchievementCategoryIDs = @("14780","14806","14863","14866","14901","14922","14941")
$achievementInventory = foreach ($achievement in $historicalAchievements | Where-Object { [string]$_.Category -in $wrathAchievementCategoryIDs }) {
    $category = $historicalAchievementCategoryByID[[string]$achievement.Category]
    [pscustomobject]@{
        status="wrath_category_confirmed"; current_exists=$currentAchievementIDs.ContainsKey([string]$achievement.ID)
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
$achievementCriteriaInventory = foreach ($achievement in $historicalAchievements | Where-Object { [string]$_.Category -in $wrathAchievementCategoryIDs -and $_.Criteria_tree -ne "0" }) {
    foreach ($leaf in (Get-CriteriaLeaves ([string]$achievement.Criteria_tree))) {
        [pscustomobject]@{ achievement_id=$achievement.ID; title=$achievement.Title_lang; category_id=$achievement.Category; order_path=$leaf.order_path; tree_id=$leaf.tree_id; description=$leaf.description; criteria_id=$leaf.criteria_id; criteria_type=$leaf.criteria_type; asset_id=$leaf.asset_id; amount=$leaf.amount; operator=$leaf.operator }
    }
}
$rareInventory = foreach ($row in $achievementCriteriaInventory | Where-Object achievement_id -eq "2257") {
    [pscustomobject]@{
        achievement_id=$row.achievement_id; achievement=$row.title; order_path=$row.order_path; tree_id=$row.tree_id
        criterion=$row.description; criteria_id=$row.criteria_id; criteria_type=$row.criteria_type; criteria_asset=$row.asset_id
        npc_id=$row.asset_id; completion_quest_id=""; object_id=""; selection_decision="include_wrath"
    }
}
# Wrath has no canonical expansion-wide treasure checklist achievement.
$treasureInventory = @()

$tradeCategoryChildren = @{}; $tradeCategoryByID = New-Index $currentTradeCategories
foreach ($category in $currentTradeCategories) {
    $parent=[string]$category.ParentTradeSkillCategoryID
    if (-not $tradeCategoryChildren.ContainsKey($parent)) { $tradeCategoryChildren[$parent]=[System.Collections.Generic.List[string]]::new() }
    $tradeCategoryChildren[$parent].Add([string]$category.ID)
}
$wrathTradeRoots = @("599","576","74","662","716","766","812","879","953")
$allowedTradeCategories=@{}; $tradeQueue=[System.Collections.Generic.Queue[string]]::new(); foreach($root in $wrathTradeRoots){$tradeQueue.Enqueue($root)}
while($tradeQueue.Count){$id=$tradeQueue.Dequeue();if($allowedTradeCategories.ContainsKey($id)){continue};$allowedTradeCategories[$id]=$true;foreach($child in @($tradeCategoryChildren[$id])){$tradeQueue.Enqueue($child)}}
$houseDecorTradeCategories=@{}
foreach($id in $allowedTradeCategories.Keys){if($tradeCategoryByID[$id] -and $tradeCategoryByID[$id].Name_lang -eq "House Decor"){$houseDecorTradeCategories[$id]=$true}}
$professionNames=@{"171"="Alchemy";"164"="Blacksmithing";"185"="Cooking";"333"="Enchanting";"202"="Engineering";"773"="Inscription";"755"="Jewelcrafting";"165"="Leatherworking";"197"="Tailoring"}
$recipeInventory = foreach($ability in $currentTradeAbilities | Where-Object {
    $allowedTradeCategories.ContainsKey([string]$_.TradeSkillCategoryID) -and ($wrathRecipeSpellIDs.ContainsKey([string]$_.Spell) -or $houseDecorTradeCategories.ContainsKey([string]$_.TradeSkillCategoryID))
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

$mapIDs = @("113","114","115","116","117","118","119","120","121","123","125","127","170")
$mapInventory = foreach($id in $mapIDs){$map=$currentMapByID[$id];if(-not$map){throw "Missing current Wrath map $id"};[pscustomobject]@{status="wrath_support_confirmed";current_exists=$true;map_id=$map.ID;name=$map.Name_lang;parent_map_id=$map.ParentUiMapID;map_type=$map.Type;flags=$map.Flags}}
$factionNames = @{
    "1037"="Alliance Vanguard";"1050"="Valiance Expedition";"1052"="Horde Expedition";"1064"="The Taunka";"1067"="The Hand of Vengeance";
    "1068"="Explorers' League";"1073"="The Kalu'ak";"1085"="Warsong Offensive";"1090"="Kirin Tor";"1091"="The Wyrmrest Accord";
    "1094"="The Silver Covenant";"1098"="Knights of the Ebon Blade";"1104"="Frenzyheart Tribe";"1105"="The Oracles";"1106"="Argent Crusade";
    "1119"="The Sons of Hodir";"1124"="The Sunreavers";"1126"="The Frostborn";"1156"="The Ashen Verdict"
}
$currentFactionByID=New-Index $currentFactions
$factionInventory=foreach($id in $factionNames.Keys|Sort-Object {[int]$_}){$f=$currentFactionByID[$id];if(-not$f){throw "Missing current Wrath faction $id"};if($f.Name_lang-ne$factionNames[$id]){throw "Wrath faction $id name mismatch: '$($f.Name_lang)'"};[pscustomobject]@{status="wrath_support_confirmed";current_exists=$currentFactionIDs.ContainsKey($id);faction_id=$f.ID;name=$f.Name_lang;parent_faction_id=$f.ParentFactionID}}
$currencyNames = @{
    "61"="Dalaran Jewelcrafter's Token";"81"="Epicurean's Award";"101"="Emblem of Heroism";"102"="Emblem of Valor";
    "124"="Strand of the Ancients Mark of Honor";"126"="Wintergrasp Mark of Honor";"161"="Stone Keeper's Shard";"201"="Venture Coin";
    "221"="Emblem of Conquest";"241"="Champion's Seal";"301"="Emblem of Triumph";"321"="Isle of Conquest Mark of Honor";"341"="Emblem of Frost"
}
$currentCurrencyByID=New-Index $currentCurrencies
$currencyInventory=foreach($id in $currencyNames.Keys|Sort-Object {[int]$_}){$c=$currentCurrencyByID[$id];if(-not$c){throw "Missing current Wrath currency $id"};if($c.Name_lang-ne$currencyNames[$id]){throw "Wrath currency $id name mismatch: '$($c.Name_lang)'"};[pscustomobject]@{status="wrath_support_confirmed";current_exists=$currentCurrencyIDs.ContainsKey($id);currency_id=$c.ID;name=$c.Name_lang;category_id=$c.CategoryID;flags=$c.Flags}}

Assert-Equal $mountInventory.Count 110 "Wrath mount inventory count"
Assert-Equal $petInventory.Count 50 "Wrath pet inventory count"
Assert-Equal $toyInventory.Count 46 "Wrath toy inventory count"
Assert-Equal $decorInventory.Count 27 "Wrath decoration inventory count"
Assert-Equal $achievementInventory.Count 384 "Wrath achievement inventory count"
Assert-Equal $achievementCriteriaInventory.Count 1352 "Wrath achievement criteria inventory count"
Assert-Equal $recipeInventory.Count 860 "Wrath recipe inventory count"
Assert-Equal @($recipeInventory | Where-Object house_decor_recipe).Count 21 "Wrath house decor recipe count"
Assert-Equal $rareInventory.Count 23 "Wrath rare count"
Assert-Equal $mapInventory.Count 13 "Wrath map count"
Assert-Equal $factionInventory.Count 19 "Wrath faction count"
Assert-Equal $currencyInventory.Count 13 "Wrath currency count"
Assert-Equal @($achievementInventory | Where-Object { -not $_.current_exists }).Count 0 "Wrath missing current achievement count"
Assert-Equal @($recipeInventory | Where-Object { -not $_.current_spell_name_exists }).Count 0 "Wrath unnamed recipe count"

$taskAchievementIDs = @($achievementCriteriaInventory | Group-Object achievement_id | Where-Object { $_.Count -ge 2 -and $_.Count -le 30 } | ForEach-Object Name)
Assert-Equal $taskAchievementIDs.Count 239 "Wrath eligible task achievement count"
Assert-Equal @($achievementCriteriaInventory | Where-Object { [string]$_.achievement_id -in $taskAchievementIDs }).Count 1207 "Wrath eligible task criteria count"

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
    mounts=@{rows=@($mountInventory|Where-Object release_decision -eq "include_wrath"|Sort-Object {[int]$_.mount_id});expected=93;id="mount_id"}
    pets=@{rows=@($petInventory|Sort-Object {[int]$_.species_id});expected=50;id="species_id"}
    toys=@{rows=@($toyInventory|Where-Object release_decision -eq "include_wrath"|Sort-Object {[int]$_.toy_id});expected=36;id="toy_id"}
    decorations=@{rows=@($decorInventory|Sort-Object {[int]$_.decor_id});expected=27;id="decor_id"}
    achievements=@{rows=@($achievementInventory|Sort-Object {[int]$_.achievement_id});expected=384;id="achievement_id"}
    "achievement-criteria"=@{rows=@($achievementCriteriaInventory|Sort-Object {[int]$_.achievement_id},{Get-OrderPathSortKey $_.order_path});expected=1352;id="tree_id"}
    recipes=@{rows=@($recipeInventory|Sort-Object profession,{[int]$_.recipe_spell_id});expected=860;id="recipe_spell_id"}
    rares=@{rows=@($rareInventory|Sort-Object {Get-OrderPathSortKey $_.order_path});expected=23;id="tree_id"}
    treasures=@{rows=$treasureInventory;expected=0;id="tree_id"}
    "supporting-maps"=@{rows=$mapInventory;expected=13;id="map_id"}
    "supporting-factions"=@{rows=$factionInventory;expected=19;id="faction_id"}
    "supporting-currencies"=@{rows=$currencyInventory;expected=13;id="currency_id"}
}
$manifestSummary=@()
foreach($name in $manifests.Keys){$entry=$manifests[$name];Assert-Equal @($entry.rows).Count $entry.expected "Wrath $name manifest";Assert-UniqueField @($entry.rows) $entry.id "Wrath $name manifest";Write-CsvFile (Join-Path $ManifestRoot "$name.csv") @($entry.rows);$manifestSummary+=[pscustomobject]@{manifest=$name;rows=@($entry.rows).Count;identifier=$entry.id}}
Write-CsvFile (Join-Path $ManifestRoot "summary.csv") $manifestSummary

Write-Host "Generated Collectionist Wrath ID inventory"
$summary | Format-Table -AutoSize
Write-Host "Release manifests"
$manifestSummary | Format-Table -AutoSize
