//
// Created by Christopher Yarp on 10/27/19.
//

#include "mainThread.h"


#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <time.h>

#define TIME_DURATION (1.0)

void* mainThread(void* uncastArgs){
    threadArgs_t* args = (threadArgs_t*) uncastArgs;
    char *txPipeName = args->txPipeName;
    char *rxPipeName = args->rxPipeName;

    int32_t blockLen = args->blockLen;

    //Open Pipes (if applicable)
    FILE *rxPipe = NULL;
    FILE *txPipe = NULL;
    FILE *txFeedbackPipe = NULL;

    if(rxPipeName != NULL) {
        rxPipe = fopen(rxPipeName, "wb");
        if (rxPipe == NULL) {
            printf("Unable to open Rx Pipe ... exiting\n");
            perror(NULL);
            exit(1);
        }
    }

    if(txPipeName != NULL) {
        txPipe = fopen(txPipeName, "rb");
        if (txPipe == NULL) {
            printf("Unable to open Tx Pipe ... exiting\n");
            perror(NULL);
            exit(1);
        }
    }

    //If transmitting, allocate arrays and form a Tx packet
    SAMPLE_COMPONENT_DATATYPE* sampBuffer = (SAMPLE_COMPONENT_DATATYPE*) malloc(sizeof(SAMPLE_COMPONENT_DATATYPE)*2*blockLen);

    int flushCounter = 0;
    int flushPeriod = 1;

    int samplesRecv = 0;
    int samplesSent = 0;

    time_t recvStartTime;
    time_t sendStartTime;

    time_t lastRecvPrint;
    time_t lastSendPrint;

    //Main Loop
    bool running = true;
    while(running){
        if(rxPipe != NULL) {
            //Get samples from rx pipe (ok to block)
            int samplesRead = fread(sampBuffer, sizeof(SAMPLE_COMPONENT_DATATYPE) * 2, blockLen, rxPipe);
            if(samplesRecv == 0){
                recvStartTime = time(NULL);
                lastRecvPrint = recvStartTime;
            }
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

            time_t currentTime = time(NULL);
            double duration = difftime(currentTime, lastRecvPrint);
            if(duration >= TIME_DURATION){
                lastRecvPrint = currentTime;
                double totalDuration = difftime(currentTime, recvStartTime);
                double msps = samplesRecv/totalDuration/1000000.0;
                printf("Recv Rate %f Msps\n", msps);
            }
        }

        if(txPipe != NULL) {
            //Write samples to tx pipe (ok to block)
            fwrite(sampBuffer, sizeof(SAMPLE_COMPONENT_DATATYPE) * 2, blockLen, txPipe);
            if(samplesSent == 0){
                sendStartTime = time(NULL);
            }
            samplesSent+=blockLen;

            if(flushCounter >= flushPeriod){
                fflush(txPipe);
                flushCounter = 0;
            }else{
                flushCounter++;
            }

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

    free(sampBuffer);

    return NULL;
}