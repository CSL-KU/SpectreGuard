#!/usr/bin/perl

use warnings;
use strict;

use lib '.';
require 'Monitor.pm';

my @tasks = ();

## setup the work to create the shared checkpoints for the synthetic benchmark
foreach my $kernel ( 'vmlinux', 'vmlinux_SG_all_no_stack' )
{
    push @tasks, {
        msg  => "Shared checkpoint for kernel $kernel",
        func => \&create_shared_checkpoint,
        args => {
            kernel => $kernel,
        },
    };
}

## uncomment this to reuse the same checkpoints
## @tasks = ();

Monitor::do_work({
    tasks => \@tasks,
    max_tasks => 2,
});

## setup the work to run the synthetic benchmarks
foreach my $bench (
    { name => 'Native',      scheme => 'UnsafeBaseline',           SG_all => '0', SG_opt => '0', script => 'specBench_base', kernel => 'vmlinux' },
    { name => 'InvisiSpec',  scheme => 'SpectreSafeInvisibleSpec', SG_all => '0', SG_opt => '0', script => 'specBench_base', kernel => 'vmlinux' },
    { name => 'Fence',       scheme => 'SpectreSafeFence',         SG_all => '0', SG_opt => '0', script => 'specBench_base', kernel => 'vmlinux' },
    { name => 'SG-Opt',      scheme => 'UnsafeBaseline',           SG_all => '0', SG_opt => '1', script => 'specBench_wbor', kernel => 'vmlinux' },
    { name => 'SG-Base',     scheme => 'UnsafeBaseline',           SG_all => '0', SG_opt => '0', script => 'specBench_wbor', kernel => 'vmlinux' },
    { name => 'SG-Opt-All',  scheme => 'UnsafeBaseline',           SG_all => '1', SG_opt => '1', script => 'specBench_base', kernel => 'vmlinux' },
    { name => 'SG-Base-All', scheme => 'UnsafeBaseline',           SG_all => '1', SG_opt => '0', script => 'specBench_base', kernel => 'vmlinux' },
    { name => 'SG-Opt-NoS',  scheme => 'UnsafeBaseline',           SG_all => '0', SG_opt => '1', script => 'specBench_base', kernel => 'vmlinux_SG_all_no_stack' },
    { name => 'SG-Base-NoS', scheme => 'UnsafeBaseline',           SG_all => '0', SG_opt => '0', script => 'specBench_base', kernel => 'vmlinux_SG_all_no_stack' },
)
{
    my $name   = $bench->{'name'};
    my $kernel = $bench->{'kernel'};
    push @tasks, {
        msg  => "Bench $name using kernel $kernel",
        func => \&run_synthetic_bench,
        args => $bench,
    };
}

Monitor::do_work({
    tasks => \@tasks,
    max_tasks => 9,
});

sub run_synthetic_bench
{
    my $bench = shift;
    
    my $name   = $bench->{'name'};
    my $scheme = $bench->{'scheme'};
    my $SG_all = $bench->{'SG_all'};
    my $SG_opt = $bench->{'SG_opt'};
    my $script = $bench->{'script'};
    my $kernel = $bench->{'kernel'};
    
    if( -e "./artifacts/results/synthetic/${name}" )
    {
        system "rm -rf ./artifacts/results/synthetic/${name}";
    }
    
    system "mkdir -p ./artifacts/results/synthetic/${name}";
    
    $ENV{'M5_PATH'} = "./x86-system";
    
    system "./gem5-InvisiSpec/build/X86_MESI_Two_Level/gem5.fast -d ./artifacts/results/synthetic/${name} gem5-InvisiSpec/configs/example/fs.py --num-cpus=1 --sys-clock=2GHz --mem-type=DDR3_1600_8x8 --mem-size=100MB --caches --l2cache --l1d_size=64kB --l1i_size=16kB --l2_size=256kB --cpu-type=DerivO3CPU --cpu-clock=2GHz --network=simple --topology=Mesh_XY --mesh-rows=1 --ruby --l1d_assoc=8 --l2_assoc=16 --l1i_assoc=4 --needsTSO=0 --scheme=${scheme} --SG_all=${SG_all} --SG_opt=${SG_opt} --checkpoint-restore=1 --checkpoint-dir=artifacts/checkpoints/generic/${kernel} --restore-with-cpu=AtomicSimpleCPU --disk-image=amd64-linux.img --script=scripts/${script}.rcS > artifacts/results/synthetic/${name}/log.out 2>&1";
}

sub create_shared_checkpoint
{
    my $args = shift;
    
    my $kernel = $args->{'kernel'};
    
    if( -e "./artifacts/checkpoints/generic/${kernel}" )
    {
        system "rm -rf ./artifacts/checkpoints/generic/${kernel}";
    }
    
    system "mkdir -p ./artifacts/checkpoints/generic/${kernel}";
    
    $ENV{'M5_PATH'} = "./x86-system";
    
    system "./gem5-InvisiSpec/build/X86_MESI_Two_Level/gem5.fast -d artifacts/checkpoints/generic/${kernel} gem5-InvisiSpec/configs/example/fs.py --num-cpus=1 --sys-clock=2GHz --mem-type=DDR3_1600_8x8 --mem-size=100MB --caches --l2cache --l1d_size=64kB --l1i_size=16kB --l2_size=256kB --cpu-type=AtomicSimpleCPU --cpu-clock=2GHz --script=scripts/specBench_base.rcS --disk-image=amd64-linux.img --kernel=$kernel > artifacts/checkpoints/generic/${kernel}/log.out 2>&1";
}

exit 0;
