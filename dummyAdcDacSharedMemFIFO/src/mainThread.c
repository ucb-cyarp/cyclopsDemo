//
// Created by Christopher Yarp on 10/28/19.
//

#include "mainThread.h"

#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <sys/mman.h>
#include <stdatomic.h>

#include "depends/BerkeleySharedMemoryFIFO.h"

void* mainThread(void* uncastArgs){
    threadArgs_t* args = (threadArgs_t*) uncastArgs;
    char *txSharedName = args->txSharedName;
    char *txFeedbackSharedName = args->txFeedbackSharedName;
    char *rxSharedName = args->rxSharedName;
    float gain = args->gain;

    int32_t blockLen = args->blockLen;
    int32_t fifoSizeBlocks = args->fifoSizeBlocks;
    bool print = args->print;

    //---- Constants for opening FIFOs ----
    sharedMemoryFIFO_t txFifo;
    sharedMemoryFIFO_t txfbFifo;
    sharedMemoryFIFO_t rxFifo;

    initSharedMemoryFIFO(&txFifo);
    initSharedMemoryFIFO(&txfbFifo);
    initSharedMemoryFIFO(&rxFifo);

    size_t fifoBufferSizeBytes = SAMPLE_SIZE*fifoSizeBlocks*blockLen;
    size_t txfbFifoBufferSizeBytes = sizeof(FEEDBACK_DATATYPE)*fifoSizeBlocks;

    //Initialize Producer FIFOs first to avoid deadlock
    //Note, producer fifos block on consumer joining durring the first write
    producerOpenInitFIFO(rxSharedName, fifoBufferSizeBytes, &rxFifo);
    producerOpenInitFIFO(txFeedbackSharedName, txfbFifoBufferSizeBytes, &txfbFifo);
    consumerOpenFIFOBlock(txSharedName, fifoBufferSizeBytes, &txFifo);

    //If transmitting, allocate arrays and form a Tx packet
    SAMPLE_COMPONENT_DATATYPE* sampBuffer = (SAMPLE_COMPONENT_DATATYPE*) malloc(sizeof(SAMPLE_COMPONENT_DATATYPE)*2*blockLen);

    //Main Loop
    bool running = true;
    while(running){
        //Get samples from rx pipe (ok to block)
        // printf("About to read samples\n");
        int samplesRead = readFifo(sampBuffer, sizeof(SAMPLE_COMPONENT_DATATYPE) * 2, blockLen, &txFifo);
        if (samplesRead != blockLen) {
            //Done!
            running = false;
            break;
        }
        // printf("Read\n");

        if(gain !=0){
            for(int i = 0; i<blockLen*2; i++){
                sampBuffer[i] *= gain;
            }
        }

        //Write samples to tx pipe (ok to block)
        // printf("About to write samples\n");
        writeFifo(sampBuffer, sizeof(SAMPLE_COMPONENT_DATATYPE) * 2, blockLen, &rxFifo);
        // printf("Wrote samples\n");
        // printf("About to write token\n");
        FEEDBACK_DATATYPE tokensReturned = 1;
        writeFifo(&tokensReturned, sizeof(tokensReturned), 1, &txfbFifo);
        // printf("Wrote token\n");
    }

    free(sampBuffer);

    return NULL;
}