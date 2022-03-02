FROM ubuntu:20.04

ARG DEBIAN_FRONTEND="noninteractive"
ENV TZ="America/Los_Angeles"

##Install Basic Dependencies
#Laminar/Vitis
RUN apt-get update && apt-get install --no-install-recommends -y build-essential \
                                         git \
                                         cmake \
                                         sudo \
                                         clang-12 \
                                         libboost-all-dev \
                                         libxerces-c-dev \
                                         graphviz \
                                         papi-tools \
                                         libpapi-dev \
                                         libpfm4-dev \
#For Demo
                                         tmux \
#Used to install doxygen from apt but need a more modern version (see below) so I compile from src
#Telemetry Dash
                                         python3 \
                                         python3-pip \                                   
#UHD
#                                         python \
#                                         python-pip \
                                         libuhd-dev \
#BladeRF
                                         libusb-1.0-0-dev \
                                         libusb-1.0-0 \
                                         build-essential \
                                         cmake \
                                         libncurses5-dev \
                                         libtecla1 \
                                         libtecla-dev \
                                         pkg-config \
                                         git \
                                         wget \
                                         help2man \
                                         pandoc\
#Doxygen build dependencies
                                         flex \
                                         bison \
#General Utils
                                         htop; \
#Clean APT
apt-get clean

#Install Doxygen from Repo
#Install more modern doxygen 1.9.2 due to a regression in grouped classes (https://github.com/doxygen/doxygen/issues/7772)
RUN cd /tmp && \
    mkdir doxygen && \
    git clone https://github.com/doxygen/doxygen.git && \
    cd doxygen && \
    git checkout Release_1_9_2 && \
    mkdir build && \
    cd build && \
    cmake -G "Unix Makefiles" .. && \
    make && \
    make install && \
    #Cleanup Doxygen Build Dir
    cd /tmp && \
    rm -rf doxygen

#Install libbladeRF from repo
ENV LIBBLADERFCOMMIT="43a559dd5ed77df94bef9e28c1f45126c4d051a5"
RUN cd /tmp && \
    git clone https://github.com/Nuand/bladeRF.git ./bladeRF && \
    cd bladeRF && \
    git checkout "$LIBBLADERFCOMMIT" && \
    cd host && \
    mkdir build && \
    cd build && \
    cmake -DCMAKE_BUILD_TYPE=Release -DINSTALL_UDEV_RULES=ON ../ && \
    make && \
    make install && \
    #Cleanup libbladeRF Build Dir
    cd /tmp && \
    rm -rf bladeRF

#Install Python Dependencies
RUN mkdir /tmp/pythonRequirements
WORKDIR /tmp/pythonRequirements
COPY ./submodules/vitisTelemetryDash/requirements.txt .
RUN pip3 install -r requirements.txt

WORKDIR /tmp
RUN rm -r /tmp/pythonRequirements

##Copy Repo
#NOTE: This script must be run one directory up
RUN mkdir /tmp/cyclopsDemo
COPY . /tmp/cyclopsDemo

##Build Demo
#Tell build that this is a docker target and to not pin threads
ENV BUILD_ENV=DOCKER
WORKDIR /tmp/cyclopsDemo/build
#Change compiler to be clang-12
RUN sed -i 's/clang/clang-12/g' /tmp/cyclopsDemo/scripts/setCompilersToUse.sh && sed -i 's/clang-12++/clang++-12/g' /tmp/cyclopsDemo/scripts/setCompilersToUse.sh
#Change telemetry dashboard bind address to be 0.0.0.0 (from default 127.0.0.1) due to the way docker handles port forwarding - need to listen for contections not from localhost.  
#See: https://stackoverflow.com/questions/39525820/docker-port-forwarding-not-working
RUN sed -i 's/127.0.0.1/0.0.0.0/g' /tmp/cyclopsDemo/submodules/vitisTelemetryDash/src/frontend/vitisTelemetryDash.py

RUN ./build.sh

##Default command, run with 
CMD ./runDemoTmuxSharedMem.sh 2