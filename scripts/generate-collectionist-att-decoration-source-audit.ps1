param(
    [string]$CurrentDb2Root = (Join-Path $env:TEMP "collectionist-tww-db2\current"),
    [string]$AttCategoriesRoot = (Join-Path $env:TEMP "collectionist-att-12007\db\Standard\Categories"),
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

function Get-TrackedIDs {
    $ids = [System.Collections.Generic.HashSet[string]]::new()
    $root = Join-Path $AddonRoot "Modules\Decorations\Data"
    foreach ($path in @(Get-ChildItem -LiteralPath $root -File -Filter "*.lua")) {
        foreach ($match in [regex]::Matches((Get-Content -Raw -LiteralPath $path.FullName), 'decorID\s*=\s*(\d+)')) {
            [void]$ids.Add($match.Groups[1].Value)
        }
    }
    return $ids
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

$decorations = Read-Table "HouseDecor"
$items = New-Index (Read-Table "ItemSparse")
$tracked = Get-TrackedIDs
$candidates = @($decorations | Where-Object {
    -not $tracked.Contains([string]$_.ID) -and $items.ContainsKey([string]$_.ItemID)
})

$housingPath = Join-Path $AttCategoriesRoot "Housing.lua"
$extractor = Join-Path $PSScriptRoot "extract-att-housing-sources.lua"
$housingRows = @(& $LuaJit $extractor $housingPath | ConvertFrom-Csv)
if ($LASTEXITCODE -ne 0) { throw "ATT housing extraction failed with exit code $LASTEXITCODE" }
$housingByDecor = $housingRows | Group-Object decor_id -AsHashTable -AsString

$attFilesByDecor = @{}
foreach ($path in @(Get-ChildItem -LiteralPath $AttCategoriesRoot -Recurse -File -Filter "*.lua")) {
    foreach ($match in [regex]::Matches((Get-Content -Raw -LiteralPath $path.FullName), '\bde\((\d+)')) {
        $id = $match.Groups[1].Value
        if (-not $attFilesByDecor.ContainsKey($id)) {
            $attFilesByDecor[$id] = [System.Collections.Generic.HashSet[string]]::new()
        }
        [void]$attFilesByDecor[$id].Add($path.Name)
    }
}

$actionableFiles = @(
    "Character.lua", "Secrets.lua", "Craftables.lua", "Delves.lua",
    "Holidays.lua", "Professions.lua", "ExpansionFeatures.lua", "Instances.lua",
    "PVP.lua", "WorldEvents.lua", "Zones.lua"
)

$audit = foreach ($decor in $candidates) {
    $id = [string]$decor.ID
    $files = @($attFilesByDecor[$id] | Sort-Object)
    $housing = @($housingByDecor[$id])
    if ($housing.Count -eq 1 -and $null -eq $housing[0]) { $housing = @() }
    $directHousing = @($housing | Where-Object source_kind)
    $sourceFiles = @($files | Where-Object { $_ -in $actionableFiles })
    $onlyNeverImplemented = $files.Count -gt 0 -and
        @($files | Where-Object { $_ -notin @("NeverImplemented.lua", "Unsorted.lua", "Housing.lua") }).Count -eq 0 -and
        "NeverImplemented.lua" -in $files
    $onlyExternal = $files.Count -gt 0 -and
        @($files | Where-Object { $_ -notin @("InGameShop.lua", "Promotions.lua", "Housing.lua", "Unsorted.lua") }).Count -eq 0 -and
        @($files | Where-Object { $_ -in @("InGameShop.lua", "Promotions.lua") }).Count -gt 0

    $decision = if ($directHousing.Count) { "source_ancestry_available" }
        elseif ($sourceFiles.Count) { "source_file_lead_available" }
        elseif ($onlyNeverImplemented) { "exclude_never_implemented_only" }
        elseif ($onlyExternal) { "exclude_external_only" }
        elseif ($files.Count -eq 0) { "defer_no_att_record" }
        else { "defer_catalog_or_unsorted_only" }

    $item = $items[[string]$decor.ItemID]
    [pscustomobject][ordered]@{
        decision               = $decision
        decision_basis         = if ($decision -eq "source_ancestry_available") { "att_housing_direct_quest_or_npc_ancestry" }
            elseif ($decision -eq "source_file_lead_available") { "att_acquisition_category_contains_decor" }
            elseif ($decision -eq "exclude_never_implemented_only") { "att_never_implemented_without_live_source" }
            elseif ($decision -eq "exclude_external_only") { "att_shop_or_promotion_without_ingame_source" }
            elseif ($decision -eq "defer_no_att_record") { "current_db2_item_has_no_att_decor_record" }
            else { "att_catalog_or_unsorted_record_has_no_acquisition_source" }
        decor_id               = $decor.ID
        item_id                = $decor.ItemID
        name                   = $decor.Name_lang
        item_name              = $item.Display_lang
        item_expansion_id      = $item.ExpansionID
        att_files              = $files -join ";"
        housing_source_kinds   = @($directHousing.source_kind | Sort-Object -Unique) -join ";"
        housing_source_ids     = @($directHousing.source_id | Sort-Object -Unique) -join ";"
        housing_map_ids        = @($directHousing.map_ids | Where-Object { $_ } | Sort-Object -Unique) -join ";"
        housing_patches        = @($directHousing.available_patches | Where-Object { $_ } | Sort-Object -Unique) -join ";"
        housing_ancestry       = @($directHousing.ancestry | Sort-Object -Unique) -join ";"
    }
}

$audit = @($audit | Sort-Object { [int]$_.decor_id })
$auditPath = Join-Path $AuditRoot "att-decoration-source-audit.csv"
Write-CsvFile $auditPath $audit

$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add("# ATT decoration source coverage audit")
$lines.Add("")
$lines.Add("Every current item-backed decoration missing from Collectionist is cross-checked against ATT's full category corpus. Direct quest/NPC ancestry from Housing is separated from category-level source leads, external-only records, never-implemented records, and unresolved catalog records.")
$lines.Add("")
$lines.Add("## Result")
$lines.Add("")
$lines.Add("- Current item-backed decoration gaps: $($audit.Count)")
$lines.Add("- Direct ATT source ancestry available: $(@($audit | Where-Object decision -eq 'source_ancestry_available').Count)")
$lines.Add("- Additional ATT acquisition-category leads: $(@($audit | Where-Object decision -eq 'source_file_lead_available').Count)")
$lines.Add("- Catalog/unsorted-only deferrals: $(@($audit | Where-Object decision -eq 'defer_catalog_or_unsorted_only').Count)")
$lines.Add("- External-only exclusions: $(@($audit | Where-Object decision -eq 'exclude_external_only').Count)")
$lines.Add("- Never-implemented-only exclusions: $(@($audit | Where-Object decision -eq 'exclude_never_implemented_only').Count)")
$lines.Add("- No ATT record: $(@($audit | Where-Object decision -eq 'defer_no_att_record').Count)")
$lines.Add("")
$lines.Add("## Interpretation")
$lines.Add("")
$lines.Add("The prior Housing-only pass understated ATT coverage because some generated factory payloads store children directly on the node rather than under g, and because acquisition records also live in zone, profession, instance, PvP, holiday, and expansion-feature categories. The direct ancestry rows can proceed to expansion/source adjudication now; category-level leads need their local ATT ancestry extracted before ingestion.")
$lines.Add("")
$lines.Add("Theme and item DB2 expansion values remain non-authoritative. Expansion ownership must follow the content that actually awards the decoration.")
Write-Utf8File (Join-Path $AuditRoot "att-decoration-source-audit.md") ((@($lines) -join "`n") + "`n")

Write-Host "Wrote $($audit.Count) decoration source decisions to $auditPath"
