//
// Created by Christopher Yarp on 10/22/19.
//

#ifndef ADCDACTESTER_MAINTHREAD_H
#define ADCDACTESTER_MAINTHREAD_H

#include <stdint.h>
#include <stdbool.h>

#define FEEDBACK_DATATYPE int32_t
#define SAMPLE_COMPONENT_DATATYPE float

#define SAMPLE_COMPONENT_INIT_VAL (0)

typedef struct{
    char *txPipeName;
    char *txFeedbackPipeName;
    char *rxPipeName;

    int32_t txTokens;
    int32_t maxBlocksToProcess;
    int32_t blockLen;
    bool print;
} threadArgs_t;

void* mainThread(void* args);

#endif //ADCDACTESTER_MAINTHREAD_H
