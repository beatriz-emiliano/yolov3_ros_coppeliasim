function sysCall_info()
    return {autoStart=false}
end

function sysCall_addOnScriptSuspend()
    return {cmd='cleanup'}
end

function close_callback()
    leaveNow=true
end

function dist(ui,id)
    restoreScene()
    local entity1=obj1
    local entity2=obj2
    local entity1=sim.createCollection(0)
    local entity2=sim.createCollection(0)
    if obj1IsModel then
        sim.addItemToCollection(entity1,sim.handle_tree,obj1,0)
    else
        sim.addItemToCollection(entity1,sim.handle_single,obj1,0)
    end
    if obj2~=-1 then
        if obj2IsModel then
            sim.addItemToCollection(entity2,sim.handle_tree,obj2,0)
        else
            sim.addItemToCollection(entity2,sim.handle_single,obj2,0)
        end
    else
        sim.addItemToCollection(entity2,sim.handle_all,-1,0)
        if obj1IsModel then
            sim.addItemToCollection(entity2,sim.handle_tree,obj1,1)
        else
            sim.addItemToCollection(entity2,sim.handle_single,obj1,1)
        end
    end

    local r,distData,pair=sim.checkDistance(entity1,entity2)
    sim.destroyCollection(entity1)
    sim.destroyCollection(entity2)
    restoreData={time=sim.getSystemTime()}
    if r>0 then
        sim.addLog(sim.verbosity_scriptinfos,string.format("measured distance is %.3f meters",distData[7]))
        restoreData.lineContainer=sim.addDrawingObject(sim.drawing_lines,4,0,-1,99,{0,0,0})
        sim.addDrawingObjectItem(restoreData.lineContainer,distData)
    else
        sim.addLog(sim.verbosity_scriptinfos,"no distance could be measured")
        restoreData=nil
    end
end

function sysCall_init()
    sim.addLog(sim.verbosity_scriptinfos,"This add-on allows to quickly measure the distance between two entities, or between one entity and the environment. Just select one or two entities.")
    obj1=-1
    obj2=-1
end

function showDlg()
    if not ui and sim.isHandle(obj1) then
        local pos='position="-50,50" placement="relative"'
        if uiPos then
            pos='position="'..uiPos[1]..','..uiPos[2]..'" placement="absolute"'
        end
        local txt1
        if obj2==-1 then
            if obj1IsModel then
                txt1="Check distance to the environment for model "..sim.getObjectAlias(obj1,5)
            else
                txt1="Check distance to the environment for object "..sim.getObjectAlias(obj1,5)
            end
        else
            txt1="Check distance between "
            if obj1IsModel then
                txt1=txt1.."model "
            else
                txt1=txt1.."object "
            end
            txt1=txt1..sim.getObjectAlias(obj1,5).." and "
            if obj2IsModel then
                txt1=txt1.."model "
            else
                txt1=txt1.."object "
            end
            txt1=txt1..sim.getObjectAlias(obj2,5)
        end
        local xml ='<ui title="Distance check" activate="false" closeable="true" on-close="close_callback" layout="vbox" '..pos..'>'
        xml=xml..'<button text="'..txt1..'" on-click="dist" style="* {min-width: 300px; min-height: 50px;}" id="1"/>'
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
    obj1=-1
    obj2=-1
    restoreScene()
end

function restoreScene()
    if restoreData then
        sim.removeDrawingObject(restoreData.lineContainer)
        restoreData=nil
    end
end

function sysCall_sensing()
    return update()
end

function sysCall_nonSimulation()
    return update()
end

function update()
    if leaveNow then
        hideDlg()
        return {cmd='cleanup'}
    end
    local s=sim.getObjectSelection()
    local o1=-1
    local o2=-1
    if s and #s<3 and #s>0 then
        obj1IsModel=(sim.getModelProperty(s[1])&sim.modelproperty_not_model)==0
        local t=sim.getObjectType(s[1])
        if t==sim.object_shape_type or t==sim.object_dummy_type or t==sim.object_octree_type or t==sim.object_pointcloud_type or obj1IsModel then
            o1=s[1]
        end
        if #s==2 then
            obj2IsModel=(sim.getModelProperty(s[2])&sim.modelproperty_not_model)==0
            local t=sim.getObjectType(s[2])
            if t==sim.object_shape_type or t==sim.object_dummy_type or t==sim.object_octree_type or t==sim.object_pointcloud_type or obj2IsModel then
                o2=s[2]
            else
                o1=-1
            end
        end
        if obj1~=o1 or obj2~=o2 then
            hideDlg()
        end
    end
    obj1=o1
    obj2=o2
    if obj1~=-1 then
        showDlg()
    else
        hideDlg()
    end
    if restoreData then
        if sim.getSystemTime()-restoreData.time>1 then
            restoreScene()
        end
    end
end

function sysCall_cleanup()
    hideDlg()
end

function sysCall_beforeInstanceSwitch()
    hideDlg()
    obj1=-99
end
