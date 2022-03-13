#!/bin/bash
# using https://stackoverflow.com/questions/1908610/how-to-get-pid-of-background-process

oldDir=$(pwd)

#Get build dir
scriptSrc=$(dirname "${BASH_SOURCE[0]}")
cd $scriptSrc
scriptSrc=$(pwd)
if [[ $(basename $scriptSrc) == scripts ]]; then
    cd ../build
    buildDir=$(pwd)
elif [[ $(basename $scriptSrc) == build ]]; then
    buildDir=$scriptSrc
else
    echo "Error: Unable to determine location of demo build directory"
    cd $oldDir
    exit 1
fi

cleaner=$buildDir/../sharedMemFIFOBench/build/cleanupShared

vitisFromADCPipe="rx_demo_inst2_input_bundle_1"
vitisFromRxPipe="rx_demo_inst2_output_bundle_1"
vitisToTxPipe="tx_demo_inst2_input_bundle_1"
vitisToDACPipe="tx_demo_inst2_output_bundle_1"
TxFeedbkAppPipeName="txFeedbkAppLayer_inst2"

pkill -f bladeRFToFIFO
pkill -f benchmark_tx_demo_inst2_io_posix_shared_mem
pkill -f benchmark_rx_demo_inst2_io_posix_shared_mem
pkill -f cyclopsASCIILink
pkill -f dummyAdcDacSharedMemFIFO

${cleaner} ${vitisFromADCPipe}
${cleaner} ${vitisFromRxPipe}
${cleaner} ${vitisToTxPipe}
${cleaner} ${vitisToDACPipe}
${cleaner} ${TxFeedbkAppPipeName}

cd $oldDir