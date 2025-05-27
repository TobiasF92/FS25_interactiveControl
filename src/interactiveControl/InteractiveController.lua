------------------------------------------------------------------------------------------------------------------------
-- InteractiveController
------------------------------------------------------------------------------------------------------------------------
-- Purpose: Functionality of interactive controller object
--
---@author John Deere 6930 @VertexDezign
------------------------------------------------------------------------------------------------------------------------

---@class InteractiveController
---@field public modName string
---@field public modDirectory string
---@field public interactiveActors table<InteractiveActor>
---@field public interactiveActions table<InteractiveAction>
---@field public stateValue number
InteractiveController = {}

local interactiveObject_mt = Class(InteractiveController)

InteractiveController.STATE_VALUE_THRESHOLD = 0.0001

---@enum InteractiveController.INPUT_TYPES Interactive object inputTypes
InteractiveController.INPUT_TYPES = {
    UNKNOWN = 0,
    VEHICLE = 1,
    PLACEABLE = 2,
}

---Validates path against inputTypes
---@param path string Path for registrations
---@param inputTypes table<InteractiveController.INPUT_TYPES> InputTypes to validate path against
---@return boolean isValid Returns true if is valid, false otherwise
local function validatePathAgainstInputTypes(path, inputTypes)
    local isValid = false

    for _, inputType in ipairs(inputTypes) do
        if inputType == InteractiveController.INPUT_TYPES.UNKNOWN then
            isValid = true
            break
        elseif inputType == InteractiveController.INPUT_TYPES.VEHICLE then
            if path:find("vehicle") then
                isValid = true
            end
        elseif inputType == InteractiveController.INPUT_TYPES.PLACEABLE then
            if path:find("placeable") then
                isValid = true
            end
        end
    end

    return isValid
end

---Register XMLPaths to XMLSchema
---@param schema XMLSchema Instance of XMLSchema to register path to
---@param basePath string Base path for path registrations
function InteractiveController.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.L10N_STRING, basePath .. "#posText", "Text for positive direction action", "$l10n_actionIC_activate")
    schema:register(XMLValueType.L10N_STRING, basePath .. "#negText", "Text for negative direction action", "$l10n_actionIC_deactivate")

    schema:register(XMLValueType.BOOL, basePath .. "#enabled", "Interactive control is enabled", true)
    schema:register(XMLValueType.BOOL, basePath .. "#analog", "Interactive control is analog", false)
    schema:register(XMLValueType.FLOAT, basePath .. "#analogSpeed", "Interactive control analog speed", 0.04)
    schema:register(XMLValueType.BOOL, basePath .. "#allowsSaving", "Interactive control allows saving (Functions can never be saved)", true)

    -- Register all valid interactiveActors in XMLSchema
    for name, actorClass in pairs(InteractiveActor.TYPE_BY_NAMES) do
        if validatePathAgainstInputTypes(basePath, actorClass.INPUT_TYPES) then
            local keyName = actorClass.KEY_NAME or name

            local actorBasePath = basePath
            if actorClass.USE_ITERATION then
                actorBasePath = ("%s.%s(?)"):format(basePath, keyName)
            end

            actorClass.registerXMLPaths(schema, actorBasePath, basePath)
        end
    end

    -- Register all valid interactiveActions in XMLSchema
    for name, actionClass in pairs(InteractiveAction.TYPE_BY_NAMES) do
        if validatePathAgainstInputTypes(basePath, actionClass.INPUT_TYPES) then
            local keyName = actionClass.KEY_NAME or name

            local actionBasePath = basePath
            if actionClass.USE_ITERATION then
                actionBasePath = ("%s.%s(?)"):format(basePath, keyName)
            end

            actionClass.registerXMLPaths(schema, actionBasePath, basePath)
        end
    end

    -- register configurations restrictions
    schema:register(XMLValueType.STRING, basePath .. ".configurationsRestrictions.restriction(?)#name", "Configuration name")
    schema:register(XMLValueType.VECTOR_N, basePath .. ".configurationsRestrictions.restriction(?)#indices", "Configuration indices to block interactive control", true)

    -- register depending movingTools
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".dependingMovingTool(?)#node", "Moving tool node")
    schema:register(XMLValueType.BOOL, basePath .. ".dependingMovingTool(?)#isInactive", "(IC) Is moving tool active while control is configured", true)

    -- register depending movingTools
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".dependingMovingPart(?)#node", "Moving part node")
    schema:register(XMLValueType.BOOL, basePath .. ".dependingMovingPart(?)#isInactive", "(IC) Is moving part active while control is configured", true)

    -- register sound modifier
    schema:register(XMLValueType.FLOAT, basePath .. ".soundModifier#indoorFactor", "Indoor sound modifier factor for active interactive control")
    schema:register(XMLValueType.FLOAT, basePath .. ".soundModifier#delayedSoundAnimationTime", "Delayed sound animation time")
    schema:register(XMLValueType.STRING, basePath .. ".soundModifier#name", "Animation name, if not set, first animation will be used")
end

---Register savegame XMLPaths to XMLSchema
---@param schema XMLSchema Instance of XMLSchema to register path to
---@param basePath string Base path for path registrations
function InteractiveController.registerSavegameXMLPaths(schema, basePath)
    schema:register(XMLValueType.INT, basePath .. "#index", "Current interactive control index")
    schema:register(XMLValueType.FLOAT, basePath .. "#stateValue", "Current interactive control state value")
end

---Create new instance of InteractiveController
---@param modName string mod name
---@param modDirectory string mod directory
---@param customMt? metatable custom metatable
---@return InteractiveController
function InteractiveController.new(modName, modDirectory, customMt)
    local self = setmetatable({}, customMt or interactiveObject_mt)

    self.modName = modName
    self.modDirectory = modDirectory

    self.stateValue = 0.0
    self.lastStateValue = 1.0
    self.loadedDirty = false
    self.analog = false
    self.allowsSaving = true
    self.externallyBlocked = false
    self.hoverTimeOut = 0
    self.lastChangeTime = 0

    self.interactiveActors = {}
    self.interactiveActions = {}

    return self
end

---Loads Interactive Object from xmlFile, returns true if loading was successful, false otherwise
---@param xmlFile XMLFile Instance of XMLFile
---@param key string XML key to load from
---@param target any Target vehicle or placeable
---@param index number index of controller at target
---@return boolean loaded loaded state
function InteractiveController:loadFromXML(xmlFile, key, target, index)
    if xmlFile == nil or target == nil then
        return false
    end

    self.xmlFile = xmlFile
    self.index = index
    self.target = target

    self.posText = xmlFile:getValue(key .. "#posText", "$l10n_actionIC_activate", target.customEnvironment)
    self.negText = xmlFile:getValue(key .. "#negText", "$l10n_actionIC_deactivate", target.customEnvironment)

    self.analog = xmlFile:getValue(key .. "#analog", false)
    self.analogSpeed = xmlFile:getValue(key .. "#analogSpeed", 0.04)
    self.allowsSaving = xmlFile:getValue(key .. "#allowsSaving", true)
    self.enabled = xmlFile:getValue(key .. "#enabled", true)

    if self.enabled then
        self.enabled = self:isRestricted(xmlFile, key .. ".configurationsRestrictions", target)
    end

    for name, class in pairs(InteractiveActor.TYPE_BY_NAMES) do
        local keyName = class.KEY_NAME or name

        if class.USE_ITERATION then
            xmlFile:iterate(key .. "." .. keyName, function(_, actorKey)
                local interactiveActor = class.new(self.modName, self.modDirectory)

                if interactiveActor:loadFromXML(xmlFile, actorKey, target, self) then
                    table.insert(self.interactiveActors, interactiveActor)
                else
                    interactiveActor:delete()
                    Logging.xmlWarning(xmlFile, "Could not load interactiveActor for '%s'", actorKey)

                    return false
                end
            end)
        else
            local interactiveActor = class.new(self.modName, self.modDirectory)

            if interactiveActor:loadFromXML(xmlFile, key, target, self) then
                table.insert(self.interactiveActors, interactiveActor)
            else
                interactiveActor:delete()
                Logging.xmlWarning(xmlFile, "Could not load interactiveActor for '%s'", key)
            end
        end
    end

    for name, class in pairs(InteractiveAction.TYPE_BY_NAMES) do
        local keyName = class.KEY_NAME or name

        if class.USE_ITERATION then
            xmlFile:iterate(key .. "." .. keyName, function(_, actionKey)
                local interactiveAction = class.new(self.modName, self.modDirectory)

                if interactiveAction:loadFromXML(xmlFile, actionKey, target, self) then
                    table.insert(self.interactiveActions, interactiveAction)
                else
                    interactiveAction:delete()
                    Logging.xmlWarning(xmlFile, "Could not load interactiveAction for '%s'", actionKey)

                    return false
                end
            end)
        else
            local interactiveAction = class.new(self.modName, self.modDirectory)

            if interactiveAction:loadFromXML(xmlFile, key, target, self) then
                table.insert(self.interactiveActions, interactiveAction)
            else
                interactiveAction:delete()
                Logging.xmlWarning(xmlFile, "Could not load interactiveAction for '%s'", key)
            end
        end
    end

    self.allowsSaving = self:isSavingAllowed()

    if self.analog then
        self.analog = self:isAnalogAllowed()
    end

    self.movingToolsInactive = {}
    self.movingPartsInactive = {}

    if target.getMovingToolByNode ~= nil then
        -- load inactive movingTools from xml
        xmlFile:iterate(key .. ".dependingMovingTool", function(_, movingToolKey)
            local mNode = xmlFile:getValue(movingToolKey .. "#node", nil, target.components, target.i3dMappings)
            local isInactive = xmlFile:getValue(movingToolKey .. "#isInactive")
            local movingTool = target:getMovingToolByNode(mNode)

            if movingTool ~= nil and isInactive then
                self.movingToolsInactive[movingTool] = true
            end
        end)

        -- load inactive movingParts from xml
        xmlFile:iterate(key .. ".dependingMovingPart", function(_, movingPartKey)
            local mNode = xmlFile:getValue(movingPartKey .. "#node", nil, target.components, target.i3dMappings)
            local isInactive = xmlFile:getValue(movingPartKey .. "#isInactive")
            local movingPart = target:getMovingPartByNode(mNode)

            if movingPart ~= nil and isInactive then
                self.movingPartsInactive[movingPart] = true
            end
        end)
    end

    -- load sound modifier
    self.soundModifier = {
        indoorFactor = xmlFile:getValue(key .. ".soundModifier#indoorFactor"),
        delayedSoundAnimationTime = xmlFile:getValue(key .. ".soundModifier#delayedSoundAnimationTime"),
        name = xmlFile:getValue(key .. ".soundModifier#name"),
        currentFactor = InteractiveControl.SOUND_FALLBACK
    }

    self.loadedDirty = false

    return true
end

---Called after load
---@param savegame table savegame
function InteractiveController:postLoad(savegame)
    -- Set default animation name for sound modifier
    if self.soundModifier.name == nil then
        for _, actor in ipairs(self.interactiveActors) do
            if actor:isa(InteractiveActorAnimation) then
                if actor.name ~= nil then
                    self.soundModifier.name = actor.name
                    break
                end
            end
        end
    end

    -- Post load at actors and actions
    self:callInteractiveBaseFunction('postLoad', true, true, savegame)
end

---Called on load from savegame
---@param savegame table savegame
---@param key string XML key to load from
function InteractiveController:loadFromSavegame(savegame, key)
    local stateValue = savegame.xmlFile:getValue(key .. "#stateValue", 0.0)
    self:setStateValue(stateValue, true, true, true)

    self.loadedDirty = true
end

---Saves interactive controller state to savegame
---@param xmlFile XMLFile Instance of XMLFile
---@param key string XML key to load from
---@param usedModNames boolean Used mod names
function InteractiveController:saveToXMLFile(xmlFile, key, usedModNames)
    if not self.allowsSaving then
        return false
    end

    xmlFile:setValue(key .. "#index", self.index)
    xmlFile:setValue(key .. "#stateValue", self:getStateValue())

    return true
end

---Calls function name on any actor or action
---@param functionName string Function name to call
---@param callActors? boolean Call on actors
---@param callActions? boolean Call on actions
---@param ... unknown Arguments to pass to function call
function InteractiveController:callInteractiveBaseFunction(functionName, callActors, callActions, ...)
    if Utils.getNoNil(callActors, true) then
        for _, actor in ipairs(self.interactiveActors) do
            if actor[functionName] ~= nil then
                actor[functionName](actor, ...)
            end
        end
    end

    if Utils.getNoNil(callActions, true) then
        for _, action in ipairs(self.interactiveActions) do
            if action[functionName] ~= nil then
                action[functionName](action, ...)
            end
        end
    end
end

---Returns true if predicate function is valid, false if any interactive base returns false
---@param predicateName string Predicate function name to call
---@param checkActors? boolean Check on actors
---@param checkActions? boolean Check on actions
---@param inverted? boolean Inverted function return
---@param ... unknown Arguments to pass to predicate function call
---@return boolean allowed predicate is allowed
function InteractiveController:isInteractiveBasePredicateAllowed(predicateName, checkActors, checkActions, inverted, ...)
    inverted = Utils.getNoNil(inverted, false)

    if Utils.getNoNil(checkActors, true) then
        for _, actor in ipairs(self.interactiveActors) do
            if actor[predicateName] ~= nil then
                if actor[predicateName](actor, ...) == inverted then
                    return inverted
                end
            end
        end
    end

    if Utils.getNoNil(checkActions, true) then
        for _, action in ipairs(self.interactiveActions) do
            if action[predicateName] ~= nil then
                if action[predicateName](action, ...) == inverted then
                    return inverted
                end
            end
        end
    end

    return not inverted
end

---Returns true if saving is allowed, false otherwise
---@return boolean allowsSaving
function InteractiveController:isSavingAllowed()
    return self:isInteractiveBasePredicateAllowed('isSavingAllowed')
end

---Returns true if analog is allowed, false otherwise
---@return boolean allowsSaving
function InteractiveController:isAnalogAllowed()
    return self:isInteractiveBasePredicateAllowed('isAnalogAllowed')
end

---Returns true if controller is blocked, false otherwise
---@return boolean isBlocked
function InteractiveController:isBlocked()
    return self:isExternallyBlocked() or self:isInteractiveBasePredicateAllowed('isBlocked', true, true, true)
end

---Returns true if InteractiveController is enabled by configuration setup
---@param xmlFile XMLFile Instance of XMLFile
---@param key string XML key to load from
---@param target any Target vehicle or placeable
---@return boolean enabled
function InteractiveController:isRestricted(xmlFile, key, target)
    local enabled = true

    xmlFile:iterate(key .. ".restriction", function(_, restrictionKey)
        if enabled then
            XMLUtil.checkDeprecatedXMLElements(self.xmlFile, restrictionKey .. "#indicies", restrictionKey .. "#indices") -- FS22 to FS25

            local name = xmlFile:getValue(restrictionKey .. "#name")

            if target.configurations[name] ~= nil then
                local indices = xmlFile:getValue(restrictionKey .. "#indices", nil, true)

                if indices ~= nil then
                    for _, index in ipairs(indices) do
                        if index == target.configurations[name] then
                            enabled = false
                            break
                        end
                    end
                end
            else
                enabled = false
            end
        end
    end)

    return enabled
end

---Called on delete
function InteractiveController:delete()
    -- Delete at actors and actions
    self:callInteractiveBaseFunction('delete', true, true)
end

---Called on client side on join
---@param streamId number streamId
---@param connection number connection
function InteractiveController:readStream(streamId, connection)
    local stateValue = streamReadFloat32(streamId)
    self:setStateValue(stateValue, nil, true)
end

---Called on server side on join
---@param streamId number stream id
---@param connection number connection id
function InteractiveController:writeStream(streamId, connection)
    streamWriteFloat32(streamId, self.stateValue)
end

---Called on update
---@param isIndoor boolean True if update is indoor
---@param isOutdoor boolean True if update is outdoor
---@param hasInput boolean True if target has input
function InteractiveController:update(isIndoor, isOutdoor, hasInput)
    if not self:isEnabled() then
        return
    end

    if self:isBlocked() then
        isIndoor = false
        isOutdoor = false
        hasInput = false
    end

    -- Update at actors and actions
    self:callInteractiveBaseFunction('update', true, true, isIndoor, isOutdoor, hasInput)
end

---Returns true if interactiveController is enabled, false otherwise
---@return boolean enabled
function InteractiveController:isEnabled()
    return self.enabled
end

---Returns true if interactiveController is analog, false otherwise
---@return boolean enabled
function InteractiveController:isAnalog()
    return self.analog
end

---Set state value
---@param stateValue number|boolean State value to set, boolean values will be converted
---@param updateStates? boolean Update states at actors and actions
---@param forced? boolean Forced state value set
---@param noEventSend? boolean Don't send an event
function InteractiveController:setStateValue(stateValue, updateStates, forced, noEventSend)
    if type(stateValue) == 'boolean' then
        stateValue = stateValue and 1.0 or 0.0
    end

    if math.abs(stateValue - self.stateValue) > InteractiveController.STATE_VALUE_THRESHOLD or forced then
        ICStateValueEvent.sendEvent(self.target, self.index, stateValue, noEventSend)

        self.stateValue = stateValue
        self.lastChangeTime = g_currentMission.time

        if updateStates == nil or updateStates then
            self:updateState(stateValue, forced, noEventSend)
        end

        self.hoverTimeOut = g_currentMission.time + self:maxHoverTimeout()
    end
end

---Toggle control if not analog
function InteractiveController:toggleStateValue()
    if self:isAnalog() then
        return
    end

    self:setStateValue(not self:getStateBool())
end

---Changes analog control state value in direction
---@param direction? number Direction to set state value
function InteractiveController:changeAnalogStateValueInDirection(direction)
    if direction == nil or direction == 0 then
        return
    end

    local stateValue = math.clamp(self.stateValue + self.analogSpeed * direction, 0.0, 1.0)
    self:setStateValue(stateValue)
end

---Executes controller, based on analog or not
function InteractiveController:execute()
    if self:isAnalog() then
        self:changeAnalogStateValueInDirection(self:getActiveActionDirection())
    else
        self:toggleStateValue()
    end
end

---Returns state value between 0.0 and 1.0
---@return number stateValue
function InteractiveController:getStateValue()
    return self.stateValue
end

---Returns true if is active, false otherwise
---@return boolean state
function InteractiveController:getStateBool()
    return self.stateValue > 0.5
end

---Updates InteractiveController by stateValue
---@param stateValue number InteractiveController stateValue
---@param forced? boolean Forced update if is true
---@param noEventSend? boolean Don't send an event
function InteractiveController:updateState(stateValue, forced, noEventSend)
    -- Update state at actors
    self:callInteractiveBaseFunction('updateState', true, false, stateValue, forced, noEventSend)
end

---Returns max hover time out collected from all actors and actions
---@return integer
function InteractiveController:maxHoverTimeout()
    local maxTimeout = 0

    if self:isAnalog() then
        return maxTimeout
    end

    for _, actor in ipairs(self.interactiveActors) do
        if actor['maxHoverTimeout'] ~= nil then
            local timeout = actor['maxHoverTimeout'](actor)

            maxTimeout = math.max(maxTimeout, timeout)
        end
    end

    for _, action in ipairs(self.interactiveActions) do
        if action['maxHoverTimeout'] ~= nil then
            local timeout = action['maxHoverTimeout'](action)

            maxTimeout = math.max(maxTimeout, timeout)
        end
    end

    return maxTimeout
end

---Returns true if controller has hover timeout, false otherwise
---@return boolean hasTimeout
function InteractiveController:hasHoverTimeout()
    return self.hoverTimeOut > g_currentMission.time
end

------------------------------------------------------Action Events-----------------------------------------------------

---Updates the active action and returns it
---@return InteractiveAction|nil activeAction
function InteractiveController:updateActiveAction()
    self.activeAction = nil

    for _, action in ipairs(self.interactiveActions) do
        if action:isExecutable() then
            --Todo: add priority?
            self.activeAction = action
            break
        end
    end

    return self.activeAction
end

---Returns direction of active action
---@return number direction
function InteractiveController:getActiveActionDirection()
    if self.activeAction ~= nil then
        return self.activeAction.direction
    end

    return 0
end

---Returns action text by controller state
---@param getForced boolean
---@return string actionText
function InteractiveController:getActionText(getForced)
    if getForced == nil or getForced then
        for _, actor in ipairs(self.interactiveActors) do
            if actor['getForcedActionText'] ~= nil then
                local forcedText = actor['getForcedActionText'](actor)

                if forcedText ~= nil and forcedText ~= "" then
                    return forcedText
                end
            end
        end
    end

    if self:isAnalog() then
        return self:getActiveActionDirection() >= 0 and self.posText or self.negText
    end

    return self:getStateBool() and self.posText or self.negText
end

---Returns action input button by controller state
---@return InputAction inputButton
function InteractiveController:getActionInputButton()
    return self.activeAction.inputButton
end

------------------------------------------------------ Cylindered ------------------------------------------------------

---Returns true if moving tools are set, false otherwise
---@return boolean hasDependingMovingTools
function InteractiveController:hasDependingMovingTools()
    return table.size(self.movingToolsInactive) > 0
end

---Returns true if movingTool is inactive, false otherwise
---@param movingTool table movingTool table
---@return boolean isInactive
function InteractiveController:getMovingToolIsInactive(movingTool)
    if self.movingToolsInactive[movingTool] ~= nil and self.movingToolsInactive[movingTool] then
        return true
    end

    return false
end

---Returns true if moving parts are set, false otherwise
---@return boolean hasDependingMovingParts
function InteractiveController:hasDependingMovingParts()
    return table.size(self.movingPartsInactive) > 0
end

---Returns true if movingPart is inactive, false otherwise
---@param movingPart table movingPart table
---@return boolean isInactive
function InteractiveController:getMovingPartIsInactive(movingPart)
    if self.movingPartsInactive[movingPart] ~= nil and self.movingPartsInactive[movingPart] then
        return true
    end

    return false
end

-------------------------------------------------- Externally Blocking -------------------------------------------------

---Set controller externally blocked
---@param externallyBlocked boolean Externally blocked value to set
function InteractiveController:blockExternally(externallyBlocked)
    if externallyBlocked ~= self.externallyBlocked then
        self.externallyBlocked = externallyBlocked
    end
end

---Returns true if controller is externally blocked
---@return boolean externallyBlocked
function InteractiveController:isExternallyBlocked()
    return self.externallyBlocked
end

-------------------------------------------------------- Sounds --------------------------------------------------------

---Called on animation is updated
---@param animationName string Animation name
function InteractiveController:updateAnimation(animationName)
    local soundModifier = self.soundModifier

    if soundModifier.name == nil or soundModifier.indoorFactor == nil or animationName ~= soundModifier.name then
        return
    end

    local animTime = self.target:getAnimationTime(animationName)
    if animTime == nil then
        return
    end

    soundModifier.delayedSoundAnimationTime = 0.5

    local currentFactor = InteractiveControl.SOUND_FALLBACK
    for _, actor in ipairs(self.interactiveActors) do
        if actor:isa(InteractiveActorAnimation) then
            if soundModifier.name == actor.name then
                if soundModifier.delayedSoundAnimationTime ~= nil then
                    local alpha = math.clamp(animTime, 0, soundModifier.delayedSoundAnimationTime) / soundModifier.delayedSoundAnimationTime
                    currentFactor = MathUtil.lerp(InteractiveControl.SOUND_FALLBACK, soundModifier.indoorFactor, alpha)
                end

                break
            end
        end
    end

    soundModifier.currentFactor = currentFactor
end

---Returns current indoor sound factor
---@return number factor
function InteractiveController:getIndoorSoundFactor()
    return self.soundModifier.currentFactor
end
