#!/bin/bash

buildLogName="buildLog.log"

echo "++++ Clean Infrastructure: ++++"
./cleanBuild.sh

echo "++++ Build Infrastructure: ++++"
echo "++++ Build Infrastructure: ++++" >> $buildLogName
./buildInfrastructure.sh | tee -a $buildLogName

echo >> $buildLogName
echo "++++ Build Demo: ++++"
echo "++++ Build Demo: ++++" >> $buildLogName
./runMultithreadGen.sh | tee -a $buildLogName
