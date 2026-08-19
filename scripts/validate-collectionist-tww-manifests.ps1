param(
    [string]$RepoRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = "Stop"

function Get-UniqueLuaIDs([string]$path, [string]$field, [string]$pattern) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing Lua data file: $path"
    }

    $raw = Get-Content -LiteralPath $path -Raw
    if (-not $pattern) {
        $pattern = "\b$([regex]::Escape($field))\s*=\s*(\d+)"
    }
    $matches = [regex]::Matches($raw, $pattern)
    $ids = @($matches | ForEach-Object { $_.Groups[1].Value })
    $duplicates = @($ids | Group-Object | Where-Object Count -gt 1)
    if ($duplicates.Count -gt 0) {
        throw "$path contains duplicate ${field}: $($duplicates.Name -join ', ')"
    }
    return $ids
}

$checks = @(
    @{ Name = "mounts";      Lua = "addons/Collectionist/Modules/Mounts/Data/TheWarWithin.lua";      LuaField = "mountID";   ManifestField = "mount_id" },
    @{ Name = "pets";        Lua = "addons/Collectionist/Modules/Pets/Data/TheWarWithin.lua";        LuaField = "speciesID"; ManifestField = "species_id" },
    @{ Name = "toys";        Lua = "addons/Collectionist/Modules/Toys/Data/TheWarWithin.lua";        LuaField = "itemID";    ManifestField = "item_id" },
    @{ Name = "decorations"; Lua = "addons/Collectionist/Modules/Decorations/Data/TheWarWithin.lua"; LuaField = "decorID";   ManifestField = "decor_id" },
    @{ Name = "achievements"; Lua = "addons/Collectionist/Modules/Achievements/Data/TheWarWithin.lua"; LuaField = "achievementID"; ManifestField = "achievement_id"; Pattern = "(?m)^            \{ achievementID\s*=\s*(\d+)" },
    @{ Name = "recipes";     Lua = "addons/Collectionist/Modules/Recipes/Data/TheWarWithin.lua";     LuaField = "id";        ManifestField = "recipe_spell_id" }
)

$results = foreach ($check in $checks) {
    $luaPath = Join-Path $RepoRoot $check.Lua
    $manifestPath = Join-Path $RepoRoot "research/collectionist/tww/manifests/$($check.Name).csv"
    if (-not (Test-Path -LiteralPath $manifestPath)) {
        throw "Missing manifest: $manifestPath"
    }

    $manifestRows = @(Import-Csv -LiteralPath $manifestPath)
    $expectedIDs = @($manifestRows | ForEach-Object { [string]$_.$($check.ManifestField) })
    $manifestDuplicates = @($expectedIDs | Group-Object | Where-Object Count -gt 1)
    if ($manifestDuplicates.Count -gt 0) {
        throw "$manifestPath contains duplicate $($check.ManifestField): $($manifestDuplicates.Name -join ', ')"
    }

    $actualIDs = @(Get-UniqueLuaIDs $luaPath $check.LuaField $check.Pattern)
    $actualSet = @{}
    foreach ($id in $actualIDs) { $actualSet[$id] = $true }
    $expectedSet = @{}
    foreach ($id in $expectedIDs) { $expectedSet[$id] = $true }

    $missing = @($expectedIDs | Where-Object { -not $actualSet.ContainsKey($_) })
    $extra = @($actualIDs | Where-Object { -not $expectedSet.ContainsKey($_) })
    if ($missing.Count -gt 0 -or $extra.Count -gt 0) {
        throw "$($check.Name) manifest mismatch; missing=[$($missing -join ',')] extra=[$($extra -join ',')]"
    }

    [pscustomobject]@{
        catalog = $check.Name
        rows    = $actualIDs.Count
        status  = "exact"
    }
}

$results | Format-Table -AutoSize
