#!/bin/bash
RxSrc=rx_combined_man_partition_fewerLuts_demo_fastslim1_fast1_slow1
TxSrc=transmitter_man_partition_fewerLuts_demo_fastslim1_fast1_slow1
BlockSize=32

cyclopsASCIIDir=~/git/cyclopsASCIILink

curDir=`pwd`

./runRxMultithreadGen.sh ${RxSrc} ${BlockSize}
if [ $? -ne 0 ]; then
        echo "Gen Failed for Rx"
        exit 1
fi
./runTxMultithreadGen.sh ${TxSrc} ${BlockSize}
if [ $? -ne 0 ]; then
        echo "Gen Failed for Tx"
        exit 1
fi

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

cd ${curDir}