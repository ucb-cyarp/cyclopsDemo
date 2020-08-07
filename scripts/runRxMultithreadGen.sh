#!/bin/bash

./simulinkGraphMLImporter ./$1.graphml $1_vitis.graphml
if [ $? -ne 0 ]; then
        echo "GraphML Import Failed for Rx"
        exit 1
fi
OUT_DIR=cOut_$1
mkdir ${OUT_DIR}
#./multiThreadedGenerator $1_vitis.graphml ./${OUT_DIR} rx_demo --emitGraphMLSched --schedHeur DFS --blockSize $2 --fifoLength 7 --ioFifoSize $3 --partitionMap [4,5,6,7,22,23,14,15,30,31]
./multiThreadedGenerator $1_vitis.graphml ./${OUT_DIR} rx_demo --emitGraphMLSched --schedHeur DFS --blockSize $2 --fifoLength 7 --ioFifoSize $3 --partitionMap [4,5,6,7,22,23,14,15,30,31] --printTelem --telemDumpPrefix telemDump_
if [ $? -ne 0 ]; then
        echo "Multithread Gen Failed for Rx"
        exit 1
fi
cd ${OUT_DIR}
cp -rs ../common .
cp -rs ../depends .
cp -rs ../intrin .
make -f Makefile_rx_demo_io_linux_pipe.mk USE_PCM=0 USE_AMDuPROF=0
if [ $? -ne 0 ]; then
        echo "Make Failed for Rx pipes"
        exit 1
fi
make -f Makefile_rx_demo_io_posix_shared_mem.mk USE_PCM=0 USE_AMDuPROF=0
if [ $? -ne 0 ]; then
        echo "Make Failed for Rx pipes"
        exit 1
fi
