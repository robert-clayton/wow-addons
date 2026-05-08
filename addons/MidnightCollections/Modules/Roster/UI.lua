local _, MC = ...

local mod = MC.modulesByKey["roster"]
mod.UI = {}
local UI = mod.UI

local MUI = LibStub("MidnightUI-1.0")

local ROW_HEIGHT  = 18

-- Class color lookup. RAID_CLASS_COLORS is Blizzard-provided.
local function classRGB(token)
    local c = RAID_CLASS_COLORS and RAID_CLASS_COLORS[token]
    if c then return c.r, c.g, c.b end
    return 0.7, 0.7, 0.7
end

-- "Carlie-Stormrage" -> "Carlie"
local function nameOnly(fullName)
    local n = fullName:match("^([^%-]+)") or fullName
    return n
end

-- Sum collected/total across all known modules.
local function totalCounts(counts)
    if not counts then return 0, 0 end
    local got, total = 0, 0
    for _, c in pairs(counts) do
        got   = got + (c.collected or 0)
        total = total + (c.total or 0)
    end
    return got, total
end

-- 22h 14m / 3d 1h / 14m / 9s — relative timestamp.
local function relTime(ts)
    if not ts then return "" end
    local dt = time() - ts
    if dt < 60      then return dt .. "s ago" end
    if dt < 3600    then return math.floor(dt / 60) .. "m ago" end
    if dt < 86400   then return math.floor(dt / 3600) .. "h ago" end
    return math.floor(dt / 86400) .. "d ago"
end

function UI:Init(panel, m)
    self.panel = panel
    self.mod   = m
end

function UI:GetConfigDefs()
    return {
        { type = "checkbox", label = "Share my collection with guild",
          get = function() return mod.db and mod.db.share end,
          set = function(v)
              if mod.db then mod.db.share = v end
              if v then MC.RosterForceBroadcast("GUILD") end
          end },
    }
end

--------------------------------------------------------------------------
-- Sort the roster into a stable display order: total collected (desc),
-- then alphabetical.
--------------------------------------------------------------------------
local function buildSortedList()
    local list = {}
    if not MC.RosterDB then return list end
    for name, rec in pairs(MC.RosterDB) do
        local got, total = totalCounts(rec.counts)
        list[#list + 1] = {
            name     = name,
            class    = rec.class,
            version  = rec.version,
            counts   = rec.counts,
            lastSeen = rec.lastSeen,
            got      = got,
            total    = total,
        }
    end
    table.sort(list, function(a, b)
        if a.got ~= b.got then return a.got > b.got end
        return (a.name or "") < (b.name or "")
    end)
    return list
end

--------------------------------------------------------------------------
-- The hover tooltip: full per-module breakdown for one peer.
--------------------------------------------------------------------------
local MOD_DISPLAY_ORDER = { "mounts", "pets", "toys", "decorations", "recipes", "rares", "treasures" }
local MOD_LABELS = {
    mounts      = "Mounts",
    pets        = "Pets",
    toys        = "Toys",
    decorations = "Decorations",
    recipes     = "Recipes",
    rares       = "Rares",
    treasures   = "Treasures",
}

function UI:ShowPeerTooltip(owner, entry)
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    local r, g, b = classRGB(entry.class)
    GameTooltip:AddLine(nameOnly(entry.name), r, g, b)
    GameTooltip:AddLine(entry.name, 0.7, 0.7, 0.7)
    GameTooltip:AddLine(" ")
    for _, key in ipairs(MOD_DISPLAY_ORDER) do
        local c = entry.counts and entry.counts[key]
        if c then
            local done = c.total > 0 and c.collected >= c.total
            local cr, cg, cb = MUI.CountColor(c.collected, c.total)
            GameTooltip:AddDoubleLine(MOD_LABELS[key],
                format("%d / %d", c.collected, c.total),
                0.85, 0.85, 0.85, cr, cg, cb)
            if done then
                -- emphasize completed modules with a green check
            end
        end
    end
    GameTooltip:AddLine(" ")
    GameTooltip:AddDoubleLine("Last seen", relTime(entry.lastSeen),
        0.6, 0.6, 0.6, 0.85, 0.85, 0.85)
    if entry.version then
        GameTooltip:AddDoubleLine("Addon", "v" .. entry.version,
            0.6, 0.6, 0.6, 0.6, 0.6, 0.6)
    end
    GameTooltip:Show()
end

--------------------------------------------------------------------------
-- Render
--------------------------------------------------------------------------
function UI:Refresh()
    if not self.panel or not self.panel.scrollChild then return end

    self.panel.pool:ReleaseAll()
    local child = self.panel.scrollChild
    local yOff = 0

    local list = buildSortedList()

    if #list == 0 then
        local msg
        if not IsInGuild() then
            msg = "Not in a guild — Roster needs guild membership to broadcast."
        elseif not (mod.db and mod.db.share) then
            msg = "Roster sharing is OFF. Enable in options or run /mc roster on."
        else
            msg = "No guildies seen yet. Try /mc roster sync to request updates."
        end
        yOff = MUI.ShowEmptyMessage(child, msg)
        if self.panel.titleProgressText then
            self.panel.titleProgressText:SetText("")
        end
        self.panel:RefreshScrollContent(yOff)
        return
    else
        MUI.HideEmptyMessage(child)
    end

    -- Title bar shows "N peers" so the player has a quick read on how
    -- much of the guild is running the addon.
    if self.panel.titleProgressText then
        self.panel.titleProgressText:SetText(format("%d peer%s",
            #list, #list == 1 and "" or "s"))
    end

    for _, entry in ipairs(list) do
        yOff = self:RenderRow(child, entry, yOff)
    end

    self.panel:RefreshScrollContent(yOff)
end

function UI:RenderRow(parent, entry, yOff)
    local r, g, b = classRGB(entry.class)
    local info = format("%d / %d", entry.got, entry.total)

    return MUI.RenderItemRow(self.panel.pool, parent, yOff, {
        height  = ROW_HEIGHT,
        indent  = 8,
        leading = { kind = "dot", size = 6, color = { r, g, b } },
        name    = nameOnly(entry.name),
        info    = info,
        onEnter = function(row)
            UI:ShowPeerTooltip(row, entry)
        end,
        onLeave = function()
            GameTooltip:Hide()
        end,
        onClick = function()
            if MC.ShowPeerPanel then MC.ShowPeerPanel(entry.name) end
        end,
    })
end
