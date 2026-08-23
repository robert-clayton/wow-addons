local _, MC = ...

-- Single CHAT_MSG_ADDON listener under the "MC" prefix; sub-prefix
-- routing is ours. Outbound messages get queued and rate-limited so
-- login storms don't disconnect.
--
-- Wire: "MC|<proto>|<sub>|<payload>". Subs:
--   u  update (account-wide count summary across all expansions)
--   e  expansion sub-totals: "<expKey>:<modKey>:N/M,<modKey>:N/M,...".
--      One 'e' per expansion the player has data for. Lets the
--      Inspector's expansion filter actually re-scope peer columns.
--      Older peers without an 'e' handler silently drop these.
--   s  Collection Score: "<modKey>:<score>:<legacyCount>,...". The
--      time-investment score; per-module score plus a count of
--      collected-but-now-unobtainable items kept separately so
--      retired content doesn't lock newer collectors out.
--   v  version handshake
--   r  re-broadcast request
--   b  bitmap (single message; ≤250 bytes total wire)
--   B  bitmap chunk (one of N pieces of a larger bitmap). Payload:
--      "<fingerprint>|<generation>|<seq>/<total>|<chunk-base64>".
--      Generation contains a monotonic sender timestamp plus a content
--      length/hash, preventing chunks from different snapshots mixing.
--      Reassembled by
--      the comms layer and dispatched as a single 'b' to handlers
--      once all chunks arrive. Older peers without a 'B' handler
--      silently drop these — forward-compatible.

local PROTO_VERSION = 2
local PREFIX = "MC"
local MAX_PROTO = 2

-- Throttle base + jitter so a guild-wide login storm doesn't all hit
-- the same tick. Slower in raids since key sync can wait but DCs can't.
local SEND_INTERVAL_NORMAL = 0.3
local SEND_INTERVAL_RAID   = 1.0

local Comms = {}
Comms.queue = {}
Comms.handlers = {}  -- handlers[channel][sub] = fn(payload, sender)
Comms.frame = CreateFrame("Frame", "CollectionistCommsFrame")
Comms.encounterPause = false

MC.Comms = Comms

-- Handler registration
function Comms:RegisterPrefix(channel, sub, fn)
    if not self.handlers[channel] then self.handlers[channel] = {} end
    self.handlers[channel][sub] = fn
end

function Comms:UnregisterPrefix(channel, sub)
    if self.handlers[channel] then self.handlers[channel][sub] = nil end
end

-- Outgoing queue. Messages continue to queue during encounters; the pump
-- pauses until ENCOUNTER_END so state changes are delayed rather than lost.
local function finishMessage(msg, sent)
    if msg and msg.onSent then
        pcall(msg.onSent, sent and true or false)
    end
end

function Comms:_Enqueue(msg)
    -- Snapshot messages pass a queue key so a newer state can replace an
    -- older state that has not left the client yet.
    if msg.queueKey then
        for i = #self.queue, 1, -1 do
            if self.queue[i].queueKey == msg.queueKey then
                local replaced = self.queue[i]
                self.queue[i] = msg
                finishMessage(replaced, false)
                self.frame:Show()
                return true
            end
        end
    end
    self.queue[#self.queue + 1] = msg
    self.frame:Show()
    return true
end

function Comms:ClearQueue()
    for _, msg in ipairs(self.queue) do finishMessage(msg, false) end
    wipe(self.queue)
    self.frame:Hide()
end

function Comms:Send(sub, payload, channel, target, onSent, queueKey)
    channel = channel or "GUILD"
    if channel == "GUILD" and not IsInGuild() then return false end
    if (channel == "PARTY" or channel == "RAID") and not IsInGroup() then return false end

    local body = format("%s|%d|%s|%s", PREFIX, PROTO_VERSION, sub, payload or "")
    if #body > 250 then
        print(format("|cffff8888[MC]|r Dropping oversize comms message (%d bytes): %s", #body, sub))
        return false
    end

    return self:_Enqueue({
        body    = body,
        channel = channel,
        target  = target,
        onSent  = onSent,
        queueKey = queueKey and format("%s:%s:%s", channel, tostring(target or ""), queueKey),
    })
end

-- Broadcast to every online BNet friend who's in WoW.
function Comms:BroadcastBNet(sub, payload, onSent, queueKey)
    if not (BNGetNumFriends and BNSendGameData and BNConnected) then return end
    if not BNConnected() then return end

    local body = format("%s|%d|%s|%s", PREFIX, PROTO_VERSION, sub, payload or "")
    if #body > 250 then
        print(format("|cffff8888[MC]|r Dropping oversize BNET message (%d bytes): %s", #body, sub))
        return false
    end

    local targets = {}
    local total = BNGetNumFriends()
    for i = 1, total do
        local accountInfo = C_BattleNet and C_BattleNet.GetFriendAccountInfo
                            and C_BattleNet.GetFriendAccountInfo(i)
        if accountInfo and accountInfo.gameAccountInfo
           and accountInfo.gameAccountInfo.clientProgram == "WoW"
           and accountInfo.gameAccountInfo.isOnline then
            targets[#targets + 1] = accountInfo.gameAccountInfo.gameAccountID
        end
    end
    if #targets == 0 then return false end

    local remaining, anySent = #targets, false
    local function oneFinished(sent)
        anySent = anySent or sent
        remaining = remaining - 1
        if remaining == 0 and onSent then onSent(anySent) end
    end
    for _, target in ipairs(targets) do
        self:_Enqueue({
            body    = body,
            channel = "BNET",
            target  = target,
            onSent  = oneFinished,
            queueKey = queueKey and format("BNET:%s:%s", tostring(target), queueKey),
        })
    end
    return true
end

-- Throttled send pump. One queued message per tick; idle when empty.
local elapsed = 0
Comms.frame:Hide()
Comms.frame:SetScript("OnUpdate", function(self, dt)
    if Comms.encounterPause then return end
    elapsed = elapsed + dt
    local interval = UnitAffectingCombat("player")
        and SEND_INTERVAL_RAID or SEND_INTERVAL_NORMAL
    -- Add up to ±30ms jitter
    local jitter = (math.random() - 0.5) * 0.06
    if elapsed < interval + jitter then return end
    elapsed = 0

    local msg = table.remove(Comms.queue, 1)
    if not msg then
        self:Hide()
        return
    end

    -- Skip if context lost mid-queue (left the guild, etc.)
    if msg.channel == "GUILD" and not IsInGuild() then
        finishMessage(msg, false)
        return
    end
    if (msg.channel == "PARTY" or msg.channel == "RAID") and not IsInGroup() then
        finishMessage(msg, false)
        return
    end

    local sent = false
    if msg.channel == "BNET" then
        if BNSendGameData and msg.target then
            local ok = pcall(BNSendGameData, msg.target, PREFIX, msg.body)
            sent = ok
        end
    elseif C_ChatInfo and C_ChatInfo.SendAddonMessage then
        local ok, result = pcall(C_ChatInfo.SendAddonMessage,
            PREFIX, msg.body, msg.channel, msg.target)
        if ok then
            local success = Enum and Enum.SendAddonMessageResult
                         and Enum.SendAddonMessageResult.Success
            -- Older clients returned nil. Current clients return a result
            -- enum, whose Success value is the only confirmed delivery.
            if type(result) == "boolean" then
                sent = result
            else
                sent = result == nil or success == nil or result == success
            end
        end
    end
    finishMessage(msg, sent)
end)

-- Inbound dispatch.
local function dispatch(channel, body, sender)
    local p, proto, sub, payload = strsplit("|", body, 4)
    if p ~= PREFIX then return end
    proto = tonumber(proto)
    if not proto or proto > MAX_PROTO then return end
    local hs = Comms.handlers[channel]
    if not hs then return end
    local fn = hs[sub]
    if fn then fn(payload or "", sender, proto) end
end

local listener = CreateFrame("Frame", "CollectionistCommsListener")
listener:RegisterEvent("CHAT_MSG_ADDON")
listener:RegisterEvent("BN_CHAT_MSG_ADDON")
listener:RegisterEvent("ENCOUNTER_START")
listener:RegisterEvent("ENCOUNTER_END")
listener:SetScript("OnEvent", function(_, event, ...)
    if event == "CHAT_MSG_ADDON" then
        local prefix, body, channel, sender = ...
        if prefix ~= PREFIX then return end
        dispatch(channel, body, sender)
    elseif event == "BN_CHAT_MSG_ADDON" then
        -- BNet's 4th arg is a presenceID, not a gameAccountID. Resolve
        -- it to Name-Realm via the account info so this lines up with
        -- the guild dedup keying.
        local prefix, body, _, presenceID = ...
        if prefix ~= PREFIX then return end

        local sender
        if C_BattleNet and C_BattleNet.GetAccountInfoByID then
            local acct = C_BattleNet.GetAccountInfoByID(presenceID)
            local g = acct and acct.gameAccountInfo
            if g and g.characterName and g.realmName then
                sender = g.characterName .. "-" .. (g.realmName:gsub("%s+", ""))
            end
        end

        -- Drop unresolved senders rather than store a generic "BNet"
        -- entry that would never dedupe with the guild copy.
        if not sender then return end

        dispatch("BNET", body, sender)
    elseif event == "ENCOUNTER_START" then
        Comms.encounterPause = true
    elseif event == "ENCOUNTER_END" then
        Comms.encounterPause = false
        if #Comms.queue > 0 then Comms.frame:Show() end
    end
end)

-- Safe to register before PLAYER_LOGIN.
if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
    C_ChatInfo.RegisterAddonMessagePrefix(PREFIX)
end

function Comms:Broadcast(sub, payload)
    if IsInGuild() then return self:Send(sub, payload, "GUILD") end
    return false
end

----------------------------------------------------------------------
-- Bitmap chunking. Today's single-expansion bitmaps fit in one
-- ~150-byte addon-message; with multi-expansion data the encoded
-- payload will exceed the 250-byte cap.
--
-- SendBitmap / BroadcastBNetBitmap pick single-message ('b') for
-- small payloads and chunked ('B') for large ones. Reassembly happens
-- inside this file — handlers register against 'b' as before and
-- receive the rebuilt payload when the last chunk lands.
----------------------------------------------------------------------

-- Wire-cap budget for the pipe-separated wire shape. 250 is the
-- in-game addon-message limit; we leave a little slack.
local WIRE_BUDGET = 250

-- Per-(channel, sender, fingerprint) reassembly state. Discarded
-- after CHUNK_EXPIRY_SECONDS to keep stalled transfers from leaking.
local CHUNK_EXPIRY_SECONDS = 60
local chunkBuffer = {}

-- A generation is unique for each send and binds all chunks to the exact
-- payload. The timestamp orders generations; length/hash verifies the
-- reassembled bytes. Keep the local stamp monotonic if two sends happen in
-- the same millisecond (or the underlying clocks tick coarsely).
local lastBitmapGenerationStamp = 0

local function bitmapPayloadHash(fingerprint, payload)
    local h = 5381
    local value = tostring(fingerprint) .. "|" .. tostring(payload)
    for i = 1, #value do
        h = ((h * 33) + value:byte(i)) % 4294967296
    end
    return string.format("%08x", h)
end

local function newBitmapGeneration(fingerprint, payload)
    -- The epoch-scale component is comparable across sessions; a fractional
    -- uptime component and the monotonic fallback disambiguate rapid sends.
    local seconds = (GetServerTime and GetServerTime())
                 or (time and time()) or 0
    local precise = GetTimePreciseSec and GetTimePreciseSec() or 0
    local stamp = seconds * 1000 + math.floor((precise % 1) * 1000)
    if stamp <= lastBitmapGenerationStamp then
        stamp = lastBitmapGenerationStamp + 1
    end
    lastBitmapGenerationStamp = stamp
    -- %.0f, not %d. The stamp is an epoch in MILLISECONDS -- about 1.79e12 --
    -- and %d asks the runtime to convert the double to an integer, which
    -- overflows and raises "integer overflow attempting to store". %f formats
    -- the double directly and, with zero precision, emits exactly the same
    -- digits, so the wire format and parseBitmapGeneration are unchanged.
    return format("%.0f-%d-%s", stamp, #payload,
        bitmapPayloadHash(fingerprint, payload))
end

local function parseBitmapGeneration(generation)
    local stamp, length, hash = tostring(generation or ""):match("^(%d+)%-(%d+)%-(%x+)$")
    stamp, length = tonumber(stamp), tonumber(length)
    if not (stamp and length and hash and #hash == 8) then return nil end
    return stamp, length, hash:lower()
end

local function chunkPayloadBudget(fingerprint, generation)
    -- Body shape: MC|<proto>|B|<fp>|<generation>|<seq>/<total>|<chunk>
    -- Reserve room for the longest plausible header. seq/total caps at
    -- 9999/9999 so 9 chars including the slash; round up to 10.
    local header = #PREFIX + 1
                 + #tostring(PROTO_VERSION) + 1
                 + 1 + 1                                  -- "B|"
                 + #fingerprint + 1                       -- "<fp>|"
                 + #generation + 1                        -- "<generation>|"
                 + 10 + 1                                 -- "<seq/total>|"
    return WIRE_BUDGET - header
end

local function splitForChunking(fingerprint, generation, payload)
    local maxChunk = chunkPayloadBudget(fingerprint, generation)
    if maxChunk <= 0 then return nil end
    local chunks = {}
    for i = 1, #payload, maxChunk do
        chunks[#chunks + 1] = payload:sub(i, i + maxChunk - 1)
    end
    return chunks
end

local function singleBitmapFits(fingerprint, payload)
    -- Body: MC|<proto>|b|<fingerprint>|<payload>
    local header = #PREFIX + 1 + #tostring(PROTO_VERSION) + 1 + 1 + 1
                 + #fingerprint + 1
    return (header + #payload) <= WIRE_BUDGET
end

function Comms:SendBitmap(fingerprint, payload, channel, onSent, queueKey)
    if not (fingerprint and payload) then return end
    if singleBitmapFits(fingerprint, payload) then
        return self:Send("b", fingerprint .. "|" .. payload, channel, nil,
            onSent, queueKey)
    end
    local generation = newBitmapGeneration(fingerprint, payload)
    local chunks = splitForChunking(fingerprint, generation, payload)
    if not chunks then
        print(format("|cffff8888[MC]|r Cannot chunk bitmap (fingerprint too long): %s",
            tostring(fingerprint)))
        return false
    end
    local total = #chunks
    local remaining, allSent = total, true
    local function chunkFinished(sent)
        allSent = allSent and sent
        remaining = remaining - 1
        if remaining == 0 and onSent then onSent(allSent) end
    end
    for seq, chunk in ipairs(chunks) do
        local queued = self:Send("B", format("%s|%s|%d/%d|%s",
            fingerprint, generation, seq, total, chunk),
            channel, nil, chunkFinished, queueKey and (queueKey .. ":" .. seq))
        if not queued then chunkFinished(false) end
    end
    return true
end

function Comms:BroadcastBNetBitmap(fingerprint, payload, onSent, queueKey)
    if not (fingerprint and payload) then return end
    if singleBitmapFits(fingerprint, payload) then
        return self:BroadcastBNet("b", fingerprint .. "|" .. payload, onSent, queueKey)
    end
    local generation = newBitmapGeneration(fingerprint, payload)
    local chunks = splitForChunking(fingerprint, generation, payload)
    if not chunks then return false end
    local total = #chunks
    local remaining, allSent = total, true
    local function chunkFinished(sent)
        allSent = allSent and sent
        remaining = remaining - 1
        if remaining == 0 and onSent then onSent(allSent) end
    end
    for seq, chunk in ipairs(chunks) do
        local queued = self:BroadcastBNet("B",
            format("%s|%s|%d/%d|%s", fingerprint, generation, seq, total, chunk),
            chunkFinished, queueKey and (queueKey .. ":" .. seq))
        if not queued then chunkFinished(false) end
    end
    return true
end

-- Internal handler for chunk pieces: assemble in chunkBuffer, dispatch
-- to the registered 'b' handler when complete. Drops chunks whose
-- (fingerprint, total) doesn't match the in-flight reassembly so a
-- mid-stream version change can't corrupt a partial buffer.
local function onBitmapChunk(payload, sender, _, channel)
    local fp, generation, seqTotal, chunk = strsplit("|", payload, 4)
    if not (fp and generation and seqTotal and chunk) then return end
    local generationStamp, expectedLength, expectedHash = parseBitmapGeneration(generation)
    if not generationStamp then return end
    local seqStr, totalStr = strsplit("/", seqTotal, 2)
    local seq, total = tonumber(seqStr), tonumber(totalStr)
    if not (seq and total and seq >= 1 and seq <= total
            and total >= 1 and total <= 9999) then return end

    local now = time()

    chunkBuffer[channel] = chunkBuffer[channel] or {}
    chunkBuffer[channel][sender] = chunkBuffer[channel][sender] or {}
    local senderBuf = chunkBuffer[channel][sender]

    -- Sweep stale entries on each chunk so we don't accumulate forever.
    for fingerprint, buffered in pairs(senderBuf) do
        if buffered.ts and (now - buffered.ts) > CHUNK_EXPIRY_SECONDS then
            senderBuf[fingerprint] = nil
        end
    end

    local rec = senderBuf[fp]
    if rec and rec.generation ~= generation then
        -- A late chunk from a superseded generation must never replace or
        -- complete against a newer snapshot.
        if generationStamp < (rec.generationStamp or 0) then return end
        if generationStamp == (rec.generationStamp or 0) then
            -- Distinct snapshots can share a timestamp across addon reloads.
            -- Use the content-bound generation string as a deterministic
            -- tie-breaker so they still cannot share a reassembly buffer.
            if generation <= rec.generation then return end
        end
        rec = nil
    end
    if not rec then
        rec = {
            count = 0,
            total = total,
            parts = {},
            ts = now,
            generation = generation,
            generationStamp = generationStamp,
            expectedLength = expectedLength,
            expectedHash = expectedHash,
        }
        senderBuf[fp] = rec
    elseif rec.total ~= total or rec.complete then
        return
    end
    if not rec.parts[seq] then
        rec.parts[seq] = chunk
        rec.count = rec.count + 1
    end
    rec.ts = now

    if rec.count >= total then
        local full = {}
        for i = 1, total do
            if not rec.parts[i] then
                -- Missing piece — should not happen if count == total,
                -- but guard regardless.
                return
            end
            full[i] = rec.parts[i]
        end
        local bitmapPayload = table.concat(full)
        -- Retain the completed generation until expiry. This makes delayed
        -- older chunks harmless instead of letting them start a stale buffer.
        rec.complete = true
        rec.parts = nil
        rec.ts = now
        if #bitmapPayload ~= rec.expectedLength
           or bitmapPayloadHash(fp, bitmapPayload) ~= rec.expectedHash then
            return
        end
        local rebuilt = fp .. "|" .. bitmapPayload
        local hs = Comms.handlers[channel]
        local fn = hs and hs["b"]
        if fn then fn(rebuilt, sender, PROTO_VERSION, generation) end
    end
end

-- Auto-register the chunk-reassembler on every channel that gets a
-- 'b' handler. Wraps the original RegisterPrefix; consumers don't
-- need to know chunking exists.
local _origRegister = Comms.RegisterPrefix
function Comms:RegisterPrefix(channel, sub, fn)
    _origRegister(self, channel, sub, fn)
    if sub == "b" then
        _origRegister(self, channel, "B", function(payload, sender, proto)
            onBitmapChunk(payload, sender, proto, channel)
        end)
    end
end

function Comms:GetMaxProto() return MAX_PROTO end
function Comms:_BumpMaxProto(n)
    if n > MAX_PROTO then MAX_PROTO = n end
end
