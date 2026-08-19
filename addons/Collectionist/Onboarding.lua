local _, MC = ...

-- One-time popup shown on the first login after an addon-version
-- milestone bump. Lets the player turn off any tracker and decide
-- whether to share collection counts with their guild before the
-- first broadcast goes out.
--
-- It's a custom frame because StaticPopupDialogs only support one
-- editbox / two buttons.

local MUI = LibStub("MidnightUI-1.0", true)

-- Onboarding fires once per account on first install. The flag below
-- is a sentinel value — once any truthy value is stored on
-- _onboardingShown, the popup never reappears, even across version
-- bumps. Existing players upgrading from 1.6.x or earlier (where the
-- flag was a version string) are also covered: any non-nil value
-- counts as "shown".
local ONBOARDING_FLAG = true

local INTRO_LINES = {
    "Collectionist tracks what you're missing from Midnight:",
    " ",
    "  • Mounts, pets, toys, decor, recipes, rares, treasures, achievements",
    "  • Click any row to drop waypoints to where you need to go",
    "  • Optional Sharing lets you compare progress with guildies",
}

local FRAME

local function buildFrame()
    if FRAME then return FRAME end

    local theme = MUI and MUI.Theme
    local f = CreateFrame("Frame", "CollectionistOnboarding", UIParent, "BackdropTemplate")
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

    -- Title bar
    local bar = CreateFrame("Frame", nil, f, "BackdropTemplate")
    bar:SetHeight(26)
    bar:SetPoint("TOPLEFT")
    bar:SetPoint("TOPRIGHT")

    -- Font has to be set before SetText; theme hook re-applies later.
    local themeFont = (MUI and MUI.Theme and MUI.Theme.font) or STANDARD_TEXT_FONT

    local title = bar:CreateFontString(nil, "OVERLAY")
    title:SetFont(themeFont, 13, "OUTLINE")
    title:SetPoint("LEFT", 10, 0)
    title:SetText("Collectionist — Welcome")

    local intro = f:CreateFontString(nil, "OVERLAY")
    intro:SetFont(themeFont, 11, "")
    intro:SetPoint("TOPLEFT", 14, -40)
    intro:SetPoint("TOPRIGHT", -14, -40)
    intro:SetJustifyH("LEFT")
    intro:SetText(table.concat(INTRO_LINES, "\n"))

    f.moduleSection = f:CreateFontString(nil, "OVERLAY")
    f.moduleSection:SetFont(themeFont, 11, "OUTLINE")
    f.moduleSection:SetPoint("TOPLEFT", 14, -180)
    f.moduleSection:SetText("Trackers")

    f.moduleChecks = {}

    f.shareSection = f:CreateFontString(nil, "OVERLAY")
    f.shareSection:SetFont(themeFont, 11, "OUTLINE")
    f.shareSection:SetText("Sharing")

    f.footer = f:CreateFontString(nil, "OVERLAY")
    f.footer:SetFont(themeFont, 10, "")
    f.footer:SetPoint("BOTTOMLEFT", 14, 44)
    f.footer:SetPoint("BOTTOMRIGHT", -14, 44)
    f.footer:SetJustifyH("LEFT")
    f.footer:SetText("You can change all of these later in /mc options.")

    local function applyOnboardingTheme()
        local th = MUI and MUI.Theme
        if not th then return end
        MUI.ApplyThemedBackdrop(f, { kind = "panel", alpha = 0.97 })
        MUI.ApplyThemedBackdrop(bar, { kind = "titlebar", alpha = 1 })
        title:SetFont(th.font, 13, "OUTLINE")
        title:SetTextColor(unpack(th.colors.title))
        intro:SetFont(th.font, 11, "")
        intro:SetTextColor(unpack(th.colors.text))
        f.moduleSection:SetFont(th.font, 11, "OUTLINE")
        f.moduleSection:SetTextColor(unpack(th.colors.accent))
        f.shareSection:SetFont(th.font, 11, "OUTLINE")
        f.shareSection:SetTextColor(unpack(th.colors.accent))
        f.footer:SetFont(th.font, 10, "")
        f.footer:SetTextColor(unpack(th.colors.textDim))
    end
    applyOnboardingTheme()
    if MUI and MUI.RegisterThemeHook then
        MUI.RegisterThemeHook(applyOnboardingTheme)
    end

    -- Got it button
    local btn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    btn:SetSize(110, 24)
    btn:SetPoint("BOTTOM", 0, 14)
    btn:SetText("Got it")
    f.acceptBtn = btn

    FRAME = f
    return f
end

-- Populate the per-module checkboxes. Runs at show time so MC.modules
-- is fully populated.
local function populate(f)
    -- Wipe existing checkboxes
    for _, cb in pairs(f.moduleChecks) do cb:Hide() end
    wipe(f.moduleChecks)

    local y = -200  -- below the "Trackers" label
    for _, m in ipairs(MC.modules) do
        if m.key ~= "roster" then
            local cb = MUI.MakeCheckbox(f, {
                label   = m.label,
                checked = MC.IsModuleEnabled(m.key),
            })
            cb:SetPoint("TOPLEFT", 14, y)
            cb._key = m.key
            f.moduleChecks[#f.moduleChecks + 1] = cb
            y = y - 22
        end
    end

    -- Position the "Sharing" section after the module list
    f.shareSection:ClearAllPoints()
    f.shareSection:SetPoint("TOPLEFT", 14, y - 12)

    -- Master switch for the Sharing feature (peer counts + Inspector).
    if not f.rosterCheck then
        f.rosterCheck = MUI.MakeCheckbox(f, { label = "Enable Sharing" })
    end
    f.rosterCheck:ClearAllPoints()
    f.rosterCheck:SetPoint("TOPLEFT", 14, y - 36)
    f.rosterCheck:SetChecked((MC.db and MC.db.rosterEnabled ~= false) and true or false)
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
    if MC.db then
        if MC.SetRosterEnabled then
            MC.SetRosterEnabled(f.rosterCheck:GetChecked() and true or false)
        else
            MC.db.rosterEnabled = f.rosterCheck:GetChecked() and true or false
        end
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
        -- Write the flag to the per-character DB. The PLAYER_LOGOUT
        -- snapshot routine in Core.lua copies MC.db -> CollectionistDB,
        -- so writing to CollectionistDB directly here would get
        -- clobbered every reload. The CharDB-side flag is preserved across
        -- reloads (saved as part of CollectionistCharDB) and
        -- propagates to fresh alts via the snapshot seed.
        if MC.db then
            MC.db._onboardingShown = ONBOARDING_FLAG
        end
        if CollectionistDB then
            CollectionistDB._onboardingShown = ONBOARDING_FLAG
        end
        -- After explicit opt-in, fire the first broadcast once the initial
        -- scanners have populated their snapshots.
        if MC.db and MC.db.rosterEnabled and MC.RosterForceBroadcast then
            C_Timer.After(2, function()
                if MC.RosterCanShare and MC.RosterCanShare() then
                    MC.RosterForceBroadcast("GUILD")
                    -- Fresh consent usually means an empty peer list; ask
                    -- peers to introduce themselves (no-op otherwise).
                    if MC.RosterRequestSync then MC.RosterRequestSync(false) end
                end
            end)
        end
        print(MC.PREFIX .. " You're set. Type /mc to open the panel.")
    end)
    f:Show()
end

function MC.MaybeShowOnboarding()
    -- Any truthy value means the player has accepted the popup at some
    -- point — never re-show, even across version bumps. Pre-1.7.0 users
    -- had a version string here ("1.5.0", "1.6.0", etc.) which still
    -- counts as truthy, so they don't get the popup again either.
    local shown = (MC.db and MC.db._onboardingShown)
                  or (CollectionistDB and CollectionistDB._onboardingShown)
    if shown then return end
    -- Defer so MC.modules and friends are populated.
    C_Timer.After(2, function() MC.ShowOnboarding() end)
end
