param(
    [string]$Db2Root = (Join-Path $env:TEMP "collectionist-bfa-db2"),
    [string]$CurrentDb2Root = (Join-Path $env:TEMP "collectionist-df-db2\current"),
    [string]$CurrentTradeDb2Root = (Join-Path $env:TEMP "collectionist-tww-db2\current"),
    [string]$AttRoot = (Join-Path $env:TEMP "collectionist-att-12007"),
    [string]$OutputRoot = (Join-Path $PSScriptRoot "..\research\collectionist\battle-for-azeroth\ids"),
    [string]$ManifestRoot = (Join-Path $PSScriptRoot "..\research\collectionist\battle-for-azeroth\manifests")
)

$ErrorActionPreference = "Stop"
$decorAuditPath = Join-Path $PSScriptRoot "..\research\collectionist\battle-for-azeroth\sources\housing-wowdb-acquisition-audit.csv"
$rareNPCAuditPath = Join-Path $PSScriptRoot "..\research\collectionist\battle-for-azeroth\sources\rare-npc-audit.csv"
$legionRoot = Join-Path $Db2Root "legion"
$bfaRoot = Join-Path $Db2Root "bfa"
$attZonePath = Join-Path $AttRoot "db\Standard\Categories\Zones.lua"

foreach ($required in @($legionRoot, $bfaRoot, $CurrentDb2Root, $CurrentTradeDb2Root, $attZonePath)) {
    if (-not (Test-Path -LiteralPath $required)) { throw "Missing input directory: $required" }
}
New-Item -ItemType Directory -Force -Path $OutputRoot | Out-Null
New-Item -ItemType Directory -Force -Path $ManifestRoot | Out-Null

function Read-Table([string]$root, [string]$name) {
    $path = Join-Path $root "$name.csv"
    if (-not (Test-Path -LiteralPath $path)) { throw "Missing DB2 table: $path" }
    return @(Import-Csv -LiteralPath $path)
}
function New-Index($rows, [string]$field = "ID") {
    $index = @{}
    foreach ($row in $rows) { $index[[string]$row.$field] = $row }
    return $index
}
function New-IDSet($rows, [string]$field = "ID") {
    $set = @{}
    foreach ($row in $rows) { $set[[string]$row.$field] = $true }
    return $set
}
function Get-NewRows($oldRows, $newRows) {
    $oldIDs = New-IDSet $oldRows
    return @($newRows | Where-Object { -not $oldIDs.ContainsKey([string]$_.ID) })
}
function Join-IDs($values) {
    return (@($values | Where-Object { $_ } | Sort-Object -Unique) -join ";")
}
function Get-OrderPathSortKey([string]$path) {
    return ((@($path -split "/") | ForEach-Object { "{0:D8}" -f [int]$_ }) -join "/")
}
function Write-CsvFile([string]$path, $rows) {
    $lines = @($rows) | ConvertTo-Csv -NoTypeInformation
    $text = if ($lines.Count) { ($lines -join "`n") + "`n" } else { "" }
    $text = $text.Replace("`r`n", "`n").Replace("`r", "`n")
    [System.IO.File]::WriteAllText($path, $text, [System.Text.UTF8Encoding]::new($false))
}
function Export-Inventory([string]$name, $rows) {
    Write-CsvFile (Join-Path $OutputRoot "$name.csv") @($rows)
    return [pscustomobject]@{ file = $name; rows = @($rows).Count }
}
function Assert-Equal($actual, $expected, [string]$label) {
    if ([int]$actual -ne [int]$expected) { throw "$label mismatch: expected $expected, got $actual" }
}
function Assert-UniqueField($rows, [string]$field, [string]$label) {
    $duplicates = @($rows | Group-Object $field | Where-Object Count -gt 1)
    if ($duplicates.Count) { throw "$label contains duplicate ${field}: $($duplicates.Name -join ', ')" }
}

$legionMounts = Read-Table $legionRoot "Mount"
$bfaMounts = Read-Table $bfaRoot "Mount"
$legionPets = Read-Table $legionRoot "BattlePetSpecies"
$bfaPets = Read-Table $bfaRoot "BattlePetSpecies"
$legionToys = Read-Table $legionRoot "Toy"
$bfaToys = Read-Table $bfaRoot "Toy"
$legionAchievements = Read-Table $legionRoot "Achievement"
$bfaAchievements = Read-Table $bfaRoot "Achievement"
$legionCurrencies = Read-Table $legionRoot "CurrencyTypes"
$bfaCurrencies = Read-Table $bfaRoot "CurrencyTypes"

$currentMountIDs = New-IDSet (Read-Table $CurrentDb2Root "Mount")
$currentPetIDs = New-IDSet (Read-Table $CurrentDb2Root "BattlePetSpecies")
$currentToyIDs = New-IDSet (Read-Table $CurrentDb2Root "Toy")
$currentAchievementIDs = New-IDSet (Read-Table $CurrentDb2Root "Achievement")
$currentRecipeSpellIDs = New-IDSet (Read-Table $CurrentDb2Root "SkillLineAbility") "Spell"
$currentSpellNameIDs = New-IDSet (Read-Table $CurrentDb2Root "SpellName")
$currentTradeSkillCategories = Read-Table $CurrentTradeDb2Root "TradeSkillCategory"
$currentTradeSkillAbilities = Read-Table $CurrentTradeDb2Root "SkillLineAbility"
$currentTradeSpellNames = New-Index (Read-Table $CurrentTradeDb2Root "SpellName")
$currentCurrencyRows = Read-Table $CurrentDb2Root "CurrencyTypes"
$currentCurrencyIDs = New-IDSet $currentCurrencyRows
$currentFactionIDs = New-IDSet (Read-Table $CurrentDb2Root "Faction")
$currentMapIDs = New-IDSet (Read-Table $CurrentDb2Root "UiMap")
$currentItems = New-Index (Read-Table $CurrentDb2Root "ItemSparse")
$currentDecorByID = New-Index (Read-Table $CurrentDb2Root "HouseDecor")

$items = New-Index (Read-Table $bfaRoot "ItemSparse")
$creatures = Read-Table $bfaRoot "Creature"
$itemEffects = Read-Table $bfaRoot "ItemEffect"
$achievementCategories = Read-Table $bfaRoot "Achievement_Category"
$achievementCategoryByID = New-Index $achievementCategories
$criteriaByID = New-Index (Read-Table $bfaRoot "Criteria")
$criteriaTreeRows = Read-Table $bfaRoot "CriteriaTree"
$tradeSkillCategories = Read-Table $bfaRoot "TradeSkillCategory"
$skillLineAbilities = Read-Table $bfaRoot "SkillLineAbility"
$spellNames = New-Index (Read-Table $bfaRoot "SpellName")
$bfaFactionRows = Read-Table $bfaRoot "Faction"
$bfaMapRows = Read-Table $bfaRoot "UiMap"

if (-not (Test-Path -LiteralPath $decorAuditPath)) { throw "Missing housing audit: $decorAuditPath" }
$decorAuditRows = @(Import-Csv -LiteralPath $decorAuditPath)

$itemsBySpell = @{}
foreach ($effect in $itemEffects) {
    if (-not $effect.SpellID -or $effect.SpellID -eq "0" -or -not $effect.ParentItemID -or $effect.ParentItemID -eq "0") { continue }
    $spellID = [string]$effect.SpellID
    if (-not $itemsBySpell.ContainsKey($spellID)) { $itemsBySpell[$spellID] = [System.Collections.Generic.List[string]]::new() }
    $itemsBySpell[$spellID].Add([string]$effect.ParentItemID)
}

$externalPattern = "In[- ]Game Shop|Trading Post|Promotion|Recruit-A-Friend|Legacy|WoW Esports|Blizz[Cc]on|Mythic Dungeon International"
$mountExternalIDs = @("32", "996", "997", "1011", "1051", "1193", "1221", "1222", "1223", "1266", "1267", "1269", "1270", "1271", "1272", "1287", "1288", "1289", "1290", "1291", "1312", "1330", "1346")
$mountInternalIDs = @("1069", "1071")
$petExternalIDs = @("2143", "2184", "2185", "2623", "2776", "2777", "2778", "2779", "2780")
$petInternalIDs = @("2480")
$mopPetIDs = @("2579", "2580", "2581", "2582", "2583", "2584", "2585", "2586", "2587", "2589", "2590")
$toyExternalIDs = @("823", "824", "913", "914", "926", "981")
$toyInternalIDs = @("929", "953")
$bfaGladiatorMountIDs = @("1030", "1031", "1032", "1035")
$bfaUnavailableMountIDs = @($bfaGladiatorMountIDs + @("1220", "1265", "1326"))
$toySourceOverrides = @{
    "686" = "|cFFFFD200Secret:|r Secret of the Depths|n|cFFFFD200Zone:|r Tiragarde Sound"
}

$mountInventory = foreach ($mount in (Get-NewRows $legionMounts $bfaMounts)) {
    $itemIDs = @($itemsBySpell[[string]$mount.SourceSpellID])
    $itemExpansionIDs = @($itemIDs | ForEach-Object { $item = $items[[string]$_]; if ($item) { $item.ExpansionID } })
    [pscustomobject]@{
        status = if ($mount.SourceText_lang -match $externalPattern) { "policy_external_candidate" } elseif ($itemExpansionIDs -contains "7") { "item_expansion_signal" } else { "snapshot_candidate" }
        release_decision = if ([string]$mount.ID -in $mountExternalIDs) { "exclude_policy_external" } elseif ([string]$mount.ID -in $mountInternalIDs) { "exclude_unobtainable_or_internal" } else { "include_bfa" }
        unavailable = [string]$mount.ID -in $bfaUnavailableMountIDs
        availability_note = if ([string]$mount.ID -in $bfaGladiatorMountIDs) { "Battle for Azeroth Gladiator season reward; season ended" } elseif ([string]$mount.ID -eq "1220") { "Battle for Azeroth Brawler's Guild murder-mystery questline; removed in patch 9.0.1" } elseif ([string]$mount.ID -eq "1265") { "Battle for Azeroth Ahead of the Curve quest reward; removed with Shadowlands" } elseif ([string]$mount.ID -eq "1326") { "Battle for Azeroth Keystone Master season 4 reward; season ended" } else { $null }
        current_exists = $currentMountIDs.ContainsKey([string]$mount.ID)
        mount_id = $mount.ID
        name = $mount.Name_lang
        source_spell_id = $mount.SourceSpellID
        item_ids = Join-IDs $itemIDs
        item_expansion_ids = Join-IDs $itemExpansionIDs
        source_type_enum = $mount.SourceTypeEnum
        flags = $mount.Flags
        source_text = $mount.SourceText_lang
    }
}

$historicalCreatureByID = New-Index $creatures
$petInventory = foreach ($pet in (Get-NewRows $legionPets $bfaPets)) {
    $itemIDs = @($itemsBySpell[[string]$pet.SummonSpellID])
    $itemExpansionIDs = @($itemIDs | ForEach-Object { $item = $items[[string]$_]; if ($item) { $item.ExpansionID } })
    $creature = $historicalCreatureByID[[string]$pet.CreatureID]
    $noncollectible = $pet.SummonSpellID -eq "0" -or [int]$pet.SourceTypeEnum -lt 0
    [pscustomobject]@{
        status = if ([string]$pet.ID -in $mopPetIDs) { "mop_acquisition_boundary" } elseif ($noncollectible) { "noncollectible_pet_battle_npc" } elseif ($pet.SourceText_lang -match $externalPattern) { "policy_external_candidate" } else { "snapshot_candidate" }
        release_decision = if ([string]$pet.ID -in $mopPetIDs) { "exclude_mop" } elseif ($noncollectible) { "exclude_noncollectible" } elseif ([string]$pet.ID -in $petExternalIDs) { "exclude_policy_external" } elseif ([string]$pet.ID -in $petInternalIDs) { "exclude_unobtainable_or_internal" } else { "include_bfa" }
        unavailable = $false
        availability_note = $null
        current_exists = $currentPetIDs.ContainsKey([string]$pet.ID)
        species_id = $pet.ID
        name = if ($creature) { $creature.Name_lang } else { $null }
        creature_id = $pet.CreatureID
        summon_spell_id = $pet.SummonSpellID
        item_ids = Join-IDs $itemIDs
        item_expansion_ids = Join-IDs $itemExpansionIDs
        pet_type_enum = $pet.PetTypeEnum
        flags = $pet.Flags
        source_type_enum = $pet.SourceTypeEnum
        source_text = $pet.SourceText_lang
    }
}

$toyInventory = foreach ($toy in (Get-NewRows $legionToys $bfaToys)) {
    $item = $items[[string]$toy.ItemID]
    if (-not $item) { $item = $currentItems[[string]$toy.ItemID] }
    $sourceText = if ($toySourceOverrides.ContainsKey([string]$toy.ID)) { $toySourceOverrides[[string]$toy.ID] } else { $toy.SourceText_lang }
    [pscustomobject]@{
        status = if ($sourceText -match $externalPattern) { "policy_external_candidate" } elseif ($item -and $item.ExpansionID -eq "7") { "item_expansion_signal" } else { "snapshot_candidate" }
        release_decision = if ([string]$toy.ID -in $toyExternalIDs) { "exclude_policy_external" } elseif ([string]$toy.ID -in $toyInternalIDs) { "exclude_unobtainable_or_internal" } else { "include_bfa" }
        unavailable = $false
        availability_note = $null
        current_exists = $currentToyIDs.ContainsKey([string]$toy.ID)
        toy_id = $toy.ID
        item_id = $toy.ItemID
        name = if ($item) { $item.Display_lang } else { $null }
        item_expansion_id = if ($item) { $item.ExpansionID } else { $null }
        source_type_enum = $toy.SourceTypeEnum
        flags = $toy.Flags
        source_text = $sourceText
    }
}

$bfaAchievementCategoryIDs = @("15284", "15285", "15286", "15298", "15305", "15307", "15308", "15417")
$achievementInventory = foreach ($achievement in (Get-NewRows $legionAchievements $bfaAchievements)) {
    $category = $achievementCategoryByID[[string]$achievement.Category]
    $isBfaCategory = [string]$achievement.Category -in $bfaAchievementCategoryIDs
    $isHidden = (([int64]$achievement.Flags -band 0x100000) -ne 0)
    [pscustomobject]@{
        status = if ($achievement.Title_lang -match "DNT|DO NOT USE") { "internal_dnt" } elseif (-not $currentAchievementIDs.ContainsKey([string]$achievement.ID)) { "removed_after_bfa" } elseif ($isBfaCategory -and $isHidden) { "bfa_category_hidden" } elseif ($isBfaCategory) { "bfa_category_confirmed" } else { "snapshot_candidate" }
        current_exists = $currentAchievementIDs.ContainsKey([string]$achievement.ID)
        achievement_id = $achievement.ID
        title = $achievement.Title_lang
        description = $achievement.Description_lang
        category_id = $achievement.Category
        category_name = if ($category) { $category.Name_lang } else { $null }
        criteria_tree_id = $achievement.Criteria_tree
        reward_item_id = $achievement.RewardItemID
        flags = $achievement.Flags
        points = $achievement.Points
    }
}

$criteriaChildren = @{}
foreach ($node in $criteriaTreeRows) {
    $parentID = [string]$node.Parent
    if (-not $criteriaChildren.ContainsKey($parentID)) { $criteriaChildren[$parentID] = [System.Collections.Generic.List[object]]::new() }
    $criteriaChildren[$parentID].Add($node)
}
function Get-CriteriaLeaves([string]$rootID) {
    if (-not $rootID -or $rootID -eq "0") { return }
    $queue = [System.Collections.Generic.Queue[object]]::new()
    $queue.Enqueue(@($rootID, ""))
    while ($queue.Count) {
        $pair = $queue.Dequeue()
        foreach ($node in @($criteriaChildren[[string]$pair[0]] | Sort-Object { [int]$_.OrderIndex })) {
            $path = if ($pair[1]) { "$($pair[1])/$($node.OrderIndex)" } else { [string]$node.OrderIndex }
            if ($node.CriteriaID -ne "0") {
                $criterion = $criteriaByID[[string]$node.CriteriaID]
                [pscustomobject]@{ order_path = $path; tree_id = $node.ID; description = $node.Description_lang; criteria_id = $node.CriteriaID; criteria_type = if ($criterion) { $criterion.Type } else { $null }; asset_id = if ($criterion) { $criterion.Asset } else { $null }; amount = $node.Amount; operator = $node.Operator }
            } else { $queue.Enqueue(@([string]$node.ID, $path)) }
        }
    }
}

$selectedAchievements = @($bfaAchievements | Where-Object { [string]$_.Category -in $bfaAchievementCategoryIDs -and (([int64]$_.Flags -band 0x100000) -eq 0) -and $currentAchievementIDs.ContainsKey([string]$_.ID) })
$achievementCriteriaInventory = foreach ($achievement in $selectedAchievements | Where-Object Criteria_tree -ne "0") {
    foreach ($leaf in (Get-CriteriaLeaves ([string]$achievement.Criteria_tree))) {
        [pscustomobject]@{ achievement_id = $achievement.ID; title = $achievement.Title_lang; category_id = $achievement.Category; order_path = $leaf.order_path; tree_id = $leaf.tree_id; description = $leaf.description; criteria_id = $leaf.criteria_id; criteria_type = $leaf.criteria_type; asset_id = $leaf.asset_id; amount = $leaf.amount; operator = $leaf.operator }
    }
}

$achievementByID = New-Index $bfaAchievements
$attEntityByCriteriaID = @{}
$attZoneText = Get-Content -LiteralPath $attZonePath -Raw
foreach ($match in [regex]::Matches($attZoneText, '(?ms)^(n|o)\((\d+),\{(?:(?!^(?:n|o)\().)*')) {
    $entityType = if ($match.Groups[1].Value -eq "n") { "npc" } else { "object" }
    $candidate = [pscustomobject]@{ type = $entityType; id = $match.Groups[2].Value }
    foreach ($criteriaMatch in [regex]::Matches($match.Value, '\bcrit\((\d+)')) {
        $criteriaID = $criteriaMatch.Groups[1].Value
        if ($attEntityByCriteriaID.ContainsKey($criteriaID)) {
            $existing = $attEntityByCriteriaID[$criteriaID]
            if ($existing -and ($existing.type -ne $candidate.type -or $existing.id -ne $candidate.id)) {
                $attEntityByCriteriaID[$criteriaID] = $null
            }
        } else { $attEntityByCriteriaID[$criteriaID] = $candidate }
    }
}
function Get-EncounterRows($achievementIDs, [string]$kind) {
    foreach ($achievementID in $achievementIDs) {
        $achievement = $achievementByID[[string]$achievementID]
        if (-not $achievement) { throw "Missing $kind achievement $achievementID" }
        foreach ($leaf in (Get-CriteriaLeaves ([string]$achievement.Criteria_tree))) {
            $npcID = $null; $objectID = $null; $mapping = $null
            if ($kind -eq "rare") {
                if ($leaf.criteria_type -eq "0" -and $leaf.asset_id -ne "0") { $npcID = [string]$leaf.asset_id; $mapping = "criteria_creature_asset" }
                else {
                    $entity = $attEntityByCriteriaID[[string]$leaf.criteria_id]
                    if ($entity -and $entity.type -eq "npc") { $npcID = $entity.id; $mapping = "att_quest_npc_provider" }
                    elseif ($entity -and $entity.type -eq "object") { $objectID = $entity.id; $mapping = "att_quest_object_provider" }
                }
            }
            [pscustomobject]@{ achievement_id = $achievement.ID; achievement = $achievement.Title_lang; order_path = $leaf.order_path; tree_id = $leaf.tree_id; criterion = $leaf.description; criteria_id = $leaf.criteria_id; criteria_type = $leaf.criteria_type; criteria_asset = $leaf.asset_id; npc_ids = $npcID; object_ids = $objectID; entity_mapping = $mapping; selection_decision = "include_bfa" }
        }
    }
}
$rareAchievementIDs = @("12939", "12940", "12941", "12942", "12943", "12944", "13470", "13691")
$treasureAchievementIDs = @("12771", "12849", "12851", "12852", "12853", "12995", "13549", "13836")
$rareInventory = @(Get-EncounterRows $rareAchievementIDs "rare")
$treasureInventory = @(Get-EncounterRows $treasureAchievementIDs "treasure")

$rareNPCAudit = @($rareInventory | Where-Object criteria_type -eq "27" | ForEach-Object {
    [pscustomobject]@{ achievement_id = $_.achievement_id; achievement = $_.achievement; tree_id = $_.tree_id; criterion = $_.criterion; completion_quest_id = $_.criteria_asset; npc_id = $_.npc_ids; object_id = $_.object_ids; mapping = $_.entity_mapping }
})
Write-CsvFile $rareNPCAuditPath ($rareNPCAudit | Sort-Object { [int]$_.achievement_id }, { [int]$_.tree_id })

$tradeCategoryChildren = @{}
foreach ($category in $tradeSkillCategories) {
    $parentID = [string]$category.ParentTradeSkillCategoryID
    if (-not $tradeCategoryChildren.ContainsKey($parentID)) { $tradeCategoryChildren[$parentID] = [System.Collections.Generic.List[string]]::new() }
    $tradeCategoryChildren[$parentID].Add([string]$category.ID)
}
$bfaTradeRoots = @("541", "591", "646", "708", "758", "804", "870", "941", "1117")
$allowedTradeCategories = @{}
$tradeQueue = [System.Collections.Generic.Queue[string]]::new()
foreach ($rootID in $bfaTradeRoots) { $tradeQueue.Enqueue($rootID) }
while ($tradeQueue.Count) {
    $categoryID = $tradeQueue.Dequeue()
    if ($allowedTradeCategories.ContainsKey($categoryID)) { continue }
    $allowedTradeCategories[$categoryID] = $true
    foreach ($childID in @($tradeCategoryChildren[$categoryID])) { $tradeQueue.Enqueue($childID) }
}
$professionNames = @{ "171" = "Alchemy"; "164" = "Blacksmithing"; "185" = "Cooking"; "333" = "Enchanting"; "202" = "Engineering"; "773" = "Inscription"; "755" = "Jewelcrafting"; "165" = "Leatherworking"; "197" = "Tailoring" }
$historicalRecipeInventory = foreach ($ability in $skillLineAbilities | Where-Object { $allowedTradeCategories.ContainsKey([string]$_.TradeSkillCategoryID) -and $professionNames.ContainsKey([string]$_.SkillLine) }) {
    $spell = $spellNames[[string]$ability.Spell]
    [pscustomobject]@{ status = if ($spell -and $spell.Name_lang -match "DNT|DO NOT USE") { "internal_dnt" } elseif ($spell -and $spell.Name_lang) { "named_recipe" } else { "unnamed_db2_ability_candidate" }; current_ability_exists = $currentRecipeSpellIDs.ContainsKey([string]$ability.Spell); current_spell_name_exists = $currentSpellNameIDs.ContainsKey([string]$ability.Spell); profession = $professionNames[[string]$ability.SkillLine]; profession_id = $ability.SkillLine; recipe_spell_id = $ability.Spell; name = if ($spell) { $spell.Name_lang } else { $null }; skill_line_ability_id = $ability.ID; trade_category_id = $ability.TradeSkillCategoryID; acquire_method = $ability.AcquireMethod; supercedes_spell_id = $ability.SupercedesSpell }
}
$currentTradeChildren = @{}
$currentTradeCategoryByID = New-Index $currentTradeSkillCategories
foreach ($category in $currentTradeSkillCategories) {
    $parentID = [string]$category.ParentTradeSkillCategoryID
    if (-not $currentTradeChildren.ContainsKey($parentID)) { $currentTradeChildren[$parentID] = [System.Collections.Generic.List[string]]::new() }
    $currentTradeChildren[$parentID].Add([string]$category.ID)
}
$currentAllowedTradeCategories = @{}
$currentTradeQueue = [System.Collections.Generic.Queue[string]]::new()
foreach ($rootID in $bfaTradeRoots) { $currentTradeQueue.Enqueue($rootID) }
while ($currentTradeQueue.Count) {
    $categoryID = $currentTradeQueue.Dequeue()
    if ($currentAllowedTradeCategories.ContainsKey($categoryID)) { continue }
    $currentAllowedTradeCategories[$categoryID] = $true
    foreach ($childID in @($currentTradeChildren[$categoryID])) { $currentTradeQueue.Enqueue($childID) }
}
$houseDecorTradeCategories = @{}
foreach ($categoryID in $currentAllowedTradeCategories.Keys) {
    $category = $currentTradeCategoryByID[$categoryID]
    if ($category -and $category.Name_lang -eq "House Decor") { $houseDecorTradeCategories[$categoryID] = $true }
}
$historicalRecipeIDs = New-IDSet $historicalRecipeInventory "recipe_spell_id"
$houseDecorRecipeInventory = foreach ($ability in $currentTradeSkillAbilities | Where-Object { $houseDecorTradeCategories.ContainsKey([string]$_.TradeSkillCategoryID) -and $professionNames.ContainsKey([string]$_.SkillLine) }) {
    if ($historicalRecipeIDs.ContainsKey([string]$ability.Spell)) { throw "BFA house decor recipe $($ability.Spell) duplicates the historical inventory" }
    $spell = $currentTradeSpellNames[[string]$ability.Spell]
    if (-not $spell -or -not $spell.Name_lang) { throw "BFA house decor recipe $($ability.Spell) has no current spell name" }
    [pscustomobject]@{ status = "current_house_decor_recipe"; current_ability_exists = $true; current_spell_name_exists = $true; profession = $professionNames[[string]$ability.SkillLine]; profession_id = $ability.SkillLine; recipe_spell_id = $ability.Spell; name = $spell.Name_lang; skill_line_ability_id = $ability.ID; trade_category_id = $ability.TradeSkillCategoryID; acquire_method = $ability.AcquireMethod; supercedes_spell_id = $ability.SupercedesSpell }
}
$recipeInventory = @($historicalRecipeInventory) + @($houseDecorRecipeInventory)

$decorationInventory = foreach ($audit in $decorAuditRows) {
    $decor = $currentDecorByID[[string]$audit.decor_id]
    if (-not $decor) { throw "Housing decor $($audit.decor_id) is absent from current DB2" }
    if ($decor.Name_lang.Trim() -ne $audit.catalog_name.Trim()) { throw "Housing decor $($audit.decor_id) name mismatch" }
    $item = $currentItems[[string]$decor.ItemID]
    [pscustomobject]@{ status = $audit.status; candidate_basis = "live_catalog_acquisition_audit"; acquisition_expansion = $audit.acquisition_expansion; catalog_scope = $audit.catalog_scope; decor_id = $decor.ID; item_id = $decor.ItemID; decor_name = $decor.Name_lang.Trim(); source_text = $audit.source_text; achievement_ids = $audit.achievement_ids; quest_ids = $audit.quest_ids; npc_ids = $audit.npc_ids; spell_ids = $audit.spell_ids; currency_ids = $audit.currency_ids; source_item_ids = $audit.item_ids; classification_note = $audit.classification_note; acquisition_source_url = $audit.acquisition_source_url; item_name = if ($item) { $item.Display_lang } else { $null }; item_expansion_id = if ($item) { $item.ExpansionID } else { $null }; flags = $decor.Flags; type = $decor.Type; model_type = $decor.ModelType; weight_cost = $decor.WeightCost }
}

$mapIDs = @("862", "863", "864", "895", "896", "942", "1355", "1462", "1527", "1530")
$mapByID = New-Index $bfaMapRows
$mapInventory = @($mapIDs | ForEach-Object { $map = $mapByID[[string]$_]; if (-not $map) { throw "Missing BFA map $_" }; [pscustomobject]@{ status = "primary_map_confirmed"; map_id = $map.ID; name = $map.Name_lang; parent_map_id = $map.ParentUiMapID; system = $map.System; type = $map.Type; flags = $map.Flags } })
$factionIDs = @("2103", "2156", "2157", "2158", "2159", "2160", "2161", "2162", "2163", "2164", "2373", "2391", "2395", "2396", "2397", "2398", "2400", "2415", "2417")
$factionByID = New-Index $bfaFactionRows
$factionInventory = @($factionIDs | ForEach-Object { $faction = $factionByID[[string]$_]; if (-not $faction) { throw "Missing BFA faction $_" }; [pscustomobject]@{ status = "bfa_collectible_requirement"; faction_id = $faction.ID; name = $faction.Name_lang; parent_faction_id = $faction.ParentFactionID; friendship_rep_id = $faction.FriendshipRepID; flags = $faction.Flags } })
$currencyInventory = foreach ($currency in (Get-NewRows $legionCurrencies $bfaCurrencies)) { [pscustomobject]@{ currency_id = $currency.ID; name = $currency.Name_lang; description = $currency.Description_lang; category_id = $currency.CategoryID; faction_id = $currency.FactionID; max_quantity = $currency.MaxQty; flags_0 = $currency.Flags_0; flags_1 = $currency.Flags_1 } }

Assert-Equal @($mountInventory).Count 165 "Mount snapshot row count"
Assert-Equal @($mountInventory | Where-Object release_decision -eq "include_bfa").Count 140 "Selected BFA mount count"
Assert-Equal @($petInventory).Count 489 "Pet snapshot row count"
Assert-Equal @($petInventory | Where-Object release_decision -eq "include_bfa").Count 236 "Selected BFA pet count"
Assert-Equal @($toyInventory).Count 143 "Toy snapshot row count"
Assert-Equal @($toyInventory | Where-Object release_decision -eq "include_bfa").Count 135 "Selected BFA toy count"
Assert-Equal @($mountInventory | Where-Object { $_.release_decision -eq "include_bfa" -and $_.unavailable }).Count 7 "Unavailable BFA mount count"
Assert-Equal @($selectedAchievements).Count 452 "Visible BFA achievement count"
Assert-Equal @($historicalRecipeInventory | Where-Object status -eq "named_recipe").Count 1231 "Historical named BFA recipe count"
Assert-Equal @($houseDecorRecipeInventory).Count 22 "Current BFA house decor recipe count"
Assert-Equal @($recipeInventory | Where-Object status -in @("named_recipe", "current_house_decor_recipe")).Count 1253 "Named BFA recipe count"
Assert-Equal @($decorationInventory).Count 136 "BFA-owned decoration count"
Assert-Equal @($rareInventory | Where-Object { -not $_.npc_ids -and -not $_.object_ids }).Count 0 "Rare criteria without entity IDs"
Assert-Equal @($rareNPCAudit | Where-Object { -not $_.npc_id -and -not $_.object_id }).Count 0 "Quest rare criteria without audited entity IDs"
Assert-Equal @($mountInventory | Where-Object { $_.release_decision -eq "include_bfa" -and -not $_.source_text }).Count 0 "Selected mounts with blank sources"
Assert-Equal @($petInventory | Where-Object { $_.release_decision -eq "include_bfa" -and -not $_.source_text }).Count 0 "Selected pets with blank sources"
Assert-Equal @($toyInventory | Where-Object { $_.release_decision -eq "include_bfa" -and -not $_.source_text }).Count 0 "Selected toys with blank sources"
foreach ($spec in @(@($mountInventory, "mount_id", "Mount"), @($petInventory, "species_id", "Pet"), @($toyInventory, "toy_id", "Toy"), @($achievementInventory, "achievement_id", "Achievement"), @($achievementCriteriaInventory, "tree_id", "Achievement criteria"), @($recipeInventory, "recipe_spell_id", "Recipe"), @($rareInventory, "tree_id", "Rare"), @($treasureInventory, "tree_id", "Treasure"), @($decorationInventory, "decor_id", "Decoration"))) { Assert-UniqueField $spec[0] $spec[1] $spec[2] }

$summary = @()
$summary += Export-Inventory "mounts" ($mountInventory | Sort-Object { [int]$_.mount_id })
$summary += Export-Inventory "pets" ($petInventory | Sort-Object { [int]$_.species_id })
$summary += Export-Inventory "toys" ($toyInventory | Sort-Object { [int]$_.toy_id })
$summary += Export-Inventory "decorations" ($decorationInventory | Sort-Object { [int]$_.decor_id })
$summary += Export-Inventory "achievements" ($achievementInventory | Sort-Object { [int]$_.achievement_id })
$summary += Export-Inventory "achievement-criteria" ($achievementCriteriaInventory | Sort-Object { [int]$_.achievement_id }, { Get-OrderPathSortKey $_.order_path })
$summary += Export-Inventory "rare-candidates" ($rareInventory | Sort-Object { [int]$_.achievement_id }, { Get-OrderPathSortKey $_.order_path })
$summary += Export-Inventory "treasure-candidates" ($treasureInventory | Sort-Object { [int]$_.achievement_id }, { Get-OrderPathSortKey $_.order_path })
$summary += Export-Inventory "recipes" ($recipeInventory | Sort-Object profession, { [int]$_.recipe_spell_id })
$summary += Export-Inventory "maps" ($mapInventory | Sort-Object { [int]$_.map_id })
$summary += Export-Inventory "factions" ($factionInventory | Sort-Object { [int]$_.faction_id })
$summary += Export-Inventory "currencies" ($currencyInventory | Sort-Object { [int]$_.currency_id })
Write-CsvFile (Join-Path $OutputRoot "summary.csv") $summary

$mountManifest = @($mountInventory | Where-Object release_decision -eq "include_bfa" | Sort-Object { [int]$_.mount_id })
$petManifest = @($petInventory | Where-Object release_decision -eq "include_bfa" | Sort-Object { [int]$_.species_id })
$toyManifest = @($toyInventory | Where-Object release_decision -eq "include_bfa" | Sort-Object { [int]$_.toy_id })
$decorationManifest = @($decorationInventory | Sort-Object { [int]$_.decor_id })
$achievementManifest = @($achievementInventory | Where-Object status -eq "bfa_category_confirmed" | Sort-Object { [int]$_.achievement_id })
$achievementIDs = @($achievementManifest | ForEach-Object { [string]$_.achievement_id })
$achievementCriteriaManifest = @($achievementCriteriaInventory | Where-Object { [string]$_.achievement_id -in $achievementIDs } | Sort-Object { [int]$_.achievement_id }, { Get-OrderPathSortKey $_.order_path })
$recipeManifest = @($recipeInventory | Where-Object status -in @("named_recipe", "current_house_decor_recipe") | Sort-Object profession, { [int]$_.recipe_spell_id })
$rareManifest = @($rareInventory | Sort-Object { [int]$_.achievement_id }, { Get-OrderPathSortKey $_.order_path })
$treasureManifest = @($treasureInventory | Sort-Object { [int]$_.achievement_id }, { Get-OrderPathSortKey $_.order_path })
foreach ($pair in @(@("mounts", $mountManifest), @("pets", $petManifest), @("toys", $toyManifest), @("decorations", $decorationManifest), @("achievements", $achievementManifest), @("achievement-criteria", $achievementCriteriaManifest), @("recipes", $recipeManifest), @("rares", $rareManifest), @("treasures", $treasureManifest))) { Write-CsvFile (Join-Path $ManifestRoot "$($pair[0]).csv") $pair[1] }

$supportingCurrencyIDs = @("241", "391", "515", "1166", "1220", "1226", "1560", "1710", "1716", "1717", "1719", "1721", "1803", "3363")
$bfaCurrencyByID = New-Index $bfaCurrencies
$currentCurrencyByID = New-Index $currentCurrencyRows
$supportingCurrencyManifest = @($supportingCurrencyIDs | ForEach-Object {
    $currency = $bfaCurrencyByID[[string]$_]
    $source = "historical_collectible_source"
    if (-not $currency) { $currency = $currentCurrencyByID[[string]$_]; $source = "current_decoration_acquisition" }
    if (-not $currency) { throw "Missing supporting currency $_" }
    [pscustomobject]@{ current_exists = $currentCurrencyIDs.ContainsKey([string]$currency.ID); currency_id = $currency.ID; name = $currency.Name_lang; description = $currency.Description_lang; category_id = $currency.CategoryID; faction_id = $currency.FactionID; max_quantity = $currency.MaxQty; source = $source }
})
$supportingFactionManifest = @($factionInventory | ForEach-Object { [pscustomobject]@{ current_exists = $currentFactionIDs.ContainsKey([string]$_.faction_id); faction_id = $_.faction_id; name = $_.name; parent_faction_id = $_.parent_faction_id; friendship_rep_id = $_.friendship_rep_id; flags = $_.flags; source = "selected_collectible_or_achievement_requirement" } })
$supportingMapManifest = @($mapInventory | ForEach-Object { [pscustomobject]@{ current_exists = $currentMapIDs.ContainsKey([string]$_.map_id); map_id = $_.map_id; name = $_.name; parent_map_id = $_.parent_map_id; system = $_.system; type = $_.type; flags = $_.flags; source = "selected_primary_zone" } })
Write-CsvFile (Join-Path $ManifestRoot "supporting-currencies.csv") $supportingCurrencyManifest
Write-CsvFile (Join-Path $ManifestRoot "supporting-factions.csv") $supportingFactionManifest
Write-CsvFile (Join-Path $ManifestRoot "supporting-maps.csv") $supportingMapManifest

$manifestSummary = @(
    [pscustomobject]@{ manifest = "mounts"; rows = $mountManifest.Count; identifier = "mount_id" }
    [pscustomobject]@{ manifest = "pets"; rows = $petManifest.Count; identifier = "species_id" }
    [pscustomobject]@{ manifest = "toys"; rows = $toyManifest.Count; identifier = "toy_id" }
    [pscustomobject]@{ manifest = "decorations"; rows = $decorationManifest.Count; identifier = "decor_id" }
    [pscustomobject]@{ manifest = "achievements"; rows = $achievementManifest.Count; identifier = "achievement_id" }
    [pscustomobject]@{ manifest = "achievement-criteria"; rows = $achievementCriteriaManifest.Count; identifier = "tree_id" }
    [pscustomobject]@{ manifest = "recipes"; rows = $recipeManifest.Count; identifier = "recipe_spell_id" }
    [pscustomobject]@{ manifest = "rares"; rows = $rareManifest.Count; identifier = "tree_id" }
    [pscustomobject]@{ manifest = "treasures"; rows = $treasureManifest.Count; identifier = "tree_id" }
    [pscustomobject]@{ manifest = "supporting-currencies"; rows = $supportingCurrencyManifest.Count; identifier = "currency_id" }
    [pscustomobject]@{ manifest = "supporting-factions"; rows = $supportingFactionManifest.Count; identifier = "faction_id" }
    [pscustomobject]@{ manifest = "supporting-maps"; rows = $supportingMapManifest.Count; identifier = "map_id" }
)
Write-CsvFile (Join-Path $ManifestRoot "summary.csv") $manifestSummary
$summary | Format-Table -AutoSize
Write-Host "Generated Collectionist Battle for Azeroth ID inventory and release manifests"
