package Monitor;
use strict;
use warnings;

## I only take care of launching processes without launching too many.
## If there is a problem, I do no cleanup, sorry.
sub do_work
{
    my $work = shift;
    my $num_tasks = 0;
    
    my $max_tasks = $work->{'max_tasks'};
    my $tasks = $work->{'tasks'};
    my %pids = ();
    
    while(1)
    {
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
