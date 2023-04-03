The various source code items can be found on https://github.com/CoppeliaRobotics
Clone each required repository with:

git clone --recursive https://github.com/CoppeliaRobotics/repositoryName

Use following directory structure:

coppeliaRobotics
    |__ coppeliaSimLib (CoppeliaSim main library)
    |__ programming
                  |__ include
                  |__ common
                  |__ simMath
                  |__ coppeliaGeometricRoutines
                  |__ coppeliaKinematicsRoutines
                  |__ simExtGeom
                  |__ simExtIK
                  |__ simExtDyn
                  |__ libPlugin
                  |__ zmqRemoteApi
                  |__ wsRemoteApi
                  |__ simExtCodeEditor
                  |__ simExtJoystick
                  |__ simExtCam
                  |__ simExtURDF
                  |__ simExtSDF
                  |__ simExtRuckig
                  |__ simExtRRS1
                  |__ simExtMTB
                  |__ simExtUI
                  |__ simExtOMPL
                  |__ simExtICP
                  |__ simExtSurfRec
                  |__ simExtLuaCmd
                  |__ simExtPluginSkeleton
                  |__ simExtSkel
                  |__ simExtCHAI3D
                  |__ simExtConvexDecompose
                  |__ simExtPovRay
                  |__ simExtQhull
                  |__ simExtVision
                  |__ simExtExternalRenderer
                  |__ simExtIM
                  |__ simExtBubbleRob
                  |__ simExtK3
                  |__ simExtAssimp
                  |__ simExtOpenMesh
                  |__ simExtOpenGL3Renderer
                  |__ simExtGLTF
                  |__ simExtZMQ
                  |__ simExtURLDrop
                  |__ simExtSubprocess
                  |__ simExtEigen
                  |__ bubbleRobServer
                  |__ bubbleRobZmqServer
                  |__ rcsServer
                  |__ mtbServer
                  |
                  |__ ros_packages
                  |            |__ simExtROS
                  |            |__ ros_bubble_rob
                  |
                  |__ ros2_packages
                               |__ simExtROS2
                               |__ ros2_bubble_rob
                               

           
Following are the main Items:
-----------------------------

-   'coppeliaSimLib' (requires 'include', 'common' and 'simMath'):         
    https://github.com/CoppeliaRobotics/coppeliaSimLib

-   'coppeliaSimClientApplication' (requires 'include' and 'common'):
    https://github.com/CoppeliaRobotics/coppeliaSimClientApplication


Various common items:
---------------------

-   'simMath':
    https://github.com/CoppeliaRobotics/simMath

-   'common' (requires 'include'):
    https://github.com/CoppeliaRobotics/common

-   'include' (requires 'common'):
    https://github.com/CoppeliaRobotics/include

-   'libPlugin':
    https://github.com/CoppeliaRobotics/libPlugin

-   'zmqRemoteApi'
    https://github.com/CoppeliaRobotics/zmqRemoteApi

-   'wsRemoteApi'
    https://github.com/CoppeliaRobotics/wsRemoteApi

-   'coppeliaGeometricRoutines' (requires 'include', 'common' and 'simMath'):
    https://github.com/CoppeliaRobotics/coppeliaGeometricRoutines

-   'coppeliaKinematicsRoutines' (requires 'include', 'common' and 'simMath'):
    https://github.com/CoppeliaRobotics/coppeliaKinematicsRoutines
    
Major plugins:
--------------

-   'simExtDyn' (requires 'include', 'common' and 'simMath'):
    https://github.com/CoppeliaRobotics/simExtDyn

-   'simExtGeom' (requires 'include', 'common', 'simMath' and coppeliaGeometricRoutines):
    https://github.com/CoppeliaRobotics/simExtGeom

-   'simExtIK' (requires 'include', 'common', 'simMath' and coppeliaKinematicsRoutines):
    https://github.com/CoppeliaRobotics/simExtIK

-   'simExtCodeEditor' (requires 'include', 'common' and 'QScintilla'):
    https://github.com/CoppeliaRobotics/simExtCodeEditor


Various plugins:
----------------

-   'simExtJoystick' (requires 'include' and 'common'):
    https://github.com/CoppeliaRobotics/simExtJoystick (Windows only)

-   'simExtCam' (requires 'include' and 'common'):
    https://github.com/CoppeliaRobotics/simExtCam (Windows only)

-   'simExtURDF' (requires 'include', 'common' and 'simMath'):
    https://github.com/CoppeliaRobotics/simExtURDF

-   'simExtSDF' (requires 'include' and 'common', 'simMath' and 'libPlugin'):
    https://github.com/CoppeliaRobotics/simExtSDF

-   'simExtRuckig' (requires 'include' and 'common'):
    https://github.com/CoppeliaRobotics/simExtRuckig

-   'simExtRRS1' (requires 'include' and 'common'):
    https://github.com/CoppeliaRobotics/simExtRRS1

-   'simExtMTB' (requires 'include' and 'common'):
    https://github.com/CoppeliaRobotics/simExtMTB

-   'simExtUI' (requires 'include', 'common' and 'libPlugin'):
    https://github.com/CoppeliaRobotics/simExtUI

-   'simExtOMPL' (requires 'include', 'common' and 'libPlugin'):
    https://github.com/CoppeliaRobotics/simExtOMPL

-   'simExtICP' (requires 'include', 'common' and 'libPlugin'):
    https://github.com/CoppeliaRobotics/simExtICP

-   'simExtSurfRec' (requires 'include', 'common' and 'libPlugin'):
    https://github.com/CoppeliaRobotics/simExtSurfRec

-   'simExtROS' (requires 'include', 'common' and 'libPlugin'):
    https://github.com/CoppeliaRobotics/simExtROS

-   'simExtROS2' (requires 'include', 'common' and 'libPlugin'):
    https://github.com/CoppeliaRobotics/simExtROS2

-   'simExtLuaCmd' (requires 'include', 'common' and 'libPlugin'):
    https://github.com/CoppeliaRobotics/simExtLuaCmd

-   'simExtCHAI3D' (requires 'include' and 'common'):
    https://github.com/CoppeliaRobotics/simExtCHAI3D

-   'simExtConvexDecompose' (requires 'include' and 'common'):
    https://github.com/CoppeliaRobotics/simExtConvexDecompose

-   'simExtPovRay' (requires 'include' and 'common'):
    https://github.com/CoppeliaRobotics/simExtPovRay

-   'simExtQhull' (requires 'include' and 'common'):
    https://github.com/CoppeliaRobotics/simExtQhull

-   'simExtOpenMesh' (requires 'include' and 'common'):
    https://github.com/CoppeliaRobotics/simExtOpenMesh

-   'simExtVision' (requires 'include' and 'common'):
    https://github.com/CoppeliaRobotics/simExtVision

-   'simExtExternalRenderer' (requires 'include' and 'common'):
    https://github.com/CoppeliaRobotics/simExtExternalRenderer

-   'simExtIM' (requires 'include', 'common' and 'libPlugin'):
    https://github.com/CoppeliaRobotics/simExtIM

-   'simExtBubbleRob' (requires 'include' and 'common'):
    https://github.com/CoppeliaRobotics/simExtBubbleRob

-   'simExtK3' (requires 'include' and 'common'):
    https://github.com/CoppeliaRobotics/simExtK3

-   'simExtOpenGL3Renderer' (requires 'include' and 'common'):
    https://github.com/stepjam/simExtOpenGL3Renderer or https://github.com/CoppeliaRobotics/simExtOpenGL3Renderer

-   'simExtGLTF' (requires 'include' and 'common' and 'libPlugin'):
    https://github.com/CoppeliaRobotics/simExtGLTF

-   'simExtZMQ' (requires 'include' and 'common' and 'libPlugin'):
    https://github.com/CoppeliaRobotics/simExtZMQ

-   'simExtURLDrop' (requires 'include' and 'common' and 'libPlugin'):
    https://github.com/CoppeliaRobotics/simExtURLDrop

-   'simExtSubprocess' (requires 'include' and 'common' and 'libPlugin' and Qt):
    https://github.com/CoppeliaRobotics/simExtSubprocess

-   'simExtEigen' (requires 'include' and 'common' and 'libPlugin' and Eigen):
    https://github.com/CoppeliaRobotics/simExtEigen

Various other repositories:		
---------------------------

-   'bubbleRobServer' (requires 'include' and 'common'):
    https://github.com/CoppeliaRobotics/bubbleRobServer
    
-   'bubbleRobZmqServer' (requires 'include' and 'common'):
    https://github.com/CoppeliaRobotics/bubbleRobZmqServer
    
-   'rcsServer' (requires 'include' and 'common'):
    https://github.com/CoppeliaRobotics/rcsServer

-   'mtbServer' (requires 'include' and 'common'):
    https://github.com/CoppeliaRobotics/mtbServer

-   'ros_bubble_rob'
    https://github.com/CoppeliaRobotics/ros_bubble_rob

-   'ros2_bubble_rob'
    https://github.com/CoppeliaRobotics/ros2_bubble_rob

-   'PyRep':
    https://github.com/stepjam/PyRep
