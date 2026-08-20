param(
    [string]$CurrentDb2Root = (Join-Path $env:TEMP "collectionist-tww-db2\current"),
    [string]$AttHousingPath = (Join-Path $env:TEMP "collectionist-att-12007\db\Standard\Categories\Housing.lua"),
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
function Get-TrackedIDs([string]$module, [string]$pattern, [string]$excludedFile) {
    $ids = [System.Collections.Generic.HashSet[string]]::new()
    $root = Join-Path $AddonRoot "Modules\$module\Data"
    foreach ($path in @(Get-ChildItem -LiteralPath $root -File -Filter "*.lua" |
            Where-Object Name -ne $excludedFile)) {
        foreach ($match in [regex]::Matches((Get-Content -Raw -LiteralPath $path.FullName), $pattern)) {
            [void]$ids.Add($match.Groups[1].Value)
        }
    }
    return $ids
}
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
function Write-CsvFile([string]$path, $rows) {
    $csv = @($rows | ConvertTo-Csv -NoTypeInformation) -join "`n"
    Write-Utf8File $path ($csv + "`n")
}
function Assert-Equal($actual, $expected, [string]$label) {
    if ($actual -ne $expected) { throw "$label mismatch: expected $expected, got $actual" }
}
function Get-Source([string]$sourceType) {
    return @{
        "0" = "drop"; "1" = "quest"; "2" = "vendor"; "3" = "profession"
        "4" = "wild"; "5" = "achievement"; "6" = "event"
    }[[string]$sourceType]
}
function Write-RuntimeFile([string]$module, [string]$listKey, [string]$idField,
        [string]$outputName, $rows, [scriptblock]$entryBuilder) {
    $contentKeys = [ordered]@{
        classic = "vanilla"; tbc = "tbc"; wrath = "wrath"; cataclysm = "cata"
        mists_of_pandaria = "mop"; wod = "wod"; legion = "legion"
        battle_for_azeroth = "bfa"; shadowlands = "shadowlands"; dragonflight = "df"
        tww = "tww"; midnight = "midnight"
    }
    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add("local _, MC = ...")
    $lines.Add("")
    $lines.Add("-- Current DB2 collectible gaps confirmed by source audit.")
    $lines.Add("-- Generated from the exact $(@($rows).Count)-row include set.")
    foreach ($content in $contentKeys.GetEnumerator()) {
        $expansionRows = @($rows | Where-Object acquisition_expansion -eq $content.Key)
        if ($expansionRows.Count -eq 0) { continue }
        $lines.Add("")
        $lines.Add("MC.RegisterContent($(ConvertTo-LuaString $content.Value), $(ConvertTo-LuaString $module.ToLowerInvariant()), {")
        foreach ($sourceGroup in @($expansionRows | Group-Object source | Sort-Object Name)) {
            $lines.Add("    { source = $(ConvertTo-LuaString $sourceGroup.Name), $listKey = {")
            foreach ($row in @($sourceGroup.Group | Sort-Object { [int]$_.$idField })) {
                $lines.Add((& $entryBuilder $row))
            }
            $lines.Add("    } },")
        }
        $lines.Add("})")
    }
    $path = Join-Path $AddonRoot "Modules\$module\Data\$outputName"
    Write-Utf8File $path ((@($lines) -join "`n") + "`n")
}

$pets = Read-Table "BattlePetSpecies"
$creatures = New-Index (Read-Table "Creature")
$mounts = Read-Table "Mount"
$toys = Read-Table "Toy"
$decorations = Read-Table "HouseDecor"
$items = New-Index (Read-Table "ItemSparse")

# Non-wild pets -------------------------------------------------------------
$trackedPets = Get-TrackedIDs "Pets" 'speciesID\s*=\s*(\d+)' "DB2Gaps.lua"
$petExternalPattern = 'In-Game Shop|Trading Card Game|Trading Post|Promotion|Recruit-a-Friend|Collector''s Edition|BlizzCon|iCoke|Developers|\bPH\b|Test'
$petCandidates = @($pets | Where-Object {
    -not $trackedPets.Contains([string]$_.ID) -and $_.SummonSpellID -ne "0" -and
    [int]$_.SourceTypeEnum -ge 0 -and [int]$_.SourceTypeEnum -le 6 -and
    $_.SourceText_lang -notmatch $petExternalPattern -and
    [string]$creatures[[string]$_.CreatureID].Name_lang -notmatch $petExternalPattern
})
Assert-Equal $petCandidates.Count 97 "Non-wild pet source-audit queue"

$petExpansionIDs = [ordered]@{
    classic = @(57,220,232,235,237,286,287,291,301,307,331,332,629,630,1237)
    tbc = @(187)
    wrath = @(160,166,194,195,196,197,198,200,201,202,203,211,225,226,236,243,250,251,253,254)
    cataclysm = @(255,270,272,280,281,282,283,289,308,318,319,320,321,323,325,330,335,336,337,338,339,340,341,342,343,344,345,4508)
    mists_of_pandaria = @(115,381,820,821,848,855,856,1040,1061,1063,1142,1184,1276,1303,1320,1322,1331,1349,1351)
    wod = @(1384)
    legion = @(382,666,2003)
    tww = @(3361,3518,3525,3543,3544,3547,3550)
    midnight = @(4945)
}
$petExpansionByID = @{}
foreach ($pair in $petExpansionIDs.GetEnumerator()) {
    foreach ($id in $pair.Value) { $petExpansionByID[[string]$id] = $pair.Key }
}
$petAudit = @($petCandidates | Sort-Object { [int]$_.ID } | ForEach-Object {
    $id = [string]$_.ID
    $excluded = $id -in @("1757", "1758")
    $creature = $creatures[[string]$_.CreatureID]
    $expansion = $petExpansionByID[$id]
    if (-not $excluded -and -not $expansion) { throw "No expansion placement for pet species $id" }
    [pscustomobject][ordered]@{
        decision              = if ($excluded) { "exclude_unobtainable_or_internal" } else { "include" }
        decision_basis        = if ($excluded) { "confirmed_existing_legion_inventory_adjudication" } else { "current_db2_source_confirmed" }
        acquisition_expansion = $expansion
        unavailable           = $id -in @("187", "202", "243")
        species_id            = $_.ID
        name                  = if ($creature) { $creature.Name_lang } else { "" }
        creature_id           = $_.CreatureID
        pet_type_enum         = $_.PetTypeEnum
        summon_spell_id       = $_.SummonSpellID
        source_type_enum      = $_.SourceTypeEnum
        source_text           = $_.SourceText_lang
        source                = Get-Source $_.SourceTypeEnum
    }
})
$petIncludes = @($petAudit | Where-Object decision -eq "include")
Assert-Equal $petIncludes.Count 95 "Included non-wild pet gap count"
Write-CsvFile (Join-Path $AuditRoot "db2-pet-gap-audit.csv") $petAudit
Write-RuntimeFile "Pets" "pets" "species_id" "DB2Gaps.lua" $petIncludes {
    param($row)
    $parts = @(
        "speciesID = $($row.species_id)"
        "npcID = $($row.creature_id)"
        "name = $(ConvertTo-LuaString $row.name)"
        "petType = $([int]$row.pet_type_enum + 1)"
        "source = $(ConvertTo-LuaString $row.source)"
        "sourceInfo = $(ConvertTo-LuaString $row.source_text)"
    )
    if ([System.Convert]::ToBoolean($row.unavailable)) { $parts += "unavailable = true" }
    return "        { $($parts -join ', ') },"
}

# Mounts --------------------------------------------------------------------
$trackedMounts = Get-TrackedIDs "Mounts" 'mountID\s*=\s*(\d+)' "DB2Gaps.lua"
$mountExternalPattern = 'In-Game Shop|Trading Card Game|Trading Post|Promotion|Recruit-a-Friend|Collector''s Edition|BlizzCon|iCoke|\bPH\b|Test|Unused|DNT|Legacy'
$mountCandidates = @($mounts | Where-Object {
    -not $trackedMounts.Contains([string]$_.ID) -and
    [int]$_.SourceTypeEnum -ge 0 -and [int]$_.SourceTypeEnum -le 6 -and
    $_.SourceText_lang -notmatch $mountExternalPattern -and $_.Name_lang -notmatch $mountExternalPattern
})
Assert-Equal $mountCandidates.Count 23 "Mount source-audit queue"
$mountExcludedIDs = @("7", "12", "43", "123", "145")
$mountExpansionIDs = [ordered]@{
    wrath = @(552)
    mists_of_pandaria = @(462,484,485,488)
    wod = @(416)
    legion = @(633)
    shadowlands = @(1374)
    midnight = @(2492,2754,2818,2917,3005,3006,3007,3008,3009,3010)
}
$mountExpansionByID = @{}
foreach ($pair in $mountExpansionIDs.GetEnumerator()) {
    foreach ($id in $pair.Value) { $mountExpansionByID[[string]$id] = $pair.Key }
}
$mountAudit = @($mountCandidates | Sort-Object { [int]$_.ID } | ForEach-Object {
    $id = [string]$_.ID
    $excluded = $id -in $mountExcludedIDs
    $expansion = $mountExpansionByID[$id]
    if (-not $excluded -and -not $expansion) { throw "No expansion placement for mount $id" }
    [pscustomobject][ordered]@{
        decision              = if ($excluded) { "exclude_unobtainable_or_internal" } else { "include" }
        decision_basis        = if ($excluded) { "confirmed_existing_expansion_inventory_adjudication" } else { "current_db2_source_confirmed" }
        acquisition_expansion = $expansion
        unavailable           = $id -in @("462", "484", "485")
        mount_id              = $_.ID
        name                  = $_.Name_lang
        source_spell_id       = $_.SourceSpellID
        source_type_enum      = $_.SourceTypeEnum
        source_text           = $_.SourceText_lang
        source                = Get-Source $_.SourceTypeEnum
    }
})
$mountIncludes = @($mountAudit | Where-Object decision -eq "include")
Assert-Equal $mountIncludes.Count 18 "Included mount gap count"
Write-CsvFile (Join-Path $AuditRoot "db2-mount-gap-audit.csv") $mountAudit
Write-RuntimeFile "Mounts" "mounts" "mount_id" "DB2Gaps.lua" $mountIncludes {
    param($row)
    $parts = @(
        "mountID = $($row.mount_id)"
        "name = $(ConvertTo-LuaString $row.name)"
        "source = $(ConvertTo-LuaString $row.source)"
        "sourceInfo = $(ConvertTo-LuaString $row.source_text)"
    )
    if ([System.Convert]::ToBoolean($row.unavailable)) { $parts += "unavailable = true" }
    return "        { $($parts -join ', ') },"
}

# Toys ----------------------------------------------------------------------
$trackedToys = Get-TrackedIDs "Toys" 'itemID\s*=\s*(\d+)' "DB2Gaps.lua"
$toyRawCandidates = @($toys | Where-Object {
    -not $trackedToys.Contains([string]$_.ItemID) -and
    [int]$_.SourceTypeEnum -ge 0 -and [int]$_.SourceTypeEnum -le 6
})
Assert-Equal $toyRawCandidates.Count 96 "Raw toy DB2 gap count"
$toyCandidates = @($toyRawCandidates | Where-Object { [string]$_.ItemID -notin @("72223", "208883") })
Assert-Equal $toyCandidates.Count 94 "Toy source-audit queue"
$toyExpansionOverrides = @{
    "88566" = "classic"; "97919" = "classic"; "97921" = "classic"; "98552" = "classic"
    "90899" = "cataclysm"; "101571" = "cataclysm"; "105898" = "cataclysm"
}
$neverImplementedToyIDs = @("88587", "110586", "166851")
$toyAudit = @($toyCandidates | Sort-Object { [int]$_.ItemID } | ForEach-Object {
    $item = $items[[string]$_.ItemID]
    $neverImplemented = [string]$_.ItemID -in $neverImplementedToyIDs
    $included = $null -ne $item -and -not $neverImplemented
    $expansion = $null
    if ($included) {
        $expansion = $toyExpansionOverrides[[string]$_.ItemID]
        if (-not $expansion) {
            $itemID = [int]$_.ItemID
            $expansion = if ($itemID -ge 263000) { "midnight" }
                elseif ($itemID -ge 200000) { "dragonflight" }
                elseif ($itemID -ge 166000) { "battle_for_azeroth" }
                elseif ($itemID -ge 131000) { "legion" }
                elseif ($itemID -ge 108000) { "wod" }
                else { "mists_of_pandaria" }
        }
    }
    [pscustomobject][ordered]@{
        decision              = if ($included) { "include" } elseif ($neverImplemented) { "exclude_never_implemented" } else { "exclude_missing_current_item" }
        decision_basis        = if ($included) { "current_toy_and_item_db2_source_confirmed" } elseif ($neverImplemented) { "confirmed_att_never_implemented_catalog" } else { "toy_row_has_no_current_itemsparse_record" }
        acquisition_expansion = $expansion
        toy_id                = $_.ID
        item_id               = $_.ItemID
        name                  = if ($item) { $item.Display_lang } else { "" }
        item_expansion_id     = if ($item) { $item.ExpansionID } else { "" }
        source_type_enum      = $_.SourceTypeEnum
        source_text           = $_.SourceText_lang
        source                = Get-Source $_.SourceTypeEnum
    }
})
$toyIncludes = @($toyAudit | Where-Object decision -eq "include")
Assert-Equal $toyIncludes.Count 75 "Included toy gap count"
Assert-Equal @($toyAudit | Where-Object decision -eq "exclude_missing_current_item").Count 16 "Missing-current-item toy exclusion count"
Assert-Equal @($toyAudit | Where-Object decision -eq "exclude_never_implemented").Count 3 "Never-implemented toy exclusion count"
Write-CsvFile (Join-Path $AuditRoot "db2-toy-gap-audit.csv") $toyAudit
Write-RuntimeFile "Toys" "toys" "item_id" "DB2Gaps.lua" $toyIncludes {
    param($row)
    return "        { itemID = $($row.item_id), name = $(ConvertTo-LuaString $row.name), source = $(ConvertTo-LuaString $row.source), sourceInfo = $(ConvertTo-LuaString $row.source_text) },"
}

# Decorations ---------------------------------------------------------------
$trackedDecor = Get-TrackedIDs "Decorations" 'decorID\s*=\s*(\d+)' "DB2Gaps.lua"
$decorCandidates = @($decorations | Where-Object {
    -not $trackedDecor.Contains([string]$_.ID) -and $items.ContainsKey([string]$_.ItemID)
})
Assert-Equal $decorCandidates.Count 816 "Item-backed decoration source-audit queue"

$attByDecor = @{}
if (Test-Path -LiteralPath $AttHousingPath) {
    $extractor = Join-Path $PSScriptRoot "extract-att-housing-sources.lua"
    $attRows = @(& luajit $extractor $AttHousingPath | ConvertFrom-Csv)
    $attByDecor = $attRows | Group-Object decor_id -AsHashTable -AsString
}
$decorAudit = @($decorCandidates | Sort-Object { [int]$_.ID } | ForEach-Object {
    $item = $items[[string]$_.ItemID]
    $attOccurrences = @($attByDecor[[string]$_.ID])
    if ($attOccurrences.Count -eq 1 -and $null -eq $attOccurrences[0]) { $attOccurrences = @() }
    [pscustomobject][ordered]@{
        decision              = "defer_acquisition_source_required"
        decision_basis        = if ($attOccurrences.Count) { "current_db2_item_backed_att_catalog_only" } else { "current_db2_item_backed_no_local_acquisition_source" }
        acquisition_expansion = ""
        decor_id              = $_.ID
        item_id               = $_.ItemID
        name                  = $_.Name_lang
        item_name             = $item.Display_lang
        item_expansion_id     = $item.ExpansionID
        att_occurrences       = $attOccurrences.Count
        att_source_ancestry   = @($attOccurrences.ancestry | Sort-Object -Unique) -join ";"
    }
})
Assert-Equal @($decorAudit | Where-Object { [int]$_.att_occurrences -gt 0 }).Count 377 "Decorations represented in local ATT housing data"
Write-CsvFile (Join-Path $AuditRoot "db2-decoration-gap-audit.csv") $decorAudit

Write-Output "DB2 gap audit complete"
Write-Output "Pets: 97 audited, 95 included, 2 confirmed internal"
Write-Output "Mounts: 23 audited, 18 included, 5 confirmed internal"
Write-Output "Toys: 94 audited, 75 included, 16 missing current item records, 3 confirmed never implemented"
Write-Output "Decorations: 816 item-backed gaps deferred pending acquisition sources (377 have ATT catalog ancestry)"
