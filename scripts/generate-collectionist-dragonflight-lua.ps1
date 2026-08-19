param(
    [string]$ManifestRoot = (Join-Path $PSScriptRoot "..\research\collectionist\dragonflight\manifests"),
    [string]$AddonRoot = (Join-Path $PSScriptRoot "..\addons\Collectionist")
)

$ErrorActionPreference = "Stop"

function Read-Manifest([string]$name) {
    $path = Join-Path $ManifestRoot "$name.csv"
    if (-not (Test-Path -LiteralPath $path)) { throw "Missing manifest: $path" }
    return @(Import-Csv -LiteralPath $path)
}

function ConvertTo-LuaString($value) {
    $text = [string]$value
    $text = $text.Replace("\", "\\").Replace('"', '\"')
    $text = $text.Replace("`r`n", "\n").Replace("`r", "\n").Replace("`n", "\n")
    return '"' + $text + '"'
}

function Write-LuaFile([string]$relativePath, $lines) {
    $path = Join-Path $AddonRoot $relativePath
    $text = (@($lines) -join "`n") + "`n"
    [System.IO.File]::WriteAllText($path, $text, [System.Text.UTF8Encoding]::new($false))
}

function First-ID($value) {
    return @(([string]$value -split ";") | Where-Object { $_ })[0]
}

function Get-OrderPathSortKey([string]$path) {
    return ((@($path -split "/") | ForEach-Object { "{0:D8}" -f [int]$_ }) -join "/")
}

function Get-SourceKey([string]$text, [string]$catalog) {
    if ($text -match "World Event|Holiday|Remix|Keg Leg's Crew|A Greedy Emissary|Hearthstone Anniversary|Secrets of Azeroth|Anniversary") {
        return $(if ($catalog -eq "pets") { "event" } else { "worldevent" })
    }
    if ($text -match "Faction:|Renown:|Reputation:") {
        return $(if ($catalog -eq "pets") { "vendor" } else { "renown" })
    }
    if ($text -match "Achievement:") { return "achievement" }
    if ($text -match "Quest:|World Quest:") { return "quest" }
    if ($text -match "Treasure:") { return "treasure" }
    if ($text -match "Profession|Crafting:") { return $(if ($catalog -eq "pets") { "profession" } else { "profession" }) }
    if ($text -match "PvP:|Gladiator:") { return $(if ($catalog -eq "mounts") { "pvp" } else { "achievement" }) }
    if ($text -match "Raid:|Zone:.*Vault of the Incarnates|Zone:.*Aberrus|Zone:.*Amirdrassil") {
        return $(if ($catalog -eq "mounts" -or $catalog -eq "toys") { "raid" } else { "drop" })
    }
    if ($text -match "Dungeon:") { return $(if ($catalog -eq "mounts" -or $catalog -eq "toys") { "dungeon" } else { "drop" }) }
    if ($text -match "Vendor:") { return "vendor" }
    if ($text -match "Drop:|Pet Battle:") { return $(if ($text -match "Pet Battle:") { "wild" } else { "drop" }) }
    return "drop"
}

function Get-ProfessionExpression([string]$text) {
    foreach ($name in @("Alchemy", "Blacksmithing", "Cooking", "Enchanting", "Engineering", "Inscription", "Jewelcrafting", "Leatherworking", "Tailoring")) {
        if ($text -match [regex]::Escape($name)) { return "MC.PROFESSION.$name" }
    }
    return $null
}

function Add-GroupedEntries($lines, $rows, [string]$catalog, [string]$listKey, [scriptblock]$entryBuilder) {
    $orderedSources = @("renown", "reputation", "wild", "drop", "achievement", "quest", "treasure", "dungeon", "raid", "pvp", "profession", "vendor", "worldevent", "event")
    $groups = @{}
    foreach ($row in $rows) {
        $source = Get-SourceKey ([string]$row.source_text) $catalog
        if (-not $groups.ContainsKey($source)) { $groups[$source] = [System.Collections.Generic.List[object]]::new() }
        $groups[$source].Add($row)
    }
    foreach ($source in $orderedSources) {
        if (-not $groups.ContainsKey($source)) { continue }
        $lines.Add("    { source = $(ConvertTo-LuaString $source), $listKey = {")
        foreach ($row in @($groups[$source])) {
            $lines.Add((& $entryBuilder $row $source))
        }
        $lines.Add("    } },")
    }
}

# Mounts --------------------------------------------------------------------
$mounts = Read-Manifest "mounts"
$unavailableMountIDs = @(
    "994", "1259", "1660", "1681", "1725", "1739", "1801", "1822", "1831",
    "1959", "2055", "2090", "2091"
)
$mountLines = [System.Collections.Generic.List[string]]::new()
$mountLines.Add("local _, MC = ...")
$mountLines.Add("")
$mountLines.Add("-- Dragonflight mounts. Generated from the exact 161-row release manifest.")
$mountLines.Add('MC.RegisterContent("df", "mounts", {')
Add-GroupedEntries $mountLines $mounts "mounts" "mounts" {
    param($row, $source)
    $parts = [System.Collections.Generic.List[string]]::new()
    $parts.Add("mountID = $($row.mount_id)")
    $itemID = First-ID $row.item_ids
    if ($itemID) { $parts.Add("itemID = $itemID") }
    $parts.Add("name = $(ConvertTo-LuaString $row.name)")
    $parts.Add("source = $(ConvertTo-LuaString $source)")
    $info = if ([string]::IsNullOrWhiteSpace($row.source_text)) { "Source details unavailable in the final Dragonflight snapshot" } else { $row.source_text }
    $parts.Add("sourceInfo = $(ConvertTo-LuaString $info)")
    if ($row.source_text -match "Remix" -or [string]$row.mount_id -in $unavailableMountIDs) {
        $parts.Add("unavailable = true")
    }
    return "        { $($parts -join ', ') },"
}
$mountLines.Add("})")
Write-LuaFile "Modules\Mounts\Data\Dragonflight.lua" $mountLines

# Pets ----------------------------------------------------------------------
$pets = Read-Manifest "pets"
$unavailablePetIDs = @("4265", "4425", "4426", "4435", "4579", "4580")
$petLines = [System.Collections.Generic.List[string]]::new()
$petLines.Add("local _, MC = ...")
$petLines.Add("")
$petLines.Add("-- Dragonflight battle pets. Generated from the exact 164-row release manifest.")
$petLines.Add('MC.RegisterContent("df", "pets", {')
Add-GroupedEntries $petLines $pets "pets" "pets" {
    param($row, $source)
    $parts = [System.Collections.Generic.List[string]]::new()
    $parts.Add("speciesID = $($row.species_id)")
    $itemID = First-ID $row.item_ids
    if ($itemID) { $parts.Add("itemID = $itemID") }
    if ($row.creature_id) { $parts.Add("npcID = $($row.creature_id)") }
    $parts.Add("name = $(ConvertTo-LuaString $row.name)")
    $parts.Add("petType = $([int]$row.pet_type_enum + 1)")
    $parts.Add("source = $(ConvertTo-LuaString $source)")
    $info = if ([string]::IsNullOrWhiteSpace($row.source_text)) { "Source details unavailable in the final Dragonflight snapshot" } else { $row.source_text }
    $parts.Add("sourceInfo = $(ConvertTo-LuaString $info)")
    if ([string]$row.species_id -in $unavailablePetIDs) { $parts.Add("unavailable = true") }
    return "        { $($parts -join ', ') },"
}
$petLines.Add("})")
Write-LuaFile "Modules\Pets\Data\Dragonflight.lua" $petLines

# Toys ----------------------------------------------------------------------
$toys = Read-Manifest "toys"
$unavailableToyIDs = @("1330", "1331", "1333", "1434", "1448", "1450", "1456", "1464")
$toyLines = [System.Collections.Generic.List[string]]::new()
$toyLines.Add("local _, MC = ...")
$toyLines.Add("")
$toyLines.Add("-- Dragonflight toys. Generated from the exact 172-row release manifest.")
$toyLines.Add('MC.RegisterContent("df", "toys", {')
Add-GroupedEntries $toyLines $toys "toys" "toys" {
    param($row, $source)
    $parts = [System.Collections.Generic.List[string]]::new()
    $parts.Add("itemID = $($row.item_id)")
    $parts.Add("name = $(ConvertTo-LuaString $row.name)")
    $parts.Add("source = $(ConvertTo-LuaString $source)")
    $info = if ([string]::IsNullOrWhiteSpace($row.source_text)) { "Source details unavailable in the final Dragonflight snapshot" } else { $row.source_text }
    $parts.Add("sourceInfo = $(ConvertTo-LuaString $info)")
    if ([string]$row.toy_id -in $unavailableToyIDs) { $parts.Add("unavailable = true") }
    return "        { $($parts -join ', ') },"
}
$toyLines.Add("})")
Write-LuaFile "Modules\Toys\Data\Dragonflight.lua" $toyLines

# Decorations ---------------------------------------------------------------
$decorations = Read-Manifest "decorations"
$decorLines = [System.Collections.Generic.List[string]]::new()
$decorLines.Add("local _, MC = ...")
$decorLines.Add("")
$decorLines.Add("-- Dragonflight-acquisition housing decor. Generated from the exact 76-row manifest.")
$decorLines.Add('MC.RegisterContent("df", "decorations", {')
$decorGroups = $decorations | Group-Object {
    if ($_.spell_ids) { "crafted" } elseif ($_.achievement_ids) { "achievement" } elseif ($_.quest_ids) { "quest" } elseif ($_.currency_ids -or $_.npc_ids) { "vendor" } else { "drop" }
}
$decorOrder = @("crafted", "vendor", "quest", "achievement", "drop")
foreach ($source in $decorOrder) {
    $group = $decorGroups | Where-Object Name -eq $source
    if (-not $group) { continue }
    $decorLines.Add("    { source = $(ConvertTo-LuaString $source), decorations = {")
    foreach ($row in $group.Group | Sort-Object { [int]$_.decor_id }) {
        $parts = [System.Collections.Generic.List[string]]::new()
        $parts.Add("decorID = $($row.decor_id)")
        $parts.Add("itemID = $($row.item_id)")
        $parts.Add("name = $(ConvertTo-LuaString $row.decor_name)")
        $parts.Add("source = $(ConvertTo-LuaString $source)")
        $parts.Add("sourceInfo = $(ConvertTo-LuaString $row.source_text)")
        $profession = Get-ProfessionExpression $row.source_text
        if ($profession) { $parts.Add("skillLine = $profession") }
        $achievementID = First-ID $row.achievement_ids
        if ($achievementID) { $parts.Add("achievementID = $achievementID") }
        $questID = First-ID $row.quest_ids
        if ($questID) { $parts.Add("questID = $questID") }
        $decorLines.Add("        { $($parts -join ', ') },")
    }
    $decorLines.Add("    } },")
}
$decorLines.Add("})")
Write-LuaFile "Modules\Decorations\Data\Dragonflight.lua" $decorLines

# Achievements --------------------------------------------------------------
$achievements = Read-Manifest "achievements"
$criteria = Read-Manifest "achievement-criteria"
$criteriaByAchievement = @{}
foreach ($row in $criteria) {
    $id = [string]$row.achievement_id
    if (-not $criteriaByAchievement.ContainsKey($id)) { $criteriaByAchievement[$id] = [System.Collections.Generic.List[object]]::new() }
    $criteriaByAchievement[$id].Add($row)
}
$achievementGroups = @{
    "15455" = @("quests", "metas", "Dragonflight")
    "15462" = @("features", "dragonriding", "Dragonriding")
    "15465" = @("exploration", "zone", "Dragon Isles")
    "15466" = @("features", "reputation", "Dragonflight Features")
    "15467" = @("features", "dungeons", "Dragonflight Dungeons")
    "15468" = @("features", "raid", "Dragonflight Raids")
    "15478" = @("collections", "mounts", "Dragonriding Cosmetics")
}
$achievementLines = [System.Collections.Generic.List[string]]::new()
$achievementLines.Add("local _, MC = ...")
$achievementLines.Add("")
$achievementLines.Add("-- Dragonflight player-facing achievements. Exact 569-row manifest;")
$achievementLines.Add("-- stable criteria tasks are attached only for 2-30-row progress lists.")
$achievementLines.Add('MC.RegisterContent("df", "achievements", {')
foreach ($categoryID in @("15455", "15462", "15465", "15466", "15467", "15468", "15478")) {
    $meta = $achievementGroups[$categoryID]
    $achievementLines.Add("    { category = $(ConvertTo-LuaString $meta[0]), source = $(ConvertTo-LuaString $meta[1]), achievements = {")
    foreach ($row in $achievements | Where-Object category_id -eq $categoryID | Sort-Object { [int]$_.achievement_id }) {
        $prefix = "        { achievementID = $($row.achievement_id), name = $(ConvertTo-LuaString $row.title), description = $(ConvertTo-LuaString $row.description), zone = $(ConvertTo-LuaString $meta[2])"
        $tasks = @($criteriaByAchievement[[string]$row.achievement_id])
        if ($tasks.Count -ge 2 -and $tasks.Count -le 30) {
            $achievementLines.Add($prefix + ",")
            $achievementLines.Add('          taskList = { intro = "Progress from live achievement criteria.", tasks = {')
            foreach ($task in $tasks) {
                $label = if ($task.description) { ", label = $(ConvertTo-LuaString $task.description)" } else { "" }
                $achievementLines.Add("              { achievementID = $($row.achievement_id), criteriaID = $($task.criteria_id)$label },")
            }
            $achievementLines.Add("          } } },")
        } else {
            $achievementLines.Add($prefix + " },")
        }
    }
    $achievementLines.Add("    } },")
}
$achievementLines.Add("})")
Write-LuaFile "Modules\Achievements\Data\Dragonflight.lua" $achievementLines

# Recipes -------------------------------------------------------------------
$recipes = Read-Manifest "recipes"
$recipeLines = [System.Collections.Generic.List[string]]::new()
$recipeLines.Add("local _, MC = ...")
$recipeLines.Add("")
$recipeLines.Add("-- Dragonflight-acquisition profession recipes. Generated from the exact $($recipes.Count)-spell manifest.")
$recipeLines.Add('MC.RegisterContent("df", "recipes", {')
foreach ($group in $recipes | Group-Object profession | Sort-Object Name) {
    $first = $group.Group[0]
    $recipeLines.Add("    { skillLine = $($first.profession_id), name = `"Dragonflight`", recipes = {")
    foreach ($row in $group.Group | Sort-Object { [int]$_.recipe_spell_id }) {
        if ($row.status -eq "acquisition_dragonflight_ancient_zulgurub") {
            $recipeLines.Add("        { id = $($row.recipe_spell_id), name = $(ConvertTo-LuaString $row.name), source = `"drop`", sourceInfo = `"Gurubashi Tribute in Zul'Gurub (Dragonflight 10.0.7)`" },")
        } elseif ($row.acquire_method -eq "1") {
            $recipeLines.Add("        { id = $($row.recipe_spell_id), name = $(ConvertTo-LuaString $row.name), source = `"trainer`", sourceInfo = `"Learned automatically`", priority = 1 },")
        } else {
            $recipeLines.Add("        { id = $($row.recipe_spell_id), name = $(ConvertTo-LuaString $row.name), source = `"unknown`" },")
        }
    }
    $recipeLines.Add("    } },")
}
$recipeLines.Add("})")
Write-LuaFile "Modules\Recipes\Data\Dragonflight.lua" $recipeLines

# Rares ---------------------------------------------------------------------
$rares = Read-Manifest "rares"
$rareMap = @{
    "16676" = @("waking_shores", "Waking Shores", "MC.MAP.WakingShores")
    "16677" = @("ohnahran_plains", "Ohn'ahran Plains", "MC.MAP.OhnahranPlains")
    "16678" = @("azure_span", "The Azure Span", "MC.MAP.AzureSpan")
    "16679" = @("thaldraszus", "Thaldraszus", "MC.MAP.Thaldraszus")
    "17524" = @("forbidden_reach", "The Forbidden Reach", "MC.MAP.ForbiddenReach")
    "17783" = @("zaralek_cavern", "Zaralek Cavern", "MC.MAP.ZaralekCavern")
    "19316" = @("emerald_dream", "Emerald Dream", "MC.MAP.EmeraldDream")
}
$rareLines = [System.Collections.Generic.List[string]]::new()
$rareLines.Add("local addonName, MC = ...")
$rareLines.Add("")
$rareLines.Add("-- Dragonflight zone rares. Exact 197 ordered criteria/NPC rows.")
$rareLines.Add('MC.RegisterContent("df", "rares", {')
foreach ($achievementID in @("16676", "16677", "16678", "16679", "17524", "17783", "19316")) {
    $meta = $rareMap[$achievementID]
    $rows = @($rares | Where-Object achievement_id -eq $achievementID | Sort-Object { Get-OrderPathSortKey $_.order_path })
    $ids = @($rows | ForEach-Object { First-ID $_.npc_ids })
    $treeIDs = @($rows | ForEach-Object { $_.tree_id })
    $rareLines.Add("    { source = $(ConvertTo-LuaString $meta[0]), achievementID = $achievementID, criteriaCount = $($rows.Count),")
    $rareLines.Add("      criteriaTreeIDs = { $($treeIDs -join ', ') },")
    $rareLines.Add("      criteriaNPCIDs = { $($ids -join ', ') }, name = $(ConvertTo-LuaString $rows[0].achievement),")
    $rareLines.Add("      zoneMapID = $($meta[2]), zone = $(ConvertTo-LuaString $meta[1]) },")
}
$rareLines.Add("})")
$rareLines.Add("")
$rareLines.Add("local SOURCE_KEYS = {")
foreach ($achievementID in @("16676", "16677", "16678", "16679", "17524", "17783", "19316")) {
    $meta = $rareMap[$achievementID]
    $rareLines.Add("    { $(ConvertTo-LuaString $meta[0]), $(ConvertTo-LuaString $meta[1]) },")
}
$rareLines.Add("}")
$rareLines.Add("local function merge()")
$rareLines.Add("    MC.RareSourceOrder = MC.RareSourceOrder or {}")
$rareLines.Add("    MC.RareSourceLabels = MC.RareSourceLabels or {}")
$rareLines.Add("    for i, pair in ipairs(SOURCE_KEYS) do table.insert(MC.RareSourceOrder, i, pair[1]); MC.RareSourceLabels[pair[1]] = pair[2] end")
$rareLines.Add("end")
$rareLines.Add("if MC.RareSourceOrder then merge() else")
$rareLines.Add('    local frame = CreateFrame("Frame"); frame:RegisterEvent("ADDON_LOADED")')
$rareLines.Add('    frame:SetScript("OnEvent", function(self, _, name) if name ~= addonName then return end; self:UnregisterEvent("ADDON_LOADED"); self:SetScript("OnEvent", nil); merge() end)')
$rareLines.Add("end")
Write-LuaFile "Modules\Rares\Data\Dragonflight.lua" $rareLines

# Treasures -----------------------------------------------------------------
$treasures = Read-Manifest "treasures"
$treasureLines = [System.Collections.Generic.List[string]]::new()
$treasureLines.Add("local addonName, MC = ...")
$treasureLines.Add("")
$treasureLines.Add("-- Dragonflight zone treasures. Exact 57 ordered criteria rows.")
$treasureLines.Add('MC.RegisterContent("df", "treasures", {')
foreach ($achievementID in @("16297", "16299", "16300", "16301", "17526", "17786", "19317")) {
    $rareID = @{ "16297"="16676"; "16299"="16677"; "16300"="16678"; "16301"="16679"; "17526"="17524"; "17786"="17783"; "19317"="19316" }[$achievementID]
    $meta = $rareMap[$rareID]
    $rows = @($treasures | Where-Object achievement_id -eq $achievementID | Sort-Object { Get-OrderPathSortKey $_.order_path })
    $names = @($rows | ForEach-Object { ConvertTo-LuaString $_.treasure })
    $treeIDs = @($rows | ForEach-Object { $_.tree_id })
    $treasureLines.Add("    { source = $(ConvertTo-LuaString $meta[0]), achievementID = $achievementID, criteriaCount = $($rows.Count),")
    $treasureLines.Add("      criteriaTreeIDs = { $($treeIDs -join ', ') },")
    $treasureLines.Add("      criteriaNames = { $($names -join ', ') }, name = $(ConvertTo-LuaString $rows[0].achievement),")
    $treasureLines.Add("      zoneMapID = $($meta[2]), zone = $(ConvertTo-LuaString $meta[1]) },")
}
$treasureLines.Add("})")
$treasureLines.Add("")
$treasureLines.Add("local SOURCE_KEYS = {")
foreach ($achievementID in @("16676", "16677", "16678", "16679", "17524", "17783", "19316")) {
    $meta = $rareMap[$achievementID]
    $treasureLines.Add("    { $(ConvertTo-LuaString $meta[0]), $(ConvertTo-LuaString $meta[1]) },")
}
$treasureLines.Add("}")
$treasureLines.Add("local function merge()")
$treasureLines.Add("    MC.TreasureSourceOrder = MC.TreasureSourceOrder or {}")
$treasureLines.Add("    MC.TreasureSourceLabels = MC.TreasureSourceLabels or {}")
$treasureLines.Add("    for i, pair in ipairs(SOURCE_KEYS) do table.insert(MC.TreasureSourceOrder, i, pair[1]); MC.TreasureSourceLabels[pair[1]] = pair[2] end")
$treasureLines.Add("end")
$treasureLines.Add("if MC.TreasureSourceOrder then merge() else")
$treasureLines.Add('    local frame = CreateFrame("Frame"); frame:RegisterEvent("ADDON_LOADED")')
$treasureLines.Add('    frame:SetScript("OnEvent", function(self, _, name) if name ~= addonName then return end; self:UnregisterEvent("ADDON_LOADED"); self:SetScript("OnEvent", nil); merge() end)')
$treasureLines.Add("end")
Write-LuaFile "Modules\Treasures\Data\Dragonflight.lua" $treasureLines

Write-Host "Generated Dragonflight Lua data files"
