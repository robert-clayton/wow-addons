local _, MC = ...

--------------------------------------------------------------------------
-- One-time onboarding frame, shown the first time the user logs in on a
-- given addon-version milestone (currently "1.5.0"). Lets the player
-- toggle each module on/off and confirm they want to share their counts
-- with their guild before the first broadcast goes out.
--
-- StaticPopupDialogs only support one EditBox / two buttons, which is too
-- limited for a multi-checkbox layout — so we build a small custom frame.
--------------------------------------------------------------------------

local MUI = LibStub("MidnightUI-1.0", true)

local ONBOARDING_VERSION = "1.5.0"

-- Shown text. Avoid making it sound like malware: lead with the user
-- benefit, mention the share toggle plainly.
local INTRO_LINES = {
    "Midnight Collections has new features in 1.5.0:",
    " ",
    "  • Roster tab — see your guild's collection progress",
    "  • Per-treasure step-by-step guides",
    "  • Click checklists for prerequisite quest chains",
    " ",
    "Pick which trackers you want enabled, and whether",
    "to share your collection counts with the guild.",
}

local FRAME

local function buildFrame()
    if FRAME then return FRAME end

    local theme = MUI and MUI.Theme
    local f = CreateFrame("Frame", "MidnightCollectionsOnboarding", UIParent, "BackdropTemplate")
    f:SetFrameStrata("DIALOG")
    f:SetSize(420, 460)
    f:SetPoint("CENTER")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop",  f.StopMovingOrSizing)
    f:SetClampedToScreen(true)
    f:Hide()

    if theme and theme.backdrop then
        f:SetBackdrop(theme.backdrop)
        f:SetBackdropColor(theme.colors.bg[1], theme.colors.bg[2], theme.colors.bg[3], 0.97)
        f:SetBackdropBorderColor(unpack(theme.colors.border))
    end

    -- Title bar
    local bar = CreateFrame("Frame", nil, f, "BackdropTemplate")
    bar:SetHeight(26)
    bar:SetPoint("TOPLEFT")
    bar:SetPoint("TOPRIGHT")
    if theme and theme.backdrop then
        bar:SetBackdrop(theme.backdrop)
        bar:SetBackdropColor(unpack(theme.colors.titlebar))
        bar:SetBackdropBorderColor(unpack(theme.colors.titleBorder))
    end

    local title = bar:CreateFontString(nil, "OVERLAY")
    title:SetFont(theme and theme.font or STANDARD_TEXT_FONT, 13, "OUTLINE")
    title:SetPoint("LEFT", 10, 0)
    title:SetText("Midnight Collections — Welcome to 1.5.0")
    if theme then title:SetTextColor(unpack(theme.colors.title)) end

    -- Intro text
    local intro = f:CreateFontString(nil, "OVERLAY")
    intro:SetFont(theme and theme.font or STANDARD_TEXT_FONT, 11, "")
    intro:SetPoint("TOPLEFT", 14, -40)
    intro:SetPoint("TOPRIGHT", -14, -40)
    intro:SetJustifyH("LEFT")
    intro:SetText(table.concat(INTRO_LINES, "\n"))
    if theme then intro:SetTextColor(unpack(theme.colors.text)) end

    -- Checkbox factory
    local function mkCheckbox(parent, label, anchor, yOff, getFn)
        local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
        cb:SetPoint("TOPLEFT", anchor, "TOPLEFT", 14, yOff)
        cb:SetSize(22, 22)
        local fs = cb:CreateFontString(nil, "OVERLAY")
        fs:SetFont(theme and theme.font or STANDARD_TEXT_FONT, 11, "")
        fs:SetPoint("LEFT", cb, "RIGHT", 4, 0)
        fs:SetText(label)
        if theme then fs:SetTextColor(unpack(theme.colors.text)) end
        if getFn then cb:SetChecked(getFn()) end
        return cb
    end

    f.moduleSection = f:CreateFontString(nil, "OVERLAY")
    f.moduleSection:SetFont(theme and theme.font or STANDARD_TEXT_FONT, 11, "OUTLINE")
    f.moduleSection:SetPoint("TOPLEFT", 14, -180)
    f.moduleSection:SetText("Trackers")
    if theme then f.moduleSection:SetTextColor(unpack(theme.colors.accent)) end

    f.moduleChecks = {}

    -- Module checkboxes are populated lazily once MC.modules is ready.
    f.shareSection = f:CreateFontString(nil, "OVERLAY")
    f.shareSection:SetFont(theme and theme.font or STANDARD_TEXT_FONT, 11, "OUTLINE")
    f.shareSection:SetText("Sharing")
    if theme then f.shareSection:SetTextColor(unpack(theme.colors.accent)) end

    -- Footer hint
    f.footer = f:CreateFontString(nil, "OVERLAY")
    f.footer:SetFont(theme and theme.font or STANDARD_TEXT_FONT, 10, "")
    f.footer:SetPoint("BOTTOMLEFT", 14, 44)
    f.footer:SetPoint("BOTTOMRIGHT", -14, 44)
    f.footer:SetJustifyH("LEFT")
    f.footer:SetText("You can change all of these later in /mc options.")
    if theme then f.footer:SetTextColor(unpack(theme.colors.textDim)) end

    -- Got it button
    local btn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    btn:SetSize(110, 24)
    btn:SetPoint("BOTTOM", 0, 14)
    btn:SetText("Got it")
    f.acceptBtn = btn

    FRAME = f
    return f
end

--------------------------------------------------------------------------
-- Populate the module checkboxes from MC.modules. Has to run after the
-- modules have registered themselves (PLAYER_LOGIN+).
--------------------------------------------------------------------------
local function populate(f)
    -- Wipe existing checkboxes
    for _, cb in pairs(f.moduleChecks) do cb:Hide() end
    wipe(f.moduleChecks)

    local theme = MUI and MUI.Theme
    local y = -200  -- below the "Trackers" label
    for _, m in ipairs(MC.modules) do
        if m.key ~= "roster" then
            local cb = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
            cb:SetPoint("TOPLEFT", 14, y)
            cb:SetSize(22, 22)
            cb:SetChecked(MC.IsModuleEnabled(m.key))
            cb._key = m.key

            local fs = cb:CreateFontString(nil, "OVERLAY")
            fs:SetFont(theme and theme.font or STANDARD_TEXT_FONT, 11, "")
            fs:SetPoint("LEFT", cb, "RIGHT", 4, 0)
            fs:SetText(m.label)
            if theme then fs:SetTextColor(unpack(theme.colors.text)) end

            f.moduleChecks[#f.moduleChecks + 1] = cb
            y = y - 22
        end
    end

    -- Position the "Sharing" section after the module list
    f.shareSection:ClearAllPoints()
    f.shareSection:SetPoint("TOPLEFT", 14, y - 12)

    -- Share toggle
    if not f.shareCheck then
        local cb = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
        cb:SetSize(22, 22)
        local fs = cb:CreateFontString(nil, "OVERLAY")
        fs:SetFont(theme and theme.font or STANDARD_TEXT_FONT, 11, "")
        fs:SetPoint("LEFT", cb, "RIGHT", 4, 0)
        fs:SetText("Share my collection counts with the guild")
        if theme then fs:SetTextColor(unpack(theme.colors.text)) end
        f.shareCheck = cb
    end
    f.shareCheck:ClearAllPoints()
    f.shareCheck:SetPoint("TOPLEFT", 14, y - 36)
    local rosterMod = MC.modulesByKey and MC.modulesByKey["roster"]
    if rosterMod and rosterMod.db then
        f.shareCheck:SetChecked(rosterMod.db.share and true or false)
    else
        f.shareCheck:SetChecked(true)
    end
end

--------------------------------------------------------------------------
-- Apply the user's choices on Got it.
--------------------------------------------------------------------------
local function applyChoices(f)
    for _, cb in ipairs(f.moduleChecks) do
        local key = cb._key
        local enabled = cb:GetChecked() and true or false
        if MC.IsModuleEnabled(key) ~= enabled then
            MC.SetModuleEnabled(key, enabled)
        end
    end
    local rosterMod = MC.modulesByKey and MC.modulesByKey["roster"]
    if rosterMod and rosterMod.db then
        rosterMod.db.share = f.shareCheck:GetChecked() and true or false
    end
end

--------------------------------------------------------------------------
-- Show: builds the frame if needed, populates, hooks the accept button.
--------------------------------------------------------------------------
function MC.ShowOnboarding()
    local f = buildFrame()
    populate(f)
    f.acceptBtn:SetScript("OnClick", function()
        applyChoices(f)
        f:Hide()
        if MidnightCollectionsDB then
            MidnightCollectionsDB._onboardingShown = ONBOARDING_VERSION
        end
        -- After the user accepts, fire the first broadcast in 2s so it
        -- reflects whichever modules they kept on.
        if MC.RosterForceBroadcast then
            C_Timer.After(2, function() MC.RosterForceBroadcast("GUILD") end)
        end
        print(MC.PREFIX .. " Welcome aboard. Use /mc to open the panel.")
    end)
    f:Show()
end

function MC.MaybeShowOnboarding()
    if not MidnightCollectionsDB then return end
    if MidnightCollectionsDB._onboardingShown == ONBOARDING_VERSION then return end
    -- Defer so MC.modules and friends are populated.
    C_Timer.After(2, function() MC.ShowOnboarding() end)
end
