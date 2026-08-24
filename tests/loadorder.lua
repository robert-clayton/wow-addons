-- Load-order regressions: things that are only wrong once the files run in
-- the order the game runs them, with the deferred ADDON_LOADED work replayed.
--
-- This needs its own harness. tests/loadall.lua answers every unknown global
-- with a permissive auto-table, which is what makes it able to load the whole
-- addon -- but that same stub swallows SetScript without keeping the handler,
-- so nothing deferred to ADDON_LOADED ever runs there, and it also makes
-- `MC.RareSourceOrder` truthy from the first read. Both of those hide exactly
-- the bug this file exists to catch.

local pass, fail = 0, 0
local function ok(cond, label)
    if cond then pass = pass + 1 else fail = fail + 1 print("  FAIL " .. label) end
end

local pending = {}
local function stubFrame()
    local f = {}
    function f:RegisterEvent() end
    function f:UnregisterEvent() end
    function f:SetScript(kind, fn)
        if kind == "OnEvent" and fn then
            pending[#pending + 1] = { frame = self, fn = fn }
        end
    end
    function f:GetScript() return nil end
    return f
end

CreateFrame = stubFrame
UIParent = stubFrame()
format = string.format
time = os.time
wipe = function(t) for k in pairs(t) do t[k] = nil end end
tinsert, tremove = table.insert, table.remove
strtrim = function(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end

local MC = {}
MC.RegisterContent = function() end
MC.RegisterModule = function() end

-- The TOC is the load order. Reading it rather than listing files here is the
-- point: an alphabetical walk of the same files reports no duplicates at all
-- and fifteen false ones elsewhere.
local loaded = 0
local toc = assert(io.open("addons/Collectionist/Collectionist.toc"))
for line in toc:lines() do
    local rel = line:gsub("%s+$", "")
    if rel:match("%.lua$") and not rel:match("^#") then
        local path = "addons/Collectionist/" .. rel:gsub("\\", "/")
        local chunk = loadfile(path)
        if chunk then
            pcall(chunk, "Collectionist", MC)
            loaded = loaded + 1
        end
    end
end
toc:close()
ok(loaded > 150, "loaded the addon in TOC order (" .. loaded .. " files)")

-- Whatever the data files deferred to ADDON_LOADED now runs, after the base
-- files they were waiting for.
for _, entry in ipairs(pending) do
    pcall(entry.fn, entry.frame, "ADDON_LOADED", "Collectionist")
end
ok(#pending > 0, "some files deferred work to ADDON_LOADED (" .. #pending .. ")")

-- Each expansion file merges its own source keys into an order array the base
-- file already declares in full. Without a presence check every shared key
-- lands twice: the group renders twice, and MC.MakeSourceSummary prints the
-- zone twice in the /mc breakdown.
for _, name in ipairs({ "MountSourceOrder", "PetSourceOrder", "ToySourceOrder",
                        "DecoSourceOrder", "RareSourceOrder",
                        "TreasureSourceOrder" }) do
    local arr = MC[name]
    ok(type(arr) == "table" and #arr > 0, name .. " is populated")
    if type(arr) == "table" then
        local seen, dups = {}, 0
        for _, key in ipairs(arr) do
            if seen[key] then dups = dups + 1 end
            seen[key] = true
        end
        ok(dups == 0, name .. " lists every key once (" .. dups .. " repeated)")
    end
end

-- Every key in an order array needs a label, or the header falls back to the
-- raw key and the player reads "azj_kahet".
for _, pair in ipairs({ { "RareSourceOrder", "RareSourceLabels" },
                        { "TreasureSourceOrder", "TreasureSourceLabels" } }) do
    local arr, labels = MC[pair[1]], MC[pair[2]]
    if type(arr) == "table" and type(labels) == "table" then
        local missing = 0
        for _, key in ipairs(arr) do
            if not labels[key] then missing = missing + 1 end
        end
        ok(missing == 0, pair[1] .. " keys all have labels (" .. missing .. " without)")
    end
end

print(string.format("%d passed, %d failed", pass, fail))
os.exit(fail == 0 and 0 or 1)
