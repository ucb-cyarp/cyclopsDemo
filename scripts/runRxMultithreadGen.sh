#!/bin/bash

./simulinkGraphMLImporter ./$1.graphml $1_vitis.graphml
if [ $? -ne 0 ]; then
        echo "GraphML Import Failed for Rx"
        exit 1
fi
OUT_DIR=cOut_$1
mkdir ${OUT_DIR}

if [[ $(uname) == "Darwin" ]]; then
        #Cannot set thread affinity on MacOS
        partitionMap="[]" 
else
        partitionMap="[12,12,13,14,15,16,17,18,19,20,21,23]"
fi

#./multiThreadedGenerator $1_vitis.graphml ./${OUT_DIR} rx_demo --emitGraphMLSched --schedHeur DFS --blockSize $2 --fifoLength 7 --ioFifoSize $3 --partitionMap ${partitionMap}
./multiThreadedGenerator $1_vitis.graphml ./${OUT_DIR} rx_demo --emitGraphMLSched --schedHeur DFS --blockSize $2 --fifoLength 7 --ioFifoSize $3 --partitionMap ${partitionMap}  --printTelem --telemDumpPrefix telemDump_
#./multiThreadedGenerator $1_vitis.graphml ./${OUT_DIR} rx_demo --emitGraphMLSched --schedHeur DFS --blockSize $2 --fifoLength 7 --ioFifoSize $3 --partitionMap ${partitionMap} --telemDumpPrefix telemDump_

if [ $? -ne 0 ]; then
        echo "Multithread Gen Failed for Rx"
        exit 1
fi
cd ${OUT_DIR}
if [[ $(uname) == "Darwin" ]]; then
	cp -r ../common .
	cp -r ../depends .
	cp -r ../intrin .
else
	cp -rs ../common .
	cp -rs ../depends .
	cp -rs ../intrin .
fi
make -f Makefile_rx_demo_io_linux_pipe.mk USE_PCM=0 USE_AMDuPROF=0 CC=$4 CXX=$5
if [ $? -ne 0 ]; then
        echo "Make Failed for Rx pipes"
        exit 1
fi

if [[ $(uname) == "Darwin" ]]; then
        echo "Cannot build POSIX SharedMemory version on MacOS"
else
        make -f Makefile_rx_demo_io_posix_shared_mem.mk USE_PCM=0 USE_AMDuPROF=0 CC=$4 CXX=$5
        if [ $? -ne 0 ]; then
                echo "Make Failed for Rx pipes"
                exit 1
        fi
fi
