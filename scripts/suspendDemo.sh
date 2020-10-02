#!/bin/bash

#Try suspending demo processes
pkill -f benchmark_tx_demo_io_linux_pipe --signal SIGTSTP
pkill -f benchmark_rx_demo_io_linux_pipe --signal SIGTSTP
pkill -f uhdToPipes --signal SIGTSTP
pkill -f cyclopsASCIILink --signal SIGTSTP
pkill -f dummyAdcDac --signal SIGTSTP