//
// Created by Christopher Yarp on 10/28/19.
//

#ifndef SHAREDMEMFIFOBENCH_HELPERS_H
#define SHAREDMEMFIFOBENCH_HELPERS_H

#include <stdatomic.h>
#include <semaphore.h>
#include <sys/mman.h>
#include <stdatomic.h>
#include <unistd.h>

int producerOpenInitFIFOBlock(char *sharedName, int *txSharedFD, char** txSemaphoreName, char** rxSemaphoreName, sem_t **txSem, sem_t **rxSem, atomic_int_fast32_t** txFifoCount, void** txFifoBlock, void** txFifoBuffer, size_t fifoSizeBytes);

int consumerOpenFIFOBlock(char *sharedName, int *rxSharedFD, char** txSemaphoreName, char** rxSemaphoreName, sem_t **txSem, sem_t **rxSem, atomic_int_fast32_t** rxFifoCount, void** rxFifoBlock, void** rxFifoBuffer, size_t fifoSizeBytes);


//NOTE: this function blocks until numElements can be written into the FIFO
int write_fifo(size_t fifoSize, atomic_int_fast32_t* fifoCount, size_t *currentOffset, void* dst, void* src, size_t elementSize, int numElements);

int read_fifo(size_t fifoSize, atomic_int_fast32_t* fifoCount, size_t *currentOffset, void* dst, void* src, size_t elementSize, int numElements);

#endif //SHAREDMEMFIFOBENCH_HELPERS_H
