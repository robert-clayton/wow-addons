param(
    [string]$CurrentDb2Root = (Join-Path $env:TEMP "collectionist-tww-db2\current"),
    [string]$AttTradingPostPath = (Join-Path $env:TEMP "collectionist-att-12007\db\Standard\Categories\TradingPost.lua"),
    [string]$AuditRoot = (Join-Path $PSScriptRoot "..\research\collectionist\sources"),
    [string]$AddonRoot = (Join-Path $PSScriptRoot "..\addons\Collectionist"),
    [string]$LuaJit = "luajit"
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

function Get-TrackedIDs([string]$module, [string]$pattern) {
    $ids = [System.Collections.Generic.HashSet[string]]::new()
    $root = Join-Path $AddonRoot "Modules\$module\Data"
    foreach ($path in @(Get-ChildItem -LiteralPath $root -File -Filter "*.lua")) {
        foreach ($match in [regex]::Matches((Get-Content -Raw -LiteralPath $path.FullName), $pattern)) {
            [void]$ids.Add($match.Groups[1].Value)
        }
    }
    return $ids
}

function ConvertTo-PatchName($value) {
    if (-not $value) { return "" }
    $number = [int]$value
    $major = [math]::Floor($number / 10000)
    $minor = [math]::Floor(($number % 10000) / 100)
    $patch = $number % 100
    return "$major.$minor.$patch"
}

function Get-Expansion($patch) {
    if (-not $patch) { return "unknown" }
    $number = [int]$patch
    if ($number -ge 120000) { return "midnight" }
    if ($number -ge 110000) { return "tww" }
    if ($number -ge 100000) { return "dragonflight" }
    return "unknown"
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

if (-not (Test-Path -LiteralPath $AttTradingPostPath)) {
    throw "Missing ATT Trading Post source: $AttTradingPostPath"
}

$extractor = Join-Path $PSScriptRoot "extract-att-trading-post-sources.lua"
$raw = @(& $LuaJit $extractor $AttTradingPostPath)
if ($LASTEXITCODE -ne 0) { throw "ATT Trading Post extraction failed with exit code $LASTEXITCODE" }
$attRows = @($raw | ConvertFrom-Csv)

$pets = New-Index (Read-Table "BattlePetSpecies")
$creatures = New-Index (Read-Table "Creature")
$mountsBySpell = @{}
foreach ($mount in Read-Table "Mount") {
    $key = [string]$mount.SourceSpellID
    if (-not $mountsBySpell.ContainsKey($key)) { $mountsBySpell[$key] = @() }
    $mountsBySpell[$key] += $mount
}
$toys = @{}
foreach ($toy in Read-Table "Toy") { $toys[[string]$toy.ItemID] = $toy }
$items = New-Index (Read-Table "ItemSparse")

$trackedPets = Get-TrackedIDs "Pets" 'speciesID\s*=\s*(\d+)'
$trackedMounts = Get-TrackedIDs "Mounts" 'mountID\s*=\s*(\d+)'
$trackedToys = Get-TrackedIDs "Toys" 'itemID\s*=\s*(\d+)'

$audit = foreach ($group in @($attRows | Group-Object kind, source_id)) {
    $occurrences = @($group.Group)
    $firstPatch = @($occurrences | Where-Object available_patch | ForEach-Object { [int]$_.available_patch } | Sort-Object | Select-Object -First 1)
    $firstPatch = if ($firstPatch.Count) { $firstPatch[0] } else { $null }
    $kind = [string]$occurrences[0].kind
    $sourceID = [string]$occurrences[0].source_id
    $record = $null
    $collectibleID = ""
    $name = ""
    $sourceType = ""
    $sourceText = ""
    $tracked = $false

    if ($kind -eq "pet") {
        $record = $pets[$sourceID]
        if ($record) {
            $collectibleID = [string]$record.ID
            $creature = $creatures[[string]$record.CreatureID]
            $name = if ($creature) { $creature.Name_lang } else { "" }
            $sourceType = $record.SourceTypeEnum
            $sourceText = $record.SourceText_lang
            $tracked = $trackedPets.Contains($collectibleID)
        }
    } elseif ($kind -eq "mount") {
        $matches = @($mountsBySpell[$sourceID])
        if ($matches.Count -gt 1) { throw "Multiple mount rows use source spell $sourceID" }
        if ($matches.Count -eq 1) {
            $record = $matches[0]
            $collectibleID = [string]$record.ID
            $name = $record.Name_lang
            $sourceType = $record.SourceTypeEnum
            $sourceText = $record.SourceText_lang
            $tracked = $trackedMounts.Contains($collectibleID)
        }
    } elseif ($kind -eq "toy") {
        $record = $toys[$sourceID]
        if ($record) {
            $collectibleID = $sourceID
            $item = $items[$sourceID]
            $name = if ($item) { $item.Display_lang } else { "" }
            $sourceType = $record.SourceTypeEnum
            $sourceText = $record.SourceText_lang
            $tracked = $trackedToys.Contains($collectibleID)
        }
    }

    $placeholder = $name -match '(?i)\b(PH|Test|DNT|DO NOT USE|Unused)\b'
    $decision = if (-not $record) { "defer_missing_current_db2_record" }
        elseif ($placeholder) { "exclude_placeholder_or_internal" }
        elseif ($tracked) { "already_tracked" }
        else { "confirmed_policy_gap" }
    $basis = if (-not $record) { "att_trading_post_entry_has_no_current_collectible_db2_row" }
        elseif ($placeholder) { "current_db2_name_marks_internal_or_placeholder" }
        elseif ($tracked) { "att_trading_post_entry_already_exists_in_collectionist_runtime" }
        else { "att_trading_post_acquisition_confirmed_but_current_policy_excludes_rotating_source" }

    [pscustomobject][ordered]@{
        decision              = $decision
        decision_basis        = $basis
        acquisition_expansion = Get-Expansion $firstPatch
        first_trading_post_patch = ConvertTo-PatchName $firstPatch
        first_patch_value     = $firstPatch
        kind                  = $kind
        collectible_id        = $collectibleID
        att_source_id         = $sourceID
        name                  = $name
        item_id               = (@($occurrences | Where-Object item_id | Select-Object -First 1).item_id)
        occurrence_count      = $occurrences.Count
        source_type_enum      = $sourceType
        source_text           = $sourceText
    }
}

$audit = @($audit | Sort-Object kind, { if ($_.collectible_id) { [int]$_.collectible_id } else { [int]$_.att_source_id } })
$auditPath = Join-Path $AuditRoot "trading-post-gap-audit.csv"
Write-CsvFile $auditPath $audit

$confirmed = @($audit | Where-Object decision -eq "confirmed_policy_gap")
$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add("# Trading Post collectible gap audit")
$lines.Add("")
$lines.Add("ATT's curated Trading Post catalog is compared with current retail DB2 and every Collectionist runtime data file. The first ATT availability patch assigns each item to the expansion in which it first became obtainable from the Trading Post, regardless of its older promotional or shop origin.")
$lines.Add("")
$lines.Add("## Result")
$lines.Add("")
$lines.Add("- Confirmed policy gaps: $($confirmed.Count)")
$lines.Add("- Already tracked: $(@($audit | Where-Object decision -eq 'already_tracked').Count)")
$lines.Add("- Missing current DB2 record: $(@($audit | Where-Object decision -eq 'defer_missing_current_db2_record').Count)")
$lines.Add("- Placeholder/internal: $(@($audit | Where-Object decision -eq 'exclude_placeholder_or_internal').Count)")
$lines.Add("")
$lines.Add("## Confirmed gaps by expansion and kind")
$lines.Add("")
$lines.Add("| Expansion | Mounts | Pets | Toys | Total |")
$lines.Add("| --- | ---: | ---: | ---: | ---: |")
foreach ($expansion in @("dragonflight", "tww", "midnight", "unknown")) {
    $rows = @($confirmed | Where-Object acquisition_expansion -eq $expansion)
    if ($rows.Count -eq 0) { continue }
    $mountCount = @($rows | Where-Object kind -eq "mount").Count
    $petCount = @($rows | Where-Object kind -eq "pet").Count
    $toyCount = @($rows | Where-Object kind -eq "toy").Count
    $lines.Add("| $expansion | $mountCount | $petCount | $toyCount | $($rows.Count) |")
}
$lines.Add("")
$lines.Add("## Interpretation")
$lines.Add("")
$lines.Add("Collectionist's current DB2 gap filter treats the Trading Post as an external-source exclusion. That is no longer a completeness-safe policy: these collectibles are acquired in game, rotate back into availability, and can be assigned to the expansion of their first Trading Post appearance. Rows marked `confirmed_policy_gap` are therefore real catalog omissions, not speculative preload records.")
$lines.Add("")
$lines.Add("The CSV retains every ATT catalog item, including already-tracked and source-incomplete rows, so later runs can detect source drift without re-adjudicating the whole category.")
Write-Utf8File (Join-Path $AuditRoot "trading-post-gap-audit.md") ((@($lines) -join "`n") + "`n")

Write-Host "Wrote $($audit.Count) ATT Trading Post catalog rows to $auditPath"
Write-Host "Confirmed Collectionist policy gaps: $($confirmed.Count)"
