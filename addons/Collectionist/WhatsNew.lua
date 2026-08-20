local _, MC = ...

-- "What's New" on the first login after an update.
--
-- Onboarding.lua covers the first install; this covers every upgrade after
-- it. The two never both fire: a fresh install has no lastSeenVersion to
-- compare against, so it records the current version silently and only
-- Onboarding shows.
--
-- Content comes from Data/Changelog.lua, generated from CHANGELOG.md by
-- scripts/generate-collectionist-changelog-lua.ps1.

local MUI = LibStub("MidnightUI-1.0", true)

local WIDTH, HEIGHT = 560, 480
local LINE_PAD, SECTION_PAD, VERSION_PAD = 6, 12, 18

MC.WhatsNew = {}
local WhatsNew = MC.WhatsNew

-- "1.14.0" -> 1014000, so numeric comparison matches semver ordering without
-- string tricks. Anything unparseable sorts lowest, which makes a malformed
-- stored version behave like "very old" and simply show the notes.
local function versionValue(v)
    if type(v) ~= "string" then return -1 end
    local major, minor, patch = v:match("^(%d+)%.(%d+)%.?(%d*)")
    if not major then return -1 end
    return tonumber(major) * 1000000
         + tonumber(minor) * 1000
         + (tonumber(patch) or 0)
end
WhatsNew.VersionValue = versionValue

-- Every changelog entry strictly newer than `since`. Skipping several
-- versions at once shows all of them, so nothing is missed by a player who
-- updates infrequently.
function WhatsNew:EntriesSince(since)
    local out = {}
    if type(MC.CHANGELOG) ~= "table" then return out end
    local floor = versionValue(since)
    for _, entry in ipairs(MC.CHANGELOG) do
        if versionValue(entry.version) > floor then
            out[#out + 1] = entry
        end
    end
    return out
end

-- The newest changelog version strictly older than the one running. Passing
-- this to Show() renders the current version's notes regardless of what the
-- player has already dismissed, which is what /mc whatsnew is for.
function WhatsNew.PreviousVersionFloor()
    local running = versionValue(MC.version)
    local best
    for _, entry in ipairs(MC.CHANGELOG or {}) do
        local v = versionValue(entry.version)
        if v < running and (not best or v > versionValue(best)) then
            best = entry.version
        end
    end
    return best
end

local function fontString(parent, cache, key, size, flags)
    local fs = cache[key]
    if not fs then
        fs = parent:CreateFontString(nil, "OVERLAY")
        cache[key] = fs
    end
    fs:SetFont(MUI.Theme.font, size, flags or MUI.FontFlags())
    fs:Show()
    return fs
end

function WhatsNew:Build()
    if self.win then return self.win end
    if not (MUI and MUI.CreateWindow) then
        print("|cffff8888[Collectionist]|r Window.lua did not load. Restart the "
            .. "game client fully — a /reload does not pick up newly added files.")
        return nil
    end

    local win = MUI.CreateWindow({
        name         = "CollectionistWhatsNew",
        db           = CollectionistDB or {},
        posKey       = "whatsNewPosition",
        width        = WIDTH,
        height       = HEIGHT,
        title        = "What's New",
        footerHeight = 40,
    })
    win:AddFooterButton("Got it", nil, function() win:Close() end)

    -- Dismissing by any route counts as read; otherwise closing with Escape
    -- would show the same notes again next login.
    win.frame:HookScript("OnHide", function()
        if CollectionistDB then CollectionistDB.lastSeenVersion = MC.version end
    end)

    self.win = win
    self._fs = {}
    return win
end

function WhatsNew:Render(entries)
    local win = self.win
    if not win then return end
    local body, cache = win.body, self._fs
    local theme = MUI.Theme
    local n, y = 0, 0

    for _, fs in pairs(cache) do fs:Hide() end

    for _, entry in ipairs(entries) do
        n = n + 1
        local head = fontString(body, cache, "v" .. n, 15, "OUTLINE")
        head:ClearAllPoints()
        head:SetPoint("TOPLEFT", body, "TOPLEFT", 0, -y)
        head:SetText(entry.version)
        local ac = theme.colors.scoreAccent or { 1, 0.82, 0.4 }
        head:SetTextColor(ac[1], ac[2], ac[3])
        y = y + head:GetStringHeight() + SECTION_PAD

        for si, section in ipairs(entry.sections or {}) do
            local sh = fontString(body, cache, "s" .. n .. "_" .. si, 12)
            sh:ClearAllPoints()
            sh:SetPoint("TOPLEFT", body, "TOPLEFT", 4, -y)
            sh:SetText(section.heading)
            sh:SetTextColor(0.85, 0.85, 0.9)
            y = y + sh:GetStringHeight() + LINE_PAD

            for li, line in ipairs(section.lines or {}) do
                local ls = fontString(body, cache, "l" .. n .. "_" .. si .. "_" .. li, 11)
                ls:ClearAllPoints()
                ls:SetPoint("TOPLEFT", body, "TOPLEFT", 14, -y)
                -- Wrap inside the body; leave room for the scrollbar.
                ls:SetWidth(WIDTH - 60)
                ls:SetJustifyH("LEFT")
                ls:SetText("• " .. line)
                local ic = theme.colors.infoText or { 0.72, 0.72, 0.72 }
                ls:SetTextColor(ic[1], ic[2], ic[3])
                y = y + ls:GetStringHeight() + LINE_PAD
            end
            y = y + SECTION_PAD
        end
        y = y + VERSION_PAD
    end

    if body.SetHeight then body:SetHeight(math.max(y, 1)) end
    if win.UpdateScrollBar then win:UpdateScrollBar() end
end

-- `since` is optional; defaults to what the player last saw.
function WhatsNew:Show(since)
    local from = since or (CollectionistDB and CollectionistDB.lastSeenVersion)
    local entries = self:EntriesSince(from)
    if #entries == 0 then
        -- Nothing new. Only reachable from /mc whatsnew, so say so rather
        -- than opening an empty window.
        print("|cff88ccff[Collectionist]|r You're on the latest version ("
            .. tostring(MC.version) .. ") — nothing new to show.")
        return
    end
    if not self:Build() then return end
    self.win:SetTitle("What's New", "Collectionist " .. tostring(MC.version))
    self:Render(entries)
    self.win:Open()
end

--------------------------------------------------------------------------
-- Toast
--
-- An update notice has no business interrupting anyone, so nothing is shown
-- until the player opens Collectionist of their own accord. The toast then
-- rides the panel: a single line clipped to its edge, click to read, ignore
-- to dismiss. The full window above is only ever opened deliberately.
--------------------------------------------------------------------------

local TOAST_W, TOAST_H = 260, 34
local TOAST_GAP        = 6
-- Below the panel normally; above it when the panel sits low enough that a
-- toast underneath would be clipped by the screen edge.
local TOAST_FLIP_AT    = TOAST_H + TOAST_GAP + 12
local TOAST_LINGER     = 25

function WhatsNew:BuildToast()
    if self.toast then return self.toast end
    local theme = MUI.Theme
    local t = theme:CreateStyledFrame(UIParent, TOAST_W, TOAST_H)
    t:SetFrameStrata("DIALOG")
    t:EnableMouse(true)
    t:Hide()

    local label = t:CreateFontString(nil, "OVERLAY")
    label:SetPoint("LEFT", t, "LEFT", 10, 0)
    label:SetPoint("RIGHT", t, "RIGHT", -24, 0)
    label:SetJustifyH("LEFT")
    t.label = label

    local close = CreateFrame("Button", nil, t)
    close:SetSize(16, 16)
    close:SetPoint("RIGHT", t, "RIGHT", -6, 0)
    local x = close:CreateFontString(nil, "OVERLAY")
    x:SetPoint("CENTER")
    x:SetText("×")
    close.text = x
    close:SetScript("OnClick", function() WhatsNew:DismissToast() end)
    t.closeBtn = close

    t:SetScript("OnMouseUp", function(_, button)
        if button ~= "LeftButton" then return end
        WhatsNew:DismissToast()
        WhatsNew:Show(WhatsNew._toastSince)
    end)
    t:SetScript("OnEnter", function() t:SetBackdropBorderColor(unpack(theme.colors.scoreAccent or { 1, 0.82, 0.4 })) end)
    t:SetScript("OnLeave", function() t:SetBackdropBorderColor(unpack(theme.colors.border)) end)

    local function repaint()
        label:SetFont(theme.font, 11, MUI.FontFlags())
        label:SetTextColor(0.92, 0.92, 0.95)
        x:SetFont(theme.font, 13, MUI.FontFlags())
        local ic = theme.colors.infoText or { 0.7, 0.7, 0.7 }
        x:SetTextColor(ic[1], ic[2], ic[3])
        t:SetBackdropBorderColor(unpack(theme.colors.border))
    end
    repaint()
    if MUI.RegisterThemeHook then MUI.RegisterThemeHook(repaint) end

    self.toast = t
    return t
end

function WhatsNew:PositionToast()
    local t, panel = self.toast, MC.panel and MC.panel.frame
    if not (t and panel) then return end
    t:ClearAllPoints()
    local bottom = panel:GetBottom()
    local flip = bottom and bottom < TOAST_FLIP_AT
    if flip then
        t:SetPoint("BOTTOMLEFT", panel, "TOPLEFT", 0, TOAST_GAP)
    else
        t:SetPoint("TOPLEFT", panel, "BOTTOMLEFT", 0, -TOAST_GAP)
    end
end

function WhatsNew:DismissToast()
    local t = self.toast
    self._toastPending = false
    if CollectionistDB then CollectionistDB.lastSeenVersion = MC.version end
    if self._toastTimer then self._toastTimer:Cancel(); self._toastTimer = nil end
    if t and t:IsShown() then
        if MUI.FadeOut then MUI.FadeOut(t, 0.18, function() t:Hide() end) else t:Hide() end
    end
end

function WhatsNew:ShowToast()
    if not self._toastPending then return end
    local panel = MC.panel and MC.panel.frame
    if not (panel and panel:IsShown()) then return end

    local t = self:BuildToast()
    local n = #self:EntriesSince(self._toastSince)
    t.label:SetText(n > 1
        and format("Updated to %s — %d releases of changes", tostring(MC.version), n)
        or  format("Updated to %s — see what's new", tostring(MC.version)))
    self:PositionToast()
    t:Show()
    if MUI.FadeIn then MUI.FadeIn(t, 0.22) end

    -- Leaves on its own, but only after long enough to be read. Timing out is
    -- not the same as reading it, so the version is NOT stamped here -- an
    -- unread notice comes back next time the panel opens.
    if self._toastTimer then self._toastTimer:Cancel() end
    self._toastTimer = C_Timer.NewTimer(TOAST_LINGER, function()
        WhatsNew._toastTimer = nil
        if t:IsShown() then
            if MUI.FadeOut then MUI.FadeOut(t, 0.4, function() t:Hide() end) else t:Hide() end
        end
    end)
end

-- Called once from Core at PLAYER_LOGIN.
function WhatsNew:CheckOnLogin()
    if not CollectionistDB then return end
    local seen = CollectionistDB.lastSeenVersion

    -- First install: record and stay quiet. Onboarding.lua handles the intro,
    -- and a brand-new player has no "what changed" to care about.
    if not seen then
        CollectionistDB.lastSeenVersion = MC.version
        return
    end
    if versionValue(MC.version) <= versionValue(seen) then return end
    if CollectionistDB.whatsNewDisabled then
        CollectionistDB.lastSeenVersion = MC.version
        return
    end

    self._toastPending = true
    self._toastSince = seen

    local panel = MC.panel and MC.panel.frame
    if not panel then return end
    -- Fires whenever the panel opens, so an update noticed while the panel is
    -- closed still gets its toast the next time the player looks.
    panel:HookScript("OnShow", function()
        C_Timer.After(0.35, function() WhatsNew:ShowToast() end)
    end)
    if panel:IsShown() then C_Timer.After(0.6, function() WhatsNew:ShowToast() end) end
end
