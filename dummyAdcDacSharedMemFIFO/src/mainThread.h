//
// Created by Christopher Yarp on 10/28/19.
//

#ifndef DUMMYADCDACSHAREDMEMFIFO_MAINTHREAD_H
#define DUMMYADCDACSHAREDMEMFIFO_MAINTHREAD_H

#include <stdint.h>
#include <stdbool.h>

#define FEEDBACK_DATATYPE int32_t
#define SAMPLE_COMPONENT_DATATYPE float
#define SAMPLE_SIZE (sizeof(SAMPLE_COMPONENT_DATATYPE)*2)

typedef struct{
    char *txSharedName;
    char *txFeedbackSharedName;
    char *rxSharedName;
    float gain;

    int32_t blockLen;
    int32_t fifoSizeBlocks;

    bool print;
} threadArgs_t;

void* mainThread(void* uncastArgs);

#endif //DUMMYADCDACSHAREDMEMFIFO_MAINTHREAD_H
