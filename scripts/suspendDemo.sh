#!/bin/bash

#Try suspending demo processes
#pkill -f benchmark_tx_demo_io_linux_pipe --signal SIGTSTP
#pkill -f benchmark_rx_demo_io_linux_pipe --signal SIGTSTP
#pkill -f benchmark_tx_demo_io_posix_shared_mem --signal SIGTSTP
#pkill -f benchmark_rx_demo_io_posix_shared_mem --signal SIGTSTP
#pkill -f uhdToPipes --signal SIGTSTP
#pkill -f cyclopsASCIILink --signal SIGTSTP
#pkill -f dummyAdcDac --signal SIGTSTP
#pkill -f dummyAdcDacSharedMemFIFO --signal SIGTSTP

pkill -f benchmark_tx_demo_io_linux_pipe --signal SIGSTOP
pkill -f benchmark_rx_demo_io_linux_pipe --signal SIGSTOP
pkill -f benchmark_tx_demo_io_posix_shared_mem --signal SIGSTOP
pkill -f benchmark_rx_demo_io_posix_shared_mem --signal SIGSTOP
pkill -f uhdToPipes --signal SIGSTOP
pkill -f cyclopsASCIILink --signal SIGSTOP
pkill -f dummyAdcDac --signal SIGSTOP
pkill -f dummyAdcDacSharedMemFIFO --signal SIGSTOP
