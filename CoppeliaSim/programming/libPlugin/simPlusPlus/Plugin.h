#ifndef SIMPLUSPLUS_PLUGIN_H_INCLUDED
#define SIMPLUSPLUS_PLUGIN_H_INCLUDED

#if __cplusplus <= 199711L
    #error simPlusPlus needs at least a C++11 compliant compiler
#endif

#include <algorithm>
#include <iostream>
#include <string>
#include <vector>
#include <stdexcept>
#include <boost/format.hpp>

#include "simLib.h"

#if SIM_PROGRAM_FULL_VERSION_NB < 4010005
    #error CoppeliaSim headers are not up to date
#endif

#ifdef _WIN32
	#define SIM_DLLEXPORT extern "C" __declspec(dllexport)
#endif /* _WIN32 */
#if defined (__linux) || defined (__APPLE__)
	#define SIM_DLLEXPORT extern "C"
#endif /* __linux || __APPLE__ */

#ifdef _WIN32
    #ifdef QT_COMPIL
        #include <direct.h>
    #else
        #include <shlwapi.h>
        #pragma comment(lib, "Shlwapi.lib")
    #endif
#endif /* _WIN32 */
#if defined (__linux) || defined (__APPLE__)
    #include <unistd.h>
#define _stricmp strcasecmp
#endif /* __linux || __APPLE__ */

namespace sim
{
    extern std::string pluginName;
    extern int pluginVersion;
    extern std::string pluginNameAndVersion;

    struct InstancePassFlags
    {
        bool objectsErased;
        bool objectsCreated;
        bool modelLoaded;
        bool sceneLoaded;
        bool undoCalled;
        bool redoCalled;
        bool sceneSwitched;
        bool editModeActive;
        bool objectsScaled;
        bool selectionStateChanged;
        bool keyPressed;
        bool simulationStarted;
        bool simulationEnded;
        bool scriptCreated;
        bool scriptErased;
    };

    class Plugin
    {
    public:
        void setName(const std::string &name);
        std::string name() const;
        void setExtVersion(const std::string &s);
        void setExtVersion(int i);
        void setBuildDate(const std::string &s);
        void setVerbosity(int i);
        int getVerbosity();
        void init();
        virtual void onStart();
        virtual void onEnd();
        virtual void * onMessage(int message, int *auxData, void *customData, int *replyData) final;
        virtual LIBRARY loadSimLibrary();

        virtual void onInstancePass(const InstancePassFlags &flags, bool first);
        virtual void onInstancePass(const InstancePassFlags &flags);
        virtual void onFirstInstancePass(const InstancePassFlags &flags);
        virtual void onLastInstancePass();
        virtual void onInstanceSwitch(int sceneID);
        virtual void onInstanceAboutToSwitch(int sceneID);
        virtual void onMenuItemSelected(int itemHandle, int itemState);
        virtual void onBroadcast(int header, int messageID);
        virtual void onSceneSave();
        virtual void onModelSave();
        virtual void onModuleOpen(char *name);
        virtual void onModuleHandle(char *name);
        virtual void onModuleHandleInSensingPart(char *name);
        virtual void onModuleClose(char *name);
        virtual void onRenderingPass();
        virtual void onBeforeRendering();
        virtual void onImageFilterEnumReset();
        virtual void onImageFilterEnumerate(int &headerID, int &filterID, std::string &name);
        virtual void onImageFilterAdjustParams(int headerID, int filterID, int bufferSize, void *buffer, int &editedBufferSize, void *&editedBuffer);
        virtual std::vector<simFloat> onImageFilterProcess(int headerID, int filterID, int resX, int resY, int visionSensorHandle, simFloat *inputImage, simFloat *depthImage, simFloat *workImage, simFloat *bufferImage1, simFloat *bufferImage2, simFloat *outputImage, void *filterParamBuffer, int &triggerDetectionn);
        virtual void onAboutToUndo();
        virtual void onUndo();
        virtual void onAboutToRedo();
        virtual void onRedo();
        virtual void onScriptIconDblClick(int objectHandle, int &dontOpenEditor);
        virtual void onSimulationAboutToStart();
        virtual void onSimulationAboutToEnd();
        virtual void onSimulationEnded();
        virtual void onKeyPress(int key, int mods);
        virtual void onBannerClicked(int bannerID);
        virtual void onRefreshDialogs(int refreshDegree);
        virtual void onSceneLoaded();
        virtual void onModelLoaded();
        virtual void onGuiPass();
        virtual void onMainScriptAboutToBeCalled(int &out);
        virtual void onRMLPos();
        virtual void onRMLVel();
        virtual void onRMLStep();
        virtual void onRMLRemove();
        virtual void onPathPlanningPlugin();
        virtual void onColladaPlugin();
        virtual void onOpenGL(int programIndex, int renderingAttributes, int cameraHandle, int viewIndex);
        virtual void onOpenGLFrame(int sizeX, int sizeY, int &out);
        virtual void onOpenGLCameraView(int sizeX, int sizeY, int viewIndex, int &out);
        virtual void onProxSensorSelectDown(int objectID, simFloat *clickedPoint, simFloat *normalVector);
        virtual void onProxSensorSelectUp(int objectID, simFloat *clickedPoint, simFloat *normalVector);
        virtual void onPickSelectDown(int objectID);
        virtual void onScriptStateDestroyed(int scriptID);

    private:
        bool firstInstancePass = true;
        std::string name_;
    };
}

#define SIM_PLUGIN(pluginName_, pluginVersion_, className_) \
namespace sim { \
LIBRARY lib; \
::className_ *plugin; \
std::string pluginName; \
std::string pluginNameAndVersion; \
int pluginVersion; \
} \
SIM_DLLEXPORT unsigned char simStart(void *reservedPointer, int reservedInt) \
{ \
    try \
    { \
        sim::pluginName = pluginName_; \
        sim::pluginVersion = pluginVersion_; \
        sim::pluginNameAndVersion = pluginName_; \
        if(pluginVersion_ > 0) \
        { \
            sim::pluginNameAndVersion += "-"; \
            sim::pluginNameAndVersion += std::to_string(pluginVersion_); \
        } \
        sim::plugin = new className_; \
        sim::plugin->setName(pluginName_); \
        sim::lib = sim::plugin->loadSimLibrary(); \
        sim::plugin->onStart(); \
        return std::max(1, sim::pluginVersion); \
    } \
    catch(std::exception &ex) \
    { \
        simAddLog(sim::pluginName.c_str(), sim_verbosity_errors, ex.what()); \
        return 0; \
    } \
} \
SIM_DLLEXPORT void simEnd() \
{ \
    try \
    { \
        if(sim::plugin) \
        { \
            sim::plugin->onEnd(); \
            delete sim::plugin; \
            sim::plugin = nullptr; \
        } \
    } \
    catch(std::exception &ex) \
    { \
        simAddLog(sim::pluginName.c_str(), sim_verbosity_errors, ex.what()); \
    } \
    unloadSimLibrary(sim::lib); \
} \
SIM_DLLEXPORT void * simMessage(int message, int *auxiliaryData, void *customData, int *replyData) \
{ \
    try \
    { \
        if(sim::plugin) \
        { \
            return sim::plugin->onMessage(message, auxiliaryData, customData, replyData); \
        } \
    } \
    catch(std::exception &ex) \
    { \
        simAddLog(sim::pluginName.c_str(), sim_verbosity_errors, ex.what()); \
    } \
    return 0L; \
}

#endif // SIMPLUSPLUS_PLUGIN_H_INCLUDED
