#!/bin/bash
# Inspired by https://stackoverflow.com/questions/5447278/bash-scripts-with-tmux-to-launch-a-4-paned-window
# but used a lot of tmux forum splunking, manpage reading, and various user's tmux

RxSrc=rev1BB_receiver
TxSrc=rev1BB_transmitter
cyclopsASCIIDir=../../submodules/cyclopsASCIILink-sharedMem
bladeRFToFIFODir=../../submodules/bladeRFToFIFO
dummyAdcDacDir=../../dummyAdcDacSharedMemFIFO
BlockSize=120
#BlockSize=64
#BlockSize=16
IO_FIFO_SIZE=120

if [ -z $1 ]; then
    USE_DUMMY=0
else
    USE_DUMMY=$1
fi

appCPU=7 # Epyc 3000 & Ryzen 3000 (New Bios)
# appCPU=4 # Ryzen 3000 (Old Bios)
TxTokens=1000
txdutycycle=1.00
# rxsubsampleperiod=2000
rxsubsampleperiod=100
# rxsubsampleperiod=10

#ProcessLimitCyclops=10
ProcessLimitCyclops=100
vitisFromADCPipe="rx_demo_input_bundle_1"
vitisFromRxPipe="rx_demo_output_bundle_1"

vitisToTxPipe="tx_demo_input_bundle_1"
vitisToDACPipe="tx_demo_output_bundle_1"

#Epyc 7002 & Ryzen 3000 (New Bios)
uhdCPU=4 
txCPU=5
rxCPU=6

# #Ryzen 3000 (Old Bios)
# uhdCPU=1
# txCPU=2
# rxCPU=3

Freq=2400000000
#CSV Dump Rate
Rate=1000000
BW=1000000
#Low Rate
# Rate=4000000
# BW=6000000
#Max Reccomended BladeRF Rate 1x1 Tx/Rx simultanious
# Rate=40000000
# BW=40000000
#Max Rate
# Rate=61440000
# BW=56000000
TxGainDB=45
RxGainDB=35
#For BladeRF Only
FullScale=1.75
#For USRP Only
usrpArgs="addr=192.168.40.2"
txChan=0
rxChan=1

## BladeRF IQ Params
# BLADERF_A_SERIAL="3baf359b82904cb4967f4c275f174b88"
# BLADERF_A_RX_DC_I="-0.64618"
# BLADERF_A_RX_DC_Q="-0.15726"
# BLADERF_A_RX_IQ_GAIN="0.86432"
# BLADERF_A_RX_IQ_PHASE_DEG="-1.7253"
# BLADERF_A_TX_DC_I="0.18758"
# BLADERF_A_TX_DC_Q="-0.10816"
# BLADERF_A_TX_IQ_GAIN="0.9839"
# BLADERF_A_TX_IQ_PHASE_DEG="-0.010293"

BLADERF_B_SERIAL="72e930b12d1441ba861ed8f0396f0238"
BLADERF_B_RX_DC_I="-0.055969"
BLADERF_B_RX_DC_Q="0.7084"
BLADERF_B_RX_IQ_GAIN="1.0871"
BLADERF_B_RX_IQ_PHASE_DEG="-1.3382"
BLADERF_B_TX_DC_I="0.6388"
BLADERF_B_TX_DC_Q="0.95944"
BLADERF_B_TX_IQ_GAIN="0.98044"
BLADERF_B_TX_IQ_PHASE_DEG="-0.0055925"

BLADERF_A_SERIAL="3baf359b82904cb4967f4c275f174b88"
BLADERF_A_RX_DC_I="0"
BLADERF_A_RX_DC_Q="0"
BLADERF_A_RX_IQ_GAIN="1"
BLADERF_A_RX_IQ_PHASE_DEG="0"
BLADERF_A_TX_DC_I="0"
BLADERF_A_TX_DC_Q="0"
BLADERF_A_TX_IQ_GAIN="1"
BLADERF_A_TX_IQ_PHASE_DEG="0"

BLADERF_TX="A" #A or B
BLADERF_RX="A" #A or B

if [[ ${BLADERF_TX} == "A" ]]; then
    BLADERF_TX_SERIAL=${BLADERF_A_SERIAL};
    BLADERF_TX_DC_I=${BLADERF_A_TX_DC_I};
    BLADERF_TX_DC_Q=${BLADERF_A_TX_DC_Q};
    BLADERF_TX_IQ_GAIN=${BLADERF_A_TX_IQ_GAIN};
    BLADERF_TX_IQ_PHASE_DEG=${BLADERF_A_TX_IQ_PHASE_DEG};
elif [[ ${BLADERF_TX} == "B" ]]; then
    BLADERF_TX_SERIAL=${BLADERF_B_SERIAL};
    BLADERF_TX_DC_I=${BLADERF_B_TX_DC_I};
    BLADERF_TX_DC_Q=${BLADERF_B_TX_DC_Q};
    BLADERF_TX_IQ_GAIN=${BLADERF_B_TX_IQ_GAIN};
    BLADERF_TX_IQ_PHASE_DEG=${BLADERF_B_TX_IQ_PHASE_DEG};
else
    echo "Unknown BladeRF_TX!"
    exit 1
fi

if [[ ${BLADERF_RX} == "A" ]]; then
    BLADERF_RX_SERIAL=${BLADERF_A_SERIAL};
    BLADERF_RX_DC_I=${BLADERF_A_RX_DC_I};
    BLADERF_RX_DC_Q=${BLADERF_A_RX_DC_Q};
    BLADERF_RX_IQ_GAIN=${BLADERF_A_RX_IQ_GAIN};
    BLADERF_RX_IQ_PHASE_DEG=${BLADERF_A_RX_IQ_PHASE_DEG};
elif [[ ${BLADERF_RX} == "B" ]]; then
    BLADERF_RX_SERIAL=${BLADERF_B_SERIAL};
    BLADERF_RX_DC_I=${BLADERF_B_RX_DC_I};
    BLADERF_RX_DC_Q=${BLADERF_B_RX_DC_Q};
    BLADERF_RX_IQ_GAIN=${BLADERF_B_RX_IQ_GAIN};
    BLADERF_RX_IQ_PHASE_DEG=${BLADERF_B_RX_IQ_PHASE_DEG};
else
    echo "Unknown BladeRF_TX!"
    exit 1
fi

curDir=`pwd`
RxDir=${curDir}/cOut_${RxSrc}
TxDir=${curDir}/cOut_${TxSrc}
cyclopsASCIIBuildDir=${cyclopsASCIIDir}/build
bladeRFToFIFOBuildDir=${bladeRFToFIFODir}/build
dummyAdcDacBuildDir=${dummyAdcDacDir}/build

if [ ${USE_DUMMY} -ne 0 ]; then
    echo "Demo with Dummy ADC/DAC"
else
    echo "Demo with bladeRF"
fi

if [[ -d "demoRun" ]]; then
	echo "rm -r demoRun"
	rm -r demoRun
fi
mkdir demoRun
cd demoRun
#Start vitis generated code
mkdir rx
cd rx
tmux new-session -d -s vitis_cyclopse_demo "printf '\\033]2;%s\\033\\\\' 'Rx_DSP'; module load papi; ${RxDir}/benchmark_rx_demo_io_posix_shared_mem"
tmux rename-window -t vitis_cyclopse_demo:0 'vitis_cyclopse_demo'
tmux set-option -t vitis_cyclopse_demo pane-border-status top

echo "${RxDir}/benchmark_rx_demo_io_posix_shared_mem"
cd ..
mkdir tx
cd tx
tmux split-window -h -d -t vitis_cyclopse_demo:0 "printf '\\033]2;%s\\033\\\\' 'Tx_DSP'; module load papi; ${TxDir}/benchmark_tx_demo_io_posix_shared_mem; sleep 5"
# tmux rename-window -t vitis_cyclopse_demo:1 'tx'
echo "${TxDir}/benchmark_tx_demo_io_posix_shared_mem"
cd ..

#Create Feeback Pipe for the Application Layer Side
TxFeedbkAppPipeName="txFeedbkAppLayer"

echo "Waiting 5 Seconds for DSP to Start"
sleep 5

#Start cyclopsASCII (before the ADC/DAC)
#Feedback backpressure will prevent a runaway
tmux split-window -v -d -t vitis_cyclopse_demo:0 "printf '\\033]2;%s\\033\\\\' 'Cyclops_ASCII_Application'; ${cyclopsASCIIBuildDir}/cyclopsASCIILink -rx ${vitisFromRxPipe} -tx ${vitisToTxPipe} -txfb ${TxFeedbkAppPipeName} -txtokens ${TxTokens} -cpu ${appCPU} -processlimit ${ProcessLimitCyclops} -txdutycycle ${txdutycycle} -rxsubsampleperiod ${rxsubsampleperiod} -fifosize ${IO_FIFO_SIZE}; sleep 5"
# tmux rename-window -t vitis_cyclopse_demo:2 'cyclopsASCII'
echo "${cyclopsASCIIBuildDir}/cyclopsASCIILink -rx ${vitisFromRxPipe} -tx ${vitisToTxPipe} -txfb ${TxFeedbkAppPipeName} -txtokens ${TxTokens} -cpu ${appCPU} -processlimit ${ProcessLimitCyclops} -txdutycycle ${txdutycycle} -rxsubsampleperiod ${rxsubsampleperiod} -fifosize ${IO_FIFO_SIZE}"

if [ ${USE_DUMMY} -ne 0 ]; then
    #Start dummyAdcDac
    tmux split-window -v -d -t vitis_cyclopse_demo:0.2 "printf '\\033]2;%s\\033\\\\' 'Dummy_DAC/DAC'; ${dummyAdcDacBuildDir}/dummyAdcDacSharedMemFIFO -cpu ${txCPU} -rx ${vitisFromADCPipe} -tx ${vitisToDACPipe} -txfb ${TxFeedbkAppPipeName} -blocklen ${BlockSize} -fifosize ${IO_FIFO_SIZE}; sleep 5"
    # tmux rename-window -t vitis_cyclopse_demo:3 'dummyAdcDac'
    echo "${dummyAdcDacBuildDir}/dummyAdcDacSharedMemFIFO -cpu ${txCPU} -rx ${vitisFromADCPipe} -tx ${vitisToDACPipe} -txfb ${TxFeedbkAppPipeName} -blocklen ${BlockSize} -fifosize ${IO_FIFO_SIZE}"
else
    # #Start bladeRFToFIFO
    tmux split-window -v -d -t vitis_cyclopse_demo:0.2 "printf '\\033]2;%s\\033\\\\' 'bladeRF'; module load bladeRF; ${bladeRFToFIFOBuildDir}/bladeRFToFIFO -txFreq ${Freq} -rxFreq ${Freq} -txSampRate ${Rate} -rxSampRate ${Rate} -txBW ${BW} -rxBW ${BW} -txGain ${TxGainDB} -rxGain ${RxGainDB} -txCpu ${txCPU} -rxCpu ${rxCPU} -rx ${vitisFromADCPipe} -tx ${vitisToDACPipe} -txfb ${TxFeedbkAppPipeName} -blocklen ${BlockSize} -fifosize ${IO_FIFO_SIZE} -fullScale ${FullScale} -saturate -txSerialNum ${BLADERF_TX_SERIAL} -rxSerialNum ${BLADERF_RX_SERIAL} -txDCOffsetI ${BLADERF_TX_DC_I} -txDCOffsetQ ${BLADERF_TX_DC_Q} -rxDCOffsetI ${BLADERF_RX_DC_I} -rxDCOffsetQ ${BLADERF_RX_DC_Q} -txIQGain ${BLADERF_TX_IQ_GAIN} -txIQPhase ${BLADERF_TX_IQ_PHASE_DEG} -rxIQGain ${BLADERF_RX_IQ_GAIN} -rxIQPhase ${BLADERF_RX_IQ_PHASE_DEG} -v; sleep 100"
    # tmux rename-window -t vitis_cyclopse_demo:3 'bladeRFToFIFO'
    echo "${bladeRFToFIFOBuildDir}/bladeRFToFIFO -txFreq ${Freq} -rxFreq ${Freq} -txSampRate ${Rate} -rxSampRate ${Rate} -txBW ${BW} -rxBW ${BW} -txGain ${TxGainDB} -rxGain ${RxGainDB} -txCpu ${txCPU} -rxCpu ${rxCPU} -rx ${vitisFromADCPipe} -tx ${vitisToDACPipe} -txfb ${TxFeedbkAppPipeName} -blocklen ${BlockSize} -fifosize ${IO_FIFO_SIZE} -fullScale ${FullScale} -saturate -txSerialNum ${BLADERF_TX_SERIAL} -rxSerialNum ${BLADERF_RX_SERIAL} -txDCOffsetI ${BLADERF_TX_DC_I} -txDCOffsetQ ${BLADERF_TX_DC_Q} -rxDCOffsetI ${BLADERF_RX_DC_I} -rxDCOffsetQ ${BLADERF_RX_DC_Q} -txIQGain ${BLADERF_TX_IQ_GAIN} -txIQPhase ${BLADERF_TX_IQ_PHASE_DEG} -rxIQGain ${BLADERF_RX_IQ_GAIN} -rxIQPhase ${BLADERF_RX_IQ_PHASE_DEG} -v"
fi

cd ${curDir}

if [ -z ${TMUX} ]; then
    tmux attach-session -t vitis_cyclopse_demo
else
    echo "Use TMUX to switch to the new session: vitis_cyclopse_demo"
fi
