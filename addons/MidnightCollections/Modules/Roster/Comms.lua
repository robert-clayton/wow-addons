local _, MC = ...

--------------------------------------------------------------------------
-- Roster comms: single CHAT_MSG_ADDON listener with sub-prefix routing
-- under the "MC" addon prefix. Outgoing messages sit on a throttled queue
-- so login storms in a 500-person guild don't disconnect anyone.
--
-- Wire format: "MC|<protoVer>|<sub>|<payload>"
--   <sub> = u (update), v (version), r (request), b (bitmap, v2 only)
--
-- Adapted from AstralKeys' AstralComs pattern. We register one global
-- prefix ("MC") and dispatch by sub-prefix ourselves.
--------------------------------------------------------------------------

local PROTO_VERSION = 1
local PREFIX = "MC"

-- Highest proto version this client speaks. Bumps with v2.
local MAX_PROTO = 1

-- Throttle: 0.3s default with ±0.03s jitter so peers don't all try to
-- send on the same boundary tick. 1s during raid encounters.
local SEND_INTERVAL_NORMAL = 0.3
local SEND_INTERVAL_RAID   = 1.0

local Comms = {}
Comms.queue = {}
Comms.handlers = {}  -- handlers[channel][sub] = fn(payload, sender)
Comms.frame = CreateFrame("Frame", "MidnightCollectionsCommsFrame")
Comms.encounterPause = false

MC.Comms = Comms

--------------------------------------------------------------------------
-- Handler registration
--------------------------------------------------------------------------
function Comms:RegisterPrefix(channel, sub, fn)
    if not self.handlers[channel] then self.handlers[channel] = {} end
    self.handlers[channel][sub] = fn
end

function Comms:UnregisterPrefix(channel, sub)
    if self.handlers[channel] then self.handlers[channel][sub] = nil end
end

--------------------------------------------------------------------------
-- Outgoing queue
--------------------------------------------------------------------------
function Comms:Send(sub, payload, channel, target)
    if self.encounterPause then return end
    if channel == "GUILD" and not IsInGuild() then return end
    if (channel == "PARTY" or channel == "RAID") and not IsInGroup() then return end

    local body = format("%s|%d|%s|%s", PREFIX, PROTO_VERSION, sub, payload or "")
    -- Stay under WoW's 255-byte addon-message ceiling. If a message is too
    -- big, drop it and log; v2's bitmap path will chunk explicitly.
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

--------------------------------------------------------------------------
-- Throttled send pump. Fires off one queued message per tick; idles
-- itself when the queue empties.
--------------------------------------------------------------------------
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

    if C_ChatInfo and C_ChatInfo.SendAddonMessage then
        C_ChatInfo.SendAddonMessage(PREFIX, msg.body, msg.channel, msg.target)
    end
end)

--------------------------------------------------------------------------
-- Incoming dispatcher
--------------------------------------------------------------------------
local function dispatch(channel, body, sender)
    -- Body shape: "MC|<proto>|<sub>|<payload>"
    local p, proto, sub, payload = strsplit("|", body, 4)
    if p ~= PREFIX then return end
    proto = tonumber(proto)
    if not proto or proto > MAX_PROTO then return end

    local channelHandlers = Comms.handlers[channel]
    if not channelHandlers then return end
    local fn = channelHandlers[sub]
    if not fn then return end

    -- Strip the realm-on-self suffix some servers add for guild messages.
    -- AstralKeys uses Ambiguate("guild") for display; we keep the full
    -- "Name-Realm" form internally and ambiguate at render time.
    fn(payload or "", sender, proto)
end

local listener = CreateFrame("Frame", "MidnightCollectionsCommsListener")
listener:RegisterEvent("CHAT_MSG_ADDON")
listener:RegisterEvent("ENCOUNTER_START")
listener:RegisterEvent("ENCOUNTER_END")
listener:SetScript("OnEvent", function(_, event, ...)
    if event == "CHAT_MSG_ADDON" then
        local prefix, body, channel, sender = ...
        if prefix ~= PREFIX then return end
        dispatch(channel, body, sender)
    elseif event == "ENCOUNTER_START" then
        Comms.encounterPause = true
    elseif event == "ENCOUNTER_END" then
        Comms.encounterPause = false
    end
end)

-- Register the addon prefix at module load. Safe to call before PLAYER_LOGIN.
if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
    C_ChatInfo.RegisterAddonMessagePrefix(PREFIX)
end

--------------------------------------------------------------------------
-- Convenience: same-shape sender for the standard channels.
--------------------------------------------------------------------------
function Comms:Broadcast(sub, payload)
    if IsInGuild() then self:Send(sub, payload, "GUILD") end
end

function Comms:GetMaxProto() return MAX_PROTO end

-- v2 will bump MAX_PROTO via this hook so the dispatcher accepts proto-2
-- messages once the bitmap module is loaded.
function Comms:_BumpMaxProto(n)
    if n > MAX_PROTO then MAX_PROTO = n end
end
