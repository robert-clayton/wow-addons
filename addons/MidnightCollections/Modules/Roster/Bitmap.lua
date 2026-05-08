local _, MC = ...

--------------------------------------------------------------------------
-- Bitmap encoding for per-item ownership sync (v2 wire format).
--
-- Each module has a stable bit-index assigned to every collectible based
-- on declaration order in MC.<Module>Data. A peer's owned-set is packed
-- into a bitstring, base64-encoded, and broadcast as a single
-- "MC|2|b|<fingerprint>|<payload>" message.
--
-- A protoFingerprint of the bit-layout (cheap hash of all collectible IDs
-- in order) gates compatibility: a peer with a different addon version
-- whose data files have shifted item ordering will compute a different
-- fingerprint and ignore the payload, since the bit indices won't line up.
--
-- Total bit budget for current Midnight content (~620 collectibles):
--   ~620 / 8 = ~78 bytes raw -> ~104 chars base64
--   "MC|2|b|<8-char-fp>|<104 chars>" ~= 124 bytes total — fits in one
--   addon message comfortably under the 255-byte cap.
--------------------------------------------------------------------------

local Bitmap = {}
MC.Bitmap = Bitmap

-- Module key -> sub-key (a single char in the wire so we can pack
-- multiple modules into one bitmap message later if needed).
local MODULE_SECTIONS = { "mounts", "pets", "toys", "decorations", "rares", "treasures" }
-- Recipes deliberately omitted: their key is recipe.id (spell IDs that
-- can rev across patches) and the result table is keyed by skillLine.
-- Keep the bitmap to the modules with stable, declaration-order IDs.

--------------------------------------------------------------------------
-- Build a per-module index lookup. Each module contributes:
--   ids[modKey][i] = canonical-ID of the i-th collectible (1-based)
--   indexOf[modKey][canonicalID] = i (reverse lookup)
-- Canonical-ID picks the first stable identifier present on the entry:
--   mountID > speciesID > itemID > decorID > npcID > criteriaIndex
-- For rares we use npcID; for treasures we use criterion-name (no
-- numeric ID, but Treasures Scanner exposes them in a known order via
-- MC.TreasureCoords).
--------------------------------------------------------------------------
local function flattenModuleData(modKey)
    local out = {}
    if modKey == "mounts" then
        for _, group in ipairs(MC.MountData or {}) do
            for _, m in ipairs(group.mounts or {}) do
                out[#out + 1] = m.mountID or m.itemID
            end
        end
    elseif modKey == "pets" then
        for _, group in ipairs(MC.PetData or {}) do
            for _, p in ipairs(group.pets or {}) do
                out[#out + 1] = p.speciesID
            end
        end
    elseif modKey == "toys" then
        for _, group in ipairs(MC.ToyData or {}) do
            for _, t in ipairs(group.toys or {}) do
                out[#out + 1] = t.itemID
            end
        end
    elseif modKey == "decorations" then
        for _, group in ipairs(MC.DecorationData or {}) do
            for _, d in ipairs(group.decorations or {}) do
                out[#out + 1] = d.decorID
            end
        end
    elseif modKey == "rares" then
        for npcID in pairs(MC.RareNPCs or {}) do
            out[#out + 1] = npcID
        end
        table.sort(out)
    elseif modKey == "treasures" then
        for name in pairs(MC.TreasureCoords or {}) do
            out[#out + 1] = name
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

--------------------------------------------------------------------------
-- Fingerprint: cheap hash of every section's ID list joined together.
-- Different addon-versions with reordered/added items produce a
-- different fingerprint, so peers running mismatched data ignore each
-- other's bitmaps instead of mis-interpreting bit positions.
--------------------------------------------------------------------------
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

--------------------------------------------------------------------------
-- Owned-set extraction from current Scanner results.
--------------------------------------------------------------------------
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
    if not (decorID and C_HousingCatalog) then return false end
    local info = C_HousingCatalog.GetCatalogEntryInfoByRecordID
                 and C_HousingCatalog.GetCatalogEntryInfoByRecordID(decorID)
    return info and info.isOwned or false
end

local function isRareKilled(npcID)
    -- Rares are tracked via achievement criteria; the Rares scanner
    -- already publishes a per-rare collected flag in its results.
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

--------------------------------------------------------------------------
-- Pack a 0/1 array (1-indexed) into a byte string.
--------------------------------------------------------------------------
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

--------------------------------------------------------------------------
-- Base64 (URL-safe alphabet so the message can be wire-clean).
--------------------------------------------------------------------------
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

--------------------------------------------------------------------------
-- Build current owned-bitmap for broadcast.
--------------------------------------------------------------------------
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
    -- Sections separated by ';'. Section format: <base64>/<bitCount>.
    return table.concat(sectionParts, ";")
end

--------------------------------------------------------------------------
-- Decode a peer's bitmap into a per-module set keyed by canonical ID.
--------------------------------------------------------------------------
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
                -- If the per-section bit count doesn't match what we
                -- expect for this module, silently drop that section
                -- (peer's data file has different ordering).
            end
        end
    end
    return owned
end

--------------------------------------------------------------------------
-- Lookup helper used by the tooltip extension. Returns a list of peer
-- character names whose decoded bitmap contains the given module/id.
--------------------------------------------------------------------------
function Bitmap:OwnersOf(modKey, canonicalID)
    if not (MC.RosterDB and self.fingerprint) then return {} end
    local owners = {}
    for name, rec in pairs(MC.RosterDB) do
        if rec.bitmap and rec.bitmap.fingerprint == self.fingerprint then
            local set = rec.bitmap.owned and rec.bitmap.owned[modKey]
            if set and set[canonicalID] then
                owners[#owners + 1] = name
            end
        end
    end
    table.sort(owners)
    return owners
end

--------------------------------------------------------------------------
-- Initialization. Build the index after PLAYER_LOGIN so all module data
-- files are loaded.
--------------------------------------------------------------------------
function Bitmap:Init()
    buildIndex()
    computeFingerprint()
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function() Bitmap:Init() end)
