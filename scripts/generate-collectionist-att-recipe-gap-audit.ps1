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
    $root = Join-Path $AddonRoot "Modules\Recipes\Data"
    foreach ($path in @(Get-ChildItem -LiteralPath $root -File -Filter "*.lua")) {
        foreach ($match in [regex]::Matches((Get-Content -Raw -LiteralPath $path.FullName), '\bid\s*=\s*(\d+)')) {
            [void]$ids.Add($match.Groups[1].Value)
        }
    }
    return $ids
}

function Get-TradeCategoryPath([string]$id, $categoryByID) {
    $names = [System.Collections.Generic.List[string]]::new()
    $seen = [System.Collections.Generic.HashSet[string]]::new()
    $category = $categoryByID[$id]
    while ($category -and $seen.Add([string]$category.ID)) {
        $names.Insert(0, [string]$category.Name_lang)
        if ([int]$category.ParentTradeSkillCategoryID -le 0) { break }
        $category = $categoryByID[[string]$category.ParentTradeSkillCategoryID]
    }
    return @($names)
}

function Get-CategoryExpansionHint([string]$categoryPath, [string]$profession) {
    $hint = if ($categoryPath -match '^(Classic|Old World)') { "classic" }
        elseif ($categoryPath -match '^Outland') { "tbc" }
        elseif ($categoryPath -match '^Northrend') { "wrath" }
        elseif ($categoryPath -match '^Cataclysm') { "cataclysm" }
        elseif ($categoryPath -match '^(Pandaria|Pandaren)') { "mists_of_pandaria" }
        elseif ($categoryPath -match '(^|of )Draenor') { "wod" }
        elseif ($categoryPath -match '(^Legion|Broken Isles)') { "legion" }
        elseif ($categoryPath -match '^(Kul Tiran|Zandalari)') { "battle_for_azeroth" }
        elseif ($categoryPath -match '^Shadowlands') { "shadowlands" }
        elseif ($categoryPath -match '^Dragon Isles') { "dragonflight" }
        elseif ($categoryPath -match '^Khaz Algar') { "tww" }
        elseif ($categoryPath -match '^Midnight') { "midnight" }
        else { "unknown" }

    # A recipe cannot predate the profession that teaches it, even when the
    # live profession UI groups it under older-world materials.
    if ($profession -eq "Inscription" -and $hint -in @("classic", "tbc")) { return "wrath" }
    if ($profession -eq "Jewelcrafting" -and $hint -eq "classic") { return "tbc" }
    return $hint
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

$abilities = Read-Table "SkillLineAbility"
$spellByID = New-Index (Read-Table "SpellName")
$categoryByID = New-Index (Read-Table "TradeSkillCategory")
$tracked = Get-TrackedIDs
$professionNames = @{
    "171" = "Alchemy"; "164" = "Blacksmithing"; "185" = "Cooking"
    "333" = "Enchanting"; "202" = "Engineering"; "773" = "Inscription"
    "755" = "Jewelcrafting"; "165" = "Leatherworking"; "197" = "Tailoring"
}

$attSources = @{}
foreach ($path in @(Get-ChildItem -LiteralPath $AttCategoriesRoot -Recurse -File -Filter "*.lua")) {
    foreach ($match in [regex]::Matches((Get-Content -Raw -LiteralPath $path.FullName), '\br\((\d+)')) {
        $id = $match.Groups[1].Value
        if (-not $attSources.ContainsKey($id)) {
            $attSources[$id] = [System.Collections.Generic.HashSet[string]]::new()
        }
        [void]$attSources[$id].Add($path.Name)
    }
}

$audit = foreach ($group in @($abilities | Where-Object {
    $professionNames.ContainsKey([string]$_.SkillLine) -and
    [int]$_.TradeSkillCategoryID -gt 0 -and
    $spellByID.ContainsKey([string]$_.Spell) -and
    -not $tracked.Contains([string]$_.Spell)
} | Group-Object Spell)) {
    $ability = $group.Group[0]
    $id = [string]$ability.Spell
    $name = [string]$spellByID[$id].Name_lang
    $profession = $professionNames[[string]$ability.SkillLine]
    $pathNames = @(Get-TradeCategoryPath ([string]$ability.TradeSkillCategoryID) $categoryByID)
    $categoryPath = $pathNames -join " > "
    $sources = @($attSources[$id] | Sort-Object)
    $onlyNeverImplemented = $sources.Count -eq 1 -and $sources[0] -eq "NeverImplemented.lua"
    $nonRecipe = $categoryPath -match '(?i)> [^>]*Training$|> Optional Reagents$|> Appendix ' -or $name -eq $profession
    $decision = if ($nonRecipe) { "exclude_nonrecipe_ui_or_training" }
        elseif ($onlyNeverImplemented) { "exclude_att_never_implemented_only" }
        elseif ($sources.Count -eq 0) { "defer_not_in_att" }
        else { "confirmed_recipe_gap_needs_source_placement" }

    [pscustomobject][ordered]@{
        decision                = $decision
        decision_basis          = if ($decision -eq "confirmed_recipe_gap_needs_source_placement") { "current_named_trade_ability_and_att_recipe_but_not_collectionist" } else { "audit_filter" }
        category_expansion_hint = Get-CategoryExpansionHint $categoryPath $profession
        placement_status        = if ($decision -eq "confirmed_recipe_gap_needs_source_placement") { "needs_att_source_ancestry" } else { "not_applicable" }
        recipe_spell_id         = $id
        name                    = $name
        profession              = $profession
        profession_id           = $ability.SkillLine
        trade_category_id       = $ability.TradeSkillCategoryID
        trade_category_path     = $categoryPath
        acquire_method          = $ability.AcquireMethod
        skill_line_ability_id   = $ability.ID
        att_source_files        = $sources -join ";"
    }
}

$audit = @($audit | Sort-Object { [int]$_.recipe_spell_id })
$auditPath = Join-Path $AuditRoot "att-recipe-gap-audit.csv"
Write-CsvFile $auditPath $audit

$confirmed = @($audit | Where-Object decision -eq "confirmed_recipe_gap_needs_source_placement")
$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add("# ATT recipe coverage gap audit")
$lines.Add("")
$lines.Add("Current named retail profession abilities are compared with every Collectionist recipe and ATT's curated recipe catalog. Profession UI glossary/stat entries, optional-reagent internals, training steps, and ATT-only never-implemented recipes are classified separately.")
$lines.Add("")
$lines.Add("## Result")
$lines.Add("")
$lines.Add("- Current named trade-category abilities absent from Collectionist: $($audit.Count)")
$lines.Add("- Confirmed ATT recipe gaps needing source placement: $($confirmed.Count)")
$lines.Add("- Non-recipe UI/training exclusions: $(@($audit | Where-Object decision -eq 'exclude_nonrecipe_ui_or_training').Count)")
$lines.Add("- ATT never-implemented-only exclusions: $(@($audit | Where-Object decision -eq 'exclude_att_never_implemented_only').Count)")
$lines.Add("- DB2 abilities not corroborated by ATT: $(@($audit | Where-Object decision -eq 'defer_not_in_att').Count)")
$lines.Add("")
$lines.Add("## Confirmed gaps by profession")
$lines.Add("")
$lines.Add("| Profession | Count |")
$lines.Add("| --- | ---: |")
foreach ($group in @($confirmed | Group-Object profession | Sort-Object Count -Descending)) {
    $lines.Add("| $($group.Name) | $($group.Count) |")
}
$lines.Add("")
$lines.Add("## Category expansion hints")
$lines.Add("")
$lines.Add("| Hint | Count |")
$lines.Add("| --- | ---: |")
foreach ($group in @($confirmed | Group-Object category_expansion_hint | Sort-Object Count -Descending)) {
    $lines.Add("| $($group.Name) | $($group.Count) |")
}
$lines.Add("")
$lines.Add("## Interpretation")
$lines.Add("")
$lines.Add("These are real recipe catalog omissions, but the category expansion is only a routing hint. It is not final ownership: recipes grouped under an old profession tier can be newly restored or newly obtainable in a later expansion. Final ingestion must use ATT source ancestry or another acquisition source before assigning the expansion.")
Write-Utf8File (Join-Path $AuditRoot "att-recipe-gap-audit.md") ((@($lines) -join "`n") + "`n")

Write-Host "Wrote $($audit.Count) missing trade-ability decisions to $auditPath"
Write-Host "Confirmed ATT recipe gaps needing source placement: $($confirmed.Count)"
