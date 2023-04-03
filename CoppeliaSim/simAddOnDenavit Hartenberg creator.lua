function sysCall_info()
    return {autoStart=false,menu='Denavit-Hartenberg\nCreator'}
end

function sysCall_addOnScriptSuspend()
    return {cmd='cleanup'}
end

function sysCall_init()
    sim.addLog(sim.verbosity_scriptinfos,"This tool allows to create joints with the Denavit-Hartenberg notation. Simply select an object in the scene on top of which you wish to create a joint, then adjust the D-H parameters in the dialog.")
    d=0.05
    theta=math.pi/2
    a=0.1
    alpha=math.pi/4
end

function showDlg()
    if not ui then
        local pos='position="-50,50" placement="relative"'
        if uiPos then
            pos='position="'..uiPos[1]..','..uiPos[2]..'" placement="absolute"'
        end
        local xml ='<ui title="DH joint creator" activate="false" on-close="close_callback" closeable="true" layout="form" '..pos..[[>
                <label text="d"/>
                <edit value="" id="1" on-editing-finished="d_callback"/>
                <label text="theta"/>
                <edit value="" id="2" on-editing-finished="theta_callback"/>
                <label text="a"/>
                <edit value="" id="3" on-editing-finished="a_callback"/>
                <label text="alpha"/>
                <edit value="" id="4" on-editing-finished="alpha_callback"/>
                <button text="Create revolute joint" on-click="rev_callback"/>
                <button text="Create prismatic joint" on-click="prism_callback"/>
        </ui>]]
        ui=simUI.create(xml)
        simUI.setEditValue(ui,1,string.format("%.4f",d))
        simUI.setEditValue(ui,2,string.format("%.1f",theta*180/math.pi))
        simUI.setEditValue(ui,3,string.format("%.4f",a))
        simUI.setEditValue(ui,4,string.format("%.1f",alpha*180/math.pi))
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

function d_callback(ui,id,v)
    v=tonumber(v)
    if v then
        if v<0 then v=0 end
        if v>1 then v=1 end
        d=v
    end
    simUI.setEditValue(ui,1,string.format("%.4f",d))
end

function theta_callback(ui,id,v)
    v=tonumber(v)
    if v then
        if v<-180 then v=-180 end
        if v>180 then v=180 end
        theta=v*math.pi/180
    end
    simUI.setEditValue(ui,2,string.format("%.1f",theta*180/math.pi))
 end

function a_callback(ui,id,v)
    v=tonumber(v)
    if v then
        if v<0 then v=0 end
        if v>1 then v=1 end
        a=v
    end
    simUI.setEditValue(ui,3,string.format("%.4f",a))
end

function alpha_callback(ui,id,v)
    v=tonumber(v)
    if v then
        if v<-180 then v=-180 end
        if v>180 then v=180 end
        alpha=v*math.pi/180
    end
    simUI.setEditValue(ui,4,string.format("%.1f",alpha*180/math.pi))
end

function rev_callback()
    buildJoint(true)
end

function prism_callback()
    buildJoint(false)
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

function sysCall_nonSimulation()
    if leaveNow then
        return {cmd='cleanup'}
    end
    local s=sim.getObjectSelection()
    local show=(s and #s==1 )
    if show then
        showDlg()
    else
        hideDlg()
    end
end

function buildJoint(revoluteJoint)
    local selectedObjects=sim.getObjectSelection()
    local dhParams={d,theta,a,alpha}
    
    local objMatr=sim.getObjectMatrix(selectedObjects[1],-1)
    if sim.getObjectType(selectedObjects[1])==sim.object_joint_type then
        objMatr=sim.multiplyMatrices(objMatr,sim.getJointMatrix(selectedObjects[1])) -- don't forget the joint's intrinsic transformation
    end
    local m1=sim.buildMatrix({0,0,dhParams[1]},{0,0,dhParams[2]})
    local m2=sim.buildMatrix({dhParams[3],0,0},{dhParams[4],0,0})
    local m=sim.multiplyMatrices(m1,m2)
    objMatr=sim.multiplyMatrices(objMatr,m)
    local newJoint=-1
    if revoluteJoint then
        newJoint=sim.createJoint(sim.joint_revolute_subtype,sim.jointmode_force,0)
    else
        newJoint=sim.createJoint(sim.joint_prismatic_subtype,sim.jointmode_force,0)
    end
    sim.setObjectMatrix(newJoint,-1,objMatr)
    sim.setObjectParent(newJoint,selectedObjects[1],true)
    sim.removeObjectFromSelection(sim.handle_all,-1)
    sim.addObjectToSelection(sim.handle_single,newJoint)
end
