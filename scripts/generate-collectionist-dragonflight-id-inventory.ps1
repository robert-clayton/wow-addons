param(
    [string]$Db2Root = (Join-Path $env:TEMP "collectionist-df-db2"),
    [string]$CurrentTradeDb2Root = (Join-Path $env:TEMP "collectionist-tww-db2\current"),
    [string]$OutputRoot = (Join-Path $PSScriptRoot "..\research\collectionist\dragonflight\ids"),
    [string]$ManifestRoot = (Join-Path $PSScriptRoot "..\research\collectionist\dragonflight\manifests")
)

$ErrorActionPreference = "Stop"

$shadowlandsRoot = Join-Path $Db2Root "shadowlands"
$dragonflightRoot = Join-Path $Db2Root "dragonflight"
$currentRoot = Join-Path $Db2Root "current"
$guideRoot = Join-Path $Db2Root "guides"
$decorSourcePath = Join-Path $PSScriptRoot "..\research\collectionist\dragonflight\sources\housing-wowdb.csv"
$decorDetailSourcePath = Join-Path $PSScriptRoot "..\research\collectionist\dragonflight\sources\housing-wowdb-details.csv"
$decorAuditSourcePath = Join-Path $PSScriptRoot "..\research\collectionist\dragonflight\sources\housing-wowdb-acquisition-audit.csv"
$ancientZulGurubSourcePath = Join-Path $PSScriptRoot "..\research\collectionist\dragonflight\sources\ancient-zulgurub-recipes.csv"

foreach ($required in @($shadowlandsRoot, $dragonflightRoot, $currentRoot, $CurrentTradeDb2Root)) {
    if (-not (Test-Path -LiteralPath $required)) {
        throw "Missing input directory: $required"
    }
}
if (-not (Test-Path -LiteralPath $ancientZulGurubSourcePath)) {
    throw "Missing Ancient Zul'Gurub recipe audit: $ancientZulGurubSourcePath"
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

function Get-RegexIDs([string]$text, [string]$pattern) {
    $ids = @{}
    foreach ($match in [regex]::Matches($text, $pattern)) {
        $ids[$match.Groups[1].Value] = $true
    }
    return $ids
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

$slMounts = Read-Table $shadowlandsRoot "Mount"
$dfMounts = Read-Table $dragonflightRoot "Mount"
$slPets = Read-Table $shadowlandsRoot "BattlePetSpecies"
$dfPets = Read-Table $dragonflightRoot "BattlePetSpecies"
$slToys = Read-Table $shadowlandsRoot "Toy"
$dfToys = Read-Table $dragonflightRoot "Toy"
$slAchievements = Read-Table $shadowlandsRoot "Achievement"
$dfAchievements = Read-Table $dragonflightRoot "Achievement"
$slCurrencies = Read-Table $shadowlandsRoot "CurrencyTypes"
$dfCurrencies = Read-Table $dragonflightRoot "CurrencyTypes"

$currentMountIDs = New-IDSet (Read-Table $currentRoot "Mount")
$currentPetIDs = New-IDSet (Read-Table $currentRoot "BattlePetSpecies")
$currentToyIDs = New-IDSet (Read-Table $currentRoot "Toy")
$currentAchievementIDs = New-IDSet (Read-Table $currentRoot "Achievement")
$currentRecipeSpellIDs = New-IDSet (Read-Table $currentRoot "SkillLineAbility") "Spell"
$currentSpellNameIDs = New-IDSet (Read-Table $currentRoot "SpellName")
$currentTradeSkillCategories = Read-Table $CurrentTradeDb2Root "TradeSkillCategory"
$currentTradeSkillAbilities = Read-Table $CurrentTradeDb2Root "SkillLineAbility"
$currentTradeSpellNames = New-Index (Read-Table $CurrentTradeDb2Root "SpellName")
$currentDecorRows = Read-Table $currentRoot "HouseDecor"
$currentItems = New-Index (Read-Table $currentRoot "ItemSparse")
$catalogDecorNames = @{}
$catalogRows = @()
$catalogDetailRows = @()
$catalogDetailsByID = @{}
$catalogAuditRows = @()
$catalogAuditByID = @{}
if (Test-Path -LiteralPath $decorSourcePath) {
    $catalogRows = @(Import-Csv -LiteralPath $decorSourcePath)
    foreach ($row in $catalogRows) {
        $catalogDecorNames[[string]$row.decor_id] = $row.catalog_name
    }
}
if (Test-Path -LiteralPath $decorDetailSourcePath) {
    $catalogDetailRows = @(Import-Csv -LiteralPath $decorDetailSourcePath)
    foreach ($row in $catalogDetailRows) {
        $catalogDetailsByID[[string]$row.decor_id] = $row
    }
}
if (Test-Path -LiteralPath $decorAuditSourcePath) {
    $catalogAuditRows = @(Import-Csv -LiteralPath $decorAuditSourcePath)
    foreach ($row in $catalogAuditRows) {
        $catalogAuditByID[[string]$row.decor_id] = $row
    }
}

$items = New-Index (Read-Table $dragonflightRoot "ItemSparse")
$creatures = New-Index (Read-Table $dragonflightRoot "Creature")
$effects = New-Index (Read-Table $dragonflightRoot "ItemEffect")
$itemEffects = Read-Table $dragonflightRoot "ItemXItemEffect"
$achievementCategories = Read-Table $dragonflightRoot "Achievement_Category"
$achievementCategoryByID = New-Index $achievementCategories
$criteriaByID = New-Index (Read-Table $dragonflightRoot "Criteria")
$criteriaTreeRows = Read-Table $dragonflightRoot "CriteriaTree"
$tradeSkillCategories = Read-Table $dragonflightRoot "TradeSkillCategory"
$skillLineAbilities = Read-Table $dragonflightRoot "SkillLineAbility"
$spellNames = New-Index (Read-Table $dragonflightRoot "SpellName")

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

function Get-GuideText([string]$pattern) {
    if (-not (Test-Path -LiteralPath $guideRoot)) { return "" }
    return ((Get-ChildItem -LiteralPath $guideRoot -Filter $pattern -File | ForEach-Object {
        Get-Content -Raw -LiteralPath $_.FullName
    }) -join "`n")
}

function Get-GuideSpells($guideItemIDs) {
    $spells = @{}
    foreach ($relation in $itemEffects) {
        if (-not $guideItemIDs.ContainsKey([string]$relation.ItemID)) { continue }
        $effect = $effects[[string]$relation.ItemEffectID]
        if ($effect -and $effect.SpellID) {
            $spells[[string]$effect.SpellID] = [string]$relation.ItemID
        }
    }
    return $spells
}

$mountGuideText = Get-GuideText "mounts-*.html"
$mountGuideItemIDs = Get-RegexIDs $mountGuideText "(?:/item=|\[item=)(\d+)"
$mountGuideSpells = Get-GuideSpells $mountGuideItemIDs
$petGuideText = Get-GuideText "pets-*.html"
$petGuideItemIDs = Get-RegexIDs $petGuideText "(?:/item=|\[item=)(\d+)"
$petGuideNPCIDs = Get-RegexIDs $petGuideText "(?:/npc=|\[npc=)(\d+)"
$petGuideSpells = Get-GuideSpells $petGuideItemIDs
$toyGuideText = Get-GuideText "toys*.html"
$toyGuideItemIDs = Get-RegexIDs $toyGuideText "(?:/item=|\[item=)(\d+)"

$dfSignalPattern = "Dragonflight|Dragon Isles|Waking Shores|Ohn.ahran|Azure Span|Thaldraszus|Forbidden Reach|Zaralek|Emerald Dream|Valdrakken|Dracthyr|Primal Storm"
$externalCollectionPattern = "In-Game Shop|Trading Post|Promotion|Recruit-A-Friend|Legacy|WoW Esports|Blizz[Cc]on"
$mountSnapshotIncludeIDs = @(
    "482", "994", "1259", "1614", "1733", "1772", "1773", "1798", "1813", "1941", "1959", "2023",
    "2060", "2063", "2064", "2065", "2067", "2068", "2069", "2070", "2071", "2072", "2073", "2074",
    "2075", "2076", "2077", "2078", "2080", "2081", "2083", "2084", "2085", "2086", "2087", "2088",
    "2089", "2090", "2118", "2142", "2143"
)
$petSnapshotIncludeIDs = @(
    "3334", "3549", "3581", "4265", "4409", "4411", "4412", "4425", "4426", "4435", "4579", "4580"
)
$toySnapshotIncludeIDs = @(
    "1276", "1303", "1311", "1328", "1331", "1352", "1357", "1427", "1429", "1435", "1439", "1445",
    "1447", "1456", "1461", "1464", "1467", "1468", "1469", "1470", "1476"
)
$petSourceOverrides = @{
    "3552" = "|cFFFFD200Quest:|r Mean Green Infusion Machine|n|cFFFFD200Zone:|r Emerald Dream"
}
$toySourceOverrides = @{
    "1228" = "|cFFFFD200Drop:|r Blightpaw the Depraved, Blightfur, or High Shaman Rotknuckle"
    "1229" = "|cFFFFD200Drop:|r Dragon Isles rares"
    "1239" = "|cFFFFD200World Event:|r Siege on Dragonbane Keep"
    "1240" = "|cFFFFD200Drop:|r Qalashi djaradin in the Obsidian Citadel"
    "1268" = "|cFFFFD200Treasure:|r Rumble Coin Bag -> Rumble Prize Box (Warcraft Rumble Machine)"
    "1283" = "|cFFFFD200Treasure:|r Rumble Coin Bag -> Rumble Prize Box (Warcraft Rumble Machine)"
    "1284" = "|cFFFFD200Treasure:|r Rumble Coin Bag -> Rumble Prize Box (Warcraft Rumble Machine)"
    "1285" = "|cFFFFD200Treasure:|r Rumble Coin Bag -> Rumble Prize Box (Warcraft Rumble Machine)"
    "1286" = "|cFFFFD200Treasure:|r Rumble Coin Bag -> Rumble Prize Box (Warcraft Rumble Machine)"
    "1287" = "|cFFFFD200Treasure:|r Rumble Coin Bag -> Rumble Prize Box (Warcraft Rumble Machine)"
    "1288" = "|cFFFFD200Treasure:|r Rumble Coin Bag -> Rumble Prize Box (Warcraft Rumble Machine)"
    "1310" = "|cFFFFD200Quest:|r The Patience of Princes|n|cFFFFD200Zone:|r Zaralek Cavern"
    "1450" = "|cFFFFD200World Event:|r Hearthstone's 10th Anniversary|n|cFFFFD200Achievement:|r Hearthstone Beginner"
    "1456" = "|cFFFFD200World Event:|r Hearthstone's 10th Anniversary|n|cFFFFD200Drop:|r Dr. Boom"
}

$mountInventory = foreach ($mount in (Get-NewRows $slMounts $dfMounts)) {
    $itemIDs = @($itemsBySpell[[string]$mount.SourceSpellID])
    $itemExpansionIDs = @($itemIDs | ForEach-Object {
        $item = $items[[string]$_]
        if ($item) { $item.ExpansionID }
    })
    $guideNameMatch = $mountGuideText -and $mount.Name_lang -and
        $mountGuideText.IndexOf($mount.Name_lang, [System.StringComparison]::OrdinalIgnoreCase) -ge 0
    $status = if ([string]$mount.ID -in @("1608", "1952")) {
        "racial_ability_not_collectible"
    } elseif ($mountGuideSpells.ContainsKey([string]$mount.SourceSpellID) -or $guideNameMatch) {
        "guide_confirmed"
    } elseif ($itemExpansionIDs -contains "9") {
        "item_expansion_confirmed"
    } elseif ($mount.SourceText_lang -match $dfSignalPattern) {
        "db2_dragonflight_signal"
    } else {
        "snapshot_candidate"
    }
    $releaseDecision = if ($status -eq "racial_ability_not_collectible") {
        "exclude_unobtainable_or_internal"
    } elseif ($mount.SourceText_lang -match $externalCollectionPattern) {
        "exclude_policy_external"
    } elseif ($status -in @("guide_confirmed", "item_expansion_confirmed", "db2_dragonflight_signal")) {
        "include_dragonflight"
    } elseif ([string]$mount.ID -in $mountSnapshotIncludeIDs) {
        "include_dragonflight"
    } else {
        "exclude_unobtainable_or_internal"
    }
    [pscustomobject]@{
        status             = $status
        release_decision   = $releaseDecision
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

$petInventory = foreach ($pet in (Get-NewRows $slPets $dfPets)) {
    $itemIDs = @($itemsBySpell[[string]$pet.SummonSpellID])
    $itemExpansionIDs = @($itemIDs | ForEach-Object {
        $item = $items[[string]$_]
        if ($item) { $item.ExpansionID }
    })
    $creature = $creatures[[string]$pet.CreatureID]
    $name = if ($creature) { $creature.Name_lang } else { $null }
    $petSourceText = if ($petSourceOverrides.ContainsKey([string]$pet.ID)) {
        $petSourceOverrides[[string]$pet.ID]
    } else {
        $pet.SourceText_lang
    }
    $status = if ($pet.SummonSpellID -eq "0" -and [int]$pet.SourceTypeEnum -lt 0) {
        "noncollectible_pet_battle_npc"
    } elseif ([string]$pet.ID -eq "4264") {
        "cross_expansion_shop_pet"
    } elseif ($petGuideSpells.ContainsKey([string]$pet.SummonSpellID) -or
                  $petGuideNPCIDs.ContainsKey([string]$pet.CreatureID)) {
        "guide_confirmed"
    } elseif ($pet.SummonSpellID -eq "0") {
        "noncollectible_pet_battle_npc"
    } elseif ($itemExpansionIDs -contains "9") {
        "item_expansion_confirmed"
    } elseif ($petSourceText -match $dfSignalPattern) {
        "db2_dragonflight_signal"
    } else {
        "snapshot_candidate"
    }
    $releaseDecision = if ($status -eq "noncollectible_pet_battle_npc") {
        "exclude_noncollectible"
    } elseif ($status -eq "cross_expansion_shop_pet") {
        "exclude_policy_external"
    } elseif ($petSourceText -match $externalCollectionPattern) {
        "exclude_policy_external"
    } elseif ($status -in @("guide_confirmed", "item_expansion_confirmed", "db2_dragonflight_signal")) {
        "include_dragonflight"
    } elseif ([string]$pet.ID -in $petSnapshotIncludeIDs) {
        "include_dragonflight"
    } else {
        "exclude_unobtainable_or_internal"
    }
    [pscustomobject]@{
        status             = $status
        release_decision   = $releaseDecision
        current_exists     = $currentPetIDs.ContainsKey([string]$pet.ID)
        species_id         = $pet.ID
        name               = $name
        creature_id        = $pet.CreatureID
        summon_spell_id    = $pet.SummonSpellID
        item_ids           = Join-IDs $itemIDs
        item_expansion_ids = Join-IDs $itemExpansionIDs
        pet_type_enum      = $pet.PetTypeEnum
        flags              = $pet.Flags
        source_type_enum   = $pet.SourceTypeEnum
        source_text        = $petSourceText
    }
}

$classicToyIDs = @("1340")
$toyInventory = foreach ($toy in (Get-NewRows $slToys $dfToys)) {
    $item = $items[[string]$toy.ItemID]
    $toySourceText = if ($toySourceOverrides.ContainsKey([string]$toy.ID)) {
        $toySourceOverrides[[string]$toy.ID]
    } else {
        $toy.SourceText_lang
    }
    $status = if ($toyGuideItemIDs.ContainsKey([string]$toy.ItemID)) {
        "guide_confirmed"
    } elseif ($item -and $item.ExpansionID -eq "9") {
        "item_expansion_confirmed"
    } elseif ($toySourceText -match $dfSignalPattern) {
        "db2_dragonflight_signal"
    } else {
        "snapshot_candidate"
    }
    $releaseDecision = if ([string]$toy.ID -in $classicToyIDs) {
        "exclude_classic"
    } elseif ($toySourceText -match $externalCollectionPattern) {
        "exclude_policy_external"
    } elseif ([string]$toy.ID -in @("1293", "1294")) {
        "exclude_cross_expansion"
    } elseif ([string]$toy.ID -in @("1224", "1355")) {
        "exclude_unobtainable_or_internal"
    } elseif ($status -in @("guide_confirmed", "item_expansion_confirmed", "db2_dragonflight_signal")) {
        "include_dragonflight"
    } elseif ([string]$toy.ID -in $toySnapshotIncludeIDs) {
        "include_dragonflight"
    } else {
        "exclude_unobtainable_or_internal"
    }
    [pscustomobject]@{
        status            = if ([string]$toy.ID -in $classicToyIDs) { "classic_acquisition_boundary" } else { $status }
        release_decision  = $releaseDecision
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

$dfAchievementCategoryIDs = @("15455", "15462", "15465", "15466", "15467", "15468", "15478")
$achievementInventory = foreach ($achievement in (Get-NewRows $slAchievements $dfAchievements)) {
    $category = $achievementCategoryByID[[string]$achievement.Category]
    $isDragonflightCategory = [string]$achievement.Category -in $dfAchievementCategoryIDs
    $isHidden = (([int64]$achievement.Flags -band 0x100000) -ne 0)
    $status = if ($achievement.Title_lang -match "DNT|DO NOT USE") {
        "internal_dnt"
    } elseif (-not $currentAchievementIDs.ContainsKey([string]$achievement.ID)) {
        "removed_after_dragonflight"
    } elseif ($isDragonflightCategory -and $isHidden) {
        "dragonflight_category_hidden"
    } elseif ($isDragonflightCategory) {
        "dragonflight_category_confirmed"
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

$achievementCriteriaInventory = foreach ($achievement in $dfAchievements | Where-Object {
    [string]$_.Category -in $dfAchievementCategoryIDs -and $_.Criteria_tree -ne "0"
}) {
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

$achievementByID = New-Index $dfAchievements
$rareNpcOverrides = @{
    "Possessive Hornswog" = "192362;200002"
    "Brullo the Strong"    = "203621"
}
$rareAchievementIDs = @("16676", "16677", "16678", "16679", "17524", "17783", "19316")
$rareInventory = foreach ($achievementID in $rareAchievementIDs) {
    $achievement = $achievementByID[$achievementID]
    foreach ($leaf in (Get-CriteriaLeaves ([string]$achievement.Criteria_tree))) {
        [pscustomobject]@{
            achievement_id = $achievement.ID
            achievement    = $achievement.Title_lang
            order_path     = $leaf.order_path
            tree_id        = $leaf.tree_id
            criterion      = $leaf.description
            criteria_id    = $leaf.criteria_id
            criteria_type  = $leaf.criteria_type
            criteria_asset = $leaf.asset_id
            npc_ids        = if ($leaf.criteria_type -eq "0") { $leaf.asset_id } else { $rareNpcOverrides[$leaf.description] }
        }
    }
}

$treasureAchievementIDs = @("16297", "16299", "16300", "16301", "17526", "17786", "19317")
$treasureInventory = foreach ($achievementID in $treasureAchievementIDs) {
    $achievement = $achievementByID[$achievementID]
    foreach ($leaf in (Get-CriteriaLeaves ([string]$achievement.Criteria_tree))) {
        [pscustomobject]@{
            achievement_id = $achievement.ID
            achievement    = $achievement.Title_lang
            order_path     = $leaf.order_path
            tree_id        = $leaf.tree_id
            treasure       = $leaf.description
            criteria_id    = $leaf.criteria_id
            criteria_type  = $leaf.criteria_type
            criteria_asset = $leaf.asset_id
            amount         = $leaf.amount
        }
    }
}

$tradeCategoryChildren = @{}
foreach ($category in $tradeSkillCategories) {
    $parentID = [string]$category.ParentTradeSkillCategoryID
    if (-not $tradeCategoryChildren.ContainsKey($parentID)) {
        $tradeCategoryChildren[$parentID] = [System.Collections.Generic.List[string]]::new()
    }
    $tradeCategoryChildren[$parentID].Add([string]$category.ID)
}
$dfTradeRoots = @("1570", "1565", "1572", "1577", "1578", "1580", "1574", "1575", "1576")
$allowedTradeCategories = @{}
$tradeQueue = [System.Collections.Generic.Queue[string]]::new()
foreach ($rootID in $dfTradeRoots) { $tradeQueue.Enqueue($rootID) }
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
$ancientZulGurubRows = @(Import-Csv -LiteralPath $ancientZulGurubSourcePath)
if ($ancientZulGurubRows.Count -ne 31) { throw "Ancient Zul'Gurub recipe audit must contain exactly 31 rows" }
if (@($ancientZulGurubRows | Group-Object item_id | Where-Object { $_.Count -gt 1 }).Count) {
    throw "Ancient Zul'Gurub recipe item audit contains duplicate item IDs"
}
if (@($ancientZulGurubRows | Group-Object recipe_spell_id | Where-Object { $_.Count -gt 1 }).Count) {
    throw "Ancient Zul'Gurub recipe spell audit contains duplicate spell IDs"
}
foreach ($audit in $ancientZulGurubRows) {
    $item = $items[[string]$audit.item_id]
    if (-not $item -or [string]$item.Display_lang -ne [string]$audit.recipe_item_name) {
        throw "Ancient Zul'Gurub recipe item mismatch for item $($audit.item_id)"
    }
    $teachingSpellIDs = @($itemEffects | Where-Object { [string]$_.ItemID -eq [string]$audit.item_id } | ForEach-Object {
        $effect = $effects[[string]$_.ItemEffectID]
        if ($effect) { [string]$effect.SpellID }
    })
    if ([string]$audit.recipe_spell_id -notin $teachingSpellIDs) {
        throw "Ancient Zul'Gurub item $($audit.item_id) does not teach spell $($audit.recipe_spell_id)"
    }
}
$ancientZulGurubBySpell = New-Index $ancientZulGurubRows "recipe_spell_id"
$ancientZulGurubSpellIDs = New-IDSet $ancientZulGurubRows "recipe_spell_id"
$historicalRecipeInventory = foreach ($ability in $skillLineAbilities | Where-Object {
    $allowedTradeCategories.ContainsKey([string]$_.TradeSkillCategoryID) -or $ancientZulGurubSpellIDs.ContainsKey([string]$_.Spell)
}) {
    $spell = $spellNames[[string]$ability.Spell]
    $ancientZulGurubAudit = $ancientZulGurubBySpell[[string]$ability.Spell]
    [pscustomobject]@{
        status                    = if ($ancientZulGurubAudit) { "acquisition_dragonflight_ancient_zulgurub" } elseif ($spell -and $spell.Name_lang -match "DNT|DO NOT USE") { "internal_dnt" } elseif ($spell -and $spell.Name_lang) { "named_recipe" } else { "unnamed_db2_ability_candidate" }
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
foreach ($audit in $ancientZulGurubRows) {
    $recipe = @($historicalRecipeInventory | Where-Object { [string]$_.recipe_spell_id -eq [string]$audit.recipe_spell_id })
    if ($recipe.Count -ne 1 -or [string]$recipe[0].profession -ne [string]$audit.profession) {
        throw "Ancient Zul'Gurub recipe audit mismatch for spell $($audit.recipe_spell_id)"
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
foreach ($rootID in $dfTradeRoots) { $currentTradeQueue.Enqueue($rootID) }
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
    if ($historicalRecipeIDs.ContainsKey([string]$ability.Spell)) { throw "Dragonflight house decor recipe $($ability.Spell) duplicates the historical inventory" }
    $spell = $currentTradeSpellNames[[string]$ability.Spell]
    if (-not $spell -or -not $spell.Name_lang) { throw "Dragonflight house decor recipe $($ability.Spell) has no current spell name" }
    [pscustomobject]@{
        status = "current_house_decor_recipe"; current_ability_exists = $true; current_spell_name_exists = $true
        profession = $professionNames[[string]$ability.SkillLine]; profession_id = $ability.SkillLine; recipe_spell_id = $ability.Spell; name = $spell.Name_lang
        skill_line_ability_id = $ability.ID; trade_category_id = $ability.TradeSkillCategoryID; acquire_method = $ability.AcquireMethod; supercedes_spell_id = $ability.SupercedesSpell
    }
}
$recipeInventory = @($historicalRecipeInventory) + @($houseDecorRecipeInventory)

$decorationInventory = foreach ($decor in $currentDecorRows) {
    $item = $currentItems[[string]$decor.ItemID]
    $isDNT = $decor.Name_lang -match "DNT|DO NOT USE"
    $catalogName = $catalogDecorNames[[string]$decor.ID]
    $catalogDetail = $catalogDetailsByID[[string]$decor.ID]
    $catalogAudit = $catalogAuditByID[[string]$decor.ID]
    [pscustomobject]@{
        status                = if ($isDNT) { "internal_dnt" } elseif ($catalogAudit) { $catalogAudit.status } elseif ($catalogName) { "catalog_theme_candidate" } elseif ($item -and $item.ExpansionID -eq "9") { "db2_item_expansion_signal" } else { "needs_acquisition_expansion" }
        acquisition_expansion = if ($catalogAudit) { $catalogAudit.acquisition_expansion } else { $null }
        catalog_theme_expansion = if ($catalogName) { "dragonflight" } else { $null }
        decor_id              = $decor.ID
        item_id               = $decor.ItemID
        decor_name            = $decor.Name_lang
        catalog_name          = if ($catalogName) { $catalogName } elseif ($catalogAudit) { $catalogAudit.catalog_name } else { $null }
        category              = if ($catalogDetail) { $catalogDetail.category } else { $null }
        source_text           = if ($catalogDetail) { $catalogDetail.source_text } elseif ($catalogAudit) { $catalogAudit.source_text } else { $null }
        achievement_ids       = if ($catalogDetail) { $catalogDetail.achievement_ids } elseif ($catalogAudit) { $catalogAudit.achievement_ids } else { $null }
        quest_ids             = if ($catalogDetail) { $catalogDetail.quest_ids } elseif ($catalogAudit) { $catalogAudit.quest_ids } else { $null }
        npc_ids               = if ($catalogDetail) { $catalogDetail.npc_ids } elseif ($catalogAudit) { $catalogAudit.npc_ids } else { $null }
        spell_ids             = if ($catalogDetail) { $catalogDetail.spell_ids } elseif ($catalogAudit) { $catalogAudit.spell_ids } else { $null }
        currency_ids          = if ($catalogDetail) { $catalogDetail.currency_ids } elseif ($catalogAudit) { $catalogAudit.currency_ids } else { $null }
        classification_note   = if ($catalogAudit) { $catalogAudit.classification_note } else { $null }
        acquisition_source_url = if ($catalogAudit) { $catalogAudit.acquisition_source_url } else { $null }
        item_name             = if ($item) { $item.Display_lang } else { $null }
        item_expansion_id     = if ($item) { $item.ExpansionID } else { $null }
        flags                 = $decor.Flags
        type                  = $decor.Type
        model_type            = $decor.ModelType
        weight_cost           = $decor.WeightCost
    }
}

$mapIDs = @("1978", "2022", "2023", "2024", "2025", "2118", "2151", "2133", "2200")
$mapInventory = Read-Table $dragonflightRoot "UiMap" | Where-Object { [string]$_.ID -in $mapIDs } | ForEach-Object {
    [pscustomobject]@{
        map_id        = $_.ID
        name          = $_.Name_lang
        parent_map_id = $_.ParentUiMapID
        system        = $_.System
        type          = $_.Type
        flags         = $_.Flags
    }
}

$dfFactionRows = Read-Table $dragonflightRoot "Faction"
$factionInventory = $dfFactionRows | Where-Object { $_.Expansion -eq "9" } | ForEach-Object {
    [pscustomobject]@{
        status             = if ($_.Name_lang -match "DNT") { "internal_dnt" } else { "dragonflight_expansion_signal" }
        faction_id         = $_.ID
        name               = $_.Name_lang
        parent_faction_id  = $_.ParentFactionID
        renown_currency_id = $_.RenownCurrencyID
        friendship_rep_id  = $_.FriendshipRepID
        flags              = $_.Flags
    }
}

$currencyInventory = foreach ($currency in (Get-NewRows $slCurrencies $dfCurrencies)) {
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

Assert-Equal @($mountInventory).Count 212 "Mount snapshot row count"
Assert-Equal @($petInventory).Count 355 "Pet snapshot row count"
Assert-Equal @($toyInventory).Count 192 "Toy snapshot row count"
Assert-Equal @($achievementInventory).Count 3377 "Achievement snapshot row count"
Assert-Equal @($rareInventory).Count 197 "Rare criteria row count"
Assert-Equal @($treasureInventory).Count 57 "Treasure criteria row count"
Assert-Equal @($historicalRecipeInventory).Count 981 "Historical recipe row count"
Assert-Equal @($houseDecorRecipeInventory).Count 25 "Current Dragonflight house decor recipe count"
Assert-Equal @($recipeInventory).Count 1006 "Recipe row count"
Assert-Equal @($mapInventory).Count 9 "Map row count"
Assert-Equal @($factionInventory).Count 28 "Faction row count"
Assert-Equal @($currencyInventory).Count 739 "Currency row count"
Assert-Equal @($catalogRows).Count 171 "Housing catalog source row count"
Assert-Equal @($catalogDetailRows).Count 171 "Housing catalog detail row count"
Assert-Equal @($catalogAuditRows).Count 159 "Housing acquisition audit row count"

Assert-UniqueField $mountInventory "mount_id" "Mount inventory"
Assert-UniqueField $petInventory "species_id" "Pet inventory"
Assert-UniqueField $toyInventory "toy_id" "Toy inventory"
Assert-UniqueField $achievementInventory "achievement_id" "Achievement inventory"
Assert-UniqueField $recipeInventory "recipe_spell_id" "Recipe inventory"
Assert-UniqueField $rareInventory "tree_id" "Rare inventory"
Assert-UniqueField $treasureInventory "tree_id" "Treasure inventory"
Assert-UniqueField $mapInventory "map_id" "Map inventory"
Assert-UniqueField $catalogRows "decor_id" "Housing catalog source"
Assert-UniqueField $catalogDetailRows "decor_id" "Housing catalog details"
Assert-UniqueField $catalogAuditRows "decor_id" "Housing acquisition audit"

Assert-Equal @($mountInventory | Where-Object { -not $_.current_exists }).Count 0 "Mount IDs missing from current retail"
Assert-Equal @($petInventory | Where-Object { -not $_.current_exists }).Count 0 "Pet IDs missing from current retail"
Assert-Equal @($toyInventory | Where-Object { -not $_.current_exists }).Count 0 "Toy IDs missing from current retail"
Assert-Equal @($mountInventory | Where-Object { $_.release_decision -eq "include_dragonflight" }).Count 161 "Dragonflight mount manifest row count"
Assert-Equal @($mountInventory | Where-Object { $_.release_decision -eq "exclude_policy_external" }).Count 46 "Dragonflight mount external-policy exclusion count"
Assert-Equal @($mountInventory | Where-Object { $_.release_decision -eq "exclude_unobtainable_or_internal" }).Count 5 "Dragonflight mount unavailable/internal exclusion count"
Assert-Equal @($petInventory | Where-Object { $_.release_decision -eq "include_dragonflight" }).Count 164 "Dragonflight pet manifest row count"
Assert-Equal @($petInventory | Where-Object { $_.release_decision -eq "exclude_policy_external" }).Count 33 "Dragonflight pet external-policy exclusion count"
Assert-Equal @($petInventory | Where-Object { $_.release_decision -eq "exclude_unobtainable_or_internal" }).Count 34 "Dragonflight pet unavailable/internal exclusion count"
Assert-Equal @($petInventory | Where-Object { $_.release_decision -eq "exclude_noncollectible" }).Count 124 "Dragonflight noncollectible pet exclusion count"
Assert-Equal @($toyInventory | Where-Object { $_.release_decision -eq "include_dragonflight" }).Count 171 "Dragonflight toy manifest row count"
Assert-Equal @($toyInventory | Where-Object { $_.release_decision -eq "exclude_policy_external" }).Count 16 "Dragonflight toy external-policy exclusion count"
Assert-Equal @($toyInventory | Where-Object { $_.release_decision -eq "exclude_cross_expansion" }).Count 2 "Dragonflight toy cross-expansion exclusion count"
Assert-Equal @($toyInventory | Where-Object { $_.release_decision -eq "exclude_unobtainable_or_internal" }).Count 2 "Dragonflight toy unavailable/internal exclusion count"
Assert-Equal @($achievementInventory | Where-Object { $_.status -eq "dragonflight_category_confirmed" }).Count 569 "Dragonflight visible achievement manifest row count"
Assert-Equal @($achievementInventory | Where-Object { $_.status -eq "dragonflight_category_hidden" }).Count 1369 "Dragonflight hidden category achievement count"
Assert-Equal @($rareInventory | Where-Object { -not $_.npc_ids }).Count 0 "Unresolved rare NPC rows"
Assert-Equal @($historicalRecipeInventory | Where-Object { $_.status -eq "named_recipe" }).Count 948 "Historical named recipe count"
Assert-Equal @($historicalRecipeInventory | Where-Object { $_.status -eq "acquisition_dragonflight_ancient_zulgurub" }).Count 31 "Ancient Zul'Gurub acquisition recipe count"
Assert-Equal @($historicalRecipeInventory | Where-Object { $_.status -eq "internal_dnt" }).Count 1 "Internal recipe count"
Assert-Equal @($historicalRecipeInventory | Where-Object { $_.status -eq "unnamed_db2_ability_candidate" }).Count 1 "Unnamed recipe count"
Assert-Equal @($recipeInventory | Where-Object { $_.status -in @("named_recipe", "current_house_decor_recipe", "acquisition_dragonflight_ancient_zulgurub") }).Count 1004 "Named recipe count"
Assert-Equal @($recipeInventory | Where-Object { $_.status -in @("named_recipe", "current_house_decor_recipe", "acquisition_dragonflight_ancient_zulgurub") -and -not $_.current_ability_exists }).Count 0 "Named recipes missing from current retail"

$currentDecorByID = New-Index $currentDecorRows
foreach ($sourceRow in $catalogRows) {
    $decor = $currentDecorByID[[string]$sourceRow.decor_id]
    if (-not $decor) {
        throw "Housing catalog decor $($sourceRow.decor_id) is absent from current DB2"
    }
    if ($decor.Name_lang -ne $sourceRow.catalog_name) {
        throw "Housing catalog decor $($sourceRow.decor_id) name mismatch: '$($sourceRow.catalog_name)' vs '$($decor.Name_lang)'"
    }
    $detail = $catalogDetailsByID[[string]$sourceRow.decor_id]
    if (-not $detail) {
        throw "Housing catalog decor $($sourceRow.decor_id) is absent from the detail source"
    }
    if ($detail.catalog_name -ne $sourceRow.catalog_name) {
        throw "Housing catalog detail $($sourceRow.decor_id) name mismatch: '$($detail.catalog_name)' vs '$($sourceRow.catalog_name)'"
    }
    if ($decor.Name_lang -notmatch "DNT|DO NOT USE") {
        $audit = $catalogAuditByID[[string]$sourceRow.decor_id]
        if (-not $audit) {
            throw "Housing catalog decor $($sourceRow.decor_id) is absent from the acquisition audit"
        }
        if ($audit.catalog_name -ne $sourceRow.catalog_name) {
            throw "Housing acquisition audit $($sourceRow.decor_id) name mismatch: '$($audit.catalog_name)' vs '$($sourceRow.catalog_name)'"
        }
    }
}

Assert-Equal @($decorationInventory | Where-Object { $_.status -eq "acquisition_dragonflight_confirmed" }).Count 76 "Dragonflight decoration manifest row count"
Assert-Equal @($decorationInventory | Where-Object { $_.status -eq "acquisition_midnight_confirmed" }).Count 47 "Midnight-sourced Dragonflight-theme decoration count"
Assert-Equal @($decorationInventory | Where-Object { $_.status -eq "catalog_hidden_unobtainable" }).Count 28 "Hidden/unobtainable Dragonflight-theme decoration count"
Assert-Equal @($decorationInventory | Where-Object { $_.catalog_name -and (([int]$_.flags -band 128) -ne 0) }).Count 50 "Hidden Dragonflight-theme catalog row count"
Assert-Equal @($decorationInventory | Where-Object { $_.status -eq "catalog_hidden_unobtainable" -and (([int]$_.flags -band 128) -eq 0) }).Count 0 "Hidden/unobtainable rows missing HiddenInCatalog flag"
Assert-Equal @($decorationInventory | Where-Object { $_.status -eq "catalog_hidden_unobtainable" -and $_.source_text }).Count 0 "Hidden/unobtainable rows with an acquisition source"

$summary = @()
$summary += Export-Inventory "mounts" ($mountInventory | Sort-Object { [int]$_.mount_id })
$summary += Export-Inventory "pets" ($petInventory | Sort-Object { [int]$_.species_id })
$summary += Export-Inventory "toys" ($toyInventory | Sort-Object { [int]$_.toy_id })
$summary += Export-Inventory "decorations" ($decorationInventory | Sort-Object { [int]$_.decor_id })
$summary += Export-Inventory "achievements" ($achievementInventory | Sort-Object { [int]$_.achievement_id })
$summary += Export-Inventory "achievement-criteria" ($achievementCriteriaInventory | Sort-Object { [int]$_.achievement_id }, { Get-OrderPathSortKey $_.order_path })
$summary += Export-Inventory "rares" ($rareInventory | Sort-Object { [int]$_.achievement_id }, { Get-OrderPathSortKey $_.order_path })
$summary += Export-Inventory "treasures" ($treasureInventory | Sort-Object { [int]$_.achievement_id }, { Get-OrderPathSortKey $_.order_path })
$summary += Export-Inventory "recipes" ($recipeInventory | Sort-Object profession, { [int]$_.recipe_spell_id })
$summary += Export-Inventory "maps" ($mapInventory | Sort-Object { [int]$_.map_id })
$summary += Export-Inventory "factions" ($factionInventory | Sort-Object { [int]$_.faction_id })
$summary += Export-Inventory "currencies" ($currencyInventory | Sort-Object { [int]$_.currency_id })

Write-CsvFile (Join-Path $OutputRoot "summary.csv") $summary
$decorationManifest = @($decorationInventory |
    Where-Object { $_.status -eq "acquisition_dragonflight_confirmed" } |
    Sort-Object { [int]$_.decor_id })
$mountManifest = @($mountInventory |
    Where-Object { $_.release_decision -eq "include_dragonflight" } |
    Sort-Object { [int]$_.mount_id })
$petManifest = @($petInventory |
    Where-Object { $_.release_decision -eq "include_dragonflight" } |
    Sort-Object { [int]$_.species_id })
$toyManifest = @($toyInventory |
    Where-Object { $_.release_decision -eq "include_dragonflight" } |
    Sort-Object { [int]$_.toy_id })
Write-CsvFile (Join-Path $ManifestRoot "decorations.csv") $decorationManifest
Write-CsvFile (Join-Path $ManifestRoot "mounts.csv") $mountManifest
Write-CsvFile (Join-Path $ManifestRoot "pets.csv") $petManifest
Write-CsvFile (Join-Path $ManifestRoot "toys.csv") $toyManifest
$achievementManifest = @($achievementInventory | Where-Object { $_.status -eq "dragonflight_category_confirmed" } | Sort-Object { [int]$_.achievement_id })
$achievementManifestIDs = @($achievementManifest | ForEach-Object { [string]$_.achievement_id })
$achievementCriteriaManifest = @($achievementCriteriaInventory |
    Where-Object { [string]$_.achievement_id -in $achievementManifestIDs } |
    Sort-Object { [int]$_.achievement_id }, { Get-OrderPathSortKey $_.order_path })
Assert-Equal @($achievementCriteriaManifest).Count 3203 "Dragonflight visible achievement criteria manifest row count"
Assert-UniqueField $achievementCriteriaManifest "tree_id" "Dragonflight visible achievement criteria manifest"
$recipeManifest = @($recipeInventory | Where-Object { $_.status -in @("named_recipe", "current_house_decor_recipe", "acquisition_dragonflight_ancient_zulgurub") } | Sort-Object profession, { [int]$_.recipe_spell_id })
$rareManifest = @($rareInventory | Sort-Object { [int]$_.achievement_id }, { Get-OrderPathSortKey $_.order_path })
$treasureManifest = @($treasureInventory | Sort-Object { [int]$_.achievement_id }, { Get-OrderPathSortKey $_.order_path })
Write-CsvFile (Join-Path $ManifestRoot "achievements.csv") $achievementManifest
Write-CsvFile (Join-Path $ManifestRoot "achievement-criteria.csv") $achievementCriteriaManifest
Write-CsvFile (Join-Path $ManifestRoot "recipes.csv") $recipeManifest
Write-CsvFile (Join-Path $ManifestRoot "rares.csv") $rareManifest
Write-CsvFile (Join-Path $ManifestRoot "treasures.csv") $treasureManifest
$supportingCurrencyIDs = [System.Collections.Generic.HashSet[string]]::new()
foreach ($row in @($mountManifest) + @($petManifest) + @($toyManifest) + @($decorationManifest)) {
    foreach ($match in [regex]::Matches([string]$row.source_text, "currency:(\d+)")) {
        [void]$supportingCurrencyIDs.Add($match.Groups[1].Value)
    }
    foreach ($currencyID in ([string]$row.currency_ids -split ";")) {
        if ($currencyID) { [void]$supportingCurrencyIDs.Add($currencyID) }
    }
}
$dfCurrencyByID = New-Index $dfCurrencies
$supportingCurrencyManifest = @($supportingCurrencyIDs | Sort-Object { [int]$_ } | ForEach-Object {
    $currency = $dfCurrencyByID[[string]$_]
    if (-not $currency) { throw "Supporting currency $_ is absent from the final Dragonflight snapshot" }
    [pscustomobject]@{
        currency_id = $currency.ID
        name         = $currency.Name_lang
        description  = $currency.Description_lang
        category_id  = $currency.CategoryID
        faction_id   = $currency.FactionID
        max_quantity = $currency.MaxQty
        source       = "selected_collectible_source"
    }
})
$supportingFactionIDs = @(
    "2503", "2507", "2510", "2511", "2517", "2518", "2526", "2544", "2550", "2553", "2564", "2568",
    "2574", "2593", "2615"
)
$dfFactionByID = New-Index $dfFactionRows
$supportingFactionManifest = @($supportingFactionIDs | ForEach-Object {
    $faction = $dfFactionByID[[string]$_]
    if (-not $faction) { throw "Supporting faction $_ is absent from the final Dragonflight snapshot" }
    [pscustomobject]@{
        faction_id        = $faction.ID
        name              = $faction.Name_lang
        parent_faction_id = $faction.ParentFactionID
        renown_currency_id = $faction.RenownCurrencyID
        friendship_rep_id = $faction.FriendshipRepID
        source            = "selected_collectible_requirement"
    }
})
Assert-Equal @($supportingCurrencyManifest).Count 8 "Dragonflight supporting currency manifest row count"
Assert-Equal @($supportingFactionManifest).Count 15 "Dragonflight supporting faction manifest row count"
Assert-UniqueField $supportingCurrencyManifest "currency_id" "Dragonflight supporting currency manifest"
Assert-UniqueField $supportingFactionManifest "faction_id" "Dragonflight supporting faction manifest"
Write-CsvFile (Join-Path $ManifestRoot "supporting-currencies.csv") $supportingCurrencyManifest
Write-CsvFile (Join-Path $ManifestRoot "supporting-factions.csv") $supportingFactionManifest
Write-CsvFile (Join-Path $ManifestRoot "supporting-maps.csv") @($mapInventory | Sort-Object { [int]$_.map_id })
$manifestSummary = @(
    [pscustomobject]@{ manifest = "mounts"; rows = 161; identifier = "mount_id" }
    [pscustomobject]@{ manifest = "pets"; rows = 164; identifier = "species_id" }
    [pscustomobject]@{ manifest = "toys"; rows = 171; identifier = "toy_id" }
    [pscustomobject]@{ manifest = "decorations"; rows = 76; identifier = "decor_id" }
    [pscustomobject]@{ manifest = "recipes"; rows = 1004; identifier = "recipe_spell_id" }
    [pscustomobject]@{ manifest = "achievements"; rows = 569; identifier = "achievement_id" }
    [pscustomobject]@{ manifest = "achievement-criteria"; rows = 3203; identifier = "tree_id" }
    [pscustomobject]@{ manifest = "rares"; rows = 197; identifier = "tree_id" }
    [pscustomobject]@{ manifest = "treasures"; rows = 57; identifier = "tree_id" }
    [pscustomobject]@{ manifest = "supporting-currencies"; rows = 8; identifier = "currency_id" }
    [pscustomobject]@{ manifest = "supporting-factions"; rows = 15; identifier = "faction_id" }
    [pscustomobject]@{ manifest = "supporting-maps"; rows = 9; identifier = "map_id" }
)
Write-CsvFile (Join-Path $ManifestRoot "summary.csv") $manifestSummary
$summary | Format-Table -AutoSize
