param(
    [string]$HistoricalRoot = (Join-Path $env:TEMP "collectionist-legion-db2\legion"),
    [string]$TbcClassicRoot = (Join-Path $env:TEMP "collectionist-tbc-classic-db2"),
    [string]$CurrentDb2Root = (Join-Path $env:TEMP "collectionist-tww-db2\current"),
    [string]$CurrentSupportDb2Root = (Join-Path $env:TEMP "collectionist-df-db2\current"),
    [string]$AttRoot = (Join-Path $env:TEMP "collectionist-att-12007"),
    [string]$BlizzardCaptureJson = (Join-Path $env:TEMP "collectionist-tbc-blizzard-tables.json"),
    [string]$OutputRoot = (Join-Path $PSScriptRoot "..\research\collectionist\the-burning-crusade\ids"),
    [string]$ManifestRoot = (Join-Path $PSScriptRoot "..\research\collectionist\the-burning-crusade\manifests")
)

$ErrorActionPreference = "Stop"
$decorAuditPath = Join-Path $PSScriptRoot "..\research\collectionist\the-burning-crusade\sources\housing-wowdb-acquisition-audit.csv"
$blizzardSourcePath = Join-Path $PSScriptRoot "..\research\collectionist\the-burning-crusade\sources\blizzard-tbc-collectibles.csv"
$attDataRoot = Join-Path $AttRoot ".contrib\Parser\DATAS"
$attMountDbPath = Join-Path $attDataRoot "00 - DB\MountDB.lua"
$attPetDbPath = Join-Path $attDataRoot "00 - DB\PetDB.lua"
$attToyDbPath = Join-Path $attDataRoot "00 - DB\ToyDB.lua"

foreach ($required in @($HistoricalRoot, $TbcClassicRoot, $CurrentDb2Root, $CurrentSupportDb2Root, $AttRoot, $BlizzardCaptureJson, $decorAuditPath, $attMountDbPath, $attPetDbPath, $attToyDbPath)) {
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
$tbcRecipeSpellIDs = New-IDSet (Read-Table $TbcClassicRoot "SkillLineAbility") "Spell"

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
foreach ($expectation in @(@("mount",35),@("pet",47),@("toy",11))) {
    $rows = @($officialRows | Where-Object collectible_type -eq $expectation[0])
    Assert-Equal $rows.Count $expectation[1] "Blizzard TBC $($expectation[0]) guide row count"
    Assert-Equal @($rows | Where-Object mapped_id).Count $expectation[1] "Blizzard TBC mapped $($expectation[0]) count"
    Assert-Equal @($rows.mapped_id | Sort-Object -Unique).Count $expectation[1] "Blizzard TBC unique $($expectation[0]) count"
}

$mountPatchRows = @()
$patch = ""; $nyi = $false
foreach ($line in Get-Content -LiteralPath $attMountDbPath) {
    if ($line -match "-- PATCH ([0-9.]+) --") { $patch=$Matches[1]; $nyi=$false; continue }
    if ($line -match "^--- NYI ---") { $nyi=$true; continue }
    if ($patch -match "^2\." -and $line -match "^i\((\d+),\s*(\d+)\);\s*--\s*(.*)$") {
        $mountPatchRows += [pscustomobject]@{ patch=$patch; item_id=$Matches[1]; source_spell_id=$Matches[2]; source_name=$Matches[3]; nyi=$nyi }
    }
}
Assert-Equal $mountPatchRows.Count 111 "ATT TBC patch mount row count"
Assert-Equal @($mountPatchRows.source_spell_id | Sort-Object -Unique).Count 101 "ATT TBC unique patch mount spell count"
$mappedMountRows = foreach ($candidate in $mountPatchRows) {
    $mount = $currentMountBySpell[[string]$candidate.source_spell_id]
    if ($mount) { [pscustomobject]@{ candidate=$candidate; mount=$mount } }
}
Assert-Equal $mappedMountRows.Count 98 "ATT TBC current mapped mount row count"
$mountCandidateGroups = @($mappedMountRows | Group-Object { [string]$_.mount.ID })
Assert-Equal $mountCandidateGroups.Count 90 "ATT TBC unique current mount candidate count"

$mountClassicIDs = @("75","76","77","78","79","80","81","82")
$mountExternalIDs = @("125","196","197","211","212","222","224","230","243")
$mountInternalIDs = @("123","145","206","225","238")
$mountUnavailableIDs = @("169","199","201","207","223","241")
$mountUnavailableNotes = @{
    "169"="Gladiator season reward; season ended"; "199"="Original Zul'Aman timed-run reward removed"
    "201"="Original Brewfest Ram reward removed"; "207"="Gladiator season reward; season ended"
    "223"="Gladiator season reward; season ended"; "241"="Gladiator season reward; season ended"
}
$mountInventory = foreach ($group in $mountCandidateGroups | Sort-Object { [int]$_.Name }) {
    $rows=@($group.Group); $mount=$rows[0].mount; $id=[string]$mount.ID
    $decision = if ($id -in $mountClassicIDs) { "exclude_cross_expansion" } elseif ($id -in $mountExternalIDs) { "exclude_policy_external" } elseif ($id -in $mountInternalIDs) { "exclude_unobtainable_or_internal" } else { "include_tbc" }
    [pscustomobject]@{
        status=if($decision -eq "include_tbc"){"tbc_boundary_confirmed"}else{$decision}; release_decision=$decision
        acquisition_expansion=if($decision -eq "include_tbc"){"the_burning_crusade"}elseif($id -in $mountClassicIDs){"classic"}else{""}
        unavailable=$id -in $mountUnavailableIDs; availability_note=$mountUnavailableNotes[$id]
        current_exists=$currentMountByID.ContainsKey($id); official_guide_match=$officialIDs.mounts.ContainsKey($id)
        mount_id=$mount.ID; name=$mount.Name_lang; source_spell_id=$mount.SourceSpellID
        source_type_enum=$mount.SourceTypeEnum; flags=$mount.Flags; source_text=$mount.SourceText_lang
        source_patches=Join-IDs @($rows.candidate.patch); original_item_ids=Join-IDs @($rows.candidate.item_id)
        att_nyi=[bool]@($rows | Where-Object { $_.candidate.nyi }).Count
    }
}

$petItemToSpecies = @{}
foreach ($line in Get-Content -LiteralPath $attPetDbPath) {
    if ($line -match "^i\((\d+),\s*(\d+)\);") { $petItemToSpecies[$Matches[1]]=$Matches[2] }
}
$petPatchRows = @()
$patch=""; $nyi=$false
foreach ($line in Get-Content -LiteralPath $attPetDbPath) {
    if ($line -match "-- PATCH ([0-9.]+) --") { $patch=$Matches[1]; $nyi=$false; continue }
    if ($line -match "^--- NYI ---") { $nyi=$true; continue }
    if ($patch -match "^2\." -and $line -match "^i\((\d+),\s*(\d+)\);\s*--\s*(.*)$") {
        $petPatchRows += [pscustomobject]@{patch=$patch;item_id=$Matches[1];species_id=$Matches[2];source_name=$Matches[3];nyi=$nyi}
    }
}
Assert-Equal $petPatchRows.Count 46 "ATT TBC patch pet row count"
Assert-Equal @($petPatchRows.species_id | Sort-Object -Unique).Count 46 "ATT TBC unique patch pet species count"
$petPatchByID = @{}
foreach ($group in @($petPatchRows | Where-Object species_id -ne "0" | Group-Object species_id)) {
    if ($currentPetByID.ContainsKey([string]$group.Name)) { $petPatchByID[[string]$group.Name]=@($group.Group) }
}
Assert-IDValues @($petPatchRows.species_id | Where-Object { $_ -ne "0" -and -not $currentPetByID.ContainsKey([string]$_) }) @("154") "ATT TBC removed pet species"
Assert-Equal $petPatchByID.Count 44 "ATT TBC current patch pet candidate count"

$tbcSourceRoots = @(
    (Join-Path $attDataRoot "01 - Dungeons Raids\02 - Burning Crusade"),
    (Join-Path $attDataRoot "02 - Outdoor Zones\03 Outland"),
    (Join-Path $attDataRoot "06 - Expansion Features\02 - Burning Crusade"),
    (Join-Path $attDataRoot "08 - PvP\02 The Burning Crusade PvP Seasons.lua"),
    (Join-Path $attDataRoot "09 - Crafted Items\02 - Burning Crusade.lua"),
    (Join-Path $attDataRoot "03 - World Drops\01 Rooted\2 - Burning Crusade.lua")
)
$petSourceTreeIDs = @{}
foreach ($root in $tbcSourceRoots) {
    $files = if ((Get-Item -LiteralPath $root).PSIsContainer) { @(Get-ChildItem -LiteralPath $root -Recurse -File -Filter "*.lua") } else { @(Get-Item -LiteralPath $root) }
    foreach ($file in $files) {
        foreach ($line in Get-Content -LiteralPath $file.FullName) {
            foreach ($match in [regex]::Matches($line,"\bi\((\d+)")) {
                $speciesID=$petItemToSpecies[$match.Groups[1].Value]
                if ($speciesID -and $currentPetByID.ContainsKey([string]$speciesID)) { $petSourceTreeIDs[[string]$speciesID]=$true }
            }
            foreach ($match in [regex]::Matches($line,"\bp\((\d+)")) {
                $speciesID=$match.Groups[1].Value
                if ($currentPetByID.ContainsKey([string]$speciesID)) { $petSourceTreeIDs[[string]$speciesID]=$true }
            }
        }
    }
}
Assert-Equal $petSourceTreeIDs.Count 43 "ATT TBC current source-tree pet candidate count"
$petCandidateIDs = @($officialIDs.pets.Keys + $petPatchByID.Keys + $petSourceTreeIDs.Keys | Sort-Object -Unique)
Assert-Equal $petCandidateIDs.Count 85 "TBC pet inventory candidate count"
$petExternalIDs = @("111","1168","121","130","131","154","155","156","168","169","170","171","179","180","183","189")
$petClassicIDs = @("44","51","55","57","78")
$petInventory = foreach ($id in $petCandidateIDs | Sort-Object { [int]$_ }) {
    $pet=$currentPetByID[$id]; if(-not $pet){throw "Missing current TBC pet species $id"}
    $creature=$creatureByID[[string]$pet.CreatureID]; $patchRows=@($petPatchByID[$id])
    $decision = if ($id -in $petExternalIDs) { "exclude_policy_external" } elseif ($id -in $petClassicIDs) { "exclude_cross_expansion" } else { "include_tbc" }
    [pscustomobject]@{
        status=if($decision -eq "include_tbc"){"tbc_acquisition_confirmed"}else{$decision}; release_decision=$decision
        acquisition_expansion=if($decision -eq "include_tbc"){"the_burning_crusade"}elseif($id -in $petClassicIDs){"classic"}else{""}
        unavailable=$false; availability_note=""; current_exists=$true; official_guide_match=$officialIDs.pets.ContainsKey($id)
        tbc_source_tree_match=$petSourceTreeIDs.ContainsKey($id); att_patch_match=$petPatchByID.ContainsKey($id)
        species_id=$pet.ID; name=if($creature){$creature.Name_lang}else{""}; creature_id=$pet.CreatureID; summon_spell_id=$pet.SummonSpellID
        pet_type_enum=$pet.PetTypeEnum; flags=$pet.Flags; source_type_enum=$pet.SourceTypeEnum; source_text=$pet.SourceText_lang
        source_patches=Join-IDs @($patchRows.patch); original_item_ids=Join-IDs @($patchRows.item_id); att_nyi=[bool]@($patchRows | Where-Object nyi).Count
    }
}

$toyPatchRows = @()
$patch=""
foreach ($line in Get-Content -LiteralPath $attToyDbPath) {
    if ($line -match "-- PATCH ([0-9.]+) --") { $patch=$Matches[1] }
    if ($patch -match "^2\." -and $line -match "^i\((\d+)\);\s*--\s*(.*)$") {
        $toyPatchRows += [pscustomobject]@{patch=$patch;original_item_id=$Matches[1];source_name=$Matches[2]}
    }
}
Assert-Equal $toyPatchRows.Count 22 "ATT TBC patch toy row count"
$toyReplacementItems = @{"30847"="134021"}
$toyUnmappedItemIDs=@(); $toyMappedCandidates=@()
foreach($candidate in $toyPatchRows){
    $originalItemID=[string]$candidate.original_item_id
    $itemID=if($toyReplacementItems.ContainsKey($originalItemID)){$toyReplacementItems[$originalItemID]}else{$originalItemID}
    $toy=$currentToyByItem[$itemID]
    if(-not$toy){$toyUnmappedItemIDs+=$originalItemID;continue}
    $toyMappedCandidates += [pscustomobject]@{patch=$candidate.patch;original_item_id=$originalItemID;item_id=$itemID;source_name=$candidate.source_name;toy=$toy}
}
Assert-IDValues $toyUnmappedItemIDs @("23821","31337","37863") "ATT TBC intentionally unmapped toy-like items"
Assert-Equal $toyMappedCandidates.Count 19 "ATT TBC current mapped toy candidate count"
$toyExtraCandidates = @{
    "64456"="4.0.3";"64457"="4.0.3";"129926"="6.2.3";"129929"="6.2.3";"134004"="7.0.3";"134007"="7.0.3";
    "134019"="7.0.3";"136934"="7.0.3";"136935"="7.0.3";"136937"="7.0.3";"138490"="7.0.3";"151016"="7.3.0";"151184"="7.3.0"
}
foreach($itemID in $toyExtraCandidates.Keys){
    $toy=$currentToyByItem[$itemID];if(-not$toy){throw "Missing current TBC source-owned toy item $itemID"}
    $item=$currentItems[$itemID]
    $toyMappedCandidates += [pscustomobject]@{patch=$toyExtraCandidates[$itemID];original_item_id=$itemID;item_id=$itemID;source_name=if($item){$item.Display_lang}else{""};toy=$toy}
}
Assert-Equal $toyMappedCandidates.Count 32 "TBC toy inventory candidate count"
$toyExternalItemIDs=@("32542","32566","33079","33219","33223","34499","35227","38301")
$toyCataclysmItemIDs=@("64456","64457")
$toySourceOverrides = @{
    "136934"="|cFFFFD200Vendor:|r Elementalist Sharvak / Flamesmith Lanying|n|cFFFFD200Class:|r Shaman"
    "136935"="|cFFFFD200Vendor:|r Elementalist Sharvak / Flamesmith Lanying|n|cFFFFD200Class:|r Shaman"
    "136937"="|cFFFFD200Vendor:|r Elementalist Sharvak / Flamesmith Lanying|n|cFFFFD200Class:|r Shaman"
    "138490"="|cFFFFD200Vendor:|r Elementalist Sharvak / Flamesmith Lanying|n|cFFFFD200Class:|r Shaman"
}
$toyInventory=foreach($candidate in $toyMappedCandidates){
    $originalItemID=[string]$candidate.original_item_id;$toy=$candidate.toy;$item=$currentItems[[string]$toy.ItemID]
    $decision=if($originalItemID -in $toyExternalItemIDs){"exclude_policy_external"}elseif($originalItemID -in $toyCataclysmItemIDs){"exclude_cross_expansion"}else{"include_tbc"}
    [pscustomobject]@{
        status=if($decision -eq "include_tbc"){"tbc_source_confirmed"}else{$decision};release_decision=$decision
        acquisition_expansion=if($decision -eq "include_tbc"){"the_burning_crusade"}elseif($originalItemID -in $toyCataclysmItemIDs){"cataclysm"}else{""}
        unavailable=$false;current_exists=$true;official_guide_match=$officialIDs.toys.ContainsKey([string]$toy.ID)
        toy_id=$toy.ID;item_id=$toy.ItemID;original_item_id=$originalItemID;name=if($item){$item.Display_lang}else{$candidate.source_name}
        source_patch=$candidate.patch;source_type_enum=$toy.SourceTypeEnum;flags=$toy.Flags
        source_text=if($toySourceOverrides.ContainsKey([string]$toy.ItemID)){$toySourceOverrides[[string]$toy.ItemID]}else{$toy.SourceText_lang}
    }
}

$tbcAchievementCategoryIDs = @("14779","14803","14805","14862","14865")
$tbcStarterZoneAchievementIDs = @("858","859","860","861","868","4908","4926")
$selectedTbcAchievements = @($historicalAchievements | Where-Object { [string]$_.Category -in $tbcAchievementCategoryIDs -or [string]$_.ID -in $tbcStarterZoneAchievementIDs })
$achievementInventory = foreach ($achievement in $selectedTbcAchievements) {
    $category=$historicalAchievementCategoryByID[[string]$achievement.Category]
    [pscustomobject]@{
        status="tbc_category_confirmed";current_exists=$currentAchievementIDs.ContainsKey([string]$achievement.ID)
        achievement_id=$achievement.ID;title=$achievement.Title_lang;description=$achievement.Description_lang
        category_id=$achievement.Category;category_name=if($category){$category.Name_lang}else{$null}
        criteria_tree_id=$achievement.Criteria_tree;flags=$achievement.Flags;points=$achievement.Points
    }
}
$criteriaByID=New-Index $historicalCriteria;$criteriaChildren=@{}
foreach($node in $historicalCriteriaTrees){
    if(-not$criteriaChildren.ContainsKey([string]$node.Parent)){$criteriaChildren[[string]$node.Parent]=[System.Collections.Generic.List[object]]::new()}
    $criteriaChildren[[string]$node.Parent].Add($node)
}
function Get-CriteriaLeaves([string]$RootID){
    if(-not$RootID-or$RootID-eq"0"){return}
    $queue=[System.Collections.Generic.Queue[object]]::new();$queue.Enqueue(@($RootID,""))
    while($queue.Count){
        $pair=$queue.Dequeue()
        foreach($node in @($criteriaChildren[[string]$pair[0]]|Sort-Object{[int]$_.OrderIndex})){
            $path=if($pair[1]){"$($pair[1])/$($node.OrderIndex)"}else{[string]$node.OrderIndex}
            if($node.CriteriaID-ne"0"){$criterion=$criteriaByID[[string]$node.CriteriaID];[pscustomobject]@{order_path=$path;tree_id=$node.ID;description=$node.Description_lang;criteria_id=$node.CriteriaID;criteria_type=if($criterion){$criterion.Type}else{$null};asset_id=if($criterion){$criterion.Asset}else{$null};amount=$node.Amount;operator=$node.Operator}}
            else{$queue.Enqueue(@([string]$node.ID,$path))}
        }
    }
}
$achievementCriteriaInventory=foreach($achievement in $selectedTbcAchievements|Where-Object{$_.Criteria_tree-ne"0"}){
    foreach($leaf in(Get-CriteriaLeaves([string]$achievement.Criteria_tree))){[pscustomobject]@{achievement_id=$achievement.ID;title=$achievement.Title_lang;category_id=$achievement.Category;order_path=$leaf.order_path;tree_id=$leaf.tree_id;description=$leaf.description;criteria_id=$leaf.criteria_id;criteria_type=$leaf.criteria_type;asset_id=$leaf.asset_id;amount=$leaf.amount;operator=$leaf.operator}}
}
$rareInventory=foreach($row in $achievementCriteriaInventory|Where-Object achievement_id -eq "1312"){
    [pscustomobject]@{achievement_id=$row.achievement_id;achievement=$row.title;order_path=$row.order_path;tree_id=$row.tree_id;criterion=$row.description;criteria_id=$row.criteria_id;criteria_type=$row.criteria_type;criteria_asset=$row.asset_id;npc_id=$row.asset_id;completion_quest_id="";object_id="";selection_decision="include_tbc"}
}
$treasureInventory=@()

$tradeCategoryChildren=@{};$tradeCategoryByID=New-Index $currentTradeCategories
foreach($category in $currentTradeCategories){$parent=[string]$category.ParentTradeSkillCategoryID;if(-not$tradeCategoryChildren.ContainsKey($parent)){$tradeCategoryChildren[$parent]=[System.Collections.Generic.List[string]]::new()};$tradeCategoryChildren[$parent].Add([string]$category.ID)}
$tbcTradeRoots=@("601","583","73","664","718","768","814","881","955")
$allowedTradeCategories=@{};$tradeQueue=[System.Collections.Generic.Queue[string]]::new();foreach($root in $tbcTradeRoots){$tradeQueue.Enqueue($root)}
while($tradeQueue.Count){$id=$tradeQueue.Dequeue();if($allowedTradeCategories.ContainsKey($id)){continue};$allowedTradeCategories[$id]=$true;foreach($child in @($tradeCategoryChildren[$id])){$tradeQueue.Enqueue($child)}}
$houseDecorTradeCategories=@{};foreach($id in $allowedTradeCategories.Keys){if($tradeCategoryByID[$id]-and$tradeCategoryByID[$id].Name_lang-eq"House Decor"){$houseDecorTradeCategories[$id]=$true}}
$professionNames=@{"171"="Alchemy";"164"="Blacksmithing";"185"="Cooking";"333"="Enchanting";"202"="Engineering";"773"="Inscription";"755"="Jewelcrafting";"165"="Leatherworking";"197"="Tailoring"}
$recipeInventory=foreach($ability in $currentTradeAbilities|Where-Object{$allowedTradeCategories.ContainsKey([string]$_.TradeSkillCategoryID)-and($tbcRecipeSpellIDs.ContainsKey([string]$_.Spell)-or$houseDecorTradeCategories.ContainsKey([string]$_.TradeSkillCategoryID))}){
    $spell=$currentSpellNameByID[[string]$ability.Spell];$category=$tradeCategoryByID[[string]$ability.TradeSkillCategoryID]
    [pscustomobject]@{status="named_recipe";current_ability_exists=$true;current_spell_name_exists=[bool]($spell-and$spell.Name_lang);profession=$professionNames[[string]$ability.SkillLine];profession_id=$ability.SkillLine;recipe_spell_id=$ability.Spell;name=if($spell){$spell.Name_lang}else{$null};skill_line_ability_id=$ability.ID;trade_category_id=$ability.TradeSkillCategoryID;trade_category_name=if($category){$category.Name_lang}else{$null};house_decor_recipe=$houseDecorTradeCategories.ContainsKey([string]$ability.TradeSkillCategoryID);acquire_method=$ability.AcquireMethod;supercedes_spell_id=$ability.SupercedesSpell}
}
$decorInventory=foreach($row in Import-Csv -LiteralPath $decorAuditPath){[pscustomobject]@{status=$row.status;current_exists=$true;decor_id=$row.decor_id;item_id=$row.item_id;name=$row.catalog_name;catalog_scope=$row.catalog_scope;acquisition_expansion=$row.acquisition_expansion;source_kind=$row.source_kind;source_text=$row.source_text;achievement_ids=$row.achievement_ids;quest_ids=$row.quest_ids;npc_ids=$row.npc_ids;source_spell_ids=$row.source_spell_ids;currency_ids=$row.currency_ids;acquisition_source_url=$row.acquisition_source_url}}

$mapIDs=@("94","95","97","100","101","102","103","104","105","106","107","108","109","110","111","122")
$mapInventory=foreach($id in $mapIDs){$map=$currentMapByID[$id];if(-not$map){throw"Missing current TBC map $id"};[pscustomobject]@{status="tbc_support_confirmed";current_exists=$true;map_id=$map.ID;name=$map.Name_lang;parent_map_id=$map.ParentUiMapID;map_type=$map.Type;flags=$map.Flags}}
$factionNames=@{
    "911"="Silvermoon City";"922"="Tranquillien";"930"="Exodar";"932"="The Aldor";"933"="The Consortium";"934"="The Scryers";"935"="The Sha'tar";
    "941"="The Mag'har";"942"="Cenarion Expedition";"946"="Honor Hold";"947"="Thrallmar";"967"="The Violet Eye";"970"="Sporeggar";"978"="Kurenai";"989"="Keepers of Time";
    "990"="The Scale of the Sands";"1011"="Lower City";"1012"="Ashtongue Deathsworn";"1015"="Netherwing";"1031"="Sha'tari Skyguard";"1038"="Ogri'la";"1077"="Shattered Sun Offensive"
}
$currentFactionByID=New-Index $currentFactions
$factionInventory=foreach($id in $factionNames.Keys|Sort-Object{[int]$_}){$f=$currentFactionByID[$id];if(-not$f){throw"Missing current TBC faction $id"};if($f.Name_lang-ne$factionNames[$id]){throw"TBC faction $id name mismatch: '$($f.Name_lang)'"};[pscustomobject]@{status="tbc_support_confirmed";current_exists=$currentFactionIDs.ContainsKey($id);faction_id=$f.ID;name=$f.Name_lang;parent_faction_id=$f.ParentFactionID}}
$currencyNames=@{"42"="Badge of Justice";"103"="Arena Points";"123"="Eye of the Storm Mark of Honor";"1166"="Timewarped Badge";"1704"="Spirit Shard"}
$currentCurrencyByID=New-Index $currentCurrencies
$currencyInventory=foreach($id in $currencyNames.Keys|Sort-Object{[int]$_}){$c=$currentCurrencyByID[$id];if(-not$c){throw"Missing current TBC currency $id"};if($c.Name_lang-ne$currencyNames[$id]){throw"TBC currency $id name mismatch: '$($c.Name_lang)'"};[pscustomobject]@{status="tbc_support_confirmed";current_exists=$currentCurrencyIDs.ContainsKey($id);currency_id=$c.ID;name=$c.Name_lang;category_id=$c.CategoryID;flags=$c.Flags}}

Assert-Equal $mountInventory.Count 90 "TBC mount inventory count"
Assert-Equal @($mountInventory|Where-Object release_decision -eq "include_tbc").Count 68 "TBC mount manifest count"
Assert-Equal $petInventory.Count 85 "TBC pet inventory count"
Assert-Equal @($petInventory|Where-Object release_decision -eq "include_tbc").Count 65 "TBC pet manifest count"
Assert-Equal $toyInventory.Count 32 "TBC toy inventory count"
Assert-Equal @($toyInventory|Where-Object release_decision -eq "include_tbc").Count 22 "TBC toy manifest count"
Assert-Equal $decorInventory.Count 29 "TBC decoration inventory count"
Assert-Equal $achievementInventory.Count 99 "TBC achievement inventory count"
Assert-Equal $achievementCriteriaInventory.Count 845 "TBC achievement criteria inventory count"
Assert-Equal $rareInventory.Count 20 "TBC rare count"
Assert-Equal $recipeInventory.Count 755 "TBC recipe inventory count"
Assert-Equal @($recipeInventory|Where-Object house_decor_recipe).Count 26 "TBC house decor recipe count"
Assert-Equal $mapInventory.Count 16 "TBC map count"
Assert-Equal $factionInventory.Count 22 "TBC faction count"
Assert-Equal $currencyInventory.Count 5 "TBC currency count"
Assert-Equal @($achievementInventory|Where-Object{-not$_.current_exists}).Count 0 "TBC missing current achievement count"
Assert-Equal @($recipeInventory|Where-Object{-not$_.current_spell_name_exists}).Count 0 "TBC unnamed recipe count"
Assert-IDValues @($officialIDs.mounts.Keys) @($mountInventory|Where-Object official_guide_match|ForEach-Object mount_id) "TBC official mount guide set"
Assert-IDValues @($officialIDs.pets.Keys) @($petInventory|Where-Object official_guide_match|ForEach-Object species_id) "TBC official pet guide set"
Assert-IDValues @($officialIDs.toys.Keys) @($toyInventory|Where-Object official_guide_match|ForEach-Object toy_id) "TBC official toy guide set"

$taskAchievementIDs=@($achievementCriteriaInventory|Group-Object achievement_id|Where-Object{$_.Count-ge2-and$_.Count-le30}|ForEach-Object Name)
Assert-Equal $taskAchievementIDs.Count 65 "TBC eligible task achievement count"
Assert-Equal @($achievementCriteriaInventory|Where-Object{[string]$_.achievement_id-in$taskAchievementIDs}).Count 651 "TBC eligible task criteria count"

$summary=@()
$summary+=Export-Inventory "mounts" $mountInventory
$summary+=Export-Inventory "pets" $petInventory
$summary+=Export-Inventory "toys" $toyInventory
$summary+=Export-Inventory "decorations" $decorInventory
$summary+=Export-Inventory "achievements" $achievementInventory
$summary+=Export-Inventory "achievement-criteria" @($achievementCriteriaInventory|Sort-Object{[int]$_.achievement_id},{Get-OrderPathSortKey $_.order_path})
$summary+=Export-Inventory "rares" $rareInventory
$summary+=Export-Inventory "treasures" $treasureInventory
$summary+=Export-Inventory "recipes" @($recipeInventory|Sort-Object profession,{[int]$_.recipe_spell_id})
$summary+=Export-Inventory "maps" $mapInventory
$summary+=Export-Inventory "factions" $factionInventory
$summary+=Export-Inventory "currencies" $currencyInventory
Write-CsvFile (Join-Path $OutputRoot "summary.csv") $summary

$manifests=[ordered]@{
    mounts=@{rows=@($mountInventory|Where-Object release_decision -eq "include_tbc"|Sort-Object{[int]$_.mount_id});expected=68;id="mount_id"}
    pets=@{rows=@($petInventory|Where-Object release_decision -eq "include_tbc"|Sort-Object{[int]$_.species_id});expected=65;id="species_id"}
    toys=@{rows=@($toyInventory|Where-Object release_decision -eq "include_tbc"|Sort-Object{[int]$_.toy_id});expected=22;id="toy_id"}
    decorations=@{rows=@($decorInventory|Sort-Object{[int]$_.decor_id});expected=29;id="decor_id"}
    achievements=@{rows=@($achievementInventory|Sort-Object{[int]$_.achievement_id});expected=99;id="achievement_id"}
    "achievement-criteria"=@{rows=@($achievementCriteriaInventory|Sort-Object{[int]$_.achievement_id},{Get-OrderPathSortKey $_.order_path});expected=845;id="tree_id"}
    recipes=@{rows=@($recipeInventory|Sort-Object profession,{[int]$_.recipe_spell_id});expected=755;id="recipe_spell_id"}
    rares=@{rows=@($rareInventory|Sort-Object{Get-OrderPathSortKey $_.order_path});expected=20;id="tree_id"}
    treasures=@{rows=$treasureInventory;expected=0;id="tree_id"}
    "supporting-maps"=@{rows=$mapInventory;expected=16;id="map_id"}
    "supporting-factions"=@{rows=$factionInventory;expected=22;id="faction_id"}
    "supporting-currencies"=@{rows=$currencyInventory;expected=5;id="currency_id"}
}
$manifestSummary=@()
foreach($name in $manifests.Keys){$entry=$manifests[$name];Assert-Equal @($entry.rows).Count $entry.expected "TBC $name manifest";Assert-UniqueField @($entry.rows) $entry.id "TBC $name manifest";Write-CsvFile (Join-Path $ManifestRoot "$name.csv") @($entry.rows);$manifestSummary+=[pscustomobject]@{manifest=$name;rows=@($entry.rows).Count;identifier=$entry.id}}
Write-CsvFile (Join-Path $ManifestRoot "summary.csv") $manifestSummary

Write-Host "Generated Collectionist TBC ID inventory"
$summary|Format-Table -AutoSize
Write-Host "Release manifests"
$manifestSummary|Format-Table -AutoSize
