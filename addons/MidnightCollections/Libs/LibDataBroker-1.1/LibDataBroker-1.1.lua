-- LibDataBroker-1.1 - A central registry for data provider addons
-- Licensed under the MIT license.

local MAJOR, MINOR = "LibDataBroker-1.1", 4
local lib = LibStub:NewLibrary(MAJOR, MINOR)
if not lib then return end

lib.callbacks = lib.callbacks or LibStub("CallbackHandler-1.0"):New(lib)
lib.attributestorage = lib.attributestorage or {}
lib.namestorage = lib.namestorage or {}
lib.proxystorage = lib.proxystorage or {}

local attributestorage = lib.attributestorage
local callbacks = lib.callbacks
local namestorage = lib.namestorage
local proxystorage = lib.proxystorage

function lib:NewDataObject(name, dataobj)
    if proxystorage[name] then return end

    local storage = {}
    if dataobj then
        for k, v in pairs(dataobj) do
            storage[k] = v
        end
    end

    attributestorage[name] = storage
    namestorage[name] = name

    local proxy = setmetatable({}, {
        __index = function(_, key)
            return storage[key]
        end,
        __newindex = function(_, key, value)
            if storage[key] == value then return end
            storage[key] = value
            callbacks:Fire("LibDataBroker_AttributeChanged", name, key, value, proxy)
            callbacks:Fire("LibDataBroker_AttributeChanged_" .. name, name, key, value, proxy)
            callbacks:Fire("LibDataBroker_AttributeChanged_" .. name .. "_" .. key, name, key, value, proxy)
        end,
    })

    proxystorage[name] = proxy
    callbacks:Fire("LibDataBroker_DataObjectCreated", name, proxy)
    return proxy
end

function lib:DataObjectIterator()
    return pairs(proxystorage)
end

function lib:GetDataObjectByName(name)
    return proxystorage[name]
end

function lib:GetNameByDataObject(dataobj)
    for name, proxy in pairs(proxystorage) do
        if proxy == dataobj then return name end
    end
end
