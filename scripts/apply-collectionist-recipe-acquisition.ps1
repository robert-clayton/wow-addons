<#
.SYNOPSIS
Rewrites source="unknown" recipe rows using the resolved ATT acquisition data.

.DESCRIPTION
Reads research/collectionist/sources/att-recipe-acquisition.csv (produced by
generate-collectionist-recipe-acquisition.ps1) and replaces the placeholder
source on each affected row in addons/Collectionist/Modules/Recipes/Data/*.lua.

Deliberately a patch pass over the shipped Lua rather than a change to the
eleven per-expansion generators:

  * Those generators need per-expansion DB2 snapshots under %TEMP%, and only
    some are cached at any time. This needs nothing but the committed CSV.
  * TheWarWithin.lua has no generator at all - its rows were hand-emitted -
    so there is nothing to wire enrichment into there.

The pass is deterministic and idempotent: it only ever rewrites rows that
still say source="unknown", so re-running is a no-op, and running it again
after a generator re-emits placeholders restores the enrichment.

Rows the CSV cannot resolve are left exactly as they are.
#>
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
    [string]$AcquisitionCsv,
    [string]$UiMapCsv,
    [switch]$WhatIf
)

$ErrorActionPreference = "Stop"

if (-not $AcquisitionCsv) {
    $AcquisitionCsv = Join-Path $RepoRoot "research/collectionist/sources/att-recipe-acquisition.csv"
}
if (-not (Test-Path -LiteralPath $AcquisitionCsv)) {
    throw "Missing $AcquisitionCsv - run generate-collectionist-recipe-acquisition.ps1 first"
}

# Zone names are garnish: present for older maps, absent for some recent ones.
# Never fail over a missing UiMap.
$zone = @{}
if (-not $UiMapCsv) {
    $candidate = Get-ChildItem -Path (Join-Path $env:TEMP "collectionist-*-db2") -Filter UiMap.csv -Recurse -ErrorAction SilentlyContinue |
        Select-Object -First 1
    if ($candidate) { $UiMapCsv = $candidate.FullName }
}
if ($UiMapCsv -and (Test-Path -LiteralPath $UiMapCsv)) {
    foreach ($row in (Import-Csv -LiteralPath $UiMapCsv)) {
        if ($row.ID -and $row.Name_lang) { $zone[$row.ID] = $row.Name_lang }
    }
}

$acq = @{}
foreach ($row in (Import-Csv -LiteralPath $AcquisitionCsv)) { $acq[$row.recipe_spell_id] = $row }

function ConvertTo-LuaString([string]$value) {
    if ($null -eq $value) { $value = "" }
    return '"' + ($value -replace '\\', '\\\\' -replace '"', '\"') + '"'
}

# Prose per source kind. Keeps the register of the hand-curated per-profession
# files (bare "Magovu, Zul'Aman"), not the coloured markup the mount catalog
# uses -- these render in the same rows as those curated entries.
function Get-SourceInfo($row) {
    $name = $row.source_parent_name
    $where = ""
    if ($row.map_id -and $zone.ContainsKey($row.map_id)) { $where = $zone[$row.map_id] }

    switch ($row.source_kind) {
        "trainer" {
            if ($name) { return (@($name, $where) | Where-Object { $_ }) -join ", " }
            return "Trained from your profession trainer"
        }
        "vendor" {
            if ($name) { return (@($name, $where) | Where-Object { $_ }) -join ", " }
            return "Purchased from a vendor"
        }
        "drop" {
            if ($name) { return (@($name, $where) | Where-Object { $_ }) -join ", " }
            return "Drops from creatures"
        }
        "worlddrop"      { if ($where) { return "World drop, $where" }; return "World drop" }
        "quest"          { if ($name) { return "Quest: $name" }; return "Quest reward" }
        "discovery"      { if ($name) { return "Discovery: $name" }; return "Discovered while crafting" }
        "specialization" { if ($name) { return (@($name, $where) | Where-Object { $_ }) -join ", " }; return "Profession specialization" }
        "treasure"       { if ($name) { return (@($name, $where) | Where-Object { $_ }) -join ", " }; return "Found in the world" }
        "pvp"            { if ($name) { return (@($name, $where) | Where-Object { $_ }) -join ", " }; return "PvP reward" }
        # ATT's NeverImplemented bucket: in the client, never released - plus
        # content pulled since. "No longer obtainable" would be wrong for the
        # first group, so stay neutral about which it is.
        "unavailable"    { return "Not obtainable" }
        default          { return $null }
    }
}

$dataDir = Join-Path $RepoRoot "addons/Collectionist/Modules/Recipes/Data"
$files = Get-ChildItem -LiteralPath $dataDir -Filter *.lua | Sort-Object Name

# Recipes DB2 grants automatically. AcquireMethod 1 is the common case; WoD and
# TWW also use 3 for a handful. ATT classifies several of those as
# never-implemented, which is demonstrably wrong - Hexweave Cloth, Truesteel
# Ingot and the other Draenor daily-cooldown reagents are craftable today - so
# a non-zero DB2 acquire method overrides an ATT "unavailable". DB2 is
# authoritative for whether a thing exists; ATT is a community catalog.
$db2Granted = @{}
foreach ($csv in (Get-ChildItem -Path (Join-Path $RepoRoot "research/collectionist") -Filter recipes.csv -Recurse -ErrorAction SilentlyContinue)) {
    if ($csv.FullName -notmatch '[\\/]ids[\\/]') { continue }
    foreach ($row in (Import-Csv -LiteralPath $csv.FullName)) {
        if ($row.acquire_method -and $row.acquire_method -ne "0") { $db2Granted[$row.recipe_spell_id] = $true }
    }
}
Write-Host ("DB2-granted recipe IDs: {0}" -f $db2Granted.Count)

$grand = [ordered]@{}
$totalRewritten = 0
$totalLeft = 0
$totalCorrected = 0

foreach ($file in $files) {
    $lines = [System.IO.File]::ReadAllLines($file.FullName)
    $changed = 0
    $left = 0

    for ($i = 0; $i -lt $lines.Length; $i++) {
        $line = $lines[$i]

        # Correction pass: a DB2-granted recipe must never read "Not
        # obtainable". Idempotent - the rewritten line no longer matches.
        if ($line -match 'source = "unavailable"' -and $line -match '\{\s*id\s*=\s*(\d+)\s*,') {
            if ($db2Granted.ContainsKey($Matches[1])) {
                $lines[$i] = $line -replace 'source = "unavailable", sourceInfo = "[^"]*"',
                    'source = "trainer", sourceInfo = "Learned automatically"'
                if ($lines[$i] -ne $line) { $totalCorrected++ }
                continue
            }
        }

        if ($line -notmatch 'source = "unknown"') { continue }
        if ($line -notmatch '\{\s*id\s*=\s*(\d+)\s*,') { $left++; continue }
        $id = $Matches[1]

        $row = $acq[$id]
        if (-not $row -or -not $row.source_kind -or $row.source_kind -eq "unknown") { $left++; continue }

        $info = Get-SourceInfo $row
        if (-not $info) { $left++; continue }

        # Deliberately no `unavailable = true` here. Mounts and friends route
        # through MC.AccumulateScanEntry, which reads that flag into the legacy
        # bucket; the recipe scanner has its own simpler loop and never looks at
        # it, so emitting it would be dead data on 200-odd rows. The
        # source="unavailable" key already groups them under "Not obtainable",
        # which is the whole of what a player needs to know.
        $replacement = 'source = ' + (ConvertTo-LuaString $row.source_kind) +
                       ', sourceInfo = ' + (ConvertTo-LuaString $info)

        # Plain String.Replace, not -replace: the substituted text contains
        # names with apostrophes and parentheses, which -replace would try to
        # interpret as regex substitution syntax.
        $lines[$i] = $line.Replace('source = "unknown"', $replacement)
        $changed++
        if (-not $grand.Contains($row.source_kind)) { $grand[$row.source_kind] = 0 }
        $grand[$row.source_kind]++
    }

    if (($changed -gt 0 -or $totalCorrected -gt 0) -and -not $WhatIf) {
        # UTF-8 without BOM, LF - matches what the generators emit.
        $utf8 = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText($file.FullName, ($lines -join "`n") + "`n", $utf8)
    }
    $totalRewritten += $changed
    $totalLeft += $left
    if ($changed -gt 0 -or $left -gt 0) {
        "{0,-28} rewritten {1,5}   left {2,4}" -f $file.Name, $changed, $left | Write-Host
    }
}

Write-Host ""
Write-Host ("Rewritten: {0}    corrected: {1}    still unsourced: {2}" -f $totalRewritten, $totalCorrected, $totalLeft)
if ($WhatIf) { Write-Host "(-WhatIf: no files written)" }
Write-Host ""
$grand.GetEnumerator() | Sort-Object Value -Descending |
    Format-Table @{L='source';E={$_.Key}}, @{L='count';E={$_.Value}} -AutoSize | Out-String | Write-Host
