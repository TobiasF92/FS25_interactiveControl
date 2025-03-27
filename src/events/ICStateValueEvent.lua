---@class ICStateValueEvent : Event
ICStateValueEvent = {}

local icStateValueEvent_mt = Class(ICStateValueEvent, Event)

InitEventClass(ICStateValueEvent, "ICStateValueEvent")

---@return ICStateValueEvent
function ICStateValueEvent.emptyNew()
    local self = Event.new(icStateValueEvent_mt)
    return self
end

function ICStateValueEvent.new(object, index, stateValue)
    local self = ICStateValueEvent.emptyNew()

    self.object = object
    self.index = index
    self.stateValue = stateValue

    return self
end

function ICStateValueEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    self.index = streamReadInt8(streamId)
    self.stateValue = streamReadFloat32(streamId)

    self:run(connection)
end

function ICStateValueEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.object)
    streamWriteInt8(streamId, self.index)
    streamWriteFloat32(streamId, self.stateValue)
end

function ICStateValueEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, false, connection, self.object)
    end

    self.object:setInteractiveControllerStateValueByIndex(self.index, self.stateValue, nil, nil, true)
end

function ICStateValueEvent.sendEvent(object, index, stateValue, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(ICStateValueEvent.new(object, index, stateValue), nil, nil, object)
        else
            g_client:getServerConnection():sendEvent(ICStateValueEvent.new(object, index, stateValue))
        end
    end
end
