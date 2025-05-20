------------------------------------------------------------------------------------------------------------------------
-- InteractiveClickPoint
------------------------------------------------------------------------------------------------------------------------
-- Purpose: Interactive action class for clickPoint functionality.
--
---@author John Deere 6930 @VertexDezign
------------------------------------------------------------------------------------------------------------------------

---@class InteractiveClickPoint: InteractiveAction
InteractiveClickPoint = {}

local interactiveClickPoint_mt = Class(InteractiveClickPoint, InteractiveAction)

-- Set input types and key name to "clickPoint".
InteractiveClickPoint.INPUT_TYPES = { InteractiveController.INPUT_TYPES.VEHICLE, InteractiveController.INPUT_TYPES.PLACEABLE }
InteractiveClickPoint.KEY_NAME = "clickPoint"

---Register CLICK_POINT interactive action
InteractiveAction.registerInteractiveAction("CLICK_POINT", InteractiveClickPoint)

---Register XMLPaths to XMLSchema
---@param schema XMLSchema Instance of XMLSchema to register path to
---@param basePath string Base path for path registrations
---@param controllerPath string Controller path for path registrations
function InteractiveClickPoint.registerXMLPaths(schema, basePath, controllerPath)
    InteractiveClickPoint:superClass().registerXMLPaths(schema, basePath, controllerPath)

    schema:register(XMLValueType.NODE_INDEX, basePath .. "#node", "Click point node", nil, true)
    schema:register(XMLValueType.NODE_INDEX, basePath .. "#linkNode", "Click point link node", nil, true)
    schema:register(XMLValueType.VECTOR_ROT, basePath .. "#rotation", "Click point rotation")
    schema:register(XMLValueType.VECTOR_TRANS, basePath .. "#translation", "Click point translation")
    schema:register(XMLValueType.FLOAT, basePath .. "#size", "Size of click point", 0.04)
    schema:register(XMLValueType.FLOAT, basePath .. "#blinkSpeedScale", "Speed scale of size scaling", 1)
    schema:register(XMLValueType.FLOAT, basePath .. "#scaleOffset", "Scale offset", "size / 10")

    local iconTypes = ""
    for name, _ in pairs(InteractiveClickPoint.CLICK_ICON_ID) do
        iconTypes = string.format("%s %s", iconTypes, name)
    end

    schema:register(XMLValueType.STRING, basePath .. "#iconType", ("Types of click point: %s"):format(iconTypes), "CROSS", true)
    schema:register(XMLValueType.BOOL, basePath .. "#alignToCamera", "Aligns click point to current camera", true)
    schema:register(XMLValueType.BOOL, basePath .. "#invertX", "Invert click icon on x-axis", false)
    schema:register(XMLValueType.BOOL, basePath .. "#invertZ", "Invert click icon on z-axis", false)
end

---Create new instance of InteractiveClickPoint
---@param modName string mod name
---@param modDirectory string mod directory
---@param customMt? metatable custom metatable
---@return InteractiveClickPoint
function InteractiveClickPoint.new(modName, modDirectory, customMt)
    local self = InteractiveClickPoint:superClass().new(modName, modDirectory, customMt or interactiveClickPoint_mt)

    self.screenPosX = 0
    self.screenPosY = 0
    self.size = 0

    self.clickable = false
    self.blinkSpeed = 0.0
    self.blinkSpeedScale = 1.0

    self.alignToCamera = true
    self.invertX = false
    self.invertZ = false
    self.sharedLoadRequestId = nil
    self.hoverTime = 0

    return self
end

---Loads InteractiveClickPoint data from xmlFile, returns true if loading was successful, false otherwise
---@param xmlFile XMLFile Instance of XMLFile
---@param key string XML key to load from
---@param target any Target vehicle or placeable
---@param interactiveController InteractiveController interactive object table
---@return boolean loaded True if loading succeeded, false otherwise
function InteractiveClickPoint:loadFromXML(xmlFile, key, target, interactiveController)
    if not InteractiveClickPoint:superClass().loadFromXML(self, xmlFile, key, target, interactiveController) then
        return false
    end

    self.node = xmlFile:getValue(key .. "#node", nil, target.components, target.i3dMappings)
    self.linkNode = xmlFile:getValue(key .. "#linkNode", nil, target.components, target.i3dMappings)
    if self.node == nil and self.linkNode == nil then
        Logging.xmlWarning(xmlFile, "ClickPoint needs at least a node or linkNode to be used!")
        return false
    end

    self.size = xmlFile:getValue(key .. "#size", 0.04)
    self.blinkSpeedScale = xmlFile:getValue(key .. "#blinkSpeedScale", 1) * 0.016

    local scaleOffset = xmlFile:getValue(key .. "#scaleOffset", self.size / 10)
    self.scaleMin = self.size - scaleOffset
    self.scaleMax = self.size + scaleOffset

    self.typeName = xmlFile:getValue(key .. "#iconType", "CROSS")
    local iconType = InteractiveClickPoint.CLICK_ICON_ID[self.typeName:upper()]

    if iconType == nil and self.target.customEnvironment ~= nil and self.target.customEnvironment ~= "" then
        local cIconType = ("%s.%s"):format(self.target.customEnvironment, self.typeName:upper())
        iconType = InteractiveClickPoint.CLICK_ICON_ID[cIconType]
    end

    if iconType == nil then
        Logging.xmlWarning(xmlFile, "Unable to find iconType '%s' for clickPoint '%s'", self.typeName, key)
        return false
    end

    self.alignToCamera = xmlFile:getValue(key .. "#alignToCamera", true)
    self.invertX = xmlFile:getValue(key .. "#invertX", false)
    self.invertZ = xmlFile:getValue(key .. "#invertZ", false)
    self.rotation = xmlFile:getValue(key .. "#rotation", nil, true)
    self.translation = xmlFile:getValue(key .. "#translation", nil, true)
    self.sharedLoadRequestId = self:loadIconType(iconType, target)

    return true
end

---Called on delete
function InteractiveClickPoint:delete()
    if self.sharedLoadRequestId ~= nil then
        g_i3DManager:releaseSharedI3DFile(self.sharedLoadRequestId)
        self.sharedLoadRequestId = nil
    end

    InteractiveClickPoint:superClass().delete(self)
end

---Called on update
---@param isIndoor boolean True if update is indoor
---@param isOutdoor boolean True if update is outdoor
---@param hasInput boolean True if target has input
function InteractiveClickPoint:update(isIndoor, isOutdoor, hasInput)
    InteractiveClickPoint:superClass().update(self, isIndoor, isOutdoor, hasInput)

    if not self:isActivated() then
        return
    end

    local lastMouseX, lastMouseY = g_inputBinding:getMousePosition()
    self:updateScreenPosition(lastMouseX, lastMouseY)

    local clickPointHoverTime = g_currentMission.interactiveControl:getHoverTime()
    if clickPointHoverTime <= 0 then
        return
    end

    if self:isExecutable() and not self.interactiveController:hasHoverTimeout() then
        if self.hoverTime == 0 then
            self.hoverTime = g_currentMission.time + clickPointHoverTime * 1000
        else
            if self.hoverTime < g_currentMission.time then
                self.interactiveController:execute()

                if not self.interactiveController:isAnalog() then
                    self.hoverTime = 0
                end
            end
        end
    else
        self.hoverTime = 0
    end
end

---Returns true if is active, false otherwise
---@return boolean isActivatable
function InteractiveClickPoint:isActivatable()
    -- check node visibility
    if not getVisibility(self.node) then
        return false
    end

    return InteractiveClickPoint:superClass().isActivatable(self)
end

---Sets activation state
---@param activated boolean is action activated
---@param forced? boolean Forced activation set
function InteractiveClickPoint:setActivated(activated, forced)
    InteractiveClickPoint:superClass().setActivated(self, activated, forced)

    if self.clickIconNode ~= nil then
        setVisibility(self.clickIconNode, self.activated)
    end

    if not self.activated then
        self:setClickable(false)
    end
end

---Updates screen position of clickPoint
---@param mousePosX number x position of mouse
---@param mousePosY number y position of mouse
function InteractiveClickPoint:updateScreenPosition(mousePosX, mousePosY)
    local x, y, z = getWorldTranslation(self.node)
    local sx, sy, sz = project(x, y, z)

    self.screenPosX = sx
    self.screenPosY = sy

    local isOnScreen = sx > -1 and sx < 2 and sy > -1 and sy < 2 and sz <= 1

    if isOnScreen then
        local cameraNode = getCamera()

        if entityExists(cameraNode) then
            if self.alignToCamera then
                -- Align clickPoint node to camera
                local xC, yC, zC = getWorldTranslation(cameraNode)
                local dirX, dirY, dirZ = xC - x, yC - y, zC - z

                if self.invertZ then
                    dirX = -dirX
                    dirY = -dirY
                    dirZ = -dirZ
                end

                I3DUtil.setWorldDirection(self.node, dirX, dirY, dirZ, 0, 1, 0)
            else
                -- Disable static clickPoint if not in camera direction view
                local dirX, dirY, dirZ = localDirectionToWorld(self.node, 0, 0, 1)
                local cameraDirectionX, cameraDirectionY, cameraDirectionZ = localDirectionToWorld(cameraNode, 0, 0, -1)

                local dotProduct = MathUtil.dotProduct(cameraDirectionX, cameraDirectionY, cameraDirectionZ, dirX, dirY, dirZ)
                if dotProduct < math.cos(math.rad(90)) then
                    mousePosX = nil
                    mousePosY = nil
                end
            end
        end

        self:updateClickable(mousePosX, mousePosY)
    end
end

---Updates clickable state by mouse position
---@param mousePosX number x position of mouse
---@param mousePosY number y position of mouse
function InteractiveClickPoint:updateClickable(mousePosX, mousePosY)
    if mousePosX ~= nil and mousePosY ~= nil then
        local halfSize = self.size / 2
        local isMouseOver = mousePosX > self.screenPosX - halfSize and mousePosX < self.screenPosX + halfSize
            and mousePosY > self.screenPosY - halfSize and mousePosY < self.screenPosY + halfSize

        if self.clickIconNode ~= nil then
            local scale = getScale(self.clickIconNode)
            scale = math.abs(scale)
            if isMouseOver then
                if (scale >= self.scaleMax) or (scale <= self.scaleMin) then
                    self.blinkSpeed = self.blinkSpeed * -1
                end
                scale = scale + self.blinkSpeed * self.blinkSpeedScale
            else
                if scale ~= self.size then
                    self.size = scale
                end
            end

            local xScale = self.invertX and -1 or 1
            setScale(self.clickIconNode, scale * xScale, scale, scale)
        end

        self:setClickable(isMouseOver)
    else
        self:setClickable(false)
    end
end

---Sets clickable state
---@param clickable boolean clickable state value
function InteractiveClickPoint:setClickable(clickable)
    if clickable ~= nil and clickable ~= self.clickable then
        self.clickable = clickable
    end
end

---Returns true if click point is clickable
---@return boolean clickable is clickable
function InteractiveClickPoint:isClickable()
    return self.clickable
end

---Returns true if is executable
---@return boolean executable is executable
function InteractiveClickPoint:isExecutable()
    return InteractiveClickPoint:superClass().isExecutable(self) and self:isClickable()
end

---Returns max hover timeout
---@return number maxHoverTimeout
function InteractiveClickPoint:maxHoverTimeout()
    local clickPointHoverTime = g_currentMission.interactiveControl:getHoverTime()

    return 2 * clickPointHoverTime * 1000
end

---Loads fixed iconType loading
---@param iconType integer iconType integer
---@return table sharedLoadRequestId sharedLoadRequestId table
function InteractiveClickPoint:loadIconType(iconType, target)
    local clickIcon = InteractiveClickPoint.CLICK_ICONS[iconType]
    local filename = Utils.getFilename(clickIcon.filename, g_currentMission.interactiveControl.modDirectory)

    -- load external registered icon files
    if not fileExists(filename) and self.target.baseDirectory ~= nil then
        filename = Utils.getFilename(clickIcon.filename, self.target.baseDirectory)
    end

    -- create node by linkNode
    if self.linkNode ~= nil and self.node == nil then
        self.node = createTransformGroup(("clickPoint_%s"):format(clickIcon.name))
        link(self.linkNode, self.node)

        if self.translation ~= nil then
            setTranslation(self.node, unpack(self.translation))
        end
        if self.rotation ~= nil then
            setRotation(self.node, unpack(self.rotation))
        end
    end

    return target:loadSubSharedI3DFile(filename, false, false, self.onIconTypeLoading, self, { clickIcon })
end

---Called on i3d iconType loading
---@param i3dNode integer integer of i3d node
---@param failedReason any
---@param args table argument table
function InteractiveClickPoint:onIconTypeLoading(i3dNode, failedReason, args)
    if i3dNode == 0 then
        return
    end

    local clickIcon = unpack(args)

    local node = I3DUtil.indexToObject(i3dNode, clickIcon.node, nil)
    if node == nil then
        return
    end

    setTranslation(node, 0, 0, 0)
    local yRot = self.invertZ and math.rad(-180) or 0
    setRotation(node, 0, yRot, 0)
    local xScale = self.invertX and -1 or 1
    setScale(node, self.size * xScale, self.size, self.size)
    -- setVisibility(node, true)
    setVisibility(node, false)

    self.clickIconNode = node
    self.blinkSpeed = clickIcon.blinkSpeed

    link(self.node, node)
    delete(i3dNode)
end

------------------------------------------------- ClickIconType Loading ------------------------------------------------

---Register XMLPaths to XMLSchema
---@param schema XMLSchema Instance of XMLSchema to register path to
---@param basePath string Base path for path registrations
function InteractiveClickPoint.registerClickIconXMLPaths(schema, basePath)
    schema:register(XMLValueType.STRING, basePath .. ".clickIcon(?)#name", "ClickIcon identification name", true)
    schema:register(XMLValueType.STRING, basePath .. ".clickIcon(?)#filename", "ClickIcon filename", true)
    schema:register(XMLValueType.STRING, basePath .. ".clickIcon(?)#node", "ClickIcon node to load dynamic", true)
    schema:register(XMLValueType.FLOAT, basePath .. ".clickIcon(?)#blinkSpeed", "Blinkspeed of clickIcon", true)
end

---Loads and registers clickIconType from XML
---@param xmlFile XMLFile Instance of XMLFile
---@param key string XML key to load from
---@param customEnvironment string Custom environment
function InteractiveClickPoint.loadClickIconTypeFromXML(xmlFile, key, customEnvironment)
    xmlFile:iterate(key .. ".clickIcon", function(_, iconTypeKey)
        local name = xmlFile:getValue(iconTypeKey .. "#name")

        if name ~= nil and name ~= "" then
            local filename = xmlFile:getValue(iconTypeKey .. "#filename")
            local node = xmlFile:getValue(iconTypeKey .. "#node")
            local blinkSpeed = xmlFile:getValue(iconTypeKey .. "#blinkSpeed")

            InteractiveClickPoint.registerIconType(name, filename, node, blinkSpeed, customEnvironment)
        end
    end)
end

------------------------------------------------ ClickIconType Register ------------------------------------------------

---@enum InteractiveClickPoint.CLICK_ICON_ID
InteractiveClickPoint.CLICK_ICON_ID = {
    UNKNOWN = 0
}

---@type table<table> Click icons
InteractiveClickPoint.CLICK_ICONS = {}

local lastId = InteractiveClickPoint.CLICK_ICON_ID.UNKNOWN
---Returns next clickPoint id
---@return integer id
local function getNextId()
    lastId = lastId + 1
    return lastId
end

---Registers new click icon type
---@param name string name of click icon
---@param filename string filename of i3d file
---@param node string index string in i3d file
---@param blinkSpeed number blink speed
function InteractiveClickPoint.registerIconType(name, filename, node, blinkSpeed, customEnvironment)
    if name == nil or name == "" then
        Logging.warning("InteractiveControl: Unable to register clickIcon, invalid name!")
        return false
    end

    name = name:upper()

    if customEnvironment ~= nil and customEnvironment ~= "" then
        name = ("%s.%s"):format(customEnvironment, name)
    end

    if InteractiveClickPoint.CLICK_ICON_ID[name] ~= nil then
        -- clickIcon already registred, but don't write a warning
        return false
    end

    if filename == nil or filename == "" then
        Logging.warning("InteractiveControl: Unable to register clickIcon '%s', invalid filename!", name)
        return false
    end

    InteractiveClickPoint.CLICK_ICON_ID[name] = getNextId()
    local clickIcon = {}
    clickIcon.name = name
    clickIcon.filename = filename
    clickIcon.node = Utils.getNoNil(node, "0")
    clickIcon.blinkSpeed = Utils.getNoNil(blinkSpeed, 0.05)

    InteractiveClickPoint.CLICK_ICONS[InteractiveClickPoint.CLICK_ICON_ID[name]] = clickIcon
    log((" InteractiveControl: Register clickIcon '%s'"):format(name))

    return true
end

----------------------------------------------- ClickIconType Registering ----------------------------------------------

InteractiveClickPoint.registerIconType("CROSS", "data/shared/clickIcons/ic_clickIcons.i3d", "0", 0.05)
InteractiveClickPoint.registerIconType("IGNITIONKEY", "data/shared/clickIcons/ic_clickIcons.i3d", "1", 0.05)
InteractiveClickPoint.registerIconType("CRUISE_CONTROL", "data/shared/clickIcons/ic_clickIcons.i3d", "2", 0.05)
InteractiveClickPoint.registerIconType("GPS", "data/shared/clickIcons/ic_clickIcons.i3d", "3", 0.05)
InteractiveClickPoint.registerIconType("TURN_ON", "data/shared/clickIcons/ic_clickIcons.i3d", "4", 0.05)
InteractiveClickPoint.registerIconType("ATTACHERJOINT_LOWER", "data/shared/clickIcons/ic_clickIcons.i3d", "5", 0.05)
InteractiveClickPoint.registerIconType("ATTACHERJOINT_LIFT", "data/shared/clickIcons/ic_clickIcons.i3d", "6", 0.05)
InteractiveClickPoint.registerIconType("ATTACHERJOINT", "data/shared/clickIcons/ic_clickIcons.i3d", "7", 0.05)
InteractiveClickPoint.registerIconType("LIGHT_HIGH", "data/shared/clickIcons/ic_clickIcons.i3d", "8", 0.05)
InteractiveClickPoint.registerIconType("LIGHT", "data/shared/clickIcons/ic_clickIcons.i3d", "9", 0.05)
InteractiveClickPoint.registerIconType("TURNLIGHT_LEFT", "data/shared/clickIcons/ic_clickIcons.i3d", "10", 0.05)
InteractiveClickPoint.registerIconType("TURNLIGHT_RIGHT", "data/shared/clickIcons/ic_clickIcons.i3d", "11", 0.05)
InteractiveClickPoint.registerIconType("BEACON_LIGHT", "data/shared/clickIcons/ic_clickIcons.i3d", "12", 0.05)
InteractiveClickPoint.registerIconType("ARROW", "data/shared/clickIcons/ic_clickIcons.i3d", "13", 0.05)
InteractiveClickPoint.registerIconType("PIPE_FOLDING", "data/shared/clickIcons/ic_clickIcons.i3d", "14", 0.05)
