# cyclopsDemo
Support Files for Cyclops Vitis Demo

# Install
1. Clone Submodules
   ```
   git submodule update --init --recursive
   ```
3. Build Vitis
   ```
   cd submodules/vitis
   mkdir build
   cd build
   cmake ..
   make
   cd ../../..
   ```
2. A build directory with an example design is provided for you.  To create one from scratch, follow: [Creating a Build Directory from Scratch](#creating-a-build-directory-from-scratch)
7. Modify the ```RxSrc``` and ```TxSrc``` entries in the following scripts to match the graphml filenames
    - scripts/runDemo.sh (only if running legacy demo)
    - scripts/runDemoTmux.sh
    - scripts/runDemoTmuxSharedMem.sh
    - scripts/runMultithreadedGen
8. Modify the CPU/partition map in ```runTxMultithreadGen.sh``` and ```runRxMultithreadGen.sh``` based on the target system
    - **Warning**: Make sure that the cores allocated for the DSP are isolated from the OS scheduler using the ```isolcpus``` GRUB parameter.  Failure to do so may result in a system lockup as realtime priority with ```SCHED_FIFO``` is used for the DSP threads which will starve any other processes assigned to run on those CPUs
8. Build the designs using ```./runMultithreadGen```

## Installing Dependencies for Visualization
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

# Running the Demo
1. Execute one of the following:
    - To run with the USRP, use ```./runDemoTmux.sh```
    - To run with the Dummy ADC/DAC, use ```./runDemoTmux.sh 1```
2. Switch to the demo if you are launching from tmux by pressing Ctrl-b + ")"

## Cleanup the Demo
1. Exit the demo using Ctrl-c, Ctrl-c
2. If you were using tmux, reattach to your running session using ```tmux a```
3. Cleanup the demo by running ```./cleanupDemo.sh; ./cleanupDemo.sh```

# Running the Visualizer
The visualizer can be configured by modifying the ```CONFIG_FILE``` and ```TELEM_DIR``` variables in the ```submodules/vitisTelemetryDash/src/backend/runBackend.sh```.  To run the visualizer, first start the demo using the above instructions in: [Running the Demo](#running-the-demo).

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

## Stop the Visualizer
To stop the visualizer, Ctrl-c out of the frontend and then Ctrl-c out of the backend.  It may take multiple Ctrl-c presses before the applications are completely exited.  You can Ctrl-c out of the port forwarding script.

# Appendix
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