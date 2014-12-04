#!/bin/sh

# Kill all puppet processes which have
# a zombie child older than one day.

# ps "-o" format flags are linux specific.
# Similar flags with different names exist for
# BSD and Solaris as well.

pids=`pgrep puppet`
for pid in $pids
do
    # Get newest child
    childpid=`pgrep -n -P $pid`
    if [ "X$childpid" != "X" ]
    then
        # Check for zombie older than one day
        ps --no-headers -o s,etime -p $childpid | \
            egrep '^Z +[0-9]+-' > /dev/null 2>&1
        if [ $? -eq 0 ]
        then
            echo "Killing puppet process '`ps --no-headers -o pid,ppid,uid,stime,etime,cputime,args -p $pid`'"
            echo "   having zombie child '`ps --no-headers -o pid,ppid,uid,stime,etime,cputime,args -p $childpid`'"
            kill $pid
        fi
    fi
done
