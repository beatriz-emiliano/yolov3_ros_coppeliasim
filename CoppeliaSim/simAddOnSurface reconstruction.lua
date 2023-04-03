function sysCall_info()
    return {autoStart=false}
end

function sysCall_addOnScriptSuspend()
    return {cmd='cleanup'}
end

function sysCall_init()
    sim.addLog(sim.verbosity_scriptinfos,"This tool allows to construct a surface from a point cloud.")
end

function sysCall_nonSimulation()
    if leaveNow then
        return {cmd='cleanup'}
    end
    local s=sim.getObjectSelection()
    local show=false
    if s and #s==1 and (sim.getObjectType(s[1])==sim.object_pointcloud_type) then
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
        local xml = [[
        <ui title="Surface Reconstruction" closeable="true" on-close="onCloseClicked" resizable="false" ]]..pos..[[>
                <button text="Reconstruct selected point cloud" checked="false"  on-click="reconstruct_callback" id="1" />
                <label text="" style="* {margin-left: 380px;}"/>
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

function reconstruct_callback()
    local s=sim.getObjectSelection()
    if s and #s>=1 then
        local pc=s[#s]
        if sim.getObjectType(pc)==sim.object_pointcloud_type then
            if #sim.getPointCloudPoints(pc)>2 then
                if sim.msgbox_return_yes==sim.msgBox(sim.msgbox_type_question,sim.msgbox_buttons_yesno,"Surface Reconstruction","This might take several seconds/minutes. Do you want to proceed?") then
                    local shapeHandle=simSurfRec.reconstruct_scale_space(pc,4,12,300,0.001)
                end
            end
        end
    end
end

function onCloseClicked()
    leaveNow=true
end