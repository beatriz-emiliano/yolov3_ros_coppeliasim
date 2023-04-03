#py from parse import parse, escape
#py import model
#py plugin = parse(pycpp.params['xml_file'])
#include "stubs.h"
#include <simPlusPlus/Lib.h>

#include <cstring>
#include <string>
#include <vector>
#include <set>
#include <cstdlib>
#include <sstream>
#include <iostream>
#include <boost/lexical_cast.hpp>

FuncTracer::FuncTracer(const std::string &f, int l)
    : f_(f),
      l_(l)
{
    sim::addLog(l_, f_ + " [enter]");
}

FuncTracer::~FuncTracer()
{
    sim::addLog(l_, f_ + " [leave]");
}

#ifndef NDEBUG

template<typename... Arguments>
void addStubsDebugLog(const std::string &fmt, Arguments&&... args)
{
    if(sim::isStackDebugEnabled())
    {
        auto msg = sim::util::sprintf(fmt, std::forward<Arguments>(args)...);
        sim::addLog(sim_verbosity_debug, "STUBS DEBUG: %s", msg);
    }
}

static void addStubsDebugStackDump(int stackHandle)
{
    if(sim::isStackDebugEnabled())
        sim::debugStack(stackHandle);
}

#else // RELEASE
#define addStubsDebugLog(...)
#define addStubsDebugStackDump(x)
#endif

#ifdef QT_COMPIL

Qt::HANDLE UI_THREAD = NULL;
Qt::HANDLE SIM_THREAD = NULL;

std::string threadNickname()
{
    Qt::HANDLE h = QThread::currentThreadId();
    if(h == UI_THREAD) return "UI";
    if(h == SIM_THREAD) return "SIM";
    std::stringstream ss;
    ss << h;
    return ss.str();
}

void uiThread()
{
    Qt::HANDLE h = QThread::currentThreadId();
    if(UI_THREAD != NULL && UI_THREAD != h)
        sim::addLog(sim_verbosity_warnings, "UI thread has already been set");
    UI_THREAD = h;
}

void simThread()
{
    Qt::HANDLE h = QThread::currentThreadId();
    if(SIM_THREAD != NULL && SIM_THREAD != h)
        sim::addLog(sim_verbosity_warnings, "SIM thread has already been set");
    SIM_THREAD = h;
}

#endif // QT_COMPIL

void readFromStack(int stack, bool *value, const ReadOptions &rdopt)
{
    simBool v;
    if(sim::getStackBoolValue(stack, &v) == 1)
    {
        *value = v;
        sim::popStackItem(stack, 1);
    }
    else
    {
        throw sim::exception("expected bool");
    }
}

void readFromStack(int stack, int *value, const ReadOptions &rdopt)
{
    int v;
    if(sim::getStackInt32Value(stack, &v) == 1)
    {
        *value = v;
        sim::popStackItem(stack, 1);
    }
    else
    {
        throw sim::exception("expected int");
    }
}

void readFromStack(int stack, long *value, const ReadOptions &rdopt)
{
    int v;
    if(sim::getStackInt32Value(stack, &v) == 1)
    {
        *value = v;
        sim::popStackItem(stack, 1);
    }
    else
    {
        throw sim::exception("expected int");
    }
}

void readFromStack(int stack, float *value, const ReadOptions &rdopt)
{
    simFloat v;
    if(sim::getStackFloatValue(stack, &v) == 1)
    {
        *value = v;
        sim::popStackItem(stack, 1);
    }
    else
    {
        throw sim::exception("expected float");
    }
}

void readFromStack(int stack, double *value, const ReadOptions &rdopt)
{
    simDouble v;
    if(sim::getStackDoubleValue(stack, &v) == 1)
    {
        *value = v;
        sim::popStackItem(stack, 1);
    }
    else
    {
        throw sim::exception("expected double");
    }
}

void readFromStack(int stack, std::string *value, const ReadOptions &rdopt)
{
    std::string v;
    if(sim::getStackStringValue(stack, &v) == 1)
    {
        *value = v;
        sim::popStackItem(stack, 1);
    }
    else
    {
        throw sim::exception("expected string");
    }
}

template<typename T>
void readFromStack(int stack, boost::optional<T> *value, const ReadOptions &rdopt = {})
{
    if(sim::isStackValueNull(stack) == 1)
    {
        *value = boost::none;
        sim::popStackItem(stack, 1);
    }
    else
    {
        T v;
        readFromStack(stack, &v, rdopt); // will call sim::popStackItem() by itself
        *value = v;
    }
}

template<typename T>
void readFromStack(int stack, std::vector<T> *vec, const ReadOptions &rdopt = {})
{
    int sz = sim::getStackTableInfo(stack, 0);
    if(sz < 0)
        throw sim::exception("expected array (simGetStackTableInfo(stack, 0) returned %d)", sz);

    rdopt.validateTableSize(sz);

    int oldsz = sim::getStackSize(stack);
    sim::unfoldStackTable(stack);
    int sz1 = (sim::getStackSize(stack) - oldsz + 1) / 2;
    if(sz != sz1)
        throw std::runtime_error("simUnfoldStackTable unpacked more elements than simGetStackTableInfo reported");

    vec->resize(sz);

    for(int i = 0; i < sz; i++)
    {
        sim::moveStackItemToTop(stack, oldsz - 1);
        int j;
        readFromStack(stack, &j);
        sim::moveStackItemToTop(stack, oldsz - 1);
        if constexpr(std::is_same<T, bool>::value)
        {
            T v;
            readFromStack(stack, &v);
            (*vec)[i] = v;
        }
        else
        {
            readFromStack(stack, &vec->at(i));
        }
    }
}

template<typename T>
void readFromStack(int stack, std::vector<T> *vec, simInt (*f)(simInt, std::vector<T>*), const ReadOptions &rdopt = {})
{
    int sz = sim::getStackTableInfo(stack, 0);
    if(sz < 0)
        throw sim::exception("expected array (simGetStackTableInfo(stack, 0) returned %d)", sz);

    rdopt.validateTableSize(sz);

    int chk = sim::getStackTableInfo(stack, 2);
    if(chk != 1)
        throw sim::exception("table contains non-numbers (simGetStackTableInfo(stack, 2) returned %d)", chk);

    vec->resize(sz);

    int ret = f(stack, vec);
    if(ret != 1)
        throw sim::exception("readFunc error %d", ret);

    sim::popStackItem(stack, 1);
}

template<>
void readFromStack(int stack, std::vector<float> *vec, const ReadOptions &rdopt)
{
    readFromStack(stack, vec, sim::getStackFloatTable, rdopt);
}

template<>
void readFromStack(int stack, std::vector<double> *vec, const ReadOptions &rdopt)
{
    readFromStack(stack, vec, sim::getStackDoubleTable, rdopt);
}

template<>
void readFromStack(int stack, std::vector<int> *vec, const ReadOptions &rdopt)
{
    readFromStack(stack, vec, sim::getStackInt32Table, rdopt);
}

template<typename T>
void readFromStack(int stack, Grid<T> *grid, const ReadOptions &rdopt = {})
{
    try
    {
        simInt info = sim::getStackTableInfo(stack, 0);
        if(info != sim_stack_table_map && info != sim_stack_table_empty)
        {
            throw sim::exception("expected a map");
        }

        int oldsz = sim::getStackSize(stack);
        sim::unfoldStackTable(stack);
        int numItems = (sim::getStackSize(stack) - oldsz + 1) / 2;

        std::set<std::string> requiredFields{"dims", "data"};

        while(numItems >= 1)
        {
            sim::moveStackItemToTop(stack, oldsz - 1); // move key to top
            std::string key;
            readFromStack(stack, &key);

            sim::moveStackItemToTop(stack, oldsz - 1); // move value to top
            try
            {
                if(0) {}
                else if(key == "dims")
                {
                    readFromStack(stack, &grid->dims, ReadOptions().setBounds(0, 1, -1));
                }
                else if(key == "data")
                {
                    readFromStack(stack, &grid->data, ReadOptions());
                }
                else
                {
                    throw sim::exception("unexpected key");
                }
            }
            catch(std::exception &ex)
            {
                throw sim::exception("field '%s': %s", key, ex.what());
            }

            requiredFields.erase(key);
            numItems = (sim::getStackSize(stack) - oldsz + 1) / 2;
        }

        for(const auto &field : requiredFields)
            throw sim::exception("missing required field '%s'", field);

        if(grid->dims.size() < 1)
            throw sim::exception("must have at least one dimension");

        size_t elemCount = 1;
        for(const int &i : grid->dims) elemCount *= i;
        if(grid->data.size() != elemCount)
            throw sim::exception("incorrect data length (expected %d elements)", elemCount);

        rdopt.validateSize(grid->dims);
    }
    catch(std::exception &ex)
    {
        throw sim::exception("readFromStack(Grid): %s", ex.what());
    }
}

#py for struct in plugin.structs:
void readFromStack(int stack, `struct.name` *value, const ReadOptions &rdopt)
{
    addStubsDebugLog("readFromStack(`struct.name`): begin reading...");
    addStubsDebugStackDump(stack);

    try
    {
        simInt info = sim::getStackTableInfo(stack, 0);
        if(info != sim_stack_table_map && info != sim_stack_table_empty)
        {
            throw sim::exception("expected a map");
        }

        int oldsz = sim::getStackSize(stack);
        sim::unfoldStackTable(stack);
        int numItems = (sim::getStackSize(stack) - oldsz + 1) / 2;

        std::set<std::string> requiredFields{`', '.join(f'"{field.name}"' for field in struct.fields if not field.nullable and field.mandatory())`};

        while(numItems >= 1)
        {
            sim::moveStackItemToTop(stack, oldsz - 1); // move key to top
            std::string key;
            readFromStack(stack, &key);

            sim::moveStackItemToTop(stack, oldsz - 1); // move value to top
            if(0) {}
#py for field in struct.fields:
            else if(key == "`field.name`")
            {
                addStubsDebugLog("readFromStack(`struct.name`): reading field \"`field.name`\" (`field.ctype()`)...");
                try
                {
#py if isinstance(field, (model.ParamTable, model.ParamGrid)):
                    readFromStack(stack, &(value->`field.name`), ReadOptions().setBounds("`field.size`"));
#py else:
                    readFromStack(stack, &(value->`field.name`));
#py endif
                }
                catch(std::exception &ex)
                {
                    throw sim::exception("field '`field.name`': %s", ex.what());
                }
            }
#py endfor
            else
            {
                throw sim::exception("unexpected key: %s", key);
            }

            requiredFields.erase(key);
            numItems = (sim::getStackSize(stack) - oldsz + 1) / 2;
        }

        for(const auto &field : requiredFields)
            throw sim::exception("missing required field '%s'", field);
    }
    catch(std::exception &ex)
    {
        throw sim::exception("readFromStack(`struct.name`): %s", ex.what());
    }

    addStubsDebugLog("readFromStack(`struct.name`): finished reading");
}

#py endfor
void writeToStack(const bool &value, int stack, const WriteOptions &wropt)
{
    sim::pushBoolOntoStack(stack, value);
}

void writeToStack(const int &value, int stack, const WriteOptions &wropt)
{
    sim::pushInt32OntoStack(stack, value);
}

void writeToStack(const long &value, int stack, const WriteOptions &wropt)
{
    if(value < std::numeric_limits<int>::max() || value > std::numeric_limits<int>::max())
        throw std::runtime_error("stack doesn't support (yet) int64 values");
    sim::pushInt32OntoStack(stack, static_cast<int>(value));
}

void writeToStack(const float &value, int stack, const WriteOptions &wropt)
{
    sim::pushFloatOntoStack(stack, value);
}

void writeToStack(const double &value, int stack, const WriteOptions &wropt)
{
    sim::pushDoubleOntoStack(stack, value);
}

void writeToStack(const std::string &value, int stack, const WriteOptions &wropt)
{
    sim::pushStringOntoStack(stack, value);
}

template<typename T>
void writeToStack(const boost::optional<T> &value, int stack, const WriteOptions &wropt = {})
{
    if(!value)
    {
        sim::pushNullOntoStack(stack);
        return;
    }

    writeToStack(*value, stack, wropt);
}

template<typename T>
void writeToStack(const std::vector<T> &vec, int stack, const WriteOptions &wropt = {})
{
    sim::pushTableOntoStack(stack);
    for(size_t i = 0; i < vec.size(); i++)
    {
        writeToStack(int(i + 1), stack);
        writeToStack(vec.at(i), stack);
        sim::insertDataIntoStackTable(stack);
    }
}

template<>
void writeToStack(const std::vector<float> &vec, int stack, const WriteOptions &wropt)
{
    sim::pushFloatTableOntoStack(stack, vec);
}

template<>
void writeToStack(const std::vector<double> &vec, int stack, const WriteOptions &wropt)
{
    sim::pushDoubleTableOntoStack(stack, vec);
}

template<>
void writeToStack(const std::vector<int> &vec, int stack, const WriteOptions &wropt)
{
    sim::pushInt32TableOntoStack(stack, vec);
}

template<typename T>
void writeToStack(const Grid<T> &grid, int stack, const WriteOptions &wropt = {})
{
    try
    {
        sim::pushTableOntoStack(stack);

#py for field_name in ['dims', 'data']:
        try
        {
            writeToStack(std::string{"`field_name`"}, stack);
            writeToStack(grid.`field_name`, stack);
            sim::insertDataIntoStackTable(stack);
        }
        catch(std::exception &ex)
        {
            throw sim::exception("field '`field_name`': %s", ex.what());
        }
#py endfor
    }
    catch(std::exception &ex)
    {
        throw sim::exception("writeToStack(Grid): %s", ex.what());
    }
}

#py for struct in plugin.structs:
void writeToStack(const `struct.name` &value, int stack, const WriteOptions &wropt)
{
    addStubsDebugLog("writeToStack(`struct.name`): begin writing...");

    try
    {
        sim::pushTableOntoStack(stack);

#py for field in struct.fields:
        addStubsDebugLog("writeToStack(`struct.name`): writing field \"`field.name`\" (`field.ctype()`)...");
        try
        {
            writeToStack(std::string{"`field.name`"}, stack);
            writeToStack(value.`field.name`, stack);
            sim::insertDataIntoStackTable(stack);
        }
        catch(std::exception &ex)
        {
            throw sim::exception("field '`field.name`': %s", ex.what());
        }
#py endfor
    }
    catch(std::exception &ex)
    {
        throw sim::exception("writeToStack(`struct.name`): %s", ex.what());
    }

    addStubsDebugLog("writeToStack(`struct.name`): finished writing");
}

#py endfor
#py for struct in plugin.structs:
`struct.name`::`struct.name`()
{
#py for field in struct.fields:
#py if field.default:
    `field.name` = `field.cdefault()`;
#py endif
#py endfor
}

#py endfor
void checkRuntimeVersion()
{
    simInt simVer = sim::programVersion();

    // version required by simStubsGen:
    int minVer = 4010000; // 4.1.0rev0
    if(simVer < minVer)
        throw sim::exception("requires at least %s (libPlugin)", sim::versionString(minVer));

    // version required by plugin:
    if(simVer < SIM_REQUIRED_PROGRAM_VERSION_NB)
        throw sim::exception("requires at least %s", sim::versionString(SIM_REQUIRED_PROGRAM_VERSION_NB));

    // warn if the app older than the headers used to compile:
    if(simVer < SIM_PROGRAM_FULL_VERSION_NB)
        sim::addLog(sim_verbosity_warnings, "has been built for %s", sim::versionString(SIM_PROGRAM_FULL_VERSION_NB));
}

bool registerScriptStuff()
{
    try
    {
        checkRuntimeVersion();

        auto dbg = sim::getStringNamedParam("simStubsGen.debug");
        if(dbg && *dbg != "0")
            sim::enableStackDebug();

        try
        {
#py plugin_var = f'sim{plugin.name}'
#py lua_require = pycpp.params.get('lua_require')
#py #
#py if plugin.version > 0:
#py plugin_var += f'_{plugin.version}'
#py if lua_require:
#py lua_require += f'-{plugin.version}'
#py endif
#py endif
#py #
#py if lua_require:
            sim::registerScriptVariable("`plugin_var`", "require('`lua_require`')", 0);
#py else:
            sim::registerScriptVariable("`plugin_var`", "{}", 0);
#py endif
            sim::registerScriptVariable("_`plugin.name`_latest_version", "math.max(_`plugin.name`_latest_version or 0, `plugin.version`)", 0);

            // register varables from enums:
#py for enum in plugin.enums:
            sim::registerScriptVariable("`plugin_var`.`enum.name`", "{}", 0);
#py for item in enum.items:
            sim::registerScriptVariable("`plugin_var`.`enum.name`.`item.name`", boost::lexical_cast<std::string>(sim_`plugin.name.lower()`_`enum.item_prefix``item.name`), 0);
#py endfor
#py endfor
            // register commands:
#py for cmd in plugin.commands:
            sim::registerScriptCallbackFunction("`plugin_var`.`cmd.name`@`plugin.name`", "`escape(cmd.calltip)``escape(cmd.documentation)`", `cmd.c_name`_callback);
#py endfor

#py if pycpp.params['have_lua_calltips'] == 'True':
#include "lua_calltips.cpp"
#py endif
        }
        catch(std::exception &ex)
        {
            throw sim::exception("Initialization failed (registerScriptStuff): %s", ex.what());
        }
    }
    catch(sim::exception& ex)
    {
        sim::addLog(sim_verbosity_errors, ex.what());
        return false;
    }
    return true;
}

#py for enum in plugin.enums:
const char* `enum.name.lower()`_string(`enum.name` x)
{
    switch(x)
    {
#py for item in enum.items:
        case sim_`plugin.name.lower()`_`enum.item_prefix``item.name`: return "sim_`plugin.name.lower()`_`enum.item_prefix``item.name`";
#py endfor
        default: return "???";
    }
}

#py endfor
#py for cmd in plugin.commands:
`cmd.c_in_name`::`cmd.c_in_name`()
{
#py for p in cmd.params:
#py if p.cdefault() is not None:
    `p.name` = `p.cdefault()`;
#py endif
#py endfor
}

`cmd.c_out_name`::`cmd.c_out_name`()
{
#py for p in cmd.returns:
#py if p.cdefault() is not None:
    `p.name` = `p.cdefault()`;
#py endif
#py endfor
}

void `cmd.c_name`(SScriptCallBack *p, `cmd.c_in_name` *in_args, `cmd.c_out_name` *out_args)
{
    `cmd.c_name`(p, "sim`plugin.name`.`cmd.name`", in_args, out_args);
}

#py if len(cmd.returns) == 1:
`cmd.returns[0].ctype()` `cmd.c_name`(`cmd.c_arg_list(pre_args=['SScriptCallBack *p'])`)
{
    `cmd.c_in_name` in_args;
    if(p)
    {
        std::memcpy(&in_args._, p, sizeof(SScriptCallBack));
    }
#py for p in cmd.params:
    in_args.`p.name` = `p.name`;
#py endfor
    `cmd.c_out_name` out_args;
    `cmd.c_name`(p, &in_args, &out_args);
    return out_args.`cmd.returns[0].name`;
}

#py endif
#py if len(cmd.returns) == 0:
void `cmd.c_name`(`cmd.c_arg_list(pre_args=['SScriptCallBack *p'])`)
{
    `cmd.c_in_name` in_args;
    if(p)
    {
        std::memcpy(&in_args._, p, sizeof(SScriptCallBack));
    }
#py for p in cmd.params:
    in_args.`p.name` = `p.name`;
#py endfor
    `cmd.c_out_name` out_args;
    `cmd.c_name`(p, &in_args, &out_args);
}

#py endif
void `cmd.c_name`(`cmd.c_arg_list(pre_args=['SScriptCallBack *p', '%s *out_args' % cmd.c_out_name])`)
{
    `cmd.c_in_name` in_args;
    if(p)
    {
        std::memcpy(&in_args._, p, sizeof(SScriptCallBack));
    }
#py for p in cmd.params:
    in_args.`p.name` = `p.name`;
#py endfor
    `cmd.c_name`(p, &in_args, out_args);
}

void `cmd.c_name`_callback(SScriptCallBack *p)
{
    addStubsDebugLog("`cmd.c_name`_callback: reading input arguments...");
    addStubsDebugStackDump(p->stackID);

    const char *cmd = "sim`plugin.name`.`cmd.name`";

    `cmd.c_in_name` in_args;
    if(p)
    {
        std::memcpy(&in_args._, p, sizeof(SScriptCallBack));
    }
    `cmd.c_out_name` out_args;

    try
    {
        // check argument count

        int numArgs = sim::getStackSize(p->stackID);
        if(numArgs < `cmd.params_min`)
            throw sim::exception("not enough arguments");
        if(numArgs > `cmd.params_max`)
            throw sim::exception("too many arguments");

        // read input arguments from stack

#py for i, p in enumerate(cmd.params):
        if(numArgs >= `i+1`)
        {
            addStubsDebugLog("`cmd.c_name`_callback: reading input argument `i+1` \"`p.name`\" (`p.ctype()`)...");
            try
            {
                sim::moveStackItemToTop(p->stackID, 0);
#py if isinstance(p, (model.ParamTable, model.ParamGrid)):
                readFromStack(p->stackID, &(in_args.`p.name`), ReadOptions().setBounds("`p.size`"));
#py else:
                readFromStack(p->stackID, &(in_args.`p.name`));
#py endif
            }
            catch(std::exception &ex)
            {
                throw sim::exception("read in arg `i+1` (`p.name`): %s", ex.what());
            }
        }

#py endfor

        addStubsDebugLog("`cmd.c_name`_callback: stack content after reading input arguments:");
        addStubsDebugStackDump(p->stackID);

#py if cmd.clear_stack_after_reading_input:
        addStubsDebugLog("`cmd.c_name`_callback: clearing stack content after reading input arguments");
        // clear stack
        sim::popStackItem(p->stackID, 0);

#py endif

        addStubsDebugLog("`cmd.c_name`_callback: calling callback (`cmd.c_name`)");
        `cmd.c_name`(p, cmd, &in_args, &out_args);
    }
    catch(std::exception &ex)
    {
        sim::setLastError(cmd, ex.what());
    }

    try
    {
        addStubsDebugLog("`cmd.c_name`_callback: writing output arguments...");
        addStubsDebugStackDump(p->stackID);

#py if cmd.clear_stack_before_writing_output:
        addStubsDebugLog("`cmd.c_name`_callback: clearing stack content before writing output arguments");
        // clear stack
        sim::popStackItem(p->stackID, 0);

#py endif

        // write output arguments to stack

#py for i, p in enumerate(cmd.returns):
        addStubsDebugLog("`cmd.c_name`_callback: writing output argument `i+1` \"`p.name`\" (`p.ctype()`)...");
        try
        {
            writeToStack(out_args.`p.name`, p->stackID);
        }
        catch(std::exception &ex)
        {
            throw sim::exception("write out arg `i+1` (`p.name`): %s", ex.what());
        }
#py endfor

        addStubsDebugLog("`cmd.c_name`_callback: stack content after writing output arguments:");
        addStubsDebugStackDump(p->stackID);
    }
    catch(std::exception &ex)
    {
        sim::setLastError(cmd, ex.what());
        // clear stack
        try { sim::popStackItem(p->stackID, 0); } catch(...) {}
    }

    addStubsDebugLog("`cmd.c_name`_callback: finished");
}

#py endfor
#py for fn in plugin.script_functions:
`fn.c_in_name`::`fn.c_in_name`()
{
#py for p in fn.params:
#py if p.default is not None:
    `p.name` = `p.cdefault()`;
#py endif
#py endfor
}

`fn.c_out_name`::`fn.c_out_name`()
{
#py for p in fn.returns:
#py if p.default is not None:
    `p.name` = `p.cdefault()`;
#py endif
#py endfor
}

bool `fn.c_name`(simInt scriptId, const char *func, `fn.c_in_name` *in_args, `fn.c_out_name` *out_args)
{
    addStubsDebugLog("`fn.c_name`: writing input arguments...");

    int stackID = -1;

    try
    {
        stackID = sim::createStack();

        // write input arguments to stack

#py for i, p in enumerate(fn.params):
        addStubsDebugLog("`fn.c_name`: writing input argument `i+1` \"`p.name`\" (`p.ctype()`)...");
        try
        {
            writeToStack(in_args->`p.name`, stackID);
        }
        catch(std::exception &ex)
        {
            throw sim::exception("writing input argument `i+1` (`p.name`): %s", ex.what());
        }
#py endfor

        addStubsDebugLog("`fn.c_name`: wrote input arguments:");
        addStubsDebugStackDump(stackID);

        sim::callScriptFunctionEx(scriptId, func, stackID);

        // read output arguments from stack

        addStubsDebugLog("`fn.c_name`: reading output arguments...");

#py for i, p in enumerate(fn.returns):
        addStubsDebugLog("`fn.c_name`: reading output argument `i+1` \"`p.name`\" (`p.ctype()`)...");
        try
        {
            sim::moveStackItemToTop(stackID, 0);
#py if isinstance(p, (model.ParamTable, model.ParamGrid)):
            readFromStack(stackID, &(out_args->`p.name`), ReadOptions().setBounds("`p.size`"));
#py else:
            readFromStack(stackID, &(out_args->`p.name`));
#py endif
        }
        catch(std::exception &ex)
        {
            throw sim::exception("read out arg `i+1` (`p.name`): %s", ex.what());
        }
#py endfor

        addStubsDebugLog("`fn.c_name`: stack content after reading output arguments:");
        addStubsDebugStackDump(stackID);

        sim::releaseStack(stackID);
        stackID = -1;
    }
    catch(std::exception &ex)
    {
        if(stackID != -1)
            try { sim::releaseStack(stackID); } catch(...) {}
        sim::setLastError(func, ex.what());
        return false;
    }

    addStubsDebugLog("`fn.c_name`: finished");

    return true;
}

#py endfor
