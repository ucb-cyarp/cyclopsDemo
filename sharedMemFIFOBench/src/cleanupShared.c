//
// Created by Christopher Yarp on 10/28/19.
//

#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <stdlib.h>
#include <errno.h>
#include <stdbool.h>
#include <stdint.h>

void printHelp(){
    printf("cleanupShared sharedName\n");
    printf("\n");
    printf("Required Arguments:\n");
    printf("sharedName: Name of shared memory to unlink\n");
}

int main(int argc, char **argv) {
    //--- Parse the arguments ---
    char *sharedName = NULL;

    if (argc < 2) {
        printHelp();
    }

    sharedName = argv[1];

    status = shm_unlink(txSharedName);
    if(status == -1){
        printf("Error in fifo block unlink\n");
        perror(NULL);
    }

    int sharedNameLen = strlen(sharedName);
    char* txSemaphoreName = malloc(sharedNameLen+5);
    strcpy(txSemaphoreName, "/");
    strcat(txSemaphoreName, sharedName);
    strcat(txSemaphoreName, "_TX");
    status = sem_unlink(txSemaphoreName);
    if(status == -1){
        printf("Error in tx semaphore unlink\n");
        perror(NULL);
    }


    char* rxSemaphoreName = malloc(sharedNameLen+5);
    strcpy(rxSemaphoreName, "/");
    strcat(rxSemaphoreName, sharedName);
    strcat(rxSemaphoreName, "_RX");
    status = sem_unlink(rxSemaphoreName);
    if(status == -1){
        printf("Error in rx semaphore unlink\n");
        perror(NULL);
    }

    free(txSemaphoreName);
    free(rxSemaphoreName);

    return 0;
}