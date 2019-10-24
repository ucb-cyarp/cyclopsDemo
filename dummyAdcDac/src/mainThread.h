//
// Created by Christopher Yarp on 10/23/19.
//

#ifndef DUMMYADCDAC_MAINTHREAD_H
#define DUMMYADCDAC_MAINTHREAD_H

#include <stdint.h>
#include <stdbool.h>

#define FEEDBACK_DATATYPE int32_t
#define SAMPLE_COMPONENT_DATATYPE float

typedef struct{
    char *txPipeName;
    char *txFeedbackPipeName;
    char *rxPipeName;

    int32_t blockLen;
    bool print;
} threadArgs_t;

void* mainThread(void* uncastArgs);

#endif //DUMMYADCDAC_MAINTHREAD_H
