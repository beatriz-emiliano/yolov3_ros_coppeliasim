# =============================================================== #
# Coppeliasim Library
# July 2, 2022
# @yudarismawahyudi
# =============================================================== #

# Please add these following files in your project folder:
# 1. sim.py
# 2. simConst.py
# 3. remoteApi.dll (Windows) or remoteApi.so (linux)
import math

import sim
import time


# ==========================================================================
# CoppeliaSim Class
# ==========================================================================
class CoppeliaSim:
    clientId = 0
    connected = False

    def __init__(self):
        self.clientID = 0

    def connect(self, port):
        sim.simxFinish(-1)
        self.clientID = sim.simxStart('127.0.0.1', port, True, True, 5000, 5)
        CoppeliaSim.clientId = self.clientID
        if self.clientID != -1:
            sim.simxStartSimulation(self.clientID, sim.simx_opmode_blocking)
            print('Connected to remote API server')
        else:
            print('Failed connecting to remote API server')
        return self.clientID

    def getObjectHandle(self, objName):
        res, handle = sim.simxGetObjectHandle(self.clientID, objName, sim.simx_opmode_blocking)
        return handle

    def disconnect(self):
        sim.simxStopSimulation(self.clientID, sim.simx_opmode_blocking)

    def startSimulation(self):
        sim.simxStartSimulation(self.clientID, sim.simx_opmode_blocking)

    def stopSimulation(self):
        sim.simxStopSimulation(self.clientID, sim.simx_opmode_blocking)

    def message(self, message):
        sim.simxAddStatusbarMessage(self.clientID, message, sim.simx_opmode_oneshot)

# =======================================================================
# Class Coppelia Arm Robot
# =======================================================================
class CoppeliaArmRobot(CoppeliaSim):
    def __init__(self, robot_name):
        self.clientID = CoppeliaSim.clientId
        self.robot_name = robot_name
        self.targetName = "./" + robot_name + '/ikTarget'
        self.ftSensorName = './' + robot_name + '/force_sensor'

        # Retrieve object handle
        res, self.robot_handle = sim.simxGetObjectHandle(self.clientID, robot_name, sim.simx_opmode_oneshot_wait)
        res, self.target_handle = sim.simxGetObjectHandle(self.clientID, self.targetName, sim.simx_opmode_oneshot_wait)
        res, self.ftSensor_handle = sim.simxGetObjectHandle(self.clientID, self.ftSensorName, sim.simx_opmode_oneshot_wait)

        # Start position data streaming
        self.script = '/' + robot_name
        sim.simxCallScriptFunction(self.clientID, self.script,
                                    sim.sim_scripttype_childscript,
                                    'remoteApi_getPosition',
                                    [], [], [], '',
                                    sim.simx_opmode_streaming)

        # Start joint position data streaming
        sim.simxCallScriptFunction(self.clientID, self.script,
                                    sim.sim_scripttype_childscript,
                                    'remoteApi_getJointPosition',
                                    [], [], [], '',
                                    sim.simx_opmode_streaming)
        # Moving status data streaming
        sim.simxGetInt32Signal(self.clientID, 'moving_status', sim.simx_opmode_streaming)
        sim.simxGetStringSignal(self.clientID, 'moving_signal', sim.simx_opmode_streaming)
        # Print robot handle data
        print("\n>>> Arm robot initialization: ", robot_name)
        print("Robot handle = ", self.robot_handle)
        print("\n")


    def readObjectHandle(self):
        print('Robot handle  = %d' % self.robot_handle)
        print('Target handle = %d' % self.target_handle)

    def getObjectPosition(self, obj_name):
        res, handle = sim.simxGetObjectHandle(self.clientID, obj_name, sim.simx_opmode_oneshot_wait)
        res, pos = sim.simxGetObjectPosition(self.clientID, handle, self.robot_handle, sim.simx_opmode_oneshot_wait)
        res, ori = sim.simxGetObjectOrientation(self.clientID, handle, self.robot_handle, sim.simx_opmode_oneshot_wait)
        ret = [0, 0, 0, 0, 0, 0]
        for i in range(3):
            ret[i] = pos[i] * 1000
            ret[i + 3] = ori[i] * 180 / 3.14
        return ret

    # Get current robot position
    def readPosition(self):
        self.posData = [0, 0, 0, 0, 0, 0]
        ret = sim.simxCallScriptFunction(self.clientID, self.script,
                                         sim.sim_scripttype_childscript,
                                         'remoteApi_getPosition',
                                         [], [], [], '',
                                         sim.simx_opmode_buffer)
        if ret[0] == sim.simx_return_ok:
            self.posData = ret[2]
            for i in range(3):
                self.posData[i] = self.posData[i] * 1000
                self.posData[i + 3] = self.posData[i + 3] * 180 / 3.14
        return self.posData
    # ===================================================================


    # Get current joint position
    def readJointPosition(self):
        self.jointPos = [0,0,0,0,0,0]
        ret = sim.simxCallScriptFunction(self.clientID, self.script,
                                         sim.sim_scripttype_childscript,
                                         'remoteApi_getJointPosition',
                                         [], [], [], '',
                                         sim.simx_opmode_buffer)
        if ret[0] == sim.simx_return_ok:
            self.jointPos = ret[2]
            for i in range(6):
                self.jointPos[i] = self.jointPos[i] * 180 / math.pi

        else:
            print("ERROR: Read joint position failed!")

        return self.jointPos
    # ===================================================================


    # Standard set robot position
    def setPosition(self, pos):
        cmdPos = [0, 0, 0, 0, 0, 0]
        for i in range(3):
            cmdPos[i] = pos[i] / 1000
            cmdPos[i + 3] = pos[i + 3] * 3.141592 / 180
        ret = sim.simxCallScriptFunction(self.clientID, self.script,
                                         sim.sim_scripttype_childscript,
                                         'remoteApi_movePosition',
                                         [], cmdPos, [], '',
                                         sim.simx_opmode_blocking)
    # ===================================================================


    # Set robot positon with wait signal
    def setPosition2(self, pos, wait):
        self.setPosition(pos)
        if wait:
            while True:
                time.sleep(0.1)
                if self.isMoving() == 'NOT_MOVING':
                    break
    # ===================================================================


    # Set Joint Position
    def setJointPosition(self, pos, wait):
        cmdPos = [0, 0, 0, 0, 0, 0]
        for i in range(6):
            cmdPos[i] = pos[i] * math.pi / 180
        ret = sim.simxCallScriptFunction(self.clientID, self.script,
                                         sim.sim_scripttype_childscript,
                                         'remoteApi_moveJointPosition',
                                         [], cmdPos, [], '',
                                         sim.simx_opmode_blocking)
        if wait:
            while True:
                if self.isMoving() == 'NOT_MOVING':
                    break
    # ===================================================================


    # Check whether the robot is moving
    def isMoving(self):
        ret, s = sim.simxGetStringSignal(self.clientID, 'moving_signal', sim.simx_opmode_buffer)
        s = s.decode('ascii')
        return s

    # Set Robot Speed: 0 - 100
    def setSpeed(self, lin_vel, ang_vel):
        command = [0,0]
        command[0] = lin_vel / 1000
        command[1] = ang_vel * math.pi / 180
        ret = sim.simxCallScriptFunction(self.clientID, self.script,
                                         sim.sim_scripttype_childscript,
                                         'remoteApi_setSpeed',
                                         [], command, [], '',
                                         sim.simx_opmode_blocking)
    # ===================================================================

    # Catch Gripper
    def gripperCatch(self):
        command = [0,0]
        command[0] = 0
        ret = sim.simxCallScriptFunction(self.clientID, self.script,
                                         sim.sim_scripttype_childscript,
                                         'remoteApi_setGripper',
                                         command, [], [], '',
                                         sim.simx_opmode_blocking)
    # Release Gripper
    def gripperRelease(self):
        command = [0,0]
        command[0] = 1
        ret = sim.simxCallScriptFunction(self.clientID, self.script,
                                         sim.sim_scripttype_childscript,
                                         'remoteApi_setGripper',
                                         command, [], [], '',
                                         sim.simx_opmode_blocking)

# =======================================================================
    # Class Coppelia Sensors
    # =======================================================================
class CoppeliaSensor(CoppeliaSim):
    def __init__(self, sensorName, sensorType):
        self.sensorHandle = 0
        self.clientId = CoppeliaSim.clientId
        res, self.sensorHandle = sim.simxGetObjectHandle(self.clientId, sensorName, sim.simx_opmode_oneshot_wait)
        if self.sensorHandle != 0:
            if sensorType == 0:
                ret, resolution, image = sim.simxGetVisionSensorImage(self.clientId, self.sensorHandle, 0, sim.simx_opmode_streaming)
    # ========================================================

    def getImage(self):
        ret, resolution, image = sim.simxGetVisionSensorImage(self.clientId, self.sensorHandle, 0, sim.simx_opmode_buffer)
        return resolution, image
