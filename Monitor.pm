package Monitor;
use strict;
use warnings;

our $max_tasks;
our $max_tasks_from_file;

sub update_max_tasks
{
    while(1)
    {
        my $new_max_tasks;
        my $max_handle;
        unless( open( $max_handle, "<", './max_tasks.txt' ) )
        {
            print "WARNING: Can't open |./max_tasks.txt|: says |$!|\n";
            print "WARNING: Fix this ex: |echo 2 > max_tasks.txt| sleeping for 5 minutes.\n";
            sleep 300;
            next;
        }
        
        my $line;
        unless( (defined $max_handle) && ($line = <$max_handle>) )
        {
            print "WARNING: file |./max_tasks.txt|: is empty\n";
            print "WARNING: Fix this ex: |echo 2 > max_tasks.txt| sleeping for 5 minutes.\n";
            close $max_handle;
            sleep 300;
            next;
        }
        
        unless( $line =~ m/\A([1-9]{1}[0-9]{0,2})\Z/ )
        {
            chomp $line;
            print "WARNING: file |./max_tasks.txt|: contains a value |$line| that is not an integer <= 999\n";
            print "WARNING: Fix this ex: |echo 2 > max_tasks.txt| sleeping for 5 minutes.\n";
            close $max_handle;
            sleep 300;
            next;
        }
        
        $new_max_tasks = $1;
        if( $new_max_tasks != $max_tasks )
        {
            print "STATUS: updating max_tasks from |$max_tasks| to |$new_max_tasks|\n";
            $max_tasks = $new_max_tasks;
        }
        
        last;
    }
}

## I only take care of launching processes without launching too many.
## If there is a problem, I do no cleanup, sorry.
sub do_work
{
    my $work = shift;
    my $num_tasks = 0;
    
    $max_tasks = $work->{'max_tasks'};
    my $tasks = $work->{'tasks'};
    my %pids = ();
    
    if( $max_tasks < 1 )
    {
        print "STATUS: max_tasks = |${max_tasks}| reading max_tasks from file |./max_tasks.txt|\n";
        $max_tasks_from_file = 1;
    }
    else
    {
        print "STATUS: max_tasks = |${max_tasks}| not reading max_tasks from file |./max_tasks.txt|\n";
        $max_tasks_from_file = 0;
    }
    
    while(1)
    {
        if( $max_tasks_from_file )
        {
            update_max_tasks();
        }
        
        while( ((scalar @{$tasks}) > 0 ) && ( $num_tasks < $max_tasks ) )
        {
            my $task = shift @{$tasks};
            
            my $args = $task->{'args'};
            my $func = $task->{'func'};
            my $msg  = $task->{'msg'};
            my $pid  = fork();
            
            die "Problem forking child |$!|\n\n" if $pid == -1;
            
            if( $pid == 0 )
            {
                ## I am the child
                $func->($args);
                exit 0;
            }
            
            ## I am the parent
            $num_tasks++;
            $pids{$pid} = $msg;
            print "Started: $pid: ";
            print $pids{$pid};
            print "\n";
        }
        
        if( $num_tasks == 0 )
        {
            last;
        }
        else
        {
            my $pid = wait();
            
            die "Problem waiting for children |S!|\n\n" if $pid == -1;
            
            $num_tasks--;
            print "Completed: $pid: ";
            print $pids{$pid};
            print "\n";
            
            undef $pids{$pid};
        }
    }
    
    print "All tasks completed.\n\n";
}

1;
