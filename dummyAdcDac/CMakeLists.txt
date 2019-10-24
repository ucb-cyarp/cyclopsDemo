cmake_minimum_required(VERSION 3.5.1)
project(dummyAdcDac C)

set(CMAKE_C_STANDARD 11)

find_package(Threads)

set(COMMON_SRCS
        src/mainThread.c
        src/mainThread.h)

add_executable(dummyAdcDac src/main.c ${COMMON_SRCS})
target_link_libraries(dummyAdcDac ${CMAKE_THREAD_LIBS_INIT})