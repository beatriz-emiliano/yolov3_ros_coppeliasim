function sysCall_info()
    return {autoStart=false}
end

function sysCall_addOnScriptSuspend()
    return {cmd='cleanup'}
end

function sysCall_init()
    createDummies=false
    sim.addLog(sim.verbosity_scriptinfos,"This tool allows to sample points in the scene, and optionally create dummies from them")
    showDlg()
end

function sysCall_nonSimulation()
    if leaveNow then
        return {cmd='cleanup'}
    end

    sim.addDrawingObjectItem(pts,nil)
    sim.addDrawingObjectItem(lines,nil)
    if sim.getBoolParam(sim.boolparam_rayvalid) then
        local coll=sim.createCollection(1)
        local objs=sim.getObjectsInTree(sim.handle_scene)
        for i=1,#objs,1 do
            local t=sim.getObjectType(objs[i])
            if (t==sim.object_shape_type)or(t==sim.object_octree_type) then
                if sim.getObjectInt32Param(objs[i],sim.objintparam_visible)~=0 then
                    sim.addItemToCollection(coll,sim.handle_single,objs[i],0)
                end
            end
        end
        local orig=sim.getArrayParam(sim.arrayparam_rayorigin)
        local dir=sim.getArrayParam(sim.arrayparam_raydirection)
        local m=sim.buildIdentityMatrix()
        m[4]=orig[1]
        m[8]=orig[2]
        m[12]=orig[3]
        local z=Vector3(dir)
        local up=Vector3({0,0,1})
        local x=up:cross(z):normalized()
        local y=z:cross(x)
        m[1]=x[1]  m[5]=x[2]  m[9]=x[3]
        m[2]=y[1]  m[6]=y[2]  m[10]=y[3]
        m[3]=z[1]  m[7]=z[2]  m[11]=z[3]
        
        local sensor=sim.createProximitySensor(sim.proximitysensor_ray_subtype,16,1,{3,3,2,2,1,1,0,0},{0,2000,0.01,0.01,0.01,0.01,0,0,0,0,0,0,0.01,0,0})
        sim.setObjectMatrix(sensor,sim.handle_world,m)
        r,d,pt,o,n=sim.checkProximitySensor(sensor,coll)
        sim.removeObjects({sensor})
        sim.destroyCollection(coll)
        if r>0 then
            pt=sim.multiplyVector(m,pt)
            m[4]=0
            m[8]=0
            m[12]=0
            n=sim.multiplyVector(m,n)
            sim.addDrawingObjectItem(pts,pt)
            sim.addDrawingObjectItem(lines,{pt[1],pt[2],pt[3],pt[1]+n[1]*0.1,pt[2]+n[2]*0.1,pt[3]+n[3]*0.1})
            
            simUI.setLabelText(ui,2,string.format("Position: (%.3f, %.3f, %.3f)",pt[1],pt[2],pt[3]))
            simUI.setLabelText(ui,3,string.format("Normal vector: (%.3f, %.3f, %.3f)",n[1],n[2],n[3]))
            
            local c=sim.getInt32Param(sim.intparam_mouseclickcounterdown)
            if c~=clickCnt and createDummies then
                clickCnt=c
                local h=sim.createDummy(0.02)
                sim.setObjectColor(h,0,sim.colorcomponent_ambient_diffuse,{0,1,0})
                local m=sim.buildIdentityMatrix()
                m[4]=pt[1]
                m[8]=pt[2]
                m[12]=pt[3]
                if n[1]<0.99 then
                    local z=Vector3(n)
                    local x=Vector3({1,0,0})
                    local y=z:cross(x):normalized()
                    local x=y:cross(z)
                    m[1]=x[1]  m[5]=x[2]  m[9]=x[3]
                    m[2]=y[1]  m[6]=y[2]  m[10]=y[3]
                    m[3]=z[1]  m[7]=z[2]  m[11]=z[3]
                else
                    m[1]=0  m[5]=1  m[9]=0
                    m[2]=0  m[6]=0  m[10]=1
                    m[3]=1  m[7]=0  m[11]=0
                end
                sim.setObjectMatrix(h,sim.handle_world,m)
            end
        end
    end
    clickCnt=sim.getInt32Param(sim.intparam_mouseclickcounterdown)
end

function sysCall_beforeSimulation()
    hideDlg()
end

function sysCall_afterSimulation()
    showDlg()
end

function sysCall_cleanup()
    hideDlg()
end

function sysCall_beforeInstanceSwitch()
    hideDlg()
end

function sysCall_afterInstanceSwitch()
    showDlg()
end

function showDlg()
    if not ui then
        pts=sim.addDrawingObject(sim.drawing_spherepts,0.01,0,-1,1,{0,1,0})
        lines=sim.addDrawingObject(sim.drawing_lines,2,0,-1,1,{0,1,0})
        clickCnt=sim.getInt32Param(sim.intparam_mouseclickcounterdown)
        local pos='position="-50,50" placement="relative"'
        if uiPos then
            pos='position="'..uiPos[1]..','..uiPos[2]..'" placement="absolute"'
        end
        local xml ='<ui title="Point sampler" activate="false" closeable="true" on-close="close_callback" '..pos..[[>
            <checkbox checked="false" text="Create a dummy with each click" on-change="createDummy_callback" id="1" />
            <label text="Position:" id="2"/>
            <label text="Normal vector:" id="3"/>
        </ui>]]
        ui=simUI.create(xml)
        simUI.setCheckboxValue(ui,1,createDummies and 2 or 0) 
    end
end

function hideDlg()
    if ui then
        uiPos={}
        uiPos[1],uiPos[2]=simUI.getPosition(ui)
        simUI.destroy(ui)
        ui=nil
        sim.removeDrawingObject(pts)
        sim.removeDrawingObject(lines)
    end
end

function createDummy_callback(ui,id,v)
    createDummies=not createDummies
end

function close_callback()
    leaveNow=true
end

