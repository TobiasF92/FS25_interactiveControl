------------------------------------------------------------------------------------------------------------------------
-- InteractiveActorDashboard
------------------------------------------------------------------------------------------------------------------------
-- Purpose: Interactive actor class for dashboard functionality.
--
---@author John Deere 6930 @VertexDezign
------------------------------------------------------------------------------------------------------------------------

---@class InteractiveActorDashboard: InteractiveActor
InteractiveActorDashboard = {}

local interactiveActorDashboard_mt = Class(InteractiveActorDashboard, InteractiveActor)

-- Set input types to vehicle
InteractiveActorDashboard.INPUT_TYPES = { InteractiveController.INPUT_TYPES.VEHICLE }
InteractiveActorDashboard.KEY_NAME = "dashboard"

---Register DASHBOARD interactive actor
InteractiveActor.registerInteractiveActor("DASHBOARD", InteractiveActorDashboard)

---Register XMLPaths to XMLSchema
---@param schema XMLSchema Instance of XMLSchema to register path to
---@param basePath string Base path for path registrations
---@param controllerPath string Controller path for path registrations
function InteractiveActorDashboard.registerXMLPaths(schema, basePath, controllerPath)
    InteractiveActorDashboard:superClass().registerXMLPaths(schema, basePath, controllerPath)

    Dashboard.registerDashboardXMLPaths(schema, controllerPath, "ic_state | ic_stateValue | ic_action")
    schema:register(XMLValueType.TIME, basePath .. "#raiseTime", "(IC) Time to raise dashboard active", 1.0)
    schema:register(XMLValueType.TIME, basePath .. "#activeTime", "(IC) Time to hold dashboard active", 1.0)
    schema:register(XMLValueType.BOOL, basePath .. "#onICActivate", "(IC) Use dashboard on activate ic action", true)
    schema:register(XMLValueType.BOOL, basePath .. "#onICDeactivate", "(IC) Use dashboard on deactivate ic action", true)

    --     -- register depending dashboards
    --     schema:register(XMLValueType.NODE_INDEX, interactiveControlPath .. ".dependingDashboards(?)#node", "Dashboard node")
    --     schema:register(XMLValueType.NODE_INDEX, interactiveControlPath .. ".dependingDashboards(?)#numbers", "Dashboard numbers")
    --     schema:register(XMLValueType.STRING, interactiveControlPath .. ".dependingDashboards(?)#animName", "Dashboard animName")
    --     schema:register(XMLValueType.BOOL, interactiveControlPath .. ".dependingDashboards(?)#dashboardActive", "(IC) Dashboard state while control is active", true)
    --     schema:register(XMLValueType.BOOL, interactiveControlPath .. ".dependingDashboards(?)#dashboardInactive", "(IC) Dashboard state while control is inactive", true)
    --     schema:register(XMLValueType.FLOAT, interactiveControlPath .. ".dependingDashboards(?)#dashboardValueActive", "(IC) Dashboard value while control is active")
    --     schema:register(XMLValueType.FLOAT, interactiveControlPath .. ".dependingDashboards(?)#dashboardValueInactive", "(IC) Dashboard value while control is inactive")
end

---Creates new instance of InteractiveActorDashboard
---@param modName string mod name
---@param modDirectory string mod directory
---@param customMt? metatable custom metatable
---@return InteractiveActorDashboard
function InteractiveActorDashboard.new(modName, modDirectory, customMt)
    local self = InteractiveActorDashboard:superClass().new(modName, modDirectory, customMt or interactiveActorDashboard_mt)

    return self
end

---Loads InteractiveActorDashboard data from xmlFile, returns true if loading was successful, false otherwise
---@param xmlFile XMLFile Instance of XMLFile
---@param key string XML key to load from
---@param target any Target vehicle or placeable
---@param interactiveController InteractiveController Instance of InteractiveController
---@return boolean loaded True if loading succeeded, false otherwise
function InteractiveActorDashboard:loadFromXML(xmlFile, key, target, interactiveController)
    if not InteractiveActorDashboard:superClass().loadFromXML(self, xmlFile, key, target, interactiveController) then
        return false
    end

    if target.setDashboardsDirty == nil then
        return false
    end

    if target.loadDashboardsFromXML ~= nil then
        target:loadDashboardsFromXML(xmlFile, key, {
            valueFunc = "state",
            valueTypeToLoad = "ic_state",
            valueObject = interactiveController
        })
        target:loadDashboardsFromXML(xmlFile, key, {
            valueFunc = InteractiveController.getStateValue,
            valueTypeToLoad = "ic_stateValue",
            valueObject = interactiveController
        })
        target:loadDashboardsFromXML(xmlFile, key, {
            maxFunc = 1,
            minFunc = 0,
            valueTypeToLoad = "ic_action",
            valueObject = self,
            valueFunc = InteractiveActorDashboard.getInteractiveControlDashboardValue,
            additionalAttributesFunc = InteractiveActorDashboard.interactiveControlDashboardAttributes
        })
    end

    -- load depending dashboards from xml
    -- interactiveController.dependingDashboards = {}
    -- if self.spec_dashboard then
    --     local spec_dashboard = self.spec_dashboard

    --     ---Returns dashboard by possible identifiers
    --     ---@param dashboards table dashboard interactiveController
    --     ---@param _dNode number dashboard node
    --     ---@param _dNumber number dashboard number node
    --     ---@param _dAnimName string dashboard animation name
    --     ---@return table|nil dashboard
    --     ---@return any identifier
    --     local function getDashboardByIdentifier(dashboards, _dNode, _dNumber, _dAnimName)
    --         for _, dashboardI in ipairs(dashboards) do
    --             if _dNode ~= nil and dashboardI.node ~= nil and dashboardI.node == _dNode then
    --                 return dashboardI, _dNode
    --             end
    --             if _dNumber ~= nil and dashboardI.numbers ~= nil and dashboardI.numbers == _dNumber then
    --                 return dashboardI, _dNumber
    --             end
    --             if _dAnimName ~= nil and dashboardI.animName ~= nil and dashboardI.animName == _dAnimName then
    --                 return dashboardI, _dAnimName
    --             end
    --         end

    --         return nil, nil
    --     end

    --     xmlFile:iterate(key .. ".dependingDashboards", function(_, dashboardKey)
    --         local dashboardNode = xmlFile:getValue(dashboardKey .. "#node", nil, self.components, self.i3dMappings)
    --         local dashboardNumbers = xmlFile:getValue(dashboardKey .. "#numbers", nil, self.components, self.i3dMappings)
    --         local dashboardAnimName = xmlFile:getValue(dashboardKey .. "#animName")

    --         local dashboard, identifier = getDashboardByIdentifier(spec_dashboard.dashboards, dashboardNode, dashboardNumbers, dashboardAnimName)
    --         if dashboard == nil then
    --             dashboard, identifier = getDashboardByIdentifier(spec_dashboard.criticalDashboards, dashboardNode, dashboardNumbers, dashboardAnimName)
    --         end

    --         if dashboard ~= nil then
    --             local dependingDashboard = {
    --                 dashboard = dashboard,
    --                 identifier = identifier,
    --                 interactiveControl = interactiveController,
    --                 dashboardActive = xmlFile:getValue(dashboardKey .. "#dashboardActive", true),
    --                 dashboardInactive = xmlFile:getValue(dashboardKey .. "#dashboardInactive", true),
    --                 dashboardValueActive = xmlFile:getValue(dashboardKey .. "#dashboardValueActive"),
    --                 dashboardValueInactive = xmlFile:getValue(dashboardKey .. "#dashboardValueInactive"),
    --             }

    --             table.addElement(interactiveController.dependingDashboards, dependingDashboard)
    --         end
    --     end)
    -- end


    return true
end

---Updates interactive actor by stateValue
---@param stateValue number InteractiveController stateValue
---@param forced? boolean Forced update if is true
---@param noEventSend? boolean Don't send an event
function InteractiveActorDashboard:updateState(stateValue, forced, noEventSend)
    InteractiveActorDashboard:superClass().updateState(stateValue, forced, noEventSend)

    -- update dashboards
    self.target:setDashboardsDirty()
end

---Load dashboard attributes for interactive control
---@param xmlFile XMLFile Instance of XMLFile
---@param key string XML key to load from
---@param dashboard table dashboard
---@param isActive boolean is dashboard active
---@return boolean loaded returns true if loaded, false otherwise
function InteractiveActorDashboard:interactiveControlDashboardAttributes(xmlFile, key, dashboard, isActive)
    dashboard.raiseTime = xmlFile:getValue(key .. "#raiseTime", 1.0)
    dashboard.activeTime = xmlFile:getValue(key .. "#activeTime", 1.0)
    dashboard.onICActivate = xmlFile:getValue(key .. "#onICActivate", true)
    dashboard.onICDeactivate = xmlFile:getValue(key .. "#onICDeactivate", true)

    return dashboard.onICActivate or dashboard.onICDeactivate
end

---Returns current dashboard value of interactive control
---@param dashboard table dashboard
---@return number value value between 0 and 1
function InteractiveActorDashboard:getInteractiveControlDashboardValue(dashboard)
    ---@type InteractiveController
    local interactiveController = self.interactiveController
    if interactiveController.lastChangeTime == nil then
        return dashboard.idleValue
    end

    local state = interactiveController:getStateBool()
    local useDashboard = (state and dashboard.onICActivate) or (not state and dashboard.onICDeactivate)
    if not useDashboard then
        return dashboard.idleValue
    end

    local time = g_currentMission.time - interactiveController.lastChangeTime
    local raiseTime = dashboard.raiseTime
    local activeTime = dashboard.activeTime

    local value = 0
    if time <= raiseTime then
        -- raise time to active
        value = time / raiseTime
    elseif time <= (raiseTime + activeTime) then
        -- time active
        value = 1
    elseif time <= (2 * raiseTime + activeTime) then
        -- lower time to idle
        value = 1 - (time - raiseTime - activeTime) / raiseTime
    end

    if dashboard.idleValue ~= 0 then
        local direction = state and 1 or -1
        value = dashboard.idleValue + direction * (1 - dashboard.idleValue) * value
    end

    return value
end

-- ---Returns depending dashboard by identifier
-- ---@param identifier any dashboard identifier
-- ---@return table|nil dependingDashboard
-- function InteractiveActorDashboard:getICDashboardByIdentifier(identifier)
--     local spec = self.spec_interactiveControl

--     if identifier == nil or identifier == "" then
--         return nil
--     end

--     return spec.interactiveControlDependingDashboards[identifier]
-- end
