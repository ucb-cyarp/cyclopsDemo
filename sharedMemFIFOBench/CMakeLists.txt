cmake_minimum_required(VERSION 3.5.1)
project(sharedMemFIFOBench C)

#Using technique from Marcus D. Hanwell on https://blog.kitware.com/cmake-and-the-default-build-type/ to set default build type
set(default_build_type "Release")
if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    message(STATUS "Setting build type to '${default_build_type}' as none was specified.")
    set(CMAKE_BUILD_TYPE "${default_build_type}" CACHE
            STRING "Choose the type of build." FORCE)
    set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS
            "Debug" "Release" "MinSizeRel" "RelWithDebInfo")
endif()

find_package(Threads)
find_library(LIBRT rt)
if(NOT LIBRT)
    message(FATAL_ERROR "librt not found")
endif()

set(CMAKE_C_STANDARD 11)

set(COMMON_SRCS
        src/mainThread.c
        src/mainThread.h
        src/depends/BerkeleySharedMemoryFIFO.c
        src/depends/BerkeleySharedMemoryFIFO.h)

add_executable(sharedMemFIFOBench src/main.c ${COMMON_SRCS})
target_link_libraries(sharedMemFIFOBench ${CMAKE_THREAD_LIBS_INIT} ${LIBRT})

add_executable(cleanupShared src/cleanupShared.c)
target_link_libraries(cleanupShared ${CMAKE_THREAD_LIBS_INIT} ${LIBRT})