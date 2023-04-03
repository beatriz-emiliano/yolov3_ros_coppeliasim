#ifndef SIMPLUSPLUS_LIB_H_INCLUDED
#define SIMPLUSPLUS_LIB_H_INCLUDED

#if __cplusplus <= 199711L
    #error simPlusPlus needs at least a C++11 compliant compiler
#endif

#include <string>
#include <vector>
#include <array>
#include <stdexcept>
#include <boost/optional.hpp>
#include <boost/format.hpp>

#include <simLib.h>

namespace sim
{
    namespace util
    {
        static std::string sprintf(boost::format &fmt)
        {
            return fmt.str();
        }

        template<typename Arg, typename... Args>
        std::string sprintf(boost::format &fmt, Arg &&arg, Args &&...args)
        {
            return sprintf(fmt % std::forward<Arg>(arg), std::forward<Args>(args)...);
        }

        template<typename... Args>
        std::string sprintf(const std::string &msg, Args &&...args)
        {
            return msg;
        }

        template<typename Arg, typename... Args>
        std::string sprintf(const std::string &fmt, Arg &&arg, Args &&...args)
        {
            boost::format f(fmt);
            return sprintf(f, std::forward<Arg>(arg), std::forward<Args>(args)...);
        }
    } // namespace util

	/*! \brief A basic exception class
	 */
    struct exception : public ::std::exception
    {
        std::string s;

        template<typename... Arguments>
        exception(const std::string &fmt, Arguments&&... args)
            : s(util::sprintf(fmt, std::forward<Arguments>(args)...))
        {
        }

        ~exception() throw()
        {
        }

        const char* what() const throw()
        {
            return s.c_str();
        }
    };

    struct api_error : public exception
    {
        std::string func;
        std::string error;

        api_error(const std::string &func_)
            : api_error(func_, "error")
        {
        }

        api_error(const std::string &func_, const std::string &error_)
            : func(func_),
              error(error_),
              exception("%s: %s", func_, error_)
        {
        }

        ~api_error() throw()
        {
        }
    };

    void enableStackDebug();
    void disableStackDebug();
    bool isStackDebugEnabled();

    simInt registerScriptCallbackFunction(const std::string &funcNameAtPluginName, const std::string &callTips, simVoid (*callBack)(struct SScriptCallBack *cb));
    simInt registerScriptVariable(const std::string &varName, const char *varValue, simInt stackID);
    simInt registerScriptVariable(const std::string &varName, const std::string &varValue, simInt stackID);
    template<typename T>
    simInt registerScriptVariable(const std::string &varName, const T &varValue, simInt stackID)
    {
        return registerScriptVariable(varName, std::to_string(varValue), stackID);
    }

    simVoid callScriptFunctionEx(simInt scriptHandleOrType, const std::string &functionNameAtScriptName, simInt stackId);

    simInt createStack();
    simVoid releaseStack(simInt stackHandle);
    simInt copyStack(simInt stackHandle);
    simVoid pushNullOntoStack(simInt stackHandle);
    simVoid pushBoolOntoStack(simInt stackHandle, simBool value);
    simVoid pushInt32OntoStack(simInt stackHandle, simInt value);
    simVoid pushFloatOntoStack(simInt stackHandle, simFloat value);
    simVoid pushDoubleOntoStack(simInt stackHandle, simDouble value);
    simVoid pushStringOntoStack(simInt stackHandle, const simChar *value, simInt stringSize);
    simVoid pushUInt8TableOntoStack(simInt stackHandle, const simUChar *values, simInt valueCnt);
    simVoid pushInt32TableOntoStack(simInt stackHandle, const simInt *values, simInt valueCnt);
    simVoid pushFloatTableOntoStack(simInt stackHandle, const simFloat *values, simInt valueCnt);
    simVoid pushDoubleTableOntoStack(simInt stackHandle, const simDouble *values, simInt valueCnt);
    simVoid pushTableOntoStack(simInt stackHandle);
    simVoid insertDataIntoStackTable(simInt stackHandle);
    simInt getStackSize(simInt stackHandle);
    simInt popStackItem(simInt stackHandle, simInt count);
    simVoid moveStackItemToTop(simInt stackHandle, simInt cIndex);
    simInt isStackValueNull(simInt stackHandle);
    simInt getStackBoolValue(simInt stackHandle, simBool *boolValue);
    simInt getStackInt32Value(simInt stackHandle, simInt *numberValue);
    simInt getStackFloatValue(simInt stackHandle, simFloat *numberValue);
    simInt getStackDoubleValue(simInt stackHandle, simDouble *numberValue);
    simChar* getStackStringValue(simInt stackHandle, simInt *stringSize);
    simInt getStackTableInfo(simInt stackHandle, simInt infoType);
    simInt getStackUInt8Table(simInt stackHandle, simUChar *array, simInt count);
    simInt getStackInt32Table(simInt stackHandle, simInt *array, simInt count);
    simInt getStackFloatTable(simInt stackHandle, simFloat *array, simInt count);
    simInt getStackDoubleTable(simInt stackHandle, simDouble *array, simInt count);
    simVoid unfoldStackTable(simInt stackHandle);
    simVoid unfoldStackTable(simInt stackHandle);
    simVoid debugStack(simInt stackHandle, simInt index = -1);

    simVoid pushStringOntoStack(simInt stackHandle, const std::string &value);
    simVoid pushUInt8TableOntoStack(simInt stackHandle, const std::vector<simUChar> &values);
    simVoid pushInt32TableOntoStack(simInt stackHandle, const std::vector<simInt> &values);
    simVoid pushFloatTableOntoStack(simInt stackHandle, const std::vector<simFloat> &values);
    simVoid pushDoubleTableOntoStack(simInt stackHandle, const std::vector<simDouble> &values);
    simInt getStackStringValue(simInt stackHandle, std::string *stringValue);
    simInt getStackUInt8Table(simInt stackHandle, std::vector<simUChar> *v);
    simInt getStackInt32Table(simInt stackHandle, std::vector<simInt> *v);
    simInt getStackFloatTable(simInt stackHandle, std::vector<simFloat> *v);
    simInt getStackDoubleTable(simInt stackHandle, std::vector<simDouble> *v);

    simInt getBoolParameter(simInt parameter);
    simInt getInt32Parameter(simInt parameter);
    simUInt64 getUInt64Parameter(simInt parameter);
    simFloat getFloatParameter(simInt parameter);
    std::array<simFloat, 3> getArrayParameter(simInt parameter);
    std::string getStringParameter(simInt parameter);
    simVoid setBoolParameter(simInt parameter, simBool value);
    simVoid setInt32Parameter(simInt parameter, simInt value);
    simVoid setFloatParameter(simInt parameter, simFloat value);
    simVoid setArrayParameter(simInt parameter, std::array<simFloat, 3> value);
    simVoid setStringParameter(simInt parameter, simChar *value);
    simVoid setStringParameter(simInt parameter, const std::string &value);

    simFloat getObjectFloatParameter(simInt objectHandle, simInt parameterID, simFloat *parameter);
    simInt getObjectInt32Parameter(simInt objectHandle, simInt parameterID, simInt *parameter);
    std::string getObjectStringParameter(simInt objectHandle, simInt parameterID);
    simVoid setObjectFloatParameter(simInt objectHandle, simInt parameterID, simFloat parameter);
    simVoid setObjectInt32Parameter(simInt objectHandle, simInt parameterID, simInt parameter);
    simVoid setObjectStringParameter(simInt objectHandle, simInt parameterID, const std::string &parameter);

    simVoid getScriptProperty(simInt scriptHandle, simInt *scriptProperty, simInt *associatedObjectHandle);

    boost::optional<std::string> getStringNamedParam(const std::string &parameter);
    simVoid setStringNamedParam(const std::string &parameter, const std::string &value);

    simChar* createBuffer(simInt size);
    simVoid releaseBuffer(simChar *buffer);

    std::string getLastError();
    simVoid setLastError(const std::string &func, const std::string &msg);

    simInt getObjectChild(simInt objectHandle, simInt index);
    simInt getObjectHandle(const std::string &objectName);
    std::array<simFloat, 12> getObjectMatrix(simInt objectHandle, simInt relativeToObjectHandle);
    simVoid setObjectMatrix(simInt objectHandle, simInt relativeToObjectHandle, const std::array<simFloat, 12> &matrix);
    std::string getObjectName(simInt objectHandle);
    simVoid setObjectName(simInt objectHandle, const std::string &objectName);
    std::array<simFloat, 3> getObjectOrientation(simInt objectHandle, simInt relativeToObjectHandle);
    simVoid setObjectOrientation(simInt objectHandle, simInt relativeToObjectHandle, const std::array<simFloat, 3> &eulerAngles);
    simInt getObjectParent(simInt objectHandle);
    simVoid setObjectParent(simInt objectHandle, simInt parentObjectHandle, simBool keepInPlace);
    std::array<simFloat, 3> getObjectPosition(simInt objectHandle, simInt relativeToObjectHandle);
    simVoid setObjectPosition(simInt objectHandle, simInt relativeToObjectHandle, const std::array<simFloat, 3> &position);
    std::array<simFloat, 4> getObjectQuaternion(simInt objectHandle, simInt relativeToObjectHandle);
    simVoid setObjectQuaternion(simInt objectHandle, simInt relativeToObjectHandle, const std::array<simFloat, 4> &quaternion);
    simInt getObjectType(simInt objectHandle);
    simInt getObjectUniqueIdentifier(simInt objectHandle);
    std::pair<std::array<simFloat, 3>, std::array<simFloat, 3>> getObjectVelocity(simInt objectHandle);
    simInt getObjects(simInt index, simInt objectType);
    std::vector<simInt> getObjectsInTree(simInt treeBaseHandle, simInt objectType, simInt options);
    std::vector<simInt> getObjectSelection();
    simInt getObjectSelectionSize();

    simVoid setModuleInfo(const std::string &moduleName, simInt infoType, const std::string &stringInfo);
    simVoid setModuleInfo(const std::string &moduleName, simInt infoType, simInt intInfo);
    simVoid getModuleInfo(const std::string &moduleName, simInt infoType, std::string &stringInfo);
    simVoid getModuleInfo(const std::string &moduleName, simInt infoType, simInt &intInfo);
    std::string getModuleInfoStr(const std::string &moduleName, simInt infoType);
    simInt getModuleInfoInt(const std::string &moduleName, simInt infoType);

    simVoid setModuleInfo(simInt infoType, const std::string &stringInfo);
    simVoid setModuleInfo(simInt infoType, simInt intInfo);
    simVoid getModuleInfo(simInt infoType, std::string &stringInfo);
    simVoid getModuleInfo(simInt infoType, simInt &intInfo);
    std::string getModuleInfoStr(simInt infoType);
    simInt getModuleInfoInt(simInt infoType);

    simInt programVersion();
    std::string versionString(simInt v);

    extern std::string pluginNameAndVersion;

    template<typename... Arguments>
    void addLog(int verbosity, const std::string &fmt, Arguments&&... args)
    {
        ::simAddLog(pluginNameAndVersion.c_str(), verbosity, util::sprintf(fmt, std::forward<Arguments>(args)...).c_str());
    }
} // namespace sim

#endif // SIMPLUSPLUS_LIB_H_INCLUDED
