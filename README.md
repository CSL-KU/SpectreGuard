# Overview:

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
repository, so that comparisons could be made with that approach:
https://github.com/mjyan0720/InvisiSpec-1.0

Repository has been tested on Ubuntu 16.04.3 LTS and Ubuntu 18.04.1 LTS

# Building gem5:

The first step is to build the gem5 simulator. Detailed build instructions can
be found at the gem5 website:
    http://learning.gem5.org/book/part1/building.html

Once the proper tools have been installed, run these commands:
```
    cd BASE_DIR/gem5/
    scons -j16 build/X86_MESI_Two_Level/gem5.fast
```

Modify the -j16 for the number of threads your system can handle.

# Unpacking the system image:

gem5 requires a system image to run on. One has been provided. To unpack it:
```
    cd BASE_DIR/x86-system-parts/
    ./restore_system.pl
```

This system is ready to run the synthetic benchmark right out of the box,
    but you will need to mount it if you would like to build it yourself,
    or you would like to add the spec2006 benchmark files.

To mount the system simply:
```
    cd BASE_DIR/x86-system/disks/
    sudo mount -o loop,offset=$((2048*512)) amd64-linux.img tempdir
```

tempdir will now contain the system files.
The OS utilizes busybox.
On boot, the init script creates a checkpoint and then loads and runs a script
    that is passed in on the gem5 command line. There is also an init script in
    /etc for booting to a terminal.

# Building the synthetic benchmark:

To build and install the synthetic benchmark(assuming the disk image is mounted):
```
    cd BASE_DIR/synthetic_benchmark/
    make
    sudo cp specBench_base      ../x86-system/disks/tempdir/usr/bin/microbench/specBench_base
    sudo cp specBench_wbor      ../x86-system/disks/tempdir/usr/bin/microbench/specBench_wbor
    sudo cp spectre_attack      ../x86-system/disks/tempdir/usr/bin/spectre_attack
    sudo cp spectre_attack_mit  ../x86-system/disks/tempdir/usr/bin/spectre_attack_mit
    sudo cp markTest            ../x86-system/disks/tempdir/usr/bin/markTest
```

# Building spec2006:

We cannot provide spec2006 as it is licensed. To add this benchmark, you must
    first build spec2006 statically, and then copy the desired tests into the
    following tree structure:

```    
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
```

A complete list of benchmarks and files required can be found in the script
    for running the benchmarks, along as in the scripts folder which contains
    the individual scripts for each benchmark.

# Building the Linux Kernel:

We need to build 2 versions of the kernel to run all of the benchmarks.

First:
```
    cd BASE_DIR/linux-4.18.12/
    cp gem5_config .config
    make oldconfig
    make -j16 vmlinux
```

You may need to answer yes or no when performing make oldconfig, but the
    options should not be relevant.
   
``` 
    cp vmlinux ../x86-system/binaries/vmlinux
```

We must now build a special kernel that marks all heap pages as non-speculative.
```
    make clean
    cp gem5_SG_heap .config
    make oldconfig
    make -j16 vmlinux
    cp vmlinux ../x86-system/binaries/vmlinux_SG_heap
```

You are now ready to run benchmarks

# Running the Benchmarks:

General:
    Both benchmarks may take from hours to days to run depending on the
        hardware used. For this reason, both benchmarks utilize a dynamic
        system for adjusting the number of active processes. This way, 24 hours
        into a 48 hour run, a user can throttle the benchmark down from say 16
        processes to only 4 while another process needs the resources of the
        same machine. To change the number of max processes:
   
```     
        cd BASE_DIR/
        echo ### > max_tasks.txt
```
        
        Where ### is the maximum number of processes to run at one time. If
        lowering the number, you will need to wait for processes to finish for
        the load to lessen. When raising the number, you will need to wait for
        at least one process to finish before the load will change. Be sure to
        check the log file to ensure that the change happened correctly:
   
```     
        cat synthetic.log
        .....
        STATUS: updating max_tasks from |4| to |16|
        .....
```
        
    Because both benchmarks may take so long, you may want to run them like so:
   
```     
        nohup ./run_synthetic_bench.pl </dev/null >synthetic.log 2>&1 &
```
    
        This way, broken ssh connections will not stop the benchmark from
        running. The log files may then be checked to monitor progress.

To run the synthetic benchmark:
```
    cd BASE_DIR/
    ./run_synthetic_bench.pl
```

To run the spec2006 benchmark:
```
    cd BASE_DIR/
    ./run_spec2006.pl
```

# Generate the graphs:

Finally, to extract the data and create the graphs gnuplot is required.

synthetic benchmark:
```
    cd BASE_DIR/
    ./parse-synthetic.pl
```
    
spec2006 benchmark:
```
    cd BASE_DIR/
    ./parse-spec2006.pl
```
    
the resulting table and graph will be in the:
   
``` 
    BASE_DIR/artifacts/graphs/####/
```
    
    directories. Each will contain a data file and a .pdf containing the graph.
