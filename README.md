rpi-kernel-build
================

This project is a docker image that contains the cross-compile build environment for the latest Raspberry Pi 4 kernel. 

Also, provide a configuration that is suitable for my needs on my personally-owned Raspberry Pi 4 device.

Usage
-----

```
docker build . -t rpi-kern-dev
docker run -it rpi-kern-dev /bin/bash
```

Once in the container, you can proceed to actually build the kernel according to your desired configuration. To build a default kernel:

```
cd /linux
export KERNEL=kernel8
export LOCALVERSION=
export KCFLAGS='-march=armv8-a+crc -mtune=cortex-a72'
export ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- 
make bcm2711_defconfig
```

My most recent custom config is provided as hen_config for reference. 

Custom Configuration
====================

This section describes what tweaks my configuration applies atop the default Raspberry Pi 4 build config, and for what purpose those changes were made. It should help you decide if you'd like to try my shipped configuration or start from something higher up the chain. 

This config was last updated for version 6.6.22 and can be automatically updated using `make oldconfig` when it's installed as `.config`.

#### Changes to preference or common sense QOL changes

* Custom kernel version string to identify the kernel
* CONFIG_BPF_JIT_ALWAYS_ON because its pointless to build in JIT support for BPF and not use it. Force it to on, and remove the interpreter option entirely to safe space. Note that unpriv users can't run BFP programs.
* CONFIG_PREEMPT_VOLUNTARY instead of the default PREEMPT_FULL for better throughput on a limited-resource device. RPi is not well-suited for low-latency control systems anyway. I believe most real-world uses would be better served with more throughput than tiny reductions in interrupt latency. 
* Remove CONFIG_PSI_DEFAULT_DISABLED because PSI is a great idea to improve performance and should be turned on by default. This enables tools like systemd-oomd to make good choices, and provides a nice way to assess how the system is constrained. 
* Enable CONFIG_SCHED_MC. RPi4 has a multicore SoC. 
* Set NR_CPUS=4 because this is a known, fixed value.
* Set CONFIG_FORCE_NR_CPUS for the same reason.
* Enable CONFIG_ARM64_SW_TTBR0_PAN, and important security feature that prevents the kernel from accidentally accessing userspace pages. 
* Set CONFIG_RANDOMIZE_KSTACK_OFFSET_DEFAULT to enable actually using the default-compiled-in security feature that makes kernel stacks harder to exploit.
* Enable forced module loading and unloading if the userspace tool requests this, because do as I say!
* Zswap with z3fold on and enabled by default for this memory-constrained system.
* Low cost kernel memory allocator hardening options.
* Set CONFIG_RANDOM_KMALLOC_CACHES to make kernel heap spraying harder.
* Increase CONFIG_DEFAULT_MMAP_MIN_ADDR to 65536 to slightly increase difficulty of attacking kernel NULL ptr bugs.
* Set CONFIG_SECURITY_DMESG_RESTRICT because only admins should have reason to read the logs.
* Enable CONFIG_HARDENED_USERCOPY, a cheap yet effective mitigation that makes it harder to trick the kernel into loading userspace data unexpectedly.
* Enable CONFIG_FORTIFY_SOURCE because obviously yes we should try to detect and prevent buffer overflows.
* Set CONFIG_SECURITY_YAMA to build-in YAMA which limits the scope of ptrace. 
* Set CONFIG_INIT_ON_ALLOC_DEFAULT_ON to force kernel to init heap memory before using it. This is a cheap mitigation that prevents some bugs.
* Set CONFIG_ZERO_CALL_USED_REGS to force all functions to clean up temporaries, reducing some bugs and making ROP chains a little harder to build (JOP and unintended gadgets will still exist), for very little performance impact and a slightly bigger kernel text.
* Set CONFIG_LIST_HARDENED for extra linked-list consistency checks.
* Set CONFIG_BUG_ON_DATA_CORRUPTION to act on those checks.
* Set CONFIG_DEBUG_FS_ALLOW_NONE because debugfs is a security risk and isn't usually needed.
* Set CONFIG_UBSAN_BOUNDS and CONFIG_UBSAN_TRAP to guard against another source of OOB access. 
* Set CONFIG_DEBUG_WX because it's cheap and a great warning to have.
* Set CONFIG_SCHED_STACK_END_CHECK for a cheap stack corruption check.
* Set CONFIG_STRICT_DEVMEM and CONFIG_IO_STRICT_DEVMEM to really police the dangerous `/dev/mem` device.

#### Changes because uncommon or irrelevant

* Remove CONFIG_IO_URING. It's not widely used and a major source of security vulnerabilities. The few apps that do use it fallback gracefully to normal file IO. It's a nice idea that needs more time to mature. It's blocked by default on quite a few platforms such as Android for good reason. 
* Remove all arm 8.X features that we know the SoC doesn't support anyway.
* Remove CONFIG_ARM64_SVE because SoC doesn't have SVE.
* Remove CONFIG_EFI because we don't have one. 
* Remove CONFIG_VIRTUALIZATION. We don't have the RAM for this anyway. 
* Remove CONFIG_RAID6_PQ_BENCHMARK because we're really not likely to be using RAID6, and don't want to pay the cost of benchmarking on every boot. 
* Remove CONFIG_KALLSYMS_ALL because it's not usually needed, increases kernel size, and might hurt performance and security slightly. 

#### Changes because we aren't a kernel developer
* Remove CONFIG_PROFILING because we aren't profiling the kernel.
* Set CONFIG_TRIM_UNUSED_KSYMS because we don't care about building out-of-tree modules. If you need DKMS (unlikely) this setting might break your builds.
* Remove CONFIG_KGDB because we aren't debugging the kernel.
* Remove CONFIG_FTRACE to disable tracing the kernel.
* Remove latency measurement system because not interesting in kernel performance measurement, and because it would force us to enable KALLSYMS.