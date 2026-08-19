param(
    [string]$RepoRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = "Stop"

$manifestRoot = Join-Path $RepoRoot "research\collectionist\dragonflight\manifests"
$addonRoot = Join-Path $RepoRoot "addons\Collectionist"

function Read-Rows([string]$name) {
    $path = Join-Path $manifestRoot "$name.csv"
    if (-not (Test-Path -LiteralPath $path)) { throw "Missing manifest: $path" }
    return @(Import-Csv -LiteralPath $path)
}

function Read-Lua([string]$relativePath) {
    $path = Join-Path $addonRoot $relativePath
    if (-not (Test-Path -LiteralPath $path)) { throw "Missing Lua data file: $path" }
    return Get-Content -LiteralPath $path -Raw
}

function Assert-ExactLuaSet(
    [string]$catalog,
    [string]$luaPath,
    [string]$pattern,
    [string]$manifestField
) {
    $raw = Read-Lua $luaPath
    $actual = @([regex]::Matches($raw, $pattern) | ForEach-Object { $_.Groups[1].Value })
    $expected = @(Read-Rows $catalog | ForEach-Object { [string]$_.$manifestField })
    $duplicates = @($actual | Group-Object | Where-Object Count -gt 1)
    if ($duplicates.Count) {
        throw "$catalog runtime contains duplicate IDs: $($duplicates.Name -join ', ')"
    }
    $missing = @($expected | Where-Object { $_ -notin $actual })
    $extra = @($actual | Where-Object { $_ -notin $expected })
    if ($actual.Count -ne $expected.Count -or $missing.Count -or $extra.Count) {
        throw "$catalog runtime mismatch: expected=$($expected.Count) actual=$($actual.Count) missing=[$($missing -join ', ')] extra=[$($extra -join ', ')]"
    }
    return [pscustomobject]@{ catalog = $catalog; rows = $actual.Count; status = "exact" }
}

function Get-NumberList([string]$value) {
    return @([regex]::Matches($value, "\d+") | ForEach-Object { $_.Value })
}

function Assert-Sequence($actual, $expected, [string]$label) {
    if ($actual.Count -ne $expected.Count) {
        throw "$label count mismatch: expected $($expected.Count), got $($actual.Count)"
    }
    for ($i = 0; $i -lt $expected.Count; $i++) {
        if ([string]$actual[$i] -ne [string]$expected[$i]) {
            throw "$label order mismatch at index $($i + 1): expected $($expected[$i]), got $($actual[$i])"
        }
    }
}

function Assert-CriteriaGroups(
    [string]$catalog,
    [string]$luaPath,
    [string]$listField,
    [bool]$listContainsStrings
) {
    $manifest = Read-Rows $catalog
    $raw = Read-Lua $luaPath
    $pattern = "(?s)achievementID\s*=\s*(\d+),\s*criteriaCount\s*=\s*(\d+),\s*criteriaTreeIDs\s*=\s*\{([^}]*)\},\s*$listField\s*=\s*\{([^}]*)\}"
    $matches = @([regex]::Matches($raw, $pattern))
    $groups = @($manifest | Group-Object achievement_id)
    if ($matches.Count -ne $groups.Count) {
        throw "$catalog group count mismatch: expected $($groups.Count), got $($matches.Count)"
    }

    foreach ($match in $matches) {
        $achievementID = $match.Groups[1].Value
        $expectedRows = @($manifest | Where-Object achievement_id -eq $achievementID)
        if (-not $expectedRows.Count) { throw "$catalog runtime has unexpected achievement $achievementID" }
        if ([int]$match.Groups[2].Value -ne $expectedRows.Count) {
            throw "$catalog achievement $achievementID criteriaCount mismatch"
        }

        $actualTreeIDs = @(Get-NumberList $match.Groups[3].Value)
        $expectedTreeIDs = @($expectedRows | ForEach-Object { [string]$_.tree_id })
        Assert-Sequence $actualTreeIDs $expectedTreeIDs "$catalog achievement $achievementID criteriaTreeIDs"

        $listCount = if ($listContainsStrings) {
            @([regex]::Matches($match.Groups[4].Value, '"(?:\\.|[^"\\])*"')).Count
        } else {
            @(Get-NumberList $match.Groups[4].Value).Count
        }
        if ($listCount -ne $expectedRows.Count) {
            throw "$catalog achievement $achievementID $listField count mismatch: expected $($expectedRows.Count), got $listCount"
        }
    }

    return [pscustomobject]@{ catalog = $catalog; rows = $manifest.Count; status = "ordered exact" }
}

$results = @()
$results += Assert-ExactLuaSet "mounts" "Modules\Mounts\Data\Dragonflight.lua" "\bmountID\s*=\s*(\d+)" "mount_id"
$results += Assert-ExactLuaSet "pets" "Modules\Pets\Data\Dragonflight.lua" "\bspeciesID\s*=\s*(\d+)" "species_id"
$results += Assert-ExactLuaSet "toys" "Modules\Toys\Data\Dragonflight.lua" "\bitemID\s*=\s*(\d+)" "item_id"
$results += Assert-ExactLuaSet "decorations" "Modules\Decorations\Data\Dragonflight.lua" "\bdecorID\s*=\s*(\d+)" "decor_id"
$results += Assert-ExactLuaSet "achievements" "Modules\Achievements\Data\Dragonflight.lua" "(?m)^        \{ achievementID\s*=\s*(\d+),\s*name\s*=" "achievement_id"
$results += Assert-ExactLuaSet "recipes" "Modules\Recipes\Data\Dragonflight.lua" "(?m)^        \{ id\s*=\s*(\d+),\s*name\s*=" "recipe_spell_id"
$results += Assert-CriteriaGroups "rares" "Modules\Rares\Data\Dragonflight.lua" "criteriaNPCIDs" $false
$results += Assert-CriteriaGroups "treasures" "Modules\Treasures\Data\Dragonflight.lua" "criteriaNames" $true

$criteria = Read-Rows "achievement-criteria"
$eligibleAchievementIDs = @($criteria | Group-Object achievement_id | Where-Object { $_.Count -ge 2 -and $_.Count -le 30 } | ForEach-Object Name)
$achievementLua = Read-Lua "Modules\Achievements\Data\Dragonflight.lua"
$actualTaskKeys = @([regex]::Matches($achievementLua, "\{\s*achievementID\s*=\s*(\d+),\s*criteriaID\s*=\s*(\d+)") | ForEach-Object { "$($_.Groups[1].Value):$($_.Groups[2].Value)" })
$expectedTaskKeys = @()
foreach ($achievementID in $eligibleAchievementIDs) {
    $expected = @($criteria | Where-Object achievement_id -eq $achievementID | ForEach-Object { "$($_.achievement_id):$($_.criteria_id)" })
    $actual = @($actualTaskKeys | Where-Object { $_.StartsWith("${achievementID}:") })
    Assert-Sequence $actual $expected "achievement $achievementID task criteria"
    $expectedTaskKeys += $expected
}
$unexpectedTaskKeys = @($actualTaskKeys | Where-Object { $_ -notin $expectedTaskKeys })
if ($actualTaskKeys.Count -ne $expectedTaskKeys.Count -or $unexpectedTaskKeys.Count) {
    throw "achievement task criteria exact-set mismatch: expected=$($expectedTaskKeys.Count) actual=$($actualTaskKeys.Count) unexpected=[$($unexpectedTaskKeys -join ', ')]"
}
$results += [pscustomobject]@{ catalog = "achievement tasks"; rows = $actualTaskKeys.Count; status = "ordered exact" }

$results | Format-Table -AutoSize
Write-Host "Collectionist Dragonflight runtime validation passed"
