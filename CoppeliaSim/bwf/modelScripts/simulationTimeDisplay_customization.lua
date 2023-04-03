simBWF=require('simBWF')
function removeFromPluginRepresentation()

end

function updatePluginRepresentation()

end

function getDefaultInfoForNonExistingFields(info)
    if not info['version'] then
        info['version']=_MODELVERSION_
    end
    if not info['subtype'] then
        info['subtype']='time'
    end
    if not info['bitCoded'] then
        info['bitCoded']=0 -- 1: simplified display
    end
end

function readInfo()
    local data=sim.readCustomDataBlock(model,'XYZ_SIMULATIONTIME_INFO')
    if data then
        data=sim.unpackTable(data)
    else
        data={}
    end
    getDefaultInfoForNonExistingFields(data)
    return data
end

function writeInfo(data)
    if data then
        sim.writeCustomDataBlock(model,'XYZ_SIMULATIONTIME_INFO',sim.packTable(data))
    else
        sim.writeCustomDataBlock(model,'XYZ_SIMULATIONTIME_INFO','')
    end
end

function setDlgItemContent()
    if ui then
        local config=readInfo()
        local sel=simBWF.getSelectedEditWidget(ui)
        simUI.setCheckboxValue(ui,1,simBWF.getCheckboxValFromBool((config['bitCoded']&1)~=0),true)
        local sel=simBWF.getSelectedEditWidget(ui)
        simBWF.setSelectedEditWidget(ui,sel)
    end
end

function simplified_callback(ui,id)
    local c=readInfo()
    c['bitCoded']=(c['bitCoded']~1)
    writeInfo(c)
    simBWF.markUndoPoint()
    setDlgItemContent()
end

function createDlg()
    if not ui then
        local xml =[[
                <label text="" style="* {margin-left: 150px;}"/>
                <label text="" style="* {margin-left: 150px;}"/>

                <label text="Simplified display"/>
                <checkbox text="" on-change="simplified_callback" id="1" />
        ]]
        ui=simBWF.createCustomUi(xml,'Simulation Time',previousDlgPos,false,nil,false,false,false,'layout="form"')

        setDlgItemContent()
    end
end

function showDlg()
    if not ui then
        createDlg()
    end
end

function removeDlg()
    if ui then
        local x,y=simUI.getPosition(ui)
        previousDlgPos={x,y}
        simUI.destroy(ui)
        ui=nil
    end
end

showOrHideUiIfNeeded=function()
    local s=sim.getObjectSelection()
    if s and #s>=1 and s[#s]==model then
        showDlg()
    else
        removeDlg()
    end
end

function sysCall_init()
    model=sim.getObject('.')
    _MODELVERSION_=0
    _CODEVERSION_=0
    local _info=readInfo()
    simBWF.checkIfCodeAndModelMatch(model,_CODEVERSION_,_info['version'])
    writeInfo(_info)
    
    local objs=sim.getObjectsWithTag('XYZ_SIMULATIONTIME_INFO',true)
    previousDlgPos,algoDlgSize,algoDlgPos,distributionDlgSize,distributionDlgPos,previousDlg1Pos=simBWF.readSessionPersistentObjectData(model,"dlgPosAndSize")
    if #objs>1 then
        sim.removeObject(model)
        sim.removeObjectFromSelection(sim.handle_all)
        objs=sim.getObjectsWithTag('XYZ_SIMULATIONTIME_INFO',true)
        sim.addObjectToSelection(sim.handle_single,objs[1])
    else
        updatePluginRepresentation()
    end
end

function sysCall_nonSimulation()
    showOrHideUiIfNeeded()
end

function sysCall_afterSimulation()
    sim.setObjectInt32Param(model,sim.objintparam_visibility_layer,1)
end

function sysCall_beforeSimulation()
    sim.setObjectInt32Param(model,sim.objintparam_visibility_layer,0)
    removeDlg()
end

function sysCall_beforeInstanceSwitch()
    removeDlg()
    removeFromPluginRepresentation()
end

function sysCall_afterInstanceSwitch()
    updatePluginRepresentation()
end

function sysCall_cleanup()
    removeDlg()
    removeFromPluginRepresentation()
    if sim.isHandle(model) then
        -- the associated object might already have been destroyed
        simBWF.writeSessionPersistentObjectData(model,"dlgPosAndSize",previousDlgPos,algoDlgSize,algoDlgPos,distributionDlgSize,distributionDlgPos,previousDlg1Pos)
    end
end

