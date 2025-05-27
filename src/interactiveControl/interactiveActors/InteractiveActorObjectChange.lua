------------------------------------------------------------------------------------------------------------------------
-- InteractiveActorObjectChange
------------------------------------------------------------------------------------------------------------------------
-- Purpose: Interactive actor class for objectChange functionality.
--
---@author John Deere 6930 @VertexDezign
------------------------------------------------------------------------------------------------------------------------

---@class InteractiveActorObjectChange: InteractiveActor
InteractiveActorObjectChange = {}

local interactiveActorObjectChange_mt = Class(InteractiveActorObjectChange, InteractiveActor)

-- Set input types to vehicle and placeable
InteractiveActorObjectChange.INPUT_TYPES = { InteractiveController.INPUT_TYPES.VEHICLE, InteractiveController.INPUT_TYPES.PLACEABLE }
InteractiveActorObjectChange.USE_ITERATION = false

---Register OBJECT_CHANGES interactive actor
InteractiveActor.registerInteractiveActor("OBJECT_CHANGES", InteractiveActorObjectChange)

---Register XMLPaths to XMLSchema
---@param schema XMLSchema Instance of XMLSchema to register path to
---@param basePath string Base path for path registrations
---@param controllerPath string Controller path for path registrations
function InteractiveActorObjectChange.registerXMLPaths(schema, basePath, controllerPath)
    InteractiveActorObjectChange:superClass().registerXMLPaths(schema, basePath, controllerPath)

    ObjectChangeUtil.registerObjectChangeXMLPaths(schema, basePath)
end

---Creates new instance of InteractiveActorObjectChange
---@param modName string mod name
---@param modDirectory string mod directory
---@param customMt? metatable custom metatable
---@return InteractiveActorObjectChange
function InteractiveActorObjectChange.new(modName, modDirectory, customMt)
    local self = InteractiveActorObjectChange:superClass().new(modName, modDirectory, customMt or interactiveActorObjectChange_mt)

    return self
end

---Loads InteractiveActorObjectChange data from xmlFile, returns true if loading was successful, false otherwise
---@param xmlFile XMLFile Instance of XMLFile
---@param key string XML key to load from
---@param target any Target vehicle or placeable
---@param interactiveController InteractiveController Instance of InteractiveController
---@return boolean loaded True if loading succeeded, false otherwise
function InteractiveActorObjectChange:loadFromXML(xmlFile, key, target, interactiveController)
    if not InteractiveActorObjectChange:superClass().loadFromXML(self, xmlFile, key, target, interactiveController) then
        return false
    end

    self.changeObjects = {}

    if target:isa(Vehicle) then
        ObjectChangeUtil.loadObjectChangeFromXML(xmlFile, key, self.changeObjects, target.components, target)
        ObjectChangeUtil.setObjectChanges(self.changeObjects, false, self.target, target.setMovingToolDirty, true)
    elseif target:isa(Placeable) then
        ObjectChangeUtil.loadObjectChangeFromXML(xmlFile, key, self.changeObjects, target.components, target)
        ObjectChangeUtil.setObjectChanges(self.changeObjects, false, self.target)
    end

    return true
end

---Updates interactive actor by stateValue
---@param stateValue number InteractiveController stateValue
---@param forced? boolean Forced update if is true
---@param noEventSend? boolean Don't send an event
function InteractiveActorObjectChange:updateState(stateValue, forced, noEventSend)
    InteractiveActorObjectChange:superClass().updateState(stateValue, forced, noEventSend)

    local state = stateValue > 0.5

    if self.target:isa(Vehicle) then
        ObjectChangeUtil.setObjectChanges(self.changeObjects, state, self.target, self.setMovingToolDirty)
    elseif self.target:isa(Placeable) then
        ObjectChangeUtil.setObjectChanges(self.changeObjects, state, self.target)
    end
end
