function sysCall_info()
    return {autoStart=false}
end

function sysCall_addOnScriptSuspend()
    return {cmd='cleanup'}
end

function sysCall_init()
    sim.addLog(sim.verbosity_scriptinfos,"When simulation starts, you will be able to manually trigger individual simulation steps.")
end

function stop_callback()
    haltMainScript=false -- enable the main script
    sim.stopSimulation()
    stepping=false
end

function run_callback()
    haltMainScript=false -- enable the main script
    stepping=false
end

function step_callback()
    haltMainScript=false -- enable the main script
    stepping=true
end

function stepFunction(inInts,inFloats,inStrings,inBuffer)
    step_callback()
    return {},{},{},''
end

function showDlg()
    if not ui then
        local pos='position="-50,50" placement="relative"'
        if uiPos then
            pos='position="'..uiPos[1]..','..uiPos[2]..'" placement="absolute"'
        end
        local xml ='<ui title="Simulation Stepper" closeable="true" on-close="close_callback" resizable="false" activate="false" '..pos..[[>
        <button text="Step simulation" on-click="step_callback" style="* {min-width: 300px; min-height: 50px;}"/>
        <button text="Run simulation" on-click="run_callback" style="* {min-width: 300px;}"/>
        <button text="Stop simulation" on-click="stop_callback" style="* {min-width: 300px;}"/>
    </ui>
    ]]
        ui=simUI.create(xml)
    end
end

function hideDlg()
    if ui then
        uiPos={}
        uiPos[1],uiPos[2]=simUI.getPosition(ui)
        simUI.destroy(ui)
        ui=nil
    end
end

function close_callback()
    leaveNow=true
end

function sysCall_beforeMainScript()
    local retVal={doNotRunMainScript=haltMainScript}
    if leaveNow then
        retVal.cmd='cleanup'
    end
    return retVal
end

function sysCall_beforeSimulation()
    haltMainScript=true -- disable the main script
    stepping=true
    showDlg()
end

function sysCall_afterSimulation()
    haltMainScript=false -- enable the main script again
    hideDlg()
end

function sysCall_sensing()
    if stepping then
        haltMainScript=true -- disable the main script again
    else
        if not ui then -- enabled while sim. running
            haltMainScript=true
            stepping=true
            showDlg()
        end
    end
end

function sysCall_cleanup()
    hideDlg()
    haltMainScript=false -- enable the main script again
end
