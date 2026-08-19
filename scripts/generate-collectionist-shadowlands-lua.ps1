param(
    [string]$ManifestRoot = (Join-Path $PSScriptRoot "..\research\collectionist\shadowlands\manifests"),
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
    if ($text -match "World Event|Holiday|Anniversary|Feast of Winter Veil") {
        return $(if ($catalog -eq "pets") { "event" } else { "worldevent" })
    }
    if ($text -match "Faction:|Renown:|Reputation:|Covenant:") {
        return $(if ($catalog -eq "pets") { "vendor" } else { "renown" })
    }
    if ($text -match "Achievement:") { return "achievement" }
    if ($text -match "Quest:|World Quest:|Calling") { return "quest" }
    if ($text -match "Treasure:") { return "treasure" }
    if ($text -match "Profession|Crafting:") { return "profession" }
    if ($text -match "PvP:|Gladiator:") { return $(if ($catalog -eq "mounts") { "pvp" } else { "achievement" }) }
    if ($text -match "Raid:|Castle Nathria|Sanctum of Domination|Sepulcher of the First Ones") {
        return $(if ($catalog -eq "mounts" -or $catalog -eq "toys") { "raid" } else { "drop" })
    }
    if ($text -match "Dungeon:") { return $(if ($catalog -eq "mounts" -or $catalog -eq "toys") { "dungeon" } else { "drop" }) }
    if ($text -match "Vendor:|Paragon Cache:") { return "vendor" }
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
        foreach ($row in @($groups[$source])) { $lines.Add((& $entryBuilder $row $source)) }
        $lines.Add("    } },")
    }
}

# Mounts --------------------------------------------------------------------
$mounts = Read-Manifest "mounts"
$mountLines = [System.Collections.Generic.List[string]]::new()
$mountLines.Add("local _, MC = ...")
$mountLines.Add("")
$mountLines.Add("-- Shadowlands mounts. Generated from the exact $($mounts.Count)-row release manifest.")
$mountLines.Add('MC.RegisterContent("shadowlands", "mounts", {')
Add-GroupedEntries $mountLines $mounts "mounts" "mounts" {
    param($row, $source)
    $parts = [System.Collections.Generic.List[string]]::new()
    $parts.Add("mountID = $($row.mount_id)")
    $itemID = First-ID $row.item_ids
    if ($itemID) { $parts.Add("itemID = $itemID") }
    $parts.Add("name = $(ConvertTo-LuaString $row.name)")
    $parts.Add("source = $(ConvertTo-LuaString $source)")
    $parts.Add("sourceInfo = $(ConvertTo-LuaString $row.source_text)")
    if ([string]$row.unavailable -eq "True") { $parts.Add("unavailable = true") }
    return "        { $($parts -join ', ') },"
}
$mountLines.Add("})")
Write-LuaFile "Modules\Mounts\Data\Shadowlands.lua" $mountLines

# Pets ----------------------------------------------------------------------
$pets = Read-Manifest "pets"
$petLines = [System.Collections.Generic.List[string]]::new()
$petLines.Add("local _, MC = ...")
$petLines.Add("")
$petLines.Add("-- Shadowlands battle pets. Generated from the exact $($pets.Count)-row release manifest.")
$petLines.Add('MC.RegisterContent("shadowlands", "pets", {')
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
    $parts.Add("sourceInfo = $(ConvertTo-LuaString $row.source_text)")
    if ([string]$row.unavailable -eq "True") { $parts.Add("unavailable = true") }
    return "        { $($parts -join ', ') },"
}
$petLines.Add("})")
Write-LuaFile "Modules\Pets\Data\Shadowlands.lua" $petLines

# Toys ----------------------------------------------------------------------
$toys = Read-Manifest "toys"
$toyLines = [System.Collections.Generic.List[string]]::new()
$toyLines.Add("local _, MC = ...")
$toyLines.Add("")
$toyLines.Add("-- Shadowlands toys. Generated from the exact 115-row release manifest.")
$toyLines.Add('MC.RegisterContent("shadowlands", "toys", {')
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
Write-LuaFile "Modules\Toys\Data\Shadowlands.lua" $toyLines

# Decorations ---------------------------------------------------------------
$decorations = Read-Manifest "decorations"
$decorLines = [System.Collections.Generic.List[string]]::new()
$decorLines.Add("local _, MC = ...")
$decorLines.Add("")
$decorLines.Add("-- Shadowlands-acquisition housing decor. Generated from the exact 26-row manifest.")
$decorLines.Add('MC.RegisterContent("shadowlands", "decorations", {')
$decorGroups = $decorations | Group-Object {
    if ($_.source_text -match "Crafting:") { "crafted" }
    elseif ($_.source_text -match "Achievement:") { "achievement" }
    elseif ($_.source_text -match "Quest:") { "quest" }
    elseif ($_.source_text -match "Vendor:") { "vendor" }
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
        $profession = Get-ProfessionExpression $row.source_text
        if ($profession) { $parts.Add("skillLine = $profession") }
        if ([string]$row.decor_id -eq "4181") { $parts.Add("achievementID = 15654") }
        $decorLines.Add("        { $($parts -join ', ') },")
    }
    $decorLines.Add("    } },")
}
$decorLines.Add("})")
Write-LuaFile "Modules\Decorations\Data\Shadowlands.lua" $decorLines

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
    "15422" = @("quests", "metas", "Shadowlands")
    "15428" = @("features", "dungeons", "Shadowlands Dungeons")
    "15436" = @("exploration", "zone", "Shadowlands")
    "15438" = @("features", "raid", "Shadowlands Raids")
    "15439" = @("features", "reputation", "Shadowlands Reputation")
    "15440" = @("features", "torghast", "Torghast")
    "15441" = @("features", "covenants", "Covenant Sanctums")
}
$achievementLines = [System.Collections.Generic.List[string]]::new()
$achievementLines.Add("local _, MC = ...")
$achievementLines.Add("")
$achievementLines.Add("-- Shadowlands player-facing achievements. Exact 419-row manifest;")
$achievementLines.Add("-- stable criteria tasks are attached only for 2-30-row progress lists.")
$achievementLines.Add('MC.RegisterContent("shadowlands", "achievements", {')
foreach ($categoryID in @("15422", "15428", "15436", "15438", "15439", "15440", "15441")) {
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
Write-LuaFile "Modules\Achievements\Data\Shadowlands.lua" $achievementLines

# Recipes -------------------------------------------------------------------
$recipes = Read-Manifest "recipes"
$recipeLines = [System.Collections.Generic.List[string]]::new()
$recipeLines.Add("local _, MC = ...")
$recipeLines.Add("")
$recipeLines.Add("-- Shadowlands profession recipes. Generated from the exact 611-spell manifest.")
$recipeLines.Add('MC.RegisterContent("shadowlands", "recipes", {')
foreach ($group in $recipes | Group-Object profession | Sort-Object Name) {
    $first = $group.Group[0]
    $recipeLines.Add("    { skillLine = $($first.profession_id), name = `"Shadowlands`", recipes = {")
    foreach ($row in $group.Group | Sort-Object { [int]$_.recipe_spell_id }) {
        if ($row.acquire_method -eq "1") {
            $recipeLines.Add("        { id = $($row.recipe_spell_id), name = $(ConvertTo-LuaString $row.name), source = `"trainer`", sourceInfo = `"Learned automatically`", priority = 1 },")
        } else {
            $recipeLines.Add("        { id = $($row.recipe_spell_id), name = $(ConvertTo-LuaString $row.name), source = `"unknown`" },")
        }
    }
    $recipeLines.Add("    } },")
}
$recipeLines.Add("})")
Write-LuaFile "Modules\Recipes\Data\Shadowlands.lua" $recipeLines

# Rares ---------------------------------------------------------------------
$rares = Read-Manifest "rares"
$zoneMap = @{
    "bastion" = @("Bastion", "MC.MAP.Bastion")
    "maldraxxus" = @("Maldraxxus", "MC.MAP.Maldraxxus")
    "ardenweald" = @("Ardenweald", "MC.MAP.Ardenweald")
    "revendreth" = @("Revendreth", "MC.MAP.Revendreth")
    "maw" = @("The Maw", "MC.MAP.Maw")
    "korthia" = @("Korthia", "MC.MAP.Korthia")
    "zereth_mortis" = @("Zereth Mortis", "MC.MAP.ZerethMortis")
}
$rareGroups = @(
    @("14307", "bastion"), @("14308", "maldraxxus"), @("14309", "ardenweald"), @("14310", "revendreth"),
    @("14660", "maw"), @("14744", "maw"), @("15054", "maw"), @("15107", "korthia"),
    @("15391", "zereth_mortis"), @("15392", "zereth_mortis")
)
$rareLines = [System.Collections.Generic.List[string]]::new()
$rareLines.Add("local addonName, MC = ...")
$rareLines.Add("")
$rareLines.Add("-- Shadowlands zone rares. Exact 211 ordered criteria/NPC rows.")
$rareLines.Add('MC.RegisterContent("shadowlands", "rares", {')
foreach ($group in $rareGroups) {
    $achievementID, $source = $group
    $meta = $zoneMap[$source]
    $rows = @($rares | Where-Object achievement_id -eq $achievementID | Sort-Object { Get-OrderPathSortKey $_.order_path })
    $ids = @($rows | ForEach-Object { First-ID $_.npc_ids })
    $treeIDs = @($rows | ForEach-Object { $_.tree_id })
    $rareLines.Add("    { source = $(ConvertTo-LuaString $source), achievementID = $achievementID, criteriaCount = $($rows.Count),")
    $rareLines.Add("      criteriaTreeIDs = { $($treeIDs -join ', ') },")
    $rareLines.Add("      criteriaNPCIDs = { $($ids -join ', ') }, name = $(ConvertTo-LuaString $rows[0].achievement),")
    $rareLines.Add("      zoneMapID = $($meta[1]), zone = $(ConvertTo-LuaString $meta[0]) },")
}
$rareLines.Add("})")
$rareLines.Add("")
$rareLines.Add("local SOURCE_KEYS = {")
foreach ($source in @("bastion", "maldraxxus", "ardenweald", "revendreth", "maw", "korthia", "zereth_mortis")) {
    $rareLines.Add("    { $(ConvertTo-LuaString $source), $(ConvertTo-LuaString $zoneMap[$source][0]) },")
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
Write-LuaFile "Modules\Rares\Data\Shadowlands.lua" $rareLines

# Treasures -----------------------------------------------------------------
$treasures = Read-Manifest "treasures"
$treasureGroups = @(
    @("14311", "bastion"), @("14312", "maldraxxus"), @("14313", "ardenweald"), @("14314", "revendreth"),
    @("15099", "korthia"), @("15331", "zereth_mortis"), @("15502", "zereth_mortis")
)
$treasureLines = [System.Collections.Generic.List[string]]::new()
$treasureLines.Add("local addonName, MC = ...")
$treasureLines.Add("")
$treasureLines.Add("-- Shadowlands zone treasures. Exact 103 ordered criteria rows.")
$treasureLines.Add('MC.RegisterContent("shadowlands", "treasures", {')
foreach ($group in $treasureGroups) {
    $achievementID, $source = $group
    $meta = $zoneMap[$source]
    $rows = @($treasures | Where-Object achievement_id -eq $achievementID | Sort-Object { Get-OrderPathSortKey $_.order_path })
    $names = @($rows | ForEach-Object { ConvertTo-LuaString $_.criterion })
    $treeIDs = @($rows | ForEach-Object { $_.tree_id })
    $treasureLines.Add("    { source = $(ConvertTo-LuaString $source), achievementID = $achievementID, criteriaCount = $($rows.Count),")
    $treasureLines.Add("      criteriaTreeIDs = { $($treeIDs -join ', ') },")
    $treasureLines.Add("      criteriaNames = { $($names -join ', ') }, name = $(ConvertTo-LuaString $rows[0].achievement),")
    $treasureLines.Add("      zoneMapID = $($meta[1]), zone = $(ConvertTo-LuaString $meta[0]) },")
}
$treasureLines.Add("})")
$treasureLines.Add("")
$treasureLines.Add("local SOURCE_KEYS = {")
foreach ($source in @("bastion", "maldraxxus", "ardenweald", "revendreth", "korthia", "zereth_mortis")) {
    $treasureLines.Add("    { $(ConvertTo-LuaString $source), $(ConvertTo-LuaString $zoneMap[$source][0]) },")
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
Write-LuaFile "Modules\Treasures\Data\Shadowlands.lua" $treasureLines

Write-Host "Generated Shadowlands Lua data files"
