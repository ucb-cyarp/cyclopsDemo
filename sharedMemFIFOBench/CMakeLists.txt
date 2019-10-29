cmake_minimum_required(VERSION 3.5.1)
project(sharedMemFIFOBench C)

find_package(Threads)
find_library(LIBRT rt)

set(CMAKE_C_STANDARD 11)

set(COMMON_SRCS
        src/mainThread.c
        src/mainThread.h
        src/helpers.c
        src/helpers.h)

add_executable(sharedMemFIFOBench src/main.c ${COMMON_SRCS})
target_link_libraries(sharedMemFIFOBench ${CMAKE_THREAD_LIBS_INIT} ${LIB_RT})