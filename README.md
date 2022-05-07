# cyclopsDemo
Support Files for Cyclops Laminar Demo


 - [Install (Automatic)](#install-automatic)
 - [Installing Dependencies for Visualization](#installing-dependencies-for-visualization)
 - [Running the Demo (Interactive)](#running-the-demo-interactive)
   - [Cleanup the Demo (Interactive)](#cleanup-the-demo-interactive)
   - [Collect Results (Interactive)](#collect-results-interactive)
 - [Running the Visualizer (Interactive)](#running-the-visualizer-interactive)
   - [Port Forwarding Dashboard](#port-forwarding-dashboard)
   - [Viewing the Dashboard](#viewing-the-dashboard)
   - [Stoping the Visualizer](#stoping-the-visualizer)
 - [Running the Demo and Collecting Results (Unattended)](#running-the-demo-and-collecting-results-unattended)
 - [Running Unattended Benchmark](#running-unattended-benchmark)
 - [Docker](#docker)
 - [Appendix](#appendix)
   - [Install (Manual)](#install-manual)
   - [Creating a Build Directory from Scratch](#creating-a-build-directory-from-scratch)
 - [Citing This Software](#citing-this-software)

# Install (Automatic)
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
   
---
**NOTE**

When using Zenodo archives, sumbmodules are not included in the archive.  Please use the Single Instance versions of cyclopsASCIILink: [10.5281/zenodo.6526107](https://doi.org/10.5281/zenodo.6526107)

---


Note that vitis will only be built if it has not already been built.  It will also be built with the compilers specified in `scripts/setCompilersToUse.sh`.  To re-build vitis, run:
```
./cleanBuild.sh -a
./buildInfrastructure.sh -a
./cleanBuild.sh
```

You can then run `build.sh` again to record the build log for the rest of the infrastructure.

# Installing Dependencies for Visualization
If you are planning on using the web based telemetry visualizer, you will need to install some dependencies.
1. Install python3 and pip.  On Ubuntu run:
   ```
   sudo apt install python3 python3-pip
   ```
2. Install Ploty Dash dependencies
   ```
   cd submodules/vitisTelemetryDash
   pip3 install -r requirements.txt
   ```

# Running the Demo (Interactive)
1. Execute one of the following:
    - To run with the USRP, use ```./runDemoTmuxSharedMem.sh```
    - To run with the Dummy ADC/DAC, use ```./runDemoTmuxSharedMem.sh```
2. Switch to the demo if you are launching from tmux by pressing Ctrl-b + ")"

## Cleanup the Demo (Interactive)
1. Exit the demo using Ctrl-c, Ctrl-c
2. If you were using tmux, reattach to your running session using ```tmux a```
3. Cleanup the demo by running ```./cleanupDemoSharedMem.sh; ./cleanupDemoSharedMem.sh```

## Collect Results (Interactive)
It is advised for you to cleanup the interactive demo using the steps in [Cleanup the Demo (Interactive)](#cleanup-the-demo-interactive) before collecting results.

To collect the results of the interactive run, use:
```
./collectRunResults.sh <reportName>
```
Replace `<reportName>` with the name of a directory/tar.gz file to store the results in.

# Running the Visualizer (Interactive)
The visualizer can be configured by modifying the ```CONFIG_FILE``` and ```TELEM_DIR``` variables in the ```submodules/vitisTelemetryDash/src/backend/runBackend.sh```.  To run the visualizer, first start the demo using the above instructions in: [Running the Demo (Interactive)](#running-the-demo-interactive).

Then run the following commands in separate consoles or tmux panes:
1. Start the visualizer backend
   ```
   cd submodules/vitisTelemetryDash/src/backend
   ./runBackend.sh
   ```
2. Start the visualizer frontend
   ```
   cd submodules/vitisTelemetryDash/src/frontend
   python3 vitisTelemetryDash.py
   ```

## Port Forwarding Dashboard
A courtesy script is supplied to help with SSH port forwarding if the server is inaccessible.  It is located at ```submodules/vitisTelemetryDash/scrips/forwardDashboardSSH.sh```.  This should be run on the computer accessing the dashboard and the first argument should be the hostname of the server hosting the dashboard.  For example:
```
./forwardDashboardSSH.sh myDashboardServer.eecs.berkeley.edu
```

## Viewing the Dashboard
To view the dashboard, open [http://127.0.0.1:8000](http://127.0.0.1:8000) on your local system after port forwarding has been set up.

## Stoping the Visualizer
To stop the visualizer, Ctrl-c out of the frontend and then Ctrl-c out of the backend.  It may take multiple Ctrl-c presses before the applications are completely exited.  You can Ctrl-c out of the port forwarding script.

# Running the Demo and Collecting Results (Unattended)
To run a demo for a specified amount of time, cleanup the demo, and collect the results, use:
```
./runDemoAndCollectResults.sh <reportName>
```
Replace `<reportName>` with the name of a directory/tar.gz file to store the results in.

To change the amount of time the demo is allowed to run, modify the variable in `./runDemoAndCollectResults.sh`.

# Running Unattended Benchmark
The suggested procedure for running the benchmarks on multi-core platforms:
1. Make any modifications to the cyclopsDemo src that you would like to test.  If modifying vitis, make sure to re-build it before proceeding.
2. Build the demo binaries
   ```
   cd cyclopsDemo/build
   ./build.sh
   ```
3. Reboot the system to bring it back to a known clean state
4. Setup the platform (platform scripts assumed to be in `~/git/platformScripts`) and run the demo.  Replace path names with ones appropriate for your test
   ```
   cd ~/git/platformScripts; sudo ./setup.sh; cd ~/git/cyclopsDemo/build; ./runDemoAndCollectResultsSharedMemory.sh results/cyclopsDemoResults
   ```
5. Results will be collected after 3 min and stored in the provided path

# Docker
If you do not have a dedicated multi-core machine to try the demo on but would like to see the demo functioning, running a Docker container may be a good option for you.  *Note that some of the optimizations such as thread pinning are omitted when targeting a docker container.*  The procedure below details how to build a docker container with the demo and run it.

**Note: On systems with relativly few cores, the demo will run quite slowly.  This is partially because the Laminar generated DSP code polls on FIFOs and does not notify the OS that it is waiting.  This results in sub-optimal workload scheduling by the OS.**  Performance on a 12 Core AMD Ryzen 5900X with SMT enabled and Windows as the host OS yeilded impressive results but is still slower than what is possible with a dedicated many-core machine.

## Building
To build the containr, first make sure that all sub-modules have been cloned appropriatly by running `git submodule update --init`
Then, cd into the `cyclopsDemo/Docker` directory and run `./buildContainer.sh`.  This will build a timestamped docker image named `cyclops_demo_local` and will set the `cyclops_demo_local:latest` tag to the newly created image.

## Running
To run the demo, cd into the `cyclopsDemo/Docker` directory and run `runContainer.sh`.  This will run the demo including the telemetry dashboard. Port forwarding for the telemetry will be setup to port 8000 on the host system.  Direct your web browser to [http://127.0.0.1:8000](http://127.0.0.1:8000) while the demo is running to view the dashboard.

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

# Citing This Software:
If you would like to reference this software, please cite Christopher Yarp's Ph.D. thesis.

*At the time of writing, the GitHub CFF parser does not properly generate thesis citations.  Please see the bibtex entry below.*

```bibtex
@phdthesis{yarp_phd_2022,
	title = {High Speed Software Radio on General Purpose CPUs},
	school = {University of California, Berkeley},
	author = {Yarp, Christopher},
	year = {2022},
}
```
