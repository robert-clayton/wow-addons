param([string]$RepoRoot = (Split-Path -Parent $PSScriptRoot))

$ErrorActionPreference = "Stop"
$manifestRoot = Join-Path $RepoRoot "research\collectionist\classic\manifests"
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
    for ($i = 0; $i -lt $expected.Count; $i++) {
        if ([string]$actual[$i] -ne [string]$expected[$i]) {
            throw "$label order mismatch at index $($i + 1): expected $($expected[$i]), got $($actual[$i])"
        }
    }
}
function Assert-ExactLuaSet([string]$catalog, [string]$luaPath, [string]$pattern, [string]$manifestField) {
    $raw = Read-Lua $luaPath
    $actual = @([regex]::Matches($raw, $pattern) | ForEach-Object { $_.Groups[1].Value })
    $expected = @(Read-Rows $catalog | ForEach-Object { [string]$_.$manifestField })
    $duplicates = @($actual | Group-Object | Where-Object Count -gt 1)
    if ($duplicates.Count) { throw "$catalog runtime contains duplicate IDs: $($duplicates.Name -join ', ')" }
    $missing = @($expected | Where-Object { $_ -notin $actual })
    $extra = @($actual | Where-Object { $_ -notin $expected })
    if ($actual.Count -ne $expected.Count -or $missing.Count -or $extra.Count) {
        throw "$catalog runtime mismatch: expected=$($expected.Count) actual=$($actual.Count) missing=[$($missing -join ', ')] extra=[$($extra -join ', ')]"
    }
    return [pscustomobject]@{ catalog = $catalog; rows = $actual.Count; status = "exact" }
}
function Get-NumberList([string]$value) {
    return @([regex]::Matches($value, "\d+") | ForEach-Object Value)
}
function Assert-UnavailableSet([string]$catalog, [string]$luaPath, [string]$idField, [string]$manifestField) {
    $raw = Read-Lua $luaPath
    $actual = @([regex]::Matches($raw, "(?m)^\s*\{[^\r\n]*\b$idField\s*=\s*(\d+)[^\r\n]*\bunavailable\s*=\s*true") | ForEach-Object { $_.Groups[1].Value })
    $expected = @(Read-Rows $catalog | Where-Object unavailable -eq "True" | ForEach-Object { [string]$_.$manifestField })
    Assert-Sequence @($actual | Sort-Object { [int]$_ }) @($expected | Sort-Object { [int]$_ }) "$catalog unavailable IDs"
}
function Assert-RareGroups {
    $manifest = Read-Rows "rares"
    $raw = Read-Lua "Modules\Rares\Data\Classic.lua"
    $matches = @([regex]::Matches($raw, '(?s)achievementID\s*=\s*(\d+),\s*criteriaCount\s*=\s*(\d+),\s*criteriaTreeIDs\s*=\s*\{([^}]*)\},\s*criteriaNPCIDs\s*=\s*\{([^}]*)\}'))
    $groups = @($manifest | Group-Object achievement_id)
    if ($matches.Count -ne $groups.Count) { throw "rares group count mismatch: expected $($groups.Count), got $($matches.Count)" }
    foreach ($match in $matches) {
        $achievementID = $match.Groups[1].Value
        $rows = @($manifest | Where-Object achievement_id -eq $achievementID)
        if ([int]$match.Groups[2].Value -ne $rows.Count) { throw "rares achievement $achievementID criteriaCount mismatch" }
        Assert-Sequence @(Get-NumberList $match.Groups[3].Value) @($rows | ForEach-Object { [string]$_.tree_id }) "rares achievement $achievementID tree IDs"
        Assert-Sequence @(Get-NumberList $match.Groups[4].Value) @($rows | ForEach-Object { [string]$_.npc_id }) "rares achievement $achievementID NPC IDs"
    }
    return [pscustomobject]@{ catalog = "rares"; rows = $manifest.Count; status = "ordered exact" }
}
function Assert-TreasureGroups {
    $manifest = Read-Rows "treasures"
    $raw = Read-Lua "Modules\Treasures\Data\Classic.lua"
    $matches = @([regex]::Matches($raw, '(?s)achievementID\s*=\s*(\d+),\s*criteriaCount\s*=\s*(\d+),\s*criteriaTreeIDs\s*=\s*\{([^}]*)\},(.*?)\s*name\s*='))
    $groups = @($manifest | Group-Object achievement_id)
    if ($matches.Count -ne $groups.Count) { throw "treasures group count mismatch: expected $($groups.Count), got $($matches.Count)" }
    foreach ($match in $matches) {
        $achievementID = $match.Groups[1].Value
        $rows = @($manifest | Where-Object achievement_id -eq $achievementID)
        if ([int]$match.Groups[2].Value -ne $rows.Count) { throw "treasures achievement $achievementID criteriaCount mismatch" }
        Assert-Sequence @(Get-NumberList $match.Groups[3].Value) @($rows | ForEach-Object { [string]$_.tree_id }) "treasures achievement $achievementID tree IDs"
        $nameMatch = [regex]::Match($match.Groups[4].Value, 'criteriaNames\s*=\s*\{([^}]*)\}')
        $hasAllNames = @($rows | Where-Object { $_.criterion }).Count -eq $rows.Count
        if ($hasAllNames) {
            if (-not $nameMatch.Success) { throw "treasures achievement $achievementID must ship positional names" }
            $actualNames = @([regex]::Matches($nameMatch.Groups[1].Value, '"((?:\\.|[^"\\])*)"') | ForEach-Object { $_.Groups[1].Value })
            Assert-Sequence $actualNames @($rows | ForEach-Object criterion) "treasures achievement $achievementID names"
        } elseif ($nameMatch.Success) {
            throw "treasures achievement $achievementID must defer blank positional names to the live API"
        }
    }
    return [pscustomobject]@{ catalog = "treasures"; rows = $manifest.Count; status = "ordered exact" }
}

$results = @()
$results += Assert-ExactLuaSet "mounts" "Modules\Mounts\Data\Classic.lua" "\bmountID\s*=\s*(\d+)" "mount_id"
$results += Assert-ExactLuaSet "pets" "Modules\Pets\Data\Classic.lua" "\bspeciesID\s*=\s*(\d+)" "species_id"
$results += Assert-ExactLuaSet "toys" "Modules\Toys\Data\Classic.lua" "\bitemID\s*=\s*(\d+)" "item_id"
$results += Assert-ExactLuaSet "decorations" "Modules\Decorations\Data\Classic.lua" "\bdecorID\s*=\s*(\d+)" "decor_id"
$results += Assert-ExactLuaSet "achievements" "Modules\Achievements\Data\Classic.lua" '(?m)^        \{ achievementID\s*=\s*(\d+),\s*name\s*=' "achievement_id"
$results += Assert-ExactLuaSet "recipes" "Modules\Recipes\Data\Classic.lua" '(?m)^        \{ id\s*=\s*(\d+),\s*name\s*=' "recipe_spell_id"
$results += Assert-RareGroups
$results += Assert-TreasureGroups
Assert-UnavailableSet "mounts" "Modules\Mounts\Data\Classic.lua" "mountID" "mount_id"
Assert-UnavailableSet "pets" "Modules\Pets\Data\Classic.lua" "speciesID" "species_id"
Assert-UnavailableSet "toys" "Modules\Toys\Data\Classic.lua" "itemID" "item_id"

$criteria = Read-Rows "achievement-criteria"
$eligibleIDs = @($criteria | Group-Object achievement_id | Where-Object { $_.Count -ge 2 -and $_.Count -le 30 } | ForEach-Object Name)
$achievementLua = Read-Lua "Modules\Achievements\Data\Classic.lua"
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

$constants = Read-Lua "Data\Constants.lua"
foreach ($pair in @{
    Durotar = 1; Mulgore = 7; NorthernBarrens = 10; Kalimdor = 12; EasternKingdoms = 13
    ArathiHighlands = 14; Badlands = 15; BlastedLands = 17; TirisfalGlades = 18
    SilverpineForest = 21; WesternPlaguelands = 22; EasternPlaguelands = 23
    HillsbradFoothills = 25; Hinterlands = 26; DunMorogh = 27; SearingGorge = 32
    BurningSteppes = 36; ElwynnForest = 37; DeadwindPass = 42; Duskwood = 47
    LochModan = 48; RedridgeMountains = 49; NorthernStranglethorn = 50
    SwampOfSorrows = 51; Westfall = 52; Wetlands = 56; Teldrassil = 57; Darkshore = 62
    Ashenvale = 63; ThousandNeedles = 64; StonetalonMountains = 65; Desolace = 66
    Feralas = 69; DustwallowMarsh = 70; Tanaris = 71; Azshara = 76; Felwood = 77
    UngoroCrater = 78; Moonglade = 80; Silithus = 81; Winterspring = 83
    StormwindCity = 84; Orgrimmar = 85; Ironforge = 87; ThunderBluff = 88
    Darnassus = 89; Undercity = 90; AlteracValley = 91; WarsongGulch = 92
    ArathiBasin = 93; SouthernBarrens = 199; StranglethornVale = 224
}.GetEnumerator()) {
    if ($constants -notmatch "(?m)^\s*$([regex]::Escape($pair.Key))\s*=\s*$($pair.Value),") {
        throw "Missing Classic map constant $($pair.Key)=$($pair.Value)"
    }
}

$toc = Get-Content -LiteralPath (Join-Path $addonRoot "Collectionist.toc") -Raw
foreach ($module in @("Mounts", "Pets", "Decorations", "Toys", "Rares", "Treasures", "Achievements", "Recipes")) {
    $classicPath = "Modules\$module\Data\Classic.lua"
    $tbcPath = "Modules\$module\Data\TheBurningCrusade.lua"
    if (@([regex]::Matches($toc, [regex]::Escape($classicPath))).Count -ne 1) { throw "TOC must load $classicPath exactly once" }
    if ($toc.IndexOf($classicPath) -gt $toc.IndexOf($tbcPath)) { throw "TOC must load Classic before TBC for $module" }
}

foreach ($module in @("Mounts", "Pets", "Decorations", "Toys", "Rares", "Treasures", "Achievements", "Recipes")) {
    $path = Join-Path $addonRoot "Modules\$module\Data\Classic.lua"
    & luajit -b $path ([System.IO.Path]::GetTempFileName())
    if ($LASTEXITCODE -ne 0) { throw "Lua syntax validation failed: $path" }
}

$results | Format-Table -AutoSize
Write-Host "Collectionist Classic runtime validation passed"





