#!/bin/bash

# Builds infrastructure for cyclops demo
# Only builds directories if build directory does not exist (with the exception of benchmarking/common which it always tries to build)
# Only builds uhdToPipes if uhd in path

oldDir=$(pwd)

#Get build dir
scriptSrc=$(dirname "${BASH_SOURCE[0]}")
cd $scriptSrc
scriptSrc=$(pwd)
if [[ $(basename $scriptSrc) == scripts ]]; then
    cd ../build
    buildDir=$(pwd)
elif [[ $(basename $scriptSrc) == build ]]; then
    buildDir=$scriptSrc
else
    echo "Error: Unable to determine location of demo build directory"
    cd $oldDir
    exit 1
fi

source $buildDir/setCompilersToUse.sh

if [[ ! -e $buildDir/../submodules/vitis/build ]]; then
    echo "#### Building vitis ####"
    cd $buildDir/../submodules/vitis
    mkdir build
    cd build
    cmake -D CMAKE_C_COMPILER=$CC -D CMAKE_CXX_COMPILER=$CXX ..
    make
fi

# Do not build cyclopsASCIILink.  It requires files generated by laminar/vitis

# if [[ ! -e $buildDir/../submodules/cyclopsASCIILink/build ]]; then
#     echo "#### Building cyclopsASCIILink ####"
#     cd $buildDir/../submodules/cyclopsASCIILink
#     mkdir build
#     cd build
#     cmake -D CMAKE_C_COMPILER=$CC -D CMAKE_CXX_COMPILER=$CXX ..
#     make
# fi

# if [[ buildSharedMem == true ]]; then
#     if [[ ! -e $buildDir/../submodules/cyclopsASCIILink-sharedMem/build ]]; then
#         echo "#### Building cyclopsASCIILink-sharedMem ####"
#         cd $buildDir/../submodules/cyclopsASCIILink-sharedMem
#         mkdir build
#         cd build
#         cmake -D CMAKE_C_COMPILER=$CC -D CMAKE_CXX_COMPILER=$CXX ..
#         make
#     fi
# else
#     echo "**** NOTE: To build shared memory, run script with -a flag ****"
# fi

if [[ ! -e $buildDir/../dummyAdcDac/build ]]; then
    echo "#### Building dummyAdcDac ####"
    cd $buildDir/../dummyAdcDac
    mkdir build
    cd build
    cmake -D CMAKE_C_COMPILER=$CC -D CMAKE_CXX_COMPILER=$CXX ..
    make
fi

if [[ ! -e $buildDir/../dummyAdcDacSharedMemFIFO/build ]]; then
    echo "#### Building dummyAdcDacSharedMemFIFO ####"
    cd $buildDir/../dummyAdcDacSharedMemFIFO
    mkdir build
    cd build
    cmake -D CMAKE_C_COMPILER=$CC -D CMAKE_CXX_COMPILER=$CXX ..
    make
fi

if [[ ! -e $buildDir/../submodules/uhdToPipes/build && ! -z $(which uhd_usrp_probe) ]]; then
    echo "#### Building uhdToPipes ####"
    cd $buildDir/../submodules/uhdToPipes
    mkdir build
    cd build
    cmake -D CMAKE_C_COMPILER=$CC -D CMAKE_CXX_COMPILER=$CXX ..
    make
fi

echo "#### Running make on benchmarking/common ####"
cd $buildDir/../submodules/benchmarking/common
echo "make CC=$CC CXX=$CXX USE_PCM=0 USE_AMDuPROF=0"
make CC=$CC CXX=$CXX USE_PCM=0 USE_AMDuPROF=0

cd $oldDir