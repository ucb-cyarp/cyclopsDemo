#!/bin/bash

# Cleans the infrastructure built by runGen.sh

generatedDirNames=( "cOut_rev1BB_receiver" "cOut_rev1BB_transmitter" )
runDirName="demoRun"
compilerInfoName="compilerInfo.txt"
buildLogName="buildLog.log"

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

cleanVitis=false
while getopts ::a option; do
    case $option in
        a) cleanVitis=true;;
        ?) echo "Unknown option: $option"; exit 1;;
    esac
done

#Remove Generated Dirs
for genDirName in ${generatedDirNames[@]}
do
    if [[ -e $buildDir/$genDirName ]]; then
        echo "Removed $genDirName"
        rm -r $buildDir/$genDirName
    fi
done

#Remove runDir
if [[ -e $buildDir/$runDirName ]]; then
    echo "Removed $runDirName"
    rm -r $buildDir/$runDirName
fi

#Remove old build log and compiler info
if [[ -e $buildDir/$compilerInfoName ]]; then
    echo "Removed $compilerInfoName"
    rm -r $buildDir/$compilerInfoName
fi

if [[ -e $buildDir/$buildLogName ]]; then
    echo "Removed $buildLogName"
    rm -r $buildDir/$buildLogName
fi

#Clean benchmarking
echo "Cleaning benchmarking/common"
cd $buildDir/../submodules/benchmarking/common
make clean

if [[ -e $buildDir/../submodules/cyclopsASCIILink/build ]]; then
    echo "Removed cyclopsASCIILink/build"
    rm -r $buildDir/../submodules/cyclopsASCIILink/build
fi

if [[ -e $buildDir/../submodules/cyclopsASCIILink-sharedMem/build ]]; then
    echo "Removed cyclopsASCIILink-sharedMem/build"
    rm -r $buildDir/../submodules/cyclopsASCIILink-sharedMem/build
fi

if [[ -e $buildDir/../dummyAdcDac/build ]]; then
    echo "Removed dummyAdcDac/build"
    rm -r $buildDir/../dummyAdcDac/build
fi

if [[ -e $buildDir/../dummyAdcDacSharedMemFIFO/build ]]; then
    echo "Removed dummyAdcDacSharedMemFIFO/build"
    rm -r $buildDir/../dummyAdcDacSharedMemFIFO/build
fi

if [[ -e $buildDir/../submodules/uhdToPipes/build ]]; then
    echo "Removed uhdToPipes/build"
    rm -r $buildDir/../submodules/uhdToPipes/build
fi

if [[ -e $buildDir/../sharedMemFIFOBench/build ]]; then
    echo "Removed sharedMemFIFOBench/build"
    rm -r $buildDir/../sharedMemFIFOBench/build
fi

if [[ $cleanVitis == true ]]; then
    if [[ -e $buildDir/../submodules/vitis/build ]]; then
        echo "Removed vitis/build"
        rm -rf $buildDir/../submodules/vitis/build
    fi
else
    echo "**** NOTE: To clean vitis, run script with -a flag ****"
fi

cd $oldDir