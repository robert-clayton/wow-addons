local _, MC = ...

local mod = MC.modulesByKey["achievements"]
mod.UI = {}
local UI = mod.UI

local MUI = LibStub("MidnightUI-1.0")

local SECTION_PAD = 8
local ROW_HEIGHT  = 22
local ICON_SIZE   = 24

local CATEGORY_SET = {}
for _, c in ipairs(MC.AchievementCategoryOrder or {}) do CATEGORY_SET[c] = true end

function UI:Init(panel, m)
    self.panel = panel
    self.mod = m
    self._refresh = function() self:Refresh() end
end

function UI:GetConfigDefs()
    return {}
end

function UI:Refresh()
    if not self.panel or not self.panel.scrollChild then return end
    if not mod.Scanner then return end

    self.panel.pool:ReleaseAll()
    -- This module renders its own tree rather than going through
    -- MUI.RenderModulePage, so it opts into the viewport window itself.
    MUI.BeginRenderPass(self.panel.pool, self.panel.scrollFrame)

    local child = self.panel.scrollChild
    local r = mod.Scanner.results
    if not r or not r.total then
        self.panel:RefreshScrollContent(0)
        return
    end

    local yOff = 0
    -- Top-level categories first, in declared order.
    for _, cat in ipairs(MC.AchievementCategoryOrder or {}) do
        local catBuckets = r.byCategory and r.byCategory[cat]
        if catBuckets and next(catBuckets) then
            yOff = self:RenderCategoryGroup(child, cat, catBuckets, yOff)
            yOff = yOff + SECTION_PAD
        end
    end
    -- Any unrecognized categories fall through.
    if r.byCategory then
        for cat, catBuckets in pairs(r.byCategory) do
            if not CATEGORY_SET[cat] and next(catBuckets) then
                yOff = self:RenderCategoryGroup(child, cat, catBuckets, yOff)
                yOff = yOff + SECTION_PAD
            end
        end
    end

    if mod.db.showCollected and #r.collected > 0 then
        yOff = self:RenderCollectedGroup(child, r.collected, yOff)
    end

    if self.panel.titleProgressText then
        self.panel.titleProgressText:SetText(
            r.total > 0 and format("%d / %d", r.collectedCount, r.total) or "")
    end

    if yOff == 0 then
        local msg = (r.collectedCount == r.total and r.total > 0)
            and "All Midnight achievements complete!"
            or "No achievements to track."
        local color = (r.collectedCount == r.total and r.total > 0)
            and MUI.Theme.colors.textComplete or nil
        yOff = MUI.ShowEmptyMessage(child, msg, color)
    else
        MUI.HideEmptyMessage(child)
    end

    self.panel:RefreshScrollContent(yOff)
end

-- Light blue accent for achievements (distinguishes from Treasures' gold).
local function zoneColor()
    return 0.55, 0.78, 1.0
end

-- Slightly desaturated accent for inner sub-section headers so the
-- nesting is visually distinct from the outer category headers.
local function subColor()
    return 0.42, 0.60, 0.78
end

-- Render a category (Exploration, Quests, Collections, Features) with
-- its sub-categories nested underneath as inner collapsibles.
function UI:RenderCategoryGroup(parent, category, sourceBuckets, yOff)
    local sr, sg, sb = zoneColor()
    -- Total count across all this category's sub-categories.
    local totalCount = 0
    for _, entries in pairs(sourceBuckets) do totalCount = totalCount + #entries end
    local _, collapsed, newY = MUI.RenderSourceHeader(self.panel.pool, parent, yOff, {
        label       = MC.AchievementCategoryLabels[category] or category,
        accentColor = { sr, sg, sb },
        count       = totalCount,
        collKey     = "cat_" .. category,
        height      = 22,
    }, mod.db, self._refresh)
    yOff = newY
    if collapsed then return yOff end

    local order = MC.AchievementSubcategoryOrder and MC.AchievementSubcategoryOrder[category] or {}
    local rendered = {}
    for _, src in ipairs(order) do
        local entries = sourceBuckets[src]
        if entries and #entries > 0 then
            yOff = self:RenderSourceGroup(parent, category, src, entries, yOff)
            rendered[src] = true
        end
    end
    -- Any sub-categories that weren't in the declared order still render.
    for src, entries in pairs(sourceBuckets) do
        if not rendered[src] and #entries > 0 then
            yOff = self:RenderSourceGroup(parent, category, src, entries, yOff)
        end
    end
    return yOff
end

function UI:RenderSourceGroup(parent, category, srcType, entries, yOff)
    MC.SortEntries(entries)
    local sr, sg, sb = subColor()
    local _, collapsed, newY = MUI.RenderSourceHeader(self.panel.pool, parent, yOff, {
        label       = MC.AchievementSourceLabels[srcType] or srcType,
        accentColor = { sr, sg, sb },
        count       = #entries,
        collKey     = "src_" .. (category or "_") .. "_" .. srcType,
        height      = 18,
        indent      = 14,
    }, mod.db, self._refresh)
    yOff = newY
    if collapsed then return yOff end
    for _, ach in ipairs(entries) do
        yOff = self:RenderAchievementRow(parent, ach, yOff, false)
    end
    return yOff
end

function UI:RenderCollectedGroup(parent, entries, yOff)
    return MUI.RenderCollectedSection(self.panel.pool, parent, yOff, {
        entries   = entries,
        renderRow = function(p, ach, y, _) return self:RenderAchievementRow(p, ach, y, true) end,
        label     = "Completed",
        collKey   = "completed",
    }, mod.db, self._refresh)
end

function UI:RenderAchievementRow(parent, ach, yOff, isCollected)
    local sr, sg, sb = zoneColor()
    -- Show "3/5" progress in the right-side info column. For completed
    -- rows fall back to the zone label since the count is implicit.
    local info
    if ach.future then
        info = MC.GetAvailabilityBadge(ach)
    elseif isCollected then
        info = ach.zone
    elseif ach.progress and ach.progress.total > 0 then
        info = format("%d / %d", ach.progress.done, ach.progress.total)
    else
        info = ach.zone
    end
    return MUI.RenderItemRow(self.panel.pool, parent, yOff, {
        height      = ROW_HEIGHT,
        indent      = 8,
        leading     = { kind = "icon", size = ICON_SIZE,
                        texture  = ach.icon,
                        fallback = "Interface\\Icons\\Achievement_GuildPerk_HastyHearth" },
        name        = ach.name,
        info        = info,
        isCollected = isCollected,
        onEnter = function(r)
            GameTooltip:SetOwner(r, "ANCHOR_RIGHT")
            GameTooltip:AddLine(ach.name, 1, 1, 1)
            GameTooltip:Show()
            MC.ShowItemInfoTooltip(r, ach, "Achievement", sr, sg, sb)
        end,
        onLeave = MC.RowOnLeave,
        -- Click routes waypoints if the entry has any (taskList or own
        -- waypoint). DoItemAction's natural fallback opens the
        -- achievement frame when neither is set, which is the right
        -- behavior for activity-counter or meta achievements that
        -- aren't location-based.
        onClick = function() MC.DoItemAction(ach) end,
    })
end
