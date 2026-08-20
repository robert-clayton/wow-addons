<#
.SYNOPSIS
Emits Modules/Pets/Data/TradingPost.lua from the Trading Post gap audit.

.DESCRIPTION
Collectionist previously excluded the Trading Post because its earlier filter
treated every rotating source as external. That was wrong for completeness:
Trading Post pets are earned in game with Trader's Tender and rotate back into
availability, so they belong in the catalog.

Scope is deliberately narrower than the audit's full list. The audit counts a
pet as a Trading Post item if it has EVER appeared there, which sweeps in nine
pets that began life as Trading Card Game codes, in-game Shop purchases or
promotional giveaways. Those stay out unless explicitly included, per the
standing rule that out-of-game promotional collectibles get reviewed by hand
rather than added in bulk. Pass -IncludeOutOfGameOrigins to add them anyway.

Expansion ownership follows the FIRST patch the pet appeared on the Trading
Post, not the expansion its model or original promotion came from - a pet first
sold in the 10.1.5 Trading Post is Dragonflight content regardless of the 2010
TCG it started in.

petType and npcID come from BattlePetSpecies DB2, which the audit CSV does not
carry.
#>
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
    [string]$SpeciesCsv,
    [switch]$IncludeOutOfGameOrigins
)

$ErrorActionPreference = "Stop"

$auditPath = Join-Path $RepoRoot "research/collectionist/sources/trading-post-gap-audit.csv"
$outPath   = Join-Path $RepoRoot "addons/Collectionist/Modules/Pets/Data/TradingPost.lua"
if (-not (Test-Path -LiteralPath $auditPath)) { throw "Missing $auditPath" }

# Newest BattlePetSpecies export wins: older snapshots predate recent species
# and would silently drop pets for want of a petType.
if (-not $SpeciesCsv) {
    $SpeciesCsv = Get-ChildItem -Path (Join-Path $env:TEMP "collectionist-*-db2") -Filter BattlePetSpecies.csv -Recurse -ErrorAction SilentlyContinue |
        Sort-Object { (Import-Csv -LiteralPath $_.FullName).Count } -Descending |
        Select-Object -First 1 -ExpandProperty FullName
}
if (-not $SpeciesCsv -or -not (Test-Path -LiteralPath $SpeciesCsv)) {
    throw "No BattlePetSpecies.csv found. Download it from wago.tools into %TEMP%\collectionist-<exp>-db2\current\."
}

$species = @{}
foreach ($row in (Import-Csv -LiteralPath $SpeciesCsv)) { $species[$row.ID] = $row }
Write-Host ("BattlePetSpecies: {0} rows from {1}" -f $species.Count, (Split-Path -Leaf (Split-Path -Parent $SpeciesCsv)))

function ConvertTo-LuaString([string]$value) {
    if ($null -eq $value) { $value = "" }
    return '"' + ($value -replace '\\', '\\\\' -replace '"', '\"') + '"'
}

# Origins that are NOT the Trading Post itself. Kept out by default.
$OUT_OF_GAME = 'Trading Card Game|In-Game Shop|Promotion|Recruit|Collector'
function Test-OutOfGameOrigin([string]$sourceText) {
    $plain = $sourceText -replace '\|c[0-9A-Fa-f]{8}', '' -replace '\|r|\|n', ' '
    return $plain -match $OUT_OF_GAME
}

$rows = @(Import-Csv -LiteralPath $auditPath |
    Where-Object { $_.decision -eq 'confirmed_policy_gap' -and $_.kind -eq 'pet' })

$kept, $skipped = @(), @()
foreach ($row in $rows) {
    if ((Test-OutOfGameOrigin $row.source_text) -and -not $IncludeOutOfGameOrigins) {
        $skipped += $row; continue
    }
    $kept += $row
}

$missing = @($kept | Where-Object { -not $species.ContainsKey($_.collectible_id) })
if ($missing.Count -gt 0) {
    throw ("BattlePetSpecies is missing {0} species ({1}). Fetch a current export." -f
        $missing.Count, (($missing | Select-Object -First 5 | ForEach-Object { $_.collectible_id }) -join ', '))
}

$byExpansion = $kept | Group-Object acquisition_expansion | Sort-Object Name

$sb = [System.Text.StringBuilder]::new()
[void]$sb.AppendLine('local _, MC = ...')
[void]$sb.AppendLine()
[void]$sb.AppendLine('-- GENERATED FILE - do not edit.')
[void]$sb.AppendLine('-- Regenerate: scripts/generate-collectionist-trading-post-pets.ps1')
[void]$sb.AppendLine('--')
[void]$sb.AppendLine('-- Trading Post pets. Bought with Trader''s Tender in game and rotated back')
[void]$sb.AppendLine('-- into the shop over time, so they are tracked like any other earnable pet.')
[void]$sb.AppendLine('-- Expansion is the one whose Trading Post first offered the pet, not the')
[void]$sb.AppendLine('-- expansion its model or original promotion came from.')
if (-not $IncludeOutOfGameOrigins) {
    [void]$sb.AppendLine('--')
    [void]$sb.AppendLine(('-- {0} pets whose original source was a TCG code, the in-game Shop or a' -f $skipped.Count))
    [void]$sb.AppendLine('-- promotion are deliberately NOT listed here, pending review.')
}
[void]$sb.AppendLine()

foreach ($group in $byExpansion) {
    [void]$sb.AppendLine(('MC.RegisterContent({0}, "pets", {{' -f (ConvertTo-LuaString $group.Name)))
    [void]$sb.AppendLine('    { source = "tradingpost", pets = {')
    foreach ($row in ($group.Group | Sort-Object { [int]$_.collectible_id })) {
        $sp = $species[$row.collectible_id]
        $info = "|cFFFFD200Trading Post|r"
        if ($row.first_trading_post_patch) { $info += "|n|cFFFFD200First offered: |r" + $row.first_trading_post_patch }
        $parts = @(
            "speciesID = $($row.collectible_id)"
            "npcID = $($sp.CreatureID)"
            "name = $(ConvertTo-LuaString $row.name)"
            "petType = $($sp.PetTypeEnum)"
            'source = "tradingpost"'
            "sourceInfo = $(ConvertTo-LuaString $info)"
        )
        if ($row.item_id) { $parts += "itemID = $($row.item_id)" }
        [void]$sb.AppendLine('        { ' + ($parts -join ', ') + ' },')
    }
    [void]$sb.AppendLine('    } },')
    [void]$sb.AppendLine('})')
    [void]$sb.AppendLine()
}

$utf8 = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($outPath, ($sb.ToString() -replace "`r`n", "`n"), $utf8)

Write-Host ("Wrote {0} pets to {1}" -f $kept.Count, $outPath)
$byExpansion | ForEach-Object { Write-Host ("  {0,-14} {1}" -f $_.Name, $_.Count) }
if ($skipped.Count -gt 0) {
    Write-Host ""
    Write-Host ("Held back {0} with out-of-game origins (use -IncludeOutOfGameOrigins to add):" -f $skipped.Count)
    $skipped | ForEach-Object { Write-Host ("  {0,-26} {1}" -f $_.name, ($_.source_text -replace '\|c[0-9A-Fa-f]{8}', '' -replace '\|r|\|n', ' ').Trim()) }
}
