param(
    [string]$Db2Root = (Join-Path $env:TEMP "collectionist-tww-db2"),
    [string]$OutputRoot = (Join-Path $PSScriptRoot "..\research\collectionist\tww\ids"),
    [string]$ManifestRoot = (Join-Path $PSScriptRoot "..\research\collectionist\tww\manifests")
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "collectionist-wild-pet-rules.ps1")
. (Join-Path $PSScriptRoot "collectionist-current-criteria.ps1")

$dragonflightRoot = Join-Path $Db2Root "dragonflight"
$twwRoot = Join-Path $Db2Root "tww"
$currentRoot = Join-Path $Db2Root "current"
$guideRoot = Join-Path $Db2Root "guides"
$decorSourcePath = Join-Path $PSScriptRoot "..\research\collectionist\tww\sources\housing-wowdb.csv"
$decorDetailSourcePath = Join-Path $PSScriptRoot "..\research\collectionist\tww\sources\housing-wowdb-details.csv"
$decorItemAuditSourcePath = Join-Path $PSScriptRoot "..\research\collectionist\tww\sources\housing-wowdb-item-audit.csv"
$petPreloadAuditSourcePath = Join-Path $PSScriptRoot "..\research\collectionist\tww\sources\pet-preload-audit.csv"

foreach ($required in @($dragonflightRoot, $twwRoot, $currentRoot, $guideRoot)) {
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

function Write-CsvFile([string]$path, $rows) {
    $lines = @($rows) | ConvertTo-Csv -NoTypeInformation
    $text = if ($lines.Count -gt 0) { ($lines -join "`n") + "`n" } else { "" }
    $text = $text.Replace("`r`n", "`n").Replace("`r", "`n")
    $text = [regex]::Replace($text, "[ \t]+(?=`n)", "")
    [System.IO.File]::WriteAllText($path, $text, [System.Text.UTF8Encoding]::new($false))
}

function Get-DecorAcquisitionExpansion([string]$sourceText) {
    if ([string]::IsNullOrWhiteSpace($sourceText)) { return $null }

    # Housing decor was introduced with Midnight. Expansion ownership follows
    # the content that awards the decor, not the row's DB2 creation date or its
    # thematic catalog tag.
    if ($sourceText -match "Midnight Leatherworking|Founder's Point|Razorwind Shores|Harandar|Voidlight Marl|Arcantina|The Coiled Isle|Community Coupons") {
        return "midnight"
    }
    if ($sourceText -match "Amirdrassil|Dragon Isles Supplies") {
        return "dragonflight"
    }
    if ($sourceText -match "Khaz Algar|Dornogal|Hallowfall|Undermine|Liberation of Undermine|Isle of Dorn|Ringing Deeps|City of Threads|K'aresh|Resonance Crystals|Kej|Sizzling Cinderpollen|Theater Troupe|Priory of the Sacred Flame|Cinderbrew Meadery|Sprinting in the Ravine|Deephaul Ravine|Lorewalking|Worldsoul-Searching|Encounter: The Darkness") {
        return "tww"
    }

    return $null
}

function Export-Inventory([string]$name, $rows) {
    $path = Join-Path $OutputRoot "$name.csv"
    Write-CsvFile $path @($rows)
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
$currentDecorRows = Read-Table $currentRoot "HouseDecor"
$currentDecorIDs = New-IDSet $currentDecorRows
$currentDecorByID = New-Index $currentDecorRows
$currentItems = New-Index (Read-Table $currentRoot "ItemSparse")
$catalogDecorNames = @{}
$catalogRows = @()
$catalogDetailByID = @{}
$catalogDetailRows = @()
$catalogItemAuditByID = @{}
$catalogItemAuditRows = @()
$petPreloadAuditByID = @{}
$petPreloadAuditRows = @()
if (Test-Path -LiteralPath $decorSourcePath) {
    $catalogRows = @(Import-Csv -LiteralPath $decorSourcePath)
    foreach ($row in $catalogRows) {
        $catalogDecorNames[[string]$row.decor_id] = $row.catalog_name
    }
}
if (Test-Path -LiteralPath $decorDetailSourcePath) {
    $catalogDetailRows = @(Import-Csv -LiteralPath $decorDetailSourcePath)
    $catalogDetailByID = New-Index $catalogDetailRows "decor_id"
}
if (Test-Path -LiteralPath $decorItemAuditSourcePath) {
    $catalogItemAuditRows = @(Import-Csv -LiteralPath $decorItemAuditSourcePath)
    $catalogItemAuditByID = New-Index $catalogItemAuditRows "decor_id"
}
if (Test-Path -LiteralPath $petPreloadAuditSourcePath) {
    $petPreloadAuditRows = @(Import-Csv -LiteralPath $petPreloadAuditSourcePath)
    $petPreloadAuditByID = New-Index $petPreloadAuditRows "species_id"
}
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
$externalCollectionPattern = "In-Game Shop|Trading Post|Promotion"
$toySnapshotIncludeItemIDs = @("218310", "224192", "226191", "228789", "229828", "218308", "228966", "245946", "245942", "246227", "256881", "256893")
$toyExcludedItemIDs = @("239018", "243304", "245580")

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
    $releaseDecision = if ($mount.SourceText_lang -match $externalCollectionPattern) {
        "exclude_policy_external"
    } elseif ($status -in @("guide_confirmed", "db2_tww_signal")) {
        "include_tww"
    } elseif ($mount.SourceText_lang -match "World Event:\|r WoW Remix: Legion" -and $itemIDs.Count -gt 0 -and $mount.Name_lang -notmatch "^\(PH\)") {
        "include_tww"
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

# Sapphire Crab existed as an uncollectible preload in Dragonflight, then
# gained its real Isle of Dorn treasure source and item in The War Within.
$twwReacquiredPetIDs = @("3362")
$twwPetCandidates = @((Get-NewRows $dfPets $twwPets)) + @($twwPets | Where-Object { [string]$_.ID -in $twwReacquiredPetIDs })
$petInventory = foreach ($pet in $twwPetCandidates) {
    $itemIDs = @($itemsBySpell[[string]$pet.SummonSpellID])
    $itemExpansionIDs = @($itemIDs | ForEach-Object {
        $item = $items[[string]$_]
        if ($item) { $item.ExpansionID }
    })
    $guideItemID = $petGuideSpells[[string]$pet.SummonSpellID]
    $guideNPCMatch = $petGuideNPCs.ContainsKey([string]$pet.CreatureID)
    $status = if ($guideItemID -or $guideNPCMatch) {
        "guide_confirmed"
    } elseif (Test-CollectionistCollectibleWildPet $pet) {
        "collectible_wild_pet_shared_audit"
    } elseif ($pet.SummonSpellID -eq "0") {
        "noncollectible_pet_battle_npc"
    } elseif (($itemExpansionIDs -contains "10") -or $pet.SourceText_lang -match $twwSignalPattern) {
        "db2_tww_signal"
    } else {
        "snapshot_candidate"
    }
    $preloadAudit = $petPreloadAuditByID[[string]$pet.ID]
    if ($preloadAudit) {
        $status = $preloadAudit.status
    }
    $releaseDecision = if ($status -eq "post_tww_preload") {
        "exclude_cross_expansion"
    } elseif ($status -eq "collectible_wild_pet_shared_audit") {
        "exclude_shared_wild_audit"
    } elseif ($status -eq "noncollectible_pet_battle_npc") {
        "exclude_noncollectible"
    } elseif ($pet.SourceText_lang -match $externalCollectionPattern) {
        "exclude_policy_external"
    } elseif ($pet.ID -eq "4837") {
        "exclude_unobtainable_or_internal"
    } elseif ($status -in @("guide_confirmed", "db2_tww_signal")) {
        "include_tww"
    } elseif ($status -eq "snapshot_candidate" -and $pet.SourceText_lang -match "World Event|Vendor:|Drop:") {
        "include_tww"
    } else {
        "exclude_unobtainable_or_internal"
    }
    $creature = $creatures[[string]$pet.CreatureID]
    $name = $guideNPCNames[[string]$pet.CreatureID]
    if (-not $name -and $creature) { $name = $creature.Name_lang }
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
        source_text        = $pet.SourceText_lang
        audited_release_expansion = if ($preloadAudit) { $preloadAudit.release_expansion } else { $null }
        audited_source_content_expansion = if ($preloadAudit) { $preloadAudit.source_content_expansion } else { $null }
        audit_source_url   = if ($preloadAudit) { $preloadAudit.source_url } else { $null }
    }
}

if (@($petPreloadAuditRows).Count -ne 2) {
    throw "Pet preload audit row count mismatch: expected 2, got $(@($petPreloadAuditRows).Count)"
}
if (@($petPreloadAuditRows | Group-Object species_id | Where-Object { $_.Count -gt 1 }).Count -gt 0) {
    throw "Pet preload audit contains duplicate species IDs"
}
if (@($petInventory | Where-Object { [string]$_.species_id -in $twwReacquiredPetIDs -and $_.release_decision -eq "include_tww" }).Count -ne $twwReacquiredPetIDs.Count) {
    throw "TWW reacquired pet overrides were not included"
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
    $releaseDecision = if ([string]$toy.ItemID -eq "239018") {
        "exclude_duplicate_registration"
    } elseif ([string]$toy.ItemID -in @("243304", "245580")) {
        "exclude_unobtainable_or_internal"
    } elseif ($toy.SourceText_lang -match "WoW Esports|Promotion") {
        "exclude_policy_external"
    } elseif ([string]$toy.ItemID -in $toySnapshotIncludeItemIDs -or $status -in @("item_expansion_confirmed", "db2_tww_signal")) {
        "include_tww"
    } elseif ([string]::IsNullOrWhiteSpace($toy.SourceText_lang)) {
        "exclude_unobtainable_or_internal"
    } else {
        "exclude_cross_expansion"
    }
    [pscustomobject]@{
        status            = $status
        release_decision  = $releaseDecision
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
    $isTwwCategory = [string]$achievement.Category -in $twwAchievementCategoryIDs
    $isHidden = (([int64]$achievement.Flags -band 0x100000) -ne 0)
    [pscustomobject]@{
        status           = if ($isTwwCategory -and $isHidden) { "tww_category_hidden" } elseif ($isTwwCategory) { "tww_category_confirmed" } else { "snapshot_candidate" }
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
$currentEncounterCriteria = @(Sync-CollectionistAchievementCriteria $achievementCriteriaInventory $currentRoot -AllAchievements)
$rareInventory = @(Sync-CollectionistEncounterRows $rareInventory $currentEncounterCriteria)
$treasureInventory = @(Sync-CollectionistEncounterRows $treasureInventory $currentEncounterCriteria)

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
$tradeCategoryByID = New-Index $tradeSkillCategories
$houseDecorTradeCategories = @{}
foreach ($categoryID in $allowedTradeCategories.Keys) {
    $category = $tradeCategoryByID[$categoryID]
    if ($category -and $category.Name_lang -eq "House Decor") { $houseDecorTradeCategories[$categoryID] = $true }
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
$expectedHouseDecorRecipeIDs = @(
    "1245993","1245994","1245995","1259673","1259675","1259681","1259690","1259715","1259724","1259778","1259784","1259796",
    "1259805","1259818","1260005","1260044","1260096","1260172","1260215","1260326","1260328","1261878","1266541","1270836"
)
$actualHouseDecorRecipeIDs = @($recipeInventory | Where-Object { $houseDecorTradeCategories.ContainsKey([string]$_.trade_category_id) } | ForEach-Object { [string]$_.recipe_spell_id } | Sort-Object -Unique)
$missingHouseDecorRecipeIDs = @($expectedHouseDecorRecipeIDs | Where-Object { $_ -notin $actualHouseDecorRecipeIDs })
$extraHouseDecorRecipeIDs = @($actualHouseDecorRecipeIDs | Where-Object { $_ -notin $expectedHouseDecorRecipeIDs })
if ($actualHouseDecorRecipeIDs.Count -ne 24 -or $missingHouseDecorRecipeIDs.Count -or $extraHouseDecorRecipeIDs.Count) {
    throw "TWW house decor recipe mismatch: missing [$($missingHouseDecorRecipeIDs -join ', ')], extra [$($extraHouseDecorRecipeIDs -join ', ')]"
}

$twwDecorRows = Read-Table $twwRoot "HouseDecor"
$twwDecorIDs = New-IDSet $twwDecorRows
$decorRowsByID = @{}
foreach ($decor in $twwDecorRows) {
    $decorRowsByID[[string]$decor.ID] = $decor
}
foreach ($sourceRow in $catalogRows) {
    $currentDecor = $currentDecorByID[[string]$sourceRow.decor_id]
    if ($currentDecor) {
        $decorRowsByID[[string]$sourceRow.decor_id] = $currentDecor
    }
}
$decorationInventory = foreach ($decor in $decorRowsByID.Values) {
    $item = $currentItems[[string]$decor.ItemID]
    if (-not $item) { $item = $items[[string]$decor.ItemID] }
    $isDNT = $decor.Name_lang -match "DNT|DO NOT USE"
    $currentExists = $currentDecorIDs.ContainsKey([string]$decor.ID)
    $catalogName = $catalogDecorNames[[string]$decor.ID]
    $catalogDetail = $catalogDetailByID[[string]$decor.ID]
    $catalogItemAudit = $catalogItemAuditByID[[string]$decor.ID]
    $auditExpansionMatch = if ($catalogItemAudit) { [regex]::Match($catalogItemAudit.acquisition_status, "^acquisition_(.+)_confirmed$") } else { $null }
    $acquisitionExpansion = if ($auditExpansionMatch -and $auditExpansionMatch.Success) {
        $auditExpansionMatch.Groups[1].Value
    } elseif ($catalogDetail) {
        Get-DecorAcquisitionExpansion $catalogDetail.source_text
    } else {
        $null
    }
    $presentInFinalTww = $twwDecorIDs.ContainsKey([string]$decor.ID)
    $status = if ($isDNT) {
        "internal_dnt"
    } elseif (-not $currentExists) {
        "removed_after_tww"
    } elseif ($catalogItemAudit -and $catalogItemAudit.acquisition_status -eq "catalog_hidden_unobtainable") {
        "catalog_hidden_unobtainable"
    } elseif ($acquisitionExpansion) {
        "acquisition_${acquisitionExpansion}_confirmed"
    } elseif ($catalogName) {
        "catalog_acquisition_unresolved"
    } else {
        "snapshot_candidate_needs_source_expansion"
    }
    [pscustomobject]@{
        status      = $status
        current_exists = $currentExists
        present_final_tww = $presentInFinalTww
        acquisition_expansion = $acquisitionExpansion
        decor_id    = $decor.ID
        item_id     = $decor.ItemID
        decor_name  = $decor.Name_lang
        catalog_name = $catalogName
        category    = if ($catalogDetail) { $catalogDetail.category } else { $null }
        source_text = if ($catalogDetail) { $catalogDetail.source_text } else { $null }
        achievement_ids = if ($catalogDetail) { $catalogDetail.achievement_ids } else { $null }
        quest_ids   = if ($catalogDetail) { $catalogDetail.quest_ids } else { $null }
        npc_ids     = if ($catalogDetail) { $catalogDetail.npc_ids } else { $null }
        spell_ids   = if ($catalogDetail) { $catalogDetail.spell_ids } else { $null }
        currency_ids = if ($catalogDetail) { $catalogDetail.currency_ids } else { $null }
        collection_spell_id = if ($catalogItemAudit) { $catalogItemAudit.collection_spell_id } else { $null }
        catalog_flags = if ($catalogItemAudit) { $catalogItemAudit.catalog_flags } else { $null }
        acquisition_note = if ($catalogItemAudit) { $catalogItemAudit.source_note } else { $null }
        acquisition_source_url = if ($catalogItemAudit) { $catalogItemAudit.source_url } else { $null }
        item_name   = if ($item) { $item.Display_lang } else { $null }
        item_expansion_id = if ($item) { $item.ExpansionID } else { $null }
        flags       = $decor.Flags
        type        = $decor.Type
        model_type  = $decor.ModelType
        weight_cost = $decor.WeightCost
    }
}

if (@($catalogRows).Count -ne 163) {
    throw "Housing catalog source row count mismatch: expected 163, got $(@($catalogRows).Count)"
}
if (@($catalogRows | Group-Object decor_id | Where-Object { $_.Count -gt 1 }).Count -gt 0) {
    throw "Housing catalog source contains duplicate decor IDs"
}
if (@($catalogDetailRows).Count -ne 169) {
    throw "Housing catalog detail row count mismatch: expected 169, got $(@($catalogDetailRows).Count)"
}
if (@($catalogDetailRows | Group-Object decor_id | Where-Object { $_.Count -gt 1 }).Count -gt 0) {
    throw "Housing catalog detail source contains duplicate decor IDs"
}
if (@($catalogItemAuditRows).Count -ne 21) {
    throw "Housing catalog item-audit row count mismatch: expected 21, got $(@($catalogItemAuditRows).Count)"
}
if (@($catalogItemAuditRows | Group-Object decor_id | Where-Object { $_.Count -gt 1 }).Count -gt 0) {
    throw "Housing catalog item-audit source contains duplicate decor IDs"
}
foreach ($sourceRow in $catalogRows) {
    $decor = $currentDecorByID[[string]$sourceRow.decor_id]
    if (-not $decor) {
        throw "Housing catalog decor $($sourceRow.decor_id) is absent from current DB2"
    }
    if ($decor.Name_lang -ne $sourceRow.catalog_name) {
        throw "Housing catalog decor $($sourceRow.decor_id) name mismatch: '$($sourceRow.catalog_name)' vs '$($decor.Name_lang)'"
    }
    $detail = $catalogDetailByID[[string]$sourceRow.decor_id]
    if (-not $detail) {
        throw "Housing catalog decor $($sourceRow.decor_id) has no acquisition-detail row"
    }
    if ($detail.catalog_name -ne $sourceRow.catalog_name) {
        throw "Housing catalog detail $($sourceRow.decor_id) name mismatch: '$($detail.catalog_name)' vs '$($sourceRow.catalog_name)'"
    }
}
foreach ($auditRow in $catalogItemAuditRows) {
    $detail = $catalogDetailByID[[string]$auditRow.decor_id]
    if (-not $detail) {
        throw "Housing catalog item audit $($auditRow.decor_id) has no detail row"
    }
    if ($detail.catalog_name -ne $auditRow.catalog_name) {
        throw "Housing catalog item audit $($auditRow.decor_id) name mismatch: '$($auditRow.catalog_name)' vs '$($detail.catalog_name)'"
    }
    if ($auditRow.acquisition_status -eq "catalog_hidden_unobtainable" -and $auditRow.catalog_flags -notmatch "\bHIDDENINCATALOG\b") {
        throw "Housing catalog item audit $($auditRow.decor_id) is excluded without HIDDENINCATALOG evidence"
    }
}

$expectedDecorStatusCounts = [ordered]@{
    acquisition_tww_confirmed                  = 108
    acquisition_dragonflight_confirmed         = 1
    acquisition_midnight_confirmed             = 33
    catalog_hidden_unobtainable                 = 14
    internal_dnt                                = 91
    removed_after_tww                           = 1
    snapshot_candidate_needs_source_expansion   = 1231
}
$actualDecorStatusCounts = @{}
foreach ($group in @($decorationInventory | Group-Object status)) {
    $actualDecorStatusCounts[$group.Name] = $group.Count
}
foreach ($expectedStatus in $expectedDecorStatusCounts.Keys) {
    $actualCount = if ($actualDecorStatusCounts.ContainsKey($expectedStatus)) { $actualDecorStatusCounts[$expectedStatus] } else { 0 }
    if ($actualCount -ne $expectedDecorStatusCounts[$expectedStatus]) {
        throw "Housing decor status '$expectedStatus' count mismatch: expected $($expectedDecorStatusCounts[$expectedStatus]), got $actualCount"
    }
}
if (@($actualDecorStatusCounts.Keys | Where-Object { -not $expectedDecorStatusCounts.Contains($_) }).Count -gt 0) {
    throw "Housing decor inventory contains an unexpected status"
}
if (@($decorationInventory | Where-Object { $_.status -eq "acquisition_tww_confirmed" -and [string]::IsNullOrWhiteSpace($_.source_text) }).Count -gt 0) {
    throw "TWW-confirmed housing decor contains a row without acquisition evidence"
}

$twwDecorationManifest = @($decorationInventory | Where-Object { $_.status -eq "acquisition_tww_confirmed" } | Sort-Object { [int]$_.decor_id })
if ($twwDecorationManifest.Count -ne 108) {
    throw "TWW decoration manifest count mismatch: expected 108, got $($twwDecorationManifest.Count)"
}
Write-CsvFile (Join-Path $ManifestRoot "decorations.csv") $twwDecorationManifest

# Freeze the exact ID sets that the addon intentionally tracks. These are
# distinct from the broad candidate inventories above: store, promotion,
# internal/test, cross-expansion preload, and known duplicate registrations
# remain available for audit without silently entering a release manifest.
$mountManifest = @($mountInventory | Where-Object { $_.release_decision -eq "include_tww" } |
    Sort-Object { [int]$_.mount_id } | Select-Object *, @{ Name = "inclusion_reason"; Expression = {
    if ($_.status -eq "guide_confirmed") { "tww_guide_confirmed" } elseif ($_.status -eq "db2_tww_signal") { "tww_db2_signal_triage_approved" } else { "tww_era_event_confirmed" }
} })

$petManifest = @($petInventory | Where-Object { $_.release_decision -eq "include_tww" } |
    Sort-Object { [int]$_.species_id } | Select-Object *, @{ Name = "inclusion_reason"; Expression = {
    if ($_.status -eq "snapshot_candidate") { "tww_era_event_triage_approved" } elseif ($_.status -eq "guide_confirmed") { "tww_guide_confirmed" } else { "tww_db2_signal_triage_approved" }
} })

$toyManifest = @($toyInventory | Where-Object { $_.release_decision -eq "include_tww" } |
    Sort-Object { [int]$_.item_id } | Select-Object *, @{ Name = "inclusion_reason"; Expression = {
    if ($_.item_id -in $toySnapshotIncludeItemIDs) { "tww_era_event_triage_approved" } elseif ($_.status -eq "item_expansion_confirmed") { "tww_item_expansion_confirmed" } else { "tww_db2_signal_triage_approved" }
} })

$recipeManifest = @($recipeInventory | Where-Object { $_.status -eq "named_recipe" } | Sort-Object profession, { [int]$_.recipe_spell_id })
$rareManifest = @($rareInventory | Sort-Object { [int]$_.achievement_id }, order_path)
$treasureManifest = @($treasureInventory | Sort-Object { [int]$_.achievement_id }, order_path)
$achievementManifest = @($achievementInventory | Where-Object { $_.status -eq "tww_category_confirmed" } | Sort-Object { [int]$_.achievement_id })
$achievementManifestIDs = @($achievementManifest | ForEach-Object { [string]$_.achievement_id })
$achievementCriteriaManifest = @(Sync-CollectionistAchievementCriteria @(
    $achievementCriteriaInventory | Where-Object { [string]$_.achievement_id -in $achievementManifestIDs }
) $currentRoot | Sort-Object { [int]$_.achievement_id }, order_path |
    Select-Object *, @{ Name = "achievement_tree_key"; Expression = { "$($_.achievement_id):$($_.tree_id)" } })

$releaseManifests = [ordered]@{
    mounts      = @{ rows = $mountManifest; expected = 186; id = "mount_id" }
    pets        = @{ rows = $petManifest; expected = 201; id = "species_id" }
    toys        = @{ rows = $toyManifest; expected = 99; id = "item_id" }
    decorations = @{ rows = $twwDecorationManifest; expected = 108; id = "decor_id" }
    recipes     = @{ rows = $recipeManifest; expected = 696; id = "recipe_spell_id" }
    achievements = @{ rows = $achievementManifest; expected = 381; id = "achievement_id" }
    "achievement-criteria" = @{ rows = $achievementCriteriaManifest; expected = 1985; id = "achievement_tree_key" }
    rares       = @{ rows = $rareManifest; expected = 140; id = "criteria_id" }
    treasures   = @{ rows = $treasureManifest; expected = 86; id = "criteria_id" }
}
$manifestSummary = foreach ($manifestName in $releaseManifests.Keys) {
    $manifest = $releaseManifests[$manifestName]
    $rows = @($manifest.rows)
    if ($rows.Count -ne $manifest.expected) {
        throw "TWW $manifestName manifest count mismatch: expected $($manifest.expected), got $($rows.Count)"
    }
    $uniqueIDs = @($rows | ForEach-Object { [string]$_.$($manifest.id) } | Where-Object { $_ } | Sort-Object -Unique)
    if ($uniqueIDs.Count -ne $rows.Count) {
        throw "TWW $manifestName manifest contains duplicate or missing $($manifest.id) values"
    }
    Write-CsvFile (Join-Path $ManifestRoot "$manifestName.csv") $rows
    [pscustomobject]@{ manifest = $manifestName; rows = $rows.Count; identifier = $manifest.id }
}
Write-CsvFile (Join-Path $ManifestRoot "summary.csv") $manifestSummary

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

Write-CsvFile (Join-Path $OutputRoot "summary.csv") $summary
$summary | Format-Table -AutoSize
