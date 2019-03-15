#########
Overview:
#########

SpectreGuard is a novel defense strategy against Spectre attacks. Instead of
attempting to create a full solution in hardware that is invisible to the
programmer, or a software solution that is disconnected from the hardware, we
choose an approach that allows hardware and software to work together. We
allow programmers to register memory that should remain secret from an
attacker with the operating system. The operating system then utilizes low-cost
hardware extensions to protect only the memory that must be protected from an
attacker. This allows both high-performance processes that are not concerned
with security and processes that are willing to trade performance for security
to run on the same processor. It also gives programmers the flexibility to
create solutions that are both high-performance and secure.

This repository contains a system simulator(gem5) that has been modified to
implement the hardware extensions of SpectreGuard. It also contains a Linux
Kernel that has been modified to allow users to register non-speculative memory
sections. Finally, it contains benchmarks to test the modifications. The gem5
simulator was taken from the InvisiSpec(a hardware only Spectre solution)
repository, so that comparisons could be made with that approach.

Repository has been tested on Ubuntu 16.04.3 LTS and Ubuntu 18.04.1 LTS

##############
Building gem5:
##############

The first step is to build the gem5 simulator. Detailed build instructions can
be found at the gem5 website:
    http://learning.gem5.org/book/part1/building.html

Once the proper tools have been installed, run this command:
    cd BASE_DIR/gem5-InvisiSpec/
    scons -j16 build/X86_MESI_Two_Level/gem5.fast

Modify the -j16 for the number of threads your system can handle.

###########################
Unpacking the system image:
###########################

gem5 requires a system image to run on. One has been provided. To unpack it:
    cd BASE_DIR/x86-system-parts/
    ./restore_system.pl

This system is ready to run the synthetic benchmark right out of the box,
    but you will need to mount it if you would like to build it yourself,
    or you would like to add the spec2006 benchmark files.

To mount the system simply:
    cd BASE_DIR/x86-system/disks/
    sudo mount -o loop,offset=$((2048*512)) amd64-linux.img tempdir

tempdir will now contain the system files.
The OS utilizes busybox.
On boot, the init script creates a checkpoint and then loads and runs a script.
    there is also an init script in /etc for booting to a terminal.

#################################
Building the synthetic benchmark:
#################################

To build and install the synthetic benchmark:
    cd BASE_DIR/synthetic_benchmark/
    make
    cp specBench_base ../x86-system/disks/tempdir/usr/bin/microbench/specBench_base
    cp specBench_mask ../x86-system/disks/tempdir/usr/bin/microbench/specBench_mask
    cp specBench_wbor ../x86-system/disks/tempdir/usr/bin/microbench/specBench_wbor

##################
Building spec2006:
##################

We cannot provide spec2006 as it is licensed. To add this benchmark, you must
    first build it statically, and then copy the desired tests into the
    following tree structure:
    
    BASE_DIR/x86-system/disks/tempdir/usr/bin/spec/
        astar/
            astar_base.gcc43-64bit
            BigLakes2048.bin
            BigLakes2048.cfg
            rivers.bin
            rivers.cfg
        bwaves/
            bwaves_base.gcc43-64bit
            bwaves.in
        bzip2/
            ......
        .......

A complete list of benchmarks and files required can be found in the script
    for running the benchmarks, along as in the scripts folder which contains
    the individual scripts for each benchmark.

##########################
Building the Linux Kernel:
##########################

We need to build 2 versions of the kernel to run all of the benchmarks.

First:
    cd BASE_DIR/linux-4.18.12/
    cp gem5_config .config
    make oldconfig
    make -j16 vmlinux

You may need to answer yes or no when performing make oldconfig, but the
    options should not be relevant.
    
    cp vmlinux ../x86-system/binaries/vmlinux

We must now make the kernel again.
    make clean
    cp gem5_SG_all_no_stack_config .config
    make oldconfig
    make -j16 vmlinux
    cp vmlinux ../x86-system/binaries/vmlinux_SG_all_no_stack

You are now ready to run benchmarks

#######################
Running the Benchmarks:
#######################

To run the synthetic benchmark:
    cd BASE_DIR/
    ./run_synthetic_bench.pl

This will begin by creating 2 checkpoints past the kernel booting,
    and then using those checkpoints to run the benchmark under the various
    configurations.

This may take sometime, so you may want to run as:
    nohup ./run_synthetic_bench.pl </dev/null >synthetic.log 2>&1 &
