param(
    [string]$CurrentDb2Root = (Join-Path $env:TEMP "collectionist-tww-db2\current"),
    [string]$AttCategoriesRoot = (Join-Path $env:TEMP "collectionist-att-12007\db\Standard\Categories"),
    [string]$AuditRoot = (Join-Path $PSScriptRoot "..\research\collectionist\sources"),
    [string]$AddonRoot = (Join-Path $PSScriptRoot "..\addons\Collectionist")
)

$ErrorActionPreference = "Stop"

function Read-Table([string]$name) {
    $path = Join-Path $CurrentDb2Root "$name.csv"
    if (-not (Test-Path -LiteralPath $path)) { throw "Missing DB2 table: $path" }
    return @(Import-Csv -LiteralPath $path)
}

function New-Index($rows, [string]$field = "ID") {
    $index = @{}
    foreach ($row in $rows) { $index[[string]$row.$field] = $row }
    return $index
}

function Get-TrackedIDs {
    $ids = [System.Collections.Generic.HashSet[string]]::new()
    foreach ($path in @(Get-ChildItem -LiteralPath $AddonRoot -Recurse -File -Filter "*.lua")) {
        foreach ($match in [regex]::Matches((Get-Content -Raw -LiteralPath $path.FullName), 'achievementID\s*=\s*(\d+)')) {
            [void]$ids.Add($match.Groups[1].Value)
        }
    }
    return $ids
}

function Get-CategoryPath([string]$id, $categoryByID) {
    $names = [System.Collections.Generic.List[string]]::new()
    $seen = [System.Collections.Generic.HashSet[string]]::new()
    $category = $categoryByID[$id]
    while ($category -and $seen.Add([string]$category.ID)) {
        $names.Insert(0, [string]$category.Name_lang)
        if ([int]$category.Parent -lt 0) { break }
        $category = $categoryByID[[string]$category.Parent]
    }
    return @($names)
}

function Write-Utf8File([string]$path, [string]$text) {
    $directory = Split-Path -Parent $path
    if (-not (Test-Path -LiteralPath $directory)) {
        New-Item -ItemType Directory -Force -Path $directory | Out-Null
    }
    [System.IO.File]::WriteAllText($path, $text, [System.Text.UTF8Encoding]::new($false))
}

function Write-CsvFile([string]$path, $rows) {
    $csv = @($rows | ConvertTo-Csv -NoTypeInformation) -join "`n"
    Write-Utf8File $path ($csv + "`n")
}

if (-not (Test-Path -LiteralPath $AttCategoriesRoot)) {
    throw "Missing ATT categories root: $AttCategoriesRoot"
}

$achievements = New-Index (Read-Table "Achievement")
$categoryByID = New-Index (Read-Table "Achievement_Category")
$tracked = Get-TrackedIDs
$resolvedAttRoot = (Resolve-Path -LiteralPath $AttCategoriesRoot).Path.TrimEnd("\")

$attSources = @{}
$attGuildIDs = [System.Collections.Generic.HashSet[string]]::new()
foreach ($path in @(Get-ChildItem -LiteralPath $AttCategoriesRoot -Recurse -File -Filter "*.lua")) {
    $relative = $path.FullName.Substring($resolvedAttRoot.Length + 1).Replace("\", "/")
    $content = Get-Content -Raw -LiteralPath $path.FullName
    foreach ($match in [regex]::Matches($content, '\bach\((\d+)')) {
        $id = $match.Groups[1].Value
        if (-not $attSources.ContainsKey($id)) {
            $attSources[$id] = [System.Collections.Generic.HashSet[string]]::new()
        }
        [void]$attSources[$id].Add($relative)
    }
    foreach ($match in [regex]::Matches($content, '\bgach\((\d+)')) {
        [void]$attGuildIDs.Add($match.Groups[1].Value)
    }
}
$attGuildExclusionCount = @($attGuildIDs | Where-Object {
    $achievements.ContainsKey([string]$_) -and -not $tracked.Contains([string]$_)
}).Count

$classifications = [System.Collections.Generic.List[object]]::new()
foreach ($id in @($attSources.Keys | Sort-Object { [int]$_ })) {
    if ($tracked.Contains($id)) { continue }
    $achievement = $achievements[$id]
    if (-not $achievement) {
        $classifications.Add([pscustomobject]@{ decision = "historical_att_only"; root = "" })
        continue
    }

    $flags = [int64]$achievement.Flags
    $pathNames = @(Get-CategoryPath ([string]$achievement.Category) $categoryByID)
    $root = if ($pathNames.Count) { $pathNames[0] } else { "Unknown" }
    $decision = if (($flags -band 16384) -ne 0 -or $root -eq "Guild") { "exclude_guild" }
        elseif (($flags -band 1) -ne 0 -or $root -eq "Statistics") { "exclude_statistic" }
        elseif ($achievement.Title_lang -match '(?i)<DND>|\bDNT\b|DO NOT USE|\[PH\]|\bNYI\b|UNUSED|\bQA\b|\bTEST\b') { "exclude_internal_label" }
        elseif (($flags -band 1048576) -ne 0 -or $achievement.Title_lang -match '(?i)Hidden Tracking|\bTracking\b') { "exclude_hidden_tracking" }
        elseif ([int]$achievement.Criteria_tree -le 0) { "defer_no_criteria_tree" }
        else { "confirmed_catalog_gap_needs_placement" }

    $classifications.Add([pscustomobject]@{
        decision = $decision
        root = $root
        row = [pscustomobject][ordered]@{
            decision          = $decision
            decision_basis    = if ($decision -eq "confirmed_catalog_gap_needs_placement") { "current_db2_player_facing_and_att_catalog_but_not_collectionist" } else { "audit_filter" }
            achievement_id    = $achievement.ID
            title             = $achievement.Title_lang
            description       = $achievement.Description_lang
            root_category     = $root
            category_id       = $achievement.Category
            category_path     = ($pathNames -join " > ")
            points            = $achievement.Points
            flags             = $achievement.Flags
            criteria_tree_id  = $achievement.Criteria_tree
            reward_item_id    = $achievement.RewardItemID
            att_source_files  = (@($attSources[$id] | Sort-Object) -join ";")
        }
    })
}

$candidates = @($classifications | Where-Object decision -eq "confirmed_catalog_gap_needs_placement" | ForEach-Object row)
$candidatePath = Join-Path $AuditRoot "att-achievement-gap-candidates.csv"
Write-CsvFile $candidatePath $candidates

$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add("# ATT achievement coverage gap audit")
$lines.Add("")
$lines.Add("Current retail achievement DB2 is cross-checked with achievement IDs curated by ATT and every Collectionist runtime data file. Statistics, hidden tracking records, guild-only records, explicit internal labels, and records without a criteria tree are separated before reporting player-facing catalog gaps.")
$lines.Add("")
$lines.Add("## Result")
$lines.Add("")
$lines.Add("- Player-facing catalog gaps needing expansion placement: $($candidates.Count)")
foreach ($decision in @("exclude_statistic", "exclude_hidden_tracking", "exclude_internal_label", "defer_no_criteria_tree", "historical_att_only")) {
    $label = $decision.Replace("_", " ")
    $lines.Add("- ${label}: $(@($classifications | Where-Object decision -eq $decision).Count)")
}
$lines.Add("- ATT guild-only catalog records excluded before the personal scan: $attGuildExclusionCount")
$lines.Add("")
$lines.Add("## Player-facing gaps by top-level category")
$lines.Add("")
$lines.Add("| Category | Count |")
$lines.Add("| --- | ---: |")
foreach ($group in @($candidates | Group-Object root_category | Sort-Object @{ Expression = "Count"; Descending = $true }, @{ Expression = "Name"; Ascending = $true })) {
    $lines.Add("| $($group.Name.Replace('|', '\|')) | $($group.Count) |")
}
$lines.Add("")
$lines.Add("## Interpretation")
$lines.Add("")
$lines.Add("The existing expansion-category manifests are internally complete, but they do not cover the cross-expansion achievement families above. The largest missing families are legacy/feat, profession, world-event, PvP, pet-battle, and collection achievements. These rows are confirmed live catalog records; needs_placement means their first obtainable expansion still has to be assigned without relying on achievement ID ranges or theme alone.")
$lines.Add("")
$lines.Add("This audit deliberately does not turn statistics or hidden tracking records into Collectionist goals.")
Write-Utf8File (Join-Path $AuditRoot "att-achievement-gap-audit.md") ((@($lines) -join "`n") + "`n")

Write-Host "Wrote $($candidates.Count) player-facing achievement gap candidates to $candidatePath"
