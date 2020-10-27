#!/bin/bash

# Copies run results to the requested directory
# Also timestamps the result (from the time this script is run)
# and copies the binaries and src used to create them.
# Also collects git information from the demo repository and submodules

# Using help from https://www.linkedin.com/learning/learning-bash-scripting
# https://stackoverflow.com/questions/638975/how-do-i-tell-if-a-regular-file-does-not-exist-in-bash
# https://stackoverflow.com/questions/59895/how-to-get-the-source-directory-of-a-bash-script-from-within-the-script-itself
# https://stackoverflow.com/questions/35006457/choosing-between-0-and-bash-source
# https://stackoverflow.com/questions/9405478/command-substitution-backticks-or-dollar-sign-paren-enclosed
# https://superuser.com/questions/112078/delete-matching-files-in-all-subdirectories
# https://unix.stackexchange.com/questions/16640/how-can-i-get-the-size-of-a-file-in-a-bash-script

timestamp=$(date)

runDirName="demoRun"
generatedDirNames=( "cOut_rev1BB_receiver" "cOut_rev1BB_transmitter" )
buildScriptName="runMultithreadGen.sh"
demoRepoName="cyclopsDemo"
compilerInfoName="compilerInfo.txt"
buildLogName="buildLog.log"

tgtDir=$1
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
    echo "Error: Unable to determine location of results to copy"
    cd $oldDir
    exit 1
fi

cd $oldDir

#Error check
if [[ -z $tgtDir ]]; then
    echo "Please supply target dir"
    exit 1
fi

if [[ -e  $1 ]]; then
    echo "Error: $1 already exists"
    exit 1
fi

echo "Saving Cyclops Demo Results from $buildDir to $tgtDir ..."

mkdir $tgtDir
cd $tgtDir
tgtDirFullPath=$(pwd)

#Get Machine Info
echo "Collecting Machine Info"
echo "Timestamp: $timestamp" > info.txt
echo "Hostname: $(hostname)" >> info.txt
echo "uname: $(uname -a)" >> info.txt
cat info.txt
echo

#Get Compilers used (if available)
if [[ -e $buildDir/$compilerInfoName ]]; then
    echo "Copying Compiler Info"
    cp $buildDir/$compilerInfoName .
else
    echo "Warning: Compiler Info Not Available"
fi

#Get Build Log (if available)
if [[ -e $buildDir/$buildLogName ]]; then
    echo "Copying Build Log"
    cp $buildDir/$buildLogName .
else
    echo "Warning: Build Log Not Available"
fi

#Copy GraphML Files
mkdir graphML
echo "Copying GraphML Files"
cp $buildDir/*.graphml ./graphML/.

#Copy Run Results
echo "Copying Run Results"
cp -r $buildDir/$runDirName results

#Remove pipes from results
filesInResults=$(find results)
for f in $filesInResults
do
    if [[ -p "$f" ]]; then
        echo "    Removed Named Pipe from Results: $f"
        rm $f
    fi
done

#Check results for empty log
filesInResults=$(find results)
for f in $filesInResults
do
    size=$(stat --printf="%s" $f)
    if [[ size -eq 0 ]]; then
        echo "    WARNING: Log file with no contents: $f"
    fi
done

#Copy Src Files
echo "Copying Src Files (without Symlinks to Common Files)"
mkdir genSrc
for genDirName in ${generatedDirNames[@]}
do
    echo "    Copying $genDirName"
    cp -r --no-dereference $buildDir/$genDirName ./genSrc/.

    #Remove links from src
    filesInSrc=$(find ./genSrc/$genDirName)
    for f in $filesInSrc
    do
        if [[ -L "$f" ]]; then
            echo "    Removed Symlink from src: $f"
            rm $f
        fi
    done
done

#Copy Scripts
echo "Copying Script Files (Used to Generate/Run Demo)"
cp -r $buildDir/../scripts .

echo "Collecting git information ..."

#Get git Info
mkdir git
cd git
gitReportDir=$(pwd)

echo "    Collecting $demoRepoName git information"
mkdir $demoRepoName
cd $buildDir
git log -1 > $gitReportDir/$demoRepoName/gitLastCommitDetailed.txt
git log -1 --format="%H"  > $gitReportDir/$demoRepoName/gitLastCommit.txt
git status -b > $gitReportDir/$demoRepoName/gitStatus.txt
git diff > $gitReportDir/$demoRepoName/gitDiff.patch

submodules=$(ls $buildDir/../submodules)
for submodule in $submodules
do
    echo "    Collecting submodule $submodule git information"
    cd $gitReportDir
    mkdir $submodule
    cd $buildDir/../submodules/$submodule
    git log -1 > $gitReportDir/$submodule/gitLastCommitDetailed.txt
    git log -1 --format="%H"  > $gitReportDir/$submodule/gitLastCommit.txt
    git status -b > $gitReportDir/$submodule/gitStatus.txt
    git diff > $gitReportDir/$submodule/gitDiff.patch
done

cd $oldDir

echo "Compressing results into ${tgtDir}.tar.gz"

tar -cf ${tgtDir}.tar.gz ${tgtDir}