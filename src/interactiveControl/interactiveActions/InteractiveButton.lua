------------------------------------------------------------------------------------------------------------------------
-- InteractiveButton
------------------------------------------------------------------------------------------------------------------------
-- Purpose: Interactive action class for button functionality.
--
---@author John Deere 6930 @VertexDezign
------------------------------------------------------------------------------------------------------------------------

---@class InteractiveButton: InteractiveAction
InteractiveButton = {}

local interactiveButton_mt = Class(InteractiveButton, InteractiveAction)

-- Set input types and key name to "button".
InteractiveButton.INPUT_TYPES = { InteractiveController.INPUT_TYPES.VEHICLE, InteractiveController.INPUT_TYPES.PLACEABLE }
InteractiveButton.KEY_NAME = "button"

---Register BUTTON interactive action
InteractiveAction.registerInteractiveAction("BUTTON", InteractiveButton)

---Register XMLPaths to XMLSchema
---@param schema XMLSchema Instance of XMLSchema to register path to
---@param basePath string Base path for path registrations
---@param controllerPath string Controller path for path registrations
function InteractiveButton.registerXMLPaths(schema, basePath, controllerPath)
    InteractiveButton:superClass().registerXMLPaths(schema, basePath, controllerPath)

    schema:register(XMLValueType.STRING, basePath .. "#input", "Name of button", nil, true)
    schema:register(XMLValueType.FLOAT, basePath .. "#range", "Range of button", 5.0)
    schema:register(XMLValueType.NODE_INDEX, basePath .. "#refNode", "Reference node used to calculate the range. Default: rootNode.")
end

---Create new instance of InteractiveButton
function InteractiveButton.new(modName, modDirectory, customMt)
    local self = InteractiveButton:superClass().new(modName, modDirectory, customMt or interactiveButton_mt)

    self.inputButton = nil
    self.range = 0.0

    self.currentUpdateDistance = math.huge

    return self
end

---Loads InteractiveButton data from xmlFile, returns true if loading was successful, false otherwise
---@param xmlFile XMLFile Instance of XMLFile
---@param key string XML key to load from
---@param target any Target vehicle or placeable
---@param interactiveController InteractiveController interactive object table
---@return boolean loaded True if loading succeeded, false otherwise
function InteractiveButton:loadFromXML(xmlFile, key, target, interactiveController)
    if not InteractiveButton:superClass().loadFromXML(self, xmlFile, key, target, interactiveController) then
        return false
    end

    local inputButtonStr = xmlFile:getValue(key .. "#input")
    if inputButtonStr ~= nil then
        self.inputButton = InputAction[inputButtonStr]
    end

    if self.inputButton == nil then
        Logging.xmlError(xmlFile, "Unknown interactive button '%s' in '%s'", inputButtonStr, key)
        return false
    end

    self.range = xmlFile:getValue(key .. "#range", 5.0)
    self.refNode = xmlFile:getValue(key .. "#refNode", nil, target.components, target.i3dMappings)

    return true
end

---Called on update
---@param isIndoor boolean True if update is indoor
---@param isOutdoor boolean True if update is outdoor
---@param hasInput boolean True if target has input
function InteractiveButton:update(isIndoor, isOutdoor, hasInput)
    InteractiveButton:superClass().update(self, isIndoor, isOutdoor, hasInput)

    if not self:isActivated() then
        return
    end

    if self.refNode ~= nil then
        self.currentUpdateDistance = calcDistanceFrom(self.refNode, getCamera())
    else
        self.currentUpdateDistance = self.target.currentUpdateDistance
    end
end

---Returns true if button is in interaction range, false otherwise
---@return boolean isInRange
function InteractiveButton:isInRange()
    return self.currentUpdateDistance < self.range
end

---Returns true if is executable
---@return boolean executable is executable
function InteractiveButton:isExecutable()
    return InteractiveButton:superClass().isExecutable(self) and self:isInRange()
end
