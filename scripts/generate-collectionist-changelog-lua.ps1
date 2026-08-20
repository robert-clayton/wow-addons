<#
.SYNOPSIS
Turns CHANGELOG.md into Data/Changelog.lua so the addon can show "What's New".

.DESCRIPTION
The addon cannot read CHANGELOG.md at runtime - WoW gives no filesystem access,
and only files listed in the TOC are loaded. So the changelog has to ship as
Lua. This keeps CHANGELOG.md the single source of truth and generates from it,
rather than asking anyone to maintain the same notes twice.

Only the newest few versions are emitted. The whole history is thousands of
lines and nobody reads past the release they just installed.

Run this after editing CHANGELOG.md and before packaging.
#>
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
    [int]$Keep = 5
)

$ErrorActionPreference = "Stop"

$changelogPath = Join-Path $RepoRoot "addons/Collectionist/CHANGELOG.md"
$outPath       = Join-Path $RepoRoot "addons/Collectionist/Data/Changelog.lua"
if (-not (Test-Path -LiteralPath $changelogPath)) { throw "Missing $changelogPath" }

function ConvertTo-LuaString([string]$value) {
    if ($null -eq $value) { $value = "" }
    return '"' + ($value -replace '\\', '\\\\' -replace '"', '\"') + '"'
}

# Markdown -> WoW escape sequences. **bold** becomes gold, which is what the
# rest of the addon uses for emphasis; escaped brackets lose their backslash.
function Format-Line([string]$text) {
    $text = $text -replace '\*\*(.+?)\*\*', '|cffffd200$1|r'
    $text = $text -replace '\\([<>\[\]])', '$1'
    $text = $text -replace '`(.+?)`', '$1'
    return $text.Trim()
}

$versions = [System.Collections.Generic.List[object]]::new()
$current = $null
$section = $null

foreach ($line in [System.IO.File]::ReadLines($changelogPath)) {
    if ($line -match '^#\s+(.+?)\s*$') {
        if ($current) { $versions.Add($current) }
        if ($versions.Count -ge $Keep) { $current = $null; break }
        $current = [ordered]@{ version = $Matches[1].Trim(); sections = [System.Collections.Generic.List[object]]::new() }
        $section = $null
        continue
    }
    if (-not $current) { continue }
    if ($line -match '^###\s+(.+?)\s*$') {
        $section = [ordered]@{ heading = $Matches[1].Trim(); lines = [System.Collections.Generic.List[string]]::new() }
        $current.sections.Add($section)
        continue
    }
    if ($line -match '^\s*-\s+(.+?)\s*$' -and $section) {
        $section.lines.Add((Format-Line $Matches[1]))
        continue
    }
    # Continuation of a wrapped bullet.
    if ($line -match '^\s{2,}\S' -and $section -and $section.lines.Count -gt 0) {
        $section.lines[$section.lines.Count - 1] += " " + (Format-Line $line)
    }
}
if ($current) { $versions.Add($current) }
if ($versions.Count -eq 0) { throw "No version headings found in $changelogPath" }

$sb = [System.Text.StringBuilder]::new()
[void]$sb.AppendLine('local _, MC = ...')
[void]$sb.AppendLine()
[void]$sb.AppendLine('-- GENERATED FILE - do not edit.')
[void]$sb.AppendLine('-- Source: addons/Collectionist/CHANGELOG.md')
[void]$sb.AppendLine('-- Regenerate: scripts/generate-collectionist-changelog-lua.ps1')
[void]$sb.AppendLine('--')
[void]$sb.AppendLine('-- Newest first. WhatsNew.lua shows every entry newer than the version')
[void]$sb.AppendLine('-- the player last logged in on.')
[void]$sb.AppendLine('MC.CHANGELOG = {')
foreach ($v in $versions) {
    [void]$sb.AppendLine('    { version = ' + (ConvertTo-LuaString $v.version) + ', sections = {')
    foreach ($s in $v.sections) {
        [void]$sb.AppendLine('        { heading = ' + (ConvertTo-LuaString $s.heading) + ', lines = {')
        foreach ($l in $s.lines) {
            [void]$sb.AppendLine('            ' + (ConvertTo-LuaString $l) + ',')
        }
        [void]$sb.AppendLine('        } },')
    }
    [void]$sb.AppendLine('    } },')
}
[void]$sb.AppendLine('}')

$utf8 = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($outPath, ($sb.ToString() -replace "`r`n", "`n"), $utf8)

Write-Host ("Wrote {0} versions to {1}" -f $versions.Count, $outPath)
foreach ($v in $versions) {
    $n = 0; foreach ($s in $v.sections) { $n += $s.lines.Count }
    Write-Host ("  {0,-10} {1} sections, {2} entries" -f $v.version, $v.sections.Count, $n)
}
