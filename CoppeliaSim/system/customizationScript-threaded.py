#python

def sysCall_thread():
    # e.g. non-synchronized loop:
    # sim.setThreadAutomaticSwitch(True)
    # while True:
    #     p=sim.getObjectPosition(objHandle,-1)
    #     p[0]=p[0]+0.001
    #     sim.setObjectPosition(objHandle,-1,p)
        
    # e.g. synchronized loop:
    # sim.setThreadAutomaticSwitch(False)
    # while True:
    #     p=sim.getObjectPosition(objHandle,-1)
    #     p[0]=p[0]+0.001
    #     sim.setObjectPosition(objHandle,-1,p)
    #     sim.switchThread() # resume in next simulation step
    pass

# See the user manual or the available code snippets for additional callback functions and details
