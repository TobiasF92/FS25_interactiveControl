------------------------------------------------------------------------------------------------------------------------
-- InteractiveActor
------------------------------------------------------------------------------------------------------------------------
-- Purpose: Base functionality of interactive actor, that can react to interactive control
--
---@author John Deere 6930 @VertexDezign
------------------------------------------------------------------------------------------------------------------------

---@class InteractiveActor: InteractiveBase
InteractiveActor = {}

local interactiveActor_mt = Class(InteractiveActor, InteractiveBase)

---@type table<string, InteractiveActor> Actor classes by name
InteractiveActor.TYPE_BY_NAMES = {}

---Registers new interactive actor
---@param name string actor name
---@param class InteractiveActor Actor class
function InteractiveActor.registerInteractiveActor(name, class)
    if InteractiveActor.TYPE_BY_NAMES[name] ~= nil then
        Logging.error("Error: InteractiveActor '%s' already exists!", name)
        return
    end

    InteractiveActor.TYPE_BY_NAMES[name] = class
end

---Creates new instance of InteractiveActor
---@param modName string mod name
---@param modDirectory string mod directory
---@param customMt? metatable custom metatable
---@return InteractiveActor
function InteractiveActor.new(modName, modDirectory, customMt)
    local self = InteractiveActor:superClass().new(modName, modDirectory, customMt or interactiveActor_mt)

    return self
end

---Loads InteractiveActor data from xmlFile, returns true if loading was successful, false otherwise
---@param xmlFile XMLFile Instance of XMLFile
---@param key string XML key to load from
---@param target any Target vehicle or placeable
---@param interactiveController InteractiveController Instance of InteractiveController
---@return boolean loaded True if loading succeeded, false otherwise
function InteractiveActor:loadFromXML(xmlFile, key, target, interactiveController)
    if not InteractiveActor:superClass().loadFromXML(self, xmlFile, key, target, interactiveController) then
        return false
    end

    return true
end

---Updates interactive actor by stateValue
---@param stateValue number InteractiveController stateValue
---@param forced? boolean Forced update if is true
---@param noEventSend? boolean Don't send an event
function InteractiveActor:updateState(stateValue, forced, noEventSend)
end
