#!/bin/bash

oldDir=$(pwd)

#Get build dir
scriptSrc=$(dirname "${BASH_SOURCE[0]}")
cd $scriptSrc
scriptSrc=$(pwd)
if [[ $(basename $scriptSrc) == Docker ]]; then
    cd ..
    projectDir=$(pwd)
else
    echo "Error: Unable to determine location of project directory"
    cd $oldDir
    exit 1
fi

cd ${projectDir}/Docker

timestamp=$(date +%F_%H-%M-%S)

## Need to run this one directory up
# docker build --progress plain -f ./Dockerfile -t cyclops_demo_local:${timestamp} --no-cache .. 2>&1 | tee dockerBuild.log
docker build --progress plain -f ./Dockerfile -t cyclops_demo_local:${timestamp} .. 2>&1 | tee dockerBuild.log
docker tag cyclops_demo_local:${timestamp} cyclops_demo_local:latest

echo "${timestamp}" > lastBuiltTag.log

cd ${oldDir}