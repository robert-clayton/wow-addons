param(
    [string]$CurrentDb2Root = (Join-Path $env:TEMP "collectionist-tww-db2\current"),
    [string]$HandyNotesRoot = "X:\Program Files\World of Warcraft\_retail_\Interface\AddOns",
    [string]$AuditPath = (Join-Path $PSScriptRoot "..\research\collectionist\sources\handynotes-achievement-audit.csv"),
    [string]$AddonRoot = (Join-Path $PSScriptRoot "..\addons\Collectionist")
)

$ErrorActionPreference = "Stop"

function ConvertTo-LuaString($value) {
    $text = ([string]$value).Replace("\", "\\").Replace('"', '\"')
    $text = $text.Replace("`r`n", "\n").Replace("`r", "\n").Replace("`n", "\n")
    return '"' + $text + '"'
}
function Write-Utf8File([string]$path, [string]$text) {
    $directory = Split-Path -Parent $path
    if (-not (Test-Path -LiteralPath $directory)) {
        New-Item -ItemType Directory -Force -Path $directory | Out-Null
    }
    [System.IO.File]::WriteAllText($path, $text, [System.Text.UTF8Encoding]::new($false))
}
function Assert-Equal($actual, $expected, [string]$label) {
    if ($actual -ne $expected) { throw "$label mismatch: expected $expected, got $actual" }
}
function Get-CatalogPlacement($achievement) {
    $title = [string]$achievement.Title_lang
    $description = [string]$achievement.Description_lang
    $text = "$title $description"

    if ([string]$achievement.Category -in @("15118", "15119")) {
        return @("collections", "pets")
    }
    if ($text -match '(?i)Glyph Hunter') {
        return @("exploration", "glyphs")
    }
    if ([string]$achievement.Category -eq "15462" -or [string]$achievement.ID -in @("18928", "18929", "18931")) {
        return @("features", "dragonriding")
    }
    if ($text -match '(?i)delve' -or $title -match '(?i)Delver|Discoveries|Stories') {
        return @("features", "delves")
    }
    if ($text -match '(?i)Abundance') {
        return @("features", "events")
    }
    if ($text -match '(?i)battle pet|pet battle|Safari|pet trainer|Pet Tamer|companion pet') {
        return @("collections", "pets")
    }
    if ($text -match '(?i)mount|reins|drake|mammoth') {
        return @("collections", "mounts")
    }
    if ($text -match '(?i)\btoy|Minis|figures|Hearthstone cards') {
        return @("collections", "toys")
    }
    if ($text -match '(?i)fish|fishing') {
        return @("features", "professions")
    }
    if ($text -match '(?i)War Supply|War Mode|Supply Crate') {
        return @("features", "war_effort")
    }
    return @("exploration", "zone")
}

$achievementPath = Join-Path $CurrentDb2Root "Achievement.csv"
if (-not (Test-Path -LiteralPath $achievementPath)) { throw "Missing DB2 table: $achievementPath" }
$achievementByID = @{}
foreach ($row in @(Import-Csv -LiteralPath $achievementPath)) {
    $achievementByID[[string]$row.ID] = $row
}

# Exclude this generator's output so the comparison remains stable on reruns.
$tracked = [System.Collections.Generic.HashSet[string]]::new()
$moduleRoot = Join-Path $AddonRoot "Modules"
foreach ($path in @(Get-ChildItem -LiteralPath $moduleRoot -Recurse -File -Filter "*.lua" |
        Where-Object Name -ne "HandyNotes.lua")) {
    foreach ($match in [regex]::Matches((Get-Content -Raw -LiteralPath $path.FullName),
            '\bachievementID\s*=\s*(\d+)')) {
        [void]$tracked.Add($match.Groups[1].Value)
    }
}

$pluginExpansion = [ordered]@{
    HandyNotes_WorldOfWarcraft             = "classic"
    HandyNotes_TheBurningCrusade           = "tbc"
    HandyNotes_WrathOfTheLichKing          = "wrath"
    HandyNotes_Cataclysm                   = "cataclysm"
    HandyNotes_MistsOfPandaria             = "mists_of_pandaria"
    HandyNotes_MistsOfPandariaTreasures    = "mists_of_pandaria"
    HandyNotes_WarlordsOfDraenor           = "wod"
    HandyNotes_TreasureHunter              = "wod"
    HandyNotes_LegionTreasures             = "legion"
    HandyNotes_BattleForAzeroth            = "battle_for_azeroth"
    HandyNotes_BattleForAzerothTreasures   = "battle_for_azeroth"
    HandyNotes_Shadowlands                 = "shadowlands"
    HandyNotes_ShadowlandsTreasures        = "shadowlands"
    HandyNotes_Dragonflight                = "dragonflight"
    HandyNotes_DragonflightTreasures       = "dragonflight"
    HandyNotes_TheWarWithin                = "tww"
    HandyNotes_WarWithin                   = "tww"
    HandyNotes_Midnight                    = "midnight"
    HandyNotes_MidnightTreasures           = "midnight"
}

$declarations = [System.Collections.Generic.List[object]]::new()
foreach ($plugin in $pluginExpansion.Keys) {
    $root = Join-Path $HandyNotesRoot $plugin
    if (-not (Test-Path -LiteralPath $root)) { throw "Missing HandyNotes source: $root" }
    foreach ($path in @(Get-ChildItem -LiteralPath $root -Recurse -File -Filter "*.lua" |
            Where-Object { $_.FullName -notmatch '\\(core|handler|libs|localization|locales)\\' })) {
        $text = Get-Content -Raw -LiteralPath $path.FullName
        foreach ($match in [regex]::Matches($text,
                '(?s)(?<![A-Za-z0-9_])(?:ns\.reward\.)?Achievement\s*\(\s*\{(?<body>.*?)\}\s*\)')) {
            $lineStart = $text.LastIndexOf([char]10, [Math]::Max(0, $match.Index - 1)) + 1
            if ($text.Substring($lineStart, $match.Index - $lineStart) -match '--') { continue }
            if ($match.Groups['body'].Value -notmatch '\bid\s*=\s*(\d+)') { continue }
            $declarations.Add([pscustomobject]@{
                plugin = $plugin
                id = $Matches[1]
                file = $path.FullName.Substring($root.Length + 1)
            })
        }
        foreach ($match in [regex]::Matches($text,
                '(?m)(?<![A-Za-z0-9_])achievement\s*=\s*(\d+)')) {
            $lineStart = $text.LastIndexOf([char]10, [Math]::Max(0, $match.Index - 1)) + 1
            if ($text.Substring($lineStart, $match.Index - $lineStart) -match '--') { continue }
            $declarations.Add([pscustomobject]@{
                plugin = $plugin
                id = $match.Groups[1].Value
                file = $path.FullName.Substring($root.Length + 1)
            })
        }
    }
}
$declarations = @($declarations | Sort-Object plugin, id, file -Unique)

$missingGroups = @($declarations | Where-Object {
    -not $tracked.Contains([string]$_.id) -and
    $achievementByID.ContainsKey([string]$_.id) -and
    [string]$achievementByID[[string]$_.id].Criteria_tree -ne "0"
} | Group-Object id)
Assert-Equal $missingGroups.Count 215 "Visible current HandyNotes achievement gap"

$manualExpansionByID = @{
    "1257" = "tbc"
    "4958" = "cataclysm"
    "6585" = "classic"
    "6586" = "classic"
    "6587" = "tbc"
    "6588" = "wrath"
    "6589" = "mists_of_pandaria"
    "8397" = "mists_of_pandaria"
    "9713" = "wod"
    "11233" = "legion"
    "17366" = "classic"
    "17367" = "classic"
}

$auditRows = foreach ($group in $missingGroups) {
    $id = [string]$group.Name
    $achievement = $achievementByID[$id]
    $plugins = @($group.Group.plugin | Sort-Object -Unique)
    $files = @($group.Group | Sort-Object plugin, file | ForEach-Object { "$($_.plugin):$($_.file)" } | Sort-Object -Unique)

    $expansion = $manualExpansionByID[$id]
    $basis = if ($expansion) { "content_override" } else { "handynotes_provider" }
    if (-not $expansion) {
        foreach ($plugin in $pluginExpansion.Keys) {
            if ($plugin -in $plugins) {
                $expansion = $pluginExpansion[$plugin]
                break
            }
        }
    }
    if (-not $expansion) { throw "No expansion placement for achievement $id" }

    $placement = Get-CatalogPlacement $achievement
    [pscustomobject][ordered]@{
        acquisition_expansion = $expansion
        achievement_id        = $achievement.ID
        name                  = $achievement.Title_lang
        description           = $achievement.Description_lang
        category              = $placement[0]
        source                = $placement[1]
        db2_category_id       = $achievement.Category
        criteria_tree_id      = $achievement.Criteria_tree
        provider_plugins      = $plugins -join ";"
        provider_files        = $files -join ";"
        attribution_basis     = $basis
    }
}
$auditRows = @($auditRows | Sort-Object acquisition_expansion, category, source, { [int]$_.achievement_id })
Assert-Equal @($auditRows | Group-Object achievement_id | Where-Object Count -gt 1).Count 0 "Duplicate achievement audit ID"
$expectedExpansionCounts = [ordered]@{
    classic = 4; tbc = 2; wrath = 6; cataclysm = 2; mists_of_pandaria = 6; wod = 8
    legion = 3; battle_for_azeroth = 23; shadowlands = 14; dragonflight = 37; tww = 60; midnight = 50
}
foreach ($pair in $expectedExpansionCounts.GetEnumerator()) {
    Assert-Equal @($auditRows | Where-Object acquisition_expansion -eq $pair.Key).Count $pair.Value "$($pair.Key) achievement placement count"
}
$expectedCatalogCounts = [ordered]@{
    "collections|pets" = 79; "collections|mounts" = 3; "collections|toys" = 4
    "exploration|glyphs" = 5; "exploration|zone" = 30
    "features|delves" = 23; "features|dragonriding" = 45; "features|events" = 18
    "features|professions" = 4; "features|war_effort" = 4
}
foreach ($pair in $expectedCatalogCounts.GetEnumerator()) {
    $category, $source = $pair.Key -split '\|'
    Assert-Equal @($auditRows | Where-Object { $_.category -eq $category -and $_.source -eq $source }).Count $pair.Value "$($pair.Key) achievement catalog count"
}

$csv = @($auditRows | ConvertTo-Csv -NoTypeInformation) -join "`n"
Write-Utf8File $AuditPath ($csv + "`n")

$contentKeys = [ordered]@{
    classic = "vanilla"; tbc = "tbc"; wrath = "wrath"; cataclysm = "cata"
    mists_of_pandaria = "mop"; wod = "wod"; legion = "legion"
    battle_for_azeroth = "bfa"; shadowlands = "shadowlands"; dragonflight = "df"
    tww = "tww"; midnight = "midnight"
}
$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add("local _, MC = ...")
$lines.Add("")
$lines.Add("-- Visible current achievements referenced by installed HandyNotes data but absent")
$lines.Add("-- from Collectionist's expansion-category manifests. Generated from an exact")
$lines.Add("-- $($auditRows.Count)-row provider and DB2 audit.")
foreach ($content in $contentKeys.GetEnumerator()) {
    $expansionRows = @($auditRows | Where-Object acquisition_expansion -eq $content.Key)
    if ($expansionRows.Count -eq 0) { continue }
    $lines.Add("")
    $lines.Add("MC.RegisterContent($(ConvertTo-LuaString $content.Value), `"achievements`", {")
    foreach ($catalogGroup in @($expansionRows | Group-Object category, source | Sort-Object Name)) {
        $first = $catalogGroup.Group[0]
        $lines.Add("    { category = $(ConvertTo-LuaString $first.category), source = $(ConvertTo-LuaString $first.source), achievements = {")
        foreach ($row in @($catalogGroup.Group | Sort-Object { [int]$_.achievement_id })) {
            $lines.Add("        { achievementID = $($row.achievement_id), name = $(ConvertTo-LuaString $row.name), description = $(ConvertTo-LuaString $row.description) },")
        }
        $lines.Add("    } },")
    }
    $lines.Add("})")
}
$luaPath = Join-Path $AddonRoot "Modules\Achievements\Data\HandyNotes.lua"
Write-Utf8File $luaPath ((@($lines) -join "`n") + "`n")

Write-Output "Generated $($auditRows.Count) audited HandyNotes achievements at $AuditPath"
$auditRows | Group-Object acquisition_expansion | Sort-Object Name | Select-Object Count, Name | Format-Table -AutoSize
Write-Output "Generated runtime achievement data at $luaPath"
