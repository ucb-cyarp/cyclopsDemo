#!/bin/bash
# Inspired by https://stackoverflow.com/questions/5447278/bash-scripts-with-tmux-to-launch-a-4-paned-window
# but used a lot of tmux forum splunking, manpage reading, and various user's tmux

RxSrc=rev1BB_receiver
TxSrc=rev1BB_transmitter
cyclopsASCIIDir=../submodules/cyclopsASCIILink
uhdToPipesDir=../submodules/uhdToPipes
dummyAdcDacDir=../dummyAdcDac
BlockSize=32

if [ -z $1 ]; then
    USE_DUMMY=0
else
    USE_DUMMY=$1
fi

appCPU=1
TxTokens=10
txPer=1.0

vitisFromADCPipe="rx/input_bundle_1.pipe"
vitisFromRxPipe="rx/output_bundle_2.pipe"

vitisToTxPipe="tx/input_bundle_1.pipe"
vitisToDACPipe="tx/output_bundle_2.pipe"

uhdCPU=2
txCPU=3
rxCPU=18

usrpArgs="addr=192.168.40.2"
Freq=5800000000
Rate=4000000
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
tmux new-session -d -s vitis_cyclopse_demo "printf '\\033]2;%s\\033\\\\' 'Rx_DSP'; ${RxDir}/benchmark_rx_demo_io_linux_pipe"
tmux rename-window -t vitis_cyclopse_demo:0 'vitis_cyclopse_demo'
tmux set-option -t vitis_cyclopse_demo pane-border-status top

echo "${RxDir}/benchmark_rx_demo_io_linux_pipe"
cd ..
mkdir tx
cd tx
tmux split-window -h -d -t vitis_cyclopse_demo:0 "printf '\\033]2;%s\\033\\\\' 'Tx_DSP'; ${TxDir}/benchmark_tx_demo_io_linux_pipe"
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
tmux split-window -v -d -t vitis_cyclopse_demo:0 "printf '\\033]2;%s\\033\\\\' 'Cyclops_ASCII_Application'; ${cyclopsASCIIBuildDir}/cyclopsASCIILink -rx ./${vitisFromRxPipe} -tx ./${vitisToTxPipe} -txfb ./${TxFeedbkAppPipeName} -txtokens ${TxTokens} -cpu ${appCPU} -txperiod ${txPer}"
# tmux rename-window -t vitis_cyclopse_demo:2 'cyclopsASCII'
echo "${cyclopsASCIIBuildDir}/cyclopsASCIILink -rx ./${vitisFromRxPipe} -tx ./${vitisToTxPipe} -txfb ./${TxFeedbkAppPipeName} -txtokens ${TxTokens} -cpu ${appCPU} -txperiod ${txPer}"

if [ ${USE_DUMMY} -ne 0 ]; then
    #Start dummyAdcDac
    tmux split-window -v -d -t vitis_cyclopse_demo:0.2 "printf '\\033]2;%s\\033\\\\' 'Dummy_DAC/DAC'; ${dummyAdcDacBuildDir}/dummyAdcDac -cpu ${txCPU} -rx ./${vitisFromADCPipe} -tx ./${vitisToDACPipe} -txfb ./${TxFeedbkAppPipeName} -blocklen ${BlockSize}"
    # tmux rename-window -t vitis_cyclopse_demo:3 'dummyAdcDac'
    echo "${dummyAdcDacBuildDir}/dummyAdcDac -cpu ${txCPU} -rx ./${vitisFromADCPipe} -tx ./${vitisToDACPipe} -txfb ./${TxFeedbkAppPipeName} -blocklen ${BlockSize}"
else
    # #Start uhdToPipes
    # ${uhdToPipesBuildDir}/uhdToPipes -a ${usrpArgs} -f ${Freq} -r ${Rate} --txgain ${TxGainDB} --rxgain ${RxGainDB} --txcpu ${txCPU} --rxcpu ${rxCPU} --rxpipe ./${vitisFromADCPipe} --txpipe ./${vitisToDACPipe} --txfeedbackpipe ./${TxFeedbkAppPipeName} --samppertransactrx ${BlockSize} --samppertransacttx ${BlockSize} --forcefulltxbuffer --txchan ${txChan} --rxchan ${rxChan} &
    tmux split-window -v -d -t vitis_cyclopse_demo:0.2 "printf '\\033]2;%s\\033\\\\' 'UHD/USRP'; module load uhd; ${uhdToPipesBuildDir}/uhdToPipes -a ${usrpArgs} -f ${Freq} -r ${Rate} --txgain ${TxGainDB} --rxgain ${RxGainDB} --uhdcpu ${uhdCPU} --txcpu ${txCPU} --rxcpu ${rxCPU} --rxpipe ./${vitisFromADCPipe} --txpipe ./${vitisToDACPipe} --txfeedbackpipe ./${TxFeedbkAppPipeName} --samppertransactrx ${BlockSize} --samppertransacttx ${BlockSize} --forcefulltxbuffer --txchan ${txChan} --rxchan ${rxChan} --txratelimit"
    # tmux split-window -v -d -t vitis_cyclopse_demo:0.2 "printf '\\033]2;%s\\033\\\\' 'UHD/USRP'; module load uhd; ${uhdToPipesBuildDir}/uhdToPipes -a ${usrpArgs} -f ${Freq} -r ${Rate} --txgain ${TxGainDB} --rxgain ${RxGainDB} --uhdcpu ${uhdCPU} --txcpu ${txCPU} --rxcpu ${rxCPU} --rxpipe ./${vitisFromADCPipe} --txpipe ./${vitisToDACPipe} --txfeedbackpipe ./${TxFeedbkAppPipeName} --samppertransactrx ${BlockSize} --samppertransacttx ${BlockSize} --txchan ${txChan} --rxchan ${rxChan} --txratelimit"
    # tmux split-window -v -d -t vitis_cyclopse_demo:0.2 "printf '\\033]2;%s\\033\\\\' 'UHD/USRP'; module load uhd; ${uhdToPipesBuildDir}/uhdToPipes -a ${usrpArgs} -f ${Freq} -r ${Rate} --txgain ${TxGainDB} --rxgain ${RxGainDB} --uhdcpu ${uhdCPU} --txcpu ${txCPU} --rxcpu ${rxCPU} --rxpipe ./${vitisFromADCPipe} --txpipe ./${vitisToDACPipe} --txfeedbackpipe ./${TxFeedbkAppPipeName} --samppertransactrx ${BlockSize} --samppertransacttx ${BlockSize} --txchan ${txChan} --rxchan ${rxChan}"
    # tmux split-window -v -d -t vitis_cyclopse_demo:0.2 "printf '\\033]2;%s\\033\\\\' 'UHD/USRP'; module load uhd; ${uhdToPipesBuildDir}/uhdToPipes -a ${usrpArgs} -f ${Freq} -r ${Rate} --txgain ${TxGainDB} --rxgain ${RxGainDB} --uhdcpu ${uhdCPU} --txcpu ${txCPU} --rxcpu ${rxCPU} --rxpipe ./${vitisFromADCPipe} --txpipe ./${vitisToDACPipe} --txfeedbackpipe ./${TxFeedbkAppPipeName} --samppertransactrx ${BlockSize} --samppertransacttx ${BlockSize} --forcefulltxbuffer --txchan ${txChan} --rxchan ${rxChan}"
    # tmux rename-window -t vitis_cyclopse_demo:3 'uhdToPipes'
    echo "${uhdToPipesBuildDir}/uhdToPipes -a ${usrpArgs} -f ${Freq} -r ${Rate} --txgain ${TxGainDB} --rxgain ${RxGainDB} --uhdcpu ${uhdCPU} --txcpu ${txCPU} --rxcpu ${rxCPU} --rxpipe ./${vitisFromADCPipe} --txpipe ./${vitisToDACPipe} --txfeedbackpipe ./${TxFeedbkAppPipeName} --samppertransactrx ${BlockSize} --samppertransacttx ${BlockSize} --forcefulltxbuffer --txchan ${txChan} --rxchan ${rxChan} --txratelimit"
    # echo "${uhdToPipesBuildDir}/uhdToPipes -a ${usrpArgs} -f ${Freq} -r ${Rate} --txgain ${TxGainDB} --rxgain ${RxGainDB} --uhdcpu ${uhdCPU} --txcpu ${txCPU} --rxcpu ${rxCPU} --rxpipe ./${vitisFromADCPipe} --txpipe ./${vitisToDACPipe} --txfeedbackpipe ./${TxFeedbkAppPipeName} --samppertransactrx ${BlockSize} --samppertransacttx ${BlockSize} --txchan ${txChan} --rxchan ${rxChan} --txratelimit"
    # echo "${uhdToPipesBuildDir}/uhdToPipes -a ${usrpArgs} -f ${Freq} -r ${Rate} --txgain ${TxGainDB} --rxgain ${RxGainDB} --uhdcpu ${uhdCPU} --txcpu ${txCPU} --rxcpu ${rxCPU} --rxpipe ./${vitisFromADCPipe} --txpipe ./${vitisToDACPipe} --txfeedbackpipe ./${TxFeedbkAppPipeName} --samppertransactrx ${BlockSize} --samppertransacttx ${BlockSize} --txchan ${txChan} --rxchan ${rxChan}"
    # echo "${uhdToPipesBuildDir}/uhdToPipes -a ${usrpArgs} -f ${Freq} -r ${Rate} --txgain ${TxGainDB} --rxgain ${RxGainDB} --uhdcpu ${uhdCPU} --txcpu ${txCPU} --rxcpu ${rxCPU} --rxpipe ./${vitisFromADCPipe} --txpipe ./${vitisToDACPipe} --txfeedbackpipe ./${TxFeedbkAppPipeName} --samppertransactrx ${BlockSize} --samppertransacttx ${BlockSize} --forcefulltxbuffer --txchan ${txChan} --rxchan ${rxChan}"
fi

cd ${curDir}

if [ -z ${TMUX} ]; then
    tmux attach-session -t vitis_cyclopse_demo
else
    echo "Use TMUX to switch to the new session: vitis_cyclopse_demo"
fi
