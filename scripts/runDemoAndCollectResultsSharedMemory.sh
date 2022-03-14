#!/bin/bash

# Run an already generated/compiled demo, wait a specified amount of time, then collect results

timeToWait="3m"

tgtDir=$1
#Error check
if [[ -z $tgtDir ]]; then
    echo "Please supply target dir"
    exit 1
fi

./runDemoTmuxSharedMem.sh 1

echo "Letting run for $timeToWait"
sleep $timeToWait

#With help from https://stackoverflow.com/questions/29439835/find-tmux-session-that-a-pid-belongs-to
tmuxPIDs=($(tmux list-panes -t vitis_cyclops_demo_inst2 -F '#{pane_pid}'))
tmuxPIDsCommaSep=$(echo "${tmuxPIDs[*]}" | sed -e 's/ /,/g')

./suspendDemo.sh ${tmuxPIDsCommaSep}

sleep 1s

#Collect results first

./collectRunResults.sh $tgtDir

#Then cleanup to avoid issues with log files potentially being zero-ed out after process killed

./cleanupDemoSharedMem.sh ${tmuxPIDsCommaSep}