local _, MC = ...
local MUI = LibStub("MidnightUI-1.0")

--------------------------------------------------------------------------
-- "Closest to done" — the collection goals you are nearest to finishing.
--
-- Every other view answers "what do I have". This one answers "what should I
-- do next", which is the question a player with 21,948 tracked items actually
-- has. Nothing here rescans: byExpansion is already accumulated by
-- MC.AccumulateScanEntry for every module, and the uncollected entries are
-- already bucketed in bySource, so this is a ranking over data the scanners
-- produced on their last pass.
--
-- A goal is one module × expansion — "Dragonflight mounts, 3 left". That unit
-- is used rather than an achievement because it exists for all eight modules,
-- whereas achievement backing only exists for rares, treasures and
-- achievements themselves.
--------------------------------------------------------------------------

MC.Goals = MC.Goals or {}
local Goals = MC.Goals

MC.GOALS_KEY = "__goals"

-- A goal with nothing left is not a goal, and one that has barely been started
-- is not "closest to done". The floor keeps the list about finishing things
-- rather than listing every expansion the player has ever touched.
local MIN_PCT = 0.5
local MAX_ITEMS_PER_GOAL = 12

--------------------------------------------------------------------------
-- Data
--------------------------------------------------------------------------

-- Recipes keep one sub-table per skill line rather than one flat result, so
-- every consumer of scanner results has to special-case them. Yields each
-- (result, label) pair a module contributes.
local function eachResult(mod)
    local r = mod.Scanner and mod.Scanner.results
    if not r then return end
    local out = {}
    if mod.key == "recipes" then
        for skillLine, sub in pairs(r) do
            if type(sub) == "table" and sub.byExpansion then
                out[#out + 1] = { result = sub, tag = skillLine }
            end
        end
    elseif r.byExpansion then
        out[#out + 1] = { result = r, tag = nil }
    end
    return out
end

-- Uncollected entries for one expansion, pulled from the buckets the scanner
-- already built. Capped: a goal with 300 remaining is not close to done, and
-- the panel should not try to draw it.
local function itemsFor(result, expansion)
    local items = {}
    for _, bucket in pairs(result.bySource or {}) do
        for _, entry in ipairs(bucket) do
            if entry.expansion == expansion and not entry.collected
               and not entry.future then
                items[#items + 1] = entry
                if #items >= MAX_ITEMS_PER_GOAL then return items, true end
            end
        end
    end
    return items, false
end

-- Ranked goals, closest to completion first.
function Goals:Collect(limit)
    local goals = {}
    for _, mod in ipairs(MC.modules or {}) do
        if not (MC.IsModuleEnabled and MC.IsModuleEnabled(mod.key) == false) then
            for _, pair in ipairs(eachResult(mod) or {}) do
                for expKey, counts in pairs(pair.result.byExpansion or {}) do
                    local total = counts.total or 0
                    local collected = counts.collected or 0
                    local remaining = total - collected
                    local pct = total > 0 and (collected / total) or 0
                    local exp = MC.EXPANSION_BY_KEY and MC.EXPANSION_BY_KEY[expKey]
                    if total > 0 and remaining > 0 and pct >= MIN_PCT and exp then
                        local items, truncated = itemsFor(pair.result, expKey)
                        goals[#goals + 1] = {
                            moduleKey = mod.key,
                            moduleLabel = mod.label or mod.key,
                            expansion = expKey,
                            expansionLabel = exp.label or expKey,
                            expansionOrder = exp.order or 0,
                            total = total,
                            collected = collected,
                            remaining = remaining,
                            pct = pct,
                            items = items,
                            truncated = truncated,
                        }
                    end
                end
            end
        end
    end

    -- Fewest remaining first: "3 left" is more actionable than "80% of a
    -- thousand". Ties break on completion, then newest expansion, then label,
    -- so the order is total and does not shuffle between renders.
    table.sort(goals, function(a, b)
        if a.remaining ~= b.remaining then return a.remaining < b.remaining end
        if a.pct ~= b.pct then return a.pct > b.pct end
        if a.expansionOrder ~= b.expansionOrder then
            return a.expansionOrder > b.expansionOrder
        end
        if a.moduleLabel ~= b.moduleLabel then return a.moduleLabel < b.moduleLabel end
        return a.expansionLabel < b.expansionLabel
    end)

    if limit and #goals > limit then
        for i = #goals, limit + 1, -1 do goals[i] = nil end
    end
    return goals
end

--------------------------------------------------------------------------
-- View
--------------------------------------------------------------------------

function MC.IsGoalsSelected()
    return MC.activeSelection == MC.GOALS_KEY
end

local HEADER_H, ROW_H = 22, 18

function Goals:Render()
    local panel = MC.panel
    if not (panel and panel.scrollChild) then return end

    MC.HideInfoTooltip()
    if GameTooltip then GameTooltip:Hide() end

    panel.pool:ReleaseAll()
    MUI.BeginRenderPass(panel.pool, panel.scrollFrame)

    local child = panel.scrollChild
    MUI.HideEmptyMessage(child)

    local theme = MUI.Theme
    local goals = self:Collect(40)
    local yOff = 0

    if #goals == 0 then
        yOff = MUI.ShowEmptyMessage(child,
            "Nothing is close to done yet. Collect a little more and this fills in.")
        panel:RefreshScrollContent(yOff)
        if panel.titleProgressText then panel.titleProgressText:SetText("") end
        return
    end

    for i, goal in ipairs(goals) do
        local cr, cg, cb = MUI.CountColor(goal.collected, goal.total)
        local _, collapsed, newY = MUI.RenderCollapsibleHeader(
            panel.pool, child, yOff, {
                height     = HEADER_H,
                indent     = 0,
                collKey    = "goal:" .. goal.moduleKey .. ":" .. goal.expansion,
                label      = format("%s  ·  %s", goal.expansionLabel, goal.moduleLabel),
                labelColor = theme.colors.text,
                count      = format("%d left", goal.remaining),
                countColor = { cr, cg, cb },
                fontSize   = theme.fontSize,
                countFontSize = theme.fontSize - 1,
            }, MC.db, function() Goals:Render() end)
        yOff = newY

        if not collapsed then
            for _, entry in ipairs(goal.items) do
                local sr, sg, sb = theme:SourceColor(entry.source)
                yOff = MUI.RenderItemRow(panel.pool, child, yOff, {
                    height  = ROW_H,
                    indent  = 14,
                    leading = { kind = "dot", size = 6, color = { sr, sg, sb, 1 } },
                    name    = entry.name,
                    isCollected = false,
                    onEnter = function(r)
                        GameTooltip:SetOwner(r, "ANCHOR_RIGHT")
                        GameTooltip:SetText(entry.name or "")
                        if entry.zone then
                            GameTooltip:AddLine(entry.zone, 0.7, 0.7, 0.7)
                        end
                        GameTooltip:Show()
                    end,
                    onLeave = MC.RowOnLeave,
                    onClick = function()
                        if entry.waypoint and MC.AddWaypoint then
                            MC.AddWaypoint(entry.waypoint, entry.name)
                        end
                    end,
                })
            end
            if goal.truncated then
                yOff = MUI.RenderItemRow(panel.pool, child, yOff, {
                    height = ROW_H,
                    indent = 14,
                    name   = format("... and %d more",
                                    goal.remaining - #goal.items),
                    nameColor = theme.colors.textDim,
                })
            end
        end
        yOff = yOff + 6
        if i >= 40 then break end
    end

    panel:RefreshScrollContent(yOff)
    if panel.titleProgressText then
        panel.titleProgressText:SetText(format("%d goals", #goals))
    end
end
