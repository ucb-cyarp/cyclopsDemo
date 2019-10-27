#!/bin/bash
# Inspired by https://stackoverflow.com/questions/5447278/bash-scripts-with-tmux-to-launch-a-4-paned-window
# but used a lot of tmux forum splunking, manpage reading, and various user's tmux

RxSrc=rx_combined_man_partition_fewerLuts_demo_fastslim1_fast1_slow1
TxSrc=transmitter_man_partition_fewerLuts_demo_fastslim1_fast1_slow1
cyclopsASCIIDir=~/git/cyclopsASCIILink
uhdToPipesDir=~/git/uhdToPipes
dummyAdcDacDir=~/git/cyclopsDemo/dummyAdcDac
BlockSize=32

USE_DUMMY=0

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
TxGainDB=30
RxGainDB=30
txChan=0
rxChan=1

curDir=`pwd`
RxDir=${curDir}/cOut_${RxSrc}
TxDir=${curDir}/cOut_${TxSrc}
cyclopsASCIIBuildDir=${cyclopsASCIIDir}/build
uhdToPipesBuildDir=${uhdToPipesDir}/build
dummyAdcDacBuildDir=${dummyAdcDacDir}/build

if [ ${USE_DUMMY} -ne 0 ]; then
    echo "Demo with Dummy ADC/DAC"
else
    echo "Demo with USRP/UHD"
fi

mkdir demoRun
cd demoRun
#Start vitis generated code
mkdir rx
cd rx
tmux new-session -d -s vitis_cyclopse_demo "${RxDir}/benchmark_rx_demo_io_linux_pipe"
tmux rename-window -t vitis_cyclopse_demo:0 'vitis_cyclopse_demo'

echo "${RxDir}/benchmark_rx_demo_io_linux_pipe"
cd ..
mkdir tx
cd tx
tmux split-window -h -d -t vitis_cyclopse_demo:0 "${TxDir}/benchmark_tx_demo_io_linux_pipe"
# tmux rename-window -t vitis_cyclopse_demo:1 'tx'
echo "${TxDir}/benchmark_tx_demo_io_linux_pipe"
cd ..

#Create Feeback Pipe for the Application Layer Side
TxFeedbkAppPipeName="txFeedbkAppLayer.pipe"
mkfifo ${TxFeedbkAppPipeName}
echo "mkfifo ${TxFeedbkAppPipeName}"

echo "Waiting 5 Seconds for DSP to Start"
sleep 5

#Start cyclopsASCII (before the ADC/DAC)
#Feedback backpressure will prevent a runaway
tmux split-window -v -d -t vitis_cyclopse_demo:0 "${cyclopsASCIIBuildDir}/cyclopsASCIILink -rx ./${vitisFromRxPipe} -tx ./${vitisToTxPipe} -txfb ./${TxFeedbkAppPipeName} -txtokens ${TxTokens} -cpu ${appCPU}"
# tmux rename-window -t vitis_cyclopse_demo:2 'cyclopsASCII'
echo "${cyclopsASCIIBuildDir}/cyclopsASCIILink -rx ./${vitisFromRxPipe} -tx ./${vitisToTxPipe} -txfb ./${TxFeedbkAppPipeName} -txtokens ${TxTokens} -cpu ${appCPU}"

if [ ${USE_DUMMY} -ne 0 ]; then
    #Start dummyAdcDac
    tmux split-window -v -d -t vitis_cyclopse_demo:0.2 "${dummyAdcDacBuildDir}/dummyAdcDac -cpu ${txCPU} -rx ./${vitisFromADCPipe} -tx ./${vitisToDACPipe} -txfb ./${TxFeedbkAppPipeName} -blocklen ${BlockSize}"
    # tmux rename-window -t vitis_cyclopse_demo:3 'dummyAdcDac'
    echo "${dummyAdcDacBuildDir}/dummyAdcDac -cpu ${txCPU} -rx ./${vitisFromADCPipe} -tx ./${vitisToDACPipe} -txfb ./${TxFeedbkAppPipeName} -blocklen ${BlockSize}"
else
    # #Start uhdToPipes
    # ${uhdToPipesBuildDir}/uhdToPipes -a ${usrpArgs} -f ${Freq} -r ${Rate} --txgain ${TxGainDB} --rxgain ${RxGainDB} --txcpu ${txCPU} --rxcpu ${rxCPU} --rxpipe ./${vitisFromADCPipe} --txpipe ./${vitisToDACPipe} --txfeedbackpipe ./${TxFeedbkAppPipeName} --samppertransactrx ${BlockSize} --samppertransacttx ${BlockSize} --forcefulltxbuffer --txchan ${txChan} --rxchan ${rxChan} &
    tmux split-window -v -d -t vitis_cyclopse_demo:0.2 "module load uhd; ${uhdToPipesBuildDir}/uhdToPipes -a ${usrpArgs} -f ${Freq} -r ${Rate} --txgain ${TxGainDB} --rxgain ${RxGainDB} --txcpu ${txCPU} --rxcpu ${rxCPU} --rxpipe ./${vitisFromADCPipe} --txpipe ./${vitisToDACPipe} --txfeedbackpipe ./${TxFeedbkAppPipeName} --samppertransactrx ${BlockSize} --samppertransacttx ${BlockSize} --forcefulltxbuffer --txchan ${txChan} --rxchan ${rxChan} --txratelimit"
    # tmux rename-window -t vitis_cyclopse_demo:3 'uhdToPipes'
    # UDDTOPIPES_CMD="${uhdToPipesBuildDir}/uhdToPipes -a ${usrpArgs} -f ${Freq} -r ${Rate} --txgain ${TxGainDB} --rxgain ${RxGainDB} --txcpu ${txCPU} --rxcpu ${rxCPU} --rxpipe ./${vitisFromADCPipe} --txpipe ./${vitisToDACPipe} --txfeedbackpipe ./${TxFeedbkAppPipeName} --samppertransactrx ${BlockSize} --samppertransacttx ${BlockSize} --forcefulltxbuffer --txchan ${txChan} --rxchan ${rxChan} &"
    echo "${uhdToPipesBuildDir}/uhdToPipes -a ${usrpArgs} -f ${Freq} -r ${Rate} --txgain ${TxGainDB} --rxgain ${RxGainDB} --txcpu ${txCPU} --rxcpu ${rxCPU} --rxpipe ./${vitisFromADCPipe} --txpipe ./${vitisToDACPipe} --txfeedbackpipe ./${TxFeedbkAppPipeName} --samppertransactrx ${BlockSize} --samppertransacttx ${BlockSize} --forcefulltxbuffer --txchan ${txChan} --rxchan ${rxChan} --txratelimit"
fi

cd ${curDir}

tmux attach-session -t vitis_cyclopse_demo