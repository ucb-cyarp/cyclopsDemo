#!/bin/bash

# Run an already generated/compiled demo, wait a specified amount of time, then collect results

timeToWait="3m"

tgtDir=$1
#Error check
if [[ -z $tgtDir ]]; then
    echo "Please supply target dir"
    exit 1
fi

./runDemoTmux.sh 1

echo "Letting run for $timeToWait"
sleep $timeToWait

./suspendDemo.sh

sleep 1s

#Collect results first

./collectRunResults.sh $tgtDir

#Then cleanup to avoid issues with log files potentially being zero-ed out after process killed

./cleanupDemo.sh