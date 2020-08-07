# cyclopsDemo
Support Files for Cyclops Vitis Demo

## Install
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
2. Create build directory
   ```
   mkdir build
   ```
3. Link scrips into build directory
   ```
   cd build
   ln -s ../scripts/* .
   ```
4. Link vitis executables into build directory
   ```
   ln -s ../submodules/vitis/build/simulinkGraphMLImporter .
   ln -s ../submodules/vitis/build/multiThreadedGenerator .
   ```
5. Link Benchmarking Support Files 
   ```
   ln -s ../submodules/benchmarking/common .
   ln -s ../submodules/benchmarking/intrin .
   ln -s ../submodules/benchmarking/depends .
   ```
6. Copy source .graphml files into build (a version will be present there)
7. Modify the ```RxSrc``` and ```TxSrc``` entries in the following scripts to match the graphml filenames
    - scripts/runDemo.sh (only if running legacy demo)
    - scripts/runDemoTmux.sh
    - scripts/runDemoTmuxSharedMem.sh
    - scripts/runMultithreadedGen