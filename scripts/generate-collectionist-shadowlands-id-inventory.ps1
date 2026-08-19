param(
    [string]$Db2Root = (Join-Path $env:TEMP "collectionist-sl-db2"),
    [string]$CurrentDb2Root = (Join-Path $env:TEMP "collectionist-df-db2\current"),
    [string]$CurrentTradeDb2Root = (Join-Path $env:TEMP "collectionist-tww-db2\current"),
    [string]$OutputRoot = (Join-Path $PSScriptRoot "..\research\collectionist\shadowlands\ids"),
    [string]$ManifestRoot = (Join-Path $PSScriptRoot "..\research\collectionist\shadowlands\manifests")
)

$ErrorActionPreference = "Stop"
$decorAuditSourcePath = Join-Path $PSScriptRoot "..\research\collectionist\shadowlands\sources\housing-wowdb-acquisition-audit.csv"
$bastionRareNPCAuditSourcePath = Join-Path $PSScriptRoot "..\research\collectionist\shadowlands\sources\bastion-rare-npc-audit.csv"

$bfaRoot = Join-Path $Db2Root "bfa"
$shadowlandsRoot = Join-Path $Db2Root "shadowlands"
foreach ($required in @($bfaRoot, $shadowlandsRoot, $CurrentDb2Root, $CurrentTradeDb2Root)) {
    if (-not (Test-Path -LiteralPath $required)) {
        throw "Missing input directory: $required"
    }
}

New-Item -ItemType Directory -Force -Path $OutputRoot | Out-Null
New-Item -ItemType Directory -Force -Path $ManifestRoot | Out-Null

function Read-Table([string]$root, [string]$name) {
    $path = Join-Path $root "$name.csv"
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing DB2 table: $path"
    }
    return @(Import-Csv -LiteralPath $path)
}

function New-Index($rows, [string]$field = "ID") {
    $index = @{}
    foreach ($row in $rows) {
        $index[[string]$row.$field] = $row
    }
    return $index
}

function New-IDSet($rows, [string]$field = "ID") {
    $set = @{}
    foreach ($row in $rows) {
        $set[[string]$row.$field] = $true
    }
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
    $text = if ($lines.Count -gt 0) { ($lines -join "`n") + "`n" } else { "" }
    $text = $text.Replace("`r`n", "`n").Replace("`r", "`n")
    $text = [regex]::Replace($text, "[ \t]+(?=`n)", "")
    [System.IO.File]::WriteAllText($path, $text, [System.Text.UTF8Encoding]::new($false))
}

function Export-Inventory([string]$name, $rows) {
    $path = Join-Path $OutputRoot "$name.csv"
    Write-CsvFile $path @($rows)
    return [pscustomobject]@{ file = $name; rows = @($rows).Count }
}

function Assert-Equal($actual, $expected, [string]$label) {
    if ([int]$actual -ne [int]$expected) {
        throw "$label mismatch: expected $expected, got $actual"
    }
}

function Assert-UniqueField($rows, [string]$field, [string]$label) {
    $duplicates = @($rows | Group-Object $field | Where-Object { $_.Count -gt 1 })
    if ($duplicates.Count -gt 0) {
        throw "$label contains duplicate ${field}: $($duplicates.Name -join ', ')"
    }
}

$bfaMounts = Read-Table $bfaRoot "Mount"
$slMounts = Read-Table $shadowlandsRoot "Mount"
$bfaPets = Read-Table $bfaRoot "BattlePetSpecies"
$slPets = Read-Table $shadowlandsRoot "BattlePetSpecies"
$bfaToys = Read-Table $bfaRoot "Toy"
$slToys = Read-Table $shadowlandsRoot "Toy"
$bfaAchievements = Read-Table $bfaRoot "Achievement"
$slAchievements = Read-Table $shadowlandsRoot "Achievement"
$bfaCurrencies = Read-Table $bfaRoot "CurrencyTypes"
$slCurrencies = Read-Table $shadowlandsRoot "CurrencyTypes"

$currentMountIDs = New-IDSet (Read-Table $CurrentDb2Root "Mount")
$currentPetIDs = New-IDSet (Read-Table $CurrentDb2Root "BattlePetSpecies")
$currentToyIDs = New-IDSet (Read-Table $CurrentDb2Root "Toy")
$currentAchievementIDs = New-IDSet (Read-Table $CurrentDb2Root "Achievement")
$currentRecipeSpellIDs = New-IDSet (Read-Table $CurrentDb2Root "SkillLineAbility") "Spell"
$currentSpellNameIDs = New-IDSet (Read-Table $CurrentDb2Root "SpellName")
$currentTradeSkillCategories = Read-Table $CurrentTradeDb2Root "TradeSkillCategory"
$currentTradeSkillAbilities = Read-Table $CurrentTradeDb2Root "SkillLineAbility"
$currentTradeSpellNames = New-Index (Read-Table $CurrentTradeDb2Root "SpellName")
$currentCurrencyIDs = New-IDSet (Read-Table $CurrentDb2Root "CurrencyTypes")
$currentFactionIDs = New-IDSet (Read-Table $CurrentDb2Root "Faction")
$currentMapIDs = New-IDSet (Read-Table $CurrentDb2Root "UiMap")
$currentItems = New-Index (Read-Table $CurrentDb2Root "ItemSparse")
$currentDecorRows = Read-Table $CurrentDb2Root "HouseDecor"
$currentDecorByID = New-Index $currentDecorRows
if (-not (Test-Path -LiteralPath $decorAuditSourcePath)) {
    throw "Missing housing acquisition audit: $decorAuditSourcePath"
}
$decorAuditRows = @(Import-Csv -LiteralPath $decorAuditSourcePath)
if (-not (Test-Path -LiteralPath $bastionRareNPCAuditSourcePath)) {
    throw "Missing Bastion rare NPC audit: $bastionRareNPCAuditSourcePath"
}
$bastionRareNPCAuditRows = @(Import-Csv -LiteralPath $bastionRareNPCAuditSourcePath)

$items = New-Index (Read-Table $shadowlandsRoot "ItemSparse")
$creatures = New-Index (Read-Table $shadowlandsRoot "Creature")
$effects = New-Index (Read-Table $shadowlandsRoot "ItemEffect")
$itemEffects = Read-Table $shadowlandsRoot "ItemXItemEffect"
$achievementCategories = Read-Table $shadowlandsRoot "Achievement_Category"
$achievementCategoryByID = New-Index $achievementCategories
$criteriaByID = New-Index (Read-Table $shadowlandsRoot "Criteria")
$criteriaTreeRows = Read-Table $shadowlandsRoot "CriteriaTree"
$tradeSkillCategories = Read-Table $shadowlandsRoot "TradeSkillCategory"
$skillLineAbilities = Read-Table $shadowlandsRoot "SkillLineAbility"
$spellNames = New-Index (Read-Table $shadowlandsRoot "SpellName")
$slFactionRows = Read-Table $shadowlandsRoot "Faction"
$slMapRows = Read-Table $shadowlandsRoot "UiMap"

$itemsBySpell = @{}
foreach ($relation in $itemEffects) {
    $effect = $effects[[string]$relation.ItemEffectID]
    if (-not $effect -or -not $effect.SpellID) { continue }
    $spellID = [string]$effect.SpellID
    if (-not $itemsBySpell.ContainsKey($spellID)) {
        $itemsBySpell[$spellID] = [System.Collections.Generic.List[string]]::new()
    }
    $itemsBySpell[$spellID].Add([string]$relation.ItemID)
}

$shadowlandsSignalPattern = "Shadowlands|Bastion|Maldraxxus|Ardenweald|Revendreth|Oribos|The Maw|Korthia|Zereth Mortis|Torghast|Covenant|Sanctum"
$externalCollectionPattern = "In[- ]Game Shop|Trading Post|Promotion|Recruit-A-Friend|Legacy|WoW Esports|Blizz[Cc]on|Mythic Dungeon International"
$mountExternalIDs = @("1424", "1444", "1456", "1458", "1513", "1531", "1556", "1581", "1594", "1596", "1602", "1679")
$mountInternalIDs = @("1567", "1578")
$petExternalIDs = @("3053", "3153", "3175", "3177", "3248", "3249")
$toyExternalIDs = @("1148", "1162", "1163", "1192")
$toyInternalIDs = @("1151", "1164")
$shadowlandsGladiatorMountIDs = @("1363", "1480", "1572", "1599")
$shadowlandsKeystoneMountIDs = @("1405", "1419", "1520", "1544")
$shadowlandsOtherUnavailableMountIDs = @("1552", "1576")
$shadowlandsUnavailableMountIDs = @($shadowlandsGladiatorMountIDs + $shadowlandsKeystoneMountIDs + $shadowlandsOtherUnavailableMountIDs)
$shadowlandsUnavailablePetIDs = @("3046")
$toySourceOverrides = @{
    "1105" = "|cFFFFD200World Quest:|r Ardenweald world quests"
    "1106" = "|cFFFFD200Treasure:|r Elusive Faerie Cache|n|cFFFFD200Zone:|r Ardenweald"
    "1107" = "|cFFFFD200Treasure:|r Harmonic Chest|n|cFFFFD200Zone:|r Ardenweald"
    "1108" = "|cFFFFD200Vendor:|r Adjutant Nikos or Adjutant Mikaros|n|cFFFFD200Faction:|r The Ascended - Revered|n|cFFFFD200Cost:|r 1765 gold"
    "1109" = "|cFFFFD200Drop:|r Enforcer Aegeon|n|cFFFFD200Zone:|r Bastion"
    "1110" = "|cFFFFD200Treasure:|r Broken Bell or Skyward Bell|n|cFFFFD200Zone:|r Bastion"
    "1111" = "|cFFFFD200Treasure:|r Gilded Chests and Silver Strongboxes|n|cFFFFD200Zone:|r Bastion"
    "1112" = "|cFFFFD200Drop:|r Unstable Memory|n|cFFFFD200Zone:|r Bastion"
    "1113" = "|cFFFFD200Paragon Cache:|r Ascended Supplies"
    "1117" = "|cFFFFD200Profession:|r Shadowlands Enchanting (40)"
    "1118" = "|cFFFFD200Profession:|r Shadowlands Leatherworking (100)"
    "1139" = "|cFFFFD200World Event:|r Feast of Winter Veil|n|cFFFFD200Source:|r 2021 Gently Shaken Gift or Stolen Present"
    "1175" = "|cFFFFD200Secret:|r Ponderer's Portal|n|cFFFFD200Zone:|r Zereth Mortis|n|cFFFFD200Requirement:|r Six players with Sphere of Enlightened Cogitation"
    "1178" = "|cFFFFD200Vendor:|r Olea Manu|n|cFFFFD200Zone:|r Zereth Mortis|n|cFFFFD200Cost:|r 100 |Hcurrency:1979|h[Cyphers of the First Ones]|h"
    "1180" = "|cFFFFD200Treasure:|r Sandworn Chest|n|cFFFFD200Zone:|r Zereth Mortis"
    "1181" = "|cFFFFD200Quest:|r Firim daily quests|n|cFFFFD200Zone:|r Zereth Mortis"
    "1186" = "|cFFFFD200World Event:|r Feast of Winter Veil|n|cFFFFD200Source:|r 2022 Winter Veil gift or Stolen Present"
    "1187" = "|cFFFFD200World Event:|r Feast of Winter Veil|n|cFFFFD200Source:|r 2022 Gently Shaken Gift or Stolen Present"
    "1189" = "|cFFFFD200Mail:|r Ve'nari, after inspecting her at the Creation Catalyst|n|cFFFFD200Zone:|r Zereth Mortis"
}

# Mount journal ID 293 was reused in Shadowlands: the BFA row is the retired
# Black Dragonhawk while the Shadowlands row is Illidari Doomhawk.
$shadowlandsReusedMountIDs = @("293")
$shadowlandsMountCandidates = @((Get-NewRows $bfaMounts $slMounts)) + @($slMounts | Where-Object { [string]$_.ID -in $shadowlandsReusedMountIDs })
$mountInventory = foreach ($mount in $shadowlandsMountCandidates) {
    $itemIDs = @($itemsBySpell[[string]$mount.SourceSpellID])
    $itemExpansionIDs = @($itemIDs | ForEach-Object {
        $item = $items[[string]$_]
        if ($item) { $item.ExpansionID }
    })
    $status = if ($mount.SourceText_lang -match $externalCollectionPattern) {
        "policy_external_candidate"
    } elseif ($itemExpansionIDs -contains "8") {
        "item_expansion_signal"
    } elseif ($mount.SourceText_lang -match $shadowlandsSignalPattern) {
        "source_text_signal"
    } else {
        "snapshot_candidate"
    }
    [pscustomobject]@{
        status             = $status
        release_decision   = if ([string]$mount.ID -in $mountExternalIDs) { "exclude_policy_external" } elseif ([string]$mount.ID -in $mountInternalIDs) { "exclude_unobtainable_or_internal" } else { "include_shadowlands" }
        unavailable        = [string]$mount.ID -in $shadowlandsUnavailableMountIDs
        availability_note  = if ([string]$mount.ID -in $shadowlandsGladiatorMountIDs) { "Shadowlands Gladiator season reward; season ended" } elseif ([string]$mount.ID -in $shadowlandsKeystoneMountIDs) { "Shadowlands Keystone Master season reward; season ended" } elseif ([string]$mount.ID -eq "1552") { "Heroic Jailer quest reward; removed with Dragonflight" } elseif ([string]$mount.ID -eq "1576") { "Shadowlands Fated raid reward; later bullion acquisition window also closed" } else { $null }
        current_exists     = $currentMountIDs.ContainsKey([string]$mount.ID)
        mount_id           = $mount.ID
        name               = $mount.Name_lang
        source_spell_id    = $mount.SourceSpellID
        item_ids           = Join-IDs $itemIDs
        item_expansion_ids = Join-IDs $itemExpansionIDs
        source_type_enum   = $mount.SourceTypeEnum
        flags              = $mount.Flags
        source_text        = $mount.SourceText_lang
    }
}

$shadowlandsCollectibleWildPetIDs = @("3215")
$petInventory = foreach ($pet in (Get-NewRows $bfaPets $slPets)) {
    $itemIDs = @($itemsBySpell[[string]$pet.SummonSpellID])
    $itemExpansionIDs = @($itemIDs | ForEach-Object {
        $item = $items[[string]$_]
        if ($item) { $item.ExpansionID }
    })
    $creature = $creatures[[string]$pet.CreatureID]
    $status = if ([string]$pet.ID -in $shadowlandsCollectibleWildPetIDs) {
        "collectible_wild_pet"
    } elseif ($pet.SummonSpellID -eq "0" -or [int]$pet.SourceTypeEnum -lt 0) {
        "noncollectible_pet_battle_npc"
    } elseif ($pet.SourceText_lang -match $externalCollectionPattern) {
        "policy_external_candidate"
    } elseif ($itemExpansionIDs -contains "8") {
        "item_expansion_signal"
    } elseif ($pet.SourceText_lang -match $shadowlandsSignalPattern) {
        "source_text_signal"
    } else {
        "snapshot_candidate"
    }
    [pscustomobject]@{
        status             = $status
        release_decision   = if ($status -eq "noncollectible_pet_battle_npc") { "exclude_noncollectible" } elseif ([string]$pet.ID -in $petExternalIDs) { "exclude_policy_external" } else { "include_shadowlands" }
        unavailable        = [string]$pet.ID -in $shadowlandsUnavailablePetIDs
        availability_note  = if ([string]$pet.ID -eq "3046") { "Death Rising pre-expansion event reward; event ended" } else { $null }
        current_exists     = $currentPetIDs.ContainsKey([string]$pet.ID)
        species_id         = $pet.ID
        name               = if ($creature) { $creature.Name_lang } else { $null }
        creature_id        = $pet.CreatureID
        summon_spell_id    = $pet.SummonSpellID
        item_ids           = Join-IDs $itemIDs
        item_expansion_ids = Join-IDs $itemExpansionIDs
        pet_type_enum      = $pet.PetTypeEnum
        flags              = $pet.Flags
        source_type_enum   = $pet.SourceTypeEnum
        source_text        = $pet.SourceText_lang
    }
}

$toyInventory = foreach ($toy in (Get-NewRows $bfaToys $slToys)) {
    $item = $items[[string]$toy.ItemID]
    $toySourceText = if ($toySourceOverrides.ContainsKey([string]$toy.ID)) { $toySourceOverrides[[string]$toy.ID] } else { $toy.SourceText_lang }
    $status = if ($toySourceText -match $externalCollectionPattern) {
        "policy_external_candidate"
    } elseif ($item -and $item.ExpansionID -eq "8") {
        "item_expansion_signal"
    } elseif ($toySourceText -match $shadowlandsSignalPattern) {
        "source_text_signal"
    } else {
        "snapshot_candidate"
    }
    [pscustomobject]@{
        status            = $status
        release_decision  = if ([string]$toy.ID -in $toyInternalIDs) { "exclude_unobtainable_or_internal" } elseif ([string]$toy.ID -in $toyExternalIDs) { "exclude_policy_external" } else { "include_shadowlands" }
        unavailable       = $false
        availability_note = $null
        current_exists    = $currentToyIDs.ContainsKey([string]$toy.ID)
        toy_id            = $toy.ID
        item_id           = $toy.ItemID
        name              = if ($item) { $item.Display_lang } else { $null }
        item_expansion_id = if ($item) { $item.ExpansionID } else { $null }
        source_type_enum  = $toy.SourceTypeEnum
        flags             = $toy.Flags
        source_text       = $toySourceText
    }
}

$slAchievementCategoryIDs = @("15422", "15428", "15436", "15438", "15439", "15440", "15441")
$achievementInventory = foreach ($achievement in (Get-NewRows $bfaAchievements $slAchievements)) {
    $category = $achievementCategoryByID[[string]$achievement.Category]
    $isShadowlandsCategory = [string]$achievement.Category -in $slAchievementCategoryIDs
    $isHidden = (([int64]$achievement.Flags -band 0x100000) -ne 0)
    $status = if ($achievement.Title_lang -match "DNT|DO NOT USE") {
        "internal_dnt"
    } elseif (-not $currentAchievementIDs.ContainsKey([string]$achievement.ID)) {
        "removed_after_shadowlands"
    } elseif ($isShadowlandsCategory -and $isHidden) {
        "shadowlands_category_hidden"
    } elseif ($isShadowlandsCategory) {
        "shadowlands_category_confirmed"
    } else {
        "snapshot_candidate"
    }
    [pscustomobject]@{
        status           = $status
        current_exists   = $currentAchievementIDs.ContainsKey([string]$achievement.ID)
        achievement_id   = $achievement.ID
        title            = $achievement.Title_lang
        description      = $achievement.Description_lang
        category_id      = $achievement.Category
        category_name    = if ($category) { $category.Name_lang } else { $null }
        criteria_tree_id = $achievement.Criteria_tree
        reward_item_id   = $achievement.RewardItemID
        flags            = $achievement.Flags
        points           = $achievement.Points
    }
}

$criteriaChildren = @{}
foreach ($node in $criteriaTreeRows) {
    $parentID = [string]$node.Parent
    if (-not $criteriaChildren.ContainsKey($parentID)) {
        $criteriaChildren[$parentID] = [System.Collections.Generic.List[object]]::new()
    }
    $criteriaChildren[$parentID].Add($node)
}

function Get-CriteriaLeaves([string]$rootID) {
    if (-not $rootID -or $rootID -eq "0") { return }
    $queue = [System.Collections.Generic.Queue[object]]::new()
    $queue.Enqueue(@($rootID, ""))
    while ($queue.Count -gt 0) {
        $pair = $queue.Dequeue()
        $nodeID = [string]$pair[0]
        $parentPath = [string]$pair[1]
        foreach ($node in @($criteriaChildren[$nodeID] | Sort-Object { [int]$_.OrderIndex })) {
            $path = if ($parentPath) { "$parentPath/$($node.OrderIndex)" } else { [string]$node.OrderIndex }
            if ($node.CriteriaID -ne "0") {
                $criterion = $criteriaByID[[string]$node.CriteriaID]
                [pscustomobject]@{
                    order_path    = $path
                    tree_id       = $node.ID
                    description   = $node.Description_lang
                    criteria_id   = $node.CriteriaID
                    criteria_type = if ($criterion) { $criterion.Type } else { $null }
                    asset_id      = if ($criterion) { $criterion.Asset } else { $null }
                    amount        = $node.Amount
                    operator      = $node.Operator
                }
            } else {
                $queue.Enqueue(@([string]$node.ID, $path))
            }
        }
    }
}

$selectedAchievements = @($slAchievements | Where-Object {
    [string]$_.Category -in $slAchievementCategoryIDs -and
    (([int64]$_.Flags -band 0x100000) -eq 0) -and
    $currentAchievementIDs.ContainsKey([string]$_.ID)
})
$achievementCriteriaInventory = foreach ($achievement in $selectedAchievements | Where-Object { $_.Criteria_tree -ne "0" }) {
    foreach ($leaf in (Get-CriteriaLeaves ([string]$achievement.Criteria_tree))) {
        [pscustomobject]@{
            achievement_id = $achievement.ID
            title          = $achievement.Title_lang
            category_id    = $achievement.Category
            order_path     = $leaf.order_path
            tree_id        = $leaf.tree_id
            description    = $leaf.description
            criteria_id    = $leaf.criteria_id
            criteria_type  = $leaf.criteria_type
            asset_id       = $leaf.asset_id
            amount         = $leaf.amount
            operator       = $leaf.operator
        }
    }
}

$achievementByID = New-Index $slAchievements
function Get-EncounterCandidateRows($achievementIDs, [string]$kind) {
    $rows = foreach ($achievementID in $achievementIDs) {
        $achievement = $achievementByID[[string]$achievementID]
        if (-not $achievement) { throw "Missing $kind candidate achievement $achievementID" }
        foreach ($leaf in (Get-CriteriaLeaves ([string]$achievement.Criteria_tree))) {
            $identityKey = if ($leaf.criteria_type -eq "0" -and $leaf.asset_id -and $leaf.asset_id -ne "0") {
                "asset:$($leaf.asset_id)"
            } else {
                "text:$(([string]$leaf.description).Trim().ToLowerInvariant())"
            }
            [pscustomobject]@{
                achievement_id = $achievement.ID
                achievement    = $achievement.Title_lang
                order_path     = $leaf.order_path
                tree_id        = $leaf.tree_id
                criterion      = $leaf.description
                criteria_id    = $leaf.criteria_id
                criteria_type  = $leaf.criteria_type
                criteria_asset = $leaf.asset_id
                identity_key   = $identityKey
            }
        }
    }
    $counts = @{}
    foreach ($group in @($rows | Group-Object identity_key)) { $counts[$group.Name] = $group.Count }
    return @($rows | ForEach-Object {
        [pscustomobject]@{
            achievement_id          = $_.achievement_id
            achievement             = $_.achievement
            order_path              = $_.order_path
            tree_id                 = $_.tree_id
            criterion               = $_.criterion
            criteria_id             = $_.criteria_id
            criteria_type           = $_.criteria_type
            criteria_asset          = $_.criteria_asset
            identity_key            = $_.identity_key
            duplicate_identity_count = $counts[$_.identity_key]
            selection_decision      = "needs_overlap_audit"
        }
    })
}

$rareAchievementIDs = @("14307", "14308", "14309", "14310", "14660", "14744", "15054", "15107", "15391", "15392", "15512")
$treasureAchievementIDs = @("14311", "14312", "14313", "14314", "15099", "15331", "15502", "15513")
$rareInventory = Get-EncounterCandidateRows $rareAchievementIDs "rare"
$treasureInventory = Get-EncounterCandidateRows $treasureAchievementIDs "treasure"
$bastionRareNPCByCriterion = @{}
foreach ($audit in $bastionRareNPCAuditRows) {
    if ($bastionRareNPCByCriterion.ContainsKey([string]$audit.criterion)) {
        throw "Duplicate Bastion rare NPC audit criterion: $($audit.criterion)"
    }
    if ([int]$audit.npc_id -le 0) {
        throw "Invalid Bastion rare NPC ID for $($audit.criterion): $($audit.npc_id)"
    }
    $bastionRareNPCByCriterion[[string]$audit.criterion] = [string]$audit.npc_id
}
foreach ($row in $rareInventory) {
    $row.selection_decision = if ($row.achievement_id -eq "15512") { "exclude_partial_duplicate" } else { "include_shadowlands" }
    $npcIDs = if ([string]$row.criteria_type -eq "0") {
        [string]$row.criteria_asset
    } elseif ($bastionRareNPCByCriterion.ContainsKey([string]$row.criterion)) {
        $bastionRareNPCByCriterion[[string]$row.criterion]
    } else {
        $null
    }
    $row | Add-Member -NotePropertyName npc_ids -NotePropertyValue $npcIDs
}
foreach ($row in $treasureInventory) {
    $row.selection_decision = if ($row.achievement_id -eq "15513") { "exclude_partial_duplicate" } else { "include_shadowlands" }
}

$tradeCategoryChildren = @{}
foreach ($category in $tradeSkillCategories) {
    $parentID = [string]$category.ParentTradeSkillCategoryID
    if (-not $tradeCategoryChildren.ContainsKey($parentID)) {
        $tradeCategoryChildren[$parentID] = [System.Collections.Generic.List[string]]::new()
    }
    $tradeCategoryChildren[$parentID].Add([string]$category.ID)
}
$slTradeRoots = @("1293", "1310", "1322", "1333", "1363", "1380", "1394", "1405", "1417")
$allowedTradeCategories = @{}
$tradeQueue = [System.Collections.Generic.Queue[string]]::new()
foreach ($rootID in $slTradeRoots) { $tradeQueue.Enqueue($rootID) }
while ($tradeQueue.Count -gt 0) {
    $categoryID = $tradeQueue.Dequeue()
    if ($allowedTradeCategories.ContainsKey($categoryID)) { continue }
    $allowedTradeCategories[$categoryID] = $true
    foreach ($childID in @($tradeCategoryChildren[$categoryID])) { $tradeQueue.Enqueue($childID) }
}
$professionNames = @{
    "171" = "Alchemy"; "164" = "Blacksmithing"; "185" = "Cooking";
    "333" = "Enchanting"; "202" = "Engineering"; "773" = "Inscription";
    "755" = "Jewelcrafting"; "165" = "Leatherworking"; "197" = "Tailoring"
}
$historicalRecipeInventory = foreach ($ability in $skillLineAbilities | Where-Object {
    $allowedTradeCategories.ContainsKey([string]$_.TradeSkillCategoryID)
}) {
    $spell = $spellNames[[string]$ability.Spell]
    [pscustomobject]@{
        status                    = if ($spell -and $spell.Name_lang -match "DNT|DO NOT USE") { "internal_dnt" } elseif ($spell -and $spell.Name_lang) { "named_recipe" } else { "unnamed_db2_ability_candidate" }
        current_ability_exists    = $currentRecipeSpellIDs.ContainsKey([string]$ability.Spell)
        current_spell_name_exists = $currentSpellNameIDs.ContainsKey([string]$ability.Spell)
        profession                = $professionNames[[string]$ability.SkillLine]
        profession_id             = $ability.SkillLine
        recipe_spell_id           = $ability.Spell
        name                      = if ($spell) { $spell.Name_lang } else { $null }
        skill_line_ability_id     = $ability.ID
        trade_category_id         = $ability.TradeSkillCategoryID
        acquire_method            = $ability.AcquireMethod
        supercedes_spell_id       = $ability.SupercedesSpell
    }
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
foreach ($rootID in $slTradeRoots) { $currentTradeQueue.Enqueue($rootID) }
while ($currentTradeQueue.Count -gt 0) {
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
$houseDecorRecipeInventory = foreach ($ability in $currentTradeSkillAbilities | Where-Object {
    $houseDecorTradeCategories.ContainsKey([string]$_.TradeSkillCategoryID) -and $professionNames.ContainsKey([string]$_.SkillLine)
}) {
    if ($historicalRecipeIDs.ContainsKey([string]$ability.Spell)) { throw "Shadowlands house decor recipe $($ability.Spell) duplicates the historical inventory" }
    $spell = $currentTradeSpellNames[[string]$ability.Spell]
    if (-not $spell -or -not $spell.Name_lang) { throw "Shadowlands house decor recipe $($ability.Spell) has no current spell name" }
    [pscustomobject]@{
        status = "current_house_decor_recipe"; current_ability_exists = $true; current_spell_name_exists = $true
        profession = $professionNames[[string]$ability.SkillLine]; profession_id = $ability.SkillLine; recipe_spell_id = $ability.Spell; name = $spell.Name_lang
        skill_line_ability_id = $ability.ID; trade_category_id = $ability.TradeSkillCategoryID; acquire_method = $ability.AcquireMethod; supercedes_spell_id = $ability.SupercedesSpell
    }
}
$recipeInventory = @($historicalRecipeInventory) + @($houseDecorRecipeInventory)

$decorationInventory = foreach ($audit in $decorAuditRows) {
    $decor = $currentDecorByID[[string]$audit.decor_id]
    if (-not $decor) { throw "Housing catalog decor $($audit.decor_id) is absent from current DB2" }
    if ($decor.Name_lang -ne $audit.catalog_name) {
        throw "Housing catalog decor $($audit.decor_id) name mismatch: '$($audit.catalog_name)' vs '$($decor.Name_lang)'"
    }
    $item = $currentItems[[string]$decor.ItemID]
    [pscustomobject]@{
        status                 = $audit.status
        candidate_basis        = "live_catalog_acquisition_audit"
        acquisition_expansion  = $audit.acquisition_expansion
        catalog_theme_expansion = "shadowlands"
        decor_id              = $decor.ID
        item_id               = $decor.ItemID
        decor_name            = $decor.Name_lang
        source_text           = $audit.source_text
        classification_note   = $audit.classification_note
        acquisition_source_url = $audit.acquisition_source_url
        item_name             = if ($item) { $item.Display_lang } else { $null }
        item_expansion_id     = if ($item) { $item.ExpansionID } else { $null }
        flags                 = $decor.Flags
        type                  = $decor.Type
        model_type            = $decor.ModelType
        weight_cost           = $decor.WeightCost
    }
}

$mapInventory = $slMapRows | Where-Object {
    [int]$_.ID -ge 1500 -and (
        $_.Name_lang -match $shadowlandsSignalPattern -or
        [string]$_.ParentUiMapID -in @("1525", "1533", "1536", "1543", "1550", "1565", "1960", "1961", "1970")
    )
} | ForEach-Object {
    [pscustomobject]@{
        status        = if ([string]$_.ID -in @("1525", "1533", "1536", "1543", "1550", "1565", "1670", "1960", "1961", "1970")) { "primary_map_candidate" } else { "child_map_candidate" }
        map_id        = $_.ID
        name          = $_.Name_lang
        parent_map_id = $_.ParentUiMapID
        system        = $_.System
        type          = $_.Type
        flags         = $_.Flags
    }
}

$factionInventory = $slFactionRows | Where-Object { $_.Expansion -eq "8" } | ForEach-Object {
    [pscustomobject]@{
        status            = if ($_.Name_lang -match "DNT|DO NOT USE") { "internal_dnt" } elseif ($_.Expansion -eq "8") { "shadowlands_expansion_signal" } else { "snapshot_candidate" }
        faction_id        = $_.ID
        name              = $_.Name_lang
        parent_faction_id = $_.ParentFactionID
        friendship_rep_id = $_.FriendshipRepID
        expansion_id      = $_.Expansion
        flags             = $_.Flags
    }
}

$currencyInventory = foreach ($currency in (Get-NewRows $bfaCurrencies $slCurrencies)) {
    [pscustomobject]@{
        currency_id = $currency.ID
        name         = $currency.Name_lang
        description  = $currency.Description_lang
        category_id  = $currency.CategoryID
        faction_id   = $currency.FactionID
        max_quantity = $currency.MaxQty
        flags_0      = $currency.Flags_0
        flags_1      = $currency.Flags_1
    }
}

Assert-Equal @($mountInventory).Count 194 "Mount snapshot row count"
Assert-Equal @($petInventory).Count 300 "Pet snapshot row count"
Assert-Equal @($toyInventory).Count 121 "Toy snapshot row count"
Assert-Equal @($achievementInventory).Count 963 "Achievement snapshot row count"
Assert-Equal @($selectedAchievements).Count 419 "Visible Shadowlands achievement count"
Assert-Equal @($achievementCriteriaInventory).Count 2489 "Visible Shadowlands achievement criteria count"
Assert-Equal @($historicalRecipeInventory | Where-Object { $_.status -eq "named_recipe" }).Count 611 "Historical named Shadowlands recipe count"
Assert-Equal @($historicalRecipeInventory | Where-Object { $_.status -eq "unnamed_db2_ability_candidate" }).Count 2 "Unnamed Shadowlands recipe count"
Assert-Equal @($houseDecorRecipeInventory).Count 23 "Current Shadowlands house decor recipe count"
Assert-Equal @($recipeInventory | Where-Object { $_.status -in @("named_recipe", "current_house_decor_recipe") }).Count 634 "Named Shadowlands recipe count"
Assert-Equal @($mountInventory | Where-Object { $_.release_decision -eq "include_shadowlands" }).Count 180 "Selected Shadowlands mount count"
Assert-Equal @($mountInventory | Where-Object { $_.release_decision -eq "exclude_policy_external" }).Count 12 "External Shadowlands mount count"
Assert-Equal @($mountInventory | Where-Object { $_.release_decision -eq "exclude_unobtainable_or_internal" }).Count 2 "Internal Shadowlands mount count"
Assert-Equal @($petInventory | Where-Object { $_.release_decision -eq "include_shadowlands" }).Count 176 "Selected Shadowlands pet count"
Assert-Equal @($petInventory | Where-Object { $_.release_decision -eq "exclude_policy_external" }).Count 6 "External Shadowlands pet count"
Assert-Equal @($petInventory | Where-Object { $_.release_decision -eq "exclude_noncollectible" }).Count 118 "Noncollectible Shadowlands pet count"
Assert-Equal @($toyInventory | Where-Object { $_.release_decision -eq "include_shadowlands" }).Count 115 "Selected Shadowlands toy count"
Assert-Equal @($toyInventory | Where-Object { $_.release_decision -eq "exclude_policy_external" }).Count 4 "External Shadowlands toy count"
Assert-Equal @($toyInventory | Where-Object { $_.release_decision -eq "exclude_unobtainable_or_internal" }).Count 2 "Internal Shadowlands toy count"
Assert-Equal @($mountInventory | Where-Object { $_.release_decision -eq "include_shadowlands" -and -not $_.source_text }).Count 0 "Selected Shadowlands mounts with blank sources"
Assert-Equal @($petInventory | Where-Object { $_.release_decision -eq "include_shadowlands" -and -not $_.source_text }).Count 0 "Selected Shadowlands pets with blank sources"
Assert-Equal @($toyInventory | Where-Object { $_.release_decision -eq "include_shadowlands" -and -not $_.source_text }).Count 0 "Selected Shadowlands toys with blank sources"
Assert-Equal @($mountInventory | Where-Object { $_.release_decision -eq "include_shadowlands" -and $_.unavailable }).Count 10 "Unavailable Shadowlands mount count"
Assert-Equal @($petInventory | Where-Object { $_.release_decision -eq "include_shadowlands" -and $_.unavailable }).Count 1 "Unavailable Shadowlands pet count"
Assert-Equal @($toyInventory | Where-Object { $_.release_decision -eq "include_shadowlands" -and $_.unavailable }).Count 0 "Unavailable Shadowlands toy count"
Assert-Equal @($decorationInventory).Count 34 "Shadowlands housing acquisition audit row count"
Assert-Equal @($decorationInventory | Where-Object { $_.status -eq "acquisition_shadowlands_confirmed" }).Count 26 "Shadowlands-owned decoration count"
Assert-Equal @($decorationInventory | Where-Object { $_.status -match "^acquisition_(dragonflight|tww|midnight)_confirmed$" }).Count 3 "Cross-expansion decoration count"
Assert-Equal @($decorationInventory | Where-Object { $_.status -eq "catalog_hidden_unobtainable" }).Count 3 "Hidden decoration count"
Assert-Equal @($decorationInventory | Where-Object { $_.status -eq "internal_dnt" }).Count 2 "Internal decoration count"
Assert-Equal @($bastionRareNPCAuditRows).Count 29 "Bastion rare NPC audit row count"
Assert-Equal @($rareInventory | Where-Object { $_.achievement_id -eq "14307" -and $_.criteria_type -eq "27" -and $_.npc_ids }).Count 29 "Bastion quest-criteria NPC mapping count"
Assert-Equal @($rareInventory | Where-Object { $_.selection_decision -eq "include_shadowlands" }).Count 211 "Selected rare criteria count"
Assert-Equal @($rareInventory | Where-Object { $_.selection_decision -eq "exclude_partial_duplicate" }).Count 29 "Duplicate rare criteria count"
Assert-Equal @($rareInventory | Where-Object { $_.selection_decision -eq "include_shadowlands" -and -not $_.npc_ids }).Count 0 "Selected rare criteria missing NPC IDs"
Assert-Equal @($treasureInventory | Where-Object { $_.selection_decision -eq "include_shadowlands" }).Count 103 "Selected treasure criteria count"
Assert-Equal @($treasureInventory | Where-Object { $_.selection_decision -eq "exclude_partial_duplicate" }).Count 27 "Duplicate treasure criteria count"
Assert-UniqueField $mountInventory "mount_id" "Mount inventory"
Assert-UniqueField $petInventory "species_id" "Pet inventory"
Assert-UniqueField $toyInventory "toy_id" "Toy inventory"
Assert-UniqueField $achievementInventory "achievement_id" "Achievement inventory"
Assert-UniqueField $achievementCriteriaInventory "tree_id" "Achievement criteria inventory"
Assert-UniqueField $recipeInventory "recipe_spell_id" "Recipe inventory"
Assert-UniqueField $rareInventory "tree_id" "Rare candidate inventory"
Assert-UniqueField $treasureInventory "tree_id" "Treasure candidate inventory"
Assert-UniqueField $decorationInventory "decor_id" "Decoration candidate inventory"
Assert-Equal @($selectedAchievements | Where-Object { -not $currentAchievementIDs.ContainsKey([string]$_.ID) }).Count 0 "Selected achievements missing from current retail"

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

$mountManifest = @($mountInventory | Where-Object { $_.release_decision -eq "include_shadowlands" } | Sort-Object { [int]$_.mount_id })
$petManifest = @($petInventory | Where-Object { $_.release_decision -eq "include_shadowlands" } | Sort-Object { [int]$_.species_id })
$toyManifest = @($toyInventory | Where-Object { $_.release_decision -eq "include_shadowlands" } | Sort-Object { [int]$_.toy_id })
$decorationManifest = @($decorationInventory | Where-Object { $_.status -eq "acquisition_shadowlands_confirmed" } | Sort-Object { [int]$_.decor_id })
$achievementManifest = @($achievementInventory | Where-Object { $_.status -eq "shadowlands_category_confirmed" } | Sort-Object { [int]$_.achievement_id })
$achievementManifestIDs = @($achievementManifest | ForEach-Object { [string]$_.achievement_id })
$achievementCriteriaManifest = @($achievementCriteriaInventory | Where-Object { [string]$_.achievement_id -in $achievementManifestIDs } | Sort-Object { [int]$_.achievement_id }, { Get-OrderPathSortKey $_.order_path })
$recipeManifest = @($recipeInventory | Where-Object { $_.status -in @("named_recipe", "current_house_decor_recipe") } | Sort-Object profession, { [int]$_.recipe_spell_id })
$rareManifest = @($rareInventory | Where-Object { $_.selection_decision -eq "include_shadowlands" } | Sort-Object { [int]$_.achievement_id }, { Get-OrderPathSortKey $_.order_path })
$treasureManifest = @($treasureInventory | Where-Object { $_.selection_decision -eq "include_shadowlands" } | Sort-Object { [int]$_.achievement_id }, { Get-OrderPathSortKey $_.order_path })

Write-CsvFile (Join-Path $ManifestRoot "mounts.csv") $mountManifest
Write-CsvFile (Join-Path $ManifestRoot "pets.csv") $petManifest
Write-CsvFile (Join-Path $ManifestRoot "toys.csv") $toyManifest
Write-CsvFile (Join-Path $ManifestRoot "decorations.csv") $decorationManifest
Write-CsvFile (Join-Path $ManifestRoot "achievements.csv") $achievementManifest
Write-CsvFile (Join-Path $ManifestRoot "achievement-criteria.csv") $achievementCriteriaManifest
Write-CsvFile (Join-Path $ManifestRoot "recipes.csv") $recipeManifest
Write-CsvFile (Join-Path $ManifestRoot "rares.csv") $rareManifest
Write-CsvFile (Join-Path $ManifestRoot "treasures.csv") $treasureManifest

$supportingCurrencyIDs = @("1166", "1728", "1754", "1767", "1813", "1816", "1820", "1931", "1979")
$supportingFactionIDs = @("2407", "2410", "2413", "2432", "2439", "2445", "2463", "2464", "2465", "2470", "2472", "2478")
$supportingMapIDs = @("1525", "1533", "1536", "1543", "1550", "1565", "1961", "1970")
$slCurrencyByID = New-Index $slCurrencies
$slFactionByID = New-Index $slFactionRows
$slMapByID = New-Index $slMapRows
$supportingCurrencyManifest = @($supportingCurrencyIDs | ForEach-Object {
    $currency = $slCurrencyByID[[string]$_]
    if (-not $currency) { throw "Supporting currency $_ is absent from the final Shadowlands snapshot" }
    [pscustomobject]@{
        current_exists = $currentCurrencyIDs.ContainsKey([string]$currency.ID)
        currency_id    = $currency.ID
        name           = $currency.Name_lang
        description    = $currency.Description_lang
        category_id    = $currency.CategoryID
        faction_id     = $currency.FactionID
        max_quantity   = $currency.MaxQty
        source         = "selected_collectible_source"
    }
})
$supportingFactionManifest = @($supportingFactionIDs | ForEach-Object {
    $faction = $slFactionByID[[string]$_]
    if (-not $faction) { throw "Supporting faction $_ is absent from the final Shadowlands snapshot" }
    [pscustomobject]@{
        current_exists    = $currentFactionIDs.ContainsKey([string]$faction.ID)
        faction_id        = $faction.ID
        name              = $faction.Name_lang
        parent_faction_id = $faction.ParentFactionID
        friendship_rep_id = $faction.FriendshipRepID
        flags             = $faction.Flags
        source            = "selected_collectible_or_achievement_requirement"
    }
})
$supportingMapManifest = @($supportingMapIDs | ForEach-Object {
    $map = $slMapByID[[string]$_]
    if (-not $map) { throw "Supporting map $_ is absent from the final Shadowlands snapshot" }
    [pscustomobject]@{
        current_exists = $currentMapIDs.ContainsKey([string]$map.ID)
        map_id         = $map.ID
        name           = $map.Name_lang
        parent_map_id  = $map.ParentUiMapID
        system         = $map.System
        type           = $map.Type
        flags          = $map.Flags
        source         = "selected_primary_zone"
    }
})
Assert-Equal @($supportingCurrencyManifest).Count 9 "Shadowlands supporting currency count"
Assert-Equal @($supportingFactionManifest).Count 12 "Shadowlands supporting faction count"
Assert-Equal @($supportingMapManifest).Count 8 "Shadowlands supporting map count"
Assert-Equal @($supportingCurrencyManifest | Where-Object { -not [System.Convert]::ToBoolean($_.current_exists) }).Count 0 "Supporting currencies missing from current retail"
Assert-Equal @($supportingFactionManifest | Where-Object { -not [System.Convert]::ToBoolean($_.current_exists) }).Count 0 "Supporting factions missing from current retail"
Assert-Equal @($supportingMapManifest | Where-Object { -not [System.Convert]::ToBoolean($_.current_exists) }).Count 0 "Supporting maps missing from current retail"
Write-CsvFile (Join-Path $ManifestRoot "supporting-currencies.csv") $supportingCurrencyManifest
Write-CsvFile (Join-Path $ManifestRoot "supporting-factions.csv") $supportingFactionManifest
Write-CsvFile (Join-Path $ManifestRoot "supporting-maps.csv") $supportingMapManifest

$manifestSummary = @(
    [pscustomobject]@{ manifest = "mounts"; rows = 180; identifier = "mount_id" }
    [pscustomobject]@{ manifest = "pets"; rows = 176; identifier = "species_id" }
    [pscustomobject]@{ manifest = "toys"; rows = 115; identifier = "toy_id" }
    [pscustomobject]@{ manifest = "decorations"; rows = 26; identifier = "decor_id" }
    [pscustomobject]@{ manifest = "achievements"; rows = 419; identifier = "achievement_id" }
    [pscustomobject]@{ manifest = "achievement-criteria"; rows = 2489; identifier = "tree_id" }
    [pscustomobject]@{ manifest = "recipes"; rows = 634; identifier = "recipe_spell_id" }
    [pscustomobject]@{ manifest = "rares"; rows = 211; identifier = "tree_id" }
    [pscustomobject]@{ manifest = "treasures"; rows = 103; identifier = "tree_id" }
    [pscustomobject]@{ manifest = "supporting-currencies"; rows = 9; identifier = "currency_id" }
    [pscustomobject]@{ manifest = "supporting-factions"; rows = 12; identifier = "faction_id" }
    [pscustomobject]@{ manifest = "supporting-maps"; rows = 8; identifier = "map_id" }
)
Write-CsvFile (Join-Path $ManifestRoot "summary.csv") $manifestSummary

$summary | Format-Table -AutoSize
