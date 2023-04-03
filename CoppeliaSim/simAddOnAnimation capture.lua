function sysCall_info()
    return {autoStart=false}
end

function sysCall_init()
    sim.addLog(sim.verbosity_scriptinfos,"Before simulation starts, select an object/model: its movement (including all of its hierarchy) will be recorded and a self-sufficient model created from it at simulation end.")
    selectedObject=-1
end

function sysCall_addOnScriptSuspend()
    return {cmd='cleanup'}
end

function showDlg()
    if not ui then
        local pos='position="-50,50" placement="relative"'
        if uiPos then
            pos='position="'..uiPos[1]..','..uiPos[2]..'" placement="absolute"'
        end
        local xml ='<ui title="Animation model capture" activate="false" closeable="true" on-close="close_callback" layout="vbox" '..pos..[[>
                <label text="On simulation start, an animation model will be recorded for object/model ']]..sim.getObjectAlias(selectedObject,1)..[['" />
                <label text="i.e. movement of above object (and all of its hierarchy) will be captured and baked into a self-sufficient model." />
        </ui>]]
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
    selectedObject=-1
end

function sysCall_nonSimulation()
    if leaveNow then
        return {cmd='cleanup'}
    end
    local s=sim.getObjectSelection()
    local show=false
    if s and #s==1 then
        local inf=sim.readCustomDataBlock(s[1],'__info__')
        if inf==nil or sim.unpackTable(inf).type~='animation' then
            local tmp=sim.getObjectsInTree(s[1])
            local cnt=0
            for i=1,#tmp,1 do
                local obj=tmp[i]
                if sim.getObjectInt32Param(obj,sim.objintparam_visible)~=0 and sim.getObjectType(obj)==sim.object_shape_type then
                    cnt=cnt+1
                end
            end
            show=(cnt>0)
        end
    end
    if show then
        if selectedObject~=s[1] then
            hideDlg()
            selectedObject=s[1]
        end
        showDlg()
    else
        selectedObject=-1
        hideDlg()
    end
end

function sysCall_cleanup()
    hideDlg()
end

function sysCall_beforeInstanceSwitch()
    hideDlg()
end

function close_callback()
    leaveNow=true
end

function sysCall_beforeSimulation()
    local modelBase=selectedObject
    hideDlg()
    if modelBase~=-1 then
        local map={}
        local tmp=sim.getObjectsInTree(modelBase)
        local cnt=0
        for i=1,#tmp,1 do
            local obj=tmp[i]
            if sim.getObjectInt32Param(obj,sim.objintparam_visible)~=0 and sim.getObjectType(obj)==sim.object_shape_type then
                map[obj]=true
                cnt=cnt+1
            end
        end
        
        if cnt>0 then
            modelData={}
            modelData.modelBaseExists=map[modelBase]
            map[modelBase]=true
            local objects={{h=modelBase}}
            for obj,v in pairs(map) do
                if obj~=modelBase then
                    objects[#objects+1]={h=obj}
                end
            end
            for i=1,#objects,1 do
                local obj=objects[i].h
                local parent=sim.getObjectParent(obj)
                while parent~=-1 and (map[parent]==nil) do
                    parent=sim.getObjectParent(parent)
                end
                objects[i].parent=parent
                objects[i].initLocalPose=sim.getObjectPose(obj,parent)
                objects[i].previousLocalPose=sim.packTable(objects[i].initLocalPose)
                objects[i].poses={}
                objects[i].posesAreChanging=false
            end
            modelData.objects=objects
            modelData.times={}
            modelData.map=map
        end
    end
    dt=sim.getSimulationTimeStep()
end

function sysCall_afterSimulation()
    if modelData then
        local map={}
        local invMap={}
        local dummy
        for i=1,#modelData.objects,1 do
            local obj=modelData.objects[i].h
            local copy
            if i==1 then -- base
                if modelData.modelBaseExists then
                    copy=sim.copyPasteObjects({obj},2+4+8+32)[1]
                    dummy=sim.createDummy(0.001)
                else
                    copy=sim.createDummy(0.001)
                    dummy=copy
                end
            else
                copy=sim.copyPasteObjects({obj},2+4+8)[1]
            end
            if copy~=dummy then
                sim.setObjectProperty(copy,sim.objectproperty_collapsed|sim.objectproperty_selectable|sim.objectproperty_selectmodelbaseinstead)
            end
            map[copy]=obj
            invMap[obj]=copy
        end
        
        for i=1,#modelData.objects,1 do
            local data=modelData.objects[i]
            local orig=data.h
            local obj=invMap[orig]
            
            sim.setModelProperty(obj,sim.modelproperty_not_model)
            if i==1 then
                if modelData.modelBaseExists then
                    sim.setObjectParent(obj,dummy,true)
                    sim.setObjectPose(obj,sim.handle_parent,{0,0,0,0,0,0,1})
                    sim.setObjectPose(dummy,-1,data.initLocalPose)
                else
                    sim.setObjectPose(obj,sim.handle_parent,data.initLocalPose)
                end
            else
                local parent=invMap[data.parent]
                sim.setObjectParent(obj,parent,true)
                sim.setObjectPose(obj,sim.handle_parent,data.initLocalPose)
            end
            
        end

        sim.setModelProperty(dummy,sim.modelproperty_not_collidable|sim.modelproperty_not_detectable|sim.modelproperty_not_dynamic|sim.modelproperty_not_measurable|sim.modelproperty_not_respondable)
        sim.setObjectProperty(dummy,sim.objectproperty_collapsed|sim.objectproperty_selectable|sim.objectproperty_canupdatedna)
        local s=sim.addScript(sim.scripttype_customizationscript)
        sim.setScriptText(s,"require('animator_customization')")
        sim.associateScriptWithObject(s,dummy)
        local animationData={times=modelData.times,poses={modelData.objects[1].poses},initPoses={modelData.objects[1].initLocalPose}}
        local handles={dummy}
        for i=2,#modelData.objects,1 do
            if modelData.objects[i].posesAreChanging then
                handles[#handles+1]=invMap[modelData.objects[i].h]
                animationData.poses[#animationData.poses+1]=modelData.objects[i].poses
                animationData.initPoses[#animationData.initPoses+1]=modelData.objects[i].initLocalPose
            end
        end
        modelData=nil
        
        sim.writeCustomDataBlock(dummy,'animationData',sim.packTable(animationData))
        sim.writeCustomDataBlock(dummy,'__info__',sim.packTable({type='animation'}))
        sim.setReferencedHandles(dummy,handles)
        sim.setObjectAlias(dummy,"animatedModel")
        local s=sim.getModelBB(dummy)
        s=math.floor(0.1*20*(s[1]+s[2]*s[3])/3)/20 -- in 5cm steps
        if s==0 then
            s=0.05
        end
        local p=sim.getObjectPosition(dummy,-1)
        p[1]=p[1]+s
        p[2]=p[2]+s
        sim.setObjectPosition(dummy,-1,p)
        sim.removeObjectFromSelection(sim.handle_all,-1)
        sim.addObjectToSelection(sim.handle_single,dummy)
        local txt="Animation model '"..sim.getObjectAlias(dummy,1).."' was created!"
        sim.addLog(sim.verbosity_scriptinfos,txt)
        sim.msgBox(sim.dlgstyle_message,sim.msgbox_buttons_ok,'Animation model',txt)
    end
end

function sysCall_sensing()
    if modelData then
        modelData.times[#modelData.times+1]=sim.getSimulationTime()
        for i=1,#modelData.objects,1 do
            local data=modelData.objects[i]
            local p=sim.getObjectPose(data.h,data.parent)
            local pp=sim.packTable(p)
            if pp~=data.previousLocalPose then
                data.posesAreChanging=true
            end
            for j=1,7,1 do
                data.poses[#data.poses+1]=p[j]
            end
            data.previousLocalPose=pp
        end
    end
end
