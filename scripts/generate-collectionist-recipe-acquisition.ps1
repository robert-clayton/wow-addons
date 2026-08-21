<#
.SYNOPSIS
Resolves an acquisition source for every recipe Collectionist ships without one.

.DESCRIPTION
Roughly 90% of the shipped recipe catalog carries source="unknown". That is not
a bug in the addon: DB2 has no acquisition column for recipes. Mount,
BattlePetSpecies and Toy each ship a SourceText_lang that the mount/pet/toy
generators pass straight through; SkillLineAbility offers only AcquireMethod,
a binary "granted with the profession" flag. So the data was never sourced.

All The Things does carry it, under a permissive licence, and this repo already
cites ATT as the basis for its mount and pet source text. Two independent
signals are combined here:

  Signal A  .contrib/Parser/DATAS/00 - Profession DB/<Prof>.lua
            Acquisition CLASS per recipe, from "--- HEADER ---" sections:
            TRAINER / ITEM / DISCOVERY / SPECIALIZATION / QUEST / NYI.

  Signal B  db/Standard/Categories/*.lua compiled tree ancestry
            The SPECIFIC source: vendor NPC, boss, quest or object, plus map
            and coordinates. Extracted by extract-att-sources.lua.

Signal A decides the source key; Signal B supplies the prose and waypoint.
That order matters. ATT's compiled tree does not enumerate retail trainers per
recipe, so deriving the key from ancestry alone would misfile ~2,700
trainer-taught recipes as vendor purchases. Signal A knows they are trainer.

Coverage measured against the live catalog: 8,982 of 8,984 (99.98%).

.PARAMETER AttRoot
The All The Things checkout. Defaults to the same %TEMP% location the other
generators use. NOTE: that location is transient and no commit is recorded -
pin the SHA in research/collectionist/sources/README.md before relying on a
rebuild being reproducible.
#>
param(
    [string]$AttRoot = (Join-Path $env:TEMP "collectionist-att-12007"),
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
    [string]$OutFile
)

$ErrorActionPreference = "Stop"

if (-not $OutFile) {
    $OutFile = Join-Path $RepoRoot "research/collectionist/sources/att-recipe-acquisition.csv"
}
foreach ($required in @(
    $AttRoot,
    (Join-Path $AttRoot "db/Standard/Categories"),
    (Join-Path $AttRoot ".contrib/Parser/DATAS/00 - Profession DB")
)) {
    if (-not (Test-Path -LiteralPath $required)) { throw "Missing input directory: $required" }
}

function Assert-Equal($actual, $expected, $label) {
    if ($actual -ne $expected) { throw "$label`: expected $expected, got $actual" }
}

$luajit = @(Get-Command luajit -ErrorAction Stop)[0].Source
$scriptDir = $PSScriptRoot
$work = Join-Path ([System.IO.Path]::GetTempPath()) ("collectionist-recipe-acq-" + [guid]::NewGuid().ToString("N").Substring(0, 8))
New-Item -ItemType Directory -Path $work -Force | Out-Null

try {
    # ---------------------------------------------------------------- Signal B
    Write-Host "Extracting source ancestry from compiled categories..."
    $categoryFiles = Get-ChildItem -LiteralPath (Join-Path $AttRoot "db/Standard/Categories") -Filter *.lua |
        Sort-Object Name | ForEach-Object { $_.FullName }
    $ancestryCsv = Join-Path $work "ancestry.csv"
    & $luajit (Join-Path $scriptDir "extract-att-sources.lua") "r" @categoryFiles |
        Set-Content -LiteralPath $ancestryCsv -Encoding UTF8
    if ($LASTEXITCODE -ne 0) { throw "extract-att-sources.lua failed" }

    $ancestry = @{}
    foreach ($row in (Import-Csv -LiteralPath $ancestryCsv)) {
        if (-not $ancestry.ContainsKey($row.id)) { $ancestry[$row.id] = [System.Collections.Generic.List[object]]::new() }
        $ancestry[$row.id].Add($row)
    }
    Write-Host ("  {0} occurrences over {1} recipes" -f (Import-Csv -LiteralPath $ancestryCsv).Count, $ancestry.Count)

    # ------------------------------------------------------------------ Names
    Write-Host "Building name dictionary from DATAS..."
    $namesCsv = Join-Path $work "names.csv"
    Get-ChildItem -LiteralPath (Join-Path $AttRoot ".contrib/Parser/DATAS") -Filter *.lua -Recurse |
        ForEach-Object { $_.FullName } |
        & $luajit (Join-Path $scriptDir "extract-att-names.lua") |
        Set-Content -LiteralPath $namesCsv -Encoding UTF8
    $names = @{}
    foreach ($row in (Import-Csv -LiteralPath $namesCsv)) { $names[$row.kind + ":" + $row.id] = $row.name }
    Write-Host ("  {0} names" -f $names.Count)

    # ---------------------------------------------------------------- Signal A
    Write-Host "Reading acquisition classes from the profession DB..."
    $class = @{}
    $recipeItem = @{}
    foreach ($file in (Get-ChildItem -LiteralPath (Join-Path $AttRoot ".contrib/Parser/DATAS/00 - Profession DB") -Filter *.lua)) {
        $current = $null
        foreach ($line in [System.IO.File]::ReadLines($file.FullName)) {
            # "--- TRAINER ---". Separator rules ("-----------") match the same
            # shape, so require at least one letter.
            if ($line -match '^---\s*(.+?)\s*---\s*$') {
                $candidate = $Matches[1].Trim()
                if ($candidate -match '[A-Za-z]') { $current = $candidate }
                continue
            }
            if ($line -match '^\s*i\(\s*(\d+)\s*,\s*(\d+)\s*\)') {
                $class[$Matches[2]] = $current
                $recipeItem[$Matches[2]] = $Matches[1]
            }
        }
    }
    Write-Host ("  {0} classified recipes" -f $class.Count)

    # -------------------------------------------------------- Header constants
    $header = @{}
    foreach ($line in [System.IO.File]::ReadLines((Join-Path $AttRoot "db/Standard/LocalizationDB.lua"))) {
        if ($line -match '^\s+([A-Z][A-Z0-9_]*)\s*=\s*(-\d+),?\s*$') { $header[$Matches[2]] = $Matches[1] }
    }
    Assert-Equal ($header.Count -gt 100) $true "header constant count"

    # Specialization sub-headers are named per craft (ARMORSMITH, DRAGONSCALE,
    # MOONCLOTH...) rather than carrying a generic SPECIALIZATION label.
    $specHeaders = @(
        "SPECIALIZATION", "SPECIALIZATIONS", "ARMORSMITH", "WEAPONSMITH", "AXESMITH",
        "HAMMERSMITH", "SWORDSMITH", "DRAGONSCALE", "ELEMENTAL", "TRIBAL",
        "MOONCLOTH", "SHADOWEAVE", "SPELLFIRE", "GEMCUTTER", "TRANSMUTATION",
        "POTION", "ELIXIR", "GOBLIN", "GNOMISH", "WILD/METICULOUS"
    )

    function Get-HeaderNames($ancestryString) {
        $out = @()
        foreach ($part in ($ancestryString -split '>')) {
            $bits = $part -split ':'
            if ($bits.Count -eq 2 -and ($bits[0] -eq 'h' -or $bits[0] -eq 'ah')) {
                if ($header.ContainsKey($bits[1])) { $out += $header[$bits[1]] }
            }
        }
        return ($out -join ',')
    }

    # Several ATT nodes can grant the same recipe. Prefer the route a player can
    # rely on: a vendor you can walk to beats a random world drop.
    $kindRank = @{ vendor = 1; quest = 2; treasure = 3; drop = 4; worlddrop = 5; pvp = 6 }

    function Get-SourceKindFromAncestry($row) {
        $headers = Get-HeaderNames $row.ancestry
        $file = $row.att_file
        $parent = $row.source_parent_kind
        if ($file -eq "NeverImplemented.lua") { return "unavailable" }
        if ($headers -match 'VENDORS|COMMON_VENDOR_ITEMS|BLACK_MARKET') { return "vendor" }
        if ($file -eq "WorldDrops.lua" -or $headers -match 'WORLD_DROPS') { return "worlddrop" }
        if ($parent -eq 'q' -or $headers -match 'QUESTS') { return "quest" }
        if ($file -eq "PVP.lua") { return "pvp" }
        if ($parent -eq 'o') { return "treasure" }
        if ($parent -eq 'e' -or $parent -eq 'inst' -or $file -eq "Instances.lua" `
            -or $headers -match 'DROPS|COMMON_BOSS_DROPS|ZONE_DROPS') { return "drop" }
        if ($parent -eq 'n') { return "vendor" }
        return "drop"
    }

    # ------------------------------------------------------------------- Join
    Write-Host "Joining..."
    $out = [System.Collections.Generic.List[object]]::new()
    $ids = @($class.Keys) + @($ancestry.Keys) | Sort-Object -Unique { [int]$_ }

    foreach ($id in $ids) {
        $attClass = $class[$id]
        $occurrences = $ancestry[$id]

        # Signal A decides the key where it speaks. "ITEM" means "the recipe
        # item has its own source" -- it defers to the ancestry.
        $signalAKind = switch -Regex ($attClass) {
            '^NYI$'                { "unavailable"; break }
            '^TRAINER$'            { "trainer"; break }
            '^DISCOVERY$'          { "discovery"; break }
            '^QUESTS?$'            { "quest"; break }
            # LEGENDARY (ATT ships both spellings) describes what the item IS,
            # not how it is obtained -- Shadowlands runecarving recipes under
            # that header are learned from a trainer, not looted. Defer to the
            # ancestry, which is the more specific signal.
            default {
                if ($attClass -and $specHeaders -contains $attClass) { "specialization" } else { $null }
            }
        }

        # Choose the occurrence to quote. Ranking by ancestry alone will happily
        # hand a TRAINER-class recipe a vendor node, so the prose ends up
        # describing a different route than the key names. Prefer an occurrence
        # whose own ancestry agrees with the final key; fall back to rank.
        $best = $null; $bestKind = $null; $bestRank = 99; $agreeing = $null
        if ($occurrences) {
            foreach ($occ in $occurrences) {
                $k = Get-SourceKindFromAncestry $occ
                if ($signalAKind -and $k -eq $signalAKind -and
                    (-not $agreeing -or (-not $agreeing.coord_x -and $occ.coord_x))) {
                    $agreeing = $occ
                }
                $rank = if ($kindRank.ContainsKey($k)) { $kindRank[$k] } else { 9 }
                if ($rank -lt $bestRank -or ($rank -eq $bestRank -and -not $best.coord_x -and $occ.coord_x)) {
                    $best = $occ; $bestKind = $k; $bestRank = $rank
                }
            }
        }
        if ($agreeing) { $best = $agreeing }

        $kind = if ($signalAKind) { $signalAKind }
                elseif ($bestKind) { $bestKind }
                else { "unknown" }

        # Name the thing the key is about. A quest-sourced recipe nested under
        # an item node should quote the QUEST, not the item; a vendor purchase
        # should quote the NPC. Walk the chosen ancestry for the alias that
        # matches, and only fall back to the immediate parent.
        $preferAlias = switch ($kind) {
            "vendor"    { "n" }
            "trainer"   { "n" }
            "quest"     { "q" }
            "treasure"  { "o" }
            default     { $null }
        }
        $parentName = ""
        $namedKind, $namedID = "", ""
        if ($best) {
            if ($preferAlias) {
                # `ancestry` is the extractor's column name (extract-att-sources.lua);
                # `att_source_ancestry` is this script's OUTPUT name. Reading the
                # output name here silently yielded $null, so this whole walk was
                # dead code and only the immediate-parent fallback below ever ran.
                foreach ($part in ($best.ancestry -split '>')) {
                    $bits = $part -split ':'
                    if ($bits.Count -eq 2 -and $bits[0] -eq $preferAlias -and $names.ContainsKey($part)) {
                        $namedKind, $namedID, $parentName = $bits[0], $bits[1], $names[$part]
                    }
                }
            }
            if (-not $parentName -and $best.source_parent_kind -and $best.source_parent_id) {
                $key = $best.source_parent_kind + ":" + $best.source_parent_id
                if ($names.ContainsKey($key)) {
                    $namedKind, $namedID, $parentName = $best.source_parent_kind, $best.source_parent_id, $names[$key]
                }
            }
        }

        $out.Add([pscustomobject]@{
            recipe_spell_id    = $id
            source_kind        = $kind
            att_class          = $attClass
            att_recipe_item_id = $recipeItem[$id]
            source_parent_kind = if ($namedKind) { $namedKind } elseif ($best) { $best.source_parent_kind } else { "" }
            source_parent_id   = if ($namedID) { $namedID } elseif ($best) { $best.source_parent_id } else { "" }
            source_parent_name = $parentName
            map_id             = if ($best) { $best.map_id } else { "" }
            coord_x            = if ($best) { $best.coord_x } else { "" }
            coord_y            = if ($best) { $best.coord_y } else { "" }
            # Additional spawns for the same map, packed "x,y;x,y". The waypoint
            # generator turns these into a waypoint LIST, which Collectionist
            # renders as "N possible locations".
            extra_spawns       = if ($best) { $best.extra_spawns } else { "" }
            # DIAGNOSTIC ONLY - never a placement signal. Expansion placement is
            # by trade category, matching how all 9,918 shipped recipes were
            # placed. awp disagrees with that on 86% of rows and puts nothing in
            # vanilla, because it began with the 2.0 convention.
            awp_own            = if ($best) { $best.awp_own } else { "" }
            awp_ancestor       = if ($best) { $best.awp_ancestor } else { "" }
            awp_ancestor_from  = if ($best) { $best.awp_ancestor_from } else { "" }
            att_file           = if ($best) { $best.att_file } else { "" }
            att_occurrences    = if ($occurrences) { $occurrences.Count } else { 0 }
            att_source_ancestry = if ($best) { $best.ancestry } else { "" }
            attribution_basis  = if ($attClass -and $best) { "att_profession_db+att_tree" }
                                 elseif ($attClass) { "att_profession_db" }
                                 elseif ($best) { "att_tree" }
                                 else { "" }
        })
    }

    $outDir = Split-Path -Parent $OutFile
    if (-not (Test-Path -LiteralPath $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }
    $out | Sort-Object { [int]$_.recipe_spell_id } | Export-Csv -LiteralPath $OutFile -NoTypeInformation -Encoding UTF8

    Write-Host ""
    Write-Host ("Wrote {0} rows to {1}" -f $out.Count, $OutFile)
    $out | Group-Object source_kind | Sort-Object Count -Descending |
        Format-Table @{L='source';E={$_.Name}}, Count -AutoSize | Out-String | Write-Host
}
finally {
    if (Test-Path -LiteralPath $work) { Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue }
}
