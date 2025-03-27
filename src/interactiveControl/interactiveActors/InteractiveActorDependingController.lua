------------------------------------------------------------------------------------------------------------------------
-- InteractiveActorDependingController
------------------------------------------------------------------------------------------------------------------------
-- Purpose: Interactive actor class for depending interactive controller functionality.
--
---@author John Deere 6930 @VertexDezign
------------------------------------------------------------------------------------------------------------------------

---@class InteractiveActorDependingController: InteractiveActor
---@field public dependingInteractiveController InteractiveController
InteractiveActorDependingController = {}

local interactiveActorDependingController_mt = Class(InteractiveActorDependingController, InteractiveActor)

-- Set input types to vehicle and placeable
InteractiveActorDependingController.INPUT_TYPES = { InteractiveController.INPUT_TYPES.VEHICLE, InteractiveController.INPUT_TYPES.PLACEABLE }
InteractiveActorDependingController.KEY_NAME = "dependingInteractiveControl"

---Register DEPENDING_INTERACTIVE_CONTROL interactive actor
InteractiveActor.registerInteractiveActor("DEPENDING_INTERACTIVE_CONTROL", InteractiveActorDependingController)

---Register XMLPaths to XMLSchema
---@param schema XMLSchema Instance of XMLSchema to register path to
---@param basePath string Base path for path registrations
---@param controllerPath string Controller path for path registrations
function InteractiveActorDependingController.registerXMLPaths(schema, basePath, controllerPath)
    InteractiveActorDependingController:superClass().registerXMLPaths(schema, basePath, controllerPath)

    schema:register(XMLValueType.INT, basePath .. "#index", "Index of depending interactive control", nil, true)
    schema:register(XMLValueType.FLOAT, basePath .. "#minLimit", "Depending interactive control value min. limit", 0.0)
    schema:register(XMLValueType.FLOAT, basePath .. "#maxLimit", "Depending interactive control value max. limit", 1.0)
end

---Creates new instance of InteractiveActorDependingController
---@param modName string mod name
---@param modDirectory string mod directory
---@param customMt? metatable custom metatable
---@return InteractiveActorDependingController
function InteractiveActorDependingController.new(modName, modDirectory, customMt)
    local self = InteractiveActorDependingController:superClass().new(modName, modDirectory, customMt or interactiveActorDependingController_mt)

    self.dependingInteractiveController = nil

    return self
end

---Loads InteractiveActorDependingController data from xmlFile, returns true if loading was successful, false otherwise
---@param xmlFile XMLFile Instance of XMLFile
---@param key string XML key to load from
---@param target any Target vehicle
---@param interactiveController InteractiveController Instance of InteractiveController
---@return boolean loaded True if loading succeeded, false otherwise
function InteractiveActorDependingController:loadFromXML(xmlFile, key, target, interactiveController)
    if not InteractiveActorDependingController:superClass().loadFromXML(self, xmlFile, key, target, interactiveController) then
        return false
    end

    local index = xmlFile:getValue(key .. "#index")
    if index == nil then
        return false
    end

    self.index = index
    self.minLimit = xmlFile:getValue(key .. "#minLimit", 0.0)
    self.maxLimit = xmlFile:getValue(key .. "#maxLimit", 1.0)

    return true
end

---Called after load
---@param savegame any
function InteractiveActorDependingController:postLoad(savegame)
    InteractiveActorDependingController:superClass().postLoad(savegame)

    self.dependingInteractiveController = self.target:getInteractiveControllerByIndex(self.index)

    if self.dependingInteractiveController == nil then
        Logging.xmlWarning(self.xmlFile, "Unable to find depending interactive control with index '%d' in target vehicle, ignoring depending control!", self.index)
    end
end

---Returns true if controller is blocked, false otherwise
---@return boolean isBlocked
function InteractiveActorDependingController:isBlocked()
    if self.dependingInteractiveController == nil then
        return false
    end

    local stateValue = self.dependingInteractiveController:getStateValue()
    if self.maxLimit < stateValue or stateValue < self.minLimit then
        return true
    end

    return false
end
