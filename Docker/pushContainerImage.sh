#!/bin/bash

#NOTE: Replace USERNAME/cyclops_demo with Dockerhub repo name
dockerRepoName=USERNAME/cyclops_demo

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

cd $scriptSrc 

if [[ -f lastBuiltTag.log ]]; then
    tag=$(cat lastBuiltTag.log)
    if [[ ! -z ${tag} ]]; then
        echo "docker tag cyclops_demo_local:${tag} ${dockerRepoName}:${tag}"
        docker tag "cyclops_demo_local:${tag}" "${dockerRepoName}:${tag}"
    fi
fi

echo "docker tag cyclops_demo_local:latest ${dockerRepoName}:latest"
docker tag "cyclops_demo_local:latest" "${dockerRepoName}:latest"

echo "docker push -a ${dockerRepoName}"
docker push -a ${dockerRepoName}

cd ${oldDir}