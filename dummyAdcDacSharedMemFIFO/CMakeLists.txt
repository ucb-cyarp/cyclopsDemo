cmake_minimum_required(VERSION 3.5.1)
project(dummyAdcDacSharedMemFIFO C)

#Using technique from Marcus D. Hanwell on https://blog.kitware.com/cmake-and-the-default-build-type/ to set default build type
set(default_build_type "Release")
if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    message(STATUS "Setting build type to '${default_build_type}' as none was specified.")
    set(CMAKE_BUILD_TYPE "${default_build_type}" CACHE
            STRING "Choose the type of build." FORCE)
    set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS
            "Debug" "Release" "MinSizeRel" "RelWithDebInfo")
endif()

set(CMAKE_C_STANDARD 11)

find_package(Threads)
find_library(LIBRT rt)
if(NOT LIBRT)
    message(FATAL_ERROR "librt not found")
endif()

set(COMMON_SRCS
        src/SharedMemoryFIFO.c
        src/SharedMemoryFIFO.h
        src/mainThread.c
        src/mainThread.h)

add_executable(dummyAdcDacSharedMemFIFO src/main.c ${COMMON_SRCS})
target_link_libraries(dummyAdcDacSharedMemFIFO ${CMAKE_THREAD_LIBS_INIT} ${LIBRT})