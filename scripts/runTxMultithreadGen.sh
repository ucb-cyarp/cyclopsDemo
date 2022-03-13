#!/bin/bash

./simulinkGraphMLImporter ./$1.graphml $1_vitis.graphml
if [ $? -ne 0 ]; then
        echo "GraphML Import Failed for Tx"
        exit 1
fi
OUT_DIR=cOut_$1
mkdir ${OUT_DIR}

if [[ $(uname) == "Darwin" ]]; then
        #Cannot set thread affinity on MacOS
        echo "Building for MacOS, Thread Pinning Not Performed"
        partitionMap="[]" 
elif [[ ${BUILD_ENV} == "DOCKER" ]]; then
        #When running in Docker, do not set 
        echo "Building for Docker, Thread Pinning Not Performed"
        partitionMap="[]"  
else
	#For Epyc 7002 & Ryzen 3000 (New BIOS)
        #Instance1
        # partitionMap="[8,8,9,10]"
        #Instance2
        partitionMap="[40,40,41,42]"
        
	#For Ryzen 3000 (Old BIOS)
	#L3: 2
	# partitionMap="[5,5,6,7]"
fi

#./multiThreadedGenerator $1_vitis.graphml ./${OUT_DIR} tx_demo --emitGraphMLSched --schedHeur DFS --blockSize $2 --fifoLength $6 --ioFifoSize $3 --partitionMap ${partitionMap} --useSCHED_FIFO --fifoType $7 --fifoCachedIndexes $8 --fifoDoubleBuffering $9
#./multiThreadedGenerator $1_vitis.graphml ./${OUT_DIR} tx_demo --emitGraphMLSched --schedHeur DFS --blockSize $2 --fifoLength $6 --ioFifoSize $3 --partitionMap ${partitionMap} --printTelem --useSCHED_FIFO --fifoType $7 --fifoCachedIndexes $8 --fifoDoubleBuffering $9 --telemLevel ${10}
./multiThreadedGenerator $1_vitis.graphml ./${OUT_DIR} tx_demo_inst2 --emitGraphMLSched --schedHeur DFS --blockSize $2 --fifoLength $6 --ioFifoSize $3 --partitionMap ${partitionMap} --printTelem --telemDumpPrefix telemDump_ --useSCHED_FIFO --fifoType $7 --fifoCachedIndexes $8 --fifoDoubleBuffering $9 --telemLevel ${10} --subBlockSize ${11}

if [ $? -ne 0 ]; then
        echo "Multithread Gen Failed for Tx"
        exit 1
fi
cd ${OUT_DIR}
make -f Makefile_tx_demo_inst2_io_linux_pipe.mk CC=$4 CXX=$5
if [ $? -ne 0 ]; then
        echo "Make Failed for Tx pipe"
        exit 1
fi

if [[ $(uname) == "Darwin" ]]; then
        echo "Cannot build POSIX SharedMemory version on MacOS"
else
        make -f Makefile_tx_demo_inst2_io_posix_shared_mem.mk CC=$4 CXX=$5
        if [ $? -ne 0 ]; then
                echo "Make Failed for Tx shared mem"
                exit 1
        fi
fi
