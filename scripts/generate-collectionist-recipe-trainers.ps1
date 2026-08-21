<#
.SYNOPSIS
Emits Modules/Recipes/Data/Trainers.lua - faction-correct trainer waypoints.

.DESCRIPTION
ATT nests each recipe under exactly ONE faction's trainer node, so anchoring on
recipes yields 1,291 Horde-capital rows against 20 Alliance. Pinning those as-is
would route Alliance players into Orgrimmar.

The other faction's trainer is not missing from ATT - it simply has no recipes
nested beneath it. Enumerating NPC nodes directly (extract-att-sources.lua with
"self:n") finds 6,640 NPCs carrying their own coordinates, 305 of them in
Alliance capitals against 246 Horde.

So: for a recipe whose ATT trainer sits in a faction capital, look up the
same-profession trainer in the OPPOSITE faction's paired capital and emit both.
Neutral hubs - Dalaran, Shattrath, Oribos, Valdrakken - serve both factions and
are emitted once.

The addon resolves at scan time via UnitFactionGroup("player"), the same call
Modules/Mounts/Scanner.lua already uses for faction-gated mounts.
#>
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
    [string]$AttRoot = (Join-Path $env:TEMP "collectionist-att-12007"),
    [switch]$WhatIf
)

$ErrorActionPreference = "Stop"

$acqPath = Join-Path $RepoRoot "research/collectionist/sources/att-recipe-acquisition.csv"
$outPath = Join-Path $RepoRoot "addons/Collectionist/Modules/Recipes/Data/Trainers.lua"
$dataDir = Join-Path $RepoRoot "addons/Collectionist/Modules/Recipes/Data"
if (-not (Test-Path -LiteralPath $acqPath)) { throw "Missing $acqPath" }

$luajit = @(Get-Command luajit -ErrorAction Stop)[0].Source
$scriptDir = $PSScriptRoot
$work = Join-Path ([System.IO.Path]::GetTempPath()) ("collectionist-trainers-" + [guid]::NewGuid().ToString("N").Substring(0,8))
New-Item -ItemType Directory -Path $work -Force | Out-Null

# Capitals that mirror each other. A recipe taught in one is taught by the
# equivalent trainer in the other; only the coordinates differ.
$FACTION_PAIR = @{
    "85"   = @{ other = "84";   self = "horde"    }  # Orgrimmar    <-> Stormwind
    "88"   = @{ other = "87";   self = "horde"    }  # Thunder Bluff<-> Ironforge
    "90"   = @{ other = "89";   self = "horde"    }  # Undercity    <-> Darnassus
    "1165" = @{ other = "1161"; self = "horde"    }  # Dazar'alor   <-> Boralus
    "84"   = @{ other = "85";   self = "alliance" }
    "87"   = @{ other = "88";   self = "alliance" }
    "89"   = @{ other = "90";   self = "alliance" }
    "1161" = @{ other = "1165"; self = "alliance" }
}

$PROFESSIONS = @{
    "Alchemy" = 171; "Blacksmith" = 164; "Cooking" = 185; "Enchant" = 333
    "Engineer" = 202; "Inscription" = 773; "Jewelcraft" = 755
    "Leatherworking" = 165; "Tailor" = 197
}

$INV = [System.Globalization.CultureInfo]::InvariantCulture
function Format-Coord([double]$v) { return $v.ToString("0.####", $INV) }
function ConvertTo-LuaString([string]$v) {
    if ($null -eq $v) { $v = "" }
    return '"' + ($v -replace '\\', '\\\\' -replace '"', '\"') + '"'
}
function ConvertTo-Fraction($raw) {
    $d = 0.0
    if (-not [double]::TryParse([string]$raw, [System.Globalization.NumberStyles]::Float, $INV, [ref]$d)) { return $null }
    if ($d -le 0 -or $d -gt 100) { return $null }
    return [math]::Round($d / 100.0, 4)
}

try {
    Write-Host "Enumerating NPC nodes with their own coordinates..."
    $categoryFiles = Get-ChildItem -LiteralPath (Join-Path $AttRoot "db/Standard/Categories") -Filter *.lua |
        Sort-Object Name | ForEach-Object { $_.FullName }
    $npcCsv = Join-Path $work "npcs.csv"
    & $luajit (Join-Path $scriptDir "extract-att-sources.lua") "self:n" @categoryFiles |
        Set-Content -LiteralPath $npcCsv -Encoding UTF8

    Write-Host "Building name dictionary..."
    $namesCsv = Join-Path $work "names.csv"
    Get-ChildItem -LiteralPath (Join-Path $AttRoot ".contrib/Parser/DATAS") -Filter *.lua -Recurse |
        ForEach-Object { $_.FullName } |
        & $luajit (Join-Path $scriptDir "extract-att-names.lua") |
        Set-Content -LiteralPath $namesCsv -Encoding UTF8
    $names = @{}
    foreach ($row in (Import-Csv -LiteralPath $namesCsv)) {
        if ($row.kind -eq 'n') { $names[$row.id] = $row.name }
    }

    # (profession, map) -> trainer NPC. First one wins; a capital rarely has two
    # trainers for the same profession, and when it does either is fine.
    $trainerAt = @{}
    foreach ($row in (Import-Csv -LiteralPath $npcCsv)) {
        if (-not ($row.coord_x -and $row.map_id)) { continue }
        $nm = $names[$row.id]
        if (-not $nm -or $nm -notmatch 'Trainer') { continue }
        $prof = $null
        foreach ($p in $PROFESSIONS.Keys) { if ($nm -match $p) { $prof = $p; break } }
        if (-not $prof) { continue }
        $key = "$prof|$($row.map_id)"
        if ($trainerAt.ContainsKey($key)) { continue }
        $x = ConvertTo-Fraction $row.coord_x
        $y = ConvertTo-Fraction $row.coord_y
        if ($null -eq $x -or $null -eq $y) { continue }
        $trainerAt[$key] = @{ id = $row.id; name = $nm; map = $row.map_id; x = $x; y = $y; prof = $prof }
    }
    Write-Host ("  profession trainers with coordinates: {0}" -f $trainerAt.Count)

    # Only pin recipes the addon ships.
    $shipped = @{}
    foreach ($file in (Get-ChildItem -LiteralPath $dataDir -Filter *.lua)) {
        foreach ($line in [System.IO.File]::ReadLines($file.FullName)) {
            if ($line -match '\{\s*id\s*=\s*(\d+)\s*,') { $shipped[$Matches[1]] = $true }
        }
    }

    $entries = [System.Collections.Generic.List[object]]::new()
    $stats = [ordered]@{ paired = 0; neutral = 0; unpairable = 0; noTrainerNode = 0 }

    foreach ($row in (Import-Csv -LiteralPath $acqPath)) {
        if ($row.source_kind -ne 'trainer') { continue }
        if (-not $shipped.ContainsKey($row.recipe_spell_id)) { continue }
        if (-not ($row.map_id -and $row.coord_x)) { $stats.noTrainerNode++; continue }

        $nm = $names[$row.source_parent_id]
        $prof = $null
        if ($nm) { foreach ($p in $PROFESSIONS.Keys) { if ($nm -match $p) { $prof = $p; break } } }
        if (-not $prof) { $stats.noTrainerNode++; continue }

        $x = ConvertTo-Fraction $row.coord_x
        $y = ConvertTo-Fraction $row.coord_y
        if ($null -eq $x -or $null -eq $y) { $stats.noTrainerNode++; continue }
        $own = @{ map = $row.map_id; x = $x; y = $y; name = $nm }

        $pair = $FACTION_PAIR[$row.map_id]
        if (-not $pair) {
            # Neutral hub, or a zone with no faction mirror: one pin for everyone.
            $entries.Add([pscustomobject]@{ id = [int]$row.recipe_spell_id; neutral = $own })
            $stats.neutral++
            continue
        }

        $otherKey = "$prof|$($pair.other)"
        $other = $trainerAt[$otherKey]
        if (-not $other) {
            # Known trainer, but the mirror capital has no same-profession node
            # in ATT. Emitting the one we have would misroute the other faction,
            # so emit it faction-scoped and let the other side fall back to the
            # open-profession click.
            $e = [pscustomobject]@{ id = [int]$row.recipe_spell_id; alliance = $null; horde = $null }
            $e.($pair.self) = $own
            $entries.Add($e)
            $stats.unpairable++
            continue
        }

        $mirror = @{ map = $other.map; x = $other.x; y = $other.y; name = $other.name }
        $e = [pscustomobject]@{ id = [int]$row.recipe_spell_id; alliance = $null; horde = $null }
        $e.($pair.self) = $own
        $e.($(if ($pair.self -eq 'horde') { 'alliance' } else { 'horde' })) = $mirror
        $entries.Add($e)
        $stats.paired++
    }

    function Format-Tuple($t) {
        return '{ ' + $t.map + ', ' + (Format-Coord $t.x) + ', ' + (Format-Coord $t.y) + ', ' +
               (ConvertTo-LuaString $t.name) + ' }'
    }

    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine('local _, MC = ...')
    [void]$sb.AppendLine()
    [void]$sb.AppendLine('-- GENERATED FILE - do not edit.')
    [void]$sb.AppendLine('-- Regenerate: scripts/generate-collectionist-recipe-trainers.ps1')
    [void]$sb.AppendLine('--')
    [void]$sb.AppendLine('-- Trainer-taught recipes, resolved per faction at scan time.')
    [void]$sb.AppendLine('--')
    [void]$sb.AppendLine('-- ATT records each recipe under one faction''s trainer only, so pinning')
    [void]$sb.AppendLine('-- its coordinates directly would send Alliance players to Orgrimmar. Each')
    [void]$sb.AppendLine('-- entry below therefore carries the trainer for each faction, paired by')
    [void]$sb.AppendLine('-- mirrored capital. `n` is a neutral hub that serves both.')
    [void]$sb.AppendLine()
    # Group by trainer pair. A capital's Alchemy trainer teaches hundreds of
    # recipes, so repeating the tuple per recipe would be ~20x larger than
    # listing each pair once with its recipe IDs.
    $groups = [ordered]@{}
    foreach ($e in $entries) {
        $parts = @()
        if ($e.PSObject.Properties.Name -contains 'neutral' -and $e.neutral) {
            $parts += 'n = ' + (Format-Tuple $e.neutral)
        } else {
            if ($e.alliance) { $parts += 'a = ' + (Format-Tuple $e.alliance) }
            if ($e.horde)    { $parts += 'h = ' + (Format-Tuple $e.horde) }
        }
        $sig = $parts -join ', '
        if (-not $groups.Contains($sig)) { $groups[$sig] = [System.Collections.Generic.List[int]]::new() }
        $groups[$sig].Add($e.id)
    }

    [void]$sb.AppendLine('MC.RecipeTrainers = {}')
    [void]$sb.AppendLine('local T = MC.RecipeTrainers')
    [void]$sb.AppendLine()
    [void]$sb.AppendLine('-- One row per trainer pair, followed by the recipes that trainer teaches.')
    [void]$sb.AppendLine('for _, g in ipairs({')
    foreach ($sig in ($groups.Keys | Sort-Object)) {
        $ids = ($groups[$sig] | Sort-Object) -join ', '
        [void]$sb.AppendLine('    { { ' + $sig + ' }, ' + $ids + ' },')
    }
    [void]$sb.AppendLine('}) do')
    [void]$sb.AppendLine('    local e = g[1]')
    [void]$sb.AppendLine('    for i = 2, #g do T[g[i]] = e end')
    [void]$sb.AppendLine('end')
    [void]$sb.AppendLine()
    [void]$sb.AppendLine('-- Returns the waypoint for this character''s faction, or nil when only the')
    [void]$sb.AppendLine('-- other faction has a known trainer (the row then keeps its normal')
    [void]$sb.AppendLine('-- open-the-profession click).')
    [void]$sb.AppendLine('function MC.RecipeTrainerWaypoint(recipeID)')
    [void]$sb.AppendLine('    local e = recipeID and T[recipeID]')
    [void]$sb.AppendLine('    if not e then return nil end')
    [void]$sb.AppendLine('    if e.n then return e.n end')
    [void]$sb.AppendLine('    -- UnitFactionGroup is absent outside the client (tests, /reload')
    [void]$sb.AppendLine('    -- ordering); prefer Alliance-or-Horde rather than returning nil.')
    [void]$sb.AppendLine('    local faction = UnitFactionGroup and UnitFactionGroup("player")')
    [void]$sb.AppendLine('    if faction == "Alliance" then return e.a or nil end')
    [void]$sb.AppendLine('    if faction == "Horde" then return e.h or nil end')
    [void]$sb.AppendLine('    return e.a or e.h')
    [void]$sb.AppendLine('end')

    if (-not $WhatIf) {
        $utf8 = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText($outPath, ($sb.ToString() -replace "`r`n", "`n"), $utf8)
    }

    Write-Host ""
    Write-Host ("Trainer entries: {0}" -f $entries.Count)
    $stats.GetEnumerator() | ForEach-Object { Write-Host ("  {0,-15} {1}" -f $_.Key, $_.Value) }
    if (-not $WhatIf) { Write-Host ("Wrote {0}" -f $outPath) } else { Write-Host "(-WhatIf)" }
}
finally {
    if (Test-Path -LiteralPath $work) { Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue }
}
