#!/bin/bash
RxSrc=rev1BB_receiver
TxSrc=rev1BB_transmitter
BlockSize=120
#BlockSize=64
#BlockSize=16
IO_FIFO_SIZE=120
#FIFO_LEN=7
FIFO_LEN=31
FIFO_TYPE=lockeless_x86
#FIFO_TYPE=lockeless_inplace_x86
#FIFO_IND_CACHE_TYPE=none
FIFO_IND_CACHE_TYPE=producer_consumer_cache
FIFO_DOUBLE_BUFFERING=none

#PAPI should be only active in one program at a time
TELEM_LVL_TX=io_rate_only
#TELEM_LVL_RX=papi_rate_only
TELEM_LVL_RX=breakdown

#Set the compiler to use here
source ./setCompilersToUse.sh

compilerInfoName="compilerInfo.txt"

cyclopsASCIIDir=../submodules/cyclopsASCIILink
cyclopsASCIISharedMemDir=../submodules/cyclopsASCIILink-sharedMem

if [[ $(uname) == "Darwin" ]]; then
        echo "POSIX Shared Memory Version Cannot be Built on MacOS"
        cyclopsASCIISharedMemDir=
fi

curDir=`pwd`

#Save Compiler Info
echo "Compilers Specified:" > $compilerInfoName
echo "CC=$CC" >> $compilerInfoName
echo "CXX=$CXX" >> $compilerInfoName
echo >> $compilerInfoName
echo "Compiler Locations:" >> $compilerInfoName
echo "CC: $(which $CC)" >> $compilerInfoName
echo "CXX: $(which $CXX)" >> $compilerInfoName
echo >> $compilerInfoName
echo "Compiler Config:" >> $compilerInfoName
echo "CC:" >> $compilerInfoName
$CC -v > $compilerInfoName 2>&1
echo "CXX:" >> $compilerInfoName
$CXX -v > $compilerInfoName 2>&1

echo "Telem LVL Tx: ${TELEM_LVL_TX}"
echo "Telem LVL Rx: ${TELEM_LVL_RX}"

#Generate

./runRxMultithreadGen.sh ${RxSrc} ${BlockSize} ${IO_FIFO_SIZE} ${CC} ${CXX} ${FIFO_LEN} ${FIFO_TYPE} ${FIFO_IND_CACHE_TYPE} ${FIFO_DOUBLE_BUFFERING} ${TELEM_LVL_RX}
if [ $? -ne 0 ]; then
        echo "Gen Failed for Rx"
        exit 1
fi
./runTxMultithreadGen.sh ${TxSrc} ${BlockSize} ${IO_FIFO_SIZE} ${CC} ${CXX} ${FIFO_LEN} ${FIFO_TYPE} ${FIFO_IND_CACHE_TYPE} ${FIFO_DOUBLE_BUFFERING} ${TELEM_LVL_TX}
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
cmake -DBUILD_SHARED_MEM_VERSION=OFF -D CMAKE_C_COMPILER=${CC} -D CMAKE_CXX_COMPILER=${CXX} ..
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
    cmake -DBUILD_SHARED_MEM_VERSION=ON -D CMAKE_C_COMPILER=${CC} -D CMAKE_CXX_COMPILER=${CXX} ..
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
