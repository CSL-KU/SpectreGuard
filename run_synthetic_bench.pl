#!/usr/bin/perl

use warnings;
use strict;

use lib '.';
require 'Monitor.pm';

my @tasks = ();

$| = 1;

## setup the work to create the shared checkpoints for the synthetic benchmark
foreach my $kernel ( 'vmlinux', 'vmlinux_SG_heap' )
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
#@tasks = ();

Monitor::do_work({
    tasks => \@tasks,
    max_tasks => 0,
});

## setup the work to run the synthetic benchmarks
foreach my $bench (
    { name => 'Native',          scheme => 'UnsafeBaseline',           SG_all => '0', SG_opt => '0', script => 'specBench_base',    kernel => 'vmlinux' },
    { name => 'InvisiSpec',      scheme => 'SpectreSafeInvisibleSpec', SG_all => '0', SG_opt => '0', script => 'specBench_base',    kernel => 'vmlinux' },
    { name => 'Fence',           scheme => 'SpectreSafeFence',         SG_all => '0', SG_opt => '0', script => 'specBench_base',    kernel => 'vmlinux' },
    { name => 'SG-Key',          scheme => 'UnsafeBaseline',           SG_all => '0', SG_opt => '1', script => 'specBench_wbor',    kernel => 'vmlinux' },
    { name => 'SG-All',          scheme => 'UnsafeBaseline',           SG_all => '1', SG_opt => '1', script => 'specBench_base',    kernel => 'vmlinux' },
    { name => 'Attack_Test',     scheme => 'UnsafeBaseline',           SG_all => '0', SG_opt => '1', script => 'spectre_attack',    kernel => 'vmlinux' },
    { name => 'Attack_Test_Mit', scheme => 'UnsafeBaseline',           SG_all => '0', SG_opt => '1', script => 'spectre_attack_mit',kernel => 'vmlinux' },
    { name => 'Mark_Test',       scheme => 'UnsafeBaseline',           SG_all => '0', SG_opt => '0', script => 'markTest',          kernel => 'vmlinux' },
    { name => 'Mark_Test_All',   scheme => 'UnsafeBaseline',           SG_all => '1', SG_opt => '0', script => 'markTest',          kernel => 'vmlinux' },
    { name => 'Mark_Test_Heap',  scheme => 'UnsafeBaseline',           SG_all => '0', SG_opt => '0', script => 'markTest',          kernel => 'vmlinux_SG_heap' },
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
    max_tasks => 0,
});

## Confirm that Spectre can exploit the system and that it is mitigated
confirm_attack();

sub confirm_attack
{
    my $file = "./artifacts/results/synthetic/Attack_Test/bench.out";
    
    unless( -e $file )
    {
        die "File |${file}| does not exist.\nDid you run the attack benchmark??\n\n";
    }
    
    my $match = `grep hit ${file}`;
    unless( $match =~ m/\A123: [0-9]+, hit\Z/)
    {
        die "Could not confirm Spectre exploit works.\nManually check |${file}| for attack output.\nThere may just be noise on the side channel.\n";
    }
    
    $file = "./artifacts/results/synthetic/Attack_Test_Mit/bench.out";
    
    unless( -e $file )
    {
        die "File |${file}| does not exist.\nDid you run the attack mitigation benchmark??\n\n";
    }
    
    $match = `grep 123 ${file}`;
    unless( $match =~ m/\A123: [0-9]+, miss\Z/)
    {
        die "Spectre mitigation failed.\nManually check |${file}| for attack output.\nThere may just be noise on the side channel.\n\n";
    }
    
    print "Spectre exploit works and has been mitigated!!\n\n";
}

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
    
    system "./gem5/build/X86_MESI_Two_Level/gem5.fast -d ./artifacts/results/synthetic/${name} gem5/configs/example/fs.py --num-cpus=1 --sys-clock=2GHz --mem-type=DDR3_1600_8x8 --mem-size=100MB --caches --l2cache --l1d_size=64kB --l1i_size=32kB --l2_size=2MB --cpu-type=DerivO3CPU --cpu-clock=2GHz --network=simple --topology=Mesh_XY --mesh-rows=1 --ruby --l1d_assoc=8 --l2_assoc=16 --l1i_assoc=4 --needsTSO=0 --scheme=${scheme} --SG_all=${SG_all} --SG_opt=${SG_opt} --checkpoint-restore=1 --checkpoint-dir=artifacts/checkpoints/generic/${kernel} --restore-with-cpu=AtomicSimpleCPU --disk-image=amd64-linux.img --script=scripts/${script}.rcS > artifacts/results/synthetic/${name}/log.out 2>&1";
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
    
    system "./gem5/build/X86_MESI_Two_Level/gem5.fast -d artifacts/checkpoints/generic/${kernel} gem5/configs/example/fs.py --num-cpus=1 --sys-clock=2GHz --mem-type=DDR3_1600_8x8 --mem-size=100MB --caches --l2cache --l1d_size=64kB --l1i_size=32kB --l2_size=2MB --cpu-type=AtomicSimpleCPU --cpu-clock=2GHz --script=scripts/boot.rcS --disk-image=amd64-linux.img --kernel=$kernel > artifacts/checkpoints/generic/${kernel}/log.out 2>&1";
}

exit 0;
