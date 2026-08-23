local _, MC = ...

-- Game-wide collection status on item tooltips.
--
-- Hovering a mount/pet/toy/decor item anywhere — bags, loot, auction
-- house, guild bank — appends one line: whether it is collected and, when
-- missing, where to get it. The lookup is the search index's reverse
-- itemID map, so coverage grows with the manifests themselves; items
-- Collectionist does not catalog stay untouched.
--
-- Deliberately NOT hooked here:
--   * Our own tooltips. ShowItemInfoTooltip draws into a custom frame via
--     AddLine only (no SetItemByID), so no Item tooltip datatype is ever
--     processed for it and this processor never fires on it.
--   * GameTooltip rows inside Collectionist (mount journal descriptions
--     etc.) — same reason: AddLine alone never triggers the processor.
--
-- Achievements are searchable but have no item surface, so they are
-- naturally absent from tooltips.

local MUI = LibStub("MidnightUI-1.0")

local enabled = nil   -- tri-state until first use: nil = unset

local function isEnabled()
    local db = MC.db
    -- Settings not loaded yet (pre-ADDON_LOADED hover): default on rather
    -- than latching the cache to a guess.
    if not db then return true end
    if enabled == nil then
        enabled = not db.tooltipStatusDisabled
    end
    return enabled
end

-- Options toggle flips this at runtime without a reload.
function MC.TooltipsSetEnabled(on)
    enabled = on and true or false
end

local function linkItemID(link)
    if type(link) ~= "string" then return nil end
    return tonumber(link:match("item:(%d+)"))
end

local function appendStatus(tooltip, itemID)
    local search = MC.Search
    if not search then return end
    -- The itemID map, not the full search index: this needs 4,253 rows, and
    -- the index is 22,377 records carrying a searchable haystack each. It is
    -- built once on the first hover and holds only references into the frozen
    -- catalog, so no rescan can stale it.
    local byItemID = search.EnsureItemMap and search:EnsureItemMap() or search.byItemID
    local rec = byItemID and byItemID[itemID]
    if not rec then return end

    -- A lean record carries no ownership state -- resolving it at hover time is
    -- one call and keeps the map immune to rescans.
    local collected = rec.collected
    if rec.lean then
        local ok, owned = pcall(search.IsCollected, search, rec)
        collected = ok and owned or false
    end

    local c = MUI.Theme.colors
    if collected then
        local lc = c.learnedAccent or c.textComplete or { 0.047, 0.824, 0.616 }
        tooltip:AddLine("Collectionist: Collected", lc[1], lc[2], lc[3])
    else
        -- Missing, plus where to get it — in that source's color.
        local label, sr, sg, sb = search:SourceMeta(rec)
        local where = rec.ref.zone or rec.ref.sourceInfo
        tooltip:AddLine(format("Collectionist: Missing — %s", label),
            sr or 0.7, sg or 0.7, sb or 0.7)
        if where and where ~= label then
            tooltip:AddLine(where, 0.7, 0.7, 0.7, true)
        end
    end
end

if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostProcessor then
    -- The enum is guaranteed on any client shipping the processor; a
    -- string fallback would silently never match, so don't pretend.
    TooltipDataProcessor.AddTooltipPostProcessor(
        Enum.TooltipDataType.Item,
        function(tooltip)
            if not isEnabled() then return end
            if tooltip ~= GameTooltip then return end
            -- GetItem can throw outside item context; the datatype filter
            -- should prevent that, but a thrown error here would break
            -- every item tooltip in the game.
            local ok, _, link = pcall(tooltip.GetItem, tooltip)
            if not ok or not link then return end
            local itemID = linkItemID(link)
            if itemID then appendStatus(tooltip, itemID) end
        end)
elseif GameTooltip and hooksecurefunc then
    -- Fallback for clients without TooltipDataProcessor: hook the common
    -- setters. Less exhaustive, but covers bags/loot/inventory/AH/guild
    -- bank.
    local function onTooltipSetItem(tooltip)
        if not isEnabled() then return end
        if tooltip ~= GameTooltip then return end
        local ok, name, link = pcall(tooltip.GetItem, tooltip)
        if ok and link then
            local itemID = linkItemID(link)
            if itemID then appendStatus(tooltip, itemID) end
        end
    end
    -- Hook only what this client actually has. hooksecurefunc RAISES when the
    -- method is missing, and the whole point of this branch is that we are on
    -- a client whose tooltip API differs -- so assuming any given setter
    -- exists is exactly the wrong bet here. SetAuctionItem was removed in 8.3
    -- with the new Auction House, and hooking it blindly threw at load and
    -- took the rest of this file with it.
    for _, method in ipairs({
        "SetBagItem", "SetLootItem", "SetInventoryItem",
        "SetAuctionItem", "SetGuildBankItem", "SetMerchantItem",
        "SetQuestItem", "SetTradePlayerItem", "SetTradeTargetItem",
    }) do
        if type(GameTooltip[method]) == "function" then
            hooksecurefunc(GameTooltip, method, onTooltipSetItem)
        end
    end
    if type(GameTooltip.SetHyperlink) == "function" then
        hooksecurefunc(GameTooltip, "SetHyperlink", function(tooltip, link)
            if not isEnabled() then return end
            if tooltip ~= GameTooltip then return end
            local itemID = linkItemID(link)
            if itemID then appendStatus(tooltip, itemID) end
        end)
    end
end
