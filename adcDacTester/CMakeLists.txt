cmake_minimum_required(VERSION 3.5.1)
project(adcDacTester C)

find_package(Threads)

set(CMAKE_C_STANDARD 11)

set(COMMON_SRCS
        src/mainThread.c
        src/mainThread.h
        src/helpers.c
        src/helpers.h)

add_executable(adcDacTester src/main.c ${COMMON_SRCS})
target_link_libraries(adcDacTester ${CMAKE_THREAD_LIBS_INIT})