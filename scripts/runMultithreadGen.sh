#!/bin/bash
RxSrc=rx_combined_man_partition_fewerLuts_demo_raisedcos1_fastslim2_fast3_slow3
TxSrc=transmitter_man_partition_fewerLuts_demo_mod1_raisedCos1_lpf2
BlockSize=32
BlockSize=64
IO_FIFO_SIZE=128

cyclopsASCIIDir=~/git/cyclopsASCIILink
cyclopsASCIISharedMemDir=~/git/cyclopsASCIILink-sharedMem

curDir=`pwd`

./runRxMultithreadGen.sh ${RxSrc} ${BlockSize} ${IO_FIFO_SIZE}
if [ $? -ne 0 ]; then
        echo "Gen Failed for Rx"
        exit 1
fi
./runTxMultithreadGen.sh ${TxSrc} ${BlockSize} ${IO_FIFO_SIZE}
if [ $? -ne 0 ]; then
        echo "Gen Failed for Tx"
        exit 1
fi

cd ${curDir}

#Copy required headers into cyclopsASCII
cp cOut_${RxSrc}/*_io_linux_pipe.h ${cyclopsASCIIDir}/src/vitisIncludes/.
cp cOut_${RxSrc}/*fifoTypes.h ${cyclopsASCIIDir}/src/vitisIncludes/.
cp cOut_${RxSrc}/vitisTypes.h ${cyclopsASCIIDir}/src/vitisIncludes/.
cp cOut_${RxSrc}/*_parameters.h ${cyclopsASCIIDir}/src/vitisIncludes/.

cp cOut_${TxSrc}/*_io_linux_pipe.h ${cyclopsASCIIDir}/src/vitisIncludes/.
cp cOut_${TxSrc}/*fifoTypes.h ${cyclopsASCIIDir}/src/vitisIncludes/.
cp cOut_${TxSrc}/vitisTypes.h ${cyclopsASCIIDir}/src/vitisIncludes/.
cp cOut_${TxSrc}/*_parameters.h ${cyclopsASCIIDir}/src/vitisIncludes/.

#Rebuild cyclopsASCII
cd ${cyclopsASCIIDir}
mkdir build
cd build
cmake ..
if [ $? -ne 0 ]; then
        echo "cmake Failed for cyclopsASCII"
        exit 1
fi
make
if [ $? -ne 0 ]; then
        echo "make Failed for cyclopsASCII"
        exit 1
fi

if [ ! -z "${cyclopsASCIISharedMemDir}" ]; then
    cd ${curDir}
    #Copy required headers into cyclopsASCII-sharedmem
    cp cOut_${RxSrc}/*_io_linux_pipe.h ${cyclopsASCIISharedMemDir}/src/vitisIncludes/.
    cp cOut_${RxSrc}/*fifoTypes.h ${cyclopsASCIISharedMemDir}/src/vitisIncludes/.
    cp cOut_${RxSrc}/vitisTypes.h ${cyclopsASCIISharedMemDir}/src/vitisIncludes/.
    cp cOut_${RxSrc}/*_parameters.h ${cyclopsASCIISharedMemDir}/src/vitisIncludes/.

    cp cOut_${TxSrc}/*_io_linux_pipe.h ${cyclopsASCIISharedMemDir}/src/vitisIncludes/.
    cp cOut_${TxSrc}/*fifoTypes.h ${cyclopsASCIISharedMemDir}/src/vitisIncludes/.
    cp cOut_${TxSrc}/vitisTypes.h ${cyclopsASCIISharedMemDir}/src/vitisIncludes/.
    cp cOut_${TxSrc}/*_parameters.h ${cyclopsASCIISharedMemDir}/src/vitisIncludes/.

    #Rebuild cyclopsASCII
    cd ${cyclopsASCIISharedMemDir}
    mkdir build
    cd build
    cmake ..
    if [ $? -ne 0 ]; then
            echo "cmake Failed for cyclopsASCII-sharedMem"
            exit 1
    fi
    make
    if [ $? -ne 0 ]; then
            echo "make Failed for cyclopsASCII-sharedMem"
            exit 1
    fi
fi

cd ${curDir}
