------------------------------------------------------------------------------------------------------------------------
-- InteractiveControl
------------------------------------------------------------------------------------------------------------------------
-- Purpose: Specialization for interactive control

---@author John Deere 6930 @VertexDezign
------------------------------------------------------------------------------------------------------------------------

---@class InteractiveControl : Vehicle
InteractiveControl = {}

InteractiveControl.NUM_BITS = 8
InteractiveControl.NUM_MAX_CONTROLS = 2 ^ InteractiveControl.NUM_BITS - 1

InteractiveControl.PLAYER_UPDATE_TIME_OFFSET = 1500 -- ms
InteractiveControl.SOUND_FALLBACK = 1.0

InteractiveControl.INTERACTIVE_CONTROLS_CONFIG_XML_KEY = "vehicle.interactiveControl.interactiveControlConfigurations.interactiveControlConfiguration(?)"
InteractiveControl.INTERACTIVE_CONTROL_XML_KEY = InteractiveControl.INTERACTIVE_CONTROLS_CONFIG_XML_KEY .. ".interactiveControls.interactiveControl(?)"

function InteractiveControl.prerequisitesPresent(specializations)
    return true
end

function InteractiveControl.initSpecialization()
    g_vehicleConfigurationManager:addConfigurationType("interactiveControl", g_i18n:getText("configuration_interactiveControl"), "interactiveControl", VehicleConfigurationItem)

    local schema = Vehicle.xmlSchema
    local interactiveControlPath = InteractiveControl.INTERACTIVE_CONTROL_XML_KEY
    local interactiveControlConfigPath = InteractiveControl.INTERACTIVE_CONTROLS_CONFIG_XML_KEY

    schema:setXMLSpecializationType("InteractiveControl")

    InteractiveClickPoint.registerClickIconXMLPaths(schema, "vehicle.interactiveControl.registers")
    InteractiveController.registerXMLPaths(schema, interactiveControlPath)

    local outdoorTriggerPath = InteractiveControl.INTERACTIVE_CONTROLS_CONFIG_XML_KEY .. ".interactiveControls.outdoorTrigger"
    schema:register(XMLValueType.NODE_INDEX, outdoorTriggerPath .. "#node", "Outdoor trigger node")
    schema:register(XMLValueType.NODE_INDEX, outdoorTriggerPath .. "#linkNode", "Outdoor trigger shared link node")
    schema:register(XMLValueType.STRING, outdoorTriggerPath .. "#filename", "Outdoor trigger filename")
    schema:register(XMLValueType.VECTOR_ROT, outdoorTriggerPath .. "#rotation", "Outdoor trigger rotation")
    schema:register(XMLValueType.VECTOR_TRANS, outdoorTriggerPath .. "#translation", "Outdoor trigger translation")
    schema:register(XMLValueType.FLOAT, outdoorTriggerPath .. "#width", "Outdoor trigger width", 5)
    schema:register(XMLValueType.FLOAT, outdoorTriggerPath .. "#height", "Outdoor trigger height", 3)
    schema:register(XMLValueType.FLOAT, outdoorTriggerPath .. "#length", "Outdoor trigger length", 8)

    -- register animatedVehicle interactiveControl blocked animation value
    schema:addDelayedRegistrationFunc("AnimatedVehicle:part", function(cSchema, cKey)
        cSchema:register(XMLValueType.INT, cKey .. "#interactiveControlIndex", "InteractiveControl index")
        cSchema:register(XMLValueType.BOOL, cKey .. "#interactiveControlBlocked", "Interactive control blocked state")
    end)

    schema:setXMLSpecializationType()

    -- add to vehicle savegame schema
    local schemaSavegame = Vehicle.xmlSchemaSavegame
    local savegamePath = ("vehicles.vehicle(?).%s.interactiveControl.control(?)"):format(g_interactiveControlModName)
    InteractiveController.registerSavegameXMLPaths(schemaSavegame, savegamePath)
end

function InteractiveControl.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "updateInteractiveController", InteractiveControl.updateInteractiveController)
    SpecializationUtil.registerFunction(vehicleType, "setMissionActiveController", InteractiveControl.setMissionActiveController)
    SpecializationUtil.registerFunction(vehicleType, "activateInteractiveControl", InteractiveControl.activateInteractiveControl)
    SpecializationUtil.registerFunction(vehicleType, "isInteractiveControlActivated", InteractiveControl.isInteractiveControlActivated)
    SpecializationUtil.registerFunction(vehicleType, "getInteractiveControllerByIndex", InteractiveControl.getInteractiveControllerByIndex)
    SpecializationUtil.registerFunction(vehicleType, "setInteractiveControllerStateValueByIndex", InteractiveControl.setInteractiveControllerStateValueByIndex)
    SpecializationUtil.registerFunction(vehicleType, "interactiveControlTriggerCallback", InteractiveControl.interactiveControlTriggerCallback)
    SpecializationUtil.registerFunction(vehicleType, "isOutdoorActive", InteractiveControl.isOutdoorActive)
    SpecializationUtil.registerFunction(vehicleType, "isIndoorActive", InteractiveControl.isIndoorActive)
    SpecializationUtil.registerFunction(vehicleType, "setVehicleMaxUpdateTime", InteractiveControl.setVehicleMaxUpdateTime)
    SpecializationUtil.registerFunction(vehicleType, "isVehicleMaxUpdateTimeActive", InteractiveControl.isVehicleMaxUpdateTimeActive)
    SpecializationUtil.registerFunction(vehicleType, "getIndoorModifiedSoundFactor", InteractiveControl.getIndoorModifiedSoundFactor)
    SpecializationUtil.registerFunction(vehicleType, "getMaxIndoorSoundModifier", InteractiveControl.getMaxIndoorSoundModifier)
    SpecializationUtil.registerFunction(vehicleType, "loadInteractiveTriggerFromXML", InteractiveControl.loadInteractiveTriggerFromXML)
    SpecializationUtil.registerFunction(vehicleType, "onInteractiveTriggerLoading", InteractiveControl.onInteractiveTriggerLoading)
end

function InteractiveControl.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onPreLoad", InteractiveControl)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", InteractiveControl)
    SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", InteractiveControl)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", InteractiveControl)
    SpecializationUtil.registerEventListener(vehicleType, "onReadStream", InteractiveControl)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", InteractiveControl)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", InteractiveControl)
    SpecializationUtil.registerEventListener(vehicleType, "onPostUpdate", InteractiveControl)
    SpecializationUtil.registerEventListener(vehicleType, "onDraw", InteractiveControl)
    SpecializationUtil.registerEventListener(vehicleType, "onCameraChanged", InteractiveControl)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", InteractiveControl)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterAnimationValueTypes", InteractiveControl)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdateAnimation", InteractiveControl)
end

function InteractiveControl.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsActive", InteractiveControl.getIsActive)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsMovingToolActive", InteractiveControl.getIsMovingToolActive)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsMovingPartActive", InteractiveControl.getIsMovingPartActive)
end

---Called before load
---@param savegame table savegame
function InteractiveControl:onPreLoad(savegame)
    local name = "spec_interactiveControl"

    if self[name] ~= nil then
        Logging.xmlError(self.xmlFile, "The vehicle specialization '%s' could not be added because variable '%s' already exists!", InteractiveControl.MOD_NAME, name)
        self:setLoadingState(VehicleLoadingUtil.VEHICLE_LOAD_ERROR)
    end

    local env = {}
    setmetatable(env, {
        __index = self
    })

    env.actionEvents = {}
    self[name] = env

    self.spec_interactiveControl = self["spec_interactiveControl"]
end

---Called on load
---@param savegame table savegame
function InteractiveControl:onLoad(savegame)
    local spec = self.spec_interactiveControl

    InteractiveClickPoint.loadClickIconTypeFromXML(self.xmlFile, "vehicle.interactiveControl.registers", self.customEnvironment)

    local interactiveControlConfigurationId = Utils.getNoNil(self.configurations.interactiveControl, 1)
    local baseKey = string.format("vehicle.interactiveControl.interactiveControlConfigurations.interactiveControlConfiguration(%d).interactiveControls", interactiveControlConfigurationId - 1)

    ObjectChangeUtil.updateObjectChanges(self.xmlFile, "vehicle.interactiveControl.interactiveControlConfigurations.interactiveControlConfiguration", interactiveControlConfigurationId, self.components, self)

    spec.state = false

    spec.interactiveControllers = {}
    -- spec.interactiveControlDependingDashboards = {}

    self.xmlFile:iterate(baseKey .. ".interactiveControl", function(_, interactiveControlKey)
        local interactiveController = InteractiveController.new(g_currentMission.interactiveControl.modName, g_currentMission.interactiveControl.modDirectory)

        if interactiveController:loadFromXML(self.xmlFile, interactiveControlKey, self, #spec.interactiveControllers + 1)
            and interactiveController.index <= InteractiveControl.NUM_MAX_CONTROLS then
            table.insert(spec.interactiveControllers, interactiveController)

            -- for _, dependingDashboard in ipairs(interactiveController.dependingDashboards) do
            --     spec.interactiveControlDependingDashboards[dependingDashboard.identifier] = dependingDashboard
            -- end
        else
            interactiveController:delete()
            Logging.xmlWarning(self.xmlFile, "Could not load InteractiveController for '%s'", interactiveControlKey)
        end
    end)

    spec.interactiveTrigger = {}
    self:loadInteractiveTriggerFromXML(self.xmlFile, baseKey .. ".outdoorTrigger")
    spec.isPlayerInRange = false

    spec.maxUpdateTime = 0

    spec.indoorSoundModifierFactor = InteractiveControl.SOUND_FALLBACK
    spec.pendingSoundControls = {}
end

---Called after load
---@param savegame table savegame
function InteractiveControl:onPostLoad(savegame)
    local spec = self.spec_interactiveControl

    if table.getn(spec.interactiveControllers) == 0 then
        SpecializationUtil.removeEventListener(self, "onReadStream", InteractiveControl)
        SpecializationUtil.removeEventListener(self, "onWriteStream", InteractiveControl)
        SpecializationUtil.removeEventListener(self, "onUpdateTick", InteractiveControl)
        SpecializationUtil.removeEventListener(self, "onPostUpdate", InteractiveControl)
        SpecializationUtil.removeEventListener(self, "onDraw", InteractiveControl)
        SpecializationUtil.removeEventListener(self, "onRegisterActionEvents", InteractiveControl)
        SpecializationUtil.removeEventListener(self, "onUpdateAnimation", InteractiveControl)

        return
    end

    -- load interactive control from xml
    if savegame ~= nil then
        local iterationKey = ("%s.%s.interactiveControl.control"):format(savegame.key, g_interactiveControlModName)

        savegame.xmlFile:iterate(iterationKey, function(_, interactiveControllerSavegameKey)
            local index = savegame.xmlFile:getValue(interactiveControllerSavegameKey .. "#index")

            if index ~= nil then
                local interactiveController = self:getInteractiveControllerByIndex(index)

                if interactiveController ~= nil then
                    if interactiveController.allowsSaving then
                        interactiveController:loadFromSavegame(savegame, interactiveControllerSavegameKey)
                    else
                        Logging.xmlWarning(self.xmlFile, "Loaded interactive control does not allow saving '%s', skipping this control", interactiveControllerSavegameKey)
                    end
                else
                    Logging.xmlWarning(self.xmlFile, "Could not find interactive control for '%s', index may be invalid, skipping this control", interactiveControllerSavegameKey)
                end
            end
        end)
    end

    for _, interactiveController in pairs(spec.interactiveControllers) do
        interactiveController:postLoad(savegame)
    end

    spec.indoorSoundModifierFactor = self:getMaxIndoorSoundModifier()
end

---Saves interactive controls state to savegame
---@param xmlFile XMLFile Instance of XMLFile
---@param key string XML key to load from
---@param usedModNames boolean
function InteractiveControl:saveToXMLFile(xmlFile, key, usedModNames)
    local spec = self.spec_interactiveControl
    local i = 0

    for _, interactiveController in pairs(spec.interactiveControllers) do
        ---@cast interactiveController InteractiveController
        local interactiveControlKey = string.format("%s.control(%d)", key, i)

        if interactiveController:saveToXMLFile(xmlFile, interactiveControlKey, usedModNames) then
            i = i + 1
        end
    end
end

---Called on delete
function InteractiveControl:onDelete()
    local spec = self.spec_interactiveControl

    -- reset active controller
    self:setMissionActiveController(nil)

    if spec.interactiveControllers ~= nil then
        for _, interactiveController in pairs(spec.interactiveControllers) do
            ---@cast interactiveController InteractiveController
            interactiveController:delete()
        end
    end

    if spec.interactiveTrigger ~= nil and spec.interactiveTrigger.node ~= nil then
        removeTrigger(spec.interactiveTrigger.node)
        spec.interactiveTrigger.node = nil
    end
end

---Called on client side on join
---@param streamId number streamId
---@param connection number connection
function InteractiveControl:onReadStream(streamId, connection)
    local spec = self.spec_interactiveControl

    for _, interactiveController in pairs(spec.interactiveControllers) do
        ---@cast interactiveController InteractiveController
        interactiveController:readStream(streamId, connection)
    end
end

---Called on server side on join
---@param streamId number stream id
---@param connection number connection id
function InteractiveControl:onWriteStream(streamId, connection)
    local spec = self.spec_interactiveControl

    for _, interactiveController in pairs(spec.interactiveControllers) do
        ---@cast interactiveController InteractiveController
        interactiveController:writeStream(streamId, connection)
    end
end

---Called on update tick
---@param dt number time since last call in ms
---@param isActiveForInput boolean true if vehicle is active for input
---@param isActiveForInputIgnoreSelection boolean true if vehicle is active for input, ignore the selection
---@param isSelected boolean true if vehicle is selected
function InteractiveControl:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
    if not self.isClient then
        return
    end

    local spec = self.spec_interactiveControl
    local isIndoor = self:isIndoorActive()
    local isOutdoor = self:isOutdoorActive()

    --prefer indoor actions
    if isOutdoor and isIndoor then
        spec.isPlayerInRange = false
        g_currentMission.interactiveControl:setPlayerInRange(false)
    end

    if isOutdoor then
        self:updateInteractiveController(isIndoor, isOutdoor, isActiveForInputIgnoreSelection)
    elseif g_noHudModeEnabled and isIndoor or isOutdoor then
        self:updateInteractiveController(isIndoor, isOutdoor, isActiveForInputIgnoreSelection)
    elseif not isOutdoor and not isIndoor or not self:isInteractiveControlActivated() then
        self:updateInteractiveController(false, false, isActiveForInputIgnoreSelection)
    end
end

---Called on draw
---@param isActiveForInput boolean true if vehicle is active for input
---@param isActiveForInputIgnoreSelection boolean true if vehicle is active for input, ignore the selection
---@param isSelected boolean true if vehicle is selected
function InteractiveControl:onDraw(isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
    if not self.isClient then
        return
    end

    if not self:isInteractiveControlActivated() or not self:isIndoorActive() then
        return
    end

    if isActiveForInputIgnoreSelection and g_localPlayer ~= nil and g_localPlayer.currentHandTool ~= nil and g_localPlayer.currentHandTool.spec_hands ~= nil then
        g_localPlayer.currentHandTool.spec_hands.crosshair:render()
    end

    self:updateInteractiveController(true, false, isActiveForInputIgnoreSelection)
end

---Called after update
---@param dt number time since last call in ms
---@param isActiveForInput boolean true if vehicle is active for input
---@param isActiveForInputIgnoreSelection boolean true if vehicle is active for input, ignore the selection
---@param isSelected boolean true if vehicle is selected
function InteractiveControl:onPostUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
    -- raise active if is outdoor active
    if self:isOutdoorActive() then
        self:raiseActive()
    end
end

---Called on camera changed
---@param activeCamera table
---@param cameraIndex integer
function InteractiveControl:onCameraChanged(activeCamera, cameraIndex)
    local spec = self.spec_interactiveControl
    local keepAlive = g_currentMission.interactiveControl.settings:getSetting("IC_KEEP_ALIVE")

    if activeCamera.isInside and not keepAlive then
        self:activateInteractiveControl(false)
    end

    if spec.toggleStateEventId ~= nil then
        g_inputBinding:setActionEventActive(spec.toggleStateEventId, activeCamera.isInside)
    end
end

---Updates all interactive controls inputs
---@param isIndoor boolean True if update is indoor
---@param isOutdoor boolean True if update is outdoor
---@param hasInput boolean True if target has input
function InteractiveControl:updateInteractiveController(isIndoor, isOutdoor, hasInput)
    local spec = self.spec_interactiveControl

    ---@type InteractiveController
    local activeController

    for _, interactiveController in pairs(spec.interactiveControllers) do
        ---@cast interactiveController InteractiveController
        interactiveController:update(isIndoor, isOutdoor, hasInput)

        local activeAction = interactiveController:updateActiveAction()
        if activeAction ~= nil then
            activeController = interactiveController
        end
    end

    self:setMissionActiveController(activeController)
end

---Sets current mission interactive controller
---@param activeController? InteractiveController
function InteractiveControl:setMissionActiveController(activeController)
    if not self.isClient then
        return
    end

    ---@type InteractiveController
    local missionActiveController = g_currentMission.interactiveControl:getActiveInteractiveController()

    if activeController ~= nil then
        if missionActiveController == nil or (missionActiveController.target == self and missionActiveController ~= activeController) then
            --set active controller to mission controller
            g_currentMission.interactiveControl:setActiveInteractiveController(activeController)

            local actionText = activeController:getActionText()
            g_currentMission.interactiveControl:setActionText(actionText, true)
        end
    else
        if missionActiveController ~= nil then
            if missionActiveController.target == self then
                --reset mission controller
                g_currentMission.interactiveControl:setActiveInteractiveController(nil)
            end
        end
    end
end

---Sets IC active state
---@param state boolean
---@param noEventSend boolean
function InteractiveControl:activateInteractiveControl(state, noEventSend)
    local spec = self.spec_interactiveControl

    if state ~= nil and state ~= spec.state then
        ICStateEvent.sendEvent(self, state, noEventSend)

        spec.state = state

        local text = state and "action_deactivateIC" or "action_activateIC"
        if spec.toggleStateEventId ~= nil then
            g_inputBinding:setActionEventText(spec.toggleStateEventId, g_i18n:getText(text))
        end

        if not state then
            -- reset active controller
            self:setMissionActiveController(nil)
        end
    end
end

---Returns true if is active, false otherwise
---@return boolean state
function InteractiveControl:isInteractiveControlActivated()
    local spec = self.spec_interactiveControl

    local settingState = g_currentMission.interactiveControl.settings:getSetting("IC_STATE")
    if settingState == InteractiveControlManager.SETTING_STATE_OFF then
        return false
    elseif settingState == InteractiveControlManager.SETTING_STATE_ALWAYS_ON then
        return true
    end

    return spec.state
end

---Returns interactiveController by index
---@param index number number of interactiveControl
---@return InteractiveController interactiveController
function InteractiveControl:getInteractiveControllerByIndex(index)
    local spec = self.spec_interactiveControl

    if index == nil or spec.interactiveControllers[index] == nil then
        return nil
    end

    return spec.interactiveControllers[index]
end

---Sets interactiveController stateValue by index
---@param index number number of interactiveControl
---@param stateValue number|boolean State value to set
---@param updateStates? boolean Update states at actors and actions
---@param forced? boolean Forced state value set
---@param noEventSend? boolean Don't send an event
function InteractiveControl:setInteractiveControllerStateValueByIndex(index, stateValue, updateStates, forced, noEventSend)
    local interactiveController = self:getInteractiveControllerByIndex(index)
    if interactiveController == nil then
        return
    end

    interactiveController:setStateValue(stateValue, updateStates, forced, noEventSend)
end

---Called by entering trigger node
---@param triggerId integer
---@param otherId integer
---@param onEnter boolean
---@param onLeave boolean
---@param onStay boolean
function InteractiveControl:interactiveControlTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
    local spec = self.spec_interactiveControl

    local settingState = g_currentMission.interactiveControl.settings:getSetting("IC_STATE")
    if settingState == InteractiveControlManager.SETTING_STATE_OFF then
        spec.isPlayerInRange = false
        return
    end

    local currentFarmId = g_currentMission:getFarmId()
    local vehicleFarmId = self:getOwnerFarmId()
    local isFarmAllowed = currentFarmId == vehicleFarmId

    if not isFarmAllowed and currentFarmId ~= FarmManager.SPECTATOR_FARM_ID then
        local userFarm = g_farmManager:getFarmById(currentFarmId)

        if userFarm ~= nil then
            isFarmAllowed = userFarm:getIsContractingFor(vehicleFarmId)
        end
    end

    if isFarmAllowed and g_localPlayer ~= nil and otherId == g_localPlayer.rootNode then
        if onEnter then
            spec.isPlayerInRange = true
            self:raiseActive()
        else
            spec.isPlayerInRange = false
            self:setVehicleMaxUpdateTime(g_currentMission.time + InteractiveControl.PLAYER_UPDATE_TIME_OFFSET)
        end

        g_currentMission.interactiveControl:setPlayerInRange(spec.isPlayerInRange)
    end
end

---Returns true if outdoor action is valid
---@return boolean
function InteractiveControl:isOutdoorActive()
    local spec = self.spec_interactiveControl
    return spec.isPlayerInRange or false
end

---Returns true if indoor action should be activated
---@return boolean
function InteractiveControl:isIndoorActive()
    if g_soundManager:getIsIndoor() then
        return true
    end

    if self.getActiveCamera ~= nil then
        local activeCamera = self:getActiveCamera()

        if activeCamera ~= nil then
            return activeCamera.isInside and self.getIsEntered ~= nil and self:getIsEntered()
        end
    end

    return false
end

---Sets new vehicle max update time
---@param newTime number Max update time
function InteractiveControl:setVehicleMaxUpdateTime(newTime)
    local spec = self.spec_interactiveControl
    spec.maxUpdateTime = math.max(spec.maxUpdateTime, newTime)
end

---Returns true if max update time is active, false otherwise
---@return boolean isActive
function InteractiveControl:isVehicleMaxUpdateTimeActive()
    if g_currentMission == nil or g_currentMission.time == nil then
        return false
    end

    local spec = self.spec_interactiveControl
    return g_currentMission.time <= spec.maxUpdateTime
end

--------------------------------------------------------- Sound --------------------------------------------------------

---Returns current indoor modifier sound factor
---@return number indoorSoundModifier
function InteractiveControl:getIndoorModifiedSoundFactor()
    local spec = self.spec_interactiveControl

    if g_soundManager:getIsIndoor() then
        return spec.indoorSoundModifierFactor
    end

    return InteractiveControl.SOUND_FALLBACK
end

---Returns lowest indoor sound modifier of all interactiveControllers
---@return number indoorSoundModifier
function InteractiveControl:getMaxIndoorSoundModifier()
    local spec = self.spec_interactiveControl
    local indoorSoundModifier = InteractiveControl.SOUND_FALLBACK

    for _, interactiveController in pairs(spec.interactiveControllers) do
        ---@cast interactiveController InteractiveController
        local factor = interactiveController:getIndoorSoundFactor()

        if factor ~= InteractiveControl.SOUND_FALLBACK then
            indoorSoundModifier = math.max(factor, indoorSoundModifier)
        end
    end

    return indoorSoundModifier
end

---Called on animation is updated
---@param animationName string Animation name
function InteractiveControl:onUpdateAnimation(animationName)
    local spec = self.spec_interactiveControl

    for _, interactiveController in pairs(spec.interactiveControllers) do
        ---@cast interactiveController InteractiveController
        interactiveController:updateAnimation(animationName)
    end

    spec.indoorSoundModifierFactor = self:getMaxIndoorSoundModifier()
end

-------------------------------------------------- Interactive Trigger -------------------------------------------------

---Loads interactive trigger from XMLFile
---@param xmlFile XMLFile Instance of XMLFile
---@param key string XML key to load from
function InteractiveControl:loadInteractiveTriggerFromXML(xmlFile, key)
    local spec = self.spec_interactiveControl
    local triggerNode = xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)

    if triggerNode ~= nil then
        spec.interactiveTrigger.node = triggerNode
        addTrigger(spec.interactiveTrigger.node, "interactiveControlTriggerCallback", self)

        return
    end

    local linkNode = xmlFile:getValue(key .. "#linkNode", nil, self.components, self.i3dMappings)

    if linkNode == nil then
        return
    end

    local triggerFilename = xmlFile:getValue(key .. "#filename")

    if triggerFilename ~= nil and triggerFilename ~= "" then
        if triggerFilename == "SHARED_INTERACTIVE_TRIGGER" then
            triggerFilename = "data/shared/interactiveTrigger/interactiveTrigger.i3d"
        end

        local filename = Utils.getFilename(triggerFilename, g_currentMission.interactiveControl.modDirectory)

        -- load external trigger file
        if not fileExists(filename) and self.baseDirectory ~= nil then
            filename = Utils.getFilename(triggerFilename, self.baseDirectory)
        end

        local rotation = xmlFile:getValue(key .. "#rotation", nil, true)
        local translation = xmlFile:getValue(key .. "#translation", nil, true)
        local width = xmlFile:getValue(key .. "#width", 5)
        local height = xmlFile:getValue(key .. "#height", 3)
        local length = xmlFile:getValue(key .. "#length", 8)

        self:loadSubSharedI3DFile(filename, false, false, self.onInteractiveTriggerLoading, self,
            {
                linkNode = linkNode,
                rotation = rotation,
                translation = translation,
                width = width,
                height = height,
                length = length,
            }
        )
    end
end

---Called on interactive trigger i3d loading
---@param i3dNode integer integer of i3d node
---@param failedReason any
---@param args table argument table
function InteractiveControl:onInteractiveTriggerLoading(i3dNode, failedReason, args)
    if i3dNode == 0 then
        return
    end

    local node = I3DUtil.indexToObject(i3dNode, "0", nil)
    if node == nil then
        return
    end

    link(args.linkNode, node)

    if args.translation ~= nil then
        setTranslation(node, unpack(args.translation))
    else
        setTranslation(node, 0, 0, 0)
    end

    if args.rotation ~= nil then
        setRotation(node, unpack(args.rotation))
    else
        setRotation(node, 0, 0, 0)
    end

    setScale(node, args.width, args.height, args.length)
    setVisibility(node, false)

    local spec = self.spec_interactiveControl
    spec.interactiveTrigger.node = node
    addTrigger(spec.interactiveTrigger.node, "interactiveControlTriggerCallback", self)

    delete(i3dNode)
end

----------------------------------------------------- Action Events ----------------------------------------------------

---Called on register action events
---@param isActiveForInput boolean
---@param isActiveForInputIgnoreSelection boolean
function InteractiveControl:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
    if self.isClient then
        local spec = self.spec_interactiveControl

        self:clearActionEventsTable(spec.actionEvents)

        local settingState = g_currentMission.interactiveControl.settings:getSetting("IC_STATE")
        if isActiveForInputIgnoreSelection and #spec.interactiveControllers > 0 and self.spec_enterable ~= nil and settingState ~= InteractiveControlManager.SETTING_STATE_OFF then
            local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.IC_TOGGLE_STATE, self, InteractiveControl.actionEventToggleState, false, true, false, true, nil)
            g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)

            local showActionEvent = true
            local activeCamera = self.getActiveCamera ~= nil and self:getActiveCamera() or nil

            if activeCamera ~= nil then
                showActionEvent = activeCamera.isInside
            end

            g_inputBinding:setActionEventActive(actionEventId, showActionEvent)
            g_inputBinding:setActionEventText(actionEventId, g_i18n:getText("action_activateIC"))
            spec.toggleStateEventId = actionEventId
        end
    end
end

---Action Event Callback: Toggle interactive control state
function InteractiveControl:actionEventToggleState()
    self:activateInteractiveControl(not self:isInteractiveControlActivated())
end

------------------------------------------------- Animation Value Types ------------------------------------------------

---Called on register animation value types
function InteractiveControl:onRegisterAnimationValueTypes()
    self:registerAnimationValueType("interactiveControl", "interactiveControlBlocked", "", false, AnimationValueBool,
        -- load
        function(value, xmlFile, xmlKey)
            value.index = xmlFile:getValue(xmlKey .. "#interactiveControlIndex")
            if value.index == nil then
                return false
            end

            return true
        end,
        -- get
        function(value)
            ---@type InteractiveController
            local interactiveController = self:getInteractiveControllerByIndex(value.index)
            return interactiveController:isExternallyBlocked()
        end,
        -- set
        function(value, ...)
            ---@type InteractiveController
            local interactiveController = self:getInteractiveControllerByIndex(value.index)
            interactiveController:blockExternally(...)
        end
    )
end

------------------------------------------------------ Overwrites ------------------------------------------------------

---Overwritten function: getIsActive
---@param superFunc function overwritten function
---@return boolean isActive is active
function InteractiveControl:getIsActive(superFunc)
    if superFunc(self) then
        return true
    end

    return self:isOutdoorActive() or self:isVehicleMaxUpdateTimeActive()
end

---Overwritten function: getIsMovingToolActive
---@param superFunc function overwritten function
---@return boolean isActive is moving tool active
function InteractiveControl:getIsMovingToolActive(superFunc, movingTool)
    local spec = self.spec_interactiveControl

    for _, interactiveController in pairs(spec.interactiveControllers) do
        ---@cast interactiveController InteractiveController
        if interactiveController.getMovingToolIsInactive ~= nil
            and interactiveController:getMovingToolIsInactive(movingTool) then
            return false
        end
    end

    return superFunc(self, movingTool)
end

---Overwritten function: getIsMovingPartActive
---@param superFunc function overwritten function
---@return boolean isActive is moving part active
function InteractiveControl:getIsMovingPartActive(superFunc, movingPart)
    local spec = self.spec_interactiveControl

    for _, interactiveController in pairs(spec.interactiveControllers) do
        ---@cast interactiveController InteractiveController
        if interactiveController.getMovingPartIsInactive ~= nil
            and interactiveController:getMovingPartIsInactive(movingPart) then
            return false
        end
    end

    return superFunc(self, movingPart)
end
