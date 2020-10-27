//
// Created by Christopher Yarp on 10/27/19.
//

#include "mainThread.h"


#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <time.h>

#include "helpers.h"

#define TIME_DURATION (1.0)

void* mainThread(void* uncastArgs){
    threadArgs_t* args = (threadArgs_t*) uncastArgs;
    char *txPipeName = args->txPipeName;
    char *rxPipeName = args->rxPipeName;
    int flushPeriod = args->flushPeriod;

    int32_t blockLen = args->blockLen;

    //Open Pipes (if applicable)
    FILE *rxPipe = NULL;
    FILE *txPipe = NULL;

    if(rxPipeName != NULL) {
        rxPipe = fopen(rxPipeName, "rb");
        if (rxPipe == NULL) {
            printf("Unable to open Rx Pipe ... exiting\n");
            perror(NULL);
            exit(1);
        }
    }

    if(txPipeName != NULL) {
        txPipe = fopen(txPipeName, "wb");
        if (txPipe == NULL) {
            printf("Unable to open Tx Pipe ... exiting\n");
            perror(NULL);
            exit(1);
        }
    }

    //If transmitting, allocate arrays and form a Tx packet
    SAMPLE_COMPONENT_DATATYPE* sampBuffer = (SAMPLE_COMPONENT_DATATYPE*) malloc(sizeof(SAMPLE_COMPONENT_DATATYPE)*2*blockLen); //Assume sending complex samples
    for(int i = 0; i<2*blockLen; i++){ //Assume sending complex sample
        sampBuffer[i]=0;
    }

    int flushCounter = 0;

    uint64_t samplesRecv = 0;
    uint64_t samplesSent = 0;

    timespec_t recvStartTime;
    timespec_t sendStartTime;

    timespec_t lastRecvPrint;
    timespec_t lastSendPrint;

    //Main Loop
    bool running = true;

    printf("Sample Size: %ld bytes\n", sizeof(SAMPLE_COMPONENT_DATATYPE) * 2); //Assume sending complex samples
    printf("Block Size: %d samples\n", blockLen);
    printf("Flush Period: %d Transmissions\n", flushPeriod);

    if(rxPipe != NULL) {
        asm volatile ("" ::: "memory"); //Stop Re-ordering of timer
        clock_gettime(CLOCK_MONOTONIC, &recvStartTime);
        asm volatile ("" ::: "memory"); //Stop Re-ordering of timer
        lastRecvPrint = recvStartTime;

        while(running){
            //Get samples from rx pipe (ok to block)
            int samplesRead = fread(sampBuffer, sizeof(SAMPLE_COMPONENT_DATATYPE) * 2, blockLen, rxPipe);
            if (samplesRead != blockLen && feof(rxPipe)) {
                //Done!
                running = false;
                break;
            } else if (samplesRead != blockLen && ferror(rxPipe)) {
                printf("An error was encountered while reading the Rx pipe\n");
                perror(NULL);
                exit(1);
            } else if (samplesRead != blockLen) {
                printf("An unknown error was encountered while reading the Rx pipe\n");
                exit(1);
            }

            samplesRecv+=samplesRead;

            //Need to make sure that the memory copy is not optimized out if the content is not checked
            asm volatile(""
            :
            : "r" (*(const SAMPLE_COMPONENT_DATATYPE (*)[]) sampBuffer) //See https://gcc.gnu.org/onlinedocs/gcc/Extended-Asm.html for information for "string memory arguments"
            :);

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

    if(txPipe != NULL) {
        asm volatile ("" ::: "memory"); //Stop Re-ordering of timer
        clock_gettime(CLOCK_MONOTONIC, &sendStartTime);
        asm volatile ("" ::: "memory"); //Stop Re-ordering of timer
        lastSendPrint = sendStartTime;

        while(running){
            asm volatile(""
                : "+m" (*sampBuffer) //See https://gcc.gnu.org/onlinedocs/gcc/Extended-Asm.html for information for "string memory arguments"
                : 
                :);
                
            //Write samples to tx pipe (ok to block)
            fwrite(sampBuffer, sizeof(SAMPLE_COMPONENT_DATATYPE) * 2, blockLen, txPipe);
            samplesSent+=blockLen;

            if(flushCounter >= flushPeriod){
                fflush(txPipe);
                flushCounter = 0;
            }else{
                flushCounter++;
            }

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

    free(sampBuffer);

    return NULL;
}