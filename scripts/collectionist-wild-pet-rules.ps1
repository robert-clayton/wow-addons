function Test-CollectionistCollectibleWildPet($Pet) {
    if ([string]$Pet.SummonSpellID -ne "0" -or [string]$Pet.SourceTypeEnum -ne "4") {
        return $false
    }

    $flags = [int64]$Pet.Flags
    if ($flags -in @(24, 26, 65546, 131098)) {
        return $true
    }

    # Wild Silkworm is capturable. Amorous Rooster is the only other current
    # flags=58 species and remains an uncollectible beta entry.
    return $flags -eq 58 -and [string]$Pet.ID -eq "715"
}
