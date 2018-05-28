#!/bin/bash

# This file is managed by puppet, see modules:qmail_asf/files/bin/list_traverse.sh

# include some standard path variables

source common.conf

# traverse mailing lists and apply a command to each
#
# find is rather slow for this purpose

# Sample:
# list_traverse.sh 'echo $LT_DOM $LT_LIST ; ezmlm-list . digest'
# list_traverse.sh script.sh
 
log() {
    echo $(date): "$@"
}

TZ=GMT
export TZ

# where the input lists are
cd $LISTS_DIR || { echo "Cannot find input lists" >&2 ; exit 1; }

for domain in */ # only match dirs
do
    dom=${domain%/}
    pushd $dom &> /dev/null ||  { log "$dom is inaccessible" ; continue ; }
    for l in */
    do
        list=${l%/}
        if [ "$list" == "*" ]
        then
           log $dom is empty
           continue
        fi
        pushd $list &> /dev/null || { log "$dom $list is inaccessible" ; continue ; }
        MLOG=mod/Log
        SLOG=Log
        if [ -f $MLOG -a -f $SLOG ]
        then
            # process 
            if [ -z "$1" ]
            then
                echo "$list $dom"
            else
               # pass parameters as variables to make it easier to use them singly
               LT_LIST=$list LT_DOM=$dom eval $1
            fi
        else
            # Weed out some old partial lists
            case "$list@$dom" in
                planners-old@apachecon.com) ;;
                speakers-old[23]@apachecon.com) ;;
                security.old@nifi.apache.org) ;;
                # Log an error for anything else
                *) log "$dom $list is empty or inaccessible (cannot access Log and/or mod/Log)" ;;
            esac
        fi
        popd >/dev/null
    done
    popd >/dev/null
done
