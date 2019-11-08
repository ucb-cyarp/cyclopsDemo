#!/bin/bash
# using https://stackoverflow.com/questions/1908610/how-to-get-pid-of-background-process

cleaner=~/git/cyclopsDemo/sharedMemFIFOBench/build/cleanupShared

vitisFromADCPipe="rx_demo_input_bundle_1"
vitisFromRxPipe="rx_demo_output_bundle_2"
vitisToTxPipe="tx_demo_input_bundle_1"
vitisToDACPipe="tx_demo_output_bundle_2"
TxFeedbkAppPipeName="txFeedbkAppLayer"

pkill -f uhdToPipes
pkill -f benchmark_tx_demo_io_posix_shared_mem
pkill -f benchmark_rx_demo_io_posix_shared_mem
pkill -f cyclopsASCIILink
pkill -f dummyAdcDacSharedMemFIFO

${cleaner} ${vitisFromADCPipe}
${cleaner} ${vitisFromRxPipe}
${cleaner} ${vitisToTxPipe}
${cleaner} ${vitisToDACPipe}
${cleaner} ${TxFeedbkAppPipeName}