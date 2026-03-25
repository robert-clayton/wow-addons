# WoW Addons Monorepo

## Structure

- `addons/<AddonName>/` — each addon is self-contained
- `libs/` — shared libraries (MidnightUI-1.0)
- `scripts/symlink.sh` — deploys addons into WoW AddOns directory

## Deploying

```bash
bash scripts/symlink.sh "X:/Program Files/World of Warcraft/_retail_/Interface/AddOns"
```

## Tools

- **LuaJIT** (`luajit`) — Lua 5.1 interpreter for syntax checking. Installed via `scoop install luajit`.
  - Syntax check: `luajit -bl path/to/file.lua > /dev/null`
  - WoW uses Lua 5.1, so LuaJIT is the correct match.

## WoW Addon Notes

- WoW API globals (CreateFrame, LibStub, GameTooltip, etc.) are not available outside the game — `luajit -bl` only validates syntax, not runtime correctness.
- TOC file load order matters: files are executed top-to-bottom, so dependencies must be listed before dependents.
- Addon namespace is passed via `local addonName, ns = ...` at the top of each file.
