//
// Created by Christopher Yarp on 10/28/19.
//

#include "helpers.h"
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int producerOpenInitFIFO(char *txSharedName, int *txSharedFD, char** txSemaphoreName, sem_t **txSem, atomic_int_fast32_t** txFifoCount, void** txFifoBlock, void** txFifoBuffer, size_t fifoSizeBytes){
    size_t sharedBlockSize = fifoSizeBytes + sizeof(atomic_int_fast32_t);

    //The producer is responsible for initializing the FIFO and releasing the semaphore
    //Note: Both Tx and Rx use the O_CREAT mode to create the semaphore if it does not already exist
    //---- Get access to the semaphore ----
    int txSharedNameLen = strlen(txSharedName);
    *txSemaphoreName = malloc(txSharedNameLen+2);
    strcpy(*txSemaphoreName, "/");
    strcat(*txSemaphoreName, txSharedName);
    *txSem = sem_open(*txSemaphoreName, O_CREAT, S_IRWXU, 0); //Initialize to 0, the consumer will wait
    if (*txSem == SEM_FAILED){
        printf("Unable to open tx semaphore\n");
        perror(NULL);
        exit(1);
    }

    //---- Init shared mem ----
    *txSharedFD = shm_open(txSharedName, O_CREAT | O_RDWR, S_IRWXU);
    if (*txSharedFD == -1){
        printf("Unable to open tx shm\n");
        perror(NULL);
        exit(1);
    }

    //Resize the shared memory
    int status = ftruncate(*txSharedFD, sharedBlockSize);
    if(status == -1){
        printf("Unable to resize tx fifo\n");
        perror(NULL);
        exit(1);
    }

    *txFifoBlock = mmap(NULL, sharedBlockSize, PROT_READ | PROT_WRITE, MAP_SHARED, *txSharedFD, 0);
    if (*txFifoBlock == MAP_FAILED){
        printf("Rx mmap failed\n");
        perror(NULL);
        exit(1);
    }

    //---- Init the fifoCount ----
    *txFifoCount = (atomic_int_fast32_t*) *txFifoBlock;
    atomic_init(*txFifoCount, 0);

    char* txFifoBlockBytes = (char*) *txFifoBlock;
    *txFifoBuffer = (void*) (txFifoBlockBytes + sizeof(atomic_int_fast32_t));

    //FIFO init done
    //---- Release the semaphore ----
    sem_post(*txSem);

    return sharedBlockSize;
}

int consumerOpenFIFOBlock(char *rxSharedName, int *rxSharedFD, char** rxSemaphoreName, sem_t **rxSem, atomic_int_fast32_t** rxFifoCount, void** rxFifoBlock, void** rxFifoBuffer, size_t fifoSizeBytes){
    size_t sharedBlockSize = fifoSizeBytes + sizeof(atomic_int_fast32_t);

    //---- Get access to the semaphore ----
    int rxSharedNameLen = strlen(rxSharedName);
    *rxSemaphoreName = malloc(rxSharedNameLen+2);
    strcpy(*rxSemaphoreName, "/");
    strcat(*rxSemaphoreName, rxSharedName);
    *rxSem = sem_open(*rxSemaphoreName, O_CREAT, S_IRWXU, 0); //Initialize to 0, the consumer waits
    if(*rxSem == SEM_FAILED){
        printf("Unable to open rx semaphore\n");
        perror(NULL);
        exit(1);
    }

    //Block on the semaphore while the producer is initializing
    int status = sem_wait(*rxSem);
    if(status == -1){
        printf("Unable to wait on rx semaphore\n");
        perror(NULL);
        exit(1);
    }

    //---- Open shared mem ----
    *rxSharedFD = shm_open(rxSharedName, O_RDWR, S_IRWXU);
    if(*rxSharedFD == -1){
        printf("Unable to open rx shm\n");
        perror(NULL);
        exit(1);
    }

    //No need to resize shared memory, the producer has already done that

    *rxFifoBlock = mmap(NULL, sharedBlockSize, PROT_READ | PROT_WRITE, MAP_SHARED, *rxSharedFD, 0);
    if(*rxFifoBlock == MAP_FAILED){
        printf("Rx mmap failed\n");
        perror(NULL);
        exit(1);
    }

    //---- Init the fifoCount ----
    *rxFifoCount = (atomic_int_fast32_t*) *rxFifoBlock;

    char* rxFifoBlockBytes = (char*) *rxFifoBlock;
    *rxFifoBuffer = (void*) (rxFifoBlockBytes + sizeof(atomic_int_fast32_t));

    return sharedBlockSize;
}

//currentOffset is updated by the call
//currentOffset is in bytes
//fifosize is in bytes
//fifoCount is in bytes

//returns number of elements written
int write_fifo(size_t fifoSize, atomic_int_fast32_t* fifoCount, size_t *currentOffset, void* dst_uncast, void* src_uncast, size_t elementSize, int numElements){
    char* dst = (char*) dst_uncast;
    char* src = (char*) src_uncast;

    bool hasRoom = false;

    size_t bytesToWrite = elementSize*numElements;

    while(!hasRoom){
        int currentCount = atomic_load(fifoCount);
        int spaceInFIFO = fifoSize - currentCount;
        //TODO: REMOVE
        if(spaceInFIFO<0){
            printf("FIFO had a negative count");
            exit(1);
        }

        if(bytesToWrite <= spaceInFIFO){
            hasRoom = true;
        }
    }

    //There is room in the FIFO, write into it
    //Write up to the end of the buffer, wrap around if nessisary
    size_t currentOffsetLocal = *currentOffset;
    size_t bytesToEnd = fifoSize - currentOffsetLocal;
    size_t bytesToTransferFirst = bytesToEnd < bytesToWrite ? bytesToEnd : bytesToWrite;
    memcpy(dst+currentOffsetLocal, src, bytesToTransferFirst);
    currentOffsetLocal += bytesToTransferFirst;
    if(currentOffsetLocal >= fifoSize){
        //Wrap around
        currentOffsetLocal = 0;

        //Write remaining (if any)
        size_t remainingBytesToTransfer = bytesToWrite - bytesToTransferFirst;
        if(remainingBytesToTransfer>0){
            //Know currentOffsetLocal is 0 so does not need to be added
            //However, need to offset source by the number of bytes transfered before
            memcpy(dst, src+bytesToTransferFirst, remainingBytesToTransfer);
            currentOffsetLocal+=remainingBytesToTransfer;
        }
    }

    //Update the current offset
    *currentOffset = currentOffsetLocal;

    //Update the fifoCount, do not need the new value
    atomic_fetch_add(fifoCount, bytesToWrite);

    return numElements;
}

int read_fifo(size_t fifoSize, atomic_int_fast32_t* fifoCount, size_t *currentOffset, void* dst_uncast, void* src_uncast, size_t elementSize, int numElements){
    char* dst = (char*) dst_uncast;
    char* src = (char*) src_uncast;

    bool hasData = false;

    size_t bytesToRead = elementSize*numElements;

    while(!hasData){
        int currentCount = atomic_load(fifoCount);
        //TODO: REMOVE
        if(currentCount<0){
            printf("FIFO had a negative count");
            exit(1);
        }

        if(currentCount >= bytesToRead){
            hasData = true;
        }
    }

    //There is enough data in the fifo to complete a read operation
    //Read from the FIFO
    //Read up to the end of the buffer and wrap if nessisary
    size_t currentOffsetLocal = *currentOffset;
    size_t bytesToEnd = fifoSize - currentOffsetLocal;
    size_t bytesToTransferFirst = bytesToEnd < bytesToRead ? bytesToEnd : bytesToRead;
    memcpy(dst, src+currentOffsetLocal, bytesToTransferFirst);
    currentOffsetLocal += bytesToTransferFirst;
    if(currentOffsetLocal >= fifoSize){
        //Wrap around
        currentOffsetLocal = 0;

        //Read remaining (if any)
        size_t remainingBytesToTransfer = bytesToRead - bytesToTransferFirst;
        if(remainingBytesToTransfer>0){
            //Know currentOffsetLocal is 0 so does not need to be added to src
            //However, need to offset dest by the number of bytes transfered before
            memcpy(dst+bytesToTransferFirst, src, remainingBytesToTransfer);
            currentOffsetLocal+=remainingBytesToTransfer;
        }
    }

    //Update the current offset
    *currentOffset = currentOffsetLocal;

    //Update the fifoCount, do not need the new value
    atomic_fetch_sub(fifoCount, bytesToRead);

    return numElements;
}