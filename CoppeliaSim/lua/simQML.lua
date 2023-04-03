local simQML={}

local json=require'dkjson'

--@fun sendEvent send an event with an object payload which will be serialized using JSON
--@arg string engine the handle of the QML engine
--@arg string name the name of the event
--@arg table data the object payload
function simQML.sendEvent(engine,name,data)
    data=data or {}
    simQML.sendEventRaw(engine,name,json.encode(data))
end

--@fun setEventHandler registers the event handler for the engine, which will deserialize JSON payloads
--@arg string engine the handle of the QML engine
--@arg string funcName the name of the function, called with args (engineHandle,eventName,eventData)
function simQML.setEventHandler(engine,funcName)
    local func=simQML.resolveHandlerFunction(funcName)
    local wrappedFuncName,i=nil,0
    while not wrappedFuncName or _G[wrappedFuncName] do
        wrappedFuncName='__simQML__eventHandler_'..i
        i=i+1
    end
    _G[wrappedFuncName]=function(engine,eventName,eventData)
        func(engine,eventName,json.decode(eventData))
    end
    simQML.setEventHandlerRaw(engine,wrappedFuncName)
end

function simQML.resolveHandlerFunction(name)
    local f=nil
    if _G[name] then
        f=_G[name]
    elseif simQML['__handler__'..funcName] then
        f=simQML['__handler__'..funcName]
    end
    if not f then
        error('function "'..funcName..'" does not exist')
    end
    if type(f)~='function' then
        error('"'..funcName..'" is not a function')
    end
    return f
end

function simQML.__handler__dispatchEventsToFunctions(engine,name,data)
    _G[name](data)
end

return simQML
