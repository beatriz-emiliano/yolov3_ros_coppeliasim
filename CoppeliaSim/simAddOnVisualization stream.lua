function sysCall_info()
    autoStart=sim.getNamedBoolParam('visualizationStream.autoStart')
    if autoStart==nil then autoStart=false end
    return {autoStart=autoStart,menu='Connectivity\nVisualization stream'}
end

function sysCall_init()
    addOnPath=sim.getStringParam(sim.stringparam_addonpath)
    addOnBaseName=addOnPath:match("^.+/(.+).lua$")
    addOnDir=addOnPath:match("^(.+)/.*")

    if not simWS then
        sim.addLog(sim.verbosity_errors,'Add-on "'..addOnBaseName..'": the WS plugin is not available')
        return {cmd='cleanup'}
    end

    wsPort=sim.getNamedInt32Param('visualizationStream.ws.port') or 23020
    sim.addLog(sim.verbosity_scriptinfos,'WS endpoint on port '..tostring(wsPort)..'...')
    if sim.getNamedBoolParam('visualizationStream.ws.retryOnStartFailure') then
        while true do
            local r,e=pcall(function() wsServer=simWS.start(wsPort) end)
            if r then break end
            sim.addLog(sim.verbosity_scriptwarnings,'WS failed to start ('..e..'). Retrying...')
            sim.wait(0.5,false)
        end
    else
        wsServer=simWS.start(wsPort)
    end
    simWS.setOpenHandler(wsServer,'onWSOpen')
    simWS.setCloseHandler(wsServer,'onWSClose')
    simWS.setMessageHandler(wsServer,'onWSMessage')
    simWS.setHTTPHandler(wsServer,'onWSHTTP')
    wsClients={}

    cbor=require('org.conman.cbor')
    base64=require('base64')
    url=require('socket.url')

    sim.test('sim.mergeEvents',true)
    sim.test('sim.cborEvents',true)
    
    sim.addLog(sim.verbosity_scriptinfos,'e.g. in your local web browser, type: http://127.0.0.1:'..tostring(wsPort))
end

function sysCall_addOnScriptSuspend()
    return {cmd='cleanup'}
end

function sysCall_event(data)
    sendEventRaw(data)
end

function sysCall_cleanup()
    if wsServer then
        simWS.stop(wsServer)
    end
end

function getFileContents(path)
    local f,err,errno=io.open(path,"rb")
    if f then
        local content=f:read("*all")
        f:close()
        return 200,content
    else
        return 404,nil
    end
end

function onWSOpen(server,connection)
    if server==wsServer then
        wsClients[connection]=1
        sendEventRaw(sim.getGenesisEvents(),connection)
    end
end

function onWSClose(server,connection)
    if server==wsServer then
        wsClients[connection]=nil
    end
end

function onWSMessage(server,connection,message)
end

function onWSHTTP(server,connection,resource,data)
    resource=url.unescape(resource)
    local mainPage='threejsFrontend'
    local status,data=404,nil
    if resource=='/' or resource=='/'..mainPage..'.html' then
        status,data=getFileContents(addOnDir..'/'..mainPage..'.html')
        if status==200 then
            data=string.gsub(data,'const wsPort = 23020;','const wsPort = '..wsPort..';')
        end
    elseif resource=='/'..mainPage..'.js' then
        status,data=getFileContents(addOnDir..'/'..mainPage..'.js')
    elseif resource:sub(1,10)=='/3rdparty/' then
        status,data=getFileContents(addOnDir..resource)
    end
    if status==404 and resource~='/favicon.ico' then
        sim.addLog(sim.verbosity_errors,'resource not found: '..resource)
    end
    return status,data
end

function sendEventRaw(d,conn)
    if d==nil then return end

    if wsServer then
        for connection,_ in pairs(wsClients) do
            if conn==nil or conn==connection then
                simWS.send(wsServer,connection,d,simWS.opcode.binary)
            end
        end
    end
end

function verbose()
    return sim.getNamedInt32Param('visualizationStream.verbose') or 0
end
