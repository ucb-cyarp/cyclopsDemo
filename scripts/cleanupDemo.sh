#!/bin/bash
# using https://stackoverflow.com/questions/1908610/how-to-get-pid-of-background-process

curDir=`pwd`

pkill -f uhdToPipes
pkill -f benchmark_tx_demo_io_linux_pipe
pkill -f benchmark_rx_demo_io_linux_pipe
pkill -f cyclopsASCIILink

cd demoRun
rm *.pipe
cd rx
rm *.pipe
cd ../tx
rm *.pipe

cd ${curDir}