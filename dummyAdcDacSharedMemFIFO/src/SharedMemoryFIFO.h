//
// Created by Christopher Yarp on 10/28/19.
//

#ifndef DUMMYADCDACSHAREDMEMFIFO_SHAREDMEMORYFIFO_H
#define DUMMYADCDACSHAREDMEMFIFO_SHAREDMEMORYFIFO_H

#include <stdatomic.h>
#include <semaphore.h>
#include <sys/mman.h>
#include <unistd.h>
#include <stdbool.h>

typedef struct{
    char *sharedName;
    int sharedFD;
    char* txSemaphoreName;
    char* rxSemaphoreName;
    sem_t *txSem;
    sem_t *rxSem;
    atomic_int_fast32_t* fifoCount;
    volatile void* fifoBlock;
    volatile void* fifoBuffer;
    size_t fifoSizeBytes;
    size_t fifoSharedBlockSizeBytes;
    size_t currentOffset;
    bool rxReady;
} sharedMemoryFIFO_t;

void initSharedMemoryFIFO(sharedMemoryFIFO_t *fifo);

int producerOpenInitFIFO(char *sharedName, size_t fifoSizeBytes, sharedMemoryFIFO_t *fifo);

int consumerOpenFIFOBlock(char *sharedName, size_t fifoSizeBytes, sharedMemoryFIFO_t *fifo);

//NOTE: this function blocks until numElements can be written into the FIFO
int writeFifo(void* src, size_t elementSize, int numElements, sharedMemoryFIFO_t *fifo);

int readFifo(void* dst, size_t elementSize, int numElements, sharedMemoryFIFO_t *fifo);

void cleanupProducer(sharedMemoryFIFO_t *fifo);

void cleanupConsumer(sharedMemoryFIFO_t *fifo);

#endif //DUMMYADCDACSHAREDMEMFIFO_SHAREDMEMORYFIFO_H
