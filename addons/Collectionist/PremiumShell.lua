local _, MC = ...

--------------------------------------------------------------------------
-- UI style (shell) axis: "classic" (default, the compact panel) vs
-- "premium" (the application-style shell). Storage mirrors the theme
-- accessors exactly (Core.lua GetTheme/SetTheme): account-wide primary,
-- per-char fallback, dual-write; the PLAYER_LOGOUT snapshot propagates
-- it to alts.
--
-- Switching is /reload-only, deliberately: a live swap would need five
-- independent invalidation surfaces handled (module UI._initialized
-- flags, scrollChild-cached widgets, the append-only theme hook
-- registry, the shared frame pool, and CreatePanel's one-shot indicator
-- chain). A /reload resets all five for free.
--------------------------------------------------------------------------
function MC.GetUIStyle()
    return (CollectionistDB and CollectionistDB.uiStyle)
        or (MC.db and MC.db.uiStyle)
        or "classic"
end

function MC.SetUIStyle(name)
    if name ~= "classic" and name ~= "premium" then return end
    if MC.GetUIStyle() == name then return end
    if MC.db then MC.db.uiStyle = name end
    if CollectionistDB then CollectionistDB.uiStyle = name end
    StaticPopup_Show("COLLECTIONIST_UISTYLE_RELOAD")
end

StaticPopupDialogs["COLLECTIONIST_UISTYLE_RELOAD"] = {
    text = "Switching the Collectionist shell takes effect after a UI reload. Reload now?",
    button1 = "Reload",
    button2 = "Later",
    OnAccept = function() ReloadUI() end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

--------------------------------------------------------------------------
-- Premium geometry DB. The shell reads Panel-style fixed keys through a
-- routing proxy: geometry keys live in MC.db.premium (per-shell, so the
-- classic panel's saved size/position survive untouched); everything
-- else (frameAlpha, frameScale, locked, panelShown, minimap, activeTab,
-- disabledModules, module sub-tables) forwards to MC.db. Lookups go
-- through MC.db.premium dynamically — not a captured upvalue — so
-- /mc reset may replace the table wholesale.
--
-- MC.db.premium lives inside CollectionistCharDB, so persistence and
-- the logout snapshot are automatic.
--------------------------------------------------------------------------
local GEO = { position = true, panelWidth = true, panelHeight = true, minimized = true }

function MC.MakePremiumDB()
    MC.db.premium = MC.db.premium or {}
    if not MC.db.premium.position then
        MC.db.premium.position =
            { point = "CENTER", relativePoint = "CENTER", x = 0, y = 0 }
    end
    return setmetatable({}, {
        __index = function(_, k)
            if GEO[k] then return MC.db.premium[k] end
            return MC.db[k]
        end,
        __newindex = function(_, k, v)
            if GEO[k] then MC.db.premium[k] = v else MC.db[k] = v end
        end,
    })
end
