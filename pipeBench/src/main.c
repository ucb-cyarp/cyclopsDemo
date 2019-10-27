#define _GNU_SOURCE //Need extra functions from sched.h to set thread affinity
#include <stdio.h>
#include <pthread.h>
#include <sched.h>
#include <unistd.h>
#include <string.h>
#include <stdlib.h>
#include <errno.h>
#include <stdbool.h>
#include <stdint.h>

#include "mainThread.h"

void printHelp(){
    printf("pipeBench <-rx rx.pipe> <-tx tx.pipe>\n");
    printf("\n");
    printf("Optional Arguments:\n");
    printf("-rx: Path to the Rx Pipe\n");
    printf("-tx: Path to the Tx Pipe\n");
    printf("-blocklen: Block length in samples\n");
    printf("-cpu: CPU to run this application on\n");
    printf("-v: verbose\n");
}

int main(int argc, char **argv) {
    //--- Parse the arguments ---
    char *txPipeName = NULL;
    char *txFeedbackPipeName = NULL;
    char *rxPipeName = NULL;

    int32_t blockLen = 1;

    int cpu = -1;

    if (argc < 2) {
        printHelp();
    }

    for (int i = 1; i < argc; i++) {
        if (strcmp("-rx", argv[i]) == 0) {
            i++; //Get the actual argument

            if (i < argc) {
                rxPipeName = argv[i];
            } else {
                printf("Missing argument for -rx\n");
                exit(1);
            }
        } else if (strcmp("-tx", argv[i]) == 0) {
            i++; //Get the actual argument

            if (i < argc) {
                txPipeName = argv[i];
            } else {
                printf("Missing argument for -tx\n");
                exit(1);
            }
        } else if (strcmp("-txfb", argv[i]) == 0) {
            i++; //Get the actual argument

            if (i < argc) {
                txFeedbackPipeName = argv[i];
            } else {
                printf("Missing argument for -txfb\n");
                exit(1);
            }
        } else if (strcmp("-blocklen", argv[i]) == 0) {
            i++; //Get the actual argument

            if (i < argc) {
                blockLen = strtol(argv[i], NULL, 10);
                if (blockLen <= 1) {
                    printf("-blocklen must be positive\n");
                }
            } else {
                printf("Missing argument for -blocklen\n");
                exit(1);
            }
        }  else if (strcmp("-cpu", argv[i]) == 0) {
            i++; //Get the actual argument

            if (i < argc) {
                cpu = strtol(argv[i], NULL, 10);
                if (cpu <= 0) {
                    printf("-cpu must be non-negative\n");
                }
            } else {
                printf("Missing argument for -cpu\n");
                exit(1);
            }
        } else {
            printf("Unknown CLI option: %s\n", argv[i]);
        }
    }

    if (txPipeName == NULL && rxPipeName == NULL) {
        printf("must supply tx or pipes\n");
        exit(1);
    }

    //Create Thread Args
    threadArgs_t threadArgs;
    threadArgs.txPipeName = txPipeName;
    threadArgs.rxPipeName = rxPipeName;

    threadArgs.blockLen = blockLen;

    //Create Thread
    cpu_set_t cpuset_app;
    pthread_t thread_app;
    pthread_attr_t attr_app;

    int status = pthread_attr_init(&attr_app);
    if (status != 0) {
        printf("Could not create pthread attributes ... exiting");
        exit(1);
    }

    //Set Thread CPU
    if (cpu >= 0) {
        CPU_ZERO(&cpuset_app); //Clear cpuset
        CPU_SET(cpu, &cpuset_app); //Add CPU to cpuset
        status = pthread_attr_setaffinity_np(&attr_app, sizeof(cpu_set_t), &cpuset_app);//Set thread CPU affinity
        if (status != 0) {
            printf("Could not set thread core affinity ... exiting");
            exit(1);
        }
    }

    //Start Thread
    status = pthread_create(&thread_app, &attr_app, mainThread, &threadArgs);
    if (status != 0) {
        printf("Could not create a thread ... exiting");
        errno = status;
        perror(NULL);
        exit(1);
    }

    //Wait for thread to exit
    void *res;
    status = pthread_join(thread_app, &res);
    if (status != 0) {
        printf("Could not join a thread ... exiting");
        errno = status;
        perror(NULL);
        exit(1);
    }

    return 0;
}