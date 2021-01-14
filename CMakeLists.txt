# Copyright (c) 2020, Cyrille Favreau
# All rights reserved. Do not distribute without permission.
# Responsible Author: Cyrille Favreau <cyrille.favreau@epfl.ch>
#
# This file is part of https://github.com/favreau/Brayns-UC-Fields

cmake_minimum_required(VERSION 3.1 FATAL_ERROR)

# ==============================================================================
# Project
# ==============================================================================
set(NAME BRAYNSFRACTALS)
set(LIBRARY_NAME braynsFractals)
project(${NAME} VERSION 0.1.0)
set(${NAME}_VERSION_ABI 1)

# ==============================================================================
# Packages and settings
# ==============================================================================
list(APPEND CMAKE_MODULE_PATH ${PROJECT_SOURCE_DIR}/CMake)
set(${NAME}_MODULES_DIR ${PROJECT_SOURCE_DIR})
set(CMAKE_CXX_STANDARD 14) # C++ 14

find_package(Brayns REQUIRED SYSTEM)
find_package(ospray REQUIRED SYSTEM)

include(ispc)

# ==============================================================================
# Sources
# ==============================================================================
set(${NAME}_SOURCES
    module/ispc/render/FractalsRenderer.cpp
    module/ispc/render/MengerSpongeRenderer.cpp
    module/ispc/render/VoxelizerRenderer.cpp
    plugin/FractalsPlugin.cpp
)

set(${NAME}_PUBLIC_HEADERS
    module/ispc/render/FractalsRenderer.h
    module/ispc/render/MengerSpongeRenderer.h
    module/ispc/render/VoxelizerRenderer.h
    plugin/FractalsPlugin.h
)

set(${NAME}_ISPC_SOURCES
    module/ispc/render/Utils.ispc
    module/ispc/render/FractalsRenderer.ispc
    module/ispc/render/MengerSpongeRenderer.ispc
    module/ispc/render/VoxelizerRenderer.ispc
)

# ==============================================================================
# Compile ispc code
# ==============================================================================
list(APPEND CMAKE_MODULE_PATH ${OSPRAY_CMAKE_ROOT})
list(APPEND ALL_ISPC_INCLUDES ${${NAME}_MODULES_DIR})
list(APPEND ALL_ISPC_INCLUDES ${OSPRAY_INCLUDE_DIRS})
list(APPEND ALL_ISPC_INCLUDES ${GLM_INCLUDE_DIRS})
include_directories_ispc(${ALL_ISPC_INCLUDES})
ospray_ispc_compile(${${NAME}_ISPC_SOURCES})
list(APPEND ${NAME}_SOURCES ${ISPC_OBJECTS})

# ==============================================================================
# Compile c++ code
# ==============================================================================
include_directories(
    ${PROJECT_SOURCE_DIR}
    ${OSPRAY_INCLUDE_DIRS}
    ${BRAYNS_INCLUDE_DIRS}
    ${GLM_INCLUDE_DIRS}
    ${Boost_INCLUDE_DIRS}
    ${${NAME}_MODULES_DIR}
)

set(${NAME}_LINK_LIBRARIES
    PUBLIC ${OSPRAY_LIBRARIES} 
    PRIVATE braynsParameters braynsPluginAPI braynsCommon braynsEngine braynsIO
            braynsOSPRayEngine
)

add_library(
    ${LIBRARY_NAME}
    SHARED ${${NAME}_SOURCES})

target_link_libraries(
    ${LIBRARY_NAME}
    ${${NAME}_LINK_LIBRARIES})

# ==============================================================================
# Install binaries
# ==============================================================================
INSTALL(TARGETS ${LIBRARY_NAME}
    RUNTIME DESTINATION bin
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib)
