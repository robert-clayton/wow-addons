[CmdletBinding()]
param(
    [string]$OutputDirectory = "",
    [string]$ExpectedTag = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot ".."))
$addonSource = Join-Path $repoRoot "addons/Collectionist"
$sharedLibrary = Join-Path $repoRoot "libs/MidnightUI-1.0"
$pkgMetaPath = Join-Path $addonSource ".pkgmeta"
if (-not (Test-Path -LiteralPath $addonSource -PathType Container)) {
    throw "Collectionist source directory was not found: $addonSource"
}
if (-not (Test-Path -LiteralPath $sharedLibrary -PathType Container)) {
    throw "MidnightUI source directory was not found: $sharedLibrary"
}
if (-not (Test-Path -LiteralPath $pkgMetaPath -PathType Leaf)) {
    throw "Packaging manifest was not found: $pkgMetaPath"
}

function Assert-PathWithin {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string]$Path
    )

    $resolvedRoot = [System.IO.Path]::GetFullPath($Root).TrimEnd(
        [System.IO.Path]::DirectorySeparatorChar,
        [System.IO.Path]::AltDirectorySeparatorChar)
    $resolvedPath = [System.IO.Path]::GetFullPath($Path)
    if ($resolvedPath -ne $resolvedRoot -and
        -not $resolvedPath.StartsWith(
            $resolvedRoot + [System.IO.Path]::DirectorySeparatorChar,
            [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Path escapes the expected root '$resolvedRoot': $resolvedPath"
    }
}

function Get-PkgMetaIgnorePatterns {
    param([Parameter(Mandatory = $true)][string]$Path)

    $patterns = [System.Collections.Generic.List[string]]::new()
    $inIgnore = $false
    foreach ($line in Get-Content -LiteralPath $Path) {
        if (-not $inIgnore) {
            if ($line -match '^ignore:\s*$') {
                $inIgnore = $true
            }
            continue
        }

        if ($line -match '^\S') { break }
        if ($line -notmatch '^\s*-\s+(.+?)\s*$') { continue }

        $pattern = $Matches[1].Trim()
        if (($pattern.StartsWith('"') -and $pattern.EndsWith('"')) -or
            ($pattern.StartsWith("'") -and $pattern.EndsWith("'"))) {
            $pattern = $pattern.Substring(1, $pattern.Length - 2)
        }
        if ([string]::IsNullOrWhiteSpace($pattern)) {
            throw "Empty ignore pattern in $Path"
        }
        $patterns.Add($pattern)
    }

    if (-not $inIgnore) {
        throw "$Path does not contain an ignore section"
    }
    return $patterns.ToArray()
}

function Get-IgnoredItems {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string]$Pattern
    )

    if ([System.IO.Path]::IsPathRooted($Pattern)) {
        throw "Absolute .pkgmeta ignore patterns are not allowed: $Pattern"
    }

    $normalizedPattern = $Pattern.Replace('\', '/').TrimStart('/')
    if ($normalizedPattern.Split('/') -contains '..') {
        throw "Parent traversal is not allowed in .pkgmeta ignore patterns: $Pattern"
    }

    $containsWildcard = $normalizedPattern.IndexOfAny([char[]]'*?[') -ge 0
    if (-not $containsWildcard) {
        $literalPath = Join-Path $Root ($normalizedPattern.Replace(
            '/', [System.IO.Path]::DirectorySeparatorChar))
        Assert-PathWithin -Root $Root -Path $literalPath
        if (Test-Path -LiteralPath $literalPath) {
            return @(Get-Item -LiteralPath $literalPath -Force)
        }
        return @()
    }

    $matchesBasename = -not $normalizedPattern.Contains('/')
    return @(Get-ChildItem -LiteralPath $Root -Recurse -Force | Where-Object {
        $relative = [System.IO.Path]::GetRelativePath($Root, $_.FullName).Replace('\', '/')
        if ($matchesBasename) {
            $_.Name -like $normalizedPattern
        } else {
            $relative -like $normalizedPattern
        }
    })
}

$tocSourcePath = Join-Path $addonSource "Collectionist.toc"
$changelogPath = Join-Path $addonSource "CHANGELOG.md"
$toc = @(Get-Content -LiteralPath $tocSourcePath)
$versionLines = @($toc | Where-Object { $_ -match '^## Version:\s*(.+)\s*$' })
if ($versionLines.Count -ne 1 -or $versionLines[0] -notmatch '^## Version:\s*(.+)\s*$') {
    throw "Collectionist.toc must contain exactly one Version field"
}
$version = $Matches[1].Trim()
$stableSemVerPattern = '^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$'
if ($version -notmatch $stableSemVerPattern) {
    throw "TOC version must be a stable semantic version (MAJOR.MINOR.PATCH): $version"
}

$firstChangelogLine = Get-Content -LiteralPath $changelogPath |
    Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
    Select-Object -First 1
if ($firstChangelogLine -ne "# $version") {
    throw "Top changelog heading '$firstChangelogLine' does not match TOC version $version"
}

if (-not [string]::IsNullOrWhiteSpace($ExpectedTag)) {
    if ($ExpectedTag -notmatch '^v(.+)$') {
        throw "Release tag must use the form vMAJOR.MINOR.PATCH: $ExpectedTag"
    }
    $tagVersion = $Matches[1]
    if ($tagVersion -notmatch $stableSemVerPattern) {
        throw "Release tag must be a stable semantic version: $ExpectedTag"
    }
    if ($tagVersion -ne $version) {
        throw "Release tag $ExpectedTag does not match TOC/changelog version $version"
    }
}

$ignorePatterns = @(Get-PkgMetaIgnorePatterns -Path $pkgMetaPath)
$requiredIgnorePatterns = @(
    '.pkgmeta',
    '.github',
    '.gitignore',
    '*.md',
    'Media/icon-source.png',
    'Media/curseforge-logo.png',
    'Media/screenshot*.png'
)
foreach ($requiredPattern in $requiredIgnorePatterns) {
    if ($ignorePatterns -cnotcontains $requiredPattern) {
        throw ".pkgmeta must exclude '$requiredPattern' from release packages"
    }
}

if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
    $OutputDirectory = Join-Path $repoRoot "dist"
} elseif (-not [System.IO.Path]::IsPathRooted($OutputDirectory)) {
    $OutputDirectory = Join-Path $repoRoot $OutputDirectory
}
$OutputDirectory = [System.IO.Path]::GetFullPath($OutputDirectory)
New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null

$stagingRoot = Join-Path $OutputDirectory (".collectionist-staging-" + [guid]::NewGuid().ToString("N"))
$stagedAddon = Join-Path $stagingRoot "Collectionist"
$stagedLibrary = Join-Path $stagedAddon "Libs/MidnightUI-1.0"

try {
    New-Item -ItemType Directory -Path $stagingRoot | Out-Null
    Copy-Item -LiteralPath $addonSource -Destination $stagedAddon -Recurse -Force

    # Development uses an ignored symlink. A release must contain actual
    # library files so a clean install is self-contained.
    if (Test-Path -LiteralPath $stagedLibrary) {
        Remove-Item -LiteralPath $stagedLibrary -Recurse -Force
    }
    New-Item -ItemType Directory -Path (Split-Path $stagedLibrary -Parent) -Force | Out-Null
    Copy-Item -LiteralPath $sharedLibrary -Destination $stagedLibrary -Recurse -Force

    foreach ($pattern in $ignorePatterns) {
        $ignoredItems = @(Get-IgnoredItems -Root $stagedAddon -Pattern $pattern)
        foreach ($item in $ignoredItems | Sort-Object { $_.FullName.Length } -Descending) {
            Assert-PathWithin -Root $stagedAddon -Path $item.FullName
            Remove-Item -LiteralPath $item.FullName -Recurse -Force
        }
    }

    foreach ($pattern in $ignorePatterns) {
        $remaining = @(Get-IgnoredItems -Root $stagedAddon -Pattern $pattern)
        if ($remaining.Count -gt 0) {
            $relativePaths = $remaining | ForEach-Object {
                [System.IO.Path]::GetRelativePath($stagedAddon, $_.FullName)
            }
            throw "Forbidden release files still match '$pattern': $($relativePaths -join ', ')"
        }
    }

    $links = @(Get-ChildItem -LiteralPath $stagedAddon -Recurse -Force | Where-Object {
        $_.Attributes -band [System.IO.FileAttributes]::ReparsePoint
    })
    if ($links.Count -gt 0) {
        $relativeLinks = $links | ForEach-Object {
            [System.IO.Path]::GetRelativePath($stagedAddon, $_.FullName)
        }
        throw "Release package must be self-contained; links remain: $($relativeLinks -join ', ')"
    }

    $tocPath = Join-Path $stagedAddon "Collectionist.toc"
    foreach ($line in $toc) {
        $entry = $line.Trim()
        if ($entry -eq "" -or $entry.StartsWith("#")) { continue }
        $entryPath = Join-Path $stagedAddon ($entry -replace '\\', [System.IO.Path]::DirectorySeparatorChar)
        Assert-PathWithin -Root $stagedAddon -Path $entryPath
        if (-not (Test-Path -LiteralPath $entryPath -PathType Leaf)) {
            throw "TOC entry is missing from staged package: $entry"
        }
    }

    $archivePath = Join-Path $OutputDirectory ("Collectionist-$version.zip")
    if (Test-Path -LiteralPath $archivePath) {
        Remove-Item -LiteralPath $archivePath -Force
    }
    Compress-Archive -LiteralPath $stagedAddon -DestinationPath $archivePath -CompressionLevel Optimal
    Write-Output $archivePath
} finally {
    if (Test-Path -LiteralPath $stagingRoot) {
        $resolvedOutput = [System.IO.Path]::GetFullPath($OutputDirectory).TrimEnd('\', '/')
        $resolvedStaging = [System.IO.Path]::GetFullPath($stagingRoot)
        if (-not $resolvedStaging.StartsWith($resolvedOutput + [System.IO.Path]::DirectorySeparatorChar,
                [System.StringComparison]::OrdinalIgnoreCase)) {
            throw "Refusing to remove staging path outside output directory: $resolvedStaging"
        }
        Remove-Item -LiteralPath $stagingRoot -Recurse -Force
    }
}
