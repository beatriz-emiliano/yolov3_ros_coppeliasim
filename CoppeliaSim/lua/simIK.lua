local simIK={}

function _S.simIKLoopThroughAltConfigSolutions(ikEnvironment,jointHandles,desiredPose,confS,x,index)
    if index>#jointHandles then
        return {sim.unpackDoubleTable(sim.packDoubleTable(confS))} -- copy the table
    else
        local c={}
        for i=1,#jointHandles,1 do
            c[i]=confS[i]
        end
        local solutions={}
        while c[index]<=x[index][2] do
            local s=_S.simIKLoopThroughAltConfigSolutions(ikEnvironment,jointHandles,desiredPose,c,x,index+1,tipHandle)
            for i=1,#s,1 do
                solutions[#solutions+1]=s[i]
            end
            c[index]=c[index]+math.pi*2
        end
        return solutions
    end
end

function simIK.getAlternateConfigs(...)
    local ikEnvironment,jointHandles,lowLimits,ranges=checkargs({{type='int'},{type='table',size='1..*',item_type='int'},{type='table',size='1..*',item_type='float',default=NIL,nullable=true},{type='table',size='1..*',item_type='float',default=NIL,nullable=true}},...)
    local dof=#jointHandles
    if (lowLimits and dof~=#lowLimits) or (ranges and dof~=#ranges) then
        error("Bad table size.")
    end

    local lb=sim.setThreadAutomaticSwitch(false)

    local retVal={}
    local ikEnv=simIK.duplicateEnvironment(ikEnvironment)
    local x={}
    local confS={}
    local err=false
    local inputConfig={}
    for i=1,#jointHandles,1 do
        inputConfig[i]=simIK.getJointPosition(ikEnv,jointHandles[i])
        local c,interv=simIK.getJointInterval(ikEnv,jointHandles[i])
        local t=simIK.getJointType(ikEnv,jointHandles[i])
        local sp=simIK.getJointScrewPitch(ikEnv,jointHandles[i])
        if t==simIK.jointtype_revolute and not c then
            if sp==0 then
                if inputConfig[i]-math.pi*2>=interv[1] or inputConfig[i]+math.pi*2<=interv[1]+interv[2] then
                    -- We use the low and range values from the joint's settings
                    local y=inputConfig[i]
                    while y-math.pi*2>=interv[1] do
                        y=y-math.pi*2
                    end
                    x[i]={y,interv[1]+interv[2]}
                end
            end
        end
        if x[i] then
            if lowLimits and ranges then
                -- the user specified low and range values. Use those instead:
                local l=lowLimits[i]
                local r=ranges[i]
                if r~=0 then
                    if r>0 then
                        if l<interv[1] then
                            -- correct for user bad input
                            r=r-(interv[1]-l)
                            l=interv[1] 
                        end
                        if l>interv[1]+interv[2] then
                            -- bad user input. No alternative position for this joint
                            x[i]={inputConfig[i],inputConfig[i]}
                            err=true
                        else
                            if l+r>interv[1]+interv[2] then
                                -- correct for user bad input
                                r=interv[1]+interv[2]-l
                            end
                            if inputConfig[i]-math.pi*2>=l or inputConfig[i]+math.pi*2<=l+r then
                                local y=inputConfig[i]
                                while y<l do
                                    y=y+math.pi*2
                                end
                                while y-math.pi*2>=l do
                                    y=y-math.pi*2
                                end
                                x[i]={y,l+r}
                            else
                                -- no alternative position for this joint
                                x[i]={inputConfig[i],inputConfig[i]}
                                err=(inputConfig[i]<l) or (inputConfig[i]>l+r)
                            end
                        end
                    else
                        r=-r
                        l=inputConfig[i]-r*0.5
                        if l<x[i][1] then
                            l=x[i][1]
                        end
                        local u=inputConfig[i]+r*0.5
                        if u>x[i][2] then
                            u=x[i][2]
                        end
                        x[i]={l,u}
                    end
                end
            end
        else
            -- there's no alternative position for this joint
            x[i]={inputConfig[i],inputConfig[i]}
        end
        confS[i]=x[i][1]
    end
    local configs={}
    if not err then
        for i=1,#jointHandles,1 do
            simIK.setJointPosition(ikEnv,jointHandles[i],inputConfig[i])
        end
        local desiredPose=0
        configs=_S.simIKLoopThroughAltConfigSolutions(ikEnv,jointHandles,desiredPose,confS,x,1)
    end
    simIK.eraseEnvironment(ikEnv)
    sim.setThreadAutomaticSwitch(lb)
    
    if next(configs)~=nil then
        configs=Matrix:fromtable(configs)
        configs=configs:data()
    end
    return configs
end

function simIK.applySceneToIkEnvironment(...)
    local ikEnv,ikGroup=checkargs({{type='int'},{type='int'}},...)

    local lb=sim.setThreadAutomaticSwitch(false)
    
    local groupData=_S.ikEnvs[ikEnv].ikGroups[ikGroup]
    if groupData.notYetApplied then
        -- Joint dependencies can go across IK elements. So apply them the first time here:
        for k,v in pairs(groupData.joints) do
            if sim.getJointMode(k)==sim.jointmode_dependent and sim.getJointType(k)~=sim.joint_spherical_subtype then
                local m,o,f=sim.getJointDependency(k)
                if m~=-1 then
                    if groupData.joints[m] then
                        simIK.setJointMode(ikEnv,v,simIK.jointmode_dependent)
                        simIK.setJointDependency(ikEnv,v,groupData.joints[m],o,f)
                    else
                        simIK.setJointMode(ikEnv,v,simIK.jointmode_passive)
                    end
                end
            end
        end
        groupData.notYetApplied=nil
    end
    for k,v in pairs(groupData.joints) do
        if sim.getJointType(k)==sim.joint_spherical_subtype then
            simIK.setSphericalJointMatrix(ikEnv,v,sim.getJointMatrix(k))
        else
            simIK.setJointPosition(ikEnv,v,sim.getJointPosition(k))
        end
    end
    for i=1,#groupData.targetTipBaseTriplets,1 do
        simIK.setObjectMatrix(ikEnv,groupData.targetTipBaseTriplets[i][4],groupData.targetTipBaseTriplets[i][6],sim.getObjectMatrix(groupData.targetTipBaseTriplets[i][1],groupData.targetTipBaseTriplets[i][3]))
        simIK.setObjectMatrix(ikEnv,groupData.targetTipBaseTriplets[i][5],groupData.targetTipBaseTriplets[i][6],sim.getObjectMatrix(groupData.targetTipBaseTriplets[i][2],groupData.targetTipBaseTriplets[i][3]))
    end
    sim.setThreadAutomaticSwitch(lb)
end

function simIK.applyIkEnvironmentToScene(...)
    local ikEnv,ikGroup,applyOnlyWhenSuccessful=checkargs({{type='int'},{type='int'},{type='bool',default=false}},...)

    local lb=sim.setThreadAutomaticSwitch(false)
    
    simIK.applySceneToIkEnvironment(ikEnv,ikGroup)
    local groupData=_S.ikEnvs[ikEnv].ikGroups[ikGroup]
    local res=simIK.handleIkGroup(ikEnv,ikGroup)
    if res==simIK.result_success or not applyOnlyWhenSuccessful then
        for k,v in pairs(groupData.joints) do
            if not groupData.passiveJoints[k] then
                if sim.getJointType(k)==sim.joint_spherical_subtype then
                    if sim.getJointMode(k)~=sim.jointmode_force then
                        sim.setSphericalJointMatrix(k,simIK.getJointMatrix(ikEnv,v))
                    end
                else
                    if sim.getJointMode(k)==sim.jointmode_force and sim.isDynamicallyEnabled(k) then
                        sim.setJointTargetPosition(k,simIK.getJointPosition(ikEnv,v))
                    else    
                        sim.setJointPosition(k,simIK.getJointPosition(ikEnv,v))
                    end
                end
            end
        end
    end
    sim.setThreadAutomaticSwitch(lb)
    return res
end

function simIK.addIkElementFromScene(...)
    local ikEnv,ikGroup,simBase,simTip,simTarget,constraints=checkargs({{type='int'},{type='int'},{type='int'},{type='int'},{type='int'},{type='int'}},...)
    
    local lb=sim.setThreadAutomaticSwitch(false)
    
    if not _S.ikEnvs then
        _S.ikEnvs={}
    end
    if not _S.ikEnvs[ikEnv] then
        _S.ikEnvs[ikEnv]={}
    end
    if not _S.ikEnvs[ikEnv].ikGroups then
        _S.ikEnvs[ikEnv].ikGroups={}
        _S.ikEnvs[ikEnv].allObjects={}
    end
    local groupData=_S.ikEnvs[ikEnv].ikGroups[ikGroup]
    -- allObjects, i.e. the mapping, need to be scoped by ik env, and not ik group,
    -- otherwise we may have duplicates:
    local allObjects=_S.ikEnvs[ikEnv].allObjects
    if not groupData then
        groupData={}
        groupData.passiveJoints={}
        groupData.joints={}
        groupData.bases={}
        groupData.targets={}
        groupData.targetTipBaseTriplets={}
        groupData.notYetApplied=true
        _S.ikEnvs[ikEnv].ikGroups[ikGroup]=groupData
    end
    local ikBase=-1
    if simBase~=-1 then
        ikBase=allObjects[simBase] -- maybe already there
        if not ikBase then
            ikBase=simIK.createDummy(ikEnv) --name not really needed in this context-- ,sim.getObjectAlias(simBase,3))
            simIK.setObjectMatrix(ikEnv,ikBase,-1,sim.getObjectMatrix(simBase,-1))
            allObjects[simBase]=ikBase
        end
        groupData.bases[simBase]=ikBase
    end
    
    local ikTip=allObjects[simTip] -- maybe already there
    if not ikTip then
        ikTip=simIK.createDummy(ikEnv) --name not really needed in this context-- ,sim.getObjectAlias(simTip,3))
        simIK.setObjectMatrix(ikEnv,ikTip,-1,sim.getObjectMatrix(simTip,-1))
        allObjects[simTip]=ikTip
    end

    local ikTarget=allObjects[simTarget] -- maybe already there
    if not ikTarget then
        ikTarget=simIK.createDummy(ikEnv) --name not really needed in this context-- ,sim.getObjectAlias(simTarget,3))
        simIK.setObjectMatrix(ikEnv,ikTarget,-1,sim.getObjectMatrix(simTarget,-1))
        allObjects[simTarget]=ikTarget
    end
    groupData.targets[simTarget]=ikTarget
    groupData.targetTipBaseTriplets[#groupData.targetTipBaseTriplets+1]={simTarget,simTip,simBase,ikTarget,ikTip,ikBase}
    
    simIK.setLinkedDummy(ikEnv,ikTip,ikTarget)

    local simPrevIterator=simTip
    local simIterator=sim.getObjectParent(simPrevIterator)
    local ikPrevIterator=ikTip
    local ikIterator=-1
    while simIterator~=simBase do
        if allObjects[simIterator] then
            -- object already added, and parenting to child done
            ikIterator=allObjects[simIterator]
        else
            if sim.getObjectType(simIterator)~=sim.object_joint_type then
                ikIterator=simIK.createDummy(ikEnv) --name not really needed in this context-- ,sim.getObjectAlias(simIterator,3))
            else
                local t=sim.getJointType(simIterator)
                ikIterator=simIK.createJoint(ikEnv,t) --name not really needed in this context-- ,sim.getObjectAlias(simIterator,3))
                local c,interv=sim.getJointInterval(simIterator)
                simIK.setJointInterval(ikEnv,ikIterator,c,interv)
                local sp=sim.getObjectFloatParam(simIterator,sim.jointfloatparam_screw_pitch)
                simIK.setJointScrewPitch(ikEnv,ikIterator,sp)
                local sp=sim.getObjectFloatParam(simIterator,sim.jointfloatparam_step_size)
                simIK.setJointMaxStepSize(ikEnv,ikIterator,sp)
                local sp=sim.getObjectFloatParam(simIterator,sim.jointfloatparam_ik_weight)
                simIK.setJointIkWeight(ikEnv,ikIterator,sp)
                if t==sim.joint_spherical_subtype then
                    simIK.setSphericalJointMatrix(ikEnv,ikIterator,sim.getJointMatrix(simIterator))
                else
                    simIK.setJointPosition(ikEnv,ikIterator,sim.getJointPosition(simIterator))
                end
            end
            allObjects[simIterator]=ikIterator
            simIK.setObjectMatrix(ikEnv,ikIterator,-1,sim.getObjectMatrix(simIterator,-1))
        end 
        if sim.getObjectType(simIterator)==sim.object_joint_type then
            groupData.joints[simIterator]=ikIterator
        end
        simIK.setObjectParent(ikEnv,ikPrevIterator,ikIterator)
        simPrevIterator=simIterator
        ikPrevIterator=ikIterator
        simIterator=sim.getObjectParent(simIterator)
        ikIterator=simIK.getObjectParent(ikEnv,ikIterator)
    end
    simIK.setObjectParent(ikEnv,ikPrevIterator,ikBase)
    simIK.setObjectParent(ikEnv,ikTarget,ikBase)

    local ikElement=simIK.addIkElement(ikEnv,ikGroup,ikTip)
    simIK.setIkElementBase(ikEnv,ikGroup,ikElement,ikBase,-1)
    simIK.setIkElementConstraints(ikEnv,ikGroup,ikElement,constraints)
    sim.setThreadAutomaticSwitch(lb)
    return ikElement,allObjects
end

function simIK.eraseEnvironment(...)
    local ikEnv=checkargs({{type='int'}},...)
    
    local lb=sim.setThreadAutomaticSwitch(false)
    
    if _S.ikEnvs then
        _S.ikEnvs[ikEnv]=nil
    end
    simIK._eraseEnvironment(ikEnv)
    sim.setThreadAutomaticSwitch(lb)
end

function simIK.getConfigForTipPose(...)
    -- deprecated
    local ikEnv,ikGroup,joints,thresholdDist,maxTime,metric,callback,auxData,jointOptions,lowLimits,ranges=checkargs({{type='int'},{type='int'},{type='table',size='1..*',item_type='int'},{type='float',default=0.1},{type='float',default=0.5},{type='table',size=4,item_type='float',default={1,1,1,0.1},nullable=true},{type='any',default=NIL,nullable=true},{type='any',default=NIL,nullable=true},{type='table',size='1..*',item_type='int',default=NIL,nullable=true},{type='table',size='1..*',item_type='float',default=NIL,nullable=true},{type='table',size='1..*',item_type='float',default=NIL,nullable=true}},...)
    local dof=#joints

    if (jointOptions and dof~=#jointOptions) or (lowLimits and dof~=#lowLimits) or (ranges and dof~=#ranges) then
        error("Bad table size.")
    end

    local lb=sim.setThreadAutomaticSwitch(false)

    local env=simIK.duplicateEnvironment(ikEnv)
    if metric==nil then metric={1,1,1,0.1} end
    if jointOptions==nil then jointOptions={} end
    if lowLimits==nil then lowLimits={} end
    if ranges==nil then ranges={} end
    local retVal
    if type(callback)=='string' then
        -- deprecated
        retVal=simIK._getConfigForTipPose(env,ikGroup,joints,thresholdDist,maxTime,metric,callback,auxData,jointOptions,lowLimits,ranges)
    else
        if maxTime<0 then 
            maxTime=-maxTime/1000 -- probably calling the function the old way 
        end
        if maxTime>2 then maxTime=2 end
        function __cb(config)
            return callback(config,auxData)
        end
        local funcNm,t
        if callback then
            funcNm='__cb'
            t=sim.getScriptAttribute(sim.handle_self,sim.scriptattribute_scripthandle)
        end
        retVal=simIK._getConfigForTipPose(env,ikGroup,joints,thresholdDist,-maxTime*1000,metric,funcNm,t,jointOptions,lowLimits,ranges)
    end
    simIK.eraseEnvironment(env)
    sim.setThreadAutomaticSwitch(lb)
    return retVal
end

function simIK.findConfig(...)
    local ikEnv,ikGroup,joints,thresholdDist,maxTime,metric,callback,auxData=checkargs({{type='int'},{type='int'},{type='table',size='1..*',item_type='int'},{type='float',default=0.1},{type='float',default=0.5},{type='table',size=4,item_type='float',default={1,1,1,0.1},nullable=true},{type='any',default=NIL,nullable=true},{type='any',default=NIL,nullable=true}},...)
    local dof=#joints
    local lb=sim.setThreadAutomaticSwitch(false)

    --local env=simIK.duplicateEnvironment(ikEnv)
    local env=ikEnv
    if metric==nil then metric={1,1,1,0.1} end
    function __cb(config)
        if type(callback)=='string' then
            return _G[callback](config,auxData)
        else
            return callback(config,auxData)
        end
    end
    local funcNm,t
    if callback then
        funcNm='__cb'
        t=sim.getScriptAttribute(sim.handle_self,sim.scriptattribute_scripthandle)
    end
    local retVal=simIK._findConfig(env,ikGroup,joints,thresholdDist,maxTime*1000,metric,funcNm,t)
    --simIK.eraseEnvironment(env)
    sim.setThreadAutomaticSwitch(lb)
    return retVal
end

function simIK.generatePath(...)
    local ikEnv,ikGroup,ikJoints,tip,ptCnt,callback,auxData=checkargs({{type='int'},{type='int'},{type='table',size='1..*',item_type='int'},{type='int'},{type='int'},{type='any',default=NIL,nullable=true},{type='any',default=NIL}},...)

    local lb=sim.setThreadAutomaticSwitch(false)

    local env=simIK.duplicateEnvironment(ikEnv)
    local targetHandle=simIK.getLinkedDummy(env,tip)
    local startMatrix=simIK.getObjectMatrix(env,tip,-1)
    local goalMatrix=simIK.getObjectMatrix(env,targetHandle,-1)
    local retPath={{}}
    for i=1,#ikJoints,1 do
        retPath[1][i]=simIK.getJointPosition(env,ikJoints[i])
    end
    local success=true
    if callback then
        if type(callback)=='string' then
            success=_G[callback](retPath[1])
        else
            success=callback(retPath[1])
        end
    end
    if success then
        for j=1,ptCnt-1,1 do
            local t=j/(ptCnt-1)
            local m=sim.interpolateMatrices(startMatrix,goalMatrix,t)
            simIK.setObjectMatrix(env,targetHandle,-1,m)
            success=simIK.handleIkGroup(env,ikGroup)==simIK.result_success
            if not success then
                break
            end
            retPath[j+1]={}
            for i=1,#ikJoints,1 do
                retPath[j+1][i]=simIK.getJointPosition(env,ikJoints[i])
            end
            if callback then
                if type(callback)=='string' then
                    success=_G[callback](retPath[j+1])
                else
                    success=callback(retPath[j+1])
                end
            end
            if not success then
                break
            end
        end
    end
    simIK.eraseEnvironment(env)
    sim.setThreadAutomaticSwitch(lb)
    if not success then
        retPath={}
    else
        retPath=Matrix:fromtable(retPath)
        retPath=retPath:data()
    end
    return retPath
end

function simIK.getObjectPose(...)
    local ikEnv,obj,relObj=checkargs({{type='int'},{type='int'},{type='int'}},...)
    local pos,quat=simIK.getObjectTransformation(ikEnv,obj,relObj)
    return {pos[1],pos[2],pos[3],quat[1],quat[2],quat[3],quat[4]}
end

function simIK.setObjectPose(...)
    local ikEnv,obj,relObj,pose=checkargs({{type='int'},{type='int'},{type='int'},{type='table',size=7,item_type='float'}},...)
    simIK.setObjectTransformation(ikEnv,obj,relObj,{pose[1],pose[2],pose[3]},{pose[4],pose[5],pose[6],pose[7]})
end

function simIK.init()
    -- can only be executed once sim.* functions were initialized
    sim.registerScriptFunction('simIK.getAlternateConfigs@simIK','float[] configs=simIK.getAlternateConfigs(int environmentHandle,int[] jointHandles,float[] lowLimits=nil,float[] ranges=nil)')
    sim.registerScriptFunction('simIK.addIkElementFromScene@simIK','int ikElement,map simToIkObjectMap=simIK.addIkElementFromScene(int environmentHandle,int ikGroup,int baseHandle,int tipHandle,int targetHandle,int constraints)')
    sim.registerScriptFunction('simIK.applySceneToIkEnvironment@simIK','simIK.applySceneToIkEnvironment(int environmentHandle,int ikGroup)')
    sim.registerScriptFunction('simIK.applyIkEnvironmentToScene@simIK','int result=simIK.applyIkEnvironmentToScene(int environmentHandle,int ikGroup,bool applyOnlyWhenSuccessful=false)')
    sim.registerScriptFunction('simIK.eraseEnvironment@simIK','simIK.eraseEnvironment(int environmentHandle)')
    sim.registerScriptFunction('simIK.findConfig@simIK','float[] jointPositions=simIK.findConfig(int environmentHandle,int ikGroupHandle,int[] jointHandles,float thresholdDist=0.1,float maxTime=0.5,float[4] metric={1,1,1,0.1},func validationCallback=nil,any auxData=nil)')
    sim.registerScriptFunction('simIK.generatePath@simIK','float[] path=simIK.generatePath(int environmentHandle,int ikGroupHandle,int[] jointHandles,int tipHandle,int pathPointCount,func validationCallback=nil,any auxData=nil)')
    sim.registerScriptFunction('simIK.getObjectPose@simIK','float[7] pose=simIK.getObjectPose(int environmentHandle,int objectHandle,int relativeToObjectHandle)')
    sim.registerScriptFunction('simIK.setObjectPose@simIK','simIK.setObjectPose(int environmentHandle,int objectHandle,int relativeToObjectHandle,float[7] pose)')
    simIK.init=nil
end

sim.registerScriptFuncHook('sysCall_init','simIK.init',true)

return simIK
