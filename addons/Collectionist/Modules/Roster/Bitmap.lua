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

local function criterionID(achievementID, criteriaIndex)
    return tostring(achievementID) .. ":" .. tostring(criteriaIndex)
end

function Bitmap:CriterionID(achievementID, criteriaIndex)
    if not (achievementID and criteriaIndex) then return nil end
    return criterionID(achievementID, criteriaIndex)
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
        for _, ach in ipairs(MC.RareData or {}) do
            for i = 1, ach.criteriaCount or 0 do
                push(out, criterionID(ach.achievementID, i))
            end
        end
    elseif modKey == "treasures" then
        for _, ach in ipairs(MC.TreasureData or {}) do
            for i = 1, ach.criteriaCount or 0 do
                push(out, criterionID(ach.achievementID, i))
            end
        end
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

-- Rare/treasure bit positions use achievementID:criteriaIndex. Both values
-- are locale-independent and remain usable even when criterion asset IDs do
-- not match the NPC/object IDs used by map data.
-- achievementID -> live criteria count, refreshed by Build() each pass.
local liveCriteriaCounts = {}

-- Returns nil (not false) when the criteria data isn't queryable yet:
-- GetAchievementCriteriaInfo hard-errors on criteria the client hasn't
-- streamed in, even after GetAchievementNumCriteria reports the full count.
local function isCriterionComplete(id)
    local achID, idx = tostring(id):match("^(%d+):(%d+)$")
    achID, idx = tonumber(achID), tonumber(idx)
    if not (achID and idx and GetAchievementCriteriaInfo) then return false end
    -- A shipped index past the live count is a removed criterion: nobody
    -- can own it, so it packs as a stable 0-bit on every same-version peer.
    local live = liveCriteriaCounts[achID]
    if live and idx > live then return false end
    local ok, _, _, completed = pcall(GetAchievementCriteriaInfo, achID, idx)
    if not ok then return nil end
    return completed and true or false
end

local SECTION_PROBE = {
    mounts      = isMountCollected,
    pets        = isSpeciesCollected,
    toys        = isToyCollected,
    decorations = isDecorCollected,
    rares       = isCriterionComplete,
    treasures   = isCriterionComplete,
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

-- Fail closed only while criteria are plausibly still streaming after
-- login. Past this window a short count is treated as a real hotfix:
-- Build's live-count check turns the missing criteria into stable 0-bits
-- instead of silently disabling sharing for every module.
local CRITERIA_STRICT_WINDOW = 180

function Bitmap:CriteriaReady()
    if self._criteriaReady then return true end
    if not GetAchievementNumCriteria then return false end
    if GetTime() - (self._loginAt or 0) > CRITERIA_STRICT_WINDOW then
        self._criteriaReady = true
        return true
    end
    for _, data in ipairs({ MC.RareData or {}, MC.TreasureData or {} }) do
        for _, ach in ipairs(data) do
            local expected = ach.criteriaCount or 0
            -- Zero-count entries contribute no bits; don't let them block.
            if expected > 0 then
                local ok, live = pcall(GetAchievementNumCriteria, ach.achievementID)
                if not ok or (live or 0) < expected then return false end
            end
        end
    end
    self._criteriaReady = true
    return true
end

-- Build the current owned-bitmap for broadcast.
function Bitmap:Build()
    if not self.ids then return nil end
    -- Never emit an all-zero partial bitmap while achievement criteria are
    -- still streaming after login.
    if not self:CriteriaReady() then return nil end
    -- Snapshot live criteria counts so the probe can distinguish removed
    -- criteria (index past the live count -> stable 0-bit) from criteria
    -- that merely haven't streamed in yet (query error -> abort below).
    wipe(liveCriteriaCounts)
    if GetAchievementNumCriteria then
        for _, data in ipairs({ MC.RareData or {}, MC.TreasureData or {} }) do
            for _, ach in ipairs(data) do
                if ach.achievementID then
                    local ok, live = pcall(GetAchievementNumCriteria, ach.achievementID)
                    liveCriteriaCounts[ach.achievementID] = (ok and live) or 0
                end
            end
        end
    end
    local sectionParts = {}
    for _, modKey in ipairs(MODULE_SECTIONS) do
        local ids = self.ids[modKey] or {}
        local probe = SECTION_PROBE[modKey]
        local bits = {}
        for i, id in ipairs(ids) do
            local owned = probe(id)
            if owned == nil then
                -- Criteria evicted since CriteriaReady() last passed; force
                -- the gate to re-verify and retry on the next CRITERIA_UPDATE.
                self._criteriaReady = false
                return nil
            end
            bits[i] = owned and 1 or 0
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
    self._criteriaReady = false
    self._loginAt = GetTime()
    computeFingerprint()
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("RECEIVED_ACHIEVEMENT_LIST")
f:RegisterEvent("CRITERIA_UPDATE")
f:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        Bitmap:Init()
    else
        Bitmap._criteriaReady = false
        if Bitmap:CriteriaReady() and MC.RosterDebouncedBroadcast then
            MC.RosterDebouncedBroadcast(5)
        end
    end
end)
