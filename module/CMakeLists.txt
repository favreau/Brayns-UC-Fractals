# Copyright (c) Cyrille Favreau
# All rights reserved. Do not distribute without permission.
# Responsible Author: Cyrille Favreau <cyrille.favreau@gmail.com>
#
# This file is part of https://github.com/favreau/Brayns-UC-Fractals

cmake_minimum_required(VERSION 3.1 FATAL_ERROR)
set(MODULE_NAME ospray_module_fractals)
project(${MODULE_NAME} VERSION 1.0.0)
set(${MODULE_NAME}_VERSION_ABI 1)

# C++ 11
add_compile_options(-std=c++11 -fPIC)

# OSPRay
list(APPEND CMAKE_MODULE_PATH ${OSPRAY_CMAKE_ROOT})
list(APPEND CMAKE_MODULE_PATH ${PROJECT_SOURCE_DIR}/CMake)
find_package(ospray REQUIRED SYSTEM)
include(ispc)

set(MODULE_SOURCES
    fractals.cpp
    ispc/renderer/VoxelizerRenderer.cpp
    ispc/renderer/MengerSpongeRenderer.cpp
    ispc/renderer/FractalsRenderer.cpp)

set(MODULE_ISPC_SOURCES
    ispc/renderer/Utils.ispc
    ispc/renderer/VoxelizerRenderer.ispc
    ispc/renderer/MengerSpongeRenderer.ispc
    ispc/renderer/FractalsRenderer.ispc)

# Compile ispc code
list(APPEND ALL_ISPC_INCLUDES ${BRAYNS_RESEARCH_MODULES_DIR})
list(APPEND ALL_ISPC_INCLUDES ${OSPRAY_INCLUDE_DIRS})
include_directories_ispc(${ALL_ISPC_INCLUDES})
ospray_ispc_compile(${MODULE_ISPC_SOURCES})
list(APPEND MODULE_SOURCES ${ISPC_OBJECTS})

# Compile C++ code
include_directories(${BRAYNS_RESEARCH_MODULES_DIR} ${OSPRAY_INCLUDE_DIRS})
set(MODULE_LINK_LIBRARIES PUBLIC ${OSPRAY_LIBRARIES})
add_library(${MODULE_NAME} SHARED ${MODULE_SOURCES})
target_link_libraries(${MODULE_NAME} ${MODULE_LINK_LIBRARIES})

# Installation
install(TARGETS ${MODULE_NAME}
    RUNTIME DESTINATION bin
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib)
