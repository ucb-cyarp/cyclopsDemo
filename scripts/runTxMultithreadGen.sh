#!/bin/bash

./simulinkGraphMLImporter ../test/stimulus/simulink/radio/$1.graphml $1_vitis.graphml
OUT_DIR=cOut_$1
mkdir ${OUT_DIR}
./multiThreadedGenerator $1_vitis.graphml ./${OUT_DIR} tx_demo --emitGraphMLSched --schedHeur DFS --blockSize 16 --fifoLength 7 --partitionMap [8,8,9,24,25]
cd ${OUT_DIR}
cp -r ../infra/common .
cp -r ../infra/depends .
cp -r ../infra/intrin .
make -f Makefile_tx_demo_io_linux_pipe.mk USE_PCM=0 USE_AMDuPROF=0
