function sysCall_jointCallback(inData)
    -- inData.mode : sim.jointmode_kinematic or sim.jointmode_dynamic
    --
    -- inData.handle : the handle of the joint associated with this script
    -- inData.revolute : whether the joint associated with this script is revolute or prismatic
    -- inData.cyclic : whether the joint associated with this script is cyclic or not
    -- inData.lowLimit : the lower limit of the joint associated with this script (if the joint is not cyclic)
    -- inData.highLimit : the higher limit of the joint associated with this script (if the joint is not cyclic)
    -- inData.dt : the step size used for the calculations
    -- inData.currentPos : the current position
    -- inData.currentVel : the current velocity
    -- inData.targetPos : the desired position (if joint is dynamic, or when sim.setJointTargetPosition was called)
    -- inData.targetVel : the desired velocity (if joint is dynamic, or when sim.setJointTargetVelocity was called)
    -- inData.initVel : the desired initial velocity (if joint is kinematic and when sim.setJointTargetVelocity
    --                  was called with a 4th argument)
    -- inData.errorValue : targetPos-currentPos (with revolute cyclic joints, the shortest cyclic distance)
    -- inData.maxVel : a maximum velocity, taken from sim.setJointTargetPosition or 
    --                 sim.setJointTargetVelocity's 3rd argument)
    -- inData.maxAccel : a maximum acceleration, taken from sim.setJointTargetPosition or
    --                   sim.setJointTargetVelocity's 3rd argument)
    -- inData.maxJerk : a maximum jerk, taken from sim.setJointTargetPosition or
    --                  sim.setJointTargetVelocity's 3rd argument)
    -- inData.first : whether this is the first call from the physics engine, since the joint
    --                was initialized (or re-initialized) in it.
    -- inData.passCnt : the current dynamics calculation pass. 1-10 by default
    -- inData.totalPasses : the number of dynamics calculation passes for each "regular" simulation pass.
    -- inData.effort : the last force or torque that acted on this joint along/around its axis. With Bullet,
    --                 torques from joint limits are not taken into account
    -- inData.force : the joint force/torque, as set via sim.setJointTargetForce
    -- inData.velUpperLimit : the joint velocity upper limit

    if inData.mode==sim.jointmode_dynamic then
        -- a simple PID controller
        if inData.first then
            PID_P=0.1
            PID_I=0
            PID_D=0
            pidCumulativeErrorForIntegralParam=0
        end
        
        -- The control happens here:
        -- 1. Proportional part:
        local ctrl=inData.errorValue*PID_P
        
        -- 2. Integral part:
        if PID_I~=0 then
            pidCumulativeErrorForIntegralParam=pidCumulativeErrorForIntegralParam+inData.errorValue*inData.dt
        else
            pidCumulativeErrorForIntegralParam=0
        end
        ctrl=ctrl+pidCumulativeErrorForIntegralParam*PID_I
        
        -- 3. Derivative part:
        if not inData.first then
            ctrl=ctrl+currentVel*PID_D
        end
        
        -- 4. Calculate the velocity needed to reach the position in one dynamic time step:
        local maxVelocity=ctrl/inData.dt -- max. velocity allowed.
        if (maxVelocity>inData.velUpperLimit) then
            maxVelocity=inData.velUpperLimit
        end
        if (maxVelocity<-inData.velUpperLimit) then
            maxVelocity=-inData.velUpperLimit
        end
        local forceOrTorqueToApply=inData.maxForce -- the maximum force/torque that the joint will be able to exert

        -- 5. Following data must be returned to CoppeliaSim:
        firstPass=false
        local outData={}
        outData.velocity=maxVelocity
        outData.force=forceOrTorqueToApply
        return outData
    end
    -- Expected return data:
    -- For kinematic joints:
    -- outData={position=pos, velocity=vel, immobile=false}
    -- 
    -- For dynamic joints:
    -- outData={force=f, velocity=vel}
end
