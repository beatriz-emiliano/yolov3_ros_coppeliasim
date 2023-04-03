function sysCall_info()
    return {autoStart=false}
end

function sysCall_addOnScriptSuspend()
    return {cmd='cleanup'}
end

function sysCall_init()
    sim.addLog(sim.verbosity_scriptinfos,"This tool allows to replace/change aliases of selected objects.")
    strings={"originalString","replacementString"}
end

function sysCall_nonSimulation()
    if leaveNow then
        return {cmd='cleanup'}
    end
    local selectedObjects=sim.getObjectSelection()
    if selectedObjects and (#selectedObjects>=1) then
        showDlg()
    else
        hideDlg()
    end
end

function sysCall_beforeSimulation()
    hideDlg()
end

function sysCall_cleanup()
    hideDlg()
end

function sysCall_beforeInstanceSwitch()
    hideDlg()
end

function showDlg()
    if not ui then
        local pos='position="-50,50" placement="relative"'
        if uiPos then
            pos='position="'..uiPos[1]..','..uiPos[2]..'" placement="absolute"'
        end
        local xml ='<ui title="Alias change tool" activate="false" closeable="true" on-close="close_callback" '..pos..[[>
            <group layout="form" flat="true">
            <label text="replace occurences of"/>
            <edit on-editing-finished="editFinished_callback" id="1" />
            <label text="with string"/>
            <edit on-editing-finished="editFinished_callback" id="2" />
            </group>
            <button text="perform operation on selected objects" on-click="replace_callback" id="3"/>
        </ui>]]
        ui=simUI.create(xml)
        simUI.setEditValue(ui,1,strings[1])
        simUI.setEditValue(ui,2,strings[2])
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

function editFinished_callback(ui,id,v)
    strings[id]=v
end

function replace_callback(ui,id,v)
    local selectedObjects=sim.getObjectSelection()
    if #strings[1]>0 then
        for i=1,#selectedObjects,1 do
            local name=sim.getObjectAlias(selectedObjects[i])
            local newName,r=string.gsub(name,strings[1],strings[2])
            if (r>0) then
                sim.setObjectAlias(selectedObjects[i],newName)
            end
        end
    end
end

function close_callback()
    leaveNow=true
end