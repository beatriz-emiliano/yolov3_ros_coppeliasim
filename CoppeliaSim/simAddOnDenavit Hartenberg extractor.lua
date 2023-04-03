function sysCall_info()
    return {autoStart=false,menu='Denavit-Hartenberg\nExtractor'}
end

function sysCall_addOnScriptSuspend()
    return {cmd='cleanup'}
end

function sysCall_init()
    sim.addLog(sim.verbosity_scriptinfos,"This tool allows to extract the Denavit-Hartenberg parameters that define the joint poses relative to each other. Simply select the first joint in a kinematic chain.")
    auxConsoleHandle=-1
end

function sysCall_beforeSimulation()
    closeConsole()
end

function sysCall_cleanup()
    closeConsole()
end

function sysCall_beforeInstanceSwitch()
    closeConsole()
end

function sysCall_nonSimulation()
    local selectedObjects=sim.getObjectSelection()
    if selectedObjects and (#selectedObjects==1) and sim.getObjectType(selectedObjects[1])==sim.object_joint_type then
        if previousSelectedObject~=selectedObjects[1] then
            closeConsole()
            previousSelectedObject=selectedObjects[1]
            auxConsoleHandle=displayDhParams(previousSelectedObject)
        end
    else
        closeConsole()
    end
end

function closeConsole()
    if auxConsoleHandle~=-1 then
        sim.auxiliaryConsoleClose(auxConsoleHandle)
        auxConsoleHandle=-1
    end
    previousSelectedObject=-1
end

getScalarProduct=function(u,v)
    return u[1]*v[1]+u[2]*v[2]+u[3]*v[3]
end

getCrossProduct=function(u,v)
    return {u[2]*v[3]-u[3]*v[2],u[3]*v[1]-u[1]*v[3],u[1]*v[2]-u[2]*v[1]}
end

getDistanceVector=function(p1,p2)
    return {p2[1]-p1[1],p2[2]-p1[2],p2[3]-p1[3]}
end

getScalarMultipliedVector=function(v,s)
    return {v[1]*s,v[2]*s,v[3]*s}
end

getNormalizedVector=function(v)
    local l=math.sqrt(v[1]*v[1]+v[2]*v[2]+v[3]*v[3])
    return {v[1]/l,v[2]/l,v[3]/l}
end

getVectorLength=function(v)
    return math.sqrt(v[1]*v[1]+v[2]*v[2]+v[3]*v[3])
end

getMinDist=function(lp,lv)
    local retT0=0
    local retT1=0
    if math.abs(lv[3])>0.9999 then
        -- Lines are parallel
        retT1=-lp[3]/lv[3]
    else
        -- Lines are NOT parallel
        local a=lp[1]*lv[1]+lp[2]*lv[2]+lp[3]*lv[3]
        local b=lp[3]+lv[3]-lv[1]*lv[1]-lv[2]*lv[2]-lv[3]*lv[3]
        if math.abs(b)>0.00000001 then
            -- Lines do NOT intersect
            retT1=a/b
            retT0=lp[3]+lv[3]*retT1
        else
            -- Lines intersect
            retT1=-lp[1]/lv[1]
            retT0=lp[3]+lv[3]*retT1
        end
    end
    return retT0,retT1
end

getAllFirstJointsInTree=function(obj)
    local output={}
    local toExplore={obj}
    while #toExplore>0 do
        local h=toExplore[1]
        table.remove(toExplore,1)
        if (sim.getObjectType(h)==sim.object_joint_type) and (h~=obj) then
            output[#output+1]=h
        else
            -- Explore its children:
            local index=0
            while true do
                local c=sim.getObjectChild(h,index)
                if c==-1 then
                    break
                end
                toExplore[#toExplore+1]=c
                index=index+1
            end
        end
    end
    return output
end

computeDhParams=function(mPreviousJoint,currentJoint)
    -- Now extract the DH parameters:
    local m2=sim.getObjectMatrix(currentJoint,-1)
    local mPreviousJointInv=sim.copyTable(mPreviousJoint)
    sim.invertMatrix(mPreviousJointInv)
    local m=sim.multiplyMatrices(mPreviousJointInv,m2)
    local lp={m[4],m[8],m[12]}
    local lv={m[3],m[7],m[11]}
    local d,theta,r,alpha,newLocalFrame
    if math.abs(lv[3])>0.9999 then
        -- The 2 axes are parallel
        d=0
        alpha=0
        r=math.sqrt(lp[1]*lp[1]+lp[2]*lp[2])
        if r<0.00001 then
            -- the two axes are coincident
            theta=0 
        else
            -- the two axes are NOT coincident
            theta=math.atan2(lp[2]/r,lp[1]/r)
        end
    else
        -- The 2 axes are NOT parallel
        local t0,t1=getMinDist(lp,lv)
        local pt1={lp[1]+lv[1]*t1,lp[2]+lv[2]*t1,lp[3]+lv[3]*t1}
        local dr={pt1[1],pt1[2],pt1[3]-t0}
        r=getVectorLength(dr)
        d=pt1[3]
        if r<0.00001 then
            -- the two axes intersect
            -- Find new new x axis:
            local nx=getCrossProduct({0,0,1},lv)
            nx=getNormalizedVector(nx)
            theta=math.atan2(nx[2],nx[1])
        else
            -- the two axes do not intersect
            theta=math.atan2(pt1[2]/r,pt1[1]/r)
        end
        local mp=sim.buildMatrix({0,0,0},{0,0,theta})
        local c1={0,0,1}
        local c2=getScalarProduct(c1,lv)
        alpha=math.acos(c2)
        if getScalarProduct(getCrossProduct(c1,lv),{mp[1],mp[5],mp[9]})<0 then
            alpha=-alpha
        end
    end
    local m1=sim.buildMatrix({0,0,d},{0,0,theta})
    local m2=sim.buildMatrix({r,0,0},{alpha,0,0})
    local newLocalFrame=sim.multiplyMatrices(m1,m2)
    return d,theta,r,alpha,sim.multiplyMatrices(mPreviousJoint,newLocalFrame)
end

displayDhParams=function(firstJoint)
    local consoleHandle=sim.auxiliaryConsoleOpen('Denavit-Hartenberg parameters',100,4,{100,100},{450,800})

    local toExplore_objs=getAllFirstJointsInTree(firstJoint)
    local toExplore_prevMatrix={}
    local toExplore_prevName={}
    for i=1,#toExplore_objs,1 do
        toExplore_prevMatrix[#toExplore_prevMatrix+1]=sim.getObjectMatrix(firstJoint,-1)
        toExplore_prevName[#toExplore_prevName+1]=sim.getObjectAlias(firstJoint,1)
    end
    local somethingWasDisplayed=false

    while #toExplore_objs>0 do
        local h=toExplore_objs[1]
        table.remove(toExplore_objs,1)
        local prevMatr={}
        for i=1,12,1 do
            prevMatr[#prevMatr+1]=toExplore_prevMatrix[1][i]
        end
        table.remove(toExplore_prevMatrix,1)
        local prevName=toExplore_prevName[1]
        table.remove(toExplore_prevName,1)
        
        local attachedJoints={}
        if sim.getObjectType(h)==sim.object_joint_type then
            attachedJoints[1]=h
        else
            attachedJoints=getAllFirstJointsInTree(h)
        end

        for i=1,#attachedJoints,1 do
            somethingWasDisplayed=true
            local d,theta,r,alpha,lastJointMatrix=computeDhParams(prevMatr,attachedJoints[i])
            local txt="Between '"..prevName.."' and '"..sim.getObjectAlias(attachedJoints[i],1).."':\n"
            txt=txt.."    d="..string.format("%.4f\n",d)
            txt=txt.."    theta="..string.format("%03.1f\n",theta*180/math.pi)
            txt=txt.."    a="..string.format("%.4f\n",r)
            txt=txt.."    alpha="..string.format("%03.1f\n\n",alpha*180/math.pi)
            sim.auxiliaryConsolePrint(consoleHandle,txt)
            local newAttachedJoints=getAllFirstJointsInTree(attachedJoints[i])
            for j=1,#newAttachedJoints,1 do
                toExplore_objs[#toExplore_objs+1]=newAttachedJoints[j]
                local matr={}
                for k=1,12,1 do
                    matr[k]=lastJointMatrix[k]
                end
                toExplore_prevMatrix[#toExplore_prevMatrix+1]=matr
                toExplore_prevName[#toExplore_prevName+1]=sim.getObjectAlias(attachedJoints[i],1)
            end
        end
    end
    if not somethingWasDisplayed then
        sim.auxiliaryConsoleClose(consoleHandle)
        consoleHandle=-1
    end
    return consoleHandle
end
