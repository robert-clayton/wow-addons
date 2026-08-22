<#
.SYNOPSIS
Emits Modules/Recipes/Data/AttGaps.lua - recipes missing from the catalog.

.DESCRIPTION
research/collectionist/sources/att-recipe-gap-audit.csv identifies 465 recipes
that exist in current DB2 and in ATT but are absent from Collectionist. All 465
already resolve to a real acquisition source through
att-recipe-acquisition.csv, so the audit's `needs_att_source_ancestry` blocker
is already lifted.

EXPANSION PLACEMENT is by trade category, matching how every one of the 9,918
shipped recipes was placed: all eleven generate-collectionist-*-id-inventory.ps1
build $allowedTradeCategories by walking TradeSkillCategory.ParentTradeSkillCategoryID
from per-expansion roots and filter SkillLineAbility by membership. The audit's
`category_expansion_hint` derives from the same TradeSkillCategory tree, so it
agrees with those root sets by construction.

ATT's `awp` patch stamp is deliberately NOT used. Measured against trade
category it disagrees on 86% of rows and places nothing in vanilla, because awp
began with the 2.0 convention and pre-TBC content inherits whatever later patch
last touched its zone. Disagreements are reported below as a diagnostic.

NEVER-IMPLEMENTED rows are excluded. 64 of the 465 resolve to ATT's
NeverImplemented bucket - including 55 of the 61 "Legion gaps" - and shipping
them would permanently inflate every completion denominator with content that
was never released.

A separate file rather than edits to the per-expansion files: those ten are
rewritten wholesale by their generators (and TWW has none at all), so hand-added
rows would be destroyed. This follows the DB2Gaps.lua precedent, which likewise
issues several RegisterContent calls with different expansion keys from one file.
#>
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
    [switch]$IncludeNeverImplemented,
    [switch]$WhatIf
)

$ErrorActionPreference = "Stop"

$gapPath = Join-Path $RepoRoot "research/collectionist/sources/att-recipe-gap-audit.csv"
$acqPath = Join-Path $RepoRoot "research/collectionist/sources/att-recipe-acquisition.csv"
$outPath = Join-Path $RepoRoot "addons/Collectionist/Modules/Recipes/Data/AttGaps.lua"
$dataDir = Join-Path $RepoRoot "addons/Collectionist/Modules/Recipes/Data"
foreach ($p in @($gapPath, $acqPath)) { if (-not (Test-Path -LiteralPath $p)) { throw "Missing $p" } }

# The audit uses descriptive names; the addon uses short keys
# (Data/Expansions.lua).
$EXPANSION_KEY = @{
    "classic" = "vanilla"; "tbc" = "tbc"; "wrath" = "wrath"
    "cataclysm" = "cata"; "mists_of_pandaria" = "mop"; "wod" = "wod"
    "legion" = "legion"; "battle_for_azeroth" = "bfa"
    "shadowlands" = "shadowlands"; "dragonflight" = "df"
    "tww" = "tww"; "midnight" = "midnight"
}
# profession_id in the audit IS the addon's skillLine - no translation needed.
$PROFESSION_LABEL = @{
    171 = "Alchemy"; 164 = "Blacksmithing"; 185 = "Cooking"; 333 = "Enchanting"
    202 = "Engineering"; 773 = "Inscription"; 755 = "Jewelcrafting"
    165 = "Leatherworking"; 197 = "Tailoring"
}
$EXPANSION_LABEL = @{
    "vanilla" = "Classic"; "tbc" = "The Burning Crusade"; "wrath" = "Wrath of the Lich King"
    "cata" = "Cataclysm"; "mop" = "Pandaria"; "wod" = "Warlords of Draenor"
    "legion" = "Legion"; "bfa" = "Battle for Azeroth"; "shadowlands" = "Shadowlands"
    "df" = "Dragonflight"; "tww" = "The War Within"; "midnight" = "Midnight"
}

function ConvertTo-LuaString([string]$v) {
    if ($null -eq $v) { $v = "" }
    return '"' + ($v -replace '\\', '\\\\' -replace '"', '\"') + '"'
}

# Same prose shape as apply-collectionist-recipe-acquisition.ps1, so these rows
# read identically to the enriched ones beside them.
function Get-SourceInfo($row) {
    $name = $row.source_parent_name
    switch ($row.source_kind) {
        "trainer"        { if ($name) { return $name }; return "Trained from your profession trainer" }
        "vendor"         { if ($name) { return $name }; return "Purchased from a vendor" }
        "drop"           { if ($name) { return $name }; return "Drops from creatures" }
        "worlddrop"      { return "World drop" }
        "quest"          { if ($name) { return "Quest: $name" }; return "Quest reward" }
        "discovery"      { if ($name) { return "Discovery: $name" }; return "Discovered while crafting" }
        "specialization" { if ($name) { return $name }; return "Profession specialization" }
        "treasure"       { if ($name) { return $name }; return "Found in the world" }
        "pvp"            { if ($name) { return $name }; return "PvP reward" }
        "unavailable"    { return "Not obtainable" }
        default          { return $null }
    }
}

$acq = @{}
foreach ($row in (Import-Csv -LiteralPath $acqPath)) { $acq[$row.recipe_spell_id] = $row }

# Guard against re-adding something already shipped: tests/run.lua asserts
# global cross-expansion spell-ID uniqueness.
$shipped = @{}
foreach ($file in (Get-ChildItem -LiteralPath $dataDir -Filter *.lua)) {
    if ($file.Name -eq "AttGaps.lua") { continue }
    foreach ($line in [System.IO.File]::ReadLines($file.FullName)) {
        if ($line -match '\{\s*id\s*=\s*(\d+)\s*,') { $shipped[$Matches[1]] = $true }
    }
}

$gaps = @(Import-Csv -LiteralPath $gapPath |
    Where-Object { $_.decision -eq 'confirmed_recipe_gap_needs_source_placement' })

$rows = [System.Collections.Generic.List[object]]::new()
$stats = [ordered]@{ neverImplemented = 0; alreadyShipped = 0; noSource = 0; noExpansion = 0; noProfession = 0 }
$awpDisagree = 0

foreach ($gap in $gaps) {
    $id = $gap.recipe_spell_id
    if ($shipped.ContainsKey($id)) { $stats.alreadyShipped++; continue }

    $a = $acq[$id]
    if (-not $a -or -not $a.source_kind -or $a.source_kind -eq 'unknown') { $stats.noSource++; continue }
    if ($a.source_kind -eq 'unavailable' -and -not $IncludeNeverImplemented) {
        $stats.neverImplemented++; continue
    }

    $expKey = $EXPANSION_KEY[$gap.category_expansion_hint]
    if (-not $expKey) { $stats.noExpansion++; continue }

    $skillLine = 0
    if (-not [int]::TryParse([string]$gap.profession_id, [ref]$skillLine)) { $stats.noProfession++; continue }
    if (-not $PROFESSION_LABEL.ContainsKey($skillLine)) { $stats.noProfession++; continue }

    $info = Get-SourceInfo $a
    if (-not $info) { $stats.noSource++; continue }

    # Diagnostic only: how often would awp have placed this differently?
    $awp = if ($a.awp_own) { $a.awp_own } else { $a.awp_ancestor }
    if ($awp -and $awp.Length -ge 5) {
        $major = [int]$awp.Substring(0, $awp.Length - 4)
        $awpKey = @("", "vanilla","tbc","wrath","cata","mop","wod","legion","bfa","shadowlands","df","tww","midnight")[$major]
        if ($awpKey -and $awpKey -ne $expKey) { $awpDisagree++ }
    }

    $rows.Add([pscustomobject]@{
        id = [int]$id; name = $gap.name; expansion = $expKey
        skillLine = $skillLine; source = $a.source_kind; sourceInfo = $info
    })
}

$sb = [System.Text.StringBuilder]::new()
[void]$sb.AppendLine('local _, MC = ...')
[void]$sb.AppendLine()
[void]$sb.AppendLine('-- GENERATED FILE - do not edit.')
[void]$sb.AppendLine('-- Regenerate: scripts/generate-collectionist-recipe-att-gaps.ps1')
[void]$sb.AppendLine('--')
[void]$sb.AppendLine('-- Recipes present in current DB2 and in All The Things but absent from the')
[void]$sb.AppendLine('-- per-expansion catalogs. Kept in their own file because those ten files are')
[void]$sb.AppendLine('-- rewritten wholesale by their generators, and The War Within has none.')
[void]$sb.AppendLine('--')
[void]$sb.AppendLine('-- Expansion follows trade-category membership, the same signal that placed')
[void]$sb.AppendLine('-- every other recipe in the catalog. Never-implemented rows are excluded.')
[void]$sb.AppendLine()

foreach ($expGroup in ($rows | Group-Object expansion | Sort-Object Name)) {
    $expKey = $expGroup.Name
    [void]$sb.AppendLine(('MC.RegisterContent({0}, "recipes", {{' -f (ConvertTo-LuaString $expKey)))
    foreach ($sl in ($expGroup.Group | Group-Object skillLine | Sort-Object { [int]$_.Name })) {
        # Plain expansion label. The category name is not rendered today
        # (Modules/Recipes/UI.lua groups by source, not category), but tagging
        # it with the tool that produced it would leak an implementation
        # detail into data for no benefit if that ever changes.
        $label = $EXPANSION_LABEL[$expKey]
        [void]$sb.AppendLine(('    {{ skillLine = {0}, name = {1}, recipes = {{ -- {2}: {3}' -f
            $sl.Name, (ConvertTo-LuaString $label), $PROFESSION_LABEL[[int]$sl.Name], $sl.Count))
        foreach ($r in ($sl.Group | Sort-Object id)) {
            [void]$sb.AppendLine(('        {{ id = {0}, name = {1}, source = {2}, sourceInfo = {3} }},' -f
                $r.id, (ConvertTo-LuaString $r.name), (ConvertTo-LuaString $r.source), (ConvertTo-LuaString $r.sourceInfo)))
        }
        [void]$sb.AppendLine('    } },')
    }
    [void]$sb.AppendLine('})')
    [void]$sb.AppendLine()
}

if (-not $WhatIf) {
    $utf8 = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($outPath, ($sb.ToString() -replace "`r`n", "`n"), $utf8)
}

Write-Host ("Candidates: {0}   ingesting: {1}" -f $gaps.Count, $rows.Count)
$stats.GetEnumerator() | Where-Object { $_.Value -gt 0 } | ForEach-Object {
    Write-Host ("  excluded {0,-18} {1}" -f $_.Key, $_.Value)
}
Write-Host ""
Write-Host "Per expansion (bump the tests/run.lua pins by these):"
$rows | Group-Object expansion | Sort-Object Name | ForEach-Object {
    Write-Host ("  {0,-13} {1}" -f $_.Name, $_.Count)
}
Write-Host ""
Write-Host "Per profession:"
$rows | Group-Object skillLine | Sort-Object { [int]$_.Name } | ForEach-Object {
    Write-Host ("  {0,-16} {1}" -f $PROFESSION_LABEL[[int]$_.Name], $_.Count)
}
Write-Host ""
Write-Host ("DIAGNOSTIC: awp would have placed {0} of {1} rows differently ({2:P0}) - not acted on." -f
    $awpDisagree, $rows.Count, ($(if ($rows.Count) { $awpDisagree / $rows.Count } else { 0 })))
if (-not $WhatIf) { Write-Host ("Wrote {0}" -f $outPath) } else { Write-Host "(-WhatIf)" }
