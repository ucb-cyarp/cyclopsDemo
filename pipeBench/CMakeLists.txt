cmake_minimum_required(VERSION 3.5.1)
project(pipeBench C)

find_package(Threads)

set(CMAKE_C_STANDARD 11)

set(COMMON_SRCS
        src/mainThread.c
        src/mainThread.h
        src/helpers.c
        src/helpers.h)

add_executable(pipeBench src/main.c ${COMMON_SRCS})
target_link_libraries(pipeBench ${CMAKE_THREAD_LIBS_INIT})