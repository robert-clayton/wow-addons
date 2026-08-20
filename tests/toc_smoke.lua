-- Execute the shipped addon in the same order as Collectionist.toc, including
-- nested XML Script/Include references. This deliberately does not fire any
-- registered events: the goal is to catch top-level namespace and load-order
-- failures without pretending to simulate the WoW client.

local function fail(message)
    error("TOC smoke test: " .. message, 0)
end

local function normalize(path)
    return (path:gsub("\\", "/"):gsub("//+", "/"))
end

local function dirname(path)
    return path:match("^(.*)/[^/]*$") or "."
end

local function join(base, relative)
    relative = normalize(relative)
    if relative:match("^%a:/") or relative:sub(1, 1) == "/" then
        return relative
    end
    return normalize(base .. "/" .. relative)
end

local function readAll(path)
    local file, err = io.open(path, "rb")
    if not file then fail("cannot open " .. path .. ": " .. tostring(err)) end
    local contents = file:read("*a")
    file:close()
    return contents
end

------------------------------------------------------------------------
-- Minimal initialization-time WoW surface.
------------------------------------------------------------------------

local noop = function() end
local newProxy

newProxy = function()
    local object = {}
    return setmetatable(object, {
        __index = function(t, key)
            local value
            if key == "CreateTexture" or key == "CreateFontString"
                or key == "CreateAnimationGroup" then
                value = function() return newProxy() end
            elseif key == "GetWidth" then
                value = function() return 1920 end
            elseif key == "GetHeight" then
                value = function() return 1080 end
            elseif key == "GetScale" or key == "GetEffectiveScale" then
                value = function() return 1 end
            elseif key == "IsShown" or key == "IsVisible" then
                value = function() return false end
            else
                value = noop
            end
            rawset(t, key, value)
            return value
        end,
    })
end

CreateFrame = function() return newProxy() end
CreateColor = function(r, g, b, a) return { r = r, g = g, b = b, a = a } end
CreateFromMixins = function(...)
    local result = {}
    for i = 1, select("#", ...) do
        local mixin = select(i, ...)
        if type(mixin) == "table" then
            for key, value in pairs(mixin) do result[key] = value end
        end
    end
    return result
end
Mixin = function(target, ...)
    local mixed = CreateFromMixins(...)
    for key, value in pairs(mixed) do target[key] = value end
    return target
end

UIParent = newProxy()
Minimap = newProxy()
GameTooltip = newProxy()
StaticPopupDialogs = {}
SlashCmdList = {}
STANDARD_TEXT_FONT = "Fonts/FRIZQT__.TTF"

C_AddOns = {
    GetAddOnMetadata = function(_, field)
        if field == "Version" then return "toc-smoke" end
    end,
}
C_ChatInfo = { RegisterAddonMessagePrefix = function() return true end }
C_Timer = { After = noop }
Enum = { SendAddonMessageResult = { Success = 0 } }

format = string.format
strlower = string.lower
strupper = string.upper
strmatch = string.match
strfind = string.find
strsub = string.sub
gsub = string.gsub
tinsert = table.insert
tremove = table.remove
strtrim = function(value, chars)
    local pattern = chars and ("^[" .. chars .. "]*(.-)[" .. chars .. "]*$")
        or "^%s*(.-)%s*$"
    return (tostring(value or ""):match(pattern))
end
strsplit = function(delimiter, value, limit)
    local parts, start = {}, 1
    value = tostring(value or "")
    while not limit or #parts < limit - 1 do
        local first, last = value:find(delimiter, start, true)
        if not first then break end
        parts[#parts + 1] = value:sub(start, first - 1)
        start = last + 1
    end
    parts[#parts + 1] = value:sub(start)
    return unpack(parts)
end
wipe = function(tbl) for key in pairs(tbl) do tbl[key] = nil end end
CopyTable = function(source)
    local copy = {}
    for key, value in pairs(source) do
        copy[key] = type(value) == "table" and CopyTable(value) or value
    end
    return copy
end
hooksecurefunc = noop
time = os.time
GetServerTime = os.time
GetTime = os.clock
GetTimePreciseSec = os.clock

------------------------------------------------------------------------
-- TOC/XML traversal and execution.
------------------------------------------------------------------------

local addonName = "Collectionist"
local namespace = {}
local loadedLua = {}
local includeStack = {}

local function executeLua(path)
    local chunk, compileError = loadfile(path)
    if not chunk then fail("compile failed in " .. path .. ": " .. tostring(compileError)) end
    local ok, runtimeError = pcall(chunk, addonName, namespace)
    if not ok then fail("load failed in " .. path .. ": " .. tostring(runtimeError)) end
    loadedLua[#loadedLua + 1] = path
end

local loadReference

local function executeXml(path)
    if includeStack[path] then fail("recursive XML include at " .. path) end
    includeStack[path] = true
    local xml = readAll(path)
    local base = dirname(path)
    for tag, attributes in xml:gmatch("<%s*([%w_:]+)(.-)>") do
        tag = tag:match("([^:]+)$")
        if tag == "Script" or tag == "Include" then
            local reference = attributes:match([[file%s*=%s*"([^"]+)"]])
                or attributes:match("file%s*=%s*[']([^']+)[']")
            if not reference then fail(tag .. " without file attribute in " .. path) end
            loadReference(join(base, reference))
        end
    end
    includeStack[path] = nil
end

loadReference = function(path)
    path = normalize(path)
    local extension = path:match("%.([^./]+)$")
    extension = extension and extension:lower()
    if extension == "lua" then
        executeLua(path)
    elseif extension == "xml" then
        executeXml(path)
    else
        fail("unsupported TOC/XML reference: " .. path)
    end
end

local tocPath = "addons/Collectionist/Collectionist.toc"
local addonRoot = dirname(tocPath)
for line in readAll(tocPath):gmatch("[^\r\n]+") do
    local entry = line:match("^%s*(.-)%s*$")
    if entry ~= "" and entry:sub(1, 1) ~= "#" then
        loadReference(join(addonRoot, entry))
    end
end

-- Data/Changelog.lua is generated from CHANGELOG.md and is the only copy the
-- addon can read at runtime. If someone bumps the TOC and edits the markdown
-- but forgets to regenerate, What's New would announce the wrong release --
-- so fail the build instead.
do
    local tocVersion = readAll(tocPath):match("##%s*Version:%s*([%d%.]+)")
    if not tocVersion then fail("no ## Version in the TOC") end
    local newest = namespace.CHANGELOG and namespace.CHANGELOG[1]
    if not newest then fail("MC.CHANGELOG is empty - run generate-collectionist-changelog-lua.ps1") end
    if newest.version ~= tocVersion then
        fail(string.format(
            "Data/Changelog.lua is stale: newest entry is %s but the TOC says %s. "
            .. "Run scripts/generate-collectionist-changelog-lua.ps1",
            tostring(newest.version), tocVersion))
    end
end

if not namespace.RegisterContent then fail("Core did not initialize RegisterContent") end
if type(namespace.modules) ~= "table" or #namespace.modules ~= 8 then
    fail("expected 8 registered modules, got " .. tostring(namespace.modules and #namespace.modules))
end
if #loadedLua < 1 then fail("TOC did not load any Lua files") end

print(string.format("Collectionist TOC smoke test passed (%d Lua files)", #loadedLua))
