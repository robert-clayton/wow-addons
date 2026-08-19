[CmdletBinding(DefaultParameterSetName = 'Archive')]
param(
    [Parameter(Mandatory = $true, ParameterSetName = 'Archive')]
    [string]$ArchivePath,

    [Parameter(Mandatory = $true, ParameterSetName = 'Directory')]
    [string]$AddonDirectory,

    [string]$LuaExecutable = 'luajit'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

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
        throw "Reference escapes the addon directory '$resolvedRoot': $resolvedPath"
    }
    return $resolvedPath
}

function Resolve-AddonReference {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string]$BaseDirectory,
        [Parameter(Mandatory = $true)][string]$Reference
    )

    if ([System.IO.Path]::IsPathRooted($Reference)) {
        throw "Addon references must be relative: $Reference"
    }
    $platformPath = $Reference.Replace('\', [System.IO.Path]::DirectorySeparatorChar).Replace(
        '/', [System.IO.Path]::DirectorySeparatorChar)
    return Assert-PathWithin -Root $Root -Path (Join-Path $BaseDirectory $platformPath)
}

$temporaryRoot = $null
try {
    if ($PSCmdlet.ParameterSetName -eq 'Archive') {
        $ArchivePath = [System.IO.Path]::GetFullPath($ArchivePath)
        if (-not (Test-Path -LiteralPath $ArchivePath -PathType Leaf)) {
            throw "Package archive was not found: $ArchivePath"
        }
        $temporaryRoot = Join-Path ([System.IO.Path]::GetTempPath()) (
            'collectionist-validation-' + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $temporaryRoot | Out-Null
        Expand-Archive -LiteralPath $ArchivePath -DestinationPath $temporaryRoot
        $AddonDirectory = Join-Path $temporaryRoot 'Collectionist'
    }

    $AddonDirectory = [System.IO.Path]::GetFullPath($AddonDirectory)
    if (-not (Test-Path -LiteralPath $AddonDirectory -PathType Container)) {
        throw "Collectionist addon directory was not found: $AddonDirectory"
    }

    $unexpectedRoots = @()
    if ($temporaryRoot) {
        $unexpectedRoots = @(Get-ChildItem -LiteralPath $temporaryRoot -Force |
            Where-Object { $_.Name -ne 'Collectionist' })
    }
    if ($unexpectedRoots.Count -gt 0) {
        throw "Package contains entries outside Collectionist/: $($unexpectedRoots.Name -join ', ')"
    }

    $forbiddenMatchers = @(
        { param($relative, $name) $relative -eq '.pkgmeta' },
        { param($relative, $name) $relative -eq '.gitignore' },
        { param($relative, $name) $relative -eq '.github' -or $relative.StartsWith('.github/') },
        { param($relative, $name) $name -like '*.md' },
        { param($relative, $name) $relative -eq 'Media/icon-source.png' },
        { param($relative, $name) $relative -eq 'Media/curseforge-logo.png' },
        { param($relative, $name) $relative -like 'Media/screenshot*.png' }
    )
    $forbidden = @(Get-ChildItem -LiteralPath $AddonDirectory -Recurse -Force | Where-Object {
        $relative = [System.IO.Path]::GetRelativePath($AddonDirectory, $_.FullName).Replace('\', '/')
        foreach ($matcher in $forbiddenMatchers) {
            if (& $matcher $relative $_.Name) { return $true }
        }
        return $false
    })
    if ($forbidden.Count -gt 0) {
        $relativeForbidden = $forbidden | ForEach-Object {
            [System.IO.Path]::GetRelativePath($AddonDirectory, $_.FullName)
        }
        throw "Package contains forbidden files: $($relativeForbidden -join ', ')"
    }

    $tocPath = Join-Path $AddonDirectory 'Collectionist.toc'
    if (-not (Test-Path -LiteralPath $tocPath -PathType Leaf)) {
        throw "Package is missing Collectionist.toc"
    }

    $pending = [System.Collections.Generic.Queue[string]]::new()
    foreach ($line in Get-Content -LiteralPath $tocPath) {
        $entry = $line.Trim()
        if ($entry -eq '' -or $entry.StartsWith('#')) { continue }
        $pending.Enqueue((Resolve-AddonReference -Root $AddonDirectory -BaseDirectory $AddonDirectory -Reference $entry))
    }

    $visited = [System.Collections.Generic.HashSet[string]]::new(
        [System.StringComparer]::Ordinal)
    while ($pending.Count -gt 0) {
        $path = $pending.Dequeue()
        if (-not $visited.Add($path)) { continue }
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            $relativeMissing = [System.IO.Path]::GetRelativePath($AddonDirectory, $path)
            throw "TOC/XML reference is missing: $relativeMissing"
        }

        if ([System.IO.Path]::GetExtension($path) -ine '.xml') { continue }
        try {
            [xml]$xml = Get-Content -LiteralPath $path -Raw
        } catch {
            $relativeXml = [System.IO.Path]::GetRelativePath($AddonDirectory, $path)
            throw "Invalid XML in ${relativeXml}: $($_.Exception.Message)"
        }
        $referenceNodes = $xml.SelectNodes(
            '//*[local-name()="Script" or local-name()="Include"][@file]')
        foreach ($node in $referenceNodes) {
            $pending.Enqueue((Resolve-AddonReference `
                -Root $AddonDirectory `
                -BaseDirectory (Split-Path $path -Parent) `
                -Reference $node.file))
        }
    }

    $shippedCode = @(Get-ChildItem -LiteralPath $AddonDirectory -Recurse -File |
        Where-Object { $_.Extension -in @('.lua', '.xml') })
    $unreferenced = @($shippedCode | Where-Object { -not $visited.Contains($_.FullName) })
    if ($unreferenced.Count -gt 0) {
        $relativeUnreferenced = $unreferenced | ForEach-Object {
            [System.IO.Path]::GetRelativePath($AddonDirectory, $_.FullName)
        }
        throw "Shipped Lua/XML files are not reachable from the TOC: $($relativeUnreferenced -join ', ')"
    }

    $compiler = Get-Command $LuaExecutable -CommandType Application -ErrorAction Stop
    $bytecodePath = Join-Path ([System.IO.Path]::GetTempPath()) (
        'collectionist-validation-' + [guid]::NewGuid().ToString('N') + '.ljbc')
    try {
        $luaFiles = @(Get-ChildItem -LiteralPath $AddonDirectory -Recurse -File -Filter '*.lua')
        foreach ($luaFile in $luaFiles) {
            & $compiler.Source -b $luaFile.FullName $bytecodePath
            if ($LASTEXITCODE -ne 0) {
                $relativeLua = [System.IO.Path]::GetRelativePath($AddonDirectory, $luaFile.FullName)
                throw "Lua compilation failed: $relativeLua"
            }
        }
    } finally {
        if (Test-Path -LiteralPath $bytecodePath) {
            Remove-Item -LiteralPath $bytecodePath -Force
        }
    }

    Write-Output "Validated $($shippedCode.Count) referenced Lua/XML files and compiled $($luaFiles.Count) Lua files."
} finally {
    if ($temporaryRoot -and (Test-Path -LiteralPath $temporaryRoot)) {
        $resolvedTempBase = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath()).TrimEnd(
            [System.IO.Path]::DirectorySeparatorChar,
            [System.IO.Path]::AltDirectorySeparatorChar)
        $resolvedTemporaryRoot = [System.IO.Path]::GetFullPath($temporaryRoot)
        if (-not $resolvedTemporaryRoot.StartsWith(
            $resolvedTempBase + [System.IO.Path]::DirectorySeparatorChar,
            [System.StringComparison]::OrdinalIgnoreCase) -or
            -not ([System.IO.Path]::GetFileName($resolvedTemporaryRoot)).StartsWith(
                'collectionist-validation-',
                [System.StringComparison]::Ordinal)) {
            throw "Refusing to remove unexpected validation directory: $resolvedTemporaryRoot"
        }
        Remove-Item -LiteralPath $temporaryRoot -Recurse -Force
    }
}
