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
    printf("dummyAdc <-rx rx.pipe> <-tx tx.pipe -txfb tx_feedback.pipe\n");
    printf("\n");
    printf("Optional Arguments:\n");
    printf("-rx: Path to the Rx Pipe\n");
    printf("-tx: Path to the Tx Pipe\n");
    printf("-txfb: Path to the Tx Feedback Pipe (required if -tx is present)\n");
    printf("-blocklen: Block length in samples\n");
    printf("-gain: Gain of the ADC/DAC\n");
    printf("-cpu: CPU to run this application on (does not apply to MacOS)\n");
    printf("-v: verbose\n");
}

int main(int argc, char **argv) {
    //--- Parse the arguments ---
    char *txPipeName = NULL;
    char *txFeedbackPipeName = NULL;
    char *rxPipeName = NULL;

    int32_t blockLen = 1;
    bool print;

    float gain = 1;

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
        } else if (strcmp("-gain", argv[i]) == 0) {
            i++; //Get the actual argument

            if (i < argc) {
                gain = strtof(argv[i], NULL);
                if (blockLen <= 1) {
                    printf("-gain must be positive\n");
                }
            } else {
                printf("Missing argument for -gain\n");
                exit(1);
            }
        } else if (strcmp("-cpu", argv[i]) == 0) {
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
        } else if (strcmp("-v", argv[i]) == 0) {
            print = true;
        } else {
            printf("Unknown CLI option: %s\n", argv[i]);
        }
    }

    if (txPipeName == NULL || txFeedbackPipeName == NULL || rxPipeName == NULL) {
        printf("must supply tx, rx, and txfb pipes\n");
        exit(1);
    }

    //Create Thread Args
    threadArgs_t threadArgs;
    threadArgs.txPipeName = txPipeName;
    threadArgs.txFeedbackPipeName = txFeedbackPipeName;
    threadArgs.rxPipeName = rxPipeName;
    threadArgs.gain = gain;

    threadArgs.blockLen = blockLen;
    threadArgs.print = print;

    //Create Thread
    pthread_t thread_app;
    pthread_attr_t attr_app;

    int status = pthread_attr_init(&attr_app);
    if (status != 0) {
        printf("Could not create pthread attributes ... exiting");
        exit(1);
    }

    #ifdef __APPLE__
        printf("Warning: On MacOS, CPU parameter is ignored\n");
    #else
        //Can't set thread affinity on MacOS
        cpu_set_t cpuset_app;

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
    #endif

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