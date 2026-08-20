param(
    [string]$HistoricalRoot = (Join-Path $env:TEMP "collectionist-legion-db2\legion"),
    [string]$CurrentDb2Root = (Join-Path $env:TEMP "collectionist-df-db2\current"),
    [string]$CurrentTradeDb2Root = (Join-Path $env:TEMP "collectionist-tww-db2\current"),
    [string]$AttRoot = (Join-Path $env:TEMP "collectionist-att-12007"),
    [string]$OutputRoot = (Join-Path $PSScriptRoot "..\research\collectionist\legion\ids"),
    [string]$ManifestRoot = (Join-Path $PSScriptRoot "..\research\collectionist\legion\manifests")
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "collectionist-wild-pet-rules.ps1")
$decorAuditPath = Join-Path $PSScriptRoot "..\research\collectionist\legion\sources\housing-wowdb-acquisition-audit.csv"
$rareNPCAuditPath = Join-Path $PSScriptRoot "..\research\collectionist\legion\sources\rare-npc-audit.csv"
$attZonePath = Join-Path $AttRoot "db\Standard\Categories\Zones.lua"

foreach ($required in @($HistoricalRoot, $CurrentDb2Root, $CurrentTradeDb2Root, $decorAuditPath, $attZonePath)) {
    if (-not (Test-Path -LiteralPath $required)) { throw "Missing input: $required" }
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
function Join-IDs($values) { return (@($values | Where-Object { $_ } | Sort-Object -Unique) -join ";") }
function Get-OrderPathSortKey([string]$path) {
    return ((@($path -split "/") | ForEach-Object { "{0:D8}" -f [int]$_ }) -join "/")
}
function Write-CsvFile([string]$path, $rows) {
    $lines = @($rows) | ConvertTo-Csv -NoTypeInformation
    $text = if ($lines.Count) { ($lines -join "`n") + "`n" } else { "" }
    [System.IO.File]::WriteAllText($path, $text.Replace("`r`n", "`n").Replace("`r", "`n"), [System.Text.UTF8Encoding]::new($false))
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

$mounts = Read-Table $HistoricalRoot "Mount"
$pets = Read-Table $HistoricalRoot "BattlePetSpecies"
$toys = Read-Table $HistoricalRoot "Toy"
$achievements = Read-Table $HistoricalRoot "Achievement"
$achievementCategories = Read-Table $HistoricalRoot "Achievement_Category"
$criteriaRows = Read-Table $HistoricalRoot "Criteria"
$criteriaTreeRows = Read-Table $HistoricalRoot "CriteriaTree"
$tradeSkillCategories = Read-Table $HistoricalRoot "TradeSkillCategory"
$skillLineAbilities = Read-Table $HistoricalRoot "SkillLineAbility"
$spells = Read-Table $HistoricalRoot "Spell"
$currencies = Read-Table $HistoricalRoot "CurrencyTypes"
$factions = Read-Table $HistoricalRoot "Faction"
$items = New-Index (Read-Table $HistoricalRoot "ItemSparse")
$creatures = New-Index (Read-Table $HistoricalRoot "Creature")
$itemEffects = Read-Table $HistoricalRoot "ItemEffect"

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
$currentMapRows = Read-Table $CurrentDb2Root "UiMap"
$currentMapIDs = New-IDSet $currentMapRows
$currentItems = New-Index (Read-Table $CurrentDb2Root "ItemSparse")
$currentDecorByID = New-Index (Read-Table $CurrentDb2Root "HouseDecor")

$itemsBySpell = @{}
foreach ($effect in $itemEffects) {
    if (-not $effect.SpellID -or $effect.SpellID -eq "0" -or -not $effect.ParentItemID -or $effect.ParentItemID -eq "0") { continue }
    $spellID = [string]$effect.SpellID
    if (-not $itemsBySpell.ContainsKey($spellID)) { $itemsBySpell[$spellID] = [System.Collections.Generic.List[string]]::new() }
    $itemsBySpell[$spellID].Add([string]$effect.ParentItemID)
}

# The final Warlords DB2 export is unavailable. The final Legion snapshot therefore uses
# a reviewed lower boundary plus explicit late-Warlords exclusions.
$wodMountIDs = @("657", "664", "678", "679", "682", "741", "751", "753", "755", "756", "758", "759", "760", "761", "762", "764", "765", "768", "769", "772", "778", "781")
$mountExternalIDs = @("763", "776", "896", "934", "949", "959", "960")
$legionGladiatorMountIDs = @("848", "849", "850", "851", "852", "853", "948")
$legionUnavailableMountIDs = @($legionGladiatorMountIDs + @("878", "978"))
$mountInventory = foreach ($mount in $mounts | Where-Object { [int]$_.ID -ge 656 }) {
    $itemIDs = @($itemsBySpell[[string]$mount.SourceSpellID])
    $itemExpansionIDs = @($itemIDs | ForEach-Object { $item = $items[[string]$_]; if ($item) { $item.ExpansionID } })
    [pscustomobject]@{
        status = if ([string]$mount.ID -in $wodMountIDs) { "late_wod_boundary" } elseif ([string]$mount.ID -in $mountExternalIDs) { "policy_external_candidate" } else { "legion_snapshot_candidate" }
        release_decision = if ([string]$mount.ID -in $wodMountIDs) { "exclude_wod" } elseif ([string]$mount.ID -in $mountExternalIDs) { "exclude_policy_external" } else { "include_legion" }
        unavailable = [string]$mount.ID -in $legionUnavailableMountIDs
        availability_note = if ([string]$mount.ID -in $legionGladiatorMountIDs) { "Legion Gladiator season reward; season ended" } elseif ([string]$mount.ID -eq "878") { "Legion Brawler's Guild rank reward; Brawler's Guild is unavailable" } elseif ([string]$mount.ID -eq "978") { "Antorus Ahead of the Curve quest reward; removed after Legion" } else { $null }
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

$petExternalIDs = @("1828", "1936", "1939", "1940", "2051", "2062")
$petInternalIDs = @("1757", "1758", "2046", "2048")
$mopPetIDs = @("2017", "2018")
$cataPetIDs = @("2078", "2079", "2082", "2083", "2085", "2086", "2087", "2089", "2090")
$wrathPetIDs = @("1727", "1952", "1953", "1954", "1955", "1956", "1957", "1958", "1959", "1960", "1961", "1962", "1963", "1964", "1965", "1966", "1967", "1968", "1969")
$petUnavailableIDs = @("1889", "2022")
$petInventory = foreach ($pet in $pets | Where-Object {
    [int]$_.ID -ge 1699 -and [int]$_.SourceTypeEnum -ge 0 -and
    ($_.SummonSpellID -ne "0" -or (Test-CollectionistCollectibleWildPet $_))
}) {
    $itemIDs = @($itemsBySpell[[string]$pet.SummonSpellID])
    $itemExpansionIDs = @($itemIDs | ForEach-Object { $item = $items[[string]$_]; if ($item) { $item.ExpansionID } })
    $creature = $creatures[[string]$pet.CreatureID]
    $collectibleWild = Test-CollectionistCollectibleWildPet $pet
    [pscustomobject]@{
        status = if ($collectibleWild) { "collectible_wild_pet_shared_audit" } elseif ([string]$pet.ID -in $wrathPetIDs) { "wrath_acquisition_boundary" } elseif ([string]$pet.ID -in $cataPetIDs) { "cataclysm_acquisition_boundary" } elseif ([string]$pet.ID -in $mopPetIDs) { "mop_acquisition_boundary" } elseif ([string]$pet.ID -in $petExternalIDs) { "policy_external_candidate" } elseif ([string]$pet.ID -in $petInternalIDs) { "unobtainable_or_internal" } else { "legion_snapshot_candidate" }
        release_decision = if ($collectibleWild) { "exclude_shared_wild_audit" } elseif ([string]$pet.ID -in $wrathPetIDs) { "exclude_wrath" } elseif ([string]$pet.ID -in $cataPetIDs) { "exclude_cataclysm" } elseif ([string]$pet.ID -in $mopPetIDs) { "exclude_mop" } elseif ([string]$pet.ID -in $petExternalIDs) { "exclude_policy_external" } elseif ([string]$pet.ID -in $petInternalIDs) { "exclude_unobtainable_or_internal" } else { "include_legion" }
        unavailable = [string]$pet.ID -in $petUnavailableIDs
        availability_note = if ([string]$pet.ID -eq "1889") { "Legion pre-launch invasion event reward; event ended" } elseif ([string]$pet.ID -eq "2022") { "Legion Brawler's Guild rank reward; Brawler's Guild is unavailable" } else { $null }
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

$toyExternalIDs = @("448", "471")
$toyInternalIDs = @("438", "443", "512", "567", "591", "603")
$wodToyIDs = @("449", "458", "459", "460", "461", "466", "469", "475", "479", "492", "493", "494", "495", "496", "499", "500", "542", "573")
$mopToyIDs = @("442", "451", "452", "453", "454", "456", "457", "462", "463", "464", "467", "468", "470", "486", "497", "498", "619", "633")
$cataToyIDs = @("444", "445", "455", "473", "484", "488", "490", "491")
$wrathToyIDs = @("465", "472", "476", "477", "514", "515", "607")
$tbcToyIDs = @("436", "481", "483", "487", "489", "501", "502", "528", "529", "530", "539", "640", "646")
$classicToyIDs = @("480", "482", "582")
$toySourceOverrides = @{
    "521" = "|cFFFFD200Vendor:|r Lorelae Wintersong|n|cFFFFD200Zone:|r Moonglade"
    "522" = "|cFFFFD200Vendor:|r Endora Moorehead|n|cFFFFD200Zone:|r Dalaran"
    "525" = "|cFFFFD200Vendor:|r Cravitz Lorent|n|cFFFFD200Zone:|r Dalaran Underbelly"
    "526" = "|cFFFFD200Vendor:|r Outfitter Reynolds / Mardan Thunderhoof|n|cFFFFD200Class:|r Hunter"
    "527" = "|cFFFFD200Vendor:|r Quartermaster Miranda Breechlock|n|cFFFFD200Zone:|r Eastern Plaguelands"
    "528" = "|cFFFFD200Vendor:|r Elementalist Sharvak / Flamesmith Lanying|n|cFFFFD200Class:|r Shaman"
    "529" = "|cFFFFD200Vendor:|r Elementalist Sharvak / Flamesmith Lanying|n|cFFFFD200Class:|r Shaman"
    "530" = "|cFFFFD200Vendor:|r Elementalist Sharvak / Flamesmith Lanying|n|cFFFFD200Class:|r Shaman"
    "539" = "|cFFFFD200Vendor:|r Elementalist Sharvak / Flamesmith Lanying|n|cFFFFD200Class:|r Shaman"
}
$toyInventory = foreach ($toy in $toys | Where-Object { $_.ID -eq "410" -or [int]$_.ID -ge 434 }) {
    $item = $items[[string]$toy.ItemID]
    if (-not $item) { $item = $currentItems[[string]$toy.ItemID] }
    $sourceText = if ($toySourceOverrides.ContainsKey([string]$toy.ID)) { $toySourceOverrides[[string]$toy.ID] } else { $toy.SourceText_lang }
    [pscustomobject]@{
        status = if ([string]$toy.ID -in $classicToyIDs) { "classic_acquisition_boundary" } elseif ([string]$toy.ID -in $tbcToyIDs) { "tbc_acquisition_boundary" } elseif ([string]$toy.ID -in $wrathToyIDs) { "wrath_acquisition_boundary" } elseif ([string]$toy.ID -in $cataToyIDs) { "cataclysm_acquisition_boundary" } elseif ([string]$toy.ID -in $mopToyIDs) { "mop_acquisition_boundary" } elseif ([string]$toy.ID -in $wodToyIDs) { "wod_acquisition_boundary" } elseif ([string]$toy.ID -in $toyExternalIDs) { "policy_external_candidate" } elseif ([string]$toy.ID -in $toyInternalIDs) { "unobtainable_or_internal" } else { "legion_snapshot_candidate" }
        release_decision = if ([string]$toy.ID -in $classicToyIDs) { "exclude_classic" } elseif ([string]$toy.ID -in $tbcToyIDs) { "exclude_tbc" } elseif ([string]$toy.ID -in $wrathToyIDs) { "exclude_wrath" } elseif ([string]$toy.ID -in $cataToyIDs) { "exclude_cataclysm" } elseif ([string]$toy.ID -in $mopToyIDs) { "exclude_mop" } elseif ([string]$toy.ID -in $wodToyIDs) { "exclude_wod" } elseif ([string]$toy.ID -in $toyExternalIDs) { "exclude_policy_external" } elseif ([string]$toy.ID -in $toyInternalIDs) { "exclude_unobtainable_or_internal" } else { "include_legion" }
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

$achievementCategoryByID = New-Index $achievementCategories
$legionAchievementCategoryIDs = @("15252", "15254", "15255", "15256", "15257", "15258", "15275", "15276")
$achievementInventory = foreach ($achievement in $achievements) {
    $category = $achievementCategoryByID[[string]$achievement.Category]
    $isLegionCategory = [string]$achievement.Category -in $legionAchievementCategoryIDs
    $isHidden = (([int64]$achievement.Flags -band 0x100000) -ne 0)
    [pscustomobject]@{
        status = if ($achievement.Title_lang -match "DNT|DO NOT USE") { "internal_dnt" } elseif (-not $currentAchievementIDs.ContainsKey([string]$achievement.ID)) { "removed_after_legion" } elseif ($isLegionCategory -and $isHidden) { "legion_category_hidden" } elseif ($isLegionCategory) { "legion_category_confirmed" } else { "snapshot_non_legion_category" }
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

$criteriaByID = New-Index $criteriaRows
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

$selectedAchievements = @($achievements | Where-Object { [string]$_.Category -in $legionAchievementCategoryIDs -and (([int64]$_.Flags -band 0x100000) -eq 0) -and $currentAchievementIDs.ContainsKey([string]$_.ID) })
$achievementCriteriaInventory = foreach ($achievement in $selectedAchievements | Where-Object Criteria_tree -ne "0") {
    foreach ($leaf in (Get-CriteriaLeaves ([string]$achievement.Criteria_tree))) {
        [pscustomobject]@{ achievement_id = $achievement.ID; title = $achievement.Title_lang; category_id = $achievement.Category; order_path = $leaf.order_path; tree_id = $leaf.tree_id; description = $leaf.description; criteria_id = $leaf.criteria_id; criteria_type = $leaf.criteria_type; asset_id = $leaf.asset_id; amount = $leaf.amount; operator = $leaf.operator }
    }
}

$achievementByID = New-Index $achievements
$attEntityByCriteriaID = @{}
$attZoneText = Get-Content -LiteralPath $attZonePath -Raw
foreach ($match in [regex]::Matches($attZoneText, '(?ms)^(n|o)\((\d+),\{(?:(?!^(?:n|o)\().)*')) {
    $entityType = if ($match.Groups[1].Value -eq "n") { "npc" } else { "object" }
    $candidate = [pscustomobject]@{ type = $entityType; id = $match.Groups[2].Value }
    foreach ($criteriaMatch in [regex]::Matches($match.Value, '\bcrit\((\d+)')) {
        $criteriaID = $criteriaMatch.Groups[1].Value
        if ($attEntityByCriteriaID.ContainsKey($criteriaID)) {
            $existing = $attEntityByCriteriaID[$criteriaID]
            if ($existing -and ($existing.type -ne $candidate.type -or $existing.id -ne $candidate.id)) { $attEntityByCriteriaID[$criteriaID] = $null }
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
            [pscustomobject]@{ achievement_id = $achievement.ID; achievement = $achievement.Title_lang; order_path = $leaf.order_path; tree_id = $leaf.tree_id; criterion = $leaf.description; criteria_id = $leaf.criteria_id; criteria_type = $leaf.criteria_type; criteria_asset = $leaf.asset_id; npc_ids = $npcID; object_ids = $objectID; entity_mapping = $mapping; selection_decision = "include_legion" }
        }
    }
}
$rareAchievementIDs = @("11261", "11262", "11263", "11264", "11265", "12078")
$treasureAchievementIDs = @("11256", "11257", "11258", "11259", "11260", "12074")
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
$legionTradeRoots = @("426", "430", "433", "443", "450", "460", "464", "469", "475")
$allowedTradeCategories = @{}
$tradeQueue = [System.Collections.Generic.Queue[string]]::new()
foreach ($rootID in $legionTradeRoots) { $tradeQueue.Enqueue($rootID) }
while ($tradeQueue.Count) {
    $categoryID = $tradeQueue.Dequeue()
    if ($allowedTradeCategories.ContainsKey($categoryID)) { continue }
    $allowedTradeCategories[$categoryID] = $true
    foreach ($childID in @($tradeCategoryChildren[$categoryID])) { $tradeQueue.Enqueue($childID) }
}
$professionNames = @{ "171" = "Alchemy"; "164" = "Blacksmithing"; "185" = "Cooking"; "333" = "Enchanting"; "202" = "Engineering"; "773" = "Inscription"; "755" = "Jewelcrafting"; "165" = "Leatherworking"; "197" = "Tailoring" }
$spellByID = New-Index $spells
$historicalRecipeInventory = foreach ($ability in $skillLineAbilities | Where-Object { $allowedTradeCategories.ContainsKey([string]$_.TradeSkillCategoryID) -and $professionNames.ContainsKey([string]$_.SkillLine) }) {
    $spell = $spellByID[[string]$ability.Spell]
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
foreach ($rootID in $legionTradeRoots) { $currentTradeQueue.Enqueue($rootID) }
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
    if ($historicalRecipeIDs.ContainsKey([string]$ability.Spell)) { throw "Legion house decor recipe $($ability.Spell) duplicates the historical inventory" }
    $spell = $currentTradeSpellNames[[string]$ability.Spell]
    if (-not $spell -or -not $spell.Name_lang) { throw "Legion house decor recipe $($ability.Spell) has no current spell name" }
    [pscustomobject]@{ status = "current_house_decor_recipe"; current_ability_exists = $true; current_spell_name_exists = $true; profession = $professionNames[[string]$ability.SkillLine]; profession_id = $ability.SkillLine; recipe_spell_id = $ability.Spell; name = $spell.Name_lang; skill_line_ability_id = $ability.ID; trade_category_id = $ability.TradeSkillCategoryID; acquire_method = $ability.AcquireMethod; supercedes_spell_id = $ability.SupercedesSpell }
}
$recipeInventory = @($historicalRecipeInventory) + @($houseDecorRecipeInventory)

$decorAuditRows = @(Import-Csv -LiteralPath $decorAuditPath)
$decorationInventory = foreach ($audit in $decorAuditRows) {
    $decor = $currentDecorByID[[string]$audit.decor_id]
    if (-not $decor) { throw "Housing decor $($audit.decor_id) is absent from current DB2" }
    if ($decor.Name_lang.Trim() -ne $audit.catalog_name.Trim()) { throw "Housing decor $($audit.decor_id) name mismatch" }
    $item = $currentItems[[string]$decor.ItemID]
    [pscustomobject]@{ status = $audit.status; candidate_basis = "live_catalog_acquisition_audit"; acquisition_expansion = $audit.acquisition_expansion; catalog_scope = $audit.catalog_scope; decor_id = $decor.ID; item_id = $decor.ItemID; decor_name = $decor.Name_lang.Trim(); source_text = $audit.source_text; achievement_ids = $audit.achievement_ids; quest_ids = $audit.quest_ids; npc_ids = $audit.npc_ids; spell_ids = $audit.spell_ids; currency_ids = $audit.currency_ids; source_item_ids = $audit.item_ids; classification_note = $audit.classification_note; acquisition_source_url = $audit.acquisition_source_url; item_name = if ($item) { $item.Display_lang } else { $null }; item_expansion_id = if ($item) { $item.ExpansionID } else { $null }; flags = $decor.Flags; type = $decor.Type; model_type = $decor.ModelType; weight_cost = $decor.WeightCost }
}

$mapIDs = @("627", "630", "634", "641", "646", "650", "680", "830", "882", "885", "905")
$mapByID = New-Index $currentMapRows
$mapInventory = @($mapIDs | ForEach-Object { $map = $mapByID[[string]$_]; if (-not $map) { throw "Missing Legion map $_" }; [pscustomobject]@{ status = "primary_map_confirmed"; current_exists = $true; map_id = $map.ID; name = $map.Name_lang; parent_map_id = $map.ParentUiMapID; system = $map.System; type = $map.Type; flags = $map.Flags } })
$factionIDs = @("1828", "1859", "1883", "1894", "1900", "1948", "1975", "2018", "2045", "2097", "2098", "2099", "2100", "2101", "2102", "2135", "2165", "2170")
$factionByID = New-Index $factions
$factionInventory = @($factionIDs | ForEach-Object { $faction = $factionByID[[string]$_]; if (-not $faction) { throw "Missing Legion faction $_" }; [pscustomobject]@{ status = "legion_collectible_requirement"; current_exists = $currentFactionIDs.ContainsKey([string]$faction.ID); faction_id = $faction.ID; name = $faction.Name_lang; parent_faction_id = $faction.ParentFactionID; friendship_rep_id = $faction.FriendshipRepID; flags = $faction.Flags } })
$currencyInventory = @($currencies | ForEach-Object { [pscustomobject]@{ current_exists = $currentCurrencyIDs.ContainsKey([string]$_.ID); currency_id = $_.ID; name = $_.Name_lang; description = $_.Description_lang; category_id = $_.CategoryID; faction_id = $_.FactionID; max_quantity = $_.MaxQty; flags = $_.Flags } })

Assert-Equal @($mountInventory).Count 153 "Legion mount boundary row count"
Assert-Equal @($mountInventory | Where-Object release_decision -eq "include_legion").Count 124 "Selected Legion mount count"
Assert-Equal @($petInventory).Count 195 "Legion collectible pet boundary row count"
Assert-Equal @($petInventory | Where-Object release_decision -eq "include_legion").Count 106 "Selected Legion pet count"
Assert-Equal @($toyInventory).Count 229 "Legion toy boundary row count"
Assert-Equal @($toyInventory | Where-Object release_decision -eq "include_legion").Count 154 "Selected Legion toy count"
Assert-Equal @($mountInventory | Where-Object { $_.release_decision -eq "include_legion" -and $_.unavailable }).Count 9 "Unavailable Legion mount count"
Assert-Equal @($petInventory | Where-Object { $_.release_decision -eq "include_legion" -and $_.unavailable }).Count 2 "Unavailable Legion pet count"
Assert-Equal @($selectedAchievements).Count 305 "Visible Legion achievement count"
Assert-Equal @($achievementCriteriaInventory).Count 2411 "Legion achievement criteria count"
Assert-Equal @($historicalRecipeInventory | Where-Object status -eq "named_recipe").Count 750 "Historical named Legion recipe count"
Assert-Equal @($houseDecorRecipeInventory).Count 23 "Current Legion house decor recipe count"
Assert-Equal @($recipeInventory | Where-Object status -in @("named_recipe", "current_house_decor_recipe")).Count 773 "Named Legion recipe count"
Assert-Equal @($decorationInventory).Count 211 "Legion-owned decoration count"
Assert-Equal @($rareInventory).Count 185 "Legion rare criteria count"
Assert-Equal @($treasureInventory).Count 314 "Legion treasure criteria count"
Assert-Equal @($rareInventory | Where-Object { -not $_.npc_ids -and -not $_.object_ids }).Count 0 "Rare criteria without entity IDs"
Assert-Equal @($rareInventory | Where-Object object_ids).Count 7 "Rare object-provider count"
Assert-Equal @($rareNPCAudit).Count 105 "Quest-style rare audit count"
Assert-Equal @($mountInventory | Where-Object { $_.release_decision -eq "include_legion" -and -not $_.source_text }).Count 0 "Selected mounts with blank sources"
Assert-Equal @($petInventory | Where-Object { $_.release_decision -eq "include_legion" -and -not $_.source_text }).Count 0 "Selected pets with blank sources"
Assert-Equal @($toyInventory | Where-Object { $_.release_decision -eq "include_legion" -and -not $_.source_text }).Count 0 "Selected toys with blank sources"
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

$manifestRows = @{
    "mounts" = @($mountInventory | Where-Object release_decision -eq "include_legion" | Sort-Object { [int]$_.mount_id })
    "pets" = @($petInventory | Where-Object release_decision -eq "include_legion" | Sort-Object { [int]$_.species_id })
    "toys" = @($toyInventory | Where-Object release_decision -eq "include_legion" | Sort-Object { [int]$_.toy_id })
    "decorations" = @($decorationInventory | Sort-Object { [int]$_.decor_id })
    "achievements" = @($achievementInventory | Where-Object status -eq "legion_category_confirmed" | Sort-Object { [int]$_.achievement_id })
    "achievement-criteria" = @($achievementCriteriaInventory | Sort-Object { [int]$_.achievement_id }, { Get-OrderPathSortKey $_.order_path })
    "recipes" = @($recipeInventory | Where-Object status -in @("named_recipe", "current_house_decor_recipe") | Sort-Object profession, { [int]$_.recipe_spell_id })
    "rares" = @($rareInventory | Sort-Object { [int]$_.achievement_id }, { Get-OrderPathSortKey $_.order_path })
    "treasures" = @($treasureInventory | Sort-Object { [int]$_.achievement_id }, { Get-OrderPathSortKey $_.order_path })
}
foreach ($name in @("mounts", "pets", "toys", "decorations", "achievements", "achievement-criteria", "recipes", "rares", "treasures")) { Write-CsvFile (Join-Path $ManifestRoot "$name.csv") $manifestRows[$name] }

$supportingCurrencyIDs = @("1149", "1154", "1155", "1166", "1220", "1226", "1275", "1299", "1342", "1379", "1416", "1508")
$historicalCurrencyByID = New-Index $currencies
$currentCurrencyByID = New-Index $currentCurrencyRows
$supportingCurrencyManifest = @($supportingCurrencyIDs | ForEach-Object {
    $currency = $historicalCurrencyByID[[string]$_]; $source = "historical_collectible_source"
    if (-not $currency) { $currency = $currentCurrencyByID[[string]$_]; $source = "current_decoration_acquisition" }
    if (-not $currency) { throw "Missing supporting currency $_" }
    [pscustomobject]@{ current_exists = $currentCurrencyIDs.ContainsKey([string]$currency.ID); currency_id = $currency.ID; name = $currency.Name_lang; description = $currency.Description_lang; category_id = $currency.CategoryID; faction_id = $currency.FactionID; max_quantity = $currency.MaxQty; source = $source }
})
$supportingFactionManifest = @($factionInventory | ForEach-Object { [pscustomobject]@{ current_exists = $_.current_exists; faction_id = $_.faction_id; name = $_.name; parent_faction_id = $_.parent_faction_id; friendship_rep_id = $_.friendship_rep_id; flags = $_.flags; source = "selected_collectible_or_achievement_requirement" } })
$supportingMapManifest = @($mapInventory | ForEach-Object { [pscustomobject]@{ current_exists = $_.current_exists; map_id = $_.map_id; name = $_.name; parent_map_id = $_.parent_map_id; system = $_.system; type = $_.type; flags = $_.flags; source = "selected_primary_zone" } })
Write-CsvFile (Join-Path $ManifestRoot "supporting-currencies.csv") $supportingCurrencyManifest
Write-CsvFile (Join-Path $ManifestRoot "supporting-factions.csv") $supportingFactionManifest
Write-CsvFile (Join-Path $ManifestRoot "supporting-maps.csv") $supportingMapManifest

$identifierFields = @{ "mounts" = "mount_id"; "pets" = "species_id"; "toys" = "toy_id"; "decorations" = "decor_id"; "achievements" = "achievement_id"; "achievement-criteria" = "tree_id"; "recipes" = "recipe_spell_id"; "rares" = "tree_id"; "treasures" = "tree_id" }
$manifestSummary = @()
foreach ($name in @("mounts", "pets", "toys", "decorations", "achievements", "achievement-criteria", "recipes", "rares", "treasures")) { $manifestSummary += [pscustomobject]@{ manifest = $name; rows = @($manifestRows[$name]).Count; identifier = $identifierFields[$name] } }
$manifestSummary += [pscustomobject]@{ manifest = "supporting-currencies"; rows = $supportingCurrencyManifest.Count; identifier = "currency_id" }
$manifestSummary += [pscustomobject]@{ manifest = "supporting-factions"; rows = $supportingFactionManifest.Count; identifier = "faction_id" }
$manifestSummary += [pscustomobject]@{ manifest = "supporting-maps"; rows = $supportingMapManifest.Count; identifier = "map_id" }
Write-CsvFile (Join-Path $ManifestRoot "summary.csv") $manifestSummary
$summary | Format-Table -AutoSize
Write-Host "Generated Collectionist Legion ID inventory and release manifests"
