function sysCall_init()
    corout=coroutine.create(coroutineMain)
end

function sysCall_nonSimulation()
    resumeThread()
end

function sysCall_actuation()
    resumeThread()
end

function resumeThread()
    if coroutine.status(corout)~='dead' then
        local ok,errorMsg=coroutine.resume(corout)
        if errorMsg then
            error(debug.traceback(corout,errorMsg),2)
        end
    end
end

function coroutineMain()
    -- Put some initialization code here


    -- Put your main loop here, e.g.:
    --
    -- while true do
    --     local p=sim.getObjectPosition(objHandle,-1)
    --     p[1]=p[1]+0.001
    --     sim.setObjectPosition(objHandle,-1,p)
    --     sim.switchThread() -- resume in next simulation step
    -- end
end

function sysCall_beforeSimulation()
    -- is executed before a simulation starts
end

function sysCall_afterSimulation()
    -- is executed before a simulation ends
end

function sysCall_cleanup()
    -- do some clean-up here
end

-- See the user manual or the available code snippets for additional callback functions and details
