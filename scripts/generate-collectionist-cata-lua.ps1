param(
    [string]$ManifestRoot = (Join-Path $PSScriptRoot "..\research\collectionist\cataclysm\manifests"),
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
function First-ID($value) { return @(([string]$value -split ";") | Where-Object { $_ })[0] }
function Get-OrderPathSortKey([string]$path) {
    return ((@($path -split "/") | ForEach-Object { "{0:D8}" -f [int]$_ }) -join "/")
}
function Get-SourceKey([string]$sourceText, [string]$catalog) {
    if ($sourceText -match "World Event|Holiday|Anniversary|Feast of Winter Veil") { return $(if ($catalog -eq "pets") { "event" } else { "worldevent" }) }
    if ($sourceText -match "PvP:|Gladiator:") { return $(if ($catalog -eq "mounts") { "pvp" } else { "achievement" }) }
    if ($sourceText -match "Faction:|Reputation:") { return $(if ($catalog -eq "pets") { "vendor" } else { "reputation" }) }
    if ($sourceText -match "Achievement:") { return "achievement" }
    if ($sourceText -match "Quest:|World Quest:|Garrison Mission") { return "quest" }
    if ($sourceText -match "Treasure:|Secret:") { return "treasure" }
    if ($sourceText -match "Profession|Crafting:") { return "profession" }
    if ($sourceText -match "Raid:") { return $(if ($catalog -eq "mounts" -or $catalog -eq "toys") { "raid" } else { "drop" }) }
    if ($sourceText -match "Dungeon:") { return $(if ($catalog -eq "mounts" -or $catalog -eq "toys") { "dungeon" } else { "drop" }) }
    if ($sourceText -match "Vendor:|Paragon Cache:") { return "vendor" }
    if ($sourceText -match "Drop:|Pet Battle:") { return $(if ($sourceText -match "Pet Battle:") { "wild" } else { "drop" }) }
    return "drop"
}
function Get-ProfessionExpression([string]$text) {
    foreach ($name in @("Alchemy", "Blacksmithing", "Cooking", "Enchanting", "Engineering", "Inscription", "Jewelcrafting", "Leatherworking", "Tailoring")) {
        if ($text -match [regex]::Escape($name)) { return "MC.PROFESSION.$name" }
    }
    return $null
}
function Add-GroupedEntries($lines, $rows, [string]$catalog, [string]$listKey, [scriptblock]$entryBuilder) {
    $orderedSources = @("reputation", "wild", "drop", "achievement", "quest", "treasure", "dungeon", "raid", "pvp", "profession", "vendor", "worldevent", "event")
    $groups = @{}
    foreach ($row in $rows) {
        $source = Get-SourceKey ([string]$row.source_text) $catalog
        if (-not $groups.ContainsKey($source)) { $groups[$source] = [System.Collections.Generic.List[object]]::new() }
        $groups[$source].Add($row)
    }
    foreach ($source in $orderedSources) {
        if (-not $groups.ContainsKey($source)) { continue }
        $lines.Add("    { source = $(ConvertTo-LuaString $source), $listKey = {")
        foreach ($row in @($groups[$source])) { $lines.Add((& $entryBuilder $row $source)) }
        $lines.Add("    } },")
    }
}

$mounts = Read-Manifest "mounts"
$mountLines = [System.Collections.Generic.List[string]]::new()
$mountLines.Add("local _, MC = ...")
$mountLines.Add("")
$mountLines.Add("-- Cataclysm mounts. Generated from the exact $($mounts.Count)-row release manifest.")
$mountLines.Add('MC.RegisterContent("cata", "mounts", {')
Add-GroupedEntries $mountLines $mounts "mounts" "mounts" {
    param($row, $source)
    $parts = [System.Collections.Generic.List[string]]::new()
    $parts.Add("mountID = $($row.mount_id)")
    $itemID = First-ID $row.item_ids; if ($itemID) { $parts.Add("itemID = $itemID") }
    $parts.Add("name = $(ConvertTo-LuaString $row.name)")
    $parts.Add("source = $(ConvertTo-LuaString $source)")
    $parts.Add("sourceInfo = $(ConvertTo-LuaString $row.source_text)")
    if ([string]$row.unavailable -eq "True") { $parts.Add("unavailable = true") }
    return "        { $($parts -join ', ') },"
}
$mountLines.Add("})")
Write-LuaFile "Modules\Mounts\Data\Cataclysm.lua" $mountLines

$pets = Read-Manifest "pets"
$petLines = [System.Collections.Generic.List[string]]::new()
$petLines.Add("local _, MC = ...")
$petLines.Add("")
$petLines.Add("-- Cataclysm battle pets. Generated from the exact $($pets.Count)-row release manifest.")
$petLines.Add('MC.RegisterContent("cata", "pets", {')
Add-GroupedEntries $petLines $pets "pets" "pets" {
    param($row, $source)
    $parts = [System.Collections.Generic.List[string]]::new()
    $parts.Add("speciesID = $($row.species_id)")
    $itemID = First-ID $row.item_ids; if ($itemID) { $parts.Add("itemID = $itemID") }
    if ($row.creature_id) { $parts.Add("npcID = $($row.creature_id)") }
    $parts.Add("name = $(ConvertTo-LuaString $row.name)")
    $parts.Add("petType = $([int]$row.pet_type_enum + 1)")
    $parts.Add("source = $(ConvertTo-LuaString $source)")
    $parts.Add("sourceInfo = $(ConvertTo-LuaString $row.source_text)")
    if ([string]$row.unavailable -eq "True") { $parts.Add("unavailable = true") }
    return "        { $($parts -join ', ') },"
}
$petLines.Add("})")
Write-LuaFile "Modules\Pets\Data\Cataclysm.lua" $petLines

$toys = Read-Manifest "toys"
$toyLines = [System.Collections.Generic.List[string]]::new()
$toyLines.Add("local _, MC = ...")
$toyLines.Add("")
$toyLines.Add("-- Cataclysm toys. Generated from the exact $($toys.Count)-row release manifest.")
$toyLines.Add('MC.RegisterContent("cata", "toys", {')
Add-GroupedEntries $toyLines $toys "toys" "toys" {
    param($row, $source)
    $parts = [System.Collections.Generic.List[string]]::new()
    $parts.Add("itemID = $($row.item_id)")
    $parts.Add("name = $(ConvertTo-LuaString $row.name)")
    $parts.Add("source = $(ConvertTo-LuaString $source)")
    $parts.Add("sourceInfo = $(ConvertTo-LuaString $row.source_text)")
    if ([string]$row.unavailable -eq "True") { $parts.Add("unavailable = true") }
    return "        { $($parts -join ', ') },"
}
$toyLines.Add("})")
Write-LuaFile "Modules\Toys\Data\Cataclysm.lua" $toyLines

$decorations = Read-Manifest "decorations"
$decorLines = [System.Collections.Generic.List[string]]::new()
$decorLines.Add("local _, MC = ...")
$decorLines.Add("")
$decorLines.Add("-- Cataclysm-acquisition housing decor. Ownership follows the awarding content, not the Midnight housing row or visual theme.")
$decorLines.Add('MC.RegisterContent("cata", "decorations", {')
$decorGroups = $decorations | Group-Object { [string]$_.source_kind }
foreach ($source in @("crafted", "vendor", "achievement", "quest", "drop")) {
    $group = $decorGroups | Where-Object Name -eq $source
    if (-not $group) { continue }
    $decorLines.Add("    { source = $(ConvertTo-LuaString $source), decorations = {")
    foreach ($row in $group.Group | Sort-Object { [int]$_.decor_id }) {
        $parts = [System.Collections.Generic.List[string]]::new()
        $parts.Add("decorID = $($row.decor_id)")
        $parts.Add("itemID = $($row.item_id)")
        $parts.Add("name = $(ConvertTo-LuaString $row.name)")
        $parts.Add("source = $(ConvertTo-LuaString $source)")
        $parts.Add("sourceInfo = $(ConvertTo-LuaString $row.source_text)")
        $profession = Get-ProfessionExpression $row.source_text; if ($profession) { $parts.Add("skillLine = $profession") }
        $achievementID = First-ID $row.achievement_ids; if ($achievementID) { $parts.Add("achievementID = $achievementID") }
        $questID = First-ID $row.quest_ids; if ($questID) { $parts.Add("questID = $questID") }
        $npcID = First-ID $row.npc_ids; if ($npcID) { $parts.Add("npcID = $npcID") }
        $decorLines.Add("        { $($parts -join ', ') },")
    }
    $decorLines.Add("    } },")
}
$decorLines.Add("})")
Write-LuaFile "Modules\Decorations\Data\Cataclysm.lua" $decorLines

$achievements = Read-Manifest "achievements"
$criteria = Read-Manifest "achievement-criteria"
$criteriaByAchievement = @{}
foreach ($row in $criteria) {
    $id = [string]$row.achievement_id
    if (-not $criteriaByAchievement.ContainsKey($id)) { $criteriaByAchievement[$id] = [System.Collections.Generic.List[object]]::new() }
    $criteriaByAchievement[$id].Add($row)
}
$achievementGroups = @{
    "15067" = @("features", "dungeons", "Cataclysm Dungeons")
    "15068" = @("features", "raid", "Cataclysm Raids")
    "15069" = @("exploration", "zone", "Cataclysm")
    "15070" = @("quests", "metas", "Cataclysm")
    "15072" = @("features", "reputation", "Cataclysm Reputation")
    "15073" = @("features", "gilneas", "Battle for Gilneas")
    "15074" = @("features", "twinpeaks", "Twin Peaks")
    "15075" = @("features", "tolbarad", "Tol Barad")
}
$categoryOrder = @("15067", "15068", "15069", "15070", "15072", "15073", "15074", "15075")
$achievementLines = [System.Collections.Generic.List[string]]::new()
$achievementLines.Add("local _, MC = ...")
$achievementLines.Add("")
$achievementLines.Add("-- Cataclysm player-facing achievements. Exact $($achievements.Count)-row manifest;")
$achievementLines.Add("-- stable criteria tasks are attached only for 2-30-row progress lists.")
$achievementLines.Add('MC.RegisterContent("cata", "achievements", {')
foreach ($categoryID in $categoryOrder) {
    $meta = $achievementGroups[$categoryID]
    $achievementLines.Add("    { category = $(ConvertTo-LuaString $meta[0]), source = $(ConvertTo-LuaString $meta[1]), achievements = {")
    foreach ($row in $achievements | Where-Object category_id -eq $categoryID | Sort-Object { [int]$_.achievement_id }) {
        $prefix = "        { achievementID = $($row.achievement_id), name = $(ConvertTo-LuaString $row.title), description = $(ConvertTo-LuaString $row.description), zone = $(ConvertTo-LuaString $meta[2])"
        $tasks = @($criteriaByAchievement[[string]$row.achievement_id])
        if ($tasks.Count -ge 2 -and $tasks.Count -le 30) {
            $achievementLines.Add($prefix + ",")
            $achievementLines.Add('          taskList = { intro = "Progress from live achievement criteria.", tasks = {')
            $duplicateCriteriaIDs = @($tasks | Group-Object criteria_id | Where-Object Count -gt 1 | ForEach-Object Name)
            $taskIndex = 0
            foreach ($task in $tasks) {
                $taskIndex++
                $criteriaIndex = if ([string]$task.criteria_id -in $duplicateCriteriaIDs) { ", criteriaIndex = $taskIndex" } else { "" }
                $label = if ($task.description) { ", label = $(ConvertTo-LuaString $task.description)" } else { "" }
                $achievementLines.Add("              { achievementID = $($row.achievement_id), criteriaID = $($task.criteria_id)$criteriaIndex$label },")
            }
            $achievementLines.Add("          } } },")
        } else { $achievementLines.Add($prefix + " },") }
    }
    $achievementLines.Add("    } },")
}
$achievementLines.Add("})")
Write-LuaFile "Modules\Achievements\Data\Cataclysm.lua" $achievementLines

$recipes = Read-Manifest "recipes"
$recipeLines = [System.Collections.Generic.List[string]]::new()
$recipeLines.Add("local _, MC = ...")
$recipeLines.Add("")
$recipeLines.Add("-- Cataclysm profession recipes. Generated from the exact $($recipes.Count)-spell manifest.")
$recipeLines.Add('MC.RegisterContent("cata", "recipes", {')
foreach ($group in $recipes | Group-Object profession | Sort-Object Name) {
    $first = $group.Group[0]
    $recipeLines.Add("    { skillLine = $($first.profession_id), name = `"Cataclysm`", recipes = {")
    foreach ($row in $group.Group | Sort-Object { [int]$_.recipe_spell_id }) {
        if ($row.acquire_method -eq "1") { $recipeLines.Add("        { id = $($row.recipe_spell_id), name = $(ConvertTo-LuaString $row.name), source = `"trainer`", sourceInfo = `"Learned automatically`", priority = 1 },") }
        else { $recipeLines.Add("        { id = $($row.recipe_spell_id), name = $(ConvertTo-LuaString $row.name), source = `"unknown`" },") }
    }
    $recipeLines.Add("    } },")
}
$recipeLines.Add("})")
Write-LuaFile "Modules\Recipes\Data\Cataclysm.lua" $recipeLines

$rareGroups = @()
$rares = Read-Manifest "rares"
$rareLines = [System.Collections.Generic.List[string]]::new()
$rareLines.Add("local addonName, MC = ...")
$rareLines.Add("")
$rareLines.Add("-- Cataclysm zone rares. Exact $($rares.Count) ordered criteria/entity rows.")
$rareLines.Add('MC.RegisterContent("cata", "rares", {')
foreach ($group in $rareGroups) {
    $achievementID, $source, $zone, $map = $group
    $rows = @($rares | Where-Object achievement_id -eq $achievementID | Sort-Object { Get-OrderPathSortKey $_.order_path })
    $npcIDs = @($rows | ForEach-Object { [string]$_.npc_id })
    $treeIDs = @($rows | ForEach-Object tree_id)
    $rareLines.Add("    { source = $(ConvertTo-LuaString $source), achievementID = $achievementID, criteriaCount = $($rows.Count),")
    $rareLines.Add("      criteriaTreeIDs = { $($treeIDs -join ', ') },")
    $rareLines.Add("      criteriaNPCIDs = { $($npcIDs -join ', ') }, name = $(ConvertTo-LuaString $rows[0].achievement),")
    $rareLines.Add("      zoneMapID = $map, zone = $(ConvertTo-LuaString $zone) },")
}
$rareLines.Add("})")
$rareLines.Add("")
$rareLines.Add("local SOURCE_KEYS = {")
foreach ($pair in @()) { $rareLines.Add("    { $(ConvertTo-LuaString $pair[0]), $(ConvertTo-LuaString $pair[1]) },") }
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
Write-LuaFile "Modules\Rares\Data\Cataclysm.lua" $rareLines

$treasureGroups = @()
$treasures = Read-Manifest "treasures"
$treasureLines = [System.Collections.Generic.List[string]]::new()
$treasureLines.Add("local addonName, MC = ...")
$treasureLines.Add("")
$treasureLines.Add("-- Cataclysm treasures. Exact $($treasures.Count) ordered criteria rows.")
$treasureLines.Add('MC.RegisterContent("cata", "treasures", {')
foreach ($group in $treasureGroups) {
    $achievementID, $source, $zone, $map = $group
    $rows = @($treasures | Where-Object achievement_id -eq $achievementID | Sort-Object { Get-OrderPathSortKey $_.order_path })
    $treeIDs = @($rows | ForEach-Object tree_id)
    $treasureLines.Add("    { source = $(ConvertTo-LuaString $source), achievementID = $achievementID, criteriaCount = $($rows.Count),")
    $treasureLines.Add("      criteriaTreeIDs = { $($treeIDs -join ', ') },")
    if (@($rows | Where-Object { $_.criterion }).Count -eq $rows.Count) {
        $names = @($rows | ForEach-Object { ConvertTo-LuaString $_.criterion })
        $treasureLines.Add("      criteriaNames = { $($names -join ', ') },")
    }
    $treasureLines.Add("      name = $(ConvertTo-LuaString $rows[0].achievement),")
    $treasureLines.Add("      zoneMapID = $map, zone = $(ConvertTo-LuaString $zone) },")
}
$treasureLines.Add("})")
$treasureLines.Add("")
$treasureLines.Add("local SOURCE_KEYS = {")
foreach ($pair in @()) { $treasureLines.Add("    { $(ConvertTo-LuaString $pair[0]), $(ConvertTo-LuaString $pair[1]) },") }
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
Write-LuaFile "Modules\Treasures\Data\Cataclysm.lua" $treasureLines

Write-Host "Generated Cataclysm Lua data files"
