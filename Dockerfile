
FROM ubuntu:latest

# Get up to date for jammy
RUN apt update
RUN apt upgrade -y

# Build deps
RUN apt install -y git bc bison flex libssl-dev make libc6-dev libncurses5-dev
RUN apt install -y crossbuild-essential-arm64

# Package deps
RUN apt install -y rsync kmod cpio debhelper

# Install inspection utilities
RUN apt install -y vim

# Pull latest kernel sources
#RUN git config --global http.sslVerify "false"  # needed on our LAN, sorry...
RUN git clone --depth=1 https://github.com/raspberrypi/linux
WORKDIR /linux

# Copy in a RPI4 config as the default
RUN cp arch/arm64/configs/bcm2711_defconfig .config

# Optional: use my security-enhanced config
ADD hen_config /linux/.config
