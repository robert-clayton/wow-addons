# Collectionist

Collectionist tracks mounts, pets, toys, housing decor, recipes, rares, treasures, and achievements from Classic through Midnight in one panel. Its eight tracker tabs group collectibles by their actual source, and clicking a row routes you toward the next objective.

Hover an entry for costs, requirements, progress, and drop information. Shift-click copies its Wowhead URL; Ctrl-click prints its IDs and source data for troubleshooting. TomTom is optional—without it, Collectionist falls back to Blizzard map pins.

Collection Score summarizes collected content by estimated time investment. Unavailable collectibles are reported separately as Legacies. Optional Sharing compares totals and per-item ownership with guild members and online Battle.net friends who also use Collectionist; a fresh installation sends nothing until Sharing is explicitly enabled during onboarding.

## Slash commands

- `/mc` — toggle the panel
- `/mc <module>` — switch to mounts, pets, decorations, toys, recipes, rares, treasures, or achievements
- `/mc scan` — rescan all trackers
- `/mc collected [module]` — toggle collected or learned entries
- `/mc score` — print Collection Score and its tracker breakdown
- `/mc filter all|current|<expansion>` — change the expansion scope
- `/mc sharing on|off|announce|sync|prune|clear|status` — manage Sharing
- `/mc theme modern|simple` — change the account-wide UI theme
- `/mc reset` — reset panel position, size, scale, and opacity
- `/mc version` / `/mc help`

## Compatibility

Retail only (Interface 120100). If a collectible is missing or has incorrect data, report it with the entry's Ctrl-click output.

## Maintainer releases

Push a stable semantic-version tag such as `v1.11.0` only after the TOC version and top changelog heading both match `1.11.0`. CI validates every shipped Lua/XML reference, builds a self-contained zip, and publishes that zip to a permanent GitHub Release. CurseForge, Wago, and WoWInterface publishing remains manual until their project IDs and API-token secrets are configured as documented in `.pkgmeta`.
