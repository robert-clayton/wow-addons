local _, MC = ...

-- Single CHAT_MSG_ADDON listener under the "MC" prefix; sub-prefix
-- routing is ours. Outbound messages get queued and rate-limited so
-- login storms don't disconnect.
--
-- Wire: "MC|<proto>|<sub>|<payload>". Subs: u=update, v=version,
-- r=request, b=bitmap (v2).

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

-- Outgoing queue
function Comms:Send(sub, payload, channel, target)
    if self.encounterPause then return end
    if channel == "GUILD" and not IsInGuild() then return end
    if (channel == "PARTY" or channel == "RAID") and not IsInGroup() then return end

    local body = format("%s|%d|%s|%s", PREFIX, PROTO_VERSION, sub, payload or "")
    if #body > 250 then
        print(format("|cffff8888[MC]|r Dropping oversize comms message (%d bytes): %s", #body, sub))
        return
    end

    self.queue[#self.queue + 1] = {
        body    = body,
        channel = channel or "GUILD",
        target  = target,
    }
    self.frame:Show()
end

-- Broadcast to every online BNet friend who's in WoW.
function Comms:BroadcastBNet(sub, payload)
    if self.encounterPause then return end
    if not (BNGetNumFriends and BNSendGameData and BNConnected) then return end
    if not BNConnected() then return end

    local body = format("%s|%d|%s|%s", PREFIX, PROTO_VERSION, sub, payload or "")
    if #body > 250 then
        print(format("|cffff8888[MC]|r Dropping oversize BNET message (%d bytes): %s", #body, sub))
        return
    end

    local total = BNGetNumFriends()
    for i = 1, total do
        local accountInfo = C_BattleNet and C_BattleNet.GetFriendAccountInfo
                            and C_BattleNet.GetFriendAccountInfo(i)
        if accountInfo and accountInfo.gameAccountInfo
           and accountInfo.gameAccountInfo.clientProgram == "WoW"
           and accountInfo.gameAccountInfo.isOnline then
            self.queue[#self.queue + 1] = {
                body    = body,
                channel = "BNET",
                target  = accountInfo.gameAccountInfo.gameAccountID,
            }
        end
    end
    self.frame:Show()
end

-- Throttled send pump. One queued message per tick; idle when empty.
local elapsed = 0
Comms.frame:Hide()
Comms.frame:SetScript("OnUpdate", function(self, dt)
    elapsed = elapsed + dt
    local interval = (UnitAffectingCombat("player") or Comms.encounterPause)
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
    if msg.channel == "GUILD" and not IsInGuild() then return end
    if (msg.channel == "PARTY" or msg.channel == "RAID") and not IsInGroup() then return end

    if msg.channel == "BNET" then
        if BNSendGameData and msg.target then
            BNSendGameData(msg.target, PREFIX, msg.body)
        end
    elseif C_ChatInfo and C_ChatInfo.SendAddonMessage then
        C_ChatInfo.SendAddonMessage(PREFIX, msg.body, msg.channel, msg.target)
    end
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
    end
end)

-- Safe to register before PLAYER_LOGIN.
if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
    C_ChatInfo.RegisterAddonMessagePrefix(PREFIX)
end

function Comms:Broadcast(sub, payload)
    if IsInGuild() then self:Send(sub, payload, "GUILD") end
end

function Comms:GetMaxProto() return MAX_PROTO end
function Comms:_BumpMaxProto(n)
    if n > MAX_PROTO then MAX_PROTO = n end
end
