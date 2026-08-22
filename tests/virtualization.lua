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

-- 5. A zero-height scroll frame (panel not yet laid out) must not window,
--    or the first paint after login would render nothing at all.
local unsized = newRegion()
unsized:SetHeight(0)
local poolD = newPool()
MUI.BeginRenderPass(poolD, unsized)
renderAll(poolD, parent)
equal(poolD.acquired, ROWS, "unsized viewport falls back to building everything")

-- 6. Passing no scroll frame clears any previous window rather than keeping a
--    stale one, which would silently blank an unrelated consumer's list.
MUI.BeginRenderPass(poolD, nil)
local poolE = newPool()
poolE._winTop = 999999
MUI.BeginRenderPass(poolE, nil)
equal(poolE._winTop, nil, "a pass with no scroll frame clears the window")

print(string.format("\n%d passed, %d failed", pass, fail))
os.exit(fail == 0 and 0 or 1)
