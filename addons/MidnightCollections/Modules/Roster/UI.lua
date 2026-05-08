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
-- Sort the roster into a stable display order: "Me" always first, then
-- peers sorted by total collected (desc), then alphabetical.
--------------------------------------------------------------------------
local function buildSortedList()
    local list = {}
    if MC.RosterDB then
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
    end
    table.sort(list, function(a, b)
        if a.got ~= b.got then return a.got > b.got end
        return (a.name or "") < (b.name or "")
    end)
    -- Prepend "Me" — local player's own progression, always visible at
    -- the top regardless of guild/share state.
    if MC.GetMeRosterEntry then
        local me = MC.GetMeRosterEntry()
        if me then
            local got, total = totalCounts(me.counts)
            table.insert(list, 1, {
                name     = me.name,
                class    = me.class,
                version  = me.version,
                counts   = me.counts,
                lastSeen = me.lastSeen,
                got      = got,
                total    = total,
                isMe     = true,
            })
        end
    end
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

    -- "Me" is always first when GetMeRosterEntry is available, so an empty
    -- list means we couldn't even build a local entry. Render the empty
    -- message and bail.
    if #list == 0 then
        yOff = MUI.ShowEmptyMessage(child,
            "Roster module not yet initialized. Try /reload.")
        if self.panel.titleProgressText then
            self.panel.titleProgressText:SetText("")
        end
        self.panel:RefreshScrollContent(yOff)
        return
    else
        MUI.HideEmptyMessage(child)
    end

    -- Count peers (everyone except Me) for the title and the empty hint.
    local peerCount = 0
    for _, e in ipairs(list) do
        if not e.isMe then peerCount = peerCount + 1 end
    end

    if self.panel.titleProgressText then
        self.panel.titleProgressText:SetText(format("%d peer%s",
            peerCount, peerCount == 1 and "" or "s"))
    end

    for _, entry in ipairs(list) do
        yOff = self:RenderRow(child, entry, yOff)
    end

    -- If only Me is showing, surface a small hint below explaining what
    -- to do — same idea as the old empty-state message but shown beneath
    -- the Me row instead of replacing it.
    if peerCount == 0 then
        local hint
        if not IsInGuild() then
            hint = "Not in a guild — Roster needs guild membership to see others."
        elseif not (mod.db and mod.db.share) then
            hint = "Sharing is OFF. Enable in options or run /mc roster on."
        else
            hint = "No guildies seen yet. Try /mc roster sync to request updates."
        end
        yOff = yOff - 8
        local theme = MUI.Theme
        local fs = MUI.GetOrCreate(child, "rosterEmptyHint", function(p)
            local f = p:CreateFontString(nil, "OVERLAY")
            f:SetFont(theme.font, theme.fontSize - 1, "OUTLINE")
            return f
        end)
        fs:ClearAllPoints()
        fs:SetPoint("TOPLEFT", child, "TOPLEFT", 14, yOff)
        fs:SetPoint("TOPRIGHT", child, "TOPRIGHT", -14, yOff)
        fs:SetJustifyH("LEFT")
        fs:SetText(hint)
        fs:SetTextColor(unpack(theme.colors.textDim))
        fs:Show()
        yOff = yOff - 24
    elseif child._children and child._children.rosterEmptyHint then
        child._children.rosterEmptyHint:Hide()
    end

    self.panel:RefreshScrollContent(yOff)
end

function UI:RenderRow(parent, entry, yOff)
    local r, g, b = classRGB(entry.class)
    local info = format("%d / %d", entry.got, entry.total)
    local label = nameOnly(entry.name)
    if entry.isMe then label = label .. " |cff888888(You)|r" end

    return MUI.RenderItemRow(self.panel.pool, parent, yOff, {
        height  = ROW_HEIGHT,
        indent  = 8,
        leading = { kind = "dot", size = 6, color = { r, g, b } },
        name    = label,
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
