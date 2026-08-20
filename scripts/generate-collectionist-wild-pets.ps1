param(
    [string]$CurrentDb2Root = (Join-Path $env:TEMP "collectionist-tww-db2\current"),
    [string]$HandyNotesRoot = "X:\Program Files\World of Warcraft\_retail_\Interface\AddOns",
    [string]$AuditPath = (Join-Path $PSScriptRoot "..\research\collectionist\sources\wild-pet-acquisition-audit.csv"),
    [string]$AddonRoot = (Join-Path $PSScriptRoot "..\addons\Collectionist")
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "collectionist-wild-pet-rules.ps1")

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

$pets = Read-Table "BattlePetSpecies"
$creatures = New-Index (Read-Table "Creature")

# Deliberately exclude this generator's own output. The audit is the set that
# was missing from all other pet catalogs, so it remains stable on reruns.
$trackedSpecies = [System.Collections.Generic.HashSet[string]]::new()
$petDataRoot = Join-Path $AddonRoot "Modules\Pets\Data"
foreach ($path in @(Get-ChildItem -LiteralPath $petDataRoot -File -Filter "*.lua" |
        Where-Object Name -ne "WildPets.lua")) {
    foreach ($match in [regex]::Matches((Get-Content -Raw -LiteralPath $path.FullName), "speciesID\s*=\s*(\d+)")) {
        [void]$trackedSpecies.Add($match.Groups[1].Value)
    }
}

$wildPets = @($pets | Where-Object {
    -not $trackedSpecies.Contains([string]$_.ID) -and
    (Test-CollectionistCollectibleWildPet $_)
})
Assert-Equal $wildPets.Count 415 "Untracked collectible wild pet count"

$families = [ordered]@{
    classic              = "HandyNotes_WorldOfWarcraft"
    tbc                  = "HandyNotes_TheBurningCrusade"
    wrath                = "HandyNotes_WrathOfTheLichKing"
    cataclysm            = "HandyNotes_Cataclysm"
    mists_of_pandaria    = "HandyNotes_MistsOfPandaria"
    wod                  = "HandyNotes_WarlordsOfDraenor"
    legion               = "HandyNotes_LegionTreasures"
    battle_for_azeroth   = "HandyNotes_BattleForAzeroth"
    shadowlands          = "HandyNotes_Shadowlands"
    dragonflight         = "HandyNotes_Dragonflight"
}
$familyPetIDs = @{}
foreach ($family in $families.GetEnumerator()) {
    $root = Join-Path $HandyNotesRoot $family.Value
    if (-not (Test-Path -LiteralPath $root)) { throw "Missing HandyNotes source: $root" }
    $ids = [System.Collections.Generic.HashSet[string]]::new()
    foreach ($path in @(Get-ChildItem -LiteralPath $root -Recurse -File -Filter "*.lua")) {
        foreach ($match in [regex]::Matches((Get-Content -Raw -LiteralPath $path.FullName),
                "Pet\s*\(\s*\{\s*id\s*=\s*(\d+)")) {
            [void]$ids.Add($match.Groups[1].Value)
        }
    }
    $familyPetIDs[$family.Key] = $ids
}

$manualExpansionByID = @{
    # Current journal rows absent from the corresponding HandyNotes Safari lists.
    "456" = "classic"; "1157" = "classic"; "1158" = "classic"; "1159" = "classic"
    "1160" = "classic"; "1161" = "classic"; "1163" = "classic"
    "539" = "cataclysm"; "553" = "cataclysm"; "1062" = "cataclysm"; "1068" = "cataclysm"
    "715" = "mists_of_pandaria"; "1013" = "mists_of_pandaria"
    "1167" = "wrath"
}

$auditRows = foreach ($pet in $wildPets) {
    $id = [string]$pet.ID
    $expansion = $null
    $basis = $null
    foreach ($family in $families.GetEnumerator()) {
        if ($familyPetIDs[$family.Key].Contains($id)) {
            $expansion = $family.Key
            $basis = "handynotes_safari:$($family.Value)"
            break
        }
    }

    if ($manualExpansionByID.ContainsKey($id)) {
        $expansion = $manualExpansionByID[$id]
        $basis = "current_journal_source_location"
    } elseif ($id -in @("461", "463")) {
        # These are listed by the world plugin as shared critters, but their
        # capturable locations are the TBC starting zones.
        $expansion = "tbc"
        $basis = "current_journal_tbc_location_override"
    } elseif ($id -eq "1736") {
        # The BFA plugin repeats this Legion Safari pet.
        $expansion = "legion"
        $basis = "current_journal_legion_location_override"
    } elseif (-not $expansion) {
        $numericID = [int]$id
        if ($numericID -ge 1400 -and $numericID -le 1699) {
            $expansion = "wod"
        } elseif ($numericID -ge 1700 -and $numericID -le 2199) {
            $expansion = "legion"
        } elseif ($numericID -ge 2500 -and $numericID -le 3099) {
            $expansion = "battle_for_azeroth"
        } elseif ($numericID -ge 3100 -and $numericID -le 3259) {
            $expansion = "shadowlands"
        } elseif ($numericID -ge 3260) {
            $expansion = "dragonflight"
        }
        if ($expansion) { $basis = "current_journal_source_and_species_era" }
    }
    if (-not $expansion) { throw "No acquisition expansion for wild pet species $id" }

    $creature = $creatures[[string]$pet.CreatureID]
    [pscustomobject][ordered]@{
        acquisition_expansion = $expansion
        species_id             = $pet.ID
        name                   = if ($creature) { $creature.Name_lang } else { "" }
        creature_id            = $pet.CreatureID
        pet_type_enum          = $pet.PetTypeEnum
        flags                  = $pet.Flags
        source_type_enum       = $pet.SourceTypeEnum
        source_text            = $pet.SourceText_lang
        attribution_basis      = $basis
    }
}
$auditRows = @($auditRows | Sort-Object acquisition_expansion, { [int]$_.species_id })
Assert-Equal @($auditRows | Group-Object species_id | Where-Object Count -gt 1).Count 0 "Duplicate wild pet species"

$expectedCounts = [ordered]@{
    classic = 130; tbc = 4; wrath = 9; cataclysm = 11; mists_of_pandaria = 2
    wod = 32; legion = 49; battle_for_azeroth = 64; shadowlands = 61; dragonflight = 53
}
foreach ($pair in $expectedCounts.GetEnumerator()) {
    Assert-Equal @($auditRows | Where-Object acquisition_expansion -eq $pair.Key).Count $pair.Value "$($pair.Key) wild pet count"
}

$csv = @($auditRows | ConvertTo-Csv -NoTypeInformation) -join "`n"
Write-Utf8File $AuditPath ($csv + "`n")

$contentKeys = [ordered]@{
    classic = "vanilla"; tbc = "tbc"; wrath = "wrath"; cataclysm = "cata"
    mists_of_pandaria = "mop"; wod = "wod"; legion = "legion"
    battle_for_azeroth = "bfa"; shadowlands = "shadowlands"; dragonflight = "df"
}
$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add("local _, MC = ...")
$lines.Add("")
$lines.Add("-- Collectible wild pets omitted by summon-spell based historical inventories.")
$lines.Add("-- Generated from the exact $($auditRows.Count)-row wild-pet acquisition audit.")
foreach ($pair in $contentKeys.GetEnumerator()) {
    $rows = @($auditRows | Where-Object acquisition_expansion -eq $pair.Key | Sort-Object { [int]$_.species_id })
    $lines.Add("")
    $lines.Add("MC.RegisterContent($(ConvertTo-LuaString $pair.Value), `"pets`", {")
    $lines.Add("    { source = `"wild`", pets = {")
    foreach ($row in $rows) {
        $parts = @(
            "speciesID = $($row.species_id)"
            "npcID = $($row.creature_id)"
            "name = $(ConvertTo-LuaString $row.name)"
            "petType = $([int]$row.pet_type_enum + 1)"
            "source = `"wild`""
            "sourceInfo = $(ConvertTo-LuaString $row.source_text)"
        )
        $lines.Add("        { $($parts -join ', ') },")
    }
    $lines.Add("    } },")
    $lines.Add("})")
}
$luaPath = Join-Path $AddonRoot "Modules\Pets\Data\WildPets.lua"
Write-Utf8File $luaPath ((@($lines) -join "`n") + "`n")

Write-Output "Generated $($auditRows.Count) audited wild pets at $AuditPath"
Write-Output "Generated runtime pet data at $luaPath"
