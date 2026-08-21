<#
.SYNOPSIS
Emits Modules/Recipes/Data/Waypoints.lua - clickable map pins for recipes.

.DESCRIPTION
The acquisition pipeline already resolved coordinates for thousands of recipes
but only ever wrote them into tooltip prose. This turns them into real
waypoints, so clicking a recipe row drops a marker the way clicking a rare or
a treasure already does.

Why a separate generated file rather than inline `waypoint =` fields:
apply-collectionist-recipe-acquisition.ps1 is safe to re-run only because its
anchor is self-consuming - it matches source="unknown" and overwrites it. That
pass has already run, so no placeholder remains. Inline waypoints would need a
second line-rewriting pass with a different anchor, and after any generator
re-emit both would have to run in the right order. One whole-file artifact that
no other generator owns is the safer shape.

SCOPE - trainers are deliberately excluded here.
ATT nests each recipe under only ONE faction's trainer, so recipe-anchored
extraction yields 1,291 Horde-capital rows against 20 Alliance. Attaching those
would route Alliance players into Orgrimmar. Trainers need faction pairing from
an NPC-level extraction, which is a separate generator.

Also skipped: worlddrop, pvp, specialization and discovery (no fixed location
to point at) and unavailable (a pin to unobtainable content is a bug).
#>
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
    [string]$AcquisitionCsv,
    [switch]$WhatIf
)

$ErrorActionPreference = "Stop"

if (-not $AcquisitionCsv) {
    $AcquisitionCsv = Join-Path $RepoRoot "research/collectionist/sources/att-recipe-acquisition.csv"
}
if (-not (Test-Path -LiteralPath $AcquisitionCsv)) {
    throw "Missing $AcquisitionCsv - run generate-collectionist-recipe-acquisition.ps1 first"
}

$outPath = Join-Path $RepoRoot "addons/Collectionist/Modules/Recipes/Data/Waypoints.lua"
$dataDir = Join-Path $RepoRoot "addons/Collectionist/Modules/Recipes/Data"

# Only pin a recipe the addon actually ships.
$shipped = @{}
foreach ($file in (Get-ChildItem -LiteralPath $dataDir -Filter *.lua)) {
    foreach ($line in [System.IO.File]::ReadLines($file.FullName)) {
        if ($line -match '\{\s*id\s*=\s*(\d+)\s*,') { $shipped[$Matches[1]] = $true }
    }
}
Write-Host ("Shipped recipe IDs: {0}" -f $shipped.Count)

$ATTACH_KINDS  = @('vendor', 'quest', 'treasure', 'drop')
$PARENT_KINDS  = @('n', 'inst', 'q', 'o')

# Lua needs a dot. On a comma-locale machine .NET renders 0.4351 as "0,4351",
# which is a syntax error that only reproduces on someone else's box - and no
# generator in this repo has ever emitted a decimal before.
$INV = [System.Globalization.CultureInfo]::InvariantCulture
function Format-Coord([double]$value) { return $value.ToString("0.####", $INV) }

function ConvertTo-LuaString([string]$value) {
    if ($null -eq $value) { $value = "" }
    return '"' + ($value -replace '\\', '\\\\' -replace '"', '\"') + '"'
}

# ATT stores 0-100 percentages; Collectionist waypoints are 0-1 fractions
# (Data/Locations.lua:3).
function ConvertTo-Fraction($raw) {
    $d = 0.0
    if (-not [double]::TryParse([string]$raw, [System.Globalization.NumberStyles]::Float, $INV, [ref]$d)) { return $null }
    if ($d -le 0 -or $d -gt 100) { return $null }
    return [math]::Round($d / 100.0, 4)
}

$rows = @(Import-Csv -LiteralPath $AcquisitionCsv)

$locations = [ordered]@{}   # tuple signature -> @{ map; spawns; name; ids }
$skipped = [ordered]@{}

foreach ($row in $rows) {
    $id = $row.recipe_spell_id
    if (-not $shipped.ContainsKey($id)) { continue }

    $kind = $row.source_kind
    if ($ATTACH_KINDS -notcontains $kind) {
        if (-not $skipped.Contains($kind)) { $skipped[$kind] = 0 }
        $skipped[$kind]++
        continue
    }
    if ($PARENT_KINDS -notcontains $row.source_parent_kind) {
        if (-not $skipped.Contains("no-parent")) { $skipped["no-parent"] = 0 }
        $skipped["no-parent"]++
        continue
    }
    if (-not $row.source_parent_name) {
        if (-not $skipped.Contains("unnamed")) { $skipped["unnamed"] = 0 }
        $skipped["unnamed"]++
        continue
    }

    # MC.AddWaypoint rejects mapID <= 0 (Core.lua:1182); omit rather than emit.
    $map = 0
    if (-not [int]::TryParse([string]$row.map_id, [ref]$map)) { continue }
    if ($map -le 0) { continue }

    $x = ConvertTo-Fraction $row.coord_x
    $y = ConvertTo-Fraction $row.coord_y
    if ($null -eq $x -or $null -eq $y) { continue }

    $spawns = @(, @($x, $y))
    if ($row.extra_spawns) {
        foreach ($pair in ($row.extra_spawns -split ';')) {
            $bits = $pair -split ','
            if ($bits.Count -ne 2) { continue }
            $ex = ConvertTo-Fraction $bits[0]
            $ey = ConvertTo-Fraction $bits[1]
            if ($null -ne $ex -and $null -ne $ey) { $spawns += , @($ex, $ey) }
        }
    }

    # Key by the coordinates themselves, not by parent id. Parent keys are not
    # unique - difficulty and encounter ids are global, so one key could map to
    # two unrelated places.
    $sig = "$map|" + (($spawns | ForEach-Object { (Format-Coord $_[0]) + ',' + (Format-Coord $_[1]) }) -join ';')
    if (-not $locations.Contains($sig)) {
        $locations[$sig] = @{
            map    = $map
            spawns = $spawns
            name   = $row.source_parent_name
            ids    = [System.Collections.Generic.List[int]]::new()
        }
    }
    $locations[$sig].ids.Add([int]$id)
}

$pinned = ($locations.Values | ForEach-Object { $_.ids.Count } | Measure-Object -Sum).Sum

$sb = [System.Text.StringBuilder]::new()
[void]$sb.AppendLine('local _, MC = ...')
[void]$sb.AppendLine()
[void]$sb.AppendLine('-- GENERATED FILE - do not edit.')
[void]$sb.AppendLine('-- Regenerate: scripts/generate-collectionist-recipe-waypoints.ps1')
[void]$sb.AppendLine('--')
[void]$sb.AppendLine('-- recipe spell ID -> { mapID, x, y, "Label" }, matching the shape used by')
[void]$sb.AppendLine('-- MC.LOC / MC.RareNPCs / MC.TreasureCoords. Attached at scan time by')
[void]$sb.AppendLine('-- Modules/Recipes/Scanner.lua; a hand-written waypoint on the recipe wins.')
[void]$sb.AppendLine('--')
[void]$sb.AppendLine('-- Grouped one entry per LOCATION rather than per recipe: the same vendor')
[void]$sb.AppendLine('-- backs up to a hundred recipes, so this stays diffable by place and holds')
[void]$sb.AppendLine('-- one table per location instead of one per recipe.')
[void]$sb.AppendLine('--')
[void]$sb.AppendLine('-- Map IDs are raw uiMapIDs, not MC.MAP constants: many of these zones have')
[void]$sb.AppendLine('-- no constant, and a generated file gains nothing from the symbol.')
[void]$sb.AppendLine('-- Trainer-taught recipes are NOT here - see Data/Trainers.lua.')
[void]$sb.AppendLine()
[void]$sb.AppendLine('MC.RecipeWaypoints = {}')
[void]$sb.AppendLine('local W = MC.RecipeWaypoints')
[void]$sb.AppendLine()
[void]$sb.AppendLine('for _, g in ipairs({')

foreach ($loc in ($locations.Values | Sort-Object { $_.map }, { $_.name })) {
    $label = ConvertTo-LuaString $loc.name
    if ($loc.spawns.Count -eq 1) {
        $wp = '{ ' + $loc.map + ', ' + (Format-Coord $loc.spawns[0][0]) + ', ' +
              (Format-Coord $loc.spawns[0][1]) + ', ' + $label + ' }'
    } else {
        # A list of tuples means "N possible locations" to MC.GetSmartWaypoint.
        $parts = foreach ($s in $loc.spawns) {
            '{ ' + $loc.map + ', ' + (Format-Coord $s[0]) + ', ' + (Format-Coord $s[1]) + ', ' + $label + ' }'
        }
        $wp = '{ ' + ($parts -join ', ') + ' }'
    }
    $ids = ($loc.ids | Sort-Object) -join ', '
    [void]$sb.AppendLine('    { ' + $wp + ', ' + $ids + ' },')
}

[void]$sb.AppendLine('}) do')
[void]$sb.AppendLine('    local wp = g[1]')
[void]$sb.AppendLine('    for i = 2, #g do W[g[i]] = wp end')
[void]$sb.AppendLine('end')

if (-not $WhatIf) {
    $utf8 = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($outPath, ($sb.ToString() -replace "`r`n", "`n"), $utf8)
}

Write-Host ""
Write-Host ("Locations : {0}" -f $locations.Count)
Write-Host ("Recipes pinned: {0}" -f $pinned)
Write-Host ("Multi-spawn locations: {0}" -f (($locations.Values | Where-Object { $_.spawns.Count -gt 1 }).Count))
if (-not $WhatIf) { Write-Host ("Wrote {0}" -f $outPath) } else { Write-Host "(-WhatIf: nothing written)" }
Write-Host ""
Write-Host "Skipped:"
$skipped.GetEnumerator() | Sort-Object Value -Descending | ForEach-Object {
    Write-Host ("  {0,-16} {1}" -f $_.Key, $_.Value)
}
