<#
.SYNOPSIS
Emits the Trading Post data files for pets, mounts and toys.

.DESCRIPTION
Collectionist previously excluded the Trading Post because its DB2 filter
treated every rotating source as external. That was wrong for completeness:
Trading Post collectibles are bought with Trader's Tender earned in game and
rotate back into availability, so they belong in the catalog.

Writes one file per module:
  Modules/Pets/Data/TradingPost.lua
  Modules/Mounts/Data/TradingPost.lua
  Modules/Toys/Data/TradingPost.lua

Scope is narrower than the audit's raw list. The audit counts a collectible as
Trading Post if it has EVER appeared there, which sweeps in items that began as
Trading Card Game codes, in-game Shop purchases, Recruit-a-Friend rewards or
promotional giveaways. Those stay out by default, per the standing rule that
out-of-game promotional collectibles are reviewed by hand rather than added in
bulk. Pass -IncludeOutOfGameOrigins to add them anyway.

Expansion ownership follows the FIRST patch the item appeared on the Trading
Post, not the expansion its model or original promotion came from.

Pets additionally need petType and npcID, which the audit CSV does not carry;
those come from BattlePetSpecies DB2. Mounts and toys need no lookup - the
audit already has every field their runtime rows use.
#>
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
    [string]$SpeciesCsv,
    [switch]$IncludeOutOfGameOrigins
)

$ErrorActionPreference = "Stop"

$auditPath = Join-Path $RepoRoot "research/collectionist/sources/trading-post-gap-audit.csv"
if (-not (Test-Path -LiteralPath $auditPath)) { throw "Missing $auditPath" }

function ConvertTo-LuaString([string]$value) {
    if ($null -eq $value) { $value = "" }
    return '"' + ($value -replace '\\', '\\\\' -replace '"', '\"') + '"'
}

# The audit writes descriptive expansion names; the addon's registry
# (Data/Expansions.lua) uses short keys. An untranslated key matches nothing in
# MC.EXPANSION_BY_KEY, so Options > Expansions silently fails to filter those
# rows and MC.GetLatestExpansion never sees them.
$EXPANSION_KEY = @{
    "classic" = "vanilla"; "tbc" = "tbc"; "wrath" = "wrath"; "cataclysm" = "cata"
    "mists_of_pandaria" = "mop"; "wod" = "wod"; "legion" = "legion"
    "battle_for_azeroth" = "bfa"; "shadowlands" = "shadowlands"
    "dragonflight" = "df"; "tww" = "tww"; "midnight" = "midnight"
}

# Origins that are NOT the Trading Post itself. Held back by default.
$OUT_OF_GAME = 'Trading Card Game|In-Game Shop|Promotion|Recruit|Collector'
function Test-OutOfGameOrigin([string]$sourceText) {
    $plain = $sourceText -replace '\|c[0-9A-Fa-f]{8}', '' -replace '\|r|\|n', ' '
    return $plain -match $OUT_OF_GAME
}

$all = @(Import-Csv -LiteralPath $auditPath | Where-Object { $_.decision -eq 'confirmed_policy_gap' })

# Pets are the only kind needing a DB2 join; skip the load if none survive.
$species = @{}
$petsWanted = @($all | Where-Object { $_.kind -eq 'pet' -and ($IncludeOutOfGameOrigins -or -not (Test-OutOfGameOrigin $_.source_text)) })
if ($petsWanted.Count -gt 0) {
    if (-not $SpeciesCsv) {
        # Newest export wins: older snapshots predate recent species and would
        # silently drop pets for want of a petType.
        $SpeciesCsv = Get-ChildItem -Path (Join-Path $env:TEMP "collectionist-*-db2") -Filter BattlePetSpecies.csv -Recurse -ErrorAction SilentlyContinue |
            Sort-Object { (Import-Csv -LiteralPath $_.FullName).Count } -Descending |
            Select-Object -First 1 -ExpandProperty FullName
    }
    if (-not $SpeciesCsv -or -not (Test-Path -LiteralPath $SpeciesCsv)) {
        throw "No BattlePetSpecies.csv found. Download it from wago.tools into %TEMP%\collectionist-<exp>-db2\current\."
    }
    foreach ($row in (Import-Csv -LiteralPath $SpeciesCsv)) { $species[$row.ID] = $row }
    Write-Host ("BattlePetSpecies: {0} rows" -f $species.Count)
}

$KINDS = @(
    @{ kind = 'pet';   module = 'Pets';   listKey = 'pets'   }
    @{ kind = 'mount'; module = 'Mounts'; listKey = 'mounts' }
    @{ kind = 'toy';   module = 'Toys';   listKey = 'toys'   }
)

$heldBack = @()

foreach ($spec in $KINDS) {
    $rows = @($all | Where-Object { $_.kind -eq $spec.kind })
    $kept = @()
    foreach ($row in $rows) {
        if ((Test-OutOfGameOrigin $row.source_text) -and -not $IncludeOutOfGameOrigins) {
            $heldBack += [pscustomobject]@{ kind = $spec.kind; name = $row.name; origin = ($row.source_text -replace '\|c[0-9A-Fa-f]{8}', '' -replace '\|r|\|n', ' ').Trim() }
            continue
        }
        $kept += $row
    }
    if ($kept.Count -eq 0) { continue }

    if ($spec.kind -eq 'pet') {
        $missing = @($kept | Where-Object { -not $species.ContainsKey($_.collectible_id) })
        if ($missing.Count -gt 0) {
            throw ("BattlePetSpecies is missing {0} species ({1}). Fetch a current export." -f
                $missing.Count, (($missing | Select-Object -First 5 | ForEach-Object { $_.collectible_id }) -join ', '))
        }
    }

    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine('local _, MC = ...')
    [void]$sb.AppendLine()
    [void]$sb.AppendLine('-- GENERATED FILE - do not edit.')
    [void]$sb.AppendLine('-- Regenerate: scripts/generate-collectionist-trading-post.ps1')
    [void]$sb.AppendLine('--')
    [void]$sb.AppendLine(('-- Trading Post {0}. Bought with Trader''s Tender in game and rotated back' -f $spec.listKey))
    [void]$sb.AppendLine('-- into the shop over time, so they are tracked like anything else earnable.')
    [void]$sb.AppendLine('-- Expansion is the one whose Trading Post first offered the item, not the')
    [void]$sb.AppendLine('-- expansion its model or original promotion came from.')
    $kindHeld = @($heldBack | Where-Object { $_.kind -eq $spec.kind })
    if ($kindHeld.Count -gt 0) {
        [void]$sb.AppendLine('--')
        [void]$sb.AppendLine(('-- {0} whose original source was a TCG code, the in-game Shop, Recruit-a-Friend' -f $kindHeld.Count))
        [void]$sb.AppendLine('-- or a promotion are deliberately NOT listed here, pending review.')
    }
    [void]$sb.AppendLine()

    foreach ($group in ($kept | Group-Object acquisition_expansion | Sort-Object Name)) {
        $expKey = $EXPANSION_KEY[$group.Name]
        if (-not $expKey) { throw "Unmapped expansion '$($group.Name)' - add it to `$EXPANSION_KEY" }
        [void]$sb.AppendLine(('MC.RegisterContent({0}, "{1}", {{' -f (ConvertTo-LuaString $expKey), $spec.listKey))
        [void]$sb.AppendLine(('    {{ source = "tradingpost", {0} = {{' -f $spec.listKey))
        foreach ($row in ($group.Group | Sort-Object { [int]$_.collectible_id })) {
            $info = "|cFFFFD200Trading Post|r"
            if ($row.first_trading_post_patch) { $info += "|n|cFFFFD200First offered: |r" + $row.first_trading_post_patch }
            $parts = @()
            switch ($spec.kind) {
                'pet' {
                    $sp = $species[$row.collectible_id]
                    $parts += "speciesID = $($row.collectible_id)"
                    $parts += "npcID = $($sp.CreatureID)"
                    $parts += "name = $(ConvertTo-LuaString $row.name)"
                    # Battle pet families are 1-10. A 0 in DB2 means the export
                    # has no family for this species, and writing it shipped a
                    # value the Scanner treats as "absent" anyway -- so omit the
                    # field and let the live C_PetJournal lookup supply it,
                    # rather than baking in a sentinel that looks like data.
                    if ($sp.PetTypeEnum -and [int]$sp.PetTypeEnum -ge 1) {
                        $parts += "petType = $($sp.PetTypeEnum)"
                    }
                }
                'mount' {
                    $parts += "mountID = $($row.collectible_id)"
                    $parts += "name = $(ConvertTo-LuaString $row.name)"
                }
                'toy' {
                    # The audit stores a toy's itemID in collectible_id; its
                    # item_id column is empty for this kind.
                    $parts += "itemID = $($row.collectible_id)"
                    $parts += "name = $(ConvertTo-LuaString $row.name)"
                }
            }
            $parts += 'source = "tradingpost"'
            $parts += "sourceInfo = $(ConvertTo-LuaString $info)"
            if ($spec.kind -ne 'toy' -and $row.item_id) { $parts += "itemID = $($row.item_id)" }
            [void]$sb.AppendLine('        { ' + ($parts -join ', ') + ' },')
        }
        [void]$sb.AppendLine('    } },')
        [void]$sb.AppendLine('})')
        [void]$sb.AppendLine()
    }

    $outPath = Join-Path $RepoRoot ("addons/Collectionist/Modules/{0}/Data/TradingPost.lua" -f $spec.module)
    $utf8 = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($outPath, ($sb.ToString() -replace "`r`n", "`n"), $utf8)
    Write-Host ("{0,-7} {1,3} rows -> Modules/{2}/Data/TradingPost.lua" -f $spec.kind, $kept.Count, $spec.module)
    $kept | Group-Object acquisition_expansion | Sort-Object Name | ForEach-Object {
        Write-Host ("          {0,-14} {1}" -f $_.Name, $_.Count)
    }
}

if ($heldBack.Count -gt 0) {
    Write-Host ""
    Write-Host ("Held back {0} with out-of-game origins (use -IncludeOutOfGameOrigins to add):" -f $heldBack.Count)
    $heldBack | Sort-Object kind, name | ForEach-Object {
        Write-Host ("  {0,-6} {1,-26} {2}" -f $_.kind, $_.name, $_.origin)
    }
}
