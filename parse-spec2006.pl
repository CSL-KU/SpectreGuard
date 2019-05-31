#!/usr/bin/perl

use strict;
use warnings;

my @bench_names = ('bzip2', 'mcf', 'gobmk', 'hmmer', 'sjeng', 'libquantum', 'h264ref', 'omnetpp', 'astar', 'bwaves', 'gamess', 'milc', 'zeusmp', 'gromacs', 'cactusADM', 'leslie3d', 'namd', 'soplex', 'calculix', 'GemsFDTD', 'tonto', 'lbm', 'sphinx3');
my @configs = ('Native', 'SG-HEAP', 'SG-Opt-All', 'InvisiSpec', 'Fence');
my %configs_display_name = (
    Native        => 'Native',
    InvisiSpec    => 'InvisiSpec',
    Fence         => 'Fence',
    'SG-HEAP'     => 'SG(Heap)',
    'SG-Opt-All'  => 'SG(All)',
);

my $normalize_run = 'Native';

my %all_benches;

foreach my $config (@configs) {
    foreach my $bench ( @bench_names )
    {
        my $bench_path = "artifacts/results/spec2006/${config}/${bench}/stats.txt";
        
        open(my $stats_handle, "<", $bench_path) or die "Can't open |$bench_path|: says |$!|";
        while (<$stats_handle>)
        {
            my @spl = split ' ';
            if (defined($spl[0]) && $spl[0] eq 'sim_seconds') {
                $all_benches{$config}{$bench}{sim_seconds} = $spl[1];
                last;
            }
        }

        close($stats_handle);
        die "Did not find sim_seconds in file |${bench_path}|!!\n\n" unless exists $all_benches{$config}{$bench}{sim_seconds};
    }
}

if( -e "./artifacts/graphs/spec2006" )
{
    system "rm -rf ./artifacts/graphs/spec2006";
}

system "mkdir -p ./artifacts/graphs/spec2006";

my $spec_perf_path_dat = "artifacts/graphs/spec2006/spec2006-perf.dat";
open(my $spec_perf_handle_dat, ">", $spec_perf_path_dat) or die "Can't open > $spec_perf_path_dat: $!";

printf $spec_perf_handle_dat "scheme\t";
foreach my $config ( @configs )
{
    printf $spec_perf_handle_dat $configs_display_name{$config} . "\t";
    $all_benches{$config}{norm_time} = 0;
}
printf $spec_perf_handle_dat "\n";

foreach my $bench (@bench_names)
{
    printf $spec_perf_handle_dat "$bench\t";
    foreach my $config ( @configs )
    {
        my $norm_time = $all_benches{$config}{$bench}{sim_seconds} / $all_benches{$normalize_run}{$bench}{sim_seconds};
        printf $spec_perf_handle_dat "%.3f\t", $norm_time;
        
        $all_benches{$config}{norm_time} = $norm_time + $all_benches{$config}{norm_time};
    }
    printf $spec_perf_handle_dat "\n";
}

printf $spec_perf_handle_dat "average\t";
foreach my $config ( @configs )
{
    printf $spec_perf_handle_dat "%.3f\t", $all_benches{$config}{norm_time} / @bench_names;
}

system "gnuplot scripts/spec2006-perf.gnu > artifacts/graphs/spec2006/spec2006-perf.pdf";

exit 0;
