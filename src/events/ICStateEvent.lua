---@class ICStateEvent : Event
ICStateEvent = {}

local icStateEvent_mt = Class(ICStateEvent, Event)

InitEventClass(ICStateEvent, "ICStateEvent")

---@return ICStateEvent
function ICStateEvent.emptyNew()
    local self = Event.new(icStateEvent_mt)
    return self
end

function ICStateEvent.new(object, state)
    local self = ICStateEvent.emptyNew()

    self.object = object
    self.state = state

    return self
end

function ICStateEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    self.state = streamReadBool(streamId)
    self:run(connection)
end

function ICStateEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.object)
    streamWriteBool(streamId, self.state)
end

function ICStateEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, false, connection, self.object)
    end

    self.object:activateInteractiveControl(self.state, true)
end

function ICStateEvent.sendEvent(object, state, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(ICStateEvent.new(object, state), nil, nil, object)
        else
            g_client:getServerConnection():sendEvent(ICStateEvent.new(object, state))
        end
    end
end
