#!/bin/bash

# Run an already generated/compiled demo, wait a specified amount of time, then collect results

timeToWait="3m"

inst1Dir=cyclopsDemo-instance1/build
inst2Dir=cyclopsDemo-instance2/build

if [[ !( -d "$inst1Dir" ) || !( -d "$inst2Dir" ) ]]; then
    echo "Please run this script 1 diretory above $inst1Dir and $inst2Dir"
    exit 1
fi

tgtDir=$1
#Error check
if [[ -z $tgtDir ]]; then
    echo "Please supply target dir"
    exit 1
fi

topDir=`pwd`

if [[ -d "$topDir/$tgtDir" ]]; then
    echo "$topDir/$tgtDir already exists"
    exit 1
else 
    mkdir "$tgtDir"
fi

cd "$topDir/$inst1Dir"
./runDemoTmuxSharedMem.sh 1
cd "$topDir/$inst2Dir"
./runDemoTmuxSharedMem.sh 1

cd "$topDir"
echo "Letting run for $timeToWait"
sleep $timeToWait

cd "$topDir/$inst1Dir"
./suspendDemo.sh # Suspends both demos since the executables have the same name

sleep 1s

#Collect results first
./collectRunResults.sh "$topDir/$tgtDir/inst1"
cd "$topDir/$inst2Dir"
./collectRunResults.sh "$topDir/$tgtDir/inst2"

#Then cleanup to avoid issues with log files potentially being zero-ed out after process killed
cd "$topDir/$inst1Dir"
./cleanupDemoSharedMem.sh
cd "$topDir/$inst2Dir"
./cleanupDemoSharedMem.sh

cd "$topDir"