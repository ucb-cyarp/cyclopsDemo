/**
 * This program is used to demonstrate the use of the shared memory interface for a FIFO.
 * It uses 2 POSIX concepts: shared memory, and semaphores.
 *
 * The shared memory is used to contain the FIFO buffer and the relavent control information (ex. element count).
 *
 * C11 stdatomic is used to access and modify the element count in an atomic manner
 *
 * An alternative is to rely on x86 memory ordering to implement a lockeless FIFO.  This implementation uses a read
 * and write pointer.  The write pointer is soely written to by the producer and the read pointer is soely written to by
 * the consumer.
 *
 * The semantics we will adhere to are that the producer is responsible for initializing the FIFO control information
 * and for informing the consumer that the FIFO is ready.  The semaphore is used to communicate this information.  The
 * semaphore will be initialized as locked and will be passed to both the producer and consumer.  The consumer will
 * block on this semaphore and the producer will initialize the FIFO.  After initialization, the
 *
 * The producer is also responsible for the teardown of the shared memory and semaphore.  A utility application
 * will also be written to help clean up shared memory and semaphores from
 *
 * The shared memory structure consists of an element count in the first 4 bytes (int type).  The remaining memory
 * is used for the FIFO buffer
 *
 * @return
 */

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
    printf("sharedMemFIFOBench <-rx rx.pipe> <-tx tx.pipe>\n");
    printf("\n");
    printf("Optional Arguments:\n");
    printf("-rx: Name of rx shared memory\n");
    printf("-tx: Name of tx shared memory\n");
    printf("-blocklen: Block length in samples\n");
    printf("-fifosize: The size of the FIFO (in blocks)\n");
    printf("-cpu: CPU to run this application on\n");
    printf("-v: verbose\n");
}

int main(int argc, char **argv) {
    //--- Parse the arguments ---
    char *txSharedName = NULL;
    char *rxSharedName = NULL;

    int32_t blockLen = 1;
    int fifoSizeBlks;

    int cpu = -1;

    if (argc < 2) {
        printHelp();
    }

    for (int i = 1; i < argc; i++) {
        if (strcmp("-rx", argv[i]) == 0) {
            i++; //Get the actual argument

            if (i < argc) {
                rxSharedName = argv[i];
            } else {
                printf("Missing argument for -rx\n");
                exit(1);
            }
        } else if (strcmp("-tx", argv[i]) == 0) {
            i++; //Get the actual argument

            if (i < argc) {
                txSharedName = argv[i];
            } else {
                printf("Missing argument for -tx\n");
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
        } else if (strcmp("-fifosize", argv[i]) == 0) {
            i++; //Get the actual argument

            if (i < argc) {
                fifoSizeBlks = strtol(argv[i], NULL, 10);
                if (fifoSizeBlks <= 1) {
                    printf("-fifosize must be positive\n");
                }
            } else {
                printf("Missing argument for -fifosize\n");
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
        } else {
            printf("Unknown CLI option: %s\n", argv[i]);
        }
    }

    if (txSharedName == NULL && rxSharedName == NULL) {
        printf("must supply tx or rx pipes\n");
        exit(1);
    }

    //Create Thread Args
    threadArgs_t threadArgs;
    threadArgs.txSharedName = txSharedName;
    threadArgs.rxSharedName = rxSharedName;

    threadArgs.blockLen = blockLen;
    threadArgs.fifoSizeBlocks = fifoSizeBlks;

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