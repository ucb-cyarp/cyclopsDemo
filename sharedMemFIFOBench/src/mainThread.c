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

#include "SharedMemoryFIFO.h"

#define TIME_DURATION (1.0)

void* mainThread(void* uncastArgs){
    threadArgs_t* args = (threadArgs_t*) uncastArgs;
    char *txSharedName = args->txSharedName;
    char *rxSharedName = args->rxSharedName;
    size_t fifoSizeBlocks = args->fifoSizeBlocks;
    int32_t blockLen = args->blockLen;

    //Open shared memory (if applicable)
    int rxSharedFD = -1;
    int txSharedFD = -1;

    sem_t *rxSem = NULL;
    sem_t *txSem = NULL;

    char* rxSemaphoreName = NULL;
    char* txSemaphoreName = NULL;

    atomic_int_fast32_t* rxFifoCount = NULL;
    atomic_int_fast32_t* txFifoCount = NULL;

    volatile void* fifoBlock = NULL;
    volatile void* fifoBuffer = NULL;

    size_t fifoBufferSizeBytes = SAMPLE_SIZE*fifoSizeBlocks*blockLen;
    size_t fifoBlockSizeBytes = fifoBufferSizeBytes + sizeof(atomic_int_fast32_t);

    if(txSharedName != NULL) {
        producerOpenInitFIFOBlock(txSharedName, &txSharedFD, &txSemaphoreName, &rxSemaphoreName, &txSem, &rxSem, &txFifoCount, &fifoBlock,
                                  &fifoBuffer, fifoBufferSizeBytes);
    }

    if(rxSharedName != NULL) {
        consumerOpenFIFOBlock(rxSharedName, &rxSharedFD, &txSemaphoreName, &rxSemaphoreName, &txSem, &rxSem, &rxFifoCount, &fifoBlock, &fifoBuffer, fifoBufferSizeBytes);
    }

    //If transmitting, allocate arrays and form a Tx packet
    SAMPLE_COMPONENT_DATATYPE* sampBuffer = (SAMPLE_COMPONENT_DATATYPE*) malloc(sizeof(SAMPLE_COMPONENT_DATATYPE)*2*blockLen);

    uint64_t samplesRecv = 0;
    uint64_t samplesSent = 0;

    time_t recvStartTime;
    time_t sendStartTime;

    time_t lastRecvPrint;
    time_t lastSendPrint;

    //Main Loop
    bool running = true;

    size_t rxCurrentOffset = 0;
    size_t txCurrentOffset = 0;

    SAMPLE_COMPONENT_DATATYPE rxFifoExpectedVal = 0;
    SAMPLE_COMPONENT_DATATYPE txFifoExpectedVal = 0;

    while(running){
        if(rxSharedName != NULL) {
            //Get samples from rx pipe (ok to block)

            int samplesRead = read_fifo(fifoBufferSizeBytes, rxFifoCount, &rxCurrentOffset, sampBuffer, fifoBuffer, sizeof(SAMPLE_COMPONENT_DATATYPE) * 2, blockLen);
            if(samplesRecv == 0){
                recvStartTime = time(NULL);
                lastRecvPrint = recvStartTime;
            }
            if (samplesRead != blockLen) {
                //TODO: Need to include method to determine when finished.  Right now, this should never happen and will block indefinatly
                //Done!
                running = false;
                break;
            }

            samplesRecv+=samplesRead;

            time_t currentTime = time(NULL);
            double duration = difftime(currentTime, lastRecvPrint);
            if(duration >= TIME_DURATION){
                lastRecvPrint = currentTime;
                double totalDuration = difftime(currentTime, recvStartTime);
                double msps = samplesRecv/totalDuration/1000000.0;
                printf("Recv Rate %f Msps\n", msps);
            }

            //Verify FIFO recv values
            //TODO: comment out for accurate speed
            for(int i = 0; i<blockLen; i++){
                if(sampBuffer[i*2] != rxFifoExpectedVal || sampBuffer[i*2+1] != rxFifoExpectedVal){
                    printf("FIFO ERROR!");
                    exit(1);
                }
            }
            rxFifoExpectedVal += 1;
        }

        if(txSharedName != NULL) {

            //TODO: comment out for accurate speed
            for(int i = 0; i<blockLen; i++){
                sampBuffer[i*2] = txFifoExpectedVal;
                sampBuffer[i*2+1] = txFifoExpectedVal;
            }
            txFifoExpectedVal += 1;

            //Write samples to tx pipe (ok to block)
            write_fifo(fifoBufferSizeBytes, txFifoCount, &txCurrentOffset, fifoBuffer, sampBuffer, sizeof(SAMPLE_COMPONENT_DATATYPE) * 2, blockLen);
            if(samplesSent == 0){
                sendStartTime = time(NULL);
            }
            samplesSent+=blockLen;

            time_t currentTime = time(NULL);
            double duration = difftime(currentTime, lastSendPrint);
            if(duration >= TIME_DURATION){
                lastSendPrint = currentTime;
                double totalDuration = difftime(currentTime, sendStartTime);
                double msps = samplesSent/totalDuration/1000000.0;
                printf("Send Rate %f Msps\n", msps);
            }
        }
    }

    //Both Tx and Rx need to do this
    int status = munmap(fifoBlock, fifoBlockSizeBytes);
    if(status == -1){
        printf("Error in tx munmap\n");
        perror(NULL);
    }

    status = sem_close(txSem);
    if(status == -1){
        printf("Error in tx semaphore close\n");
        perror(NULL);
    }

    status = sem_close(rxSem);
    if(status == -1){
        printf("Error in rx semaphore close\n");
        perror(NULL);
    }

    if(txSem != NULL){
        //Producer is responsible for unlinking semaphore too

        status = shm_unlink(txSharedName);
        if(status == -1){
            printf("Error in tx fifo unlink\n");
            perror(NULL);
        }

        status = sem_unlink(txSemaphoreName);
        if(status == -1){
            printf("Error in tx semaphore unlink\n");
            perror(NULL);
        }

        status = sem_unlink(rxSemaphoreName);
        if(status == -1){
            printf("Error in rx semaphore unlink\n");
            perror(NULL);
        }
    }

    if(txSemaphoreName != NULL){
        free(txSemaphoreName);
    }

    if(rxSemaphoreName != NULL){
        free(rxSemaphoreName);
    }

    free(sampBuffer);

    return NULL;
}