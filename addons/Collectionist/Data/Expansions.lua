local _, MC = ...

-- Expansion registry. Single source of truth for which expansions
-- exist, their display label, render order, and accent color used in
-- the filter UI and (later) in the expansion-grouped All-view.
--
-- Add a new entry here and content data files keyed by the same `key`
-- will start appearing in the filter dropdown automatically.

MC.EXPANSIONS = {
    { key = "vanilla",     label = "Classic",          order = 1,  color = { 0.85, 0.85, 0.85 } },
    { key = "tbc",         label = "Burning Crusade",  order = 2,  color = { 0.40, 0.85, 0.40 } },
    { key = "wrath",       label = "Wrath",            order = 3,  color = { 0.55, 0.85, 1.00 } },
    { key = "cata",        label = "Cataclysm",        order = 4,  color = { 0.95, 0.50, 0.30 } },
    { key = "mop",         label = "Mists of Pandaria",order = 5,  color = { 0.50, 0.85, 0.55 } },
    { key = "wod",         label = "Warlords",         order = 6,  color = { 0.80, 0.55, 0.35 } },
    { key = "legion",      label = "Legion",           order = 7,  color = { 0.55, 1.00, 0.55 } },
    { key = "bfa",         label = "Battle for Azeroth", order = 8, color = { 0.95, 0.45, 0.55 } },
    { key = "shadowlands", label = "Shadowlands",      order = 9,  color = { 0.65, 0.50, 0.85 } },
    { key = "df",          label = "Dragonflight",     order = 10, color = { 0.95, 0.65, 0.20 } },
    { key = "tww",         label = "The War Within",   order = 11, color = { 0.78, 0.65, 0.40 } },
    { key = "midnight",    label = "Midnight",         order = 12, color = { 0.55, 0.45, 0.85 } },
}

-- Quick lookup by key: MC.EXPANSION_BY_KEY["midnight"] -> the entry.
MC.EXPANSION_BY_KEY = {}
for _, e in ipairs(MC.EXPANSIONS) do
    MC.EXPANSION_BY_KEY[e.key] = e
end

-- The highest-order expansion in the registry. Used as a fallback when
-- nothing's registered yet (which shouldn't happen at runtime but does
-- in test/dev scenarios) — keeps GetLatestExpansion's contract stable
-- without hardcoding the current shipping expansion's key.
local function _highestDefinedExpansion()
    local best, bestOrder = nil, -1
    for _, e in ipairs(MC.EXPANSIONS) do
        if e.order > bestOrder then best, bestOrder = e.key, e.order end
    end
    return best
end

-- The latest expansion with content registered. Computed lazily after
-- all RegisterContent calls have run; used by the "Current" filter
-- mode so it auto-advances when a new expansion's data ships.
function MC.GetLatestExpansion(moduleKey)
    if moduleKey then
        MC._latestExpansionByModule = MC._latestExpansionByModule or {}
        if MC._latestExpansionByModule[moduleKey] then
            return MC._latestExpansionByModule[moduleKey]
        end
    elseif MC._latestExpansionKey then
        return MC._latestExpansionKey
    end
    local best, bestOrder = nil, -1
    local registered = moduleKey
        and MC._registeredExpansionsByModule
        and MC._registeredExpansionsByModule[moduleKey]
        or MC._registeredExpansions
    for key in pairs(registered or {}) do
        local e = MC.EXPANSION_BY_KEY[key]
        if e and e.order > bestOrder then
            best, bestOrder = key, e.order
        end
    end
    local resolved = best or (moduleKey and MC.GetLatestExpansion()) or _highestDefinedExpansion()
    if moduleKey then
        MC._latestExpansionByModule[moduleKey] = resolved
    else
        MC._latestExpansionKey = resolved
    end
    return resolved
end
