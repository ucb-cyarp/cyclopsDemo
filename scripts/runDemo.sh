#!/bin/bash
# using https://stackoverflow.com/questions/1908610/how-to-get-pid-of-background-process

RxSrc=rx_combined_man_partition_fewerLuts_demo_fastslim1_fast1_slow1
TxSrc=transmitter_man_partition_fewerLuts_demo_fastslim1_fast1_slow1
cyclopsASCIIDir=~/git/cyclopsASCIILink
uhdToPipesDir=~/git/uhdToPipes
BlockSize=16

appCPU=1
TxTokens=10

vitisFromADCPipe="rx/input_bundle_1.pipe"
vitisFromRxPipe="rx/output_bundle_2.pipe"

vitisToTxPipe="tx/input_bundle_1.pipe"
vitisToDACPipe="tx/output_bundle_2.pipe"

txCPU=16
rxCPU=17
usrpArgs="addr=192.168.10.2"
Freq=5800000000
Rate=1000000
TxGainDB=0
RxGainDB=0

curDir=`pwd`
RxDir=${curDir}/cOut_${RxSrc}
TxDir=${curDir}/cOut_${TxSrc}
cyclopsASCIIBuildDir=${cyclopsASCIIDir}/build
uhdToPipesBuildDir=${uhdToPipesDir}/build

mkdir demoRun
cd demoRun
#Start vitis generated code
mkdir rx
cd rx
${RxDir}/benchmark_rx_demo_io_linux_pipe > out.txt &
RX_PID=$!
RX_CMD="${RxDir}/benchmark_rx_demo_io_linux_pipe > out.txt &"
echo "[${RX_PID}] ${RX_CMD}"
cd ..
mkdir tx
cd tx
${TxDir}/benchmark_tx_demo_io_linux_pipe > out.txt &
TX_PID=$!
TX_CMD="${TxDir}/benchmark_tx_demo_io_linux_pipe > out.txt &"
echo "[${TX_PID}] ${TX_CMD}"
cd ..

#Create Feeback Pipe for the Application Layer Side
TxFeedbkAppPipeName="txFeedbkAppLayer.pipe"
mkfifo ${TxFeedbkAppPipeName}

#Start cyclopsASCII (before the ADC/DAC)
#Feedback backpressure will prevent a runaway
${cyclopsASCIIBuildDir}/cyclopsASCIILink -rx ./${vitisFromRxPipe} -tx ./${vitisToTxPipe} -txfb ./${TxFeedbkAppPipeName} -txtokens ${TxTokens} -cpu ${appCPU} &
CYCLOPSASCII_PID=$!
CYCLOPSASCII_CMD="${cyclopsASCIIBuildDir}/cyclopsASCIILink -rx ./${vitisFromRxPipe} -tx ./${vitisToTxPipe} -txfb ./${TxFeedbkAppPipeName} -txtokens ${TxTokens} -cpu ${appCPU} &"
echo "[${CYCLOPSASCII_PID}] ${CYCLOPSASCII_CMD}"

#Start uhdToPipes
${uhdToPipesBuildDir}/uhdToPipes -a ${usrpArgs} -f ${Freq} -r ${Rate} --txgain ${TxGainDB} --rxgain ${RxGainDB} --txcpu ${txCPU} --rxcpu ${rxCPU} --rxpipe ${vitisFromADCPipe} --txpipe ${vitisToDACPipe} --txfeedbackpipe ${TxFeedbkAppPipeName} --samppertransactrx ${BlockSize} --samppertransacttx ${BlockSize} --forcefulltxbuffer > uhd.out &
UHDTOPIPES_PID=$!
UDDTOPIPES_CMD="${uhdToPipesBuildDir}/uhdToPipes -a ${usrpArgs} -f ${Freq} -r ${Rate} --txgain ${TxGainDB} --rxgain ${RxGainDB} --txcpu ${txCPU} --rxcpu ${rxCPU} --rxpipe ${vitisFromADCPipe} --txpipe ${vitisToDACPipe} --txfeedbackpipe ${TxFeedbkAppPipeName} --samppertransactrx ${BlockSize} --samppertransacttx ${BlockSize} --forcefulltxbuffer > uhd.out &"
echo "[${UHDTOPIPES_PID}] ${UDDTOPIPES_CMD}"

echo "Waiting for RX Proc to Exit"
wait ${RX_PID}
echo "Waiting for TX Proc to Exit"
wait ${TX_PID}
echo "Waiting for CYCLOPS Proc to Exit"
wait ${CYCLOPSASCII_PID}
echo "Waiting for UHDTOPIPES Proc to Exit"
wait ${UHDTOPIPES_PID}

echo "Procs Exited"

#Cleanup Feeback Pipe for the Application Layer Side
rm ${TxFeedbkAppPipeName}

cd ${curDir}