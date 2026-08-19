param(
    [string]$HistoricalRoot = (Join-Path $env:TEMP "collectionist-legion-db2\legion"),
    [string]$CurrentDb2Root = (Join-Path $env:TEMP "collectionist-df-db2\current"),
    [string]$CurrentTradeDb2Root = (Join-Path $env:TEMP "collectionist-tww-db2\current"),
    [string]$AttRoot = (Join-Path $env:TEMP "collectionist-att-12007"),
    [string]$BlizzardCaptureJson = (Join-Path $env:TEMP "collectionist-wod-blizzard-tables.json"),
    [string]$OutputRoot = (Join-Path $PSScriptRoot "..\research\collectionist\warlords-of-draenor\ids"),
    [string]$ManifestRoot = (Join-Path $PSScriptRoot "..\research\collectionist\warlords-of-draenor\manifests")
)

$ErrorActionPreference = "Stop"
$decorAuditPath = Join-Path $PSScriptRoot "..\research\collectionist\warlords-of-draenor\sources\housing-wowdb-acquisition-audit.csv"
$blizzardSourcePath = Join-Path $PSScriptRoot "..\research\collectionist\warlords-of-draenor\sources\blizzard-wod-collectibles.csv"

foreach ($required in @($HistoricalRoot, $CurrentDb2Root, $CurrentTradeDb2Root, $AttRoot, $BlizzardCaptureJson, $decorAuditPath)) {
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
    return [pscustomobject]@{ file = $Name; rows = @($Rows).Count }
}
function Assert-Equal($Actual, $Expected, [string]$Label) {
    if ([int]$Actual -ne [int]$Expected) { throw "$Label mismatch: expected $Expected, got $Actual" }
}
function Assert-UniqueField($Rows, [string]$Field, [string]$Label) {
    $duplicates = @($Rows | Group-Object $Field | Where-Object Count -gt 1)
    if ($duplicates.Count) { throw "$Label contains duplicate ${Field}: $($duplicates.Name -join ', ')" }
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

$mountByID = New-Index $mounts
$mountBySpell = New-Index $mounts "SourceSpellID"
$mountByName = @{}
foreach ($mount in $mounts) { $mountByName[$mount.Name_lang.ToLowerInvariant()] = $mount }
$petByCreature = New-Index $pets "CreatureID"
$petBySpell = New-Index $pets "SummonSpellID"
$toyByItem = New-Index $toys "ItemID"

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
$spellsByItem = @{}
foreach ($effect in $itemEffects) {
    if (-not $effect.SpellID -or $effect.SpellID -eq "0" -or -not $effect.ParentItemID -or $effect.ParentItemID -eq "0") { continue }
    if (-not $itemsBySpell.ContainsKey([string]$effect.SpellID)) { $itemsBySpell[[string]$effect.SpellID] = [System.Collections.Generic.List[string]]::new() }
    $itemsBySpell[[string]$effect.SpellID].Add([string]$effect.ParentItemID)
    if (-not $spellsByItem.ContainsKey([string]$effect.ParentItemID)) { $spellsByItem[[string]$effect.ParentItemID] = [System.Collections.Generic.List[string]]::new() }
    $spellsByItem[[string]$effect.ParentItemID].Add([string]$effect.SpellID)
}

# Blizzard's maintained Warlords guide is a current-acquisition cross-check, not
# a historical build boundary. Rows added after Legion are retained in the
# source audit but cannot enter the final-Warlords candidate set.
$officialCapture = Get-Content -Raw -LiteralPath $BlizzardCaptureJson | ConvertFrom-Json
$officialRows = @()
$officialIDs = @{ mounts = @{}; pets = @{}; toys = @{} }
foreach ($kind in @("mounts", "pets", "toys")) {
    foreach ($row in @($officialCapture.$kind)) {
        $link = @($row.links)[0]
        $href = [string]$link.href
        $sourceType = $null
        $sourceID = $null
        if ($href -match "(?:spell|npc|item)=(\d+)") {
            $sourceID = $Matches[1]
            $sourceType = ([regex]::Match($href, "(spell|npc|item)=")).Groups[1].Value
        } else { throw "Unparseable Blizzard $kind source link: $href" }

        $db2Row = $null
        if ($kind -eq "mounts") {
            if ($sourceType -eq "spell") { $db2Row = $mountBySpell[$sourceID] }
            elseif ($sourceType -eq "item") {
                foreach ($spellID in @($spellsByItem[$sourceID])) { if ($mountBySpell[$spellID]) { $db2Row = $mountBySpell[$spellID]; break } }
                if (-not $db2Row) { $db2Row = $mountByName[[string]$link.text.ToLowerInvariant()] }
            }
        } elseif ($kind -eq "pets") {
            if ($sourceType -eq "npc") { $db2Row = $petByCreature[$sourceID] }
            elseif ($sourceType -eq "item") { foreach ($spellID in @($spellsByItem[$sourceID])) { if ($petBySpell[$spellID]) { $db2Row = $petBySpell[$spellID]; break } } }
        } else { $db2Row = $toyByItem[$sourceID] }

        if ($db2Row) { $officialIDs[$kind][[string]$db2Row.ID] = $true }
        $officialRows += [pscustomobject]@{
            collectible_type = $kind.TrimEnd("s")
            source_id_type = $sourceType
            source_id = $sourceID
            final_legion_db2_id = if ($db2Row) { $db2Row.ID } else { $null }
            name = $link.text
            in_final_legion_snapshot = [bool]$db2Row
            source_text = $row.text
            source_url = $href
            guide_url = $officialCapture.url
        }
    }
}
Assert-Equal $officialRows.Count 190 "Blizzard Warlords guide row count"
Assert-Equal @($officialRows | Where-Object { $_.collectible_type -eq "mount" -and $_.in_final_legion_snapshot }).Count 45 "Blizzard mounts present in final Legion"
Assert-Equal @($officialRows | Where-Object { $_.collectible_type -eq "pet" -and $_.in_final_legion_snapshot }).Count 54 "Blizzard pets present in final Legion"
Assert-Equal @($officialRows | Where-Object { $_.collectible_type -eq "toy" -and $_.in_final_legion_snapshot }).Count 87 "Blizzard toys present in final Legion"
Write-CsvFile $blizzardSourcePath $officialRows

$wodMountIDs = @(
    "571","593","594","600","603","606","607","608","609","611","612","613","614","615","616","617","618","619","620","621","622","623","624","625","626","627","628","629","630","631","632","634","635","636","637","638","639","640","641","642","643","644","645","647","648","649","650","651","652","654","655","657","664","678","679","682","741","751","753","755","756","758","759","760","761","762","764","765","768","769","772","778","781"
)
$mountExternalIDs = @("571","593","594","600","741")
$mountUnavailableIDs = @("606","651","654","759","760","761","764")
$mountAvailabilityNotes = @{
    "606" = "WoW 10th Anniversary Molten Core reward; limited event ended"
    "651" = "Azeroth Choppers login qualification ended September 30, 2014"
    "654" = "Warlords Challenge Mode reward; Challenge Modes ended in the Legion pre-patch"
    "759" = "Warlords PvP Season 1 Gladiator reward; season ended"
    "760" = "Warlords PvP Season 2 Gladiator reward; season ended"
    "761" = "Warlords PvP Season 3 Gladiator reward; season ended"
    "764" = "Grove Warden reward; no longer obtainable after the Legion launch"
}
$mountInventory = foreach ($id in $wodMountIDs) {
    $mount = $mountByID[$id]
    if (-not $mount) { throw "Missing Warlords mount $id" }
    $itemIDs = @($itemsBySpell[[string]$mount.SourceSpellID])
    [pscustomobject]@{
        status = if ($id -in $mountExternalIDs) { "policy_external_candidate" } else { "wod_boundary_confirmed" }
        release_decision = if ($id -in $mountExternalIDs) { "exclude_policy_external" } else { "include_wod" }
        unavailable = $id -in $mountUnavailableIDs
        availability_note = $mountAvailabilityNotes[$id]
        current_exists = $currentMountIDs.ContainsKey($id)
        official_guide_match = $officialIDs.mounts.ContainsKey($id)
        mount_id = $mount.ID
        name = $mount.Name_lang
        source_spell_id = $mount.SourceSpellID
        item_ids = Join-IDs $itemIDs
        item_expansion_ids = Join-IDs @($itemIDs | ForEach-Object { $item = $items[[string]$_]; if ($item) { $item.ExpansionID } })
        source_type_enum = $mount.SourceTypeEnum
        flags = $mount.Flags
        source_text = $mount.SourceText_lang
    }
}

$petExternalIDs = @("1386","1454","1466","1602","1603","1639","1691")
$tbcPetIDs = @("1622", "1623", "1624", "1625", "1626", "1627", "1628", "1629", "1631", "1632", "1633", "1634", "1635")
$petInventory = foreach ($pet in $pets | Where-Object { [int]$_.ID -ge 1386 -and [int]$_.ID -le 1693 -and $_.SummonSpellID -ne "0" -and [int]$_.SourceTypeEnum -ge 0 }) {
    $itemIDs = @($itemsBySpell[[string]$pet.SummonSpellID])
    $creature = $creatures[[string]$pet.CreatureID]
    [pscustomobject]@{
        status = if ([string]$pet.ID -in $tbcPetIDs) { "tbc_acquisition_boundary" } elseif ([string]$pet.ID -eq "1691") { "legion_promotion_boundary" } elseif ([string]$pet.ID -in $petExternalIDs) { "policy_external_candidate" } else { "wod_boundary_confirmed" }
        release_decision = if ([string]$pet.ID -in $tbcPetIDs) { "exclude_tbc" } elseif ([string]$pet.ID -eq "1691") { "exclude_legion" } elseif ([string]$pet.ID -in $petExternalIDs) { "exclude_policy_external" } else { "include_wod" }
        current_exists = $currentPetIDs.ContainsKey([string]$pet.ID)
        official_guide_match = $officialIDs.pets.ContainsKey([string]$pet.ID)
        species_id = $pet.ID
        name = if ($creature) { $creature.Name_lang } else { $null }
        creature_id = $pet.CreatureID
        summon_spell_id = $pet.SummonSpellID
        item_ids = Join-IDs $itemIDs
        item_expansion_ids = Join-IDs @($itemIDs | ForEach-Object { $item = $items[[string]$_]; if ($item) { $item.ExpansionID } })
        pet_type_enum = $pet.PetTypeEnum
        flags = $pet.Flags
        source_type_enum = $pet.SourceTypeEnum
        source_text = $pet.SourceText_lang
    }
}

$wodAttFiles = @()
foreach ($path in @(
    (Join-Path $AttRoot ".contrib\Parser\DATAS\01 - Dungeons Raids\06 - Warlords of Draenor"),
    (Join-Path $AttRoot ".contrib\Parser\DATAS\02 - Outdoor Zones\07 Draenor"),
    (Join-Path $AttRoot ".contrib\Parser\DATAS\06 - Expansion Features\06 - Warlords of Draenor")
)) { $wodAttFiles += @(Get-ChildItem -LiteralPath $path -Recurse -File -Filter "*.lua") }
foreach ($path in @(
    (Join-Path $AttRoot ".contrib\Parser\DATAS\03 - World Drops\06 - Warlords of Draenor.lua"),
    (Join-Path $AttRoot ".contrib\Parser\DATAS\08 - PvP\06 Warlords of Draenor PvP Seasons.lua"),
    (Join-Path $AttRoot ".contrib\Parser\DATAS\09 - Crafted Items\06 - Warlords of Draenor.lua")
)) { $wodAttFiles += @(Get-Item -LiteralPath $path) }

$attWodItemIDs = [System.Collections.Generic.HashSet[string]]::new()
foreach ($file in $wodAttFiles) {
    $text = Get-Content -Raw -LiteralPath $file.FullName
    foreach ($match in [regex]::Matches($text, '(?:^|[^A-Za-z])i\((\d+)')) { [void]$attWodItemIDs.Add($match.Groups[1].Value) }
}
$toyCandidateIDs = [System.Collections.Generic.HashSet[string]]::new()
foreach ($toy in $toys) {
    if ($attWodItemIDs.Contains([string]$toy.ItemID) -or $officialIDs.toys.ContainsKey([string]$toy.ID)) { [void]$toyCandidateIDs.Add([string]$toy.ID) }
}
$toyNonWodIDs = @("139","159","160","183","184","185","186","187","502","536")
$toySourceOverrides = @{ "366" = "|cFFFFD200Vendor:|r Dawn-Seeker Krisek|n|cFFFFD200Faction:|r Order of the Awakened - Revered|n|cFFFFD200Cost:|r 50,000 Apexis Crystals" }
$toyInventory = foreach ($toy in $toys | Where-Object { $toyCandidateIDs.Contains([string]$_.ID) } | Sort-Object { [int]$_.ID }) {
    $item = $items[[string]$toy.ItemID]
    if (-not $item) { $item = $currentItems[[string]$toy.ItemID] }
    $sourceText = if ($toySourceOverrides.ContainsKey([string]$toy.ID)) { $toySourceOverrides[[string]$toy.ID] } else { $toy.SourceText_lang }
    $basis = if ($officialIDs.toys.ContainsKey([string]$toy.ID) -and $attWodItemIDs.Contains([string]$toy.ItemID)) { "blizzard_guide_and_att_wod" } elseif ($officialIDs.toys.ContainsKey([string]$toy.ID)) { "blizzard_guide" } else { "att_wod_acquisition" }
    [pscustomobject]@{
        status = if ([string]$toy.ID -in $toyNonWodIDs) { "non_wod_source_or_late_boundary" } else { "wod_acquisition_confirmed" }
        release_decision = if ([string]$toy.ID -in $toyNonWodIDs) { "exclude_non_wod" } else { "include_wod" }
        candidate_basis = $basis
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
$wodAchievementCategoryIDs = @("15220","15228","15231","15232","15235","15237","15238","15239","15240","15241","15242","15249","15250")
$achievementInventory = foreach ($achievement in $achievements | Where-Object { [string]$_.Category -in $wodAchievementCategoryIDs -or [string]$_.ID -eq "9415" }) {
    $category = $achievementCategoryByID[[string]$achievement.Category]
    $hidden = (([int64]$achievement.Flags -band 0x100000) -ne 0)
    [pscustomobject]@{
        status = if ([string]$achievement.ID -eq "9415") { "wod_decoration_acquisition_support" } elseif ($hidden) { "wod_category_hidden" } elseif (-not $currentAchievementIDs.ContainsKey([string]$achievement.ID)) { "removed_after_wod" } else { "wod_category_confirmed" }
        current_exists = $currentAchievementIDs.ContainsKey([string]$achievement.ID)
        achievement_id = $achievement.ID
        title = $achievement.Title_lang
        description = $achievement.Description_lang
        category_id = $achievement.Category
        category_name = if ($category) { $category.Name_lang } else { $null }
        criteria_tree_id = $achievement.Criteria_tree
        flags = $achievement.Flags
        points = $achievement.Points
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
    $queue = [System.Collections.Generic.Queue[object]]::new()
    $queue.Enqueue(@($RootID, ""))
    while ($queue.Count) {
        $pair = $queue.Dequeue()
        foreach ($node in @($criteriaChildren[[string]$pair[0]] | Sort-Object { [int]$_.OrderIndex })) {
            $path = if ($pair[1]) { "$($pair[1])/$($node.OrderIndex)" } else { [string]$node.OrderIndex }
            if ($node.CriteriaID -ne "0") {
                $criterion = $criteriaByID[[string]$node.CriteriaID]
                [pscustomobject]@{ order_path=$path; tree_id=$node.ID; description=$node.Description_lang; criteria_id=$node.CriteriaID; criteria_type=if($criterion){$criterion.Type}else{$null}; asset_id=if($criterion){$criterion.Asset}else{$null}; amount=$node.Amount; operator=$node.Operator }
            } else { $queue.Enqueue(@([string]$node.ID, $path)) }
        }
    }
}

$selectedAchievements = @($achievements | Where-Object { [string]$_.Category -in $wodAchievementCategoryIDs -and (([int64]$_.Flags -band 0x100000) -eq 0) -and $currentAchievementIDs.ContainsKey([string]$_.ID) })
$achievementCriteriaInventory = foreach ($achievement in $selectedAchievements | Where-Object Criteria_tree -ne "0") {
    foreach ($leaf in (Get-CriteriaLeaves ([string]$achievement.Criteria_tree))) {
        [pscustomobject]@{ achievement_id=$achievement.ID; title=$achievement.Title_lang; category_id=$achievement.Category; order_path=$leaf.order_path; tree_id=$leaf.tree_id; description=$leaf.description; criteria_id=$leaf.criteria_id; criteria_type=$leaf.criteria_type; asset_id=$leaf.asset_id; amount=$leaf.amount; operator=$leaf.operator }
    }
}

$achievementByID = New-Index $achievements
function Get-EncounterRows($Specs, [string]$Kind) {
    foreach ($spec in $Specs) {
        $achievement = $achievementByID[[string]$spec.id]
        if (-not $achievement) { throw "Missing $Kind achievement $($spec.id)" }
        foreach ($leaf in (Get-CriteriaLeaves ([string]$achievement.Criteria_tree))) {
            [pscustomobject]@{
                achievement_id = $achievement.ID
                achievement = $achievement.Title_lang
                order_path = $leaf.order_path
                tree_id = $leaf.tree_id
                criterion = $leaf.description
                criteria_id = $leaf.criteria_id
                criteria_type = $leaf.criteria_type
                criteria_asset = $leaf.asset_id
                npc_id = if ($Kind -eq "rare" -and $leaf.criteria_type -eq "0") { $leaf.asset_id } else { $null }
                completion_quest_id = if ($Kind -eq "treasure" -and $leaf.criteria_type -eq "27") { $leaf.asset_id } else { $null }
                selection_decision = $spec.decision
            }
        }
    }
}
$rareSpecs = @(
    [pscustomobject]@{id="9400";decision="include_wod"},
    [pscustomobject]@{id="10061";decision="include_wod"},
    [pscustomobject]@{id="10070";decision="include_wod"},
    [pscustomobject]@{id="10259";decision="exclude_partial_duplicate"}
)
$treasureSpecs = @(
    [pscustomobject]@{id="9548";decision="include_wod"},
    [pscustomobject]@{id="9726";decision="exclude_threshold_duplicate"},
    [pscustomobject]@{id="9727";decision="exclude_threshold_duplicate"},
    [pscustomobject]@{id="9728";decision="include_wod"},
    [pscustomobject]@{id="10348";decision="exclude_threshold_duplicate"},
    [pscustomobject]@{id="10261";decision="exclude_partial_duplicate"},
    [pscustomobject]@{id="10262";decision="include_wod"}
)
$rareInventory = @(Get-EncounterRows $rareSpecs "rare")
$treasureInventory = @(Get-EncounterRows $treasureSpecs "treasure")

$tradeCategoryChildren = @{}
foreach ($category in $tradeSkillCategories) {
    if (-not $tradeCategoryChildren.ContainsKey([string]$category.ParentTradeSkillCategoryID)) { $tradeCategoryChildren[[string]$category.ParentTradeSkillCategoryID] = [System.Collections.Generic.List[string]]::new() }
    $tradeCategoryChildren[[string]$category.ParentTradeSkillCategoryID].Add([string]$category.ID)
}
$wodTradeRoots = @("332","389","342","348","347","410","373","380","369")
$allowedTradeCategories = @{}
$tradeQueue = [System.Collections.Generic.Queue[string]]::new()
foreach ($rootID in $wodTradeRoots) { $tradeQueue.Enqueue($rootID) }
while ($tradeQueue.Count) {
    $categoryID = $tradeQueue.Dequeue()
    if ($allowedTradeCategories.ContainsKey($categoryID)) { continue }
    $allowedTradeCategories[$categoryID] = $true
    foreach ($childID in @($tradeCategoryChildren[$categoryID])) { $tradeQueue.Enqueue($childID) }
}
$professionNames = @{ "171"="Alchemy"; "164"="Blacksmithing"; "185"="Cooking"; "333"="Enchanting"; "202"="Engineering"; "773"="Inscription"; "755"="Jewelcrafting"; "165"="Leatherworking"; "197"="Tailoring" }
$spellByID = New-Index $spells
$historicalRecipeInventory = foreach ($ability in $skillLineAbilities | Where-Object { $allowedTradeCategories.ContainsKey([string]$_.TradeSkillCategoryID) -and $professionNames.ContainsKey([string]$_.SkillLine) }) {
    $spell = $spellByID[[string]$ability.Spell]
    $currentAbility = $currentRecipeSpellIDs.ContainsKey([string]$ability.Spell)
    $currentName = $currentSpellNameIDs.ContainsKey([string]$ability.Spell)
    [pscustomobject]@{
        status = if (-not $spell -or -not $spell.Name_lang) { "unnamed_db2_ability_candidate" } elseif (-not $currentAbility -or -not $currentName) { "removed_after_wod" } else { "current_named_recipe" }
        current_ability_exists = $currentAbility
        current_spell_name_exists = $currentName
        profession = $professionNames[[string]$ability.SkillLine]
        profession_id = $ability.SkillLine
        recipe_spell_id = $ability.Spell
        name = if ($spell) { $spell.Name_lang } else { $null }
        skill_line_ability_id = $ability.ID
        trade_category_id = $ability.TradeSkillCategoryID
        acquire_method = $ability.AcquireMethod
        supercedes_spell_id = $ability.SupercedesSpell
    }
}

# Housing launched after Warlords, but its recipes are taught by the Draenor
# profession tiers. Import only the explicit current House Decor categories;
# other modern additions beneath these old trees are not part of this boundary.
$currentTradeChildren = @{}
$currentTradeCategoryByID = New-Index $currentTradeSkillCategories
foreach ($category in $currentTradeSkillCategories) {
    if (-not $currentTradeChildren.ContainsKey([string]$category.ParentTradeSkillCategoryID)) { $currentTradeChildren[[string]$category.ParentTradeSkillCategoryID] = [System.Collections.Generic.List[string]]::new() }
    $currentTradeChildren[[string]$category.ParentTradeSkillCategoryID].Add([string]$category.ID)
}
$currentAllowedTradeCategories = @{}
$currentTradeQueue = [System.Collections.Generic.Queue[string]]::new()
foreach ($rootID in $wodTradeRoots) { $currentTradeQueue.Enqueue($rootID) }
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
    if ($historicalRecipeIDs.ContainsKey([string]$ability.Spell)) { throw "Draenor house decor recipe $($ability.Spell) duplicates the historical inventory" }
    $spell = $currentTradeSpellNames[[string]$ability.Spell]
    if (-not $spell -or -not $spell.Name_lang) { throw "Draenor house decor recipe $($ability.Spell) has no current spell name" }
    [pscustomobject]@{
        status = "current_house_decor_recipe"
        current_ability_exists = $true
        current_spell_name_exists = $true
        profession = $professionNames[[string]$ability.SkillLine]
        profession_id = $ability.SkillLine
        recipe_spell_id = $ability.Spell
        name = $spell.Name_lang
        skill_line_ability_id = $ability.ID
        trade_category_id = $ability.TradeSkillCategoryID
        acquire_method = $ability.AcquireMethod
        supercedes_spell_id = $ability.SupercedesSpell
    }
}
$recipeInventory = @($historicalRecipeInventory) + @($houseDecorRecipeInventory)

$decorAuditRows = @(Import-Csv -LiteralPath $decorAuditPath)
$decorationInventory = foreach ($audit in $decorAuditRows) {
    $decor = $currentDecorByID[[string]$audit.decor_id]
    if (-not $decor) { throw "Housing decor $($audit.decor_id) is absent from current DB2" }
    if ($decor.Name_lang.Trim() -ne $audit.catalog_name.Trim()) { throw "Housing decor $($audit.decor_id) name mismatch" }
    $item = $currentItems[[string]$decor.ItemID]
    [pscustomobject]@{
        status=$audit.status; candidate_basis="live_catalog_acquisition_audit"; acquisition_expansion=$audit.acquisition_expansion; catalog_scope=$audit.catalog_scope
        decor_id=$decor.ID; item_id=$decor.ItemID; decor_name=$decor.Name_lang.Trim(); source_text=$audit.source_text
        achievement_ids=$audit.achievement_ids; quest_ids=$audit.quest_ids; npc_ids=$audit.npc_ids; source_spell_ids=$audit.source_spell_ids
        currency_ids=$audit.currency_ids; source_item_ids=$audit.source_item_ids; classification_note=$audit.classification_note; acquisition_source_url=$audit.acquisition_source_url
        item_name=if($item){$item.Display_lang}else{$null}; item_expansion_id=if($item){$item.ExpansionID}else{$null}; flags=$decor.Flags; type=$decor.Type; model_type=$decor.ModelType; weight_cost=$decor.WeightCost
    }
}

$mapByID = New-Index $currentMapRows
$mapIDs = @("572","525","534","535","539","542","543","550","588")
$mapInventory = @($mapIDs | ForEach-Object { $map=$mapByID[$_]; if(-not$map){throw "Missing Warlords map $_"}; [pscustomobject]@{status="primary_map_confirmed";current_exists=$true;map_id=$map.ID;name=$map.Name_lang;parent_map_id=$map.ParentUiMapID;system=$map.System;type=$map.Type;flags=$map.Flags} })
$factionByID = New-Index $factions
$factionIDs = @("1358","1445","1515","1681","1682","1708","1710","1711","1731","1733","1736","1737","1738","1739","1740","1741","1847","1848","1849","1850")
$factionInventory = @($factionIDs | ForEach-Object { $faction=$factionByID[$_]; if(-not$faction){throw "Missing Warlords faction $_"}; [pscustomobject]@{status="wod_collectible_requirement";current_exists=$currentFactionIDs.ContainsKey([string]$faction.ID);faction_id=$faction.ID;name=$faction.Name_lang;parent_faction_id=$faction.ParentFactionID;friendship_rep_id=$faction.FriendshipRepID;flags=$faction.Flags} })
$historicalCurrencyByID = New-Index $currencies
$currentCurrencyByID = New-Index $currentCurrencyRows
$currencyIDs = @("810","821","823","824","828","829","910","944","980","994","999","1008","1017","1020","1101","1129","1191")
$currencyInventory = @($currencyIDs | ForEach-Object { $currency=$historicalCurrencyByID[$_];if(-not$currency){$currency=$currentCurrencyByID[$_]};if(-not$currency){throw "Missing Warlords currency $_"};[pscustomobject]@{status="wod_collectible_requirement";current_exists=$currentCurrencyIDs.ContainsKey([string]$currency.ID);currency_id=$currency.ID;name=$currency.Name_lang;description=$currency.Description_lang;category_id=$currency.CategoryID;faction_id=$currency.FactionID;max_quantity=$currency.MaxQty;flags=$currency.Flags} })

$mountManifest = @($mountInventory | Where-Object release_decision -eq "include_wod" | Sort-Object { [int]$_.mount_id })
$petManifest = @($petInventory | Where-Object release_decision -eq "include_wod" | Sort-Object { [int]$_.species_id })
$toyManifest = @($toyInventory | Where-Object release_decision -eq "include_wod" | Sort-Object { [int]$_.toy_id })
$achievementManifest = @($achievementInventory | Where-Object status -eq "wod_category_confirmed" | Sort-Object { [int]$_.achievement_id })
$achievementManifestIDs = @($achievementManifest.achievement_id)
$achievementCriteriaManifest = @($achievementCriteriaInventory | Where-Object { [string]$_.achievement_id -in $achievementManifestIDs } | Sort-Object { [int]$_.achievement_id }, { Get-OrderPathSortKey $_.order_path })
$recipeManifest = @($recipeInventory | Where-Object status -in @("current_named_recipe", "current_house_decor_recipe") | Sort-Object profession, { [int]$_.recipe_spell_id })
$rareManifest = @($rareInventory | Where-Object selection_decision -eq "include_wod" | Sort-Object { [int]$_.achievement_id }, { Get-OrderPathSortKey $_.order_path })
$treasureManifest = @($treasureInventory | Where-Object selection_decision -eq "include_wod" | Sort-Object { [int]$_.achievement_id }, { Get-OrderPathSortKey $_.order_path })

Assert-Equal $mountInventory.Count 73 "Warlords mount candidate count"
Assert-Equal $mountManifest.Count 68 "Selected Warlords mount count"
Assert-Equal $petInventory.Count 104 "Warlords pet candidate count"
Assert-Equal $petManifest.Count 84 "Selected Warlords pet count"
Assert-Equal $toyInventory.Count 101 "Warlords toy candidate count"
Assert-Equal $toyManifest.Count 91 "Selected Warlords toy count"
Assert-Equal $achievementInventory.Count 415 "Warlords achievement audit count"
Assert-Equal $achievementManifest.Count 402 "Visible Warlords achievement count"
Assert-Equal $achievementCriteriaInventory.Count 3036 "Warlords achievement criteria count"
Assert-Equal $historicalRecipeInventory.Count 353 "Historical Warlords recipe count"
Assert-Equal $houseDecorRecipeInventory.Count 21 "Current Draenor house decor recipe count"
Assert-Equal $recipeInventory.Count 374 "Warlords recipe audit count"
Assert-Equal $recipeManifest.Count 337 "Current Warlords recipe count"
Assert-Equal $decorationInventory.Count 80 "Warlords decoration count"
Assert-Equal $rareInventory.Count 132 "Warlords rare candidate criteria count"
Assert-Equal $rareManifest.Count 72 "Selected Warlords rare criteria count"
Assert-Equal $treasureInventory.Count 1350 "Warlords treasure candidate criteria count"
Assert-Equal $treasureManifest.Count 368 "Selected Warlords treasure criteria count"
Assert-Equal $mapInventory.Count 9 "Warlords map count"
Assert-Equal $factionInventory.Count 20 "Warlords faction count"
Assert-Equal $currencyInventory.Count 17 "Warlords currency count"
Assert-Equal @($mountManifest | Where-Object { -not $_.current_exists }).Count 0 "Selected mounts missing from current retail"
Assert-Equal @($petManifest | Where-Object { -not $_.current_exists }).Count 0 "Selected pets missing from current retail"
Assert-Equal @($toyManifest | Where-Object { -not $_.current_exists }).Count 0 "Selected toys missing from current retail"
Assert-Equal @($achievementManifest | Where-Object { -not $_.current_exists }).Count 0 "Selected achievements missing from current retail"
Assert-Equal @($toyManifest | Where-Object { -not $_.source_text }).Count 0 "Selected toys with blank source text"
Assert-Equal @($rareManifest | Where-Object { -not $_.npc_id }).Count 0 "Selected rare criteria without NPC IDs"
Assert-Equal @($treasureManifest | Where-Object { -not $_.completion_quest_id }).Count 0 "Selected treasure criteria without quest IDs"
Assert-Equal @($mapInventory | Where-Object { -not $_.current_exists }).Count 0 "Selected maps missing from current retail"
Assert-Equal @($factionInventory | Where-Object { -not $_.current_exists }).Count 0 "Selected factions missing from current retail"
Assert-Equal @($currencyInventory | Where-Object { -not $_.current_exists }).Count 0 "Selected currencies missing from current retail"
foreach ($spec in @(
    @($mountInventory,"mount_id","Mount"),@($petInventory,"species_id","Pet"),@($toyInventory,"toy_id","Toy"),@($achievementInventory,"achievement_id","Achievement"),
    @($achievementCriteriaInventory,"tree_id","Achievement criteria"),@($recipeInventory,"recipe_spell_id","Recipe"),@($decorationInventory,"decor_id","Decoration")
)) { Assert-UniqueField $spec[0] $spec[1] $spec[2] }

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

$manifestRows = [ordered]@{
    mounts=$mountManifest; pets=$petManifest; toys=$toyManifest; decorations=@($decorationInventory | Sort-Object { [int]$_.decor_id });
    achievements=$achievementManifest; "achievement-criteria"=$achievementCriteriaManifest; recipes=$recipeManifest; rares=$rareManifest; treasures=$treasureManifest
}
foreach ($name in $manifestRows.Keys) { Write-CsvFile (Join-Path $ManifestRoot "$name.csv") $manifestRows[$name] }
Write-CsvFile (Join-Path $ManifestRoot "supporting-currencies.csv") $currencyInventory
Write-CsvFile (Join-Path $ManifestRoot "supporting-factions.csv") $factionInventory
Write-CsvFile (Join-Path $ManifestRoot "supporting-maps.csv") $mapInventory

$identifierFields = @{mounts="mount_id";pets="species_id";toys="toy_id";decorations="decor_id";achievements="achievement_id";"achievement-criteria"="tree_id";recipes="recipe_spell_id";rares="tree_id";treasures="tree_id"}
$manifestSummary = @($manifestRows.Keys | ForEach-Object { [pscustomobject]@{manifest=$_;rows=@($manifestRows[$_]).Count;identifier=$identifierFields[$_]} })
$manifestSummary += [pscustomobject]@{manifest="supporting-currencies";rows=$currencyInventory.Count;identifier="currency_id"}
$manifestSummary += [pscustomobject]@{manifest="supporting-factions";rows=$factionInventory.Count;identifier="faction_id"}
$manifestSummary += [pscustomobject]@{manifest="supporting-maps";rows=$mapInventory.Count;identifier="map_id"}
Write-CsvFile (Join-Path $ManifestRoot "summary.csv") $manifestSummary

$summary | Format-Table -AutoSize
Write-Host "Generated Collectionist Warlords of Draenor ID inventory and release manifests"
