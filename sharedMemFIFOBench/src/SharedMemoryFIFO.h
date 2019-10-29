//
// Created by Christopher Yarp on 10/28/19.
//

#ifndef SHAREDMEMFIFOBENCH_SHAREDMEMORYFIFO_H
#define SHAREDMEMFIFOBENCH_SHAREDMEMORYFIFO_H

#include <stdatomic.h>
#include <semaphore.h>
#include <sys/mman.h>
#include <unistd.h>

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
} sharedMemoryFIFO_t;

void initSharedMemoryFIFO(sharedMemoryFIFO_t *fifo);

int producerOpenInitFIFOBlock(char *sharedName, size_t fifoSizeBytes, sharedMemoryFIFO_t *fifo);

int consumerOpenFIFOBlock(char *sharedName, size_t fifoSizeBytes, sharedMemoryFIFO_t *fifo);

//NOTE: this function blocks until numElements can be written into the FIFO
int writeFifo(void* src, size_t elementSize, int numElements, sharedMemoryFIFO_t *fifo);

int readFifo(void* dst, size_t elementSize, int numElements, sharedMemoryFIFO_t *fifo);

void cleanupProducer(sharedMemoryFIFO_t *fifo);

void cleanupConsumer(sharedMemoryFIFO_t *fifo);

#endif //SHAREDMEMFIFOBENCH_SHAREDMEMORYFIFO_H
