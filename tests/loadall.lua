-- Loads every file the TOC lists, in order, under a stub client that FAILS
-- like the real one.
--
--   luajit tests/loadall.lua
--
-- toc_smoke checks that the files parse. This checks that they RUN, which is a
-- different question: hooksecurefunc raising on a method the client does not
-- have is a load-time abort that no syntax check can see. Collectionist hooked
-- GameTooltip.SetAuctionItem, removed in 8.3, and lost the rest of Tooltips.lua
-- to it.
--
-- The stub is deliberately strict where the real API is strict. A permissive
-- stub that answers every call is worse than no test: it reports success for
-- code the client rejects.

local pass, fail = 0, 0
local function ok(cond, label)
    if cond then pass = pass + 1 else fail = fail + 1 print("  FAIL " .. label) end
end

local function permissive(name)
    return setmetatable({}, {
        __index = function(t, k)
            if type(k) == "string" and k:sub(1, 1) == "_" then return nil end
            local c = permissive(name .. "." .. tostring(k))
            rawset(t, k, c)
            return c
        end,
        __call = function(_, a) return type(a) == "table" and a or permissive(name) end,
        __tostring = function() return name end,
        __concat = function(a, b)
            return (type(a) == "string" and a or name) .. (type(b) == "string" and b or name)
        end,
    })
end

-- The real GameTooltip has a FIXED method set. Anything not listed here does
-- not exist on a modern client, and hooksecurefunc must reject it exactly as
-- the client does.
local REAL_TOOLTIP_METHODS = {
    SetBagItem = true, SetLootItem = true, SetInventoryItem = true,
    SetGuildBankItem = true, SetMerchantItem = true, SetQuestItem = true,
    SetHyperlink = true, SetOwner = true, Show = true, Hide = true,
    AddLine = true, AddDoubleLine = true, SetText = true, GetItem = true,
    IsShown = true, ClearLines = true, SetSpellByID = true,
    -- SetAuctionItem is deliberately absent: removed in 8.3.
}

local GameTooltip = setmetatable({}, {
    __index = function(t, k)
        if REAL_TOOLTIP_METHODS[k] then
            local f = function() end
            rawset(t, k, f)
            return f
        end
        return nil
    end,
})

local function buildEnv(modern)
local G
G = setmetatable({
    CreateFrame = function() return permissive("frame") end,
    UIParent = permissive("UIParent"),
    GameTooltip = GameTooltip,
    -- Raises on a missing method, like the client.
    hooksecurefunc = function(a, b)
        local tbl, key = a, b
        if type(a) == "string" then tbl, key = G, a end
        if type(tbl) ~= "table" or type(tbl[key]) ~= "function" then
            error("hooksecurefunc(): " .. tostring(key) .. " is not a function", 2)
        end
    end,
    LibStub = setmetatable({
        NewLibrary = function(_, n) return permissive(n), 0 end,
        GetLibrary = function(_, n) return permissive(n) end,
        NewAddon = function() return permissive("addon") end,
    }, { __call = function(_, n) return permissive(n) end }),
    select = select, tonumber = tonumber, tostring = tostring, type = type,
    pairs = pairs, ipairs = ipairs, next = next, error = error, assert = assert,
    pcall = pcall, xpcall = xpcall, setmetatable = setmetatable,
    getmetatable = getmetatable, rawset = rawset, rawget = rawget,
    unpack = unpack, print = function() end, string = string, table = table,
    math = math, os = os, bit = bit, coroutine = coroutine,
    format = string.format, tinsert = table.insert, tremove = table.remove,
    wipe = function(t) for k in pairs(t) do t[k] = nil end return t end,
    time = os.time, date = os.date, GetTime = function() return 0 end,
}, { __index = function(_, k) return permissive(tostring(k)) end })
G._G = G
-- Two client shapes, because the addon branches on this and the branch not
-- taken is the one that breaks. A client without the modern tooltip processor
-- falls back to hooking setters by name -- which is where SetAuctionItem,
-- removed in 8.3, took down the file.
if not modern then
    G.TooltipDataProcessor = false
end
return G
end

local function loadAll(modern)
    local G = buildEnv(modern)
    local MC = {}
    local loaded, errors = 0, {}
for line in io.lines("addons/Collectionist/Collectionist.toc") do
    local entry = line:match("^%s*(.-)%s*$")
    if entry ~= "" and entry:sub(1, 1) ~= "#" and entry:match("%.lua$") then
        local path = "addons/Collectionist/" .. entry:gsub("\\", "/")
        -- LibStub's own version guard needs a real global, not a stub.
        if not path:match("Libs/") then
            local chunk, err = loadfile(path)
            if not chunk then
                fail = fail + 1
                print("  PARSE " .. entry .. ": " .. tostring(err))
            else
                setfenv(chunk, G)
                local good, e = pcall(chunk, "Collectionist", MC)
                if good then loaded = loaded + 1
                else errors[#errors + 1] = entry .. ": " .. tostring(e) end
            end
        end
    end
end

    return loaded, errors, MC
end

print("TOC load")

local function count(t) local n = 0 for _ in pairs(t or {}) do n = n + 1 end return n end

for _, shape in ipairs({ { true, "modern tooltip API" }, { false, "legacy tooltip API" } }) do
    local loaded, errors = loadAll(shape[1])
    for _, e in ipairs(errors) do print("  ERROR [" .. shape[2] .. "] " .. e) end
    ok(#errors == 0, "no file errors under the " .. shape[2])
    ok(loaded > 150, "every TOC file executed under the " .. shape[2] .. " (" .. loaded .. ")")
end

local _, _, MC = loadAll(true)
ok(count(MC.modules) == 8, "all 8 modules registered (" .. count(MC.modules) .. ")")
ok(MC.TabBar ~= nil, "the nav bar registered")
ok(type(MC.SortEntries) == "function", "sorting is available")
ok(MC.GOALS_KEY and MC.SEARCH_KEY and MC.OPTIONS_KEY, "the three view keys exist")
ok(count(MC.MountPins) + count(MC.PetPins) + count(MC.ToyPins) > 400, "derived pins loaded")

print(string.format("%d passed, %d failed", pass, fail))
os.exit(fail == 0 and 0 or 1)
