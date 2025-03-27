------------------------------------------------------------------------------------------------------------------------
-- InteractiveAction
------------------------------------------------------------------------------------------------------------------------
-- Purpose: Base functionality of interactive action, that can trigger interactive controls
--
---@author John Deere 6930 @VertexDezign
------------------------------------------------------------------------------------------------------------------------

---@class InteractiveAction: InteractiveBase
InteractiveAction = {}

local interactiveAction_mt = Class(InteractiveAction, InteractiveBase)

---Register XMLPaths to XMLSchema
---@param schema XMLSchema Instance of XMLSchema to register path to
---@param basePath string Base path for path registrations
---@param controllerPath string Controller path for path registrations
function InteractiveAction.registerXMLPaths(schema, basePath, controllerPath)
    InteractiveAction:superClass().registerXMLPaths(schema, basePath, controllerPath)

    schema:register(XMLValueType.STRING, basePath .. "#type", "Types of interactive object", "UNKNOWN", true)
    schema:register(XMLValueType.FLOAT, basePath .. "#direction", "Direction of analog action", 1)

    schema:register(XMLValueType.FLOAT, basePath .. "#forcedStateValue", "Forced state value to set by action")

    schema:register(XMLValueType.FLOAT, basePath .. "#foldMinLimit", "Folding time min. limit", 0.0)
    schema:register(XMLValueType.FLOAT, basePath .. "#foldMaxLimit", "Folding time max. limit", 1.0)

    schema:register(XMLValueType.STRING, basePath .. "#animName", "Animation name")
    schema:register(XMLValueType.FLOAT, basePath .. "#animMinLimit", "Animation time (rel) min. limit", 0.0)
    schema:register(XMLValueType.FLOAT, basePath .. "#animMaxLimit", "Animation time (rel) max. limit", 1.0)
end

---@type table<string, InteractiveAction> Actor classes by name
InteractiveAction.TYPE_BY_NAMES = {}

---Registers new interactive action
---@param name string action name
---@param class InteractiveAction Action class
function InteractiveAction.registerInteractiveAction(name, class)
    if InteractiveAction.TYPE_BY_NAMES[name] ~= nil then
        Logging.error("Error: InteractiveAction '%s' already exists!", name)
        return
    end

    InteractiveAction.TYPE_BY_NAMES[name] = class
end

---@enum InteractiveAction.ACTION_TYPES Interactive action types
InteractiveAction.ACTION_TYPES = {
    UNKNOWN = 0,
    INDOOR = 1,
    OUTDOOR = 2,
    INDOOR_OUTDOOR = 3,
}

---Creates new instance of InteractiveAction
---@param modName string mod name
---@param modDirectory string mod directory
---@param customMt? metatable custom metatable
---@return InteractiveAction
function InteractiveAction.new(modName, modDirectory, customMt)
    local self = InteractiveAction:superClass().new(modName, modDirectory, customMt or interactiveAction_mt)

    self.activated = false

    return self
end

---Loads InteractiveAction data from xmlFile, returns true if loading was successful, false otherwise
---@param xmlFile XMLFile Instance of XMLFile
---@param key string XML key to load from
---@param target any Target vehicle or placeable
---@param interactiveController InteractiveController Instance of InteractiveController
---@return boolean loaded True if loading succeeded, false otherwise
function InteractiveAction:loadFromXML(xmlFile, key, target, interactiveController)
    if not InteractiveAction:superClass().loadFromXML(self, xmlFile, key, target, interactiveController) then
        return false
    end

    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, key .. "#forcedState", key .. "#forcedStateValue") -- FS22 to FS25

    local typeName = xmlFile:getValue(key .. "#type")
    typeName = typeName:upper()

    ---@type InteractiveAction.ACTION_TYPES
    local type = InteractiveAction.ACTION_TYPES[typeName]

    if type == nil then
        Logging.xmlWarning(xmlFile, "Unable to find type '%s' for interactive action '%s'", typeName, key)
        return false
    end

    if type == InteractiveAction.ACTION_TYPES.UNKNOWN then
        Logging.xmlWarning(xmlFile, "Type is UNKNOWN for interactive action '%s'", typeName, key)
        return false
    end

    self.type = type

    self.direction = xmlFile:getValue(key .. "#direction", 1)
    self.forcedStateValue = xmlFile:getValue(key .. "#forcedStateValue")

    self.foldMinLimit = xmlFile:getValue(key .. "#foldMinLimit", 0.0)
    self.foldMaxLimit = xmlFile:getValue(key .. "#foldMaxLimit", 1.0)

    self.animName = xmlFile:getValue(key .. "#animName")
    self.animMinLimit = xmlFile:getValue(key .. "#animMinLimit", 0.0)
    self.animMaxLimit = xmlFile:getValue(key .. "#animMaxLimit", 1.0)

    return true
end

---Called after load
---@param savegame any
function InteractiveAction:postLoad(savegame)
    self:setActivated(self.activated, true)
end

---Called on update
---@param isIndoor boolean True if update is indoor
---@param isOutdoor boolean True if update is outdoor
---@param hasInput boolean True if target has input
function InteractiveAction:update(isIndoor, isOutdoor, hasInput)
    local activateable = self:isActivatable()

    if activateable then
        local indoor = isIndoor and self.target:isInteractiveControlActivated() and hasInput and self:isIndoorActive()
        local outdoor = isOutdoor and not hasInput and self:isOutdoorActive()

        activateable = indoor or outdoor
    end

    if activateable ~= self:isActivated() then
        self:setActivated(activateable)
    end
end

---Sets activation state
---@param activated boolean is action activated
---@param forced? boolean Forced activation set
function InteractiveAction:setActivated(activated, forced)
    if activated ~= nil and (activated ~= self.activated or forced) then
        self.activated = activated
    end
end

---Returns true if is activated, false otherwise
---@return boolean state
function InteractiveAction:isActivated()
    return self.activated
end

---Returns true if is activateable, false otherwise
---@return boolean isActivatable
function InteractiveAction:isActivatable()
    -- check foldAnim time
    if self.target.getFoldAnimTime ~= nil then
        local time = self.target:getFoldAnimTime()

        if self.foldMaxLimit < time or time < self.foldMinLimit then
            return false
        end
    end

    -- check animation time
    if self.target.getAnimationTime ~= nil and self.animName ~= nil then
        local animTime = self.target:getAnimationTime(self.animName)

        if self.animMaxLimit < animTime or animTime < self.animMinLimit then
            return false
        end
    end

    -- check forced state
    if self.forcedStateValue ~= nil then
        local stateValue = self.interactiveController:getStateValue()

        return math.abs(stateValue - self.forcedStateValue) <= InteractiveController.STATE_VALUE_THRESHOLD
    end

    return true
end

---Returns true if is executable, false otherwise
---@return boolean isExecutable
function InteractiveAction:isExecutable()
    return self:isActivated()
end

---Returns true if is indoor active, false otherwise
---@return boolean isIndoor
function InteractiveAction:isIndoorActive()
    return self.type == InteractiveAction.ACTION_TYPES.INDOOR or self.type == InteractiveAction.ACTION_TYPES.INDOOR_OUTDOOR
end

---Returns true if is outdoor active, false otherwise
---@return boolean isOutdoor
function InteractiveAction:isOutdoorActive()
    return self.type == InteractiveAction.ACTION_TYPES.OUTDOOR or self.type == InteractiveAction.ACTION_TYPES.INDOOR_OUTDOOR
end
