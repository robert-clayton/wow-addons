<#
.SYNOPSIS
Emits Modules/Decorations/Data/AttGaps.lua - housing decor missing from the catalog.

.DESCRIPTION
att-decoration-source-audit.csv classifies 816 current item-backed decoration
gaps. Only the 180 with `decision = source_ancestry_available` are ingested
here: those carry direct ATT quest or NPC ancestry, so a real source can be
named. The rest stay out until their ancestry is resolved -

  159  source_file_lead_available        category-level lead, needs local ancestry
  304  defer_catalog_or_unsorted_only    no acquisition record at all
   91  exclude_external_only             shop or promotion, excluded by policy
   77  exclude_never_implemented_only    never released
    5  defer_no_att_record

EXPANSION placement uses the ATT availability patch (`housing_patches`), which
for decor is the awarding content's patch: 110207 is The War Within, 120000 and
120001 are Midnight. This differs from recipes deliberately - recipes have a
trade-category tree that mirrors expansion tiers, decorations do not, so the
patch stamp is the best available signal rather than a worse one.

Separate file for the same reason as the recipe gaps: the per-expansion decor
files are rewritten wholesale by their generators.
#>
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
    [string]$AttRoot = (Join-Path $env:TEMP "collectionist-att-12007"),
    [switch]$WhatIf
)

$ErrorActionPreference = "Stop"

$auditPath = Join-Path $RepoRoot "research/collectionist/sources/att-decoration-source-audit.csv"
$outPath   = Join-Path $RepoRoot "addons/Collectionist/Modules/Decorations/Data/AttGaps.lua"
$dataDir   = Join-Path $RepoRoot "addons/Collectionist/Modules/Decorations/Data"
if (-not (Test-Path -LiteralPath $auditPath)) { throw "Missing $auditPath" }

$luajit = @(Get-Command luajit -ErrorAction Stop)[0].Source
$work = Join-Path ([System.IO.Path]::GetTempPath()) ("collectionist-decor-" + [guid]::NewGuid().ToString("N").Substring(0,8))
New-Item -ItemType Directory -Path $work -Force | Out-Null

function ConvertTo-LuaString([string]$v) {
    if ($null -eq $v) { $v = "" }
    return '"' + ($v -replace '\\', '\\\\' -replace '"', '\"') + '"'
}

# Leading patch digits -> expansion. 110207 = 11.2.7, 120000 = 12.0.0.
function Get-ExpansionFromPatch([string]$patches) {
    if (-not $patches) { return $null }
    # Several patches means it was re-offered; the FIRST is where it debuted.
    $first = ($patches -split ';')[0]
    if ($first.Length -lt 5) { return $null }
    $major = [int]$first.Substring(0, $first.Length - 4)
    $keys = @("", "vanilla","tbc","wrath","cata","mop","wod","legion","bfa","shadowlands","df","tww","midnight")
    if ($major -lt 1 -or $major -ge $keys.Count) { return $null }
    return $keys[$major]
}

try {
    Write-Host "Building name dictionary..."
    $namesCsv = Join-Path $work "names.csv"
    Get-ChildItem -LiteralPath (Join-Path $AttRoot ".contrib/Parser/DATAS") -Filter *.lua -Recurse |
        ForEach-Object { $_.FullName } |
        & $luajit (Join-Path $PSScriptRoot "extract-att-names.lua") |
        Set-Content -LiteralPath $namesCsv -Encoding UTF8
    $names = @{}
    foreach ($row in (Import-Csv -LiteralPath $namesCsv)) { $names[$row.kind + ":" + $row.id] = $row.name }

    $shipped = @{}
    foreach ($file in (Get-ChildItem -LiteralPath $dataDir -Filter *.lua)) {
        if ($file.Name -eq "AttGaps.lua") { continue }
        foreach ($line in [System.IO.File]::ReadLines($file.FullName)) {
            if ($line -match 'decorID\s*=\s*(\d+)') { $shipped[$Matches[1]] = $true }
        }
    }

    $rows = [System.Collections.Generic.List[object]]::new()
    $stats = [ordered]@{ alreadyShipped = 0; noExpansion = 0; noSource = 0 }

    foreach ($row in (Import-Csv -LiteralPath $auditPath |
                      Where-Object { $_.decision -eq 'source_ancestry_available' })) {
        if ($shipped.ContainsKey($row.decor_id)) { $stats.alreadyShipped++; continue }

        $expKey = Get-ExpansionFromPatch $row.housing_patches
        if (-not $expKey) { $stats.noExpansion++; continue }

        # housing_source_kinds / _ids are parallel ';'-separated lists.
        $kinds = @($row.housing_source_kinds -split ';' | Where-Object { $_ })
        $ids   = @($row.housing_source_ids   -split ';' | Where-Object { $_ })
        if ($kinds.Count -eq 0 -or $ids.Count -eq 0) { $stats.noSource++; continue }

        $kind = $kinds[0]
        $srcID = $ids[0]
        # ATT's node kind -> Collectionist's source key. `npc` means someone
        # sells or awards it, which the decor UI already labels "Vendor".
        $source = if ($kind -eq 'quest') { 'quest' } elseif ($kind -eq 'npc') { 'vendor' } else { $null }
        if (-not $source) { $stats.noSource++; continue }

        $nameKey = if ($kind -eq 'quest') { "q:$srcID" } else { "n:$srcID" }
        $srcName = $names[$nameKey]
        $info = if ($source -eq 'quest') {
            if ($srcName) { "Quest: $srcName" } else { "Quest reward" }
        } else {
            if ($srcName) { $srcName } else { "Purchased from a vendor" }
        }

        $rows.Add([pscustomobject]@{
            decorID = [int]$row.decor_id
            itemID  = $row.item_id
            name    = if ($row.name) { $row.name } else { $row.item_name }
            expansion = $expKey
            source  = $source
            info    = $info
        })
    }

    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine('local _, MC = ...')
    [void]$sb.AppendLine()
    [void]$sb.AppendLine('-- GENERATED FILE - do not edit.')
    [void]$sb.AppendLine('-- Regenerate: scripts/generate-collectionist-decor-att-gaps.ps1')
    [void]$sb.AppendLine('--')
    [void]$sb.AppendLine('-- Housing decorations present in current DB2 and in All The Things but')
    [void]$sb.AppendLine('-- absent from the per-expansion catalogs. Only rows with direct ATT quest')
    [void]$sb.AppendLine('-- or NPC ancestry are here; category-level leads and unsourced catalog')
    [void]$sb.AppendLine('-- records stay out until their source can be named.')
    [void]$sb.AppendLine('--')
    [void]$sb.AppendLine('-- Expansion follows the ATT availability patch, which for decor is the')
    [void]$sb.AppendLine('-- patch its awarding content shipped in.')
    [void]$sb.AppendLine()

    foreach ($expGroup in ($rows | Group-Object expansion | Sort-Object Name)) {
        [void]$sb.AppendLine(('MC.RegisterContent({0}, "decorations", {{' -f (ConvertTo-LuaString $expGroup.Name)))
        foreach ($srcGroup in ($expGroup.Group | Group-Object source | Sort-Object Name)) {
            [void]$sb.AppendLine(('    {{ source = {0}, decorations = {{' -f (ConvertTo-LuaString $srcGroup.Name)))
            foreach ($r in ($srcGroup.Group | Sort-Object decorID)) {
                $parts = @("decorID = $($r.decorID)")
                if ($r.itemID) { $parts += "itemID = $($r.itemID)" }
                $parts += "name = $(ConvertTo-LuaString $r.name)"
                $parts += "source = $(ConvertTo-LuaString $r.source)"
                $parts += "sourceInfo = $(ConvertTo-LuaString $r.info)"
                [void]$sb.AppendLine('        { ' + ($parts -join ', ') + ' },')
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

    Write-Host ("Ingesting {0} decorations" -f $rows.Count)
    $stats.GetEnumerator() | Where-Object { $_.Value -gt 0 } | ForEach-Object {
        Write-Host ("  excluded {0,-16} {1}" -f $_.Key, $_.Value)
    }
    Write-Host ""
    $rows | Group-Object expansion | Sort-Object Name | ForEach-Object {
        Write-Host ("  {0,-12} {1}" -f $_.Name, $_.Count)
    }
    $rows | Group-Object source | Sort-Object Name | ForEach-Object {
        Write-Host ("  {0,-12} {1}" -f $_.Name, $_.Count)
    }
    if (-not $WhatIf) { Write-Host ("Wrote {0}" -f $outPath) } else { Write-Host "(-WhatIf)" }
}
finally {
    if (Test-Path -LiteralPath $work) { Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue }
}
