------------------------------------------------------------------------------------------------------------------------
-- InteractiveControlManager
------------------------------------------------------------------------------------------------------------------------
-- Purpose: Manager for interactive control
--
---@author John Deere 6930 @VertexDezign
------------------------------------------------------------------------------------------------------------------------

---@class InteractiveControlManager
---@field public mission BaseMission
---@field public inputBinding InputBinding
---@field public injectionManager XMLInjectionsManager
---@field public settings AdditionalSettingsManager
InteractiveControlManager = {}

local interactiveControlManager_mt = Class(InteractiveControlManager)

InteractiveControlManager.SETTING_STATE_TOGGLE = 1
InteractiveControlManager.SETTING_STATE_ALWAYS_ON = 2
InteractiveControlManager.SETTING_STATE_OFF = 3

InteractiveControlManager.SETTING_HOVER_OFF = 1
InteractiveControlManager.SETTING_HOVER_1 = 2
InteractiveControlManager.SETTING_HOVER_2 = 3
InteractiveControlManager.SETTING_HOVER_3 = 4
InteractiveControlManager.SETTING_HOVER_4 = 5
InteractiveControlManager.SETTING_HOVER_5 = 6

InteractiveControlManager.SETTING_HOVER_TIME = {
    [InteractiveControlManager.SETTING_HOVER_1] = 0.5,
    [InteractiveControlManager.SETTING_HOVER_2] = 1,
    [InteractiveControlManager.SETTING_HOVER_3] = 2,
    [InteractiveControlManager.SETTING_HOVER_4] = 3,
    [InteractiveControlManager.SETTING_HOVER_5] = 5,
}

---Create new instance of InteractiveControlManager
function InteractiveControlManager.new(mission, inputBinding, i18n, modName, modDirectory, customMt)
    local self = setmetatable({}, customMt or interactiveControlManager_mt)

    self:mergeModTranslations(i18n)

    self.modName = modName
    self.modDirectory = modDirectory

    self.isServer = mission:getIsServer()
    self.isClient = mission:getIsClient()

    self.mission = mission
    self.inputBinding = inputBinding

    self.activeController = nil
    self.actionEventId = nil
    self.playerInRange = false

    -- XMLInjectionsManager
    self.injectionManager = XMLInjectionsManager.new(modName, modDirectory)
    self.injectionManager:load("data/basegameInjections/injectionFiles.xml")

    -- AdditionalSettingsManager
    local title = i18n:getText("settingsIC_title", self.customEnvironment)
    self.settings = AdditionalSettingsManager.new(title, self, modName, modDirectory)

    -- State setting
    local options = {
        i18n:getText("settingsIC_state_option01", self.customEnvironment),
        i18n:getText("settingsIC_state_option02", self.customEnvironment),
        i18n:getText("settingsIC_state_option03", self.customEnvironment),
    }

    title = i18n:getText("settingsIC_state_title", self.customEnvironment)
    local tooltip = i18n:getText("settingsIC_state_tooltip", self.customEnvironment)
    self.settings:addSetting("IC_STATE", AdditionalSettingsManager.TYPE_MULTIBOX, title, tooltip, InteractiveControlManager.SETTING_STATE_TOGGLE, options)

    -- KeepAlive setting
    title = i18n:getText("settingsIC_keepAlive_title", self.customEnvironment)
    tooltip = i18n:getText("settingsIC_keepAlive_tooltip", self.customEnvironment)
    self.settings:addSetting("IC_KEEP_ALIVE", AdditionalSettingsManager.TYPE_BINARY, title, tooltip, false)

    -- ClickPointHover setting, no loop to avoid unordered list
    options = {
        i18n:getText("settingsIC_clickPointHover_optionTimeOff", self.customEnvironment),
        i18n:getText("settingsIC_clickPointHover_optionTime", self.customEnvironment):format(InteractiveControlManager.SETTING_HOVER_TIME[InteractiveControlManager.SETTING_HOVER_1]),
        i18n:getText("settingsIC_clickPointHover_optionTime", self.customEnvironment):format(InteractiveControlManager.SETTING_HOVER_TIME[InteractiveControlManager.SETTING_HOVER_2]),
        i18n:getText("settingsIC_clickPointHover_optionTime", self.customEnvironment):format(InteractiveControlManager.SETTING_HOVER_TIME[InteractiveControlManager.SETTING_HOVER_3]),
        i18n:getText("settingsIC_clickPointHover_optionTime", self.customEnvironment):format(InteractiveControlManager.SETTING_HOVER_TIME[InteractiveControlManager.SETTING_HOVER_4]),
        i18n:getText("settingsIC_clickPointHover_optionTime", self.customEnvironment):format(InteractiveControlManager.SETTING_HOVER_TIME[InteractiveControlManager.SETTING_HOVER_5]),
    }

    title = i18n:getText("settingsIC_clickPointHover_title", self.customEnvironment)
    tooltip = i18n:getText("settingsIC_clickPointHover_tooltip", self.customEnvironment)
    self.settings:addSetting("IC_CLICK_POINT_HOVER", AdditionalSettingsManager.TYPE_MULTIBOX, title, tooltip, InteractiveControlManager.SETTING_HOVER_OFF, options)

    return self
end

---Called on delete
function InteractiveControlManager:delete()
    if self.mission ~= nil and self.mission.messageCenter ~= nil then
        self.mission.messageCenter:unsubscribeAll(self)
    end

    self.injectionManager:delete()
end

---Returns active interactive controller
---@return InteractiveController|nil
function InteractiveControlManager:getActiveInteractiveController()
    return self.activeController
end

---Returns true if manager has active control, false otherwise
---@return boolean hasActiveController
function InteractiveControlManager:isInteractiveControlActivated()
    if g_localPlayer == nil then
        return false
    end

    local controlledVehicle = g_localPlayer:getCurrentVehicle()
    if controlledVehicle ~= nil and controlledVehicle.isInteractiveControlActivated ~= nil then
        return controlledVehicle:isInteractiveControlActivated()
    end

    return self.playerInRange
end

---Sets active interactiveController
---@param activeController InteractiveController
function InteractiveControlManager:setActiveInteractiveController(activeController)
    if activeController == self.activeController then
        return
    end

    self:unregisterActionEvents()

    if activeController ~= nil then
        local inputButton = activeController:getActionInputButton()
        local isAnalog = activeController:isAnalog()

        self:registerActionEvents(inputButton, isAnalog)
    end

    self.activeController = self.actionEventId == nil and nil or activeController
end

---Sets player in range state
---@param playerInRange boolean Player is in range
function InteractiveControlManager:setPlayerInRange(playerInRange)
    if playerInRange ~= self.playerInRange then
        self.playerInRange = playerInRange
    end
end

----------------------------------------------------- Action Events ----------------------------------------------------

---Register action events
---@param inputButton InputAction Action input button
---@param isAnalog boolean Is action analog
function InteractiveControlManager:registerActionEvents(inputButton, isAnalog)
    inputButton = Utils.getNoNil(inputButton, InputAction.IC_CLICK)
    isAnalog = Utils.getNoNil(isAnalog, false)

    local _, actionEventId = self.inputBinding:registerActionEvent(inputButton, self, self.onActionEventExecute, false, true, isAnalog, true, nil, true)
    self.inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_VERY_HIGH)
    self.inputBinding:setActionEventTextVisibility(actionEventId, false)
    self.inputBinding:setActionEventActive(actionEventId, false)

    self.actionEventId = actionEventId
end

---Unregister action events
function InteractiveControlManager:unregisterActionEvents()
    self.inputBinding:removeActionEvent(self.actionEventId)
end

---Sets interactive action event text and state
---@param text string Action text
---@param active boolean Action is active
function InteractiveControlManager:setActionText(text, active)
    if self.actionEventId == nil then
        return
    end

    self.inputBinding:setActionEventText(self.actionEventId, text)
    self.inputBinding:setActionEventTextVisibility(self.actionEventId, active and text ~= "")
    self.inputBinding:setActionEventActive(self.actionEventId, active and text ~= "")
end

---Action Event: Execute interactiveController
function InteractiveControlManager:onActionEventExecute()
    if self.activeController == nil then
        return
    end

    self.activeController:execute()
end

-------------------------------------------------- Overwrite Callbacks -------------------------------------------------

---Returns modifier factor
---@param soundManager SoundManager instance of SoundManager
---@param superFunc function original function
---@param sample table sound sample
---@param modifierName string modifier string
---@return number volume
function InteractiveControlManager:getModifierFactor(soundManager, superFunc, sample, modifierName)
    local controlledVehicle = nil
    if g_localPlayer ~= nil then
        controlledVehicle = g_localPlayer:getCurrentVehicle()
    end

    if modifierName == "volume" and controlledVehicle ~= nil then
        local volume = superFunc(soundManager, sample, modifierName)

        if controlledVehicle.getIndoorModifiedSoundFactor ~= nil then
            volume = volume * controlledVehicle:getIndoorModifiedSoundFactor()
        end

        return volume
    else
        return superFunc(soundManager, sample, modifierName)
    end
end

-------------------------------------------------------- Various -------------------------------------------------------

---Installs InteractiveControl specialization into required vehicles
function InteractiveControlManager.installSpecializations(vehicleTypeManager, specializationManager, modDirectory, modName)
    local specFilename = Utils.getFilename("src/vehicles/specializations/InteractiveControl.lua", modDirectory)
    specializationManager:addSpecialization("interactiveControl", "InteractiveControl", specFilename, nil)

    ---Returns true if InteractiveControl insertion is forced, false otherwise
    ---@param specializations table Vehicle type specializations
    ---@return boolean forcedInsertion
    local function getInteractiveControlForced(specializations)
        for _, spec in ipairs(specializations) do
            if spec.ADD_INTERACTIVE_CONTROL then
                return true
            end
        end

        return false
    end

    for typeName, typeEntry in pairs(vehicleTypeManager:getTypes()) do
        local add = SpecializationUtil.hasSpecialization(Enterable, typeEntry.specializations)
            or SpecializationUtil.hasSpecialization(Attachable, typeEntry.specializations)

        if not add then
            add = getInteractiveControlForced(typeEntry.specializations)
        end

        if add then
            vehicleTypeManager:addSpecialization(typeName, modName .. ".interactiveControl")
        end
    end
end

---Merge local internationalization texts into global internationalization
---@param i18n I18N Instance of I18N
function InteractiveControlManager:mergeModTranslations(i18n)
    -- Thanks for blocking the getfenv Giants..
    local modEnvMeta = getmetatable(_G)
    local env = modEnvMeta.__index

    local global = env.g_i18n.texts
    for key, text in pairs(i18n.texts) do
        global[key] = text
    end
end

---Returns clickPoint hover time
---@return number hoverTime ClickPoint hover time
function InteractiveControlManager:getHoverTime()
    local clickPointHover = self.settings:getSetting("IC_CLICK_POINT_HOVER")

    if clickPointHover == InteractiveControlManager.SETTING_HOVER_OFF then
        return 0.0
    end

    return InteractiveControlManager.SETTING_HOVER_TIME[clickPointHover]
end

----------------
---Overwrites---
----------------

---Overwrite FS25_additionalGameSettings functions
function InteractiveControlManager.overwrite_additionalGameSettings()
    if not g_modIsLoaded["FS25_additionalGameSettings"] then
        return
    end

    if FS25_additionalGameSettings == nil or FS25_additionalGameSettings.CrosshairSetting == nil then
        return
    end

    ---Overwritten function: FS25_additionalGameSettings.CrosshairSetting.overwriteDefault
    ---Injects the InteractiveControl is active state for crosshair rendering
    ---@param setting CrosshairSetting AdditionalGameSettings
    ---@param superFunc function original function
    ---@param crosshair GuiElement Overlay
    ---@param func function
    local function inject_overwriteDefault(crosshairSetting, superFunc, crosshair, func)
        log("inject_overwriteDefault")

        if g_currentMission.interactiveControl == nil then
            return superFunc(crosshairSetting, crosshair, func)
        end

        local render = crosshair.render
        crosshair.render = function(...)
            if g_currentMission.interactiveControl:isInteractiveControlActivated() or crosshairSetting.state == 0 and (func == nil or func()) then
                render(...)
            end
        end
    end

    local crosshairSetting = FS25_additionalGameSettings.CrosshairSetting
    crosshairSetting.overwriteDefault = Utils.overwrittenFunction(crosshairSetting.overwriteDefault, inject_overwriteDefault)
end
