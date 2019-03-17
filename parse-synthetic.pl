#!/usr/bin/perl

use strict;
use warnings;

my @bench_names = ('25S/75C', '50S/50C', '75S/25C', '90S/10C');
my @configs = ('Native', 'InvisiSpec', 'Fence', 'SG-Opt', 'SG-Opt-NoS', 'SG-Opt-All', 'SG-Base', 'SG-Base-NoS', 'SG-Base-All');
my %configs_display_name = (
    Native        => 'Native',
    InvisiSpec    => 'InvisiSpec',
    Fence         => 'Fence',
    'SG-Opt'      => 'SG-Opt',
    'SG-Opt-NoS'  => 'SG-Opt-NoS',
    'SG-Opt-All'  => 'SG-Opt-All',
    'SG-Base'     => 'SG-Base',
    'SG-Base-NoS' => 'SG-Base-NoS',
    'SG-Base-All' => 'SG-Base-All',
);

my %all_benches;

foreach my $config (@configs) {
    my $bench_path = "artifacts/results/synthetic/${config}/bench.out";
    my $bench_num = 0;
    
    open(my $stats_handle, "<", $bench_path) or die "Can't open < $bench_path: $!";
    while (<$stats_handle>)
    {
        if( m/\Atotal time.*\[([0-9]+)\]/ )
        {
            my $time = $1;
            $all_benches{$config}{$bench_names[$bench_num]}{sim_seconds} = $time;
            $bench_num++;
        }
    }
    
    close($stats_handle);
    
    die "Did not find all test times for file |${bench_path}|!!\n\n" unless $bench_num == 4;
}

if( -e "./artifacts/graphs/synthetic" )
{
    system "rm -rf ./artifacts/graphs/synthetic";
}

system "mkdir -p ./artifacts/graphs/synthetic";

my $spec_perf_path_dat = "artifacts/graphs/synthetic/synthetic-perf.dat";
open(my $spec_perf_handle_dat, ">", $spec_perf_path_dat) or die "Can't open > $spec_perf_path_dat: $!";

printf $spec_perf_handle_dat "scheme\t";
foreach my $config ( @configs )
{
    printf $spec_perf_handle_dat $configs_display_name{$config} . "\t";
}
printf $spec_perf_handle_dat "\n";

foreach my $bench (@bench_names)
{
    printf $spec_perf_handle_dat "$bench\t";
    foreach my $config ( @configs )
    {
        my $norm_time = $all_benches{$config}{$bench}{sim_seconds} / $all_benches{Native}{$bench}{sim_seconds};
        printf $spec_perf_handle_dat "%.3f\t", $norm_time;
    }
    printf $spec_perf_handle_dat "\n";
}

system "gnuplot scripts/synthetic-perf.gnu > artifacts/graphs/synthetic/synthetic-perf.pdf";

exit 0;
