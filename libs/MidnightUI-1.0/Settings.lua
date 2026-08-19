local lib = LibStub:GetLibrary("MidnightUI-1.0", true)
if not lib then return end

-- Settings window. Shared by both shells: PanelProto and ShellProto both
-- build their cfgFrame from here, so the options surface is identical
-- whichever shell is active.
--
-- Replaces the old side-dock, which grew to fit its content — with a
-- dozen expansions and eight modules that ran past the bottom of the
-- screen with no way to reach the end. This is a fixed window with a
-- scrolling body: the content grows, the window doesn't.
--
-- The chrome itself now lives in Window.lua (lib.CreateWindow), which
-- the Collection Inspector shares. This file is what makes that chrome
-- "the options window": the Done button, the saved-position key, and
-- the `_scrolls` flag the config renderer reads.
--
-- The consumer contract is unchanged: this returns a FRAME (not the
-- window object) exposing `.body` for lib._populateConfigBody to render
-- into, `.UpdateScrollBar`, and `_scrolls` telling that renderer to size
-- the scroll child rather than the window. Callers hold it as cfgFrame
-- and drive it with IsShown / lib.PopIn / lib.PopOut.

-- Wide enough for the 130px category rail plus two content columns:
-- 680 - 2*16 pad - 6 scrollbar - 144 rail/gutter leaves ~249 per column,
-- which holds the longest expansion and tracker labels on one line.
local WIDTH  = 680
local HEIGHT = 620

-- opts: { name, title, subtitle, db } — db persists `optionsPosition`.
function lib.BuildSettingsWindow(owner, opts)
    opts = opts or {}
    local db = opts.db or owner.db or {}

    -- Window.lua is a separate file in the XML, and WoW reads an addon's
    -- file list at launch — a /reload after an update leaves this file
    -- re-read while the new one is still absent. Say so rather than
    -- erroring into a hidden Lua error.
    if not lib.CreateWindow then
        print("|cffff8888[MidnightUI]|r Window.lua did not load. Restart the "
            .. "game client fully — a /reload does not pick up newly added "
            .. "addon files.")
        return nil
    end

    local win = lib.CreateWindow({
        name     = (opts.name or "MidnightUISettings") .. "Window",
        title    = opts.title or "Options",
        subtitle = opts.subtitle or "",
        width    = opts.width or WIDTH,
        height   = opts.height or HEIGHT,
        db       = db,
        -- Explicit: the pre-factory window wrote here, and existing
        -- saved positions must keep resolving.
        posKey   = "optionsPosition",
    })

    local f = win.frame
    -- The window object stays reachable (f._window, set by the factory)
    -- but every existing caller holds the frame, so the handles they use
    -- live on the frame: .body, .header, .footer, .scrollFrame,
    -- .UpdateScrollBar, ._scrolls are all attached there by CreateWindow.
    f.doneBtn = win:AddFooterButton("Done",
        { primary = true, tooltip = "Close options" },
        function() lib.PopOut(f) end)

    return f
end
