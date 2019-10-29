cmake_minimum_required(VERSION 3.5.1)
project(dummyAdcDac C)

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

set(COMMON_SRCS
        src/mainThread.c
        src/mainThread.h)

add_executable(dummyAdcDac src/main.c ${COMMON_SRCS})
target_link_libraries(dummyAdcDac ${CMAKE_THREAD_LIBS_INIT})