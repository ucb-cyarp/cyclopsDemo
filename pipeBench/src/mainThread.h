//
// Created by Christopher Yarp on 10/27/19.
//

#ifndef PIPEBENCH_MAINTHREAD_H
#define PIPEBENCH_MAINTHREAD_H

#include <stdint.h>
#include <stdbool.h>

#define SAMPLE_COMPONENT_DATATYPE float

typedef struct{
    char *txPipeName;
    char *rxPipeName;

    int32_t blockLen;
} threadArgs_t;

void* mainThread(void* uncastArgs);

#endif //PIPEBENCH_MAINTHREAD_H
