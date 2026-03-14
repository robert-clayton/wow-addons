-- LibDBIcon-1.0 - Minimap icon library
-- Licensed under the MIT license.

local DBICON10 = "LibDBIcon-1.0"
local DBICON10_MINOR = 50

if not LibStub then return end
local lib = LibStub:NewLibrary(DBICON10, DBICON10_MINOR)
if not lib then return end

lib.objects = lib.objects or {}
lib.callbackRegistered = lib.callbackRegistered or {}
lib.callbacks = lib.callbacks or LibStub("CallbackHandler-1.0"):New(lib)
lib.notCreated = lib.notCreated or {}

local objects = lib.objects

local function getAnchors(frame)
    local x, y = frame:GetCenter()
    if not x or not y then return "CENTER" end
    local hhalf = (x > UIParent:GetWidth() * 2 / 3) and "RIGHT" or (x < UIParent:GetWidth() / 3) and "LEFT" or ""
    local vhalf = (y > UIParent:GetHeight() / 2) and "TOP" or "BOTTOM"
    return vhalf .. hhalf, frame, (vhalf == "TOP" and "BOTTOM" or "TOP") .. hhalf
end

local function updatePosition(button, angle)
    if type(angle) ~= "number" then
        angle = math.rad(button.db.minimapPos or 225)
    end
    local radius = button.db.radius or 80
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * radius, math.sin(angle) * radius)
end

local function onEnter(self)
    if self.isMoving then return end
    local obj = self.dataObject
    if obj.OnTooltipShow then
        GameTooltip:SetOwner(self, "ANCHOR_NONE")
        GameTooltip:SetPoint(getAnchors(self))
        obj.OnTooltipShow(GameTooltip)
        GameTooltip:Show()
    elseif obj.OnEnter then
        obj.OnEnter(self)
    end
end

local function onLeave(self)
    GameTooltip:Hide()
    if self.dataObject.OnLeave then self.dataObject.OnLeave(self) end
end

local function onClick(self, button)
    if self.dataObject.OnClick then
        self.dataObject.OnClick(self, button)
    end
end

local function onDragStart(self)
    self.isMoving = true
    self:SetScript("OnUpdate", function(s)
        local mx, my = Minimap:GetCenter()
        local cx, cy = GetCursorPosition()
        local scale = Minimap:GetEffectiveScale()
        cx, cy = cx / scale, cy / scale
        local angle = math.atan2(cy - my, cx - mx)
        s.db.minimapPos = math.deg(angle) % 360
        updatePosition(s, angle)
    end)
    GameTooltip:Hide()
end

local function onDragStop(self)
    self:SetScript("OnUpdate", nil)
    self.isMoving = false
end

local function createButton(name, obj, db)
    local button = CreateFrame("Button", "LibDBIcon10_" .. name, Minimap)
    button:SetFrameStrata("MEDIUM")
    button:SetSize(32, 32)
    button:SetFrameLevel(8)
    button:RegisterForClicks("anyUp")
    button:RegisterForDrag("LeftButton")
    button:SetHighlightTexture(136477) -- UI-Minimap-ZoomButton-Highlight

    local overlay = button:CreateTexture(nil, "OVERLAY")
    overlay:SetSize(56, 56)
    overlay:SetTexture(136430) -- MiniMap-TrackingBorder
    overlay:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)

    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetSize(24, 24)
    background:SetTexture(136467) -- UI-Minimap-Background
    background:SetPoint("CENTER", button, "CENTER", 0, 1)

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER", button, "CENTER", 0, 1)
    icon:SetTexture(obj.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
    button.icon = icon

    button.dataObject = obj
    button.db = db

    button:SetScript("OnEnter", onEnter)
    button:SetScript("OnLeave", onLeave)
    button:SetScript("OnClick", onClick)
    button:SetScript("OnDragStart", onDragStart)
    button:SetScript("OnDragStop", onDragStop)

    updatePosition(button)

    if db.hide then
        button:Hide()
    else
        button:Show()
    end

    objects[name] = button

    if not lib.callbackRegistered[name] then
        LibStub("LibDataBroker-1.1").callbacks:RegisterCallback("LibDataBroker_AttributeChanged_" .. name, function(_, _, key, value)
            if key == "icon" then
                button.icon:SetTexture(value)
            end
        end)
        lib.callbackRegistered[name] = true
    end
end

function lib:Register(name, obj, db)
    if not obj then
        error(DBICON10 .. ": You need to pass a data broker object to :Register()", 2)
    end
    if not db then
        error(DBICON10 .. ": You need to pass a saved variables table to :Register()", 2)
    end
    db.minimapPos = db.minimapPos or 225
    db.radius = db.radius or 80

    if Minimap then
        createButton(name, obj, db)
    else
        lib.notCreated[name] = {obj = obj, db = db}
    end
end

function lib:Show(name)
    if objects[name] then
        objects[name]:Show()
        objects[name].db.hide = false
    end
end

function lib:Hide(name)
    if objects[name] then
        objects[name]:Hide()
        objects[name].db.hide = true
    end
end

function lib:IsRegistered(name)
    return objects[name] ~= nil or lib.notCreated[name] ~= nil
end

function lib:GetMinimapButton(name)
    return objects[name]
end
