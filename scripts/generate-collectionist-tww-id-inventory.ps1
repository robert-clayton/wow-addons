param(
    [string]$Db2Root = (Join-Path $env:TEMP "collectionist-tww-db2"),
    [string]$OutputRoot = (Join-Path $PSScriptRoot "..\research\collectionist\tww\ids")
)

$ErrorActionPreference = "Stop"

$dragonflightRoot = Join-Path $Db2Root "dragonflight"
$twwRoot = Join-Path $Db2Root "tww"
$currentRoot = Join-Path $Db2Root "current"
$guideRoot = Join-Path $Db2Root "guides"

foreach ($required in @($dragonflightRoot, $twwRoot, $currentRoot, $guideRoot)) {
    if (-not (Test-Path -LiteralPath $required)) {
        throw "Missing input directory: $required"
    }
}

New-Item -ItemType Directory -Force -Path $OutputRoot | Out-Null

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
    $oldIDs = @{}
    foreach ($row in $oldRows) { $oldIDs[[string]$row.ID] = $true }
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

function Export-Inventory([string]$name, $rows) {
    $path = Join-Path $OutputRoot "$name.csv"
    @($rows) | Export-Csv -LiteralPath $path -NoTypeInformation -Encoding utf8
    return [pscustomobject]@{ file = $name; rows = @($rows).Count }
}

$dfMounts = Read-Table $dragonflightRoot "Mount"
$twwMounts = Read-Table $twwRoot "Mount"
$dfPets = Read-Table $dragonflightRoot "BattlePetSpecies"
$twwPets = Read-Table $twwRoot "BattlePetSpecies"
$dfToys = Read-Table $dragonflightRoot "Toy"
$twwToys = Read-Table $twwRoot "Toy"
$dfAchievements = Read-Table $dragonflightRoot "Achievement"
$twwAchievements = Read-Table $twwRoot "Achievement"
$dfCurrencies = Read-Table $dragonflightRoot "CurrencyTypes"
$twwCurrencies = Read-Table $twwRoot "CurrencyTypes"

$currentMountIDs = New-IDSet (Read-Table $currentRoot "Mount")
$currentPetIDs = New-IDSet (Read-Table $currentRoot "BattlePetSpecies")
$currentToyIDs = New-IDSet (Read-Table $currentRoot "Toy")
$currentAchievementIDs = New-IDSet (Read-Table $currentRoot "Achievement")
$currentDecorIDs = New-IDSet (Read-Table $currentRoot "HouseDecor")
$currentRecipeSpellIDs = New-IDSet (Read-Table $currentRoot "SkillLineAbility") "Spell"
$currentSpellNameIDs = New-IDSet (Read-Table $currentRoot "SpellName")

$items = New-Index (Read-Table $twwRoot "ItemSparse")
$creatures = New-Index (Read-Table $twwRoot "Creature")
$effects = New-Index (Read-Table $twwRoot "ItemEffect")
$itemEffects = Read-Table $twwRoot "ItemXItemEffect"
$achievementCategories = Read-Table $twwRoot "Achievement_Category"
$achievementCategoryByID = New-Index $achievementCategories
$criteriaRows = Read-Table $twwRoot "Criteria"
$criteriaByID = New-Index $criteriaRows
$criteriaTreeRows = Read-Table $twwRoot "CriteriaTree"
$tradeSkillCategories = Read-Table $twwRoot "TradeSkillCategory"
$skillLineAbilities = Read-Table $twwRoot "SkillLineAbility"
$spellNames = New-Index (Read-Table $twwRoot "SpellName")

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

$twwSignalPattern = "The War Within|Khaz Algar|Isle of Dorn|Ringing Deeps|Hallowfall|Azj-Kahet|Nerub-ar|Undermine|Siren Isle|K.aresh|Manaforge Omega|Liberation of Undermine|Delve|Dastardly Duos"

$mountGuideFiles = @("mounts.html", "mounts-11-2.html", "mounts-11-2-7.html")
$mountGuideText = ($mountGuideFiles | ForEach-Object {
    Get-Content -Raw -LiteralPath (Join-Path $guideRoot $_)
}) -join "`n"
$mountGuideItems = Get-RegexIDs $mountGuideText "(?:/item=|\[item=)(\d+)"
$mountGuideSpells = @{}
foreach ($relation in $itemEffects) {
    if (-not $mountGuideItems.ContainsKey([string]$relation.ItemID)) { continue }
    $effect = $effects[[string]$relation.ItemEffectID]
    if ($effect -and $effect.SpellID) {
        $mountGuideSpells[[string]$effect.SpellID] = [string]$relation.ItemID
    }
}

$mountInventory = foreach ($mount in (Get-NewRows $dfMounts $twwMounts)) {
    $itemIDs = @($itemsBySpell[[string]$mount.SourceSpellID])
    $itemExpansionIDs = @($itemIDs | ForEach-Object {
        $item = $items[[string]$_]
        if ($item) { $item.ExpansionID }
    })
    $guideItemID = $mountGuideSpells[[string]$mount.SourceSpellID]
    $guideNameMatch = $mount.SourceText_lang -and $mount.Name_lang -and
        $mountGuideText.IndexOf($mount.Name_lang, [System.StringComparison]::OrdinalIgnoreCase) -ge 0
    $status = if ($guideItemID -or $guideNameMatch) {
        "guide_confirmed"
    } elseif (($itemExpansionIDs -contains "10") -or $mount.SourceText_lang -match $twwSignalPattern) {
        "db2_tww_signal"
    } else {
        "snapshot_candidate"
    }
    [pscustomobject]@{
        status             = $status
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

$petGuideFiles = @("pets.html", "pets_wild.html", "pets_siren.html", "pets_undermine.html", "pets_karesh.html")
$petGuideText = ($petGuideFiles | ForEach-Object {
    Get-Content -Raw -LiteralPath (Join-Path $guideRoot $_)
}) -join "`n"
$petGuideItems = Get-RegexIDs $petGuideText "(?:/item=|\[item=)(\d+)"
$petGuideNPCs = Get-RegexIDs $petGuideText "(?:/npc=|\[npc=)(\d+)"
$petGuideSpells = @{}
foreach ($relation in $itemEffects) {
    if (-not $petGuideItems.ContainsKey([string]$relation.ItemID)) { continue }
    $effect = $effects[[string]$relation.ItemEffectID]
    if ($effect -and $effect.SpellID) {
        $petGuideSpells[[string]$effect.SpellID] = [string]$relation.ItemID
    }
}
$guideNPCNames = @{}
foreach ($match in [regex]::Matches($petGuideText, '<a href="/npc=(\d+)(?:/[^"#?]*)?"[^>]*>([^<]+)</a>')) {
    $guideNPCNames[$match.Groups[1].Value] = [System.Net.WebUtility]::HtmlDecode($match.Groups[2].Value)
}

$petInventory = foreach ($pet in (Get-NewRows $dfPets $twwPets)) {
    $itemIDs = @($itemsBySpell[[string]$pet.SummonSpellID])
    $itemExpansionIDs = @($itemIDs | ForEach-Object {
        $item = $items[[string]$_]
        if ($item) { $item.ExpansionID }
    })
    $guideItemID = $petGuideSpells[[string]$pet.SummonSpellID]
    $guideNPCMatch = $petGuideNPCs.ContainsKey([string]$pet.CreatureID)
    $status = if ($guideItemID -or $guideNPCMatch) {
        "guide_confirmed"
    } elseif ($pet.SummonSpellID -eq "0") {
        "noncollectible_pet_battle_npc"
    } elseif (($itemExpansionIDs -contains "10") -or $pet.SourceText_lang -match $twwSignalPattern) {
        "db2_tww_signal"
    } else {
        "snapshot_candidate"
    }
    $creature = $creatures[[string]$pet.CreatureID]
    $name = $guideNPCNames[[string]$pet.CreatureID]
    if (-not $name -and $creature) { $name = $creature.Name_lang }
    [pscustomobject]@{
        status             = $status
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
        source_text        = $pet.SourceText_lang
    }
}

$toyInventory = foreach ($toy in (Get-NewRows $dfToys $twwToys)) {
    $item = $items[[string]$toy.ItemID]
    $status = if ($item -and $item.ExpansionID -eq "10") {
        "item_expansion_confirmed"
    } elseif ($toy.SourceText_lang -match $twwSignalPattern) {
        "db2_tww_signal"
    } else {
        "snapshot_candidate"
    }
    [pscustomobject]@{
        status            = $status
        current_exists    = $currentToyIDs.ContainsKey([string]$toy.ID)
        toy_id            = $toy.ID
        item_id           = $toy.ItemID
        name              = if ($item) { $item.Display_lang } else { $null }
        item_expansion_id = if ($item) { $item.ExpansionID } else { $null }
        source_type_enum  = $toy.SourceTypeEnum
        flags             = $toy.Flags
        source_text       = $toy.SourceText_lang
    }
}

$twwAchievementCategoryIDs = @("15506", "15521", "15523", "15524", "15526", "15530", "15531")
$achievementInventory = foreach ($achievement in (Get-NewRows $dfAchievements $twwAchievements)) {
    $category = $achievementCategoryByID[[string]$achievement.Category]
    [pscustomobject]@{
        status           = if ([string]$achievement.Category -in $twwAchievementCategoryIDs) { "tww_category_confirmed" } else { "snapshot_candidate" }
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
                    order_path   = $path
                    tree_id      = $node.ID
                    description  = $node.Description_lang
                    criteria_id  = $node.CriteriaID
                    criteria_type = if ($criterion) { $criterion.Type } else { $null }
                    asset_id     = if ($criterion) { $criterion.Asset } else { $null }
                    amount       = $node.Amount
                    operator     = $node.Operator
                }
            } else {
                $queue.Enqueue(@([string]$node.ID, $path))
            }
        }
    }
}

$achievementByID = New-Index $twwAchievements
$achievementCriteriaInventory = foreach ($achievement in $twwAchievements | Where-Object {
    [string]$_.Category -in $twwAchievementCategoryIDs -and $_.Criteria_tree -ne "0"
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

$rareGuideText = @("azj.html", "hallowfall.html", "karesh.html") | ForEach-Object {
    Get-Content -Raw -LiteralPath (Join-Path $guideRoot $_)
}
$rareNPCNames = @{}
foreach ($match in [regex]::Matches(($rareGuideText -join "`n"), '<a href="/npc=(\d+)(?:/[^"#?]*)?"[^>]*>([^<]+)</a>')) {
    $name = [System.Net.WebUtility]::HtmlDecode($match.Groups[2].Value)
    $rareNPCNames[$name] = $match.Groups[1].Value
}

function Resolve-RareNPCIDs([string]$description, [string]$criteriaType, [string]$assetID) {
    if ($criteriaType -eq "0") { return $assetID }
    $names = @($description -split "\s*&\s*")
    $resolved = foreach ($name in $names) {
        $id = $rareNPCNames[$name]
        if (-not $id -and $name.StartsWith("The ")) { $id = $rareNPCNames[$name.Substring(4)] }
        if ($id) { $id }
    }
    return Join-IDs $resolved
}

$rareAchievementIDs = @("40435", "40837", "40840", "40851", "41046", "41216", "42761")
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
            npc_ids        = Resolve-RareNPCIDs $leaf.description $leaf.criteria_type $leaf.asset_id
        }
    }
}

$treasureAchievementIDs = @("40434", "40724", "40828", "40848", "41131", "41217", "42741")
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
$twwTradeRoots = @("1898", "1900", "1902", "1904", "1906", "1912", "1914", "1916", "1922")
$allowedTradeCategories = @{}
$tradeQueue = [System.Collections.Generic.Queue[string]]::new()
foreach ($rootID in $twwTradeRoots) { $tradeQueue.Enqueue($rootID) }
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
$recipeInventory = foreach ($ability in $skillLineAbilities | Where-Object {
    $allowedTradeCategories.ContainsKey([string]$_.TradeSkillCategoryID)
}) {
    $spell = $spellNames[[string]$ability.Spell]
    [pscustomobject]@{
        status               = if ($spell -and $spell.Name_lang) { "named_recipe" } else { "unnamed_db2_ability_candidate" }
        current_ability_exists = $currentRecipeSpellIDs.ContainsKey([string]$ability.Spell)
        current_spell_name_exists = $currentSpellNameIDs.ContainsKey([string]$ability.Spell)
        profession           = $professionNames[[string]$ability.SkillLine]
        profession_id        = $ability.SkillLine
        recipe_spell_id      = $ability.Spell
        name                 = if ($spell) { $spell.Name_lang } else { $null }
        skill_line_ability_id = $ability.ID
        trade_category_id    = $ability.TradeSkillCategoryID
        acquire_method       = $ability.AcquireMethod
        supercedes_spell_id  = $ability.SupercedesSpell
    }
}

$decorationInventory = foreach ($decor in (Read-Table $twwRoot "HouseDecor")) {
    $item = $items[[string]$decor.ItemID]
    $isDNT = $decor.Name_lang -match "DNT|DO NOT USE"
    $currentExists = $currentDecorIDs.ContainsKey([string]$decor.ID)
    [pscustomobject]@{
        status      = if ($isDNT) { "internal_dnt" } elseif (-not $currentExists) { "removed_after_tww" } else { "snapshot_candidate_needs_source_expansion" }
        current_exists = $currentExists
        decor_id    = $decor.ID
        item_id     = $decor.ItemID
        decor_name  = $decor.Name_lang
        item_name   = if ($item) { $item.Display_lang } else { $null }
        flags       = $decor.Flags
        type        = $decor.Type
        model_type  = $decor.ModelType
        weight_cost = $decor.WeightCost
    }
}

$mapIDs = @("2214", "2215", "2248", "2255", "2274", "2339", "2346", "2369", "2371", "2472")
$mapInventory = Read-Table $twwRoot "UiMap" | Where-Object { [string]$_.ID -in $mapIDs } | ForEach-Object {
    [pscustomobject]@{
        map_id        = $_.ID
        name          = $_.Name_lang
        parent_map_id = $_.ParentUiMapID
        system        = $_.System
        type          = $_.Type
        flags         = $_.Flags
    }
}

$factionInventory = Read-Table $twwRoot "Faction" | Where-Object { $_.Expansion -eq "10" } | ForEach-Object {
    [pscustomobject]@{
        faction_id        = $_.ID
        name              = $_.Name_lang
        parent_faction_id = $_.ParentFactionID
        renown_currency_id = $_.RenownCurrencyID
        friendship_rep_id = $_.FriendshipRepID
        flags             = $_.Flags
    }
}

$currencyInventory = foreach ($currency in (Get-NewRows $dfCurrencies $twwCurrencies)) {
    [pscustomobject]@{
        currency_id = $currency.ID
        name        = $currency.Name_lang
        description = $currency.Description_lang
        category_id = $currency.CategoryID
        faction_id  = $currency.FactionID
        max_quantity = $currency.MaxQty
        flags_0     = $currency.Flags_0
        flags_1     = $currency.Flags_1
    }
}

$summary = @()
$summary += Export-Inventory "mounts" ($mountInventory | Sort-Object { [int]$_.mount_id })
$summary += Export-Inventory "pets" ($petInventory | Sort-Object { [int]$_.species_id })
$summary += Export-Inventory "toys" ($toyInventory | Sort-Object { [int]$_.toy_id })
$summary += Export-Inventory "decorations" ($decorationInventory | Sort-Object { [int]$_.decor_id })
$summary += Export-Inventory "achievements" ($achievementInventory | Sort-Object { [int]$_.achievement_id })
$summary += Export-Inventory "achievement-criteria" ($achievementCriteriaInventory | Sort-Object { [int]$_.achievement_id }, order_path)
$summary += Export-Inventory "rares" ($rareInventory | Sort-Object { [int]$_.achievement_id }, order_path)
$summary += Export-Inventory "treasures" ($treasureInventory | Sort-Object { [int]$_.achievement_id }, order_path)
$summary += Export-Inventory "recipes" ($recipeInventory | Sort-Object profession, { [int]$_.recipe_spell_id })
$summary += Export-Inventory "maps" ($mapInventory | Sort-Object { [int]$_.map_id })
$summary += Export-Inventory "factions" ($factionInventory | Sort-Object { [int]$_.faction_id })
$summary += Export-Inventory "currencies" ($currencyInventory | Sort-Object { [int]$_.currency_id })

$summary | Export-Csv -LiteralPath (Join-Path $OutputRoot "summary.csv") -NoTypeInformation -Encoding utf8
$summary | Format-Table -AutoSize
