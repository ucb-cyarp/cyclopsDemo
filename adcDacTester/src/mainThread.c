//
// Created by Christopher Yarp on 10/22/19.
//

#include "mainThread.h"
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>

#include "helpers.h"

void* mainThread(void* uncastArgs){
    threadArgs_t* args = (threadArgs_t*) uncastArgs;
    char *txPipeName = args->txPipeName;
    char *txFeedbackPipeName = args->txFeedbackPipeName;
    char *rxPipeName = args->rxPipeName;

    int32_t txTokens = args->txTokens;
    int32_t maxBlocksToProcess = args->maxBlocksToProcess;
    int32_t blockLen = args->blockLen;
    bool print = args->print;

    //Open Pipes (if applicable)
    FILE *rxPipe = NULL;
    FILE *txPipe = NULL;
    FILE *txFeedbackPipe = NULL;

    if(rxPipeName != NULL){
        rxPipe= fopen(rxPipeName, "rb");
        if(rxPipe == NULL) {
            printf("Unable to open Rx Pipe ... exiting\n");
            perror(NULL);
            exit(1);
        }
    }

    if(txPipeName != NULL){
        txPipe = fopen(txPipeName, "wb");
        if(txPipe == NULL){
            printf("Unable to open Tx Pipe ... exiting\n");
            perror(NULL);
            exit(1);
        }

        txFeedbackPipe = fopen(txFeedbackPipeName, "rb");
        if(txFeedbackPipe == NULL) {
            printf("Unable to open Tx Feedback Pipe ... exiting\n");
            perror(NULL);
            exit(1);
        }
    }

    //If transmitting, allocate arrays and form a Tx packet
    SAMPLE_COMPONENT_DATATYPE* txSampBuffer;
    if(txPipe != NULL){
        //Craft a packet to send
        txSampBuffer = (SAMPLE_COMPONENT_DATATYPE*) malloc(sizeof(SAMPLE_COMPONENT_DATATYPE)*2*blockLen);
        for(int i = 0; i<blockLen*2; i++){
            txSampBuffer[i] = SAMPLE_COMPONENT_INIT_VAL;
        }
    }

    //Rx State
    SAMPLE_COMPONENT_DATATYPE* rxSampBuffer;
    if(rxPipe != NULL){
        //Craft a packet to send
        rxSampBuffer = (SAMPLE_COMPONENT_DATATYPE*) malloc(sizeof(SAMPLE_COMPONENT_DATATYPE)*2*blockLen);
    }

    //Main Loop
    bool running = true;
    while(running){
        if(txPipe!=NULL){
            //If transmissions are OK
            int numBlocksToSend = txTokens<maxBlocksToProcess ? txTokens : maxBlocksToProcess;
            for(int i = 0; i<numBlocksToSend; i++){
                fwrite(txSampBuffer, sizeof(SAMPLE_COMPONENT_DATATYPE)*2, blockLen, txPipe);
            }
            txTokens -=numBlocksToSend;

            if(print && numBlocksToSend > 0){
                printf("Sent %d blocks (%d samples)\n", numBlocksToSend, numBlocksToSend*blockLen);
            }

            for(int i = 0; i<maxBlocksToProcess; i++) {
                //Check for feedback (use select)
                bool feedbackReady = isReadyForReading(txFeedbackPipe);
                if(feedbackReady){
                    //Get feedback
                    FEEDBACK_DATATYPE tokensReturned;
                    //Once data starts coming, a full transaction should be in process.  Can block on the transaction.
                    int elementsRead = fread(&tokensReturned, sizeof(tokensReturned), 1, txFeedbackPipe);
                    if(elementsRead != 1 && feof(txFeedbackPipe)){
                        //Done!
                        running = false;
                        break;
                    } else if (elementsRead != 1 && ferror(txFeedbackPipe)){
                        printf("An error was encountered while reading the feedback pipe\n");
                        perror(NULL);
                        exit(1);
                    } else if (elementsRead != 1){
                        printf("An unknown error was encountered while reading the feedback pipe\n");
                        exit(1);
                    }
                    txTokens += tokensReturned;
                    if(print && tokensReturned > 0){
                        printf("Got back %d tokens\n", tokensReturned);
                    }
                }else{
                    break;
                }
            }
        }

        if(rxPipe!=NULL){
            //Read and print
            int readCount = 0;
            for(int readAttempts = 0; readAttempts<maxBlocksToProcess; readAttempts++){
                bool rxReady = isReadyForReading(txFeedbackPipe);
                if(rxReady) {
                    int samplesRead = fread(rxSampBuffer, sizeof(SAMPLE_COMPONENT_DATATYPE) * 2, blockLen, rxPipe);
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

                    readCount++;
                }
            }

            if(print && readCount > 0){
                printf("Received %d blocks (%d samples)\n", readCount, readCount*blockLen);
            }
        }
    }

    if(txPipe != NULL){
        //Cleanup
        free(txSampBuffer);
    }

    if(rxPipe != NULL){
        //Cleanup
        free(rxSampBuffer);
    }

    return NULL;
}