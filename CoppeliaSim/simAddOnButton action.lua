function sysCall_info()
    return {autoStart=false}
end

function sysCall_addOnScriptSuspend()
    return {cmd='cleanup'}
end

function close_callback()
    leaveNow=true
end

function sysCall_init()
    sim.addLog(sim.verbosity_scriptinfos,"This add-on allows to quickly apply an action to selected objects/models.")
    selectedObjects={}
end

function action()
    sim.addLog(sim.verbosity_scriptinfos,'Selected object(s) are: ')
    for i=1,#selectedObjects,1 do
        sim.addLog(sim.verbosity_scriptinfos,"    "..sim.getObjectAlias(selectedObjects[i],5))
    end
    sim.addLog(sim.verbosity_scriptinfos,'(edit the add-on to customize the action.)')
end

function showDlg()
    if not ui then
        local pos='position="-50,50" placement="relative"'
        if uiPos then
            pos='position="'..uiPos[1]..','..uiPos[2]..'" placement="absolute"'
        end
        local xml ='<ui title="Apply action" activate="false" closeable="true" on-close="close_callback" layout="vbox" '..pos.." >"
        if #selectedObjects==1 then
            xml=xml..[[<button text="Apply action to the selected object (]]..sim.getObjectAlias(selectedObjects[1],1)..[[)" on-click="action" style="* {min-width: 300px; min-height: 50px;}"/>]]
        else
            xml=xml..string.format('<button text="Apply action to the %i selected objects" on-click="action" style="* {min-width: 300px; min-height: 50px;}"/>',#selectedObjects)
        end
        xml=xml..'</ui>'
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
    selectedObjects={}
end

function sysCall_nonSimulation()
    if leaveNow then
        hideDlg()
        return {cmd='cleanup'}
    end
    local s=sim.getObjectSelection()
    if s and #s>0 then
        if not haveArraysSameContent(selectedObjects,s) then
            hideDlg()
            selectedObjects=s
        end
        showDlg()
    else
        hideDlg()
    end
end

function sysCall_cleanup()
    hideDlg()
end

function sysCall_beforeInstanceSwitch()
    hideDlg()
end

function sysCall_beforeSimulation()
    hideDlg()
end

function haveArraysSameContent(arr1,arr2)
    local retVal=false
    if #arr1==#arr2 then
        retVal=true
        for i=1,#arr1,1 do
            if arr1[i]~=arr2[i] then
                retVal=false
                break
            end
        end
    end
    return retVal
end
