<#
.SYNOPSIS
Emits navigation-only rare and treasure map references from the HandyNotes audit.

.DESCRIPTION
Seven installed HandyNotes plugins publish coordinate-keyed zone tables that
Collectionist's achievement-backed model never covered. The audit normalised
them to stable identities: 721 rare NPCs and 834 quest-identified treasures
that Collectionist does not already represent.

These are NOT collectibles. They ship under the navigation-only contract
(Data/Constants.lua:132-137, MC.BucketNavigationGroups): they render with a
"Location only" label, keep their waypoint and metadata, can be pinned, and
never enter completion denominators, Collection Score, collected lists or
roster bitmaps.

CONTRACT EXTENSION: the identity contract previously named objectID or itemID.
These treasure providers supply a stable quest completion flag instead, so
questID is now an accepted identity. That is the extension the policy document
called for; nothing else about the contract changes.

QUALITY GATES, per that same policy - "every row must have a name, stable
entity identifier, map/coordinates, expansion, and source provenance":

  * A row with no resolvable name is skipped. That drops 428 of the 834
    treasures, which carry neither a comment nor a criteria ID. A nameless
    "Location only" pin is not worth shipping.
  * A row whose zone cannot be resolved to a uiMapID is skipped.
  * Ambiguous zone names are disambiguated by expansion - HandyNotes writes
    "Nagrand" for both the Outland and the Draenor zone.
#>
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
    [switch]$WhatIf
)

$ErrorActionPreference = "Stop"

$rarePath     = Join-Path $RepoRoot "research/collectionist/sources/handynotes-table-rare-gap-audit.csv"
$treasurePath = Join-Path $RepoRoot "research/collectionist/sources/handynotes-table-treasure-gap-audit.csv"
$constants    = Join-Path $RepoRoot "addons/Collectionist/Data/Constants.lua"
foreach ($p in @($rarePath, $treasurePath, $constants)) { if (-not (Test-Path -LiteralPath $p)) { throw "Missing $p" } }

$EXPANSION_KEY = @{
    "classic" = "vanilla"; "tbc" = "tbc"; "wrath" = "wrath"; "cataclysm" = "cata"
    "mists_of_pandaria" = "mop"; "wod" = "wod"; "legion" = "legion"
    "battle_for_azeroth" = "bfa"; "shadowlands" = "shadowlands"
    "dragonflight" = "df"; "tww" = "tww"; "midnight" = "midnight"
}
# HandyNotes writes one zone name for maps that exist twice.
$AMBIGUOUS = @{
    "Nagrand"            = @{ tbc = "NagrandOutland";          wod = "NagrandDraenor" }
    "ShadowmoonValley"   = @{ tbc = "ShadowmoonValleyOutland"; wod = "ShadowmoonValleyDraenor" }
}

# MC.MAP is the addon's own zone registry; reuse it rather than inventing one.
$mapText = [System.IO.File]::ReadAllText($constants)
$mapBlock = [regex]::Match($mapText, 'MC\.MAP\s*=\s*\{(.*?)\n\}', 'Singleline').Groups[1].Value
$MAP = @{}
foreach ($m in [regex]::Matches($mapBlock, '(\w+)\s*=\s*(\d+),')) { $MAP[$m.Groups[1].Value] = [int]$m.Groups[2].Value }
$MAP_CI = @{}
foreach ($k in $MAP.Keys) { $MAP_CI[$k.ToLowerInvariant()] = $MAP[$k] }
Write-Host ("MC.MAP zones: {0}" -f $MAP.Count)

$INV = [System.Globalization.CultureInfo]::InvariantCulture
function Format-Coord([double]$v) { return $v.ToString("0.####", $INV) }
function ConvertTo-LuaString([string]$v) {
    if ($null -eq $v) { $v = "" }
    return '"' + ($v -replace '\\', '\\\\' -replace '"', '\"') + '"'
}

function Resolve-Map([string]$sourceFiles, [string]$expansion) {
    $zone = (($sourceFiles -split ';')[0]) -replace '\.lua$', ''
    if ($script:AMBIGUOUS.ContainsKey($zone)) {
        $variants = $script:AMBIGUOUS[$zone]
        if ($variants -and $variants.ContainsKey($expansion)) {
            $alt = $variants[$expansion]
            if ($alt -and $script:MAP.ContainsKey($alt)) { return @{ id = $script:MAP[$alt]; zone = $alt } }
        }
        # Ambiguous name with no rule for this expansion: refuse rather than
        # guess, or the pin lands in the wrong hemisphere.
        return $null
    }
    $id = $script:MAP_CI[$zone.ToLowerInvariant()]
    if ($id) { return @{ id = $id; zone = $zone } }
    return $null
}

# HandyNotes packs a coordinate as xxxxyyyy, each half hundredths of a percent.
# 75804758 -> 75.80, 47.58 -> 0.758, 0.4758
function ConvertTo-Coords([string]$packed) {
    # A typed list, not @() with "+= ,". PowerShell flattens an array-of-arrays
    # built that way, which silently turned every {x,y} pair into two separate
    # coordinates whose y read as 0 - and a mapID with y=0 is a pin at the top
    # edge of the map, not an error anything would catch.
    $out = [System.Collections.Generic.List[object]]::new()
    foreach ($chunk in ($packed -split '[;,]')) {
        $c = $chunk.Trim()
        if ($c.Length -lt 7 -or $c -notmatch '^\d+$') { continue }
        $c = $c.PadLeft(8, '0')
        $x = [double]$c.Substring(0, 4) / 10000.0
        $y = [double]$c.Substring(4, 4) / 10000.0
        if ($x -le 0 -or $x -gt 1 -or $y -le 0 -or $y -gt 1) { continue }
        $out.Add(@([math]::Round($x, 4), [math]::Round($y, 4)))
    }
    # Unary comma. `return $out` would ENUMERATE the list onto the pipeline and
    # the caller would collect a flat list of numbers, turning each {x,y} into
    # two coordinates with y = 0.
    return ,$out
}

# The providers' comment field is free text and often holds a raw fragment of
# their own Lua rather than a label -- "[37005734] = {quest=39083, label=ns.CHEST_SM},"
# or a bare node ID. Shipping those puts source code in the panel and on the
# map pin.
#
# Two passes. First RECOVER: these fragments usually carry the real name in a
# trailing "-- Name" comment, so prefer that over the fragment. Then REJECT
# anything still shaped like code, numeric-only, or a maintainer's note.
$NAME_FILLER = '^(verify|verified|todo|tbd|check|unknown|test|temp|\?+)$'

function Get-CleanName([string]$raw) {
    if (-not $raw) { return $null }
    $n = $raw.Trim()

    # An explicit label= is the provider's own display string and beats
    # everything else. A trailing comment on the same row is as often a
    # maintainer's note ("bugged for years") as a name.
    $lab = [regex]::Match($n, 'label\s*=\s*"([^"]+)"')
    if ($lab.Success -and $lab.Groups[1].Value.Trim()) { return $lab.Groups[1].Value.Trim() }

    # "[[npc=214726--]]}, -- Lava Slug" -> "Lava Slug".
    #
    # The leading `^.*` is greedy on purpose: it forces the match onto the LAST
    # `--` in the string. An anchored pattern without it matches the FIRST `--`
    # -- which in these fragments is usually inside the payload (`npc=214726--`)
    # -- and captures the rest of the line as if it were the label.
    $m = [regex]::Match($n, '^.*--\s*(.+?)\s*$')
    if ($m.Success -and $m.Groups[1].Value.Trim()) { $n = $m.Groups[1].Value.Trim() }

    $n = ($n -split '[;|]')[0].Trim()
    $n = $n.Trim('"', "'", ',', ' ', '-')
    if (-not $n) { return $null }

    # Still code-shaped, a bare number, or a note to self.
    if ($n -match '[\{\}\[\]=]') { return $null }
    if ($n -match '\bns\.' -or $n -match '^\s*--') { return $null }
    if ($n -match '^\d+$') { return $null }
    if ($n -match $NAME_FILLER) { return $null }
    if ($n.Length -lt 3) { return $null }
    return $n
}

# Zone key for the source bucket: lowercase, matching the existing rare data
# ("azsuna", "highmountain").
function Get-ZoneKey([string]$zone) { return ($zone -creplace '(?<!^)([A-Z])', '_$1').ToLowerInvariant() }

# Display name. Splitting the provider's CamelCase filename gives "Vale Of
# Eternal Blossoms" -- visibly not a WoW zone name -- so prefer the client's own
# UiMap name for the mapID we already resolved, and only fall back to the split
# when the export predates that map. Newest export wins for the same reason the
# trading-post generator picks the largest BattlePetSpecies.
$script:UIMAP = @{}
$uiMapCsv = Get-ChildItem -Path (Join-Path $env:TEMP "collectionist-*-db2") -Filter UiMap.csv -Recurse -ErrorAction SilentlyContinue |
    Sort-Object { (Get-Content -LiteralPath $_.FullName | Measure-Object -Line).Lines } -Descending |
    Select-Object -First 1
if ($uiMapCsv) {
    foreach ($row in (Import-Csv -LiteralPath $uiMapCsv.FullName)) {
        if ($row.ID -and $row.Name_lang) { $script:UIMAP[$row.ID] = $row.Name_lang }
    }
    Write-Host ("UiMap names: {0} (from {1})" -f $script:UIMAP.Count, (Split-Path -Leaf (Split-Path -Parent $uiMapCsv.FullName)))
}

function Get-ZoneLabel([string]$zone, $mapID) {
    if ($mapID -and $script:UIMAP.ContainsKey([string]$mapID)) { return $script:UIMAP[[string]$mapID] }
    return ($zone -creplace '(?<!^)([A-Z])', ' $1')
}

function Build-Groups($rows, [string]$listKey, [scriptblock]$entryBuilder, [ref]$stats) {
    $groups = [ordered]@{}
    foreach ($row in $rows) {
        $expKey = $EXPANSION_KEY[$row.expansion]
        if (-not $expKey) { $stats.Value.noExpansion++; continue }
        $map = Resolve-Map $row.source_files $row.expansion
        if (-not $map) { $stats.Value.noMap++; continue }
        $coords = ConvertTo-Coords $row.coordinates
        if ($coords.Count -eq 0) { $stats.Value.noCoords++; continue }

        $entry = & $entryBuilder $row $map $coords
        if (-not $entry) { $stats.Value.noName++; continue }

        $key = "$expKey|$($map.zone)"
        if (-not $groups.Contains($key)) {
            $groups[$key] = @{ expansion = $expKey; zone = $map.zone; mapID = $map.id; entries = [System.Collections.Generic.List[string]]::new() }
        }
        $groups[$key].entries.Add($entry)
        $stats.Value.emitted++
    }
    return $groups
}

function Format-Waypoint($mapID, $coords, [string]$label) {
    if ($coords.Count -eq 1) {
        return '{ ' + $mapID + ', ' + (Format-Coord $coords[0][0]) + ', ' + (Format-Coord $coords[0][1]) + ', ' + (ConvertTo-LuaString $label) + ' }'
    }
    $parts = foreach ($c in $coords) {
        '{ ' + $mapID + ', ' + (Format-Coord $c[0]) + ', ' + (Format-Coord $c[1]) + ', ' + (ConvertTo-LuaString $label) + ' }'
    }
    return '{ ' + ($parts -join ', ') + ' }'
}

function Write-NavFile($groups, [string]$module, [string]$listKey, [string]$noun, [string]$outPath) {
    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine('local _, MC = ...')
    [void]$sb.AppendLine()
    [void]$sb.AppendLine('-- GENERATED FILE - do not edit.')
    [void]$sb.AppendLine('-- Regenerate: scripts/generate-collectionist-navigation-gaps.ps1')
    [void]$sb.AppendLine('--')
    [void]$sb.AppendLine(('-- Navigation-only {0}: map references, not collectibles. They render with' -f $noun))
    [void]$sb.AppendLine('-- a "Location only" label and can be pinned, but never enter completion')
    [void]$sb.AppendLine('-- denominators, Collection Score, collected lists or roster bitmaps.')
    [void]$sb.AppendLine('-- See MC.BucketNavigationGroups in Data/Constants.lua.')
    [void]$sb.AppendLine('--')
    [void]$sb.AppendLine('-- Sourced from installed HandyNotes table providers. Rows without a')
    [void]$sb.AppendLine('-- resolvable name, zone or coordinate are deliberately absent.')
    [void]$sb.AppendLine()
    # Register every zone key with the module's source order and labels, or the
    # tab renders the raw key ("vale_of_eternal_blossoms") as a section header
    # and draws those sections in a non-deterministic order, because an
    # unregistered key falls out of a pairs() walk. Same shape and the same
    # ADDON_LOADED guard the per-expansion files already use, e.g.
    # Modules/Rares/Data/BattleForAzeroth.lua:47.
    $orderVar  = if ($module -eq 'rares') { 'RareSourceOrder' }  else { 'TreasureSourceOrder' }
    $labelsVar = if ($module -eq 'rares') { 'RareSourceLabels' } else { 'TreasureSourceLabels' }
    [void]$sb.AppendLine('local SOURCE_KEYS = {')
    foreach ($g in ($groups.Values | Sort-Object zone -Unique)) {
        [void]$sb.AppendLine(('    {{ {0}, {1} }},' -f
            (ConvertTo-LuaString (Get-ZoneKey $g.zone)), (ConvertTo-LuaString (Get-ZoneLabel $g.zone $g.mapID))))
    }
    [void]$sb.AppendLine('}')
    [void]$sb.AppendLine('local function mergeSourceKeys()')
    [void]$sb.AppendLine(('    MC.{0} = MC.{0} or {{}}' -f $orderVar))
    [void]$sb.AppendLine(('    MC.{0} = MC.{0} or {{}}' -f $labelsVar))
    [void]$sb.AppendLine('    for _, pair in ipairs(SOURCE_KEYS) do')
    [void]$sb.AppendLine(('        if not MC.{0}[pair[1]] then' -f $labelsVar))
    [void]$sb.AppendLine(('            MC.{0}[#MC.{0} + 1] = pair[1]' -f $orderVar))
    [void]$sb.AppendLine('        end')
    [void]$sb.AppendLine(('        MC.{0}[pair[1]] = MC.{0}[pair[1]] or pair[2]' -f $labelsVar))
    [void]$sb.AppendLine('    end')
    [void]$sb.AppendLine('end')
    [void]$sb.AppendLine(('if MC.{0} then mergeSourceKeys() else' -f $orderVar))
    [void]$sb.AppendLine('    local f = CreateFrame("Frame"); f:RegisterEvent("ADDON_LOADED")')
    [void]$sb.AppendLine('    f:SetScript("OnEvent", function(self, _, name)')
    [void]$sb.AppendLine('        if name ~= "Collectionist" then return end')
    [void]$sb.AppendLine('        self:UnregisterEvent("ADDON_LOADED"); self:SetScript("OnEvent", nil); mergeSourceKeys()')
    [void]$sb.AppendLine('    end)')
    [void]$sb.AppendLine('end')
    [void]$sb.AppendLine()

    foreach ($expGroup in ($groups.Values | Group-Object expansion | Sort-Object Name)) {
        [void]$sb.AppendLine(('MC.RegisterContent({0}, "{1}", {{' -f (ConvertTo-LuaString $expGroup.Name), $module))
        foreach ($g in ($expGroup.Group | Sort-Object zone)) {
            [void]$sb.AppendLine(('    {{ navigationOnly = true, source = {0}, zone = {1}, {2} = {{' -f
                (ConvertTo-LuaString (Get-ZoneKey $g.zone)), (ConvertTo-LuaString (Get-ZoneLabel $g.zone $g.mapID)), $listKey))
            foreach ($e in $g.entries) { [void]$sb.AppendLine('        ' + $e) }
            [void]$sb.AppendLine('    } },')
        }
        [void]$sb.AppendLine('})')
        [void]$sb.AppendLine()
    }
    if (-not $WhatIf) {
        $utf8 = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText($outPath, ($sb.ToString() -replace "`r`n", "`n"), $utf8)
    }
}

# ---- rares -------------------------------------------------------------
$rareStats = @{ emitted = 0; noExpansion = 0; noMap = 0; noCoords = 0; noName = 0 }
$rareRows = @(Import-Csv -LiteralPath $rarePath | Where-Object { $_.decision -eq 'navigation_candidate_needs_dedup' })
$rareGroups = Build-Groups $rareRows "rares" {
    param($row, $map, $coords)
    $name = Get-CleanName $row.name
    if (-not $name) { return $null }
    $wp = Format-Waypoint $map.id $coords $name
    return '{ npcID = ' + $row.npc_id + ', name = ' + (ConvertTo-LuaString $name) + ', waypoint = ' + $wp + ' },'
} ([ref]$rareStats)
Write-NavFile $rareGroups "rares" "rares" "rares" (Join-Path $RepoRoot "addons/Collectionist/Modules/Rares/Data/Navigation.lua")

# ---- treasures ---------------------------------------------------------
$treasureStats = @{ emitted = 0; noExpansion = 0; noMap = 0; noCoords = 0; noName = 0 }
$treasureRows = @(Import-Csv -LiteralPath $treasurePath | Where-Object { $_.decision -eq 'quest_identity_navigation_candidate' })
$treasureGroups = Build-Groups $treasureRows "treasures" {
    param($row, $map, $coords)
    # comments is the provider's own label, but often a raw Lua fragment.
    $name = Get-CleanName $row.comments
    if (-not $name) { return $null }
    $wp = Format-Waypoint $map.id $coords $name
    return '{ questID = ' + $row.quest_id + ', name = ' + (ConvertTo-LuaString $name) + ', waypoint = ' + $wp + ' },'
} ([ref]$treasureStats)
Write-NavFile $treasureGroups "treasures" "treasures" "treasures" (Join-Path $RepoRoot "addons/Collectionist/Modules/Treasures/Data/Navigation.lua")

Write-Host ""
Write-Host ("Rares     candidates {0,4}  emitted {1,4}" -f $rareRows.Count, $rareStats.emitted)
$rareStats.GetEnumerator() | Where-Object { $_.Key -ne 'emitted' -and $_.Value -gt 0 } | ForEach-Object {
    Write-Host ("   skipped {0,-12} {1}" -f $_.Key, $_.Value) }
Write-Host ("Treasures candidates {0,4}  emitted {1,4}" -f $treasureRows.Count, $treasureStats.emitted)
$treasureStats.GetEnumerator() | Where-Object { $_.Key -ne 'emitted' -and $_.Value -gt 0 } | ForEach-Object {
    Write-Host ("   skipped {0,-12} {1}" -f $_.Key, $_.Value) }
if ($WhatIf) { Write-Host "(-WhatIf)" }
