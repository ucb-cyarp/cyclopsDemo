#!/bin/bash

./simulinkGraphMLImporter ../test/stimulus/simulink/radio/$1.graphml $1_vitis.graphml
OUT_DIR=cOut_$1
mkdir ${OUT_DIR}
./multiThreadedGenerator $1_vitis.graphml ./${OUT_DIR} rx_demo --emitGraphMLSched --schedHeur DFS --blockSize 100 --fifoLength 7 --partitionMap [4,4,5,20,21]
cd ${OUT_DIR}
cp -r ../infra/common .
cp -r ../infra/depends .
cp -r ../infra/intrin .
make -f Makefile_rx_demo_io_linux_pipe.mk USE_PCM=0 USE_AMDuPROF=0
