param([string]$RepoRoot = (Split-Path -Parent $PSScriptRoot))

$ErrorActionPreference = "Stop"
$manifestRoot = Join-Path $RepoRoot "research\collectionist\legion\manifests"
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
function Assert-Sequence($actual, $expected, [string]$label) {
    if ($actual.Count -ne $expected.Count) { throw "$label count mismatch: expected $($expected.Count), got $($actual.Count)" }
    for ($i = 0; $i -lt $expected.Count; $i++) { if ([string]$actual[$i] -ne [string]$expected[$i]) { throw "$label order mismatch at index $($i + 1): expected $($expected[$i]), got $($actual[$i])" } }
}
function Assert-ExactLuaSet([string]$catalog, [string]$luaPath, [string]$pattern, [string]$manifestField) {
    $raw = Read-Lua $luaPath
    $actual = @([regex]::Matches($raw, $pattern) | ForEach-Object { $_.Groups[1].Value })
    $expected = @(Read-Rows $catalog | ForEach-Object { [string]$_.$manifestField })
    $duplicates = @($actual | Group-Object | Where-Object Count -gt 1)
    if ($duplicates.Count) { throw "$catalog runtime contains duplicate IDs: $($duplicates.Name -join ', ')" }
    $missing = @($expected | Where-Object { $_ -notin $actual })
    $extra = @($actual | Where-Object { $_ -notin $expected })
    if ($actual.Count -ne $expected.Count -or $missing.Count -or $extra.Count) { throw "$catalog runtime mismatch: expected=$($expected.Count) actual=$($actual.Count) missing=[$($missing -join ', ')] extra=[$($extra -join ', ')]" }
    return [pscustomobject]@{ catalog = $catalog; rows = $actual.Count; status = "exact" }
}
function Get-NumberList([string]$value) { return @([regex]::Matches($value, "\d+") | ForEach-Object Value) }
function Get-EntityList([string]$value) { return @([regex]::Matches($value, "\d+|false") | ForEach-Object Value) }
function Assert-UnavailableSet([string]$catalog, [string]$luaPath, [string]$idField, [string]$manifestField) {
    $raw = Read-Lua $luaPath
    $actual = @([regex]::Matches($raw, "(?m)^\s*\{[^\r\n]*\b$idField\s*=\s*(\d+)[^\r\n]*\bunavailable\s*=\s*true") | ForEach-Object { $_.Groups[1].Value })
    $expected = @(Read-Rows $catalog | Where-Object unavailable -eq "True" | ForEach-Object { [string]$_.$manifestField })
    Assert-Sequence @($actual | Sort-Object { [int]$_ }) @($expected | Sort-Object { [int]$_ }) "$catalog unavailable IDs"
}
function Assert-RareGroups {
    $manifest = Read-Rows "rares"
    $raw = Read-Lua "Modules\Rares\Data\Legion.lua"
    $matches = @([regex]::Matches($raw, '(?s)achievementID\s*=\s*(\d+),\s*criteriaCount\s*=\s*(\d+),\s*criteriaTreeIDs\s*=\s*\{([^}]*)\},\s*criteriaNPCIDs\s*=\s*\{([^}]*)\},\s*criteriaObjectIDs\s*=\s*\{([^}]*)\}'))
    $groups = @($manifest | Group-Object achievement_id)
    if ($matches.Count -ne $groups.Count) { throw "rares group count mismatch: expected $($groups.Count), got $($matches.Count)" }
    foreach ($match in $matches) {
        $achievementID = $match.Groups[1].Value; $rows = @($manifest | Where-Object achievement_id -eq $achievementID)
        if ([int]$match.Groups[2].Value -ne $rows.Count) { throw "rares achievement $achievementID criteriaCount mismatch" }
        Assert-Sequence @(Get-NumberList $match.Groups[3].Value) @($rows | ForEach-Object { [string]$_.tree_id }) "rares achievement $achievementID tree IDs"
        Assert-Sequence @(Get-EntityList $match.Groups[4].Value) @($rows | ForEach-Object { if ($_.npc_ids) { [string]$_.npc_ids } else { "false" } }) "rares achievement $achievementID NPC IDs"
        Assert-Sequence @(Get-EntityList $match.Groups[5].Value) @($rows | ForEach-Object { if ($_.object_ids) { [string]$_.object_ids } else { "false" } }) "rares achievement $achievementID object IDs"
    }
    return [pscustomobject]@{ catalog = "rares"; rows = $manifest.Count; status = "ordered exact" }
}
function Assert-TreasureGroups {
    $manifest = Read-Rows "treasures"
    $raw = Read-Lua "Modules\Treasures\Data\Legion.lua"
    $matches = @([regex]::Matches($raw, '(?s)achievementID\s*=\s*(\d+),\s*criteriaCount\s*=\s*(\d+),\s*criteriaTreeIDs\s*=\s*\{([^}]*)\},\s*criteriaNames\s*=\s*\{([^}]*)\}'))
    $groups = @($manifest | Group-Object achievement_id)
    if ($matches.Count -ne $groups.Count) { throw "treasures group count mismatch: expected $($groups.Count), got $($matches.Count)" }
    foreach ($match in $matches) {
        $achievementID = $match.Groups[1].Value; $rows = @($manifest | Where-Object achievement_id -eq $achievementID)
        if ([int]$match.Groups[2].Value -ne $rows.Count) { throw "treasures achievement $achievementID criteriaCount mismatch" }
        Assert-Sequence @(Get-NumberList $match.Groups[3].Value) @($rows | ForEach-Object { [string]$_.tree_id }) "treasures achievement $achievementID tree IDs"
        if (@([regex]::Matches($match.Groups[4].Value, '"(?:\\.|[^"\\])*"')).Count -ne $rows.Count) { throw "treasures achievement $achievementID criteriaNames count mismatch" }
    }
    return [pscustomobject]@{ catalog = "treasures"; rows = $manifest.Count; status = "ordered exact" }
}

$results = @()
$results += Assert-ExactLuaSet "mounts" "Modules\Mounts\Data\Legion.lua" "\bmountID\s*=\s*(\d+)" "mount_id"
$results += Assert-ExactLuaSet "pets" "Modules\Pets\Data\Legion.lua" "\bspeciesID\s*=\s*(\d+)" "species_id"
$results += Assert-ExactLuaSet "toys" "Modules\Toys\Data\Legion.lua" "\bitemID\s*=\s*(\d+)" "item_id"
$results += Assert-ExactLuaSet "decorations" "Modules\Decorations\Data\Legion.lua" "\bdecorID\s*=\s*(\d+)" "decor_id"
$results += Assert-ExactLuaSet "achievements" "Modules\Achievements\Data\Legion.lua" '(?m)^        \{ achievementID\s*=\s*(\d+),\s*name\s*=' "achievement_id"
$results += Assert-ExactLuaSet "recipes" "Modules\Recipes\Data\Legion.lua" '(?m)^        \{ id\s*=\s*(\d+),\s*name\s*=' "recipe_spell_id"
$results += Assert-RareGroups
$results += Assert-TreasureGroups
Assert-UnavailableSet "mounts" "Modules\Mounts\Data\Legion.lua" "mountID" "mount_id"
Assert-UnavailableSet "pets" "Modules\Pets\Data\Legion.lua" "speciesID" "species_id"
Assert-UnavailableSet "toys" "Modules\Toys\Data\Legion.lua" "itemID" "item_id"

$criteria = Read-Rows "achievement-criteria"
$eligibleIDs = @($criteria | Group-Object achievement_id | Where-Object { $_.Count -ge 2 -and $_.Count -le 30 } | ForEach-Object Name)
$achievementLua = Read-Lua "Modules\Achievements\Data\Legion.lua"
$actualTaskKeys = @([regex]::Matches($achievementLua, "\{\s*achievementID\s*=\s*(\d+),\s*criteriaID\s*=\s*(\d+)") | ForEach-Object { "$($_.Groups[1].Value):$($_.Groups[2].Value)" })
$expectedTaskKeys = @()
foreach ($achievementID in $eligibleIDs) {
    $expected = @($criteria | Where-Object achievement_id -eq $achievementID | ForEach-Object { "$($_.achievement_id):$($_.criteria_id)" })
    $actual = @($actualTaskKeys | Where-Object { $_.StartsWith("${achievementID}:") })
    Assert-Sequence $actual $expected "achievement $achievementID task criteria"
    $expectedTaskKeys += $expected
}
Assert-Sequence @($actualTaskKeys | Sort-Object) @($expectedTaskKeys | Sort-Object) "achievement task criteria exact set"
$results += [pscustomobject]@{ catalog = "achievement tasks"; rows = $actualTaskKeys.Count; status = "ordered exact" }

$toc = Get-Content -LiteralPath (Join-Path $addonRoot "Collectionist.toc") -Raw
foreach ($module in @("Mounts", "Pets", "Decorations", "Toys", "Rares", "Treasures", "Achievements", "Recipes")) {
    $path = "Modules\$module\Data\Legion.lua"
    if (@([regex]::Matches($toc, [regex]::Escape($path))).Count -ne 1) { throw "TOC must load $path exactly once" }
}

$results | Format-Table -AutoSize
Write-Host "Collectionist Legion runtime validation passed"
