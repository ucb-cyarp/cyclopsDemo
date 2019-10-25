#!/bin/bash
# using https://stackoverflow.com/questions/1908610/how-to-get-pid-of-background-process

RxSrc=rx_combined_man_partition_fewerLuts_demo_fastslim1_fast1_slow1
TxSrc=transmitter_man_partition_fewerLuts_demo_fastslim1_fast1_slow1
cyclopsASCIIDir=~/git/cyclopsASCIILink
uhdToPipesDir=~/git/uhdToPipes
dummyAdcDacDir=~/git/cyclopsDemo/dummyAdcDac
BlockSize=64

appCPU=1
TxTokens=10

vitisFromADCPipe="rx/input_bundle_1.pipe"
vitisFromRxPipe="rx/output_bundle_2.pipe"

vitisToTxPipe="tx/input_bundle_1.pipe"
vitisToDACPipe="tx/output_bundle_2.pipe"

txCPU=16
rxCPU=17
usrpArgs="addr=192.168.40.2"
Freq=5800000000
Rate=1000000
TxGainDB=25
RxGainDB=25
txChan=0
rxChan=1

curDir=`pwd`
RxDir=${curDir}/cOut_${RxSrc}
TxDir=${curDir}/cOut_${TxSrc}
cyclopsASCIIBuildDir=${cyclopsASCIIDir}/build
uhdToPipesBuildDir=${uhdToPipesDir}/build
dummyAdcDacBuildDir=${dummyAdcDacDir}/build

mkdir demoRun
cd demoRun
#Start vitis generated code
mkdir rx
cd rx
${RxDir}/benchmark_rx_demo_io_linux_pipe &
RX_PID=$!
RX_CMD="${RxDir}/benchmark_rx_demo_io_linux_pipe &"
echo "[${RX_PID}] ${RX_CMD}"
cd ..
mkdir tx
cd tx
${TxDir}/benchmark_tx_demo_io_linux_pipe &
TX_PID=$!
TX_CMD="${TxDir}/benchmark_tx_demo_io_linux_pipe &"
echo "[${TX_PID}] ${TX_CMD}"
cd ..

#Create Feeback Pipe for the Application Layer Side
TxFeedbkAppPipeName="txFeedbkAppLayer.pipe"
mkfifo ${TxFeedbkAppPipeName}
echo "mkfifo ${TxFeedbkAppPipeName}"

echo "Waiting 5 Seconds for DSP to Start"
sleep 5

#Start cyclopsASCII (before the ADC/DAC)
#Feedback backpressure will prevent a runaway
${cyclopsASCIIBuildDir}/cyclopsASCIILink -rx ./${vitisFromRxPipe} -tx ./${vitisToTxPipe} -txfb ./${TxFeedbkAppPipeName} -txtokens ${TxTokens} -cpu ${appCPU} & 
CYCLOPSASCII_PID=$!
CYCLOPSASCII_CMD="${cyclopsASCIIBuildDir}/cyclopsASCIILink -rx ./${vitisFromRxPipe} -tx ./${vitisToTxPipe} -txfb ./${TxFeedbkAppPipeName} -txtokens ${TxTokens} -cpu ${appCPU} &"
echo "[${CYCLOPSASCII_PID}] ${CYCLOPSASCII_CMD}"

#Start dummyAdcDac
${dummyAdcDacBuildDir}/dummyAdcDac -cpu ${txCPU} -rx ./${vitisFromADCPipe} -tx ./${vitisToDACPipe} -txfb ./${TxFeedbkAppPipeName} -blocklen ${BlockSize} -gain 0.001 &
DUMMYADCDAC_PID=$!
DUMMYADCDAC_CMD="${dummyAdcDacBuildDir}/dummyAdcDac -cpu ${txCPU} -rx ./${vitisFromADCPipe} -tx ./${vitisToDACPipe} -txfb ./${TxFeedbkAppPipeName} -blocklen ${BlockSize} -gain 0.001 &"
echo "[${DUMMYADCDAC_PID}] ${DUMMYADCDAC_CMD}"

# #Start uhdToPipes
# # ${uhdToPipesBuildDir}/uhdToPipes -a ${usrpArgs} -f ${Freq} -r ${Rate} --txgain ${TxGainDB} --rxgain ${RxGainDB} --txcpu ${txCPU} --rxcpu ${rxCPU} --rxpipe ./${vitisFromADCPipe} --txpipe ./${vitisToDACPipe} --txfeedbackpipe ./${TxFeedbkAppPipeName} --samppertransactrx ${BlockSize} --samppertransacttx ${BlockSize} --forcefulltxbuffer --txchan ${txChan} --rxchan ${rxChan} &
# ${uhdToPipesBuildDir}/uhdToPipes -a ${usrpArgs} -f ${Freq} -r ${Rate} --txgain ${TxGainDB} --rxgain ${RxGainDB} --txcpu ${txCPU} --rxcpu ${rxCPU} --rxpipe ./${vitisFromADCPipe} --txpipe ./${vitisToDACPipe} --txfeedbackpipe ./${TxFeedbkAppPipeName} --samppertransactrx ${BlockSize} --samppertransacttx ${BlockSize} --forcefulltxbuffer --txchan ${txChan} --rxchan ${rxChan} --txratelimit &
# UHDTOPIPES_PID=$!
# # UDDTOPIPES_CMD="${uhdToPipesBuildDir}/uhdToPipes -a ${usrpArgs} -f ${Freq} -r ${Rate} --txgain ${TxGainDB} --rxgain ${RxGainDB} --txcpu ${txCPU} --rxcpu ${rxCPU} --rxpipe ./${vitisFromADCPipe} --txpipe ./${vitisToDACPipe} --txfeedbackpipe ./${TxFeedbkAppPipeName} --samppertransactrx ${BlockSize} --samppertransacttx ${BlockSize} --forcefulltxbuffer --txchan ${txChan} --rxchan ${rxChan} &"
# UDDTOPIPES_CMD="${uhdToPipesBuildDir}/uhdToPipes -a ${usrpArgs} -f ${Freq} -r ${Rate} --txgain ${TxGainDB} --rxgain ${RxGainDB} --txcpu ${txCPU} --rxcpu ${rxCPU} --rxpipe ./${vitisFromADCPipe} --txpipe ./${vitisToDACPipe} --txfeedbackpipe ./${TxFeedbkAppPipeName} --samppertransactrx ${BlockSize} --samppertransacttx ${BlockSize} --forcefulltxbuffer --txchan ${txChan} --rxchan ${rxChan} --txratelimit &"
# echo "[${UHDTOPIPES_PID}] ${UDDTOPIPES_CMD}"

echo "Waiting for RX Proc to Exit"
wait ${RX_PID}
echo "Waiting for TX Proc to Exit"
wait ${TX_PID}
echo "Waiting for CYCLOPS Proc to Exit"
wait ${CYCLOPSASCII_PID}
# echo "Waiting for DUMMYADCDAC Proc to Exit"
# wait ${DUMMYADCDAC_PID}
echo "Waiting for UHDTOPIPES Proc to Exit"
wait ${UHDTOPIPES_PID}

echo "Procs Exited"

#Cleanup Feeback Pipe for the Application Layer Side
rm ${TxFeedbkAppPipeName}

cd ${curDir}