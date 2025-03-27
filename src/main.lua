------------------------------------------------------------------------------------------------------------------------
-- Main
------------------------------------------------------------------------------------------------------------------------
-- Purpose: Main entry script for Interactive Control
--
---@author John Deere 6930 @VertexDezign
------------------------------------------------------------------------------------------------------------------------
-- Thanks goes to: Wopster, JoPi, SirJoki80 & Flowsen (for the ui elements)
-- and Face (for the initial idea) & AgrarKadabra for many contributions!
------------------------------------------------------------------------------------------------------------------------

local modDirectory = g_currentModDirectory
local modName = g_currentModName
---@type InteractiveControlManager
local modEnvironment

---load all needed lua files
local sourceFiles = {
    -- injections
    "src/misc/XMLInjectionsManager.lua",

    -- settings
    "src/misc/AdditionalSettingsManager.lua",

    "src/misc/InteractiveControlManager.lua",
    "src/misc/InteractiveFunctions.lua",
    "src/misc/InteractiveFunctions_externalMods.lua",

    -- interactiveControl
    "src/interactiveControl/InteractiveController.lua",
    "src/interactiveControl/InteractiveBase.lua",

    "src/interactiveControl/interactiveActions/InteractiveAction.lua",
    "src/interactiveControl/interactiveActions/InteractiveClickPoint.lua",
    "src/interactiveControl/interactiveActions/InteractiveButton.lua",

    "src/interactiveControl/interactiveActors/InteractiveActor.lua",
    "src/interactiveControl/interactiveActors/InteractiveActorAnimation.lua",
    "src/interactiveControl/interactiveActors/InteractiveActorDependingController.lua",
    "src/interactiveControl/interactiveActors/InteractiveActorFunction.lua",
    "src/interactiveControl/interactiveActors/InteractiveActorObjectChange.lua",
    -- "src/interactiveControl/interactiveActors/InteractiveActorDashboard.lua",

    -- network
    "src/events/ICStateEvent.lua",
    "src/events/ICStateValueEvent.lua",
}

for _, sourceFile in ipairs(sourceFiles) do
    source(Utils.getFilename(sourceFile, modDirectory))
end

---Returns true when the current mod env is loaded, false otherwise.
local function isLoaded()
    return modEnvironment ~= nil
end

---Load the mod.
local function load(mission)
    assert(modEnvironment == nil)
    modEnvironment = InteractiveControlManager.new(mission, g_inputBinding, g_i18n, modName, modDirectory)

    mission.interactiveControl = modEnvironment

    -- load settings
    if modEnvironment.settings ~= nil then
        AdditionalSettingsManager.loadFromXML(modEnvironment.settings)
    end
end

---Unload the mod when the mod is unselected and savegame is (re)loaded or game is closed.
local function unload()
    if not isLoaded() then
        return
    end

    if modEnvironment ~= nil then
        modEnvironment:delete()
        modEnvironment = nil

        if g_currentMission ~= nil then
            g_currentMission.interactiveControl = nil
        end
    end
end

---Injects interactiveControl installation
---@param typeManager table typeManager table
local function validateTypes(typeManager)
    if typeManager.typeName == "vehicle" then
        InteractiveControlManager.installSpecializations(typeManager, g_specializationManager, modDirectory, modName)
    end
end

---Overwritten function: SoundManager.getModifierFactor
---Injects the InteractiveControl sound modifier
---@param soundManager table soundManager table
---@param superFunc function original function
---@param sample table sample table
---@param modifierName string modifier name
---@return number modifierFactor factor of modifier
local function getModifierFactor(soundManager, superFunc, sample, modifierName)
    if isLoaded() then
        return modEnvironment:getModifierFactor(soundManager, superFunc, sample, modifierName)
    end

    return superFunc(soundManager, sample, modifierName)
end

---Overwritten function: Dashboard.defaultDashboardStateFunc
---Injects InteractiveControl dashboard overwriting
---@param vehicle Vehicle Instance of vehicle
---@param superFunc function original function
---@param dashboard table Dashboard entry
---@param newValue any
---@param minValue any
---@param maxValue any
---@param isActive any
local function defaultDashboardStateFunc(vehicle, superFunc, dashboard, newValue, minValue, maxValue, isActive)
    if vehicle.getICDashboardByIdentifier ~= nil then
        local dependingDashboard = nil

        if dashboard.node ~= nil then
            dependingDashboard = vehicle:getICDashboardByIdentifier(dashboard.node)
        end

        if dependingDashboard == nil and dashboard.numbers ~= nil then
            dependingDashboard = vehicle:getICDashboardByIdentifier(dashboard.numbers)
        end

        if dependingDashboard == nil and dashboard.animName ~= nil then
            dependingDashboard = vehicle:getICDashboardByIdentifier(dashboard.animName)
        end

        if dependingDashboard ~= nil then
            local interactiveControl = dependingDashboard.interactiveControl

            if interactiveControl.isEnabled then
                if interactiveControl.state then
                    isActive = dependingDashboard.dashboardActive

                    if dependingDashboard.dashboardValueActive ~= nil then
                        newValue = dependingDashboard.dashboardValueActive
                    end
                else
                    isActive = dependingDashboard.dashboardInactive

                    if dependingDashboard.dashboardValueInactive ~= nil then
                        newValue = dependingDashboard.dashboardValueInactive
                    end
                end
            end
        end
    end

    superFunc(vehicle, dashboard, newValue, minValue, maxValue, isActive)
end

---Appended function: InGameMenuSettingsFrame.onFrameOpen
---Adds initialization of settings gui elements
---@param settingsFrame InGameMenuSettingsFrame instance of InGameMenuSettingsFrame
---@param element GuiElement gui element
local function initGui(settingsFrame, element)
    if not isLoaded() then
        return
    end

    AdditionalSettingsManager.initGui(settingsFrame, element, modEnvironment)
end

---Appended function: InGameMenuSettingsFrame.updateGeneralSettings
---Adds updating of settings gui elements
---@param settingsFrame InGameMenuSettingsFrame instance of InGameMenuSettingsFrame
local function updateGui(settingsFrame)
    if not isLoaded() then
        return
    end

    AdditionalSettingsManager.updateGui(settingsFrame, modEnvironment)
end

---Appended function: GameSettings.saveToXMLFile
---Adds saving of additional settings
---@param xmlFile XMLFile Instance of XMLFile to save settings to
local function saveSettingsToXML(xmlFile)
    if not isLoaded() then
        return
    end

    if modEnvironment.settings ~= nil then
        AdditionalSettingsManager.saveToXMLFile(modEnvironment.settings)
    end
end

---Prepended function: XMLFile.initInheritance
---Adds xml injections to XMLFile
---@param xmlFile XMLFile Instance of XMLFile
local function preInitInheritance(xmlFile)
    if not isLoaded() or modEnvironment.injectionManager == nil then
        return
    end

    modEnvironment.injectionManager:checkParentXMLData(xmlFile)
end

---Appended function: XMLFile.initInheritance
---Adds xml injections to XMLFile
---@param xmlFile XMLFile Instance of XMLFile
local function postInitInheritance(xmlFile)
    if not isLoaded() or modEnvironment.injectionManager == nil then
        return
    end

    modEnvironment.injectionManager:injectXMLData(xmlFile)
end

---Prepended function: VehicleSystem.consoleCommandReloadVehicle
---@param vehicleSystem VehicleSystem
---@param resetVehicle boolean Reset vehicle
---@param radius number Radius to reload vehicle
local function consoleCommandReloadVehicle(vehicleSystem, resetVehicle, radius)
    if not isLoaded() or modEnvironment.injectionManager == nil then
        return
    end

    modEnvironment.injectionManager:loadInjectionXMLs()
end

---Initialize the mod
local function init()
    FSBaseMission.delete = Utils.appendedFunction(FSBaseMission.delete, unload)
    Mission00.load = Utils.prependedFunction(Mission00.load, load)

    TypeManager.validateTypes = Utils.prependedFunction(TypeManager.validateTypes, validateTypes)
    SoundManager.getModifierFactor = Utils.overwrittenFunction(SoundManager.getModifierFactor, getModifierFactor)
    Dashboard.defaultDashboardStateFunc = Utils.overwrittenFunction(Dashboard.defaultDashboardStateFunc, defaultDashboardStateFunc)

    -- XMLInjectionsManager
    XMLFile.initInheritance = Utils.prependedFunction(XMLFile.initInheritance, preInitInheritance)
    XMLFile.initInheritance = Utils.appendedFunction(XMLFile.initInheritance, postInitInheritance)
    VehicleSystem.consoleCommandReloadVehicle = Utils.prependedFunction(VehicleSystem.consoleCommandReloadVehicle, consoleCommandReloadVehicle)

    -- AdditionalSettingsManager
    local modEnvMeta = getmetatable(_G)
    local env = modEnvMeta.__index
    InGameMenuSettingsFrame = env.InGameMenuSettingsFrame

    InGameMenuSettingsFrame.onFrameOpen = Utils.appendedFunction(InGameMenuSettingsFrame.onFrameOpen, initGui)
    InGameMenuSettingsFrame.updateGeneralSettings = Utils.appendedFunction(InGameMenuSettingsFrame.updateGeneralSettings, updateGui)
    GameSettings.saveToXMLFile = Utils.appendedFunction(GameSettings.saveToXMLFile, saveSettingsToXML)
end

g_interactiveControlModName = modName

init()
