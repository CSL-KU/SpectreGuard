#!/usr/bin/perl

use strict;
use warnings;

my @files = `ls`;
chomp @files;
my @pieces = ();

foreach my $file ( @files )
{
    if( $file =~ m/\A[a-xA-X]{3}\Z/ )
    {
        push @pieces, $file;
    }
}

my $command = "cat @pieces > ../x86-system.tar.gz";
print "$command\n";
system $command;

$command = "cd ..; tar -xzvf x86-system.tar.gz";
print "$command\n";
system $command;

$command = "rm ../x86-system.tar.gz";
print "$command\n";
system $command;

exit 0;
