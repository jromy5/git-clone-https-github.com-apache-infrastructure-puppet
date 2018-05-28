#!/bin/bash

# extract mailing list moderators and subcribers for use by Whimsy
#
# ezmlm-list is fairly slow, so this script caches the output in a parallel directory tree.
# If the Log file has changed since the last run, then the corresponding subscriber list is regenerated.
#
# Once the initial lists have been created, the script runs in a few seconds
#

# N.B.
# The script currently requires some command parameters that may not be universally available:
# stat -s
# date -r

 
log() {
    echo $(date): "$@"
}

TZ=GMT
export TZ

EZMLM_LIST=/usr/local/bin/ezmlm-list

# Base location for all files
BASE=${1:-$HOME/MODSUBS}
test -d $BASE || { echo "Cannot find output $BASE" ; exit 1; }

# where to cache the list meta data
CACHE=$BASE/cache
test -d $CACHE || mkdir $CACHE || { echo "Cannot create cache dir $CACHE" ; exit 1; }

# where to create the output files
DATA=$BASE/data
test -d $DATA || mkdir $DATA || { echo "Cannot create data dir $DATA" ; exit 1; }

# where to put the logs
LOGS=$BASE/logs
test -d $LOGS || mkdir $LOGS || { echo "Cannot create log dir $LOGS" ; exit 1; }

LOG=$LOGS/log

# rotate logs; one for each day of a month (DOM)
if [ -r $LOG ]
then
    # is the log DOM the same as today's?
    # date -r file does not work on hermes
    eval $(stat -s $LOG)
    OLD=$(date -r $st_mtime '+%d')

    NOW=$(date '+%d')
    if [ "$OLD" != "$NOW" ]
    then
        mv $LOG $LOGS/log_$OLD
    fi
fi

# Logs are cumulative, but rotated as above
exec >> $LOG 2>&1 || exit
# It seems that &> is not supported everywhere; use standard syntax

log Started

MODSEEN=0
SUBSEEN=0
DIGSEEN=0

START=$DATA/list-start

# where the input lists are
cd /home/apmail/lists || { echo "Cannot find input lists" ; exit 1; }

touch $START || exit 1

#
# The shell appears to be able to compare file times quite accurately.
# However updates to subscribers lists can occur at around the same time
# as the output file is created. To avoid possible missed updates, the output file
# mtime must be set back to before the change was detected.
# One way to do this is to use the time of the START marker file.
# A minor disadvantage is that this will be earlier than any checks, so may cause some
# changes to be re-detected on the next run.
# However this should be infrequent, as the run only takes a few seconds once the initial data
# has been collected. And it is much better than losing an update.

for domain in */ # only match dirs
do
    dom=${domain%/}
    pushd $dom &> /dev/null || continue
    for l in */
    do
        list=${l%/}
        if [ "$list" == "*" ]
        then
           log $dom is empty
           continue
        fi
        MLOG=${list}/mod/Log
        if [ -f $MLOG ]
        then
            #log $dom $list
            DOM=$CACHE/$dom
            LIST=$DOM/$list
            test -d $DOM  || { log New domain $dom; mkdir -p $DOM; }
            test -d $LIST || { log New list $dom/$list; mkdir -p $LIST; }
            touch $LIST # last seen date for list
            touch $DOM # last seen date for dom
            MOD=$LIST/mod
            if [ $MOD -ot $MLOG ]
            then
                log Updating $MOD
                ${EZMLM_LIST} $list mod > $MOD
                if [ $? -eq 0 ]
                then
                    touch -r $START $MOD # ensure we pick up contemporaneous changes
                else
                    rm $MOD # could not extract data, don't create output
                fi
                MODSEEN=1
            else
                : log $MOD is up to date
            fi
            SUB=$LIST/sub
            SLOG=${list}/Log
            if [ $SUB -ot $SLOG ]
            then
                log Updating $SUB
                ${EZMLM_LIST} $list .  > $SUB
                if [ $? -eq 0 ]
                then
                    touch -r $START $SUB # ensure we pick up contemporaneous changes
                else
                    rm $SUB # could not extract data, don't create output
                fi
                SUBSEEN=1
            else
                : log $SUB is up to date
            fi
            DIG=$LIST/dig
            DLOG=${list}/digest/Log
            if [ $DIG -ot $DLOG ]
            then
                log Updating $DIG
                ${EZMLM_LIST} $list digest  > $DIG
                # only keep non-empty digests
                if [ $? -eq 0 -a -s $DIG ]
                then
                    touch -r $START $DIG # ensure we pick up contemporaneous changes
                else
                    rm $DIG # could not extract data or no data, don't create output
                fi
                DIGSEEN=1
            else
                : log $DIG is up to date
            fi
        else
            # Suppress an unnecessary error message
            if [ "$dom" != 'nifi.apache.org' -o "$list" != 'security.old' ]
            then
                log "$dom $list is empty or inaccessible"
            fi
        fi
    done
    popd >/dev/null
done

cd $CACHE

# Delete directories that were not updated this pass
for list in */*
do
    if [ $list -ot $START ]
    then
        log Removing $list as it is old
        rm -rf $list
        # Ensure lists are recreated to drop old entries
        MODSEEN=1
        SUBSEEN=1
        DIGSEEN=1
    fi
done

# Now remove any empty parents
for list in */
do
    if [ $list -ot $START ]
    then
        log Removing $list as it is old and empty
        rmdir $list
        # No need to recreate lists for these
    fi
done

if [ "$MODSEEN" == 1 -o ! -r $DATA/list-mods ]
then
    log Creating list-mods
    for list in */*
    do
        # Format must agree with whimsy/asf/mlist.rb
        echo
        echo /home/apmail/lists/$list/mod
        cat $list/mod
    done >$DATA/list-mods
fi

if [ "$SUBSEEN" == 1 -o ! -r $DATA/list-subs ]
then
    log Creating list-subs
    for list in */*
    do
        # Format must agree with whimsy/asf/mlist.rb
        echo
        echo /home/apmail/lists/$list
        cat $list/sub
    done >$DATA/list-subs
fi

if [ "$DIGSEEN" == 1 -o ! -r $DATA/list-digs ]
then
    log Creating list-digs
    for list in */*
    do
        # Format must agree with whimsy/asf/mlist.rb
        # Only copy digests that exist
        if [ -f $list/dig ]
        then
            echo
            echo /home/apmail/lists/$list
            cat $list/dig
        fi
    done >$DATA/list-digs
fi

# Push the data to Whimsy
rsync -avz $DATA/ whimsy.apache.org:/srv/subscriptions/

log Ended
