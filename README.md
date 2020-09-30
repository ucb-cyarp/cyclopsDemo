# cyclopsDemo
Support Files for Cyclops Vitis Demo

 - [Install (Automatic)](#install-automatic)
 - [Running the Demo (Interactive)](#running-the-demo-interactive)
 - [Cleanup the Demo (Interactive)](#cleanup-the-demo-interactive)
 - [Collect Results (Interactive)](#collect-results-interactive)
 - [Running the Demo and Collecting Results (Unattended)](#running-the-demo-and-collecting-results-unattended)
 - [Appendix](#appendix)
   - [Install (Manual)](#install-manual)
   - [Creating a Build Directory from Scratch](#creating-a-build-directory-from-scratch)

## Install (Automatic)
There is now a semi-automated way to build the demo and associated infrastructure if you are using the provided files in the `build` directory.  For information on performing these steps manually, see [Install (Manual)](#install-manual)
1. Clone Submodules
   ```
   git submodule update --init --recursive
   ```
2. Set compilers to be used in build by modifying `scripts/setCompilersToUse.sh`
3. Run the build script
   ```
   cd build
   ./build.sh
   ```

Note that vitis will only be built if it has not already been built.  It will also be built with the compilers specified in `scripts/setCompilersToUse.sh`.  To re-build vitis, run:
```
./cleanBuild.sh -a
./buildInfrastructure.sh -a
./cleanBuild.sh
```

You can then run `build.sh` again to record the build log for the rest of the infrastructure.

## Running the Demo (Interactive)
1. Execute one of the following:
    - To run with the USRP, use ```./runDemoTmux.sh```
    - To run with the Dummy ADC/DAC, use ```./runDemoTmux.sh```
2. Switch to the demo if you are launching from tmux by pressing Ctrl-b + ")"

## Cleanup the Demo (Interactive)
1. Exit the demo using Ctrl-c, Ctrl-c
2. If you were using tmux, reattach to your running session using ```tmux a```
3. Cleanup the demo by running ```./cleanupDemo.sh; ./cleanupDemo.sh```

## Collect Results (Interactive)
It is advised for you to cleanup the interactive demo using the steps in [Cleanup the Demo (Interactive)](#cleanup-the-demo-interactive) before collecting results.

To collect the results of the interactive run, use:
```
./collectRunResults.sh <reportName>
```
Replace `<reportName>` with the name of a directory/tar.gz file to store the results in.

## Running the Demo and Collecting Results (Unattended)
To run a demo for a specified amount of time, cleanup the demo, and collect the results, use:
```
./runDemoAndCollectResults.sh <reportName>
```
Replace `<reportName>` with the name of a directory/tar.gz file to store the results in.

To change the amount of time the demo is allowed to run, modify the variable in `./runDemoAndCollectResults.sh`.

# Appendix
## Install (Manual)
1. Clone Submodules
   ```
   git submodule update --init --recursive
   ```
2. Build Vitis
   ```
   cd submodules/vitis
   mkdir build
   cd build
   cmake ..
   make
   cd ../../..
   ```
3. A build directory with an example design is provided for you.  To create one from scratch, follow: [Creating a Build Directory from Scratch](#creating-a-build-directory-from-scratch)
4. Modify the ```RxSrc``` and ```TxSrc``` entries in the following scripts to match the graphml filenames
    - scripts/runDemo.sh (only if running legacy demo)
    - scripts/runDemoTmux.sh
    - scripts/runDemoTmuxSharedMem.sh
    - scripts/runMultithreadedGen
5. Modify the CPU/partition map in ```runTxMultithreadGen.sh``` and ```runRxMultithreadGen.sh``` based on the target system
    - **Warning**: Make sure that the cores allocated for the DSP are isolated from the OS scheduler using the ```isolcpus``` GRUB parameter.  Failure to do so may result in a system lockup as realtime priority with ```SCHED_FIFO``` is used for the DSP threads which will starve any other processes assigned to run on those CPUs
8. Build the designs using ```./runMultithreadGen```

## Creating a Build Directory from Scratch
A build directory with an example design is provided for you.  To create one from scratch, follow the directions below:
1. Create build directory
   ```
   mkdir build
   ```
2. Link scrips into build directory
   ```
   cd build
   ln -s ../scripts/* .
   ```
3. Link vitis executables into build directory
   ```
   ln -s ../submodules/vitis/build/simulinkGraphMLImporter .
   ln -s ../submodules/vitis/build/multiThreadedGenerator .
   ```
4. Link Benchmarking Support Files 
   ```
   ln -s ../submodules/benchmarking/common .
   ln -s ../submodules/benchmarking/intrin .
   ln -s ../submodules/benchmarking/depends .
   ```
6. Copy source .graphml files into build