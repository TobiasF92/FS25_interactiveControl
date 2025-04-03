------------------------------------------------------------------------------------------------------------------------
-- InteractiveActorFunction
------------------------------------------------------------------------------------------------------------------------
-- Purpose: Interactive actor class for function functionality.
--
---@author John Deere 6930 @VertexDezign
------------------------------------------------------------------------------------------------------------------------

---@class InteractiveActorFunction: InteractiveActor
InteractiveActorFunction = {}

local interactiveActorFunction_mt = Class(InteractiveActorFunction, InteractiveActor)

-- Set input types to vehicle
InteractiveActorFunction.INPUT_TYPES = { InteractiveController.INPUT_TYPES.VEHICLE }
InteractiveActorFunction.KEY_NAME = "function"

---Register VEHICLE_FUNCTION interactive actor
InteractiveActor.registerInteractiveActor("VEHICLE_FUNCTION", InteractiveActorFunction)

InteractiveActorFunction.FUNCTION_UPDATE_TIME_OFFSET = 2500 -- ms

---Register XMLPaths to XMLSchema
---@param schema XMLSchema Instance of XMLSchema to register path to
---@param basePath string Base path for path registrations
---@param controllerPath string Controller path for path registrations
function InteractiveActorFunction.registerXMLPaths(schema, basePath, controllerPath)
    InteractiveActorFunction:superClass().registerXMLPaths(schema, basePath, controllerPath)

    -- register function XMLPaths
    local functionNames = ""
    for _, functionData in pairs(InteractiveFunctions.FUNCTIONS) do
        if functionData.schemaFunc ~= nil then
            functionData.schemaFunc(schema, basePath)
        end

        functionNames = ("%s | %s"):format(functionNames, functionData.name)
    end

    schema:register(XMLValueType.STRING, basePath .. "#name", ("Function name (available: %s)"):format(functionNames))
end

---Creates new instance of InteractiveActorFunction
---@param modName string mod name
---@param modDirectory string mod directory
---@param customMt? metatable custom metatable
---@return InteractiveActorFunction
function InteractiveActorFunction.new(modName, modDirectory, customMt)
    local self = InteractiveActorFunction:superClass().new(modName, modDirectory, customMt or interactiveActorFunction_mt)

    return self
end

---Loads InteractiveActorFunction data from xmlFile, returns true if loading was successful, false otherwise
---@param xmlFile XMLFile Instance of XMLFile
---@param key string XML key to load from
---@param target any Target vehicle
---@param interactiveController InteractiveController Instance of InteractiveController
---@return boolean loaded True if loading succeeded, false otherwise
function InteractiveActorFunction:loadFromXML(xmlFile, key, target, interactiveController)
    if not InteractiveActorFunction:superClass().loadFromXML(self, xmlFile, key, target, interactiveController) then
        return false
    end

    local functionName = xmlFile:getValue(key .. "#name")
    functionName = functionName:upper()

    local data = InteractiveFunctions.getFunctionData(functionName)
    if data == nil then
        Logging.xmlWarning(xmlFile, "Unable to find functionName '%s' for InteractiveActorFunction '%s'", functionName, key)
        return false
    end

    self.data = data
    self.loadData = {}

    if data.loadFunc ~= nil then
        data.loadFunc(xmlFile, key, self.loadData)
    end

    return true
end

---Returns true if saving is allowed, false otherwise
---@return boolean allowsSaving
function InteractiveActorFunction:isSavingAllowed()
    return false
end

---Returns true if analog is allowed, false otherwise
---@return boolean allowsAnalog
function InteractiveActorFunction:isAnalogAllowed()
    return false
end

---Updates interactive actor by stateValue
---@param stateValue number InteractiveController stateValue
---@param forced? boolean Forced update if is true
---@param noEventSend? boolean Don't send an event
function InteractiveActorFunction:updateState(stateValue, forced, noEventSend)
    InteractiveActorFunction:superClass().updateState(stateValue, forced, noEventSend)

    if self.data == nil then
        return
    end

    -- Todo: analog function, currently not used
    if stateValue > 0.5 then
        self.data.posFunc(self.target, self.loadData, noEventSend)
    else
        self.data.negFunc(self.target, self.loadData, noEventSend)
    end

    self.target:setVehicleMaxUpdateTime(self.interactiveController.lastChangeTime + InteractiveActorFunction.FUNCTION_UPDATE_TIME_OFFSET)
end

---Called on update
---@param isIndoor boolean True if update is indoor
---@param isOutdoor boolean True if update is outdoor
---@param hasInput boolean True if target has input
function InteractiveActorFunction:update(isIndoor, isOutdoor, hasInput)
    if self.data == nil or self.data.updateFunc == nil then
        return
    end

    local returnState = self.data.updateFunc(self.target, self.loadData)
    if returnState == nil then
        return
    end

    if type(returnState) == 'boolean' then
        if returnState ~= self.interactiveController:getStateBool() then
            self.interactiveController:setStateValue(returnState, false, true, true)
        end
    else
        -- Todo: analog function, currently not used
    end
end

---Returns true if controller is blocked, false otherwise
---@return boolean isBlocked
function InteractiveActorFunction:isBlocked()
    if self.data ~= nil and self.data.isBlockedFunc ~= nil then
        if not self.data.isBlockedFunc(self.target, self.loadData) then
            return true
        end
    end

    return false
end

---Returns forced action text if is defined
---@return string|nil forcedText
function InteractiveActorFunction:getForcedActionText()
    if self.data ~= nil and self.data.forcedActionText ~= nil then
        return self.data.forcedActionText(self.target, self.loadData)
    end

    return nil
end
