#!/usr/bin/perl

use strict;
use warnings;

my $command = "rm ../x86-system.tar.gz";
print "$command\n";
system $command;

die "could not delete old tar directory!!\n\n" if -e "../x86-system.tar.gz";
die "disk needs to be unmounted before storing!!\n\n" if -e "../x86-system/disks/tempdir/bin/busybox";

$command = "cd ..; tar -czvf x86-system.tar.gz x86-system";
print "$command\n";
system $command;

die "could not create new tar directory!!\n\n" unless -e "../x86-system.tar.gz";

$command = "rm `ls | grep -v system`";
print "$command\n";
system $command;

my $num_bytes = 32 * 1024 * 1024;
$command = "split -b $num_bytes ../x86-system.tar.gz";
print "$command\n";
system $command;

my $file = `ls | grep xaa`;
chomp($file);
die "Could not split tar file, |xaa| is missing!!\n\n" unless $file eq 'xaa';

$command = "rm ../x86-system.tar.gz";
print "$command\n";
system $command;

exit 0;
