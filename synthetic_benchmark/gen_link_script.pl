#!/usr/bin/perl

use strict;
use warnings;

########################################################################
# This script takes an old ELF binary file as input and produces a
# valid linker script that could have been used to link the |old_binary|
# such that:
#     gcc -T new_linker_script.lds -o binary ......
# will produce a working binary similar to |old_binary|
#
# This script also can add new program headers(segments) to the ELF file
# that contain custom flags. This is done by modifying the |new_phdrs|
# array. It will also take section headers that were previously placed
# in other segments - such as the data segment - and move them to one of
# the new segments, based on the new segment's flags.
#
# example:
#   a C file containing data placed in a special section such as:
#       int my_array[4096] __attribute__ ((section (".special")));
#
#   In this example, the |.special| section will be placed in the |DATA|
#   segment by the linker. This script could be then used to move the
#   |.special| section into a new segment, that contains custom flags.
#
# Currently, the new sections are all aligned on my system to 0x200000
# boundary, and adding additional features for the sections are not
# supported, but should be easy to add.
########################################################################
die "usage: gen_link_script.pl old_binary new_linker_script.lds\n\n" unless scalar @ARGV == 2;

my $old_binary = $ARGV[0];
my $new_linker_script = $ARGV[1];


### Read in the old binary file's program headers (segments)
my @old_phdrs_lines = `readelf -Wl $old_binary`;

my @old_phdrs = ();
my %old_sections = ();


### List that contains new program headers with custom flags
my @new_phdrs = (
    {
        type  => 'LOAD',
        flags => 0x10000006,
    }
);


### list that contains new section headers
###     the program header flags that they should be placed in
###     and the sub-section name matching rules
my %new_sections = (
    '.non-speculative' => {
        match_strings   => ['*(.non-speculative)'],
        flags           => 0x10000006,
    },
);


### Look for the start of the program header list
while( 1 )
{
    my $line = shift @old_phdrs_lines;
    if($line =~ m/\A\s+Type/)
    {
        last;
    }
    
    die "Never found marker for start of headers!!\n\n" if scalar @old_phdrs_lines == 0;
}


### parse the program header info
###     add each one to the |old_phdrs| array
while( 1 )
{
    my $line = shift @old_phdrs_lines;
    my @phdrs = split /\s+/, $line;
    my $cols = scalar @phdrs;
    last if $cols == 0;
    
    my $flags;
    my $type = $phdrs[1];
    $type = `echo PT_$type | cpp -P -imacros elf.h 2>&1 | tail -n 1`;
    chomp $type;
    
    if($cols == 9)
    {
        $flags = $phdrs[7];
    } elsif($cols == 10)
    {
        $flags = $phdrs[7] . $phdrs[8];
    }
    else
    {
        die "Parsing header properties and found bad line |$line|!!\n\n";
    }
    
    my $flags_num = 0;
    if( $flags =~ /E/){ $flags_num += 1; }
    if( $flags =~ /W/){ $flags_num += 2; }
    if( $flags =~ /R/){ $flags_num += 4; }
    
    my %phrds = (
            type  => $type,
            flags => $flags_num,
    );
    
    push @old_phdrs, \%phrds;
    
    last unless scalar @old_phdrs_lines;
}


### Add the new program headers from the |new_phdrs| array
###     to the end of the |old_phdrs| array
foreach my $phdrs ( @new_phdrs )
{
    my $type = $phdrs->{'type'};
    $type = `echo PT_$type | cpp -P -imacros elf.h 2>&1 | tail -n 1`;
    chomp $type;
    $phdrs->{'type'} = $type;
    
    push @old_phdrs, $phdrs;
}



### Find the start of the old section to segment mapping
while( 1 )
{
    my $line = shift @old_phdrs_lines;
    if($line =~ m/Segment Sections\.\.\./)
    {
        last;
    }
    
    die "Never found marker for start of header to section mapping!!\n\n" if scalar @old_phdrs_lines == 0;
}


### create an associative array that takes a section name as input
###     and returns a list of segments that it belongs to
while( 1 )
{
    my $line = shift @old_phdrs_lines;
    my @sections = split /\s+/, $line;
    my $cols = scalar @sections;
    
    next unless $cols > 2;
    
    shift @sections;
    my $index = $sections[0] + 0;
    shift @sections;
    
    while(scalar @sections)
    {
        my $section_name = shift @sections;
        $old_sections{$section_name} = [] unless exists $old_sections{$section_name};
        
        if( exists $new_sections{$section_name} )
        {
            my $count = 0;
            foreach my $phdrs (@old_phdrs)
            {
                if( $phdrs->{'flags'} == $new_sections{$section_name}->{'flags'} )
                {
                    last;
                }
                $count++;
            }
            
            push @{ $old_sections{$section_name} }, $count;
            next;
        }
        
        push @{ $old_sections{$section_name} }, $index;
    }

    last unless scalar @old_phdrs_lines;
}


### Add any missing sections here
###     this may change from linker to linker
if( defined $old_sections{'.init_array'} && !defined $old_sections{'.preinit_array'} )
{
    $old_sections{'.preinit_array'} = $old_sections{'.init_array'};
}


### Dump the linker's default linker script
###     Adding any program header information to this script will
###     invalidate it. So we need to modify it to add the new program
###     headers.
my @old_script = `ld --verbose 2>&1`;
while( 1 )
{
    my $line = shift @old_script;
    if($line =~ m/==================================================/)
    {
        last;
    }
    
    die "Never found marker for start of system default linker script!!\n\n" if scalar @old_script == 0;
}


### open the output file for the new linker script
open my $output_file, '>', $new_linker_script or die "Cannot open |$new_linker_script| for writing, says |$!|\n\n";
my $found_note_gnu = 0;

while( 1 )
{
    my $line = shift @old_script;
    if($line =~ m/==================================================/)
    {
        last;
    }
    
    ### The PHDRS{} block is missing from the default linker script, so
    ###     we need to add it before the SECTIONS{} block
    if($line =~ m/\ASECTIONS\Z/)
    {
        print $output_file "PHDRS\n{\n";
        
        my $count = 0;
        foreach my $phdrs (@old_phdrs)
        {
            my $type = $phdrs->{'type'};
            print $output_file "    phdr${count} ${type} ";
            $count++;
            
            my $flags = $phdrs->{'flags'};
            
            if( $type eq '1' && $flags == 5 )
            {
                print $output_file "FILEHDR PHDRS ";
            }
            
            print $output_file "FLAGS (${flags});\n";
        }
        
        print $output_file "}\n";
    }
    
    ### Add all of the custom sections here
    if( $line =~ m/DATA_SEGMENT_END/ )
    {
        foreach my $section ( keys %new_sections )
        {
            my $new_line = "  ${section} : {";
            
            foreach my $match_string ( @{ $new_sections{$section}->{'match_strings'} } )
            {
                $new_line .= " ${match_string}"
            }
            
            $new_line .= " }\n";
            
            unshift @old_script, $new_line;
            unshift @old_script, "  . = ((. + CONSTANT (MAXPAGESIZE)) & ~(CONSTANT (MAXPAGESIZE) - 1));\n";
            #unshift @old_script, "  . = ALIGN(CONSTANT (MAXPAGESIZE)) + (. & (CONSTANT (MAXPAGESIZE) - 1));\n";
        }
    }
    
    ### hard code this special gnu sections
    if( $line =~ m/\.note\.gnu\.build-id/ && !($found_note_gnu++))
    {
        unshift @old_script, $line;
        unshift @old_script, "  .note.ABI-tag : { *(.note.ABI-tag) }";
        next;
    }
    
    ### each old section needs to be modified to list what program
    ###     segments it belongs too, as this is missing from the
    ###     default linker script
    if($line =~ m/\A\s*(\.[-a-zA-Z0-9\._]+)\s+.*:/ )
    {
        my $section = $1;
        my $bracket_found = 0;
        while(1)
        {
            if( $bracket_found )
            {
                if( $line =~ m/\}/ )
                {
                    chomp $line;
                    print $output_file $line if defined $old_sections{$section};
                    
                    if( defined $old_sections{$section} )
                    {
                        foreach my $segment ( @{ $old_sections{$section} })
                        {
                            print $output_file " :phdr${segment}";
                        }
                    }
                    
                    print $output_file "\n" if defined $old_sections{$section};
                    
                    last;
                }
            }
            else
            {
                if( $line =~ m/\{/ )
                {
                    $bracket_found = 1;
                    next;
                }
            }
            
            print $output_file $line if defined $old_sections{$section};
            
            $line = shift @old_script;
            if( $line =~ m/==================================================/ || scalar @old_script == 0 )
            {
                die "Ran out of script while processing section |$section|\n\n";
            }
        }
        
        next;
    }
    
    print $output_file $line;
}

exit 0;
