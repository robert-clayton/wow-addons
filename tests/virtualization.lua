-- Windowed row rendering.
--
--   luajit tests/virtualization.lua
--
-- The invariant that matters is NOT "fewer frames" -- it is that skipping the
-- paint changes nothing about the layout. Every renderer must advance yOff by
-- its own height whether or not it built anything, or the content height and
-- scroll range would shift as you scrolled into the list.

local pass, fail = 0, 0
local function ok(cond, label)
    if cond then pass = pass + 1 else fail = fail + 1 print("  FAIL " .. label) end
end
local function equal(a, b, label)
    if a == b then pass = pass + 1
    else fail = fail + 1 print(string.format("  FAIL %s: %s ~= %s", label, tostring(a), tostring(b))) end
end

--------------------------------------------------------------------------
-- Enough of the client for the library to load and lay out rows.
--------------------------------------------------------------------------
local function newRegion()
    local r = {}
    -- Unknown METHODS resolve to no-ops, but internal fields must stay nil:
    -- the library rawsets caches like `_children` and would otherwise find a
    -- function there and try to index it.
    local meta = {
        __index = function(_, k)
            if type(k) == "string" and k:sub(1, 1) == "_" then return nil end
            return function() return r end
        end,
    }
    r.SetHeight = function(_, h) r._h = h end
    r.GetHeight = function() return r._h or 0 end
    r.SetWidth = function(_, w) r._w = w end
    r.GetWidth = function() return r._w or 100 end
    r.GetVerticalScroll = function() return r._scroll or 0 end
    r.SetVerticalScroll = function(_, v) r._scroll = v end
    r.CreateTexture = function() return newRegion() end
    r.CreateFontString = function() return newRegion() end
    return setmetatable(r, meta)
end

_G.CreateFrame = function() return newRegion() end
_G.UIParent = newRegion()
_G.GameTooltip = newRegion()
_G.GameFontNormal = newRegion()
_G.GameFontHighlight = newRegion()
_G.UISpecialFrames = {}
_G.C_Timer = { After = function() end, NewTicker = function() return { Cancel = function() end } end }
_G.GetTime = function() return 0 end
_G.PlaySound = function() end
_G.SOUNDKIT = setmetatable({}, { __index = function() return 0 end })

local registered = {}
_G.LibStub = setmetatable({
    NewLibrary = function(_, name)
        registered[name] = registered[name] or {}
        return registered[name], 0
    end,
    GetLibrary = function(_, name) return registered[name] end,
}, { __call = function(_, name) return registered[name] end })

local chunk = assert(loadfile("libs/MidnightUI-1.0/MidnightUI-1.0.lua"))
chunk()
local MUI = registered["MidnightUI-1.0"]
assert(MUI and MUI.RenderItemRow, "MidnightUI-1.0 did not register RenderItemRow")

--------------------------------------------------------------------------
-- A pool that counts how often a frame is actually built.
--------------------------------------------------------------------------
local function newPool()
    local pool = { acquired = 0, active = {}, inactive = {} }
    function pool:Acquire()
        self.acquired = self.acquired + 1
        return newRegion()
    end
    function pool:ReleaseAll() end
    return pool
end

local ROWS, ROW_H = 10318, 18

local function renderAll(pool, parent)
    local yOff = 0
    for i = 1, ROWS do
        yOff = MUI.RenderItemRow(pool, parent, yOff, {
            height = ROW_H,
            name   = "Row " .. i,
        })
    end
    return yOff
end

print("windowed row rendering")

-- 1. No render pass declared: build everything, exactly as before.
local poolA, parent = newPool(), newRegion()
local fullHeight = renderAll(poolA, parent)
equal(poolA.acquired, ROWS, "unwindowed build count")
equal(fullHeight, ROWS * ROW_H, "unwindowed total height")

-- 2. With a viewport, only rows near it are built.
local scroll = newRegion()
scroll:SetHeight(400)
scroll:SetVerticalScroll(0)

local poolB = newPool()
MUI.BeginRenderPass(poolB, scroll)
local windowedHeight = renderAll(poolB, parent)

equal(windowedHeight, fullHeight, "LAYOUT INVARIANT: windowed height matches full height")
ok(poolB.acquired < ROWS / 10, "windowed build count is a small fraction of the list")
ok(poolB.acquired > 0, "something is actually built at the top of the list")

-- 3. Scrolling to the middle builds a different, equally small slice.
local mid = math.floor(ROWS * ROW_H / 2)
scroll:SetVerticalScroll(mid)
local poolC = newPool()
MUI.BeginRenderPass(poolC, scroll)
local midHeight = renderAll(poolC, parent)
equal(midHeight, fullHeight, "LAYOUT INVARIANT: height unchanged after scrolling")
ok(poolC.acquired > 0, "rows are built at the scrolled position")
ok(poolC.acquired < ROWS / 10, "scrolled build count stays small")

-- 4. The built slice actually covers the viewport, with overscan on each side.
--    A window that painted only the exact viewport would show blank rows the
--    instant the user scrolled a single line.
local viewportRows = math.ceil(400 / ROW_H)
ok(poolC.acquired > viewportRows, "built slice exceeds the bare viewport (overscan present)")

-- 5. A zero-height scroll frame -- a panel that has not been laid out yet --
--    must fail CLOSED. Failing open leaves the window nil, nothing counts as
--    offscreen, and the whole tab builds real frames. WoW never frees a frame,
--    so that is permanent residency bought by a transient measurement.
local unsized = newRegion()
unsized:SetHeight(0)
local poolD = newPool()
MUI.BeginRenderPass(poolD, unsized)
renderAll(poolD, parent)
ok(poolD.acquired > 0, "an unsized viewport still paints something")
ok(poolD.acquired < ROWS / 10, "an unsized viewport does NOT build the whole list")

-- 6. Passing no scroll frame clears any previous window rather than keeping a
--    stale one, which would silently blank an unrelated consumer's list.
MUI.BeginRenderPass(poolD, nil)
local poolE = newPool()
poolE._winTop = 999999
MUI.BeginRenderPass(poolE, nil)
equal(poolE._winTop, nil, "a pass with no scroll frame clears the window")

-- 7. The allocation, not just the frame count. Windowing originally checked
--    inside RenderItemRow, but Lua builds the caller's table constructor
--    BEFORE the call -- so every row still allocated an opts table, its
--    sub-tables and two closures. A Recipes pass cost ~9 MB of garbage while
--    painting 63 rows, and that pass re-runs on scroll. lib.RowHidden lets the
--    caller skip the constructor entirely.
--
--    Both paths below build the SAME row. Comparing a lean opts table against
--    a rich one would measure the table, not the guard.
local function renderRich(pool, parent, guarded)
    local yOff = 0
    for i = 1, ROWS do
        if guarded and MUI.RowHidden(pool, yOff, ROW_H) then
            yOff = yOff + ROW_H
        else
            yOff = MUI.RenderItemRow(pool, parent, yOff, {
                height  = ROW_H,
                name    = "Row " .. i,
                leading = { kind = "dot", size = 6, color = { 1, 1, 1, 1 } },
                onEnter = function() end,
                onLeave = function() end,
            })
        end
    end
    return yOff
end

scroll:SetVerticalScroll(0)

-- Measure ALLOCATION, not residency. collectgarbage("count") reports the live
-- heap, so with the collector running it reports whatever survived rather than
-- what was churned -- which is the number that matters here. Stopping the
-- collector makes the delta the true allocation for the pass.
local function measure(guarded)
    local pool = newPool()
    collectgarbage("collect")
    collectgarbage("stop")
    local before = collectgarbage("count")
    MUI.BeginRenderPass(pool, scroll)
    local height = renderRich(pool, parent, guarded)
    local kb = collectgarbage("count") - before
    collectgarbage("restart")
    return kb, height, pool
end

local unguardedKB, unguardedHeight, poolF = measure(false)
local guardedKB, guardedHeight, poolG = measure(true)

equal(guardedHeight, fullHeight, "LAYOUT INVARIANT: the guarded path lays out identically")
equal(unguardedHeight, fullHeight, "and so does the unguarded one")
equal(poolF.acquired, poolG.acquired, "both paths paint the same number of rows")
ok(guardedKB < unguardedKB / 4,
    string.format("guarding at the caller cuts allocation (%.0f KB to %.0f KB)",
        unguardedKB, guardedKB))
ok(MUI.RowHidden(poolG, 5000000, ROW_H), "a far-offscreen row reports hidden")
ok(not MUI.RowHidden(poolG, 0, ROW_H), "a row at the viewport top does not")

print(string.format("  allocation per pass: in-callee skip %.0f KB, caller-guarded %.0f KB",
    unguardedKB, guardedKB))
print(string.format("%d passed, %d failed", pass, fail))
os.exit(fail == 0 and 0 or 1)
