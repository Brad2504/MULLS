ARG UBUNTU_VERSION=20.04
FROM ubuntu:${UBUNTU_VERSION} AS prereqs

RUN apt-get update && apt-get install -y checkinstall

RUN apt-get update && \
      DEBIAN_FRONTEND=noninteractive apt-get -y install sudo python3-pip apt-utils build-essential git wget checkinstall \
          protobuf-compiler libprotobuf-dev libgoogle-glog-dev libgflags-dev \
          libeigen3-dev libboost-thread-dev libpcl-dev libproj-dev libatlas-base-dev libsuitesparse-dev \
          libgeotiff-dev libopencv-dev libhdf5-serial-dev libopenmpi-dev openmpi-bin libhdf5-openmpi-dev

RUN useradd -m docker && echo "docker:docker" | chpasswd && adduser docker sudo

WORKDIR /mulls

# install newest cmake
RUN apt-get install -y apt-transport-https ca-certificates gnupg software-properties-common wget && \
    wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | gpg --dearmor - | tee /etc/apt/trusted.gpg.d/kitware.gpg >/dev/null && \
    apt-add-repository "deb https://apt.kitware.com/ubuntu/ $(lsb_release -cs) main" && \
    apt-get update && \
    apt-get install -y cmake cmake-curses-gui

# install newest clang
RUN wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add - && \
    apt-add-repository "deb http://apt.llvm.org/$(lsb_release -cs)/ llvm-toolchain-$(lsb_release -cs) main" && \
    apt-get update && \
    apt-get install -y clang

# install newer Eigen for TEASER++ and others
# Install required tools and dependencies
RUN apt-get update && apt-get install -y \
    wget \
    cmake \
    build-essential \
    git \
    libomp-dev \
    && rm -rf /var/lib/apt/lists/*

# Download and install Eigen 3.4.0 from the official source
RUN wget https://gitlab.com/libeigen/eigen/-/archive/3.4.0/eigen-3.4.0.tar.bz2 && \
    tar -xjf eigen-3.4.0.tar.bz2 && \
    cd eigen-3.4.0 && \
    mkdir build && cd build && \
    cmake .. && \
    make -j $(nproc) && \
    make install && \
    cd / && \
    rm -rf eigen-3.4.0.tar.bz2 eigen-3.4.0


RUN if [ $(lsb_release -cs) = xenial ]; then \
        python3 -m pip install pip==20.3.4; \
    else \
        python3 -m pip install --upgrade pip; \
    fi
RUN pip install pyyaml
ADD script/tools/install_dep_lib.sh script/tools/install_dep_lib.sh
ADD python/requirements.txt python/requirements.txt

ARG NPROC=""

RUN DEBIAN_FRONTEND=noninteractive NPROC=${NPROC} bash script/tools/install_dep_lib.sh

FROM prereqs

ADD . .
RUN rm -f /etc/apt/sources.list.d/kitware.list
RUN sed -i '/kitware/d' /etc/apt/sources.list
RUN rm -rf /var/lib/apt/lists/*

RUN apt update
RUN apt upgrade -y
RUN apt-get install -y libomp-dev
RUN apt-get install -y g++
RUN git clone --recursive https://github.com/fmtlib/format-benchmark.git
RUN cd format-benchmark
RUN cmake .
RUN cd ..
RUN cd /mulls
RUN apt-get install libmetis-dev
ARG CXX_COMPILER=clang++
RUN rm -rf build && \
    mkdir build && \
    cd build && \
    cmake .. && \
    cd .. && \
    make
RUN apt-get install -y xvfb

RUN sudo sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list'
RUN apt install curl
RUN curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | sudo apt-key add -
RUN apt-get update
RUN apt-get install -y ros-noetic-desktop-full
RUN echo "source /opt/ros/noetic/setup.bash" >> ~/.bashrc
SHELL ["/bin/bash", "-c"]
RUN source ~/.bashrc 
RUN apt install -y python3-rosdep python3-rosinstall python3-rosinstall-generator python3-wstool build-essential
RUN apt install python3-rosdep
RUN rosdep init
RUN rosdep update

RUN sed -i 's/real_time_viewer_on=1/real_time_viewer_on=0/g' script/run_mulls_slam.sh
# ENTRYPOINT ["/usr/bin/xvfb-run", "-a", "-s", "-screen 0 1024x768x24"]
CMD [ "/bin/bash" ]
# CMD [ "script/run_mulls_slam.sh" ]

# /usr/bin/xvfb-run -a -s '-screen 0 1024x768x24' script/run_mulls_slam.sh
