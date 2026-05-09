local _, MC = ...

-- v2 per-item ownership bitmap. Each module assigns one bit per
-- collectible (declaration order). Owned-set is packed -> base64 ->
-- shipped as "MC|2|b|<fingerprint>|<sections>".
--
-- The fingerprint hashes the ID order so peers running different addon
-- versions silently ignore each other's bitmaps instead of misreading
-- bit positions. ~620 bits today fits in a single message.

local Bitmap = {}
MC.Bitmap = Bitmap

-- Recipes left out — recipe.id is a spell ID that revs between patches
-- and the scanner keys by skillLine, so it's a poor fit for a static
-- bit index.
local MODULE_SECTIONS = { "mounts", "pets", "toys", "decorations", "rares", "treasures" }

-- Per-module ID list (declaration-order). ids[modKey][i] -> canonical
-- ID; indexOf[modKey] is the reverse.
local function push(out, id)
    -- Skip falsy IDs — a nil hole here would shift every later bit and
    -- corrupt cross-peer ownership lookups.
    if id ~= nil and id ~= "" and id ~= 0 then
        out[#out + 1] = id
    end
end

local function flattenModuleData(modKey)
    local out = {}
    if modKey == "mounts" then
        for _, group in ipairs(MC.MountData or {}) do
            for _, m in ipairs(group.mounts or {}) do
                push(out, m.mountID or m.itemID)
            end
        end
    elseif modKey == "pets" then
        for _, group in ipairs(MC.PetData or {}) do
            for _, p in ipairs(group.pets or {}) do
                push(out, p.speciesID)
            end
        end
    elseif modKey == "toys" then
        for _, group in ipairs(MC.ToyData or {}) do
            for _, t in ipairs(group.toys or {}) do
                push(out, t.itemID)
            end
        end
    elseif modKey == "decorations" then
        for _, group in ipairs(MC.DecorationData or {}) do
            for _, d in ipairs(group.decorations or {}) do
                push(out, d.decorID)
            end
        end
    elseif modKey == "rares" then
        for npcID in pairs(MC.RareNPCs or {}) do
            push(out, npcID)
        end
        table.sort(out)
    elseif modKey == "treasures" then
        for name in pairs(MC.TreasureCoords or {}) do
            push(out, name)
        end
        table.sort(out)
    end
    return out
end

local function buildIndex()
    Bitmap.ids = {}
    Bitmap.indexOf = {}
    for _, modKey in ipairs(MODULE_SECTIONS) do
        local ids = flattenModuleData(modKey)
        Bitmap.ids[modKey] = ids
        local lookup = {}
        for i, id in ipairs(ids) do lookup[id] = i end
        Bitmap.indexOf[modKey] = lookup
    end
end

-- Cheap hash; collision-resistant isn't needed, just stability.
local function cheapHash(s)
    local h = 5381
    for i = 1, #s do
        h = ((h * 33) + s:byte(i)) % 4294967296
    end
    return h
end

local function computeFingerprint()
    local parts = {}
    for _, modKey in ipairs(MODULE_SECTIONS) do
        parts[#parts + 1] = modKey
        for _, id in ipairs(Bitmap.ids[modKey] or {}) do
            parts[#parts + 1] = tostring(id)
        end
    end
    Bitmap.fingerprint = string.format("%08x", cheapHash(table.concat(parts, "|")))
end

function Bitmap:GetFingerprint() return self.fingerprint end

-- Per-module ownership probes — one function per section.
local function isMountCollected(mountID)
    if not (mountID and C_MountJournal) then return false end
    local _, _, _, _, _, _, _, _, _, _, isCollected = C_MountJournal.GetMountInfoByID(mountID)
    return isCollected and true or false
end

local function isSpeciesCollected(speciesID)
    if not (speciesID and C_PetJournal) then return false end
    local n = C_PetJournal.GetNumCollectedInfo(speciesID)
    return n and n > 0
end

local function isToyCollected(itemID)
    if not itemID then return false end
    return PlayerHasToy and PlayerHasToy(itemID) or false
end

local function isDecorCollected(decorID)
    -- Defer to the Decorations Scanner — it has the right API call
    -- shape and the numPlaced/quantity ownership semantics.
    local mod = MC.modulesByKey and MC.modulesByKey["decorations"]
    if mod and mod.Scanner and mod.Scanner.CheckCollected then
        local ok, owned = pcall(mod.Scanner.CheckCollected, mod.Scanner, decorID, nil)
        return ok and owned or false
    end
    return false
end

local function isRareKilled(npcID)
    -- Rare scanner already maintains per-rare collected state from the
    -- achievement criteria; just look in there.
    local mod = MC.modulesByKey and MC.modulesByKey["rares"]
    if not (mod and mod.Scanner and mod.Scanner.results) then return false end
    local r = mod.Scanner.results
    if not r.bySource then return false end
    for _, list in pairs(r.bySource) do
        for _, entry in ipairs(list) do
            if entry.npcID == npcID then return entry.collected and true or false end
        end
    end
    if r.collected then
        for _, entry in ipairs(r.collected) do
            if entry.npcID == npcID then return true end
        end
    end
    return false
end

local function isTreasureLooted(name)
    local mod = MC.modulesByKey and MC.modulesByKey["treasures"]
    if not (mod and mod.Scanner and mod.Scanner.results) then return false end
    local r = mod.Scanner.results
    if r.collected then
        for _, entry in ipairs(r.collected) do
            if entry.name == name then return true end
        end
    end
    return false
end

local SECTION_PROBE = {
    mounts      = isMountCollected,
    pets        = isSpeciesCollected,
    toys        = isToyCollected,
    decorations = isDecorCollected,
    rares       = isRareKilled,
    treasures   = isTreasureLooted,
}

-- 0/1 array <-> byte string.
local function packBits(bits)
    local n = #bits
    local bytes = {}
    for byteIdx = 1, math.ceil(n / 8) do
        local b = 0
        for offset = 0, 7 do
            local bitPos = (byteIdx - 1) * 8 + offset + 1
            if bits[bitPos] == 1 then
                b = b + 2 ^ offset
            end
        end
        bytes[#bytes + 1] = string.char(math.floor(b))
    end
    return table.concat(bytes)
end

local function unpackBits(s, count)
    local bits = {}
    for i = 0, count - 1 do
        local byteIdx = math.floor(i / 8) + 1
        local offset  = i % 8
        local b = s:byte(byteIdx) or 0
        bits[i + 1] = (math.floor(b / 2 ^ offset) % 2 == 1) and 1 or 0
    end
    return bits
end

-- URL-safe base64 so the payload survives chat-message escaping.
local B64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"
local B64_INDEX = {}
for i = 1, #B64 do B64_INDEX[B64:sub(i, i)] = i - 1 end

local function b64Encode(bin)
    local out = {}
    local i = 1
    while i <= #bin do
        local a = bin:byte(i)     or 0
        local b = bin:byte(i + 1) or 0
        local c = bin:byte(i + 2) or 0
        out[#out + 1] = B64:sub(math.floor(a / 4) + 1, math.floor(a / 4) + 1)
        out[#out + 1] = B64:sub(((a % 4) * 16) + math.floor(b / 16) + 1,
                                ((a % 4) * 16) + math.floor(b / 16) + 1)
        out[#out + 1] = B64:sub(((b % 16) * 4) + math.floor(c / 64) + 1,
                                ((b % 16) * 4) + math.floor(c / 64) + 1)
        out[#out + 1] = B64:sub((c % 64) + 1, (c % 64) + 1)
        i = i + 3
    end
    return table.concat(out)
end

local function b64Decode(s)
    local out = {}
    local i = 1
    while i <= #s do
        local a = B64_INDEX[s:sub(i,     i)]     or 0
        local b = B64_INDEX[s:sub(i + 1, i + 1)] or 0
        local c = B64_INDEX[s:sub(i + 2, i + 2)] or 0
        local d = B64_INDEX[s:sub(i + 3, i + 3)] or 0
        out[#out + 1] = string.char(a * 4 + math.floor(b / 16))
        out[#out + 1] = string.char(((b % 16) * 16) + math.floor(c / 4))
        out[#out + 1] = string.char(((c % 4) * 64) + d)
        i = i + 4
    end
    return table.concat(out)
end

-- Build the current owned-bitmap for broadcast.
function Bitmap:Build()
    if not self.ids then return nil end
    local sectionParts = {}
    for _, modKey in ipairs(MODULE_SECTIONS) do
        local ids = self.ids[modKey] or {}
        local probe = SECTION_PROBE[modKey]
        local bits = {}
        for i, id in ipairs(ids) do
            bits[i] = probe(id) and 1 or 0
        end
        sectionParts[#sectionParts + 1] = b64Encode(packBits(bits)) .. "/" .. tostring(#ids)
    end
    -- Sections joined by ';', each "<base64>/<bitCount>".
    return table.concat(sectionParts, ";")
end

-- Decode a peer's bitmap into per-module sets keyed by canonical ID.
function Bitmap:Decode(payload)
    if not payload or payload == "" then return nil end
    local owned = {}
    local sections = { strsplit(";", payload) }
    for i, modKey in ipairs(MODULE_SECTIONS) do
        local section = sections[i]
        if section then
            local enc, n = section:match("^(.-)/(%d+)$")
            if enc and n then
                n = tonumber(n)
                local ids = self.ids[modKey] or {}
                if #ids == n then
                    local bits = unpackBits(b64Decode(enc), n)
                    local set = {}
                    for j, id in ipairs(ids) do
                        if bits[j] == 1 then set[id] = true end
                    end
                    owned[modKey] = set
                end
                -- Skip silently when bit counts disagree — peer's data
                -- file has a different ordering than ours.
            end
        end
    end
    return owned
end

-- Used by the tooltip "Owned by:" line. Returns peer names whose
-- bitmap contains the given module/id.
function Bitmap:OwnersOf(modKey, canonicalID)
    if not (MC.RosterDB and self.fingerprint) then return {} end
    local owners = {}
    for name, rec in pairs(MC.RosterDB) do
        if type(name) == "string" and name:sub(1, 1) ~= "_"
           and type(rec) == "table"
           and rec.bitmap and rec.bitmap.fingerprint == self.fingerprint then
            local set = rec.bitmap.owned and rec.bitmap.owned[modKey]
            if set and set[canonicalID] then
                owners[#owners + 1] = name
            end
        end
    end
    table.sort(owners)
    return owners
end

-- Build the index after PLAYER_LOGIN, once all module data files are
-- loaded into MC.<Module>Data.
function Bitmap:Init()
    buildIndex()
    computeFingerprint()
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function() Bitmap:Init() end)
