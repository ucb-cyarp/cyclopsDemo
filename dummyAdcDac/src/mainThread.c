//
// Created by Christopher Yarp on 10/23/19.
//

#include "mainThread.h"

#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>

void* mainThread(void* uncastArgs){
    threadArgs_t* args = (threadArgs_t*) uncastArgs;
    char *txPipeName = args->txPipeName;
    char *txFeedbackPipeName = args->txFeedbackPipeName;
    char *rxPipeName = args->rxPipeName;

    int32_t blockLen = args->blockLen;
    bool print = args->print;

    //Open Pipes (if applicable)
    FILE *rxPipe = NULL;
    FILE *txPipe = NULL;
    FILE *txFeedbackPipe = NULL;

    rxPipe= fopen(rxPipeName, "wb");
    if(rxPipe == NULL) {
        printf("Unable to open Rx Pipe ... exiting\n");
        perror(NULL);
        exit(1);
    }

    txPipe = fopen(txPipeName, "rb");
    if(txPipe == NULL){
        printf("Unable to open Tx Pipe ... exiting\n");
        perror(NULL);
        exit(1);
    }

    txFeedbackPipe = fopen(txFeedbackPipeName, "wb");
    if(txFeedbackPipe == NULL) {
        printf("Unable to open Tx Feedback Pipe ... exiting\n");
        perror(NULL);
        exit(1);
    }

    //If transmitting, allocate arrays and form a Tx packet
    SAMPLE_COMPONENT_DATATYPE* sampBuffer = (SAMPLE_COMPONENT_DATATYPE*) malloc(sizeof(SAMPLE_COMPONENT_DATATYPE)*2*blockLen);

    //Main Loop
    bool running = true;
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

        //Write samples to tx pipe (ok to block)
        fwrite(sampBuffer, sizeof(SAMPLE_COMPONENT_DATATYPE) * 2, blockLen, txPipe);
        FEEDBACK_DATATYPE tokensReturned = 1;
        fwrite(&tokensReturned, sizeof(tokensReturned), 1, txFeedbackPipe);
    }

    if(rxPipe != NULL){
        //Cleanup
        free(sampBuffer);
    }

    return NULL;
}