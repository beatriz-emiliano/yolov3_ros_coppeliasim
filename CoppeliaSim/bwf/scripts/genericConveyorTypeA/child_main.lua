function updateConveyorForMotion(dt)
    sim.setObjectFloatParam(model.specHandles.middleParts[2],sim.shapefloatparam_texture_y,model.totShift)

    if model.specHandles.endParts[1]~=-1 then
        sim.setObjectFloatParam(model.specHandles.endParts[1],sim.shapefloatparam_texture_y,model.length*0.5+0.041574*model.height/0.2+model.totShift)
        sim.setObjectFloatParam(model.specHandles.endParts[2],sim.shapefloatparam_texture_y,-model.length*0.5-0.041574*model.height/0.2+model.totShift)
        local a=sim.getJointPosition(model.specHandles.rotJoints[1])
        sim.setJointPosition(model.specHandles.rotJoints[1],a-model.beltVelocity*dt*2/model.height)
        sim.setJointPosition(model.specHandles.rotJoints[2],a-model.beltVelocity*dt*2/model.height)
    end
    
    local relativeLinearVelocity={0,model.beltVelocity,0}
    
    sim.resetDynamicObject(model.specHandles.middleParts[3])
    local m=sim.getObjectMatrix(model.specHandles.middleParts[3],-1)
    m[4]=0
    m[8]=0
    m[12]=0
    local absoluteLinearVelocity=sim.multiplyVector(m,relativeLinearVelocity)
    sim.setObjectFloatParam(model.specHandles.middleParts[3],sim.shapefloatparam_init_velocity_x,absoluteLinearVelocity[1])
    sim.setObjectFloatParam(model.specHandles.middleParts[3],sim.shapefloatparam_init_velocity_y,absoluteLinearVelocity[2])
    sim.setObjectFloatParam(model.specHandles.middleParts[3],sim.shapefloatparam_init_velocity_z,absoluteLinearVelocity[3])
end