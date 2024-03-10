rpi-kernel-build
================

This project is a docker image that contains the cross-compile build environment for the latest Raspberry Pi 4 kernel. 

Usage
-----

```
docker build . -t rpi-kern-dev
docker run -it rpi-kern-dev /bin/bash
```

Once in the container, you can proceed to actually build the kernel according to your desired configuration. To build a default kernel:

```
cd linux
export KERNEL=kernel8
export LOCALVERSION=
export KCFLAGS='-march=armv8-a+crc -mtune=cortex-a72'
export ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- 
make bcm2711_defconfig
```

My most recent custom config is provided as hen_config for reference. 
Right now, it's based on kernel version 6.6.21.
