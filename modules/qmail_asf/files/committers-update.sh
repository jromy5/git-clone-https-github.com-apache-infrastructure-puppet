#!/bin/bash

# Script to update committers@a.o subscriptions

CURRENT=/tmp/committers-current.$$
TARGET=/tmp/committers-future.$$

cleanup() {
    rm -f $CURRENT $TARGET
}
trap cleanup EXIT

# Current list of subscribers
ezmlm-list ~apmail/lists/apache.org/committers . | sort -o $CURRENT

# Get the current committers, then add archivers
{
ldapsearch -x -LLL cn=committers memberUid | perl -nle 's/^memberUid: (.+)/$1\@apache.org/ and print'
cat <<EOD
archive-asf-private@cust-asf.ponee.io
committers-archive@apache.org
private@mbox-vm.apache.org
EOD
} | sort -o $TARGET

# Use xargs to ensure avoid calling ezmlm if there are no changes without needing to store the result

# missing from current list: i.e. in target but not current
comm -13 $CURRENT $TARGET | xargs ezmlm-sub ~apmail/lists/apache.org/committers . 

# Surplus in current list: i.e. in current list but not on target
comm -23 $CURRENT $TARGET | xargs ezmlm-unsub ~apmail/lists/apache.org/committers . 
