param(
    [string]$ManifestRoot = (Join-Path $PSScriptRoot "..\research\collectionist\battle-for-azeroth\manifests"),
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
function Get-SourceKey([string]$text, [string]$catalog) {
    if ($text -match "World Event|Holiday|Anniversary|Feast of Winter Veil") { return $(if ($catalog -eq "pets") { "event" } else { "worldevent" }) }
    if ($text -match "Faction:|Reputation:") { return $(if ($catalog -eq "pets") { "vendor" } else { "reputation" }) }
    if ($text -match "Achievement:") { return "achievement" }
    if ($text -match "Quest:|World Quest:") { return "quest" }
    if ($text -match "Treasure:|Secret:") { return "treasure" }
    if ($text -match "Profession|Crafting:") { return "profession" }
    if ($text -match "PvP:|Gladiator:") { return $(if ($catalog -eq "mounts") { "pvp" } else { "achievement" }) }
    if ($text -match "Raid:") { return $(if ($catalog -eq "mounts" -or $catalog -eq "toys") { "raid" } else { "drop" }) }
    if ($text -match "Dungeon:") { return $(if ($catalog -eq "mounts" -or $catalog -eq "toys") { "dungeon" } else { "drop" }) }
    if ($text -match "Vendor:|Paragon Cache:") { return "vendor" }
    if ($text -match "Drop:|Pet Battle:") { return $(if ($text -match "Pet Battle:") { "wild" } else { "drop" }) }
    return "drop"
}
function Get-ProfessionExpression([string]$text) {
    if ($text -match "Junkyard Tinkering") { return "MC.PROFESSION.Engineering" }
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
$mountLines.Add("-- Battle for Azeroth mounts. Generated from the exact $($mounts.Count)-row release manifest.")
$mountLines.Add('MC.RegisterContent("bfa", "mounts", {')
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
Write-LuaFile "Modules\Mounts\Data\BattleForAzeroth.lua" $mountLines

$pets = Read-Manifest "pets"
$petLines = [System.Collections.Generic.List[string]]::new()
$petLines.Add("local _, MC = ...")
$petLines.Add("")
$petLines.Add("-- Battle for Azeroth battle pets. Generated from the exact $($pets.Count)-row release manifest.")
$petLines.Add('MC.RegisterContent("bfa", "pets", {')
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
Write-LuaFile "Modules\Pets\Data\BattleForAzeroth.lua" $petLines

$toys = Read-Manifest "toys"
$toyLines = [System.Collections.Generic.List[string]]::new()
$toyLines.Add("local _, MC = ...")
$toyLines.Add("")
$toyLines.Add("-- Battle for Azeroth toys. Generated from the exact $($toys.Count)-row release manifest.")
$toyLines.Add('MC.RegisterContent("bfa", "toys", {')
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
Write-LuaFile "Modules\Toys\Data\BattleForAzeroth.lua" $toyLines

$decorations = Read-Manifest "decorations"
$decorLines = [System.Collections.Generic.List[string]]::new()
$decorLines.Add("local _, MC = ...")
$decorLines.Add("")
$decorLines.Add("-- BFA-acquisition housing decor. Ownership follows the awarding content, not the housing row build.")
$decorLines.Add('MC.RegisterContent("bfa", "decorations", {')
$decorGroups = $decorations | Group-Object {
    if ($_.spell_ids -or $_.source_text -match "Junkyard Tinkering") { "crafted" }
    elseif ($_.achievement_ids) { "achievement" }
    elseif ($_.quest_ids) { "quest" }
    elseif ($_.currency_ids -or $_.source_text -match "Vendorbot|Provisioner|Arcanist|Quartermaster|Captain |T'lama|War Resources|Dubloon|Community Coupons") { "vendor" }
    else { "drop" }
}
foreach ($source in @("crafted", "vendor", "achievement", "quest", "drop")) {
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
        $profession = Get-ProfessionExpression $row.source_text; if ($profession) { $parts.Add("skillLine = $profession") }
        $achievementID = First-ID $row.achievement_ids; if ($achievementID) { $parts.Add("achievementID = $achievementID") }
        $questID = First-ID $row.quest_ids; if ($questID) { $parts.Add("questID = $questID") }
        $npcID = First-ID $row.npc_ids; if ($npcID) { $parts.Add("npcID = $npcID") }
        $decorLines.Add("        { $($parts -join ', ') },")
    }
    $decorLines.Add("    } },")
}
$decorLines.Add("})")
Write-LuaFile "Modules\Decorations\Data\BattleForAzeroth.lua" $decorLines

$achievements = Read-Manifest "achievements"
$criteria = Read-Manifest "achievement-criteria"
$criteriaByAchievement = @{}
foreach ($row in $criteria) {
    $id = [string]$row.achievement_id
    if (-not $criteriaByAchievement.ContainsKey($id)) { $criteriaByAchievement[$id] = [System.Collections.Generic.List[object]]::new() }
    $criteriaByAchievement[$id].Add($row)
}
$achievementGroups = @{
    "15284" = @("quests", "metas", "Battle for Azeroth")
    "15285" = @("features", "dungeons", "Battle for Azeroth Dungeons")
    "15286" = @("features", "raid", "Battle for Azeroth Raids")
    "15298" = @("exploration", "zone", "Battle for Azeroth")
    "15305" = @("features", "reputation", "Battle for Azeroth Reputation")
    "15307" = @("features", "islands", "Island Expeditions")
    "15308" = @("features", "war_effort", "War Effort")
    "15417" = @("features", "heart_of_azeroth", "Heart of Azeroth")
}
$achievementLines = [System.Collections.Generic.List[string]]::new()
$achievementLines.Add("local _, MC = ...")
$achievementLines.Add("")
$achievementLines.Add("-- Battle for Azeroth player-facing achievements. Exact $($achievements.Count)-row manifest;")
$achievementLines.Add("-- stable criteria tasks are attached only for 2-30-row progress lists.")
$achievementLines.Add('MC.RegisterContent("bfa", "achievements", {')
foreach ($categoryID in @("15284", "15285", "15286", "15298", "15305", "15307", "15308", "15417")) {
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
Write-LuaFile "Modules\Achievements\Data\BattleForAzeroth.lua" $achievementLines

$recipes = Read-Manifest "recipes"
$recipeLines = [System.Collections.Generic.List[string]]::new()
$recipeLines.Add("local _, MC = ...")
$recipeLines.Add("")
$recipeLines.Add("-- Battle for Azeroth profession recipes. Generated from the exact $($recipes.Count)-spell manifest.")
$recipeLines.Add('MC.RegisterContent("bfa", "recipes", {')
foreach ($group in $recipes | Group-Object profession | Sort-Object Name) {
    $first = $group.Group[0]
    $recipeLines.Add("    { skillLine = $($first.profession_id), name = `"Battle for Azeroth`", recipes = {")
    foreach ($row in $group.Group | Sort-Object { [int]$_.recipe_spell_id }) {
        if ($row.acquire_method -eq "1") { $recipeLines.Add("        { id = $($row.recipe_spell_id), name = $(ConvertTo-LuaString $row.name), source = `"trainer`", sourceInfo = `"Learned automatically`", priority = 1 },") }
        else { $recipeLines.Add("        { id = $($row.recipe_spell_id), name = $(ConvertTo-LuaString $row.name), source = `"unknown`" },") }
    }
    $recipeLines.Add("    } },")
}
$recipeLines.Add("})")
Write-LuaFile "Modules\Recipes\Data\BattleForAzeroth.lua" $recipeLines

$zoneMap = @{
    "tiragarde" = @("Tiragarde Sound", "MC.MAP.TiragardeSound")
    "stormsong" = @("Stormsong Valley", "MC.MAP.StormsongValley")
    "drustvar" = @("Drustvar", "MC.MAP.Drustvar")
    "nazmir" = @("Nazmir", "MC.MAP.Nazmir")
    "voldun" = @("Vol'dun", "MC.MAP.Voldun")
    "zuldazar" = @("Zuldazar", "MC.MAP.Zuldazar")
    "mechagon" = @("Mechagon", "MC.MAP.Mechagon")
    "nazjatar" = @("Nazjatar", "MC.MAP.Nazjatar")
}
$rares = Read-Manifest "rares"
$rareGroups = @(@("12939", "tiragarde"), @("12940", "stormsong"), @("12941", "drustvar"), @("12942", "nazmir"), @("12943", "voldun"), @("12944", "zuldazar"), @("13470", "mechagon"), @("13691", "nazjatar"))
$rareLines = [System.Collections.Generic.List[string]]::new()
$rareLines.Add("local addonName, MC = ...")
$rareLines.Add("")
$rareLines.Add("-- Battle for Azeroth zone rares and special encounters. Exact $($rares.Count) ordered criteria/entity rows.")
$rareLines.Add('MC.RegisterContent("bfa", "rares", {')
foreach ($group in $rareGroups) {
    $achievementID, $source = $group; $meta = $zoneMap[$source]
    $rows = @($rares | Where-Object achievement_id -eq $achievementID | Sort-Object { Get-OrderPathSortKey $_.order_path })
    $npcIDs = @($rows | ForEach-Object { if ($_.npc_ids) { First-ID $_.npc_ids } else { "false" } })
    $objectIDs = @($rows | ForEach-Object { if ($_.object_ids) { First-ID $_.object_ids } else { "false" } })
    $treeIDs = @($rows | ForEach-Object tree_id)
    $rareLines.Add("    { source = $(ConvertTo-LuaString $source), achievementID = $achievementID, criteriaCount = $($rows.Count),")
    $rareLines.Add("      criteriaTreeIDs = { $($treeIDs -join ', ') },")
    $rareLines.Add("      criteriaNPCIDs = { $($npcIDs -join ', ') },")
    $rareLines.Add("      criteriaObjectIDs = { $($objectIDs -join ', ') }, name = $(ConvertTo-LuaString $rows[0].achievement),")
    $rareLines.Add("      zoneMapID = $($meta[1]), zone = $(ConvertTo-LuaString $meta[0]) },")
}
$rareLines.Add("})")
$rareLines.Add("")
$rareLines.Add("local SOURCE_KEYS = {")
foreach ($source in @("tiragarde", "stormsong", "drustvar", "nazmir", "voldun", "zuldazar", "mechagon", "nazjatar")) { $rareLines.Add("    { $(ConvertTo-LuaString $source), $(ConvertTo-LuaString $zoneMap[$source][0]) },") }
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
Write-LuaFile "Modules\Rares\Data\BattleForAzeroth.lua" $rareLines

$treasures = Read-Manifest "treasures"
$treasureGroups = @(@("12852", "tiragarde"), @("12853", "stormsong"), @("12995", "drustvar"), @("12771", "nazmir"), @("12849", "voldun"), @("12851", "zuldazar"), @("13549", "nazjatar"), @("13836", "nazjatar"))
$treasureLines = [System.Collections.Generic.List[string]]::new()
$treasureLines.Add("local addonName, MC = ...")
$treasureLines.Add("")
$treasureLines.Add("-- Battle for Azeroth treasures and hidden-object collections. Exact $($treasures.Count) ordered criteria rows.")
$treasureLines.Add('MC.RegisterContent("bfa", "treasures", {')
foreach ($group in $treasureGroups) {
    $achievementID, $source = $group; $meta = $zoneMap[$source]
    $rows = @($treasures | Where-Object achievement_id -eq $achievementID | Sort-Object { Get-OrderPathSortKey $_.order_path })
    $names = @($rows | ForEach-Object { ConvertTo-LuaString $_.criterion })
    $treeIDs = @($rows | ForEach-Object tree_id)
    $treasureLines.Add("    { source = $(ConvertTo-LuaString $source), achievementID = $achievementID, criteriaCount = $($rows.Count),")
    $treasureLines.Add("      criteriaTreeIDs = { $($treeIDs -join ', ') },")
    $treasureLines.Add("      criteriaNames = { $($names -join ', ') }, name = $(ConvertTo-LuaString $rows[0].achievement),")
    $treasureLines.Add("      zoneMapID = $($meta[1]), zone = $(ConvertTo-LuaString $meta[0]) },")
}
$treasureLines.Add("})")
$treasureLines.Add("")
$treasureLines.Add("local SOURCE_KEYS = {")
foreach ($source in @("tiragarde", "stormsong", "drustvar", "nazmir", "voldun", "zuldazar", "nazjatar")) { $treasureLines.Add("    { $(ConvertTo-LuaString $source), $(ConvertTo-LuaString $zoneMap[$source][0]) },") }
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
Write-LuaFile "Modules\Treasures\Data\BattleForAzeroth.lua" $treasureLines

Write-Host "Generated Battle for Azeroth Lua data files"
