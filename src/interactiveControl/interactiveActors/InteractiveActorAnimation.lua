------------------------------------------------------------------------------------------------------------------------
-- InteractiveActorAnimation
------------------------------------------------------------------------------------------------------------------------
-- Purpose: Interactive actor class for vehicle animation functionality.
--
---@author John Deere 6930 @VertexDezign
------------------------------------------------------------------------------------------------------------------------

---@class InteractiveActorAnimation: InteractiveActor
InteractiveActorAnimation = {}

local interactiveActorAnimation_mt = Class(InteractiveActorAnimation, InteractiveActor)

-- Set input types to vehicle and key name to "animation". This one is specific for animations in vehicles
InteractiveActorAnimation.INPUT_TYPES = { InteractiveController.INPUT_TYPES.VEHICLE }
InteractiveActorAnimation.KEY_NAME = "animation"

---Register VEHICLE_ANIMATION interactive actor
InteractiveActor.registerInteractiveActor("VEHICLE_ANIMATION", InteractiveActorAnimation)

InteractiveActorAnimation.MIN_HOVER_TIMEOUT = 1500 -- ms

---Register XMLPaths to XMLSchema
---@param schema XMLSchema Instance of XMLSchema to register path to
---@param basePath string Base path for path registrations
---@param controllerPath string Controller path for path registrations
function InteractiveActorAnimation.registerXMLPaths(schema, basePath, controllerPath)
    InteractiveActorAnimation:superClass().registerXMLPaths(schema, basePath, controllerPath)

    schema:register(XMLValueType.STRING, basePath .. "#name", "Animation name")
    schema:register(XMLValueType.FLOAT, basePath .. "#speedScale", "Speed factor animation is played", 1.0)
    schema:register(XMLValueType.FLOAT, basePath .. "#initTime", "Start animation time")
end

---Creates new instance of InteractiveActorAnimation
---@param modName string mod name
---@param modDirectory string mod directory
---@param customMt? metatable custom metatable
---@return InteractiveActorAnimation
function InteractiveActorAnimation.new(modName, modDirectory, customMt)
    local self = InteractiveActorAnimation:superClass().new(modName, modDirectory, customMt or interactiveActorAnimation_mt)

    return self
end

---Loads InteractiveActorAnimation data from xmlFile, returns true if loading was successful, false otherwise
---@param xmlFile XMLFile Instance of XMLFile
---@param key string XML key to load from
---@param target any Target vehicle
---@param interactiveController InteractiveController Instance of InteractiveController
---@return boolean loaded True if loading succeeded, false otherwise
function InteractiveActorAnimation:loadFromXML(xmlFile, key, target, interactiveController)
    if not InteractiveActorAnimation:superClass().loadFromXML(self, xmlFile, key, target, interactiveController) then
        return false
    end

    if self.target.playAnimation == nil then
        return false
    end

    local name = xmlFile:getValue(key .. "#name")
    if name == nil then
        Logging.xmlWarning(xmlFile, "Unable to find animation with out 'name' in target vehicle, ignoring actor animation!")

        return false
    end

    if not self.target:getAnimationExists(name) then
        Logging.xmlWarning(xmlFile, "Unable to find animation '%s' in target vehicle, ignoring actor animation!", name)

        return false
    end

    self.name = name
    self.speedScale = xmlFile:getValue(key .. "#speedScale", 1.0)
    self.initTime = xmlFile:getValue(key .. "#initTime")

    return true
end

---Called after load
---@param savegame any
function InteractiveActorAnimation:postLoad(savegame)
    InteractiveActorAnimation:superClass().postLoad(savegame)

    -- update actor animation to initial time
    if not self.interactiveController.loadedDirty and self.initTime ~= nil then
        local animTime = self.target:getAnimationTime(self.name)
        local direction = animTime > self.initTime and -1 or 1

        self.target:playAnimation(self.name, direction, animTime, true)
        self.target:setAnimationStopTime(self.name, self.initTime)
    end

    AnimatedVehicle.updateAnimationByName(self.target, self.name, 9999999, true)
end

---Updates interactive actor by stateValue
---@param stateValue number InteractiveController stateValue
---@param forced? boolean Forced update if is true
---@param noEventSend? boolean Don't send an event
function InteractiveActorAnimation:updateState(stateValue, forced, noEventSend)
    InteractiveActorAnimation:superClass().updateState(stateValue, forced, noEventSend)

    if self.interactiveController:isAnalog() then
        self.target:setAnimationTime(self.name, stateValue)
    else
        local dir = self.interactiveController:getStateBool() and 1 or -1

        self.target:playAnimation(self.name, self.speedScale * dir, self.target:getAnimationTime(self.name), true)
        self.target:setVehicleMaxUpdateTime(self.interactiveController.lastChangeTime + self.target:getAnimationDuration(self.name))
    end
end

---Returns max hover timeout
---@return number maxHoverTimeout
function InteractiveActorAnimation:maxHoverTimeout()
    local animationDuration = self.target:getAnimationDuration(self.name)
    return math.max(animationDuration, InteractiveActorAnimation.MIN_HOVER_TIMEOUT)
end
