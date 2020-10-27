//
// Created by Christopher Yarp on 10/28/19.
//

#ifndef SHAREDMEMFIFOBENCH_MAINTHREAD_H
#define SHAREDMEMFIFOBENCH_MAINTHREAD_H

#include <stdint.h>
#include <stdbool.h>
#include <string.h>

#define SAMPLE_COMPONENT_DATATYPE short
#define SAMPLE_SIZE (sizeof(SAMPLE_COMPONENT_DATATYPE)*2)

typedef struct{
    char *txSharedName;
    char *rxSharedName;

    size_t fifoSizeBlocks; //Number of blocks in the FIFO
    int32_t blockLen;
} threadArgs_t;

void* mainThread(void* uncastArgs);


#endif //SHAREDMEMFIFOBENCH_MAINTHREAD_H
