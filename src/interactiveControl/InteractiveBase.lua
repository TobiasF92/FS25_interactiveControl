----------------------------------------------------------------------------------------------------
-- InteractiveBase
----------------------------------------------------------------------------------------------------
-- Purpose: Base functionality of interactive actors and actions
--
---@author John Deere 6930 @VertexDezign
----------------------------------------------------------------------------------------------------

---@class InteractiveBase
---@field public interactiveController InteractiveController
---@field public target Vehicle|Placeable
---@field public xmlFile XMLFile
---@field public inputTypes InteractiveController.INPUT_TYPES
InteractiveBase = {}

local interactiveBase_mt = Class(InteractiveBase)

---@type table<InteractiveController.INPUT_TYPES> InputTypes of interactive base default is enum UNKNOWN
InteractiveBase.INPUT_TYPES = { InteractiveController.INPUT_TYPES.UNKNOWN }
---@type string|nil Key name of interactive base, default is nil
InteractiveBase.KEY_NAME = nil
---@type boolean Actor uses iterations
InteractiveBase.USE_ITERATION = true

---Register XMLPaths to XMLSchema
---@param schema XMLSchema Instance of XMLSchema to register path to
---@param basePath string Base path for path registrations
---@param controllerPath string Controller path for path registrations
function InteractiveBase.registerXMLPaths(schema, basePath, controllerPath)
end

---Creates new instance of InteractiveBase
---@param modName string mod name
---@param modDirectory string mod directory
---@param customMt? metatable custom metatable
---@return InteractiveBase
function InteractiveBase.new(modName, modDirectory, customMt)
    local self = setmetatable({}, customMt or interactiveBase_mt)

    self.modName = modName
    self.modDirectory = modDirectory
    self.interactiveController = nil
    self.target = nil
    self.xmlFile = nil

    return self
end

---Loads InteractiveBase data from xmlFile, returns true if loading was successful, false otherwise
---@param xmlFile XMLFile Instance of XMLFile
---@param key string XML key to load from
---@param target any Target vehicle or placeable
---@param interactiveController InteractiveController Instance of InteractiveController
---@return boolean loaded True if loading succeeded, false otherwise
function InteractiveBase:loadFromXML(xmlFile, key, target, interactiveController)
    if target == nil or interactiveController == nil then
        return false
    end

    self.xmlFile = xmlFile
    self.target = target
    self.interactiveController = interactiveController

    return true
end

---Called after load
---@param savegame any
function InteractiveBase:postLoad(savegame)
end

---Called on delete
function InteractiveBase:delete()
end
