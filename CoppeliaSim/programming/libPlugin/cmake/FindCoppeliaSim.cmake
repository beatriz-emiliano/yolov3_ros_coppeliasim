cmake_minimum_required(VERSION 3.16.3)
include(CMakeParseArguments)

if(CMAKE_CXX_STANDARD)
    if(CMAKE_CXX_STANDARD LESS 17)
        message(FATAL_ERROR "Set CMAKE_CXX_STANDARD to 17 or greater (or remove it)")
    endif()
else()
    set(CMAKE_CXX_STANDARD 17)
endif()

# fix CMAKE_MODULE_PATH to have forward slashes:
file(TO_CMAKE_PATH "${CMAKE_MODULE_PATH}" CMAKE_MODULE_PATH)

function(COPPELIASIM_FIND_ERROR MESSAGE)
    if(CoppeliaSim_FIND_REQUIRED)
        message(FATAL_ERROR ${MESSAGE})
    elseif(NOT CoppeliaSim_FIND_QUIETLY)
        message(SEND_ERROR ${MESSAGE})
    endif()
endfunction()

# redefine LIBPLUGIN_DIR as the directory containing this module:

get_filename_component(LIBPLUGIN_DIR ${CMAKE_CURRENT_LIST_DIR} DIRECTORY)
if(NOT CoppeliaSim_FIND_QUIETLY)
    message(STATUS "CoppeliaSim: LIBPLUGIN_DIR: ${LIBPLUGIN_DIR}.")
endif()

# determine the value of COPPELIASIM_ROOT_DIR:

if(NOT COPPELIASIM_ROOT_DIR)
    if(NOT DEFINED ENV{COPPELIASIM_ROOT_DIR})
        if(EXISTS "${LIBPLUGIN_DIR}/../../programming/include")
            get_filename_component(COPPELIASIM_PROGRAMMING_DIR ${LIBPLUGIN_DIR} DIRECTORY)
        elseif(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/../../programming/include")
            get_filename_component(COPPELIASIM_PROGRAMMING_DIR ${CMAKE_CURRENT_SOURCE_DIR} DIRECTORY)
        else()
            coppeliasim_find_error("Cannot figure out the value for COPPELIASIM_ROOT_DIR.")
            return()
        endif()
        get_filename_component(COPPELIASIM_ROOT_DIR ${COPPELIASIM_PROGRAMMING_DIR} DIRECTORY)
        unset(COPPELIASIM_PROGRAMMING_DIR)
    else()
        set(COPPELIASIM_ROOT_DIR "$ENV{COPPELIASIM_ROOT_DIR}")
    endif()
endif()

# check if COPPELIASIM_ROOT_DIR exists, is valid, etc...:

set(COPPELIASIM_FOUND FALSE)

if(EXISTS "${COPPELIASIM_ROOT_DIR}")
    file(TO_CMAKE_PATH "${COPPELIASIM_ROOT_DIR}" COPPELIASIM_ROOT_DIR)
    if(NOT CoppeliaSim_FIND_QUIETLY)
        message(STATUS "CoppeliaSim: COPPELIASIM_ROOT_DIR: ${COPPELIASIM_ROOT_DIR}.")
    endif()
else()
    coppeliasim_find_error("The specified COPPELIASIM_ROOT_DIR (${COPPELIASIM_ROOT_DIR}) does not exist")
    return()
endif()

foreach(D IN ITEMS
        "${COPPELIASIM_ROOT_DIR}/programming/include"
        "${COPPELIASIM_ROOT_DIR}/programming/common"
)
    if(NOT EXISTS "${D}" AND IS_DIRECTORY "${D}")
        coppeliasim_find_error("Directory ${D} does not exist.")
        return()
    endif()
endforeach()

set(COPPELIASIM_INCLUDE_DIR "${COPPELIASIM_ROOT_DIR}/programming/include")
set(COPPELIASIM_COMMON_DIR "${COPPELIASIM_ROOT_DIR}/programming/common")

foreach(F IN ITEMS
        "${COPPELIASIM_INCLUDE_DIR}/simLib.h"
        "${COPPELIASIM_INCLUDE_DIR}/simConst.h"
        "${COPPELIASIM_COMMON_DIR}/simLib.cpp"
        "${LIBPLUGIN_DIR}/simPlusPlus/Lib.cpp"
        "${LIBPLUGIN_DIR}/simPlusPlus/Plugin.cpp"
        "${LIBPLUGIN_DIR}/simPlusPlus/Handle.cpp"
)
    if(NOT EXISTS "${F}")
        coppeliasim_find_error("File ${F} does not exist.")
        return()
    endif()
endforeach()

set(COPPELIASIM_EXPORTED_SOURCES
    "${COPPELIASIM_EXPORTED_SOURCES}"
    "${COPPELIASIM_COMMON_DIR}/simLib.cpp")

if(NOT CoppeliaSim_FIND_QUIETLY)
    message(STATUS "Found CoppeliaSim installation at ${COPPELIASIM_ROOT_DIR}.")
endif()

# check required version:

if(DEFINED CoppeliaSim_FIND_VERSION)
    if(NOT CoppeliaSim_FIND_QUIETLY)
        message(STATUS "Checking CoppeliaSim header version...")
    endif()
    set(COPPELIASIM_VERSION_CHECK_SRC "${CMAKE_BINARY_DIR}/sim_version_check.cpp")
    set(COPPELIASIM_VERSION_CHECK_BIN "${CMAKE_BINARY_DIR}/sim_version_check")
    file(WRITE ${COPPELIASIM_VERSION_CHECK_SRC} "
#include <iostream>
#include <simConst.h>
int main() {
    char sep = ';';
    std::cout
        << SIM_PROGRAM_VERSION_NB/10000 << sep
        << SIM_PROGRAM_VERSION_NB/100%100 << sep
        << SIM_PROGRAM_VERSION_NB%100 << sep
        << SIM_PROGRAM_REVISION_NB << sep
        << 0 << std::endl;
}
")
    try_run(COPPELIASIM_VERSION_RUN_RESULT COPPELIASIM_VERSION_COMPILE_RESULT ${COPPELIASIM_VERSION_CHECK_BIN} ${COPPELIASIM_VERSION_CHECK_SRC} CMAKE_FLAGS -DINCLUDE_DIRECTORIES=${COPPELIASIM_INCLUDE_DIR} RUN_OUTPUT_VARIABLE COPPELIASIM_VERSION_CHECK_OUTPUT)
    if(${COPPELIASIM_VERSION_COMPILE_RESULT})
        if(${COPPELIASIM_VERSION_RUN_RESULT} EQUAL 0)
            list(GET COPPELIASIM_VERSION_CHECK_OUTPUT 0 COPPELIASIM_VERSION_MAJOR)
            list(GET COPPELIASIM_VERSION_CHECK_OUTPUT 1 COPPELIASIM_VERSION_MINOR)
            list(GET COPPELIASIM_VERSION_CHECK_OUTPUT 2 COPPELIASIM_VERSION_PATCH)
            list(GET COPPELIASIM_VERSION_CHECK_OUTPUT 3 COPPELIASIM_VERSION_TWEAK)
            set(COPPELIASIM_VERSION_COUNT 4)
            list(GET COPPELIASIM_VERSION_CHECK_OUTPUT 3 COPPELIASIM_REVISION)
            set(COPPELIASIM_VERSION "${COPPELIASIM_VERSION_MAJOR}.${COPPELIASIM_VERSION_MINOR}.${COPPELIASIM_VERSION_PATCH}.${COPPELIASIM_REVISION}")
            set(COPPELIASIM_VERSION_STR "${COPPELIASIM_VERSION_MAJOR}.${COPPELIASIM_VERSION_MINOR}.${COPPELIASIM_VERSION_PATCH} rev${COPPELIASIM_REVISION}")
            if(NOT CoppeliaSim_FIND_QUIETLY)
                message(STATUS "CoppeliaSim headers version ${COPPELIASIM_VERSION_STR}")
            endif()
            math(EXPR CoppeliaSim_FIND_VERSION_NB "1000000 * ${CoppeliaSim_FIND_VERSION_MAJOR} + 10000 * ${CoppeliaSim_FIND_VERSION_MINOR} + 100 * ${CoppeliaSim_FIND_VERSION_PATCH} + ${CoppeliaSim_FIND_VERSION_TWEAK}")
            add_compile_definitions(SIM_REQUIRED_PROGRAM_VERSION_NB=${CoppeliaSim_FIND_VERSION_NB})
            if(${COPPELIASIM_VERSION} VERSION_LESS ${CoppeliaSim_FIND_VERSION})
                coppeliasim_find_error("Found CoppeliaSim version ${COPPELIASIM_VERSION} but ${CoppeliaSim_FIND_VERSION} required.")
                return()
            endif()
        else()
            coppeliasim_find_error("Failed to run CoppeliaSim version check program")
            return()
        endif()
    else()
        coppeliasim_find_error("Failed to compile CoppeliaSim version check program")
        return()
    endif()
endif()

if(WIN32)
    add_definitions(-DWIN_SIM)
    add_definitions(-DNOMINMAX)
    add_definitions(-Dstrcasecmp=_stricmp)
    if((MSVC) AND (MSVC_VERSION GREATER_EQUAL 1914))
        add_compile_options("/Zc:__cplusplus")
    endif()
    set(COPPELIASIM_LIBRARIES shlwapi)
    set(COPPELIASIM_PLUGINS_DIR ${COPPELIASIM_ROOT_DIR})
    set(COPPELIASIM_LIBRARIES_DIR ${COPPELIASIM_ROOT_DIR})
    set(COPPELIASIM_HELPFILES_DIR ${COPPELIASIM_ROOT_DIR}/helpFiles)
    set(COPPELIASIM_MODELS_DIR ${COPPELIASIM_ROOT_DIR}/models)
    set(COPPELIASIM_EXECUTABLE ${COPPELIASIM_PLUGINS_DIR}/coppeliaSim.exe)
elseif(UNIX AND NOT APPLE)
    add_definitions(-DLIN_SIM)
    set(COPPELIASIM_LIBRARIES "")
    set(COPPELIASIM_PLUGINS_DIR ${COPPELIASIM_ROOT_DIR})
    set(COPPELIASIM_LIBRARIES_DIR ${COPPELIASIM_ROOT_DIR})
    set(COPPELIASIM_HELPFILES_DIR ${COPPELIASIM_ROOT_DIR}/helpFiles)
    set(COPPELIASIM_MODELS_DIR ${COPPELIASIM_ROOT_DIR}/models)
    set(COPPELIASIM_EXECUTABLE ${COPPELIASIM_PLUGINS_DIR}/coppeliaSim)
elseif(UNIX AND APPLE)
    add_definitions(-DMAC_SIM)
    set(COPPELIASIM_LIBRARIES "")
    if(EXISTS ${COPPELIASIM_ROOT_DIR}/coppeliaSim.app)
        set(COPPELIASIM_PLUGINS_DIR ${COPPELIASIM_ROOT_DIR}/coppeliaSim.app/Contents/MacOS/)
        set(COPPELIASIM_LIBRARIES_DIR ${COPPELIASIM_ROOT_DIR}/coppeliaSim.app/Contents/Frameworks/)
    elseif(EXISTS ${COPPELIASIM_ROOT_DIR}/../../Contents/MacOS)
        get_filename_component(COPPELIASIM_PLUGINS_DIR ${COPPELIASIM_ROOT_DIR}/../../Contents/MacOS/ ABSOLUTE)
        get_filename_component(COPPELIASIM_LIBRARIES_DIR ${COPPELIASIM_ROOT_DIR}/../../Contents/Frameworks/ ABSOLUTE)
    else()
        coppeliasim_find_error("Cannot determine plugins install dir")
        return()
    endif()
    set(COPPELIASIM_HELPFILES_DIR ${COPPELIASIM_ROOT_DIR}/helpFiles)
    set(COPPELIASIM_MODELS_DIR ${COPPELIASIM_ROOT_DIR}/models)
    set(COPPELIASIM_EXECUTABLE ${COPPELIASIM_PLUGINS_DIR}/coppeliaSim)
endif()
set(COPPELIASIM_LUA_DIR ${COPPELIASIM_PLUGINS_DIR}/lua)

include_directories(${LIBPLUGIN_DIR})

function(COPPELIASIM_GENERATE_STUBS GENERATED_OUTPUT_DIR)
    cmake_parse_arguments(COPPELIASIM_GENERATE_STUBS "" "XML_FILE;LUA_FILE" "" ${ARGN})
    if(NOT CoppeliaSim_FIND_QUIETLY)
        message(STATUS "Adding simStubsGen command...")
    endif()
    find_package(Python3 REQUIRED COMPONENTS Interpreter)
    if(Python3_VERSION VERSION_LESS 3.8)
        message(FATAL_ERROR "Python 3.8+ is required")
    endif()
    if(NOT CoppeliaSim_FIND_QUIETLY)
        message(STATUS "Reading plugin metadata...")
    endif()
    execute_process(
        COMMAND ${Python3_EXECUTABLE}
            ${LIBPLUGIN_DIR}/simStubsGen/generate.py
            --xml-file ${COPPELIASIM_GENERATE_STUBS_XML_FILE}
            --gen-cmake-meta
            ${GENERATED_OUTPUT_DIR}
        RESULT_VARIABLE READ_PLUGIN_META_EXITCODE)
    if(NOT READ_PLUGIN_META_EXITCODE EQUAL 0)
        message(FATAL_ERROR "Failed reading plugin metadata (error in XML file?)")
    endif()
    include(${GENERATED_OUTPUT_DIR}/meta.cmake)
    if(NOT CoppeliaSim_FIND_QUIETLY)
        set(PLUGIN_INFO_STR "${PLUGIN_NAME}")
        if(PLUGIN_VERSION GREATER 0)
            set(PLUGIN_INFO_STR "${PLUGIN_INFO_STR} [version=${PLUGIN_VERSION}]")
        endif()
        message(STATUS "Plugin: ${PLUGIN_INFO_STR}")
    endif()
    set(OUTPUT_FILES
        ${GENERATED_OUTPUT_DIR}/stubs.cpp
        ${GENERATED_OUTPUT_DIR}/stubs.h
        ${GENERATED_OUTPUT_DIR}/plugin.h
        ${GENERATED_OUTPUT_DIR}/stubsPlusPlus.cpp
        ${GENERATED_OUTPUT_DIR}/index.json
        ${GENERATED_OUTPUT_DIR}/reference.html
    )
    set(COMMAND_ARGS
        ${Python3_EXECUTABLE}
        ${LIBPLUGIN_DIR}/simStubsGen/generate.py
        --verbose
        --xml-file ${COPPELIASIM_GENERATE_STUBS_XML_FILE}
        --gen-all ${GENERATED_OUTPUT_DIR}
    )
    set(DEPENDENCIES
        ${LIBPLUGIN_DIR}/simStubsGen/__init__.py
        ${LIBPLUGIN_DIR}/simStubsGen/generate.py
        ${LIBPLUGIN_DIR}/simStubsGen/generate_api_index.py
        ${LIBPLUGIN_DIR}/simStubsGen/generate_cmake_metadata.py
        ${LIBPLUGIN_DIR}/simStubsGen/generate_lua_calltips.py
        ${LIBPLUGIN_DIR}/simStubsGen/generate_lua_typechecker.py
        ${LIBPLUGIN_DIR}/simStubsGen/generate_lua_xml.py
        ${LIBPLUGIN_DIR}/simStubsGen/parse.py
        ${LIBPLUGIN_DIR}/simStubsGen/model/__init__.py
        ${LIBPLUGIN_DIR}/simStubsGen/model/command.py
        ${LIBPLUGIN_DIR}/simStubsGen/model/enum.py
        ${LIBPLUGIN_DIR}/simStubsGen/model/param.py
        ${LIBPLUGIN_DIR}/simStubsGen/model/plugin.py
        ${LIBPLUGIN_DIR}/simStubsGen/model/script_function.py
        ${LIBPLUGIN_DIR}/simStubsGen/model/struct.py
        ${LIBPLUGIN_DIR}/simStubsGen/cpp/plugin.h
        ${LIBPLUGIN_DIR}/simStubsGen/cpp/stubs.cpp
        ${LIBPLUGIN_DIR}/simStubsGen/cpp/stubs.h
        ${LIBPLUGIN_DIR}/simStubsGen/cpp/stubsPlusPlus.cpp
        ${LIBPLUGIN_DIR}/simStubsGen/xsd/callbacks.xsd
        ${LIBPLUGIN_DIR}/simStubsGen/xsl/reference.xsl
        ${COPPELIASIM_GENERATE_STUBS_XML_FILE}
    )
    if(NOT "${COPPELIASIM_GENERATE_STUBS_LUA_FILE}" STREQUAL "")
        list(APPEND OUTPUT_FILES ${GENERATED_OUTPUT_DIR}/lua_calltips.cpp)
        list(APPEND COMMAND_ARGS --lua-file ${COPPELIASIM_GENERATE_STUBS_LUA_FILE})
        list(APPEND DEPENDENCIES ${COPPELIASIM_GENERATE_STUBS_LUA_FILE})
        get_filename_component(LUA_FILE_NAME_WLE ${COPPELIASIM_GENERATE_STUBS_LUA_FILE} NAME_WLE)
        if(PLUGIN_VERSION GREATER 0)
            set(LUA_FILE_NAME ${LUA_FILE_NAME_WLE}-${PLUGIN_VERSION}.lua)
            list(APPEND OUTPUT_FILES ${GENERATED_OUTPUT_DIR}/${LUA_FILE_NAME_WLE}-typecheck-${PLUGIN_VERSION}.lua)
            install(FILES ${GENERATED_OUTPUT_DIR}/${LUA_FILE_NAME_WLE}-typecheck-${PLUGIN_VERSION}.lua DESTINATION ${COPPELIASIM_LUA_DIR})
        else()
            set(LUA_FILE_NAME ${LUA_FILE_NAME_WLE}.lua)
            list(APPEND OUTPUT_FILES ${GENERATED_OUTPUT_DIR}/${LUA_FILE_NAME_WLE}-typecheck.lua)
            install(FILES ${GENERATED_OUTPUT_DIR}/${LUA_FILE_NAME_WLE}-typecheck.lua DESTINATION ${COPPELIASIM_LUA_DIR})
        endif()
        install(FILES ${COPPELIASIM_GENERATE_STUBS_LUA_FILE} RENAME ${LUA_FILE_NAME} DESTINATION ${COPPELIASIM_LUA_DIR})
    endif()
    add_custom_command(OUTPUT ${OUTPUT_FILES} COMMAND ${COMMAND_ARGS} DEPENDS ${DEPENDENCIES})
    if(PLUGIN_VERSION GREATER 0)
        set(REFERENCE_FILE_NAME sim${PLUGIN_NAME}-${PLUGIN_VERSION}.htm)
        set(INDEX_FILE_NAME sim${PLUGIN_NAME}-${PLUGIN_VERSION}.json)
    else()
        set(REFERENCE_FILE_NAME sim${PLUGIN_NAME}.htm)
        set(INDEX_FILE_NAME sim${PLUGIN_NAME}.json)
    endif()
    install(FILES ${GENERATED_OUTPUT_DIR}/reference.html RENAME ${REFERENCE_FILE_NAME} DESTINATION ${COPPELIASIM_HELPFILES_DIR}/en)
    install(FILES ${GENERATED_OUTPUT_DIR}/index.json RENAME ${INDEX_FILE_NAME} DESTINATION ${COPPELIASIM_HELPFILES_DIR}/index)
    set_property(SOURCE ${GENERATED_OUTPUT_DIR}/stubs.cpp PROPERTY SKIP_AUTOGEN ON)
    set_property(SOURCE ${GENERATED_OUTPUT_DIR}/stubs.h PROPERTY SKIP_AUTOGEN ON)
    include_directories("${GENERATED_OUTPUT_DIR}")
    set(COPPELIASIM_EXPORTED_SOURCES ${COPPELIASIM_EXPORTED_SOURCES} "${GENERATED_OUTPUT_DIR}/stubs.cpp" PARENT_SCOPE)
endfunction(COPPELIASIM_GENERATE_STUBS)

find_package(Boost REQUIRED COMPONENTS regex)

function(COPPELIASIM_ADD_PLUGIN PLUGIN_TARGET_NAME)
    cmake_parse_arguments(COPPELIASIM_ADD_PLUGIN "LEGACY" "" "SOURCES" ${ARGN})
    if(PLUGIN_VERSION GREATER 0)
        set(PLUGIN_TARGET_NAME_V "${PLUGIN_TARGET_NAME}-${PLUGIN_VERSION}")
    else()
        set(PLUGIN_TARGET_NAME_V "${PLUGIN_TARGET_NAME}")
    endif()
    if(NOT COPPELIASIM_ADD_PLUGIN_LEGACY)
        set(COPPELIASIM_EXPORTED_SOURCES "${COPPELIASIM_EXPORTED_SOURCES}" "${LIBPLUGIN_DIR}/simPlusPlus/Lib.cpp" "${LIBPLUGIN_DIR}/simPlusPlus/Plugin.cpp" "${LIBPLUGIN_DIR}/simPlusPlus/Handle.cpp" PARENT_SCOPE)
        set(COPPELIASIM_EXPORTED_SOURCES "${COPPELIASIM_EXPORTED_SOURCES}" "${LIBPLUGIN_DIR}/simPlusPlus/Lib.cpp" "${LIBPLUGIN_DIR}/simPlusPlus/Plugin.cpp" "${LIBPLUGIN_DIR}/simPlusPlus/Handle.cpp")
    endif()
    add_library(${PLUGIN_TARGET_NAME_V} SHARED ${COPPELIASIM_EXPORTED_SOURCES} ${COPPELIASIM_ADD_PLUGIN_SOURCES})
    target_include_directories(${PLUGIN_TARGET_NAME_V} PRIVATE ${COPPELIASIM_INCLUDE_DIR})
    target_link_libraries(${PLUGIN_TARGET_NAME_V} ${COPPELIASIM_LIBRARIES})
    target_link_libraries(${PLUGIN_TARGET_NAME_V} Boost::boost Boost::regex)
    install(TARGETS ${PLUGIN_TARGET_NAME_V} DESTINATION ${COPPELIASIM_PLUGINS_DIR})
endfunction(COPPELIASIM_ADD_PLUGIN)

function(COPPELIASIM_ADD_EXECUTABLE EXECUTABLE_TARGET_NAME)
    cmake_parse_arguments(COPPELIASIM_ADD_EXECUTABLE "" "" "SOURCES" ${ARGN})
    add_executable(${EXECUTABLE_TARGET_NAME} ${COPPELIASIM_ADD_EXECUTABLE_SOURCES})
    install(TARGETS ${EXECUTABLE_TARGET_NAME} DESTINATION ${COPPELIASIM_PLUGINS_DIR})
endfunction(COPPELIASIM_ADD_EXECUTABLE)

function(COPPELIASIM_ADD_ADDON ADDON_FILE)
    install(FILES ${ADDON_FILE} DESTINATION ${COPPELIASIM_PLUGINS_DIR})
endfunction(COPPELIASIM_ADD_ADDON)

function(COPPELIASIM_ADD_LUA LUA_FILE)
    install(FILES ${LUA_FILE} DESTINATION ${COPPELIASIM_LUA_DIR})
endfunction(COPPELIASIM_ADD_LUA)

function(COPPELIASIM_ADD_HELPFILE HELP_FILE)
    cmake_parse_arguments(COPPELIASIM_ADD_HELPFILE "" "SUBDIR" "" ${ARGN})
    if(NOT COPPELIASIM_ADD_HELPFILE_SUBDIR)
        set(COPPELIASIM_ADD_HELPFILE_SUBDIR en)
    endif()
    install(FILES ${HELP_FILE} DESTINATION ${COPPELIASIM_HELPFILES_DIR}/${COPPELIASIM_ADD_HELPFILE_SUBDIR})
endfunction(COPPELIASIM_ADD_HELPFILE)

function(COPPELIASIM_ADD_LIBRARY LIB_FILE)
    install(FILES ${LIB_FILE} DESTINATION ${COPPELIASIM_LIBRARIES_DIR})
endfunction(COPPELIASIM_ADD_LIBRARY)

function(COPPELIASIM_ADD_PLUGIN_DIRECTORY DIR)
    install(DIRECTORY ${DIR} DESTINATION ${COPPELIASIM_PLUGINS_DIR})
endfunction(COPPELIASIM_ADD_PLUGIN_DIRECTORY)

function(COPPELIASIM_ADD_MODEL MODEL_FILE)
    cmake_parse_arguments(COPPELIASIM_ADD_MODEL "" "SUBDIR" "" ${ARGN})
    if(COPPELIASIM_ADD_MODEL_SUBDIR)
        install(FILES ${MODEL_FILE} DESTINATION ${COPPELIASIM_MODELS_DIR}/${COPPELIASIM_ADD_MODEL_SUBDIR})
    else()
        install(FILES ${MODEL_FILE} DESTINATION ${COPPELIASIM_MODELS_DIR})
    endif()
endfunction(COPPELIASIM_ADD_MODEL)

find_package(Git)
if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/.git AND GIT_FOUND)
    execute_process(
        COMMAND ${GIT_EXECUTABLE} rev-parse --short HEAD
        WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
        OUTPUT_VARIABLE "BUILD_GIT_VERSION"
        RESULT_VARIABLE "GIT_RESULT"
        ERROR_QUIET
        OUTPUT_STRIP_TRAILING_WHITESPACE)
    if(NOT GIT_RESULT EQUAL 0)
        set(BUILD_GIT_VERSION "unknown")
    endif()
else()
    set(BUILD_GIT_VERSION "unknown")
endif()

set(COPPELIASIM_FOUND TRUE)
