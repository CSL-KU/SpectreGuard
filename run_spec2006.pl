#!/usr/bin/perl

use warnings;
use strict;

use lib '.';
require 'Monitor.pm';

my @tasks = ();

## setup the work to run the synthetic benchmarks
foreach my $bench (
    { name => 'Native',      scheme => 'UnsafeBaseline',           SG_all => '0', SG_opt => '0', kernel => 'vmlinux' },
    { name => 'InvisiSpec',  scheme => 'SpectreSafeInvisibleSpec', SG_all => '0', SG_opt => '0', kernel => 'vmlinux' },
    { name => 'Fence',       scheme => 'SpectreSafeFence',         SG_all => '0', SG_opt => '0', kernel => 'vmlinux' },
    { name => 'SG-Opt-All',  scheme => 'UnsafeBaseline',           SG_all => '1', SG_opt => '1', kernel => 'vmlinux' },
    { name => 'SG-Base-All', scheme => 'UnsafeBaseline',           SG_all => '1', SG_opt => '0', kernel => 'vmlinux' },
    { name => 'SG-Opt-NoS',  scheme => 'UnsafeBaseline',           SG_all => '0', SG_opt => '1', kernel => 'vmlinux_SG_all_no_stack' },
    { name => 'SG-Base-NoS', scheme => 'UnsafeBaseline',           SG_all => '0', SG_opt => '0', kernel => 'vmlinux_SG_all_no_stack' },
)
{
    foreach my $test (  "bzip2", "mcf", "gobmk", "hmmer", "sjeng", "libquantum", "h264ref", "omnetpp", "astar",
                        "bwaves", "gamess", "milc", "zeusmp", "gromacs", "cactusADM", "leslie3d", "namd", "soplex",
                        "calculix", "GemsFDTD", "tonto", "lbm", "sphinx3"
    )
    {
        my $name   = $bench->{'name'};
        my $kernel = $bench->{'kernel'};
        my %bench_copy = %{$bench};
        $bench_copy{'test'} = $test;
        push @tasks, {
            msg  => "Bench $name for test $test",
            func => \&run_spec2006,
            args => \%bench_copy,
        };
    }
}

Monitor::do_work({
    tasks => \@tasks,
    max_tasks => 30,
});

sub run_spec2006
{
    my $bench = shift;
    
    my $name   = $bench->{'name'};
    my $scheme = $bench->{'scheme'};
    my $SG_all = $bench->{'SG_all'};
    my $SG_opt = $bench->{'SG_opt'};
    my $script = $bench->{'test'};
    my $kernel = $bench->{'kernel'};
    
    if( -e "./artifacts/checkpoints/spec2006/${name}/${script}" )
    {
        system "rm -rf ./artifacts/checkpoints/spec2006/${name}/${script}";
    }
    
    system "mkdir -p ./artifacts/checkpoints/spec2006/${name}/${script}";
    
    $ENV{'M5_PATH'} = "./x86-system";
    
    system "./gem5-InvisiSpec/build/X86_MESI_Two_Level/gem5.fast -d artifacts/checkpoints/spec2006/${name}/${script} gem5-InvisiSpec/configs/example/fs.py --num-cpus=1 --sys-clock=2GHz --mem-type=DDR3_1600_8x8 --mem-size=4GB --caches --l2cache --l1d_size=64kB --l1i_size=16kB --l2_size=256kB --cpu-type=AtomicSimpleCPU --cpu-clock=2GHz --script=scripts/${script}.rcS -I 2000000000 --checkpoint-at-end --disk-image=amd64-linux.img --kernel=$kernel > artifacts/checkpoints/spec2006/${name}/${script}/log.out 2>&1";
    
    if( -e "./artifacts/results/spec2006/${name}/${script}" )
    {
        system "rm -rf ./artifacts/results/spec2006/${name}/${script}";
    }
    
    system "mkdir -p ./artifacts/results/spec2006/${name}/${script}";
    
    system "./gem5-InvisiSpec/build/X86_MESI_Two_Level/gem5.fast -d ./artifacts/results/spec2006/${name}/${script} gem5-InvisiSpec/configs/example/fs.py --num-cpus=1 --sys-clock=2GHz --mem-type=DDR3_1600_8x8 --mem-size=4GB --caches --l2cache --l1d_size=64kB --l1i_size=16kB --l2_size=256kB --cpu-type=DerivO3CPU --cpu-clock=2GHz --network=simple --topology=Mesh_XY --mesh-rows=1 --ruby --l1d_assoc=8 --l2_assoc=16 --l1i_assoc=4 --needsTSO=0 --scheme=${scheme} --SG_all=${SG_all} --SG_opt=${SG_opt} --checkpoint-restore=2 -I 1000000000 --checkpoint-dir=artifacts/checkpoints/spec2006/${name}/${script} --restore-with-cpu=AtomicSimpleCPU --disk-image=amd64-linux.img > artifacts/results/spec2006/${name}/${script}/log.out 2>&1";
}

exit 0;
