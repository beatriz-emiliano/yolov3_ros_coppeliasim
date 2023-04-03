function sysCall_info()
    return {autoStart=false}
end

function sysCall_addOnScriptSuspend()
    return {cmd='cleanup'}
end

function sysCall_init()
    sim.addLog(sim.verbosity_scriptinfos,"During simulation, all dynamic contacts in the scenes will be parsed and visualized.")
end

function sysCall_afterSimulation()
    clean()
end

function sysCall_cleanup()
    clean()
end

function sysCall_sensing()
    if lineContainer==nil then
        black={0,0,0}
        purple={1,0,1}
        lightBlue={0,1,1}
        forceVectorScaling=0.05
        forceVectorWidth=4
        contactPointSize=0.01
        -- Add a line and a sphere container:
        lineContainer=sim.addDrawingObject(sim.drawing_lines,forceVectorWidth,0,-1,1000,black,black,black,purple)
        sphereContainer=sim.addDrawingObject(sim.drawing_spherepoints,contactPointSize,0,-1,1000,black,black,black,lightBlue)
    end
    
    -- empty the containers:
    sim.addDrawingObjectItem(lineContainer,nil) 
    sim.addDrawingObjectItem(sphereContainer,nil) 
    
    -- Fill the containers with contact information:
    index=0
    while (true) do
        objectsInContact,contactPt,forceDirectionAndAmplitude=sim.getContactInfo(sim.handle_all,sim.handle_all,index)
        if (objectsInContact) then
            line={contactPt[1],contactPt[2],contactPt[3],0,0,0}
            line[4]=contactPt[1]+forceDirectionAndAmplitude[1]*forceVectorScaling
            line[5]=contactPt[2]+forceDirectionAndAmplitude[2]*forceVectorScaling
            line[6]=contactPt[3]+forceDirectionAndAmplitude[3]*forceVectorScaling
            sim.addDrawingObjectItem(lineContainer,line)
            line[4]=contactPt[1]-forceDirectionAndAmplitude[1]*forceVectorScaling
            line[5]=contactPt[2]-forceDirectionAndAmplitude[2]*forceVectorScaling
            line[6]=contactPt[3]-forceDirectionAndAmplitude[3]*forceVectorScaling
            sim.addDrawingObjectItem(lineContainer,line)
            sim.addDrawingObjectItem(sphereContainer,line)
            index=index+1
        else
            break
        end
    end
end

function clean()
    -- Remove the containers:
    if lineContainer then
        sim.removeDrawingObject(lineContainer)
        lineContainer=nil
        sim.removeDrawingObject(sphereContainer)
        sphereContainer=nil
    end
end
