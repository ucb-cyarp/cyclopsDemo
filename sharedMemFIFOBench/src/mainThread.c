//
// Created by Christopher Yarp on 10/28/19.
//

#include "mainThread.h"

#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <time.h>
#include <semaphore.h>
#include <sys/mman.h>
#include <stdatomic.h>
#include <unistd.h>

#include "helpers.h"

#include "depends/BerkeleySharedMemoryFIFO.h"

#define TIME_DURATION (1.0)

// #define CHECK_CONTENTS

void* mainThread(void* uncastArgs){
    threadArgs_t* args = (threadArgs_t*) uncastArgs;
    char *txSharedName = args->txSharedName;
    char *rxSharedName = args->rxSharedName;
    size_t fifoSizeBlocks = args->fifoSizeBlocks;
    int32_t blockLen = args->blockLen;

    //Open shared memory

    sharedMemoryFIFO_t sharedMemoryFifo;
    initSharedMemoryFIFO(&sharedMemoryFifo);

    size_t fifoBufferSizeBytes = SAMPLE_SIZE*fifoSizeBlocks*blockLen;
    size_t fifoBlockSizeBytes = fifoBufferSizeBytes + sizeof(atomic_int_fast32_t);

    if(txSharedName != NULL) {
        producerOpenInitFIFO(txSharedName, fifoBufferSizeBytes, &sharedMemoryFifo);
    }

    if(rxSharedName != NULL) {
        consumerOpenFIFOBlock(rxSharedName, fifoBufferSizeBytes, &sharedMemoryFifo);
    }

    //If transmitting, allocate arrays and form a Tx packet
    SAMPLE_COMPONENT_DATATYPE* sampBuffer = (SAMPLE_COMPONENT_DATATYPE*) malloc(sizeof(SAMPLE_COMPONENT_DATATYPE)*2*blockLen);

    uint64_t samplesRecv = 0;
    uint64_t samplesSent = 0;

    timespec_t recvStartTime;
    timespec_t sendStartTime;

    timespec_t lastRecvPrint;
    timespec_t lastSendPrint;

    //Main Loop
    bool running = true;

    SAMPLE_COMPONENT_DATATYPE rxFifoExpectedVal = 0;
    SAMPLE_COMPONENT_DATATYPE txFifoExpectedVal = 0;

    for(int i = 0; i<blockLen; i++){
        sampBuffer[i*2] = 0;
        sampBuffer[i*2+1] = 0;
    }

    printf("Sample Size: %ld bytes\n", sizeof(SAMPLE_COMPONENT_DATATYPE) * 2); //Assume sending complex samples
    printf("Block Size: %d samples\n", blockLen);
    
    if(rxSharedName != NULL) {
        asm volatile ("" ::: "memory"); //Stop Re-ordering of timer
        clock_gettime(CLOCK_MONOTONIC, &recvStartTime);
        asm volatile ("" ::: "memory"); //Stop Re-ordering of timer
        lastRecvPrint = recvStartTime;

        while(running){
            //Get samples from rx pipe (ok to block)
            int samplesRead = readFifo( sampBuffer, sizeof(SAMPLE_COMPONENT_DATATYPE) * 2, blockLen, &sharedMemoryFifo);
            if (samplesRead != blockLen) {
                //TODO: Need to include method to determine when finished.  Right now, this should never happen and will block indefinatly
                //Done!
                running = false;
                break;
            }
            samplesRecv+=samplesRead;

            #ifdef CHECK_CONTENTS
                //Verify FIFO recv values
                for(int i = 0; i<blockLen; i++){
                    if(sampBuffer[i*2] != rxFifoExpectedVal || sampBuffer[i*2+1] != rxFifoExpectedVal){
                        printf("FIFO ERROR!");
                        exit(1);
                    }
                }
                rxFifoExpectedVal += 1;
            #else
                //Need to make sure that the memory copy is not optimized out if the content is not checked
                asm volatile(""
                :
                : "r" (*(const SAMPLE_COMPONENT_DATATYPE (*)[]) sampBuffer) //See https://gcc.gnu.org/onlinedocs/gcc/Extended-Asm.html for information for "string memory arguments"
                :);
            #endif

            timespec_t currentTime;
            asm volatile ("" ::: "memory"); //Stop Re-ordering of timer
            clock_gettime(CLOCK_MONOTONIC, &currentTime);
            asm volatile ("" ::: "memory"); //Stop Re-ordering of timer

            double duration = difftimespec(&currentTime, &lastRecvPrint);
            if(duration >= TIME_DURATION){
                lastRecvPrint = currentTime;
                double totalDuration = difftimespec(&currentTime, &recvStartTime);
                double msps = samplesRecv/totalDuration/1000000.0;
                double nsPerSample = totalDuration*1.0e9/samplesRecv;
                printf("Recv Rate: %f Msps, ns Per Sample: %f\n", msps, nsPerSample);
            }
        }
    }

    if(txSharedName != NULL) {
        asm volatile ("" ::: "memory"); //Stop Re-ordering of timer
        clock_gettime(CLOCK_MONOTONIC, &sendStartTime);
        asm volatile ("" ::: "memory"); //Stop Re-ordering of timer
        lastSendPrint = sendStartTime;

        while(running){
            #ifdef CHECK_CONTENTS
                for(int i = 0; i<blockLen; i++){
                    sampBuffer[i*2] = txFifoExpectedVal;
                    sampBuffer[i*2+1] = txFifoExpectedVal;
                }
                txFifoExpectedVal += 1;
            #else
                asm volatile(""
                : "+m" (*sampBuffer) //See https://gcc.gnu.org/onlinedocs/gcc/Extended-Asm.html for information for "string memory arguments"
                : 
                :);
            #endif

            //Write samples to tx pipe (ok to block)
            writeFifo(sampBuffer, sizeof(SAMPLE_COMPONENT_DATATYPE) * 2, blockLen, &sharedMemoryFifo);
            samplesSent+=blockLen;

            timespec_t currentTime;
            asm volatile ("" ::: "memory"); //Stop Re-ordering of timer
            clock_gettime(CLOCK_MONOTONIC, &currentTime);
            asm volatile ("" ::: "memory"); //Stop Re-ordering of timer

            double duration = difftimespec(&currentTime, &lastSendPrint);
            if(duration >= TIME_DURATION){
                lastSendPrint = currentTime;
                double totalDuration = difftimespec(&currentTime, &sendStartTime);
                double msps = samplesSent/totalDuration/1000000.0;
                double nsPerSample = totalDuration*1.0e9/samplesSent;
                printf("Send Rate: %f Msps, ns Per Sample: %f\n", msps, nsPerSample);
            }
        }
    }

    if(txSharedName != NULL){
        cleanupProducer(&sharedMemoryFifo);
    }else if(rxSharedName != NULL){
        cleanupConsumer(&sharedMemoryFifo);
    }

    free(sampBuffer);

    return NULL;
}