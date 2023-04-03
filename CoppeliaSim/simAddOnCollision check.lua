function sysCall_info()
    return {autoStart=false}
end

function sysCall_addOnScriptSuspend()
    return {cmd='cleanup'}
end

function close_callback()
    leaveNow=true
end

function couldCollide(obj,typ,ignoreModelOverride)
    local retVal=false
    if typ==sim.object_shape_type or typ==sim.object_octree_type or typ==sim.object_pointcloud_type or typ==sim.object_dummy_type then
        if sim.getObjectSpecialProperty(obj)&sim.objectspecialproperty_collidable>0 then
            -- Check if the object is possibly part of a model that has a collidable flag override:
            retVal=true
            if not ignoreModelOverride then
                while obj~=-1 do
                    local p=sim.getModelProperty(obj)
                    if (p&(sim.modelproperty_not_model|sim.modelproperty_not_collidable))==sim.modelproperty_not_collidable then
                        retVal=false
                        break
                    end
                    obj=sim.getObjectParent(obj)
                end
            end
        end
    end
    return retVal
end

function adjust(obj)
    restoreScene()
    local toExplore={obj}
    local indic=0
    local modelDone=false
    while #toExplore>0 do -- process hierarchy levels sequentially
        local nextToExplore={}
        local found=false
        for j=1,#toExplore,1 do
            local obj=toExplore[j]
            
            if sim.getModelProperty(obj)&sim.modelproperty_not_model~=0 or (not modelDone) then
                modelDone=true -- stop exploration at first model
                local t=sim.getObjectType(obj)
                if couldCollide(obj,t,true) then
                    found=true
                    sim.setObjectInt32Param(obj,sim.objintparam_collection_self_collision_indicator,indic)
                end
                local i=0
                while true do
                    local c=sim.getObjectChild(obj,i)
                    if c<0 then
                        break
                    end
                    nextToExplore[#nextToExplore+1]=c
                    i=i+1
                end
            end
        end
        if found then
            indic=indic+1
        end
        toExplore=nextToExplore
    end
end

function coll(ui,id)
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
        if id==2 then
            sim.addItemToCollection(entity2,sim.handle_tree,obj1,0)
        else
            sim.addItemToCollection(entity2,sim.handle_all,-1,0)
            if obj1IsModel then
                sim.addItemToCollection(entity2,sim.handle_tree,obj1,1)
            else
                sim.addItemToCollection(entity2,sim.handle_single,obj1,1)
            end
        end
    end
    local objectsColl1=sim.getCollectionObjects(entity1)
    local objectsColl2=sim.getCollectionObjects(entity2)
    sim.destroyCollection(entity1)
    sim.destroyCollection(entity2)
    
    restoreData={dummy=-1,origs={},origLayers={},origsMap={}}
    local allCollisions={}
    local colors={{1,0,0},{0,1,0},{0,0.5,1},{1,1,0},{1,0,1},{0,1,0.5},{0.5,0,0},{0,0.5,0},{0,0.25,0.5},{0.5,0.5,0},{0.5,0,0.5},{0,0.5,0.25}}
    local colInd=1
    local function getCol(ind,b)
        local retVal
        if id==1 then
            retVal=colors[ind]
        else
            retVal=colors[colInd]
        end
        colInd=colInd+1
        if colInd>#colors then
            colInd=1
        end
        if b then
            retVal[1]=retVal[1]*255
            retVal[2]=retVal[2]*255
            retVal[3]=retVal[3]*255
        end
        return retVal
    end
    for obj1Cnt=1,#objectsColl1,1 do
        local objPair={objectsColl1[obj1Cnt]}
        local t={sim.getObjectType(objPair[1])}
        if couldCollide(objPair[1],t[1]) then
            for obj2Cnt=1,#objectsColl2,1 do
                objPair[2]=objectsColl2[obj2Cnt]
                if objPair[1]~=objPair[2] then
                    t[2]=sim.getObjectType(objPair[2])
                    if couldCollide(objPair[2],t[2]) then
                        if allCollisions[objPair[1]]==nil then
                            allCollisions[objPair[1]]={}
                        end
                        if allCollisions[objPair[2]]==nil then
                            allCollisions[objPair[2]]={}
                        end
                        if allCollisions[objPair[1]][objPair[2]]==nil then
                            local indic1=sim.getObjectInt32Param(objPair[1],sim.objintparam_collection_self_collision_indicator)
                            local indic2=sim.getObjectInt32Param(objPair[2],sim.objintparam_collection_self_collision_indicator)
                            if math.abs(indic1-indic2)~=1 and math.abs(indic1-indic2)~=10 and math.abs(indic1-indic2)~=100 and math.abs(indic1-indic2)~=1000 and math.abs(indic1-indic2)~=10000 and math.abs(indic1-indic2)~=100000 then
                                local r,collPair=sim.checkCollision(objPair[1],objPair[2])
                                if r>0 then
                                    sim.addLog(sim.verbosity_scriptinfos,"collision detected between object "..sim.getObjectAlias(objPair[1],5).." and object "..sim.getObjectAlias(objPair[2],5))
                                    if restoreData.dummy==-1 then
                                        restoreData.dummy=sim.createDummy(0.01)
                                        sim.setObjectInt32Param(restoreData.dummy,sim.objintparam_visibility_layer,0)
                                        sim.setObjectProperty(restoreData.dummy,sim.objectproperty_collapsed)
                                        sim.setObjectAlias(restoreData.dummy,"collisionCheckTemp")
                                        sim.setModelProperty(restoreData.dummy,0)
                                    end
                                    for i=1,2,1 do
                                        if restoreData.origsMap[objPair[i]]==nil then
                                            restoreData.origsMap[objPair[i]]=true
                                            restoreData.origs[#restoreData.origs+1]=objPair[i]
                                            restoreData.origLayers[#restoreData.origLayers+1]=sim.getObjectInt32Param(objPair[i],sim.objintparam_visibility_layer)
                                            sim.setObjectInt32Param(objPair[i],sim.objintparam_visibility_layer,0)
                                            local copy
                                            if t[i]==sim.object_dummy_type then
                                                copy=sim.createDummy(0.01,getCol(i))
                                                sim.setObjectPose(copy,-1,sim.getObjectPose(objPair[i],-1))
                                            end
                                            if t[i]==sim.object_shape_type then
                                                copy=sim.copyPasteObjects({objPair[i]},2+4+8+16+32)[1]
                                                sim.setShapeColor(copy,nil,sim.colorcomponent_ambient_diffuse,getCol(i))
                                                sim.setShapeColor(copy,nil,sim.colorcomponent_specular,{0.1,0.1,0.1})
                                                sim.setShapeColor(copy,nil,sim.colorcomponent_emission,{0,0,0})
                                            end
                                            if t[i]==sim.object_octree_type then
                                                copy=sim.copyPasteObjects({objPair[i]},2+4+8+16+32)[1]
                                                sim.removeVoxelsFromOctree(copy,0,nil)
                                                sim.insertVoxelsIntoOctree(copy,1,sim.getOctreeVoxels(objPair[i]),getCol(i,true))
                                            end
                                            if t[i]==sim.object_pointcloud_type then
                                                copy=sim.createPointCloud(0.1,50,8,4)
                                                sim.setObjectPose(copy,-1,sim.getObjectPose(objPair[i],-1))
                                                sim.insertPointsIntoPointCloud(copy,1,sim.getPointCloudPoints(objPair[i]),getCol(i,true))
                                            end
                                            sim.setObjectSpecialProperty(copy,0)
                                            sim.setObjectProperty(copy,0)
                                            sim.setObjectInt32Param(copy,sim.objintparam_visibility_layer,65535)
                                            sim.setObjectParent(copy,restoreData.dummy,true)
                                        end
                                    end
                                end
                            end
                            allCollisions[objPair[1]][objPair[2]]=true
                            allCollisions[objPair[2]][objPair[1]]=true
                        end
                    end
                end
            end
        end
    end
    if restoreData.dummy==-1 then
        sim.addLog(sim.verbosity_scriptinfos,"no collision detected")
        restoreData=nil
    else
        if id==2 then
            restoreData.selfCollEntity=obj1
        end
        restoreData.time=sim.getSystemTime()
    end
end

function sysCall_init()
    sim.addLog(sim.verbosity_scriptinfos,"This add-on allows to quickly verify the collision state of one or two entities. Just select one or two entities.")
    obj1=-1
    obj2=-1
end

function showDlg()
    if not ui and sim.isHandle(obj1) then
        local pos='position="-50,50" placement="relative"'
        if uiPos then
            pos='position="'..uiPos[1]..','..uiPos[2]..'" placement="absolute"'
        end
        local txt1,txt2
        if obj2==-1 then
            if obj1IsModel then
                txt1="Check for collision with the environment for model "..sim.getObjectAlias(obj1,5)
                txt2="Check for self-collision for model "..sim.getObjectAlias(obj1,5)
            else
                txt1="Check for collision with the environment for object "..sim.getObjectAlias(obj1,5)
            end
        else
            txt1="Check for collision between "
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
        local xml ='<ui title="Collision check" activate="false" closeable="true" on-close="close_callback" layout="vbox" '..pos..'>'
        xml=xml..'<button text="'..txt1..'" on-click="coll" style="* {min-width: 300px; min-height: 50px;}" id="1"/>'
        if txt2 then
            xml=xml..'<button text="'..txt2..'" on-click="coll" style="* {min-width: 300px; min-height: 50px;}" id="2"/>'
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
    obj1=-1
    obj2=-1
    restoreScene()
end

function restoreScene(selfCollEntity)
    if restoreData then
        if sim.isHandle(restoreData.dummy) then
            sim.removeModel(restoreData.dummy)
        end
        for i=1,#restoreData.origs,1 do
            if sim.isHandle(restoreData.origs[i]) then
                sim.setObjectInt32Param(restoreData.origs[i],sim.objintparam_visibility_layer,restoreData.origLayers[i])
            end
        end
        restoreData=nil
        if selfCollEntity and sim.isHandle(selfCollEntity) then
            local txt="The model "..sim.getObjectAlias(selfCollEntity,5).." collides with itself."
            txt=txt.."\nDo you want to try to apply a simple method to automatically adjust the model's collection self-collision indicators'?\n\nnote: sub-models will be left untouched"
            if simUI.msgBox(simUI.msgbox_type.question,simUI.msgbox_buttons.yesno,"Model self-collision",txt)==simUI.msgbox_result.yes then
                adjust(selfCollEntity)
            end
        end
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
            restoreScene(restoreData.selfCollEntity)
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

