#!/bin/sh

source common.conf

if [ $# -lt 1 ]; then
    echo Usage: scanall email@address
    exit 1
fi

cd $LISTS_DIR

for i in `ls -F | grep /`
do
(
cd $i
pwd=`pwd`
for j in  `ls -F | grep /`
do
if [ -d $pwd/$j/subscribers ]; then
    for m in $*
    do
        [ -f $pwd/$j/Log ] && grep -qi $m $pwd/$j/Log && ezmlm-list $pwd/$j | grep -qix $m && ezmlm-unsub $pwd/$j . $m  && echo removed $m from $j/$i
    done
fi
if [ -d $pwd/$j/digest ]; then
        for m in $*
        do
                [ -f $pwd/$j/digest/Log ] && grep -qi $m $pwd/$j/digest/Log && ezmlm-list $pwd/$j digest | grep -qix $m && ezmlm-unsub $pwd/$j digest $m  && echo removed $m from Digest list for $j/$i
        done
fi
if [ -d $pwd/$j/allow ]; then
        for m in $*
        do
                [ -f $pwd/$j/allow/Log ] && grep -qi $m $pwd/$j/allow/Log && ezmlm-list $pwd/$j allow | grep -qix $m && ezmlm-unsub $pwd/$j allow $m  && echo removed $m from Allow list for $j/$i
        done
fi
if [ -d $pwd/$j/mod ]; then
        for m in $*
        do
                [ -f $pwd/$j/mod/Log ] && grep -qi $m $pwd/$j/mod/Log && ezmlm-list $pwd/$j mod | grep -qix $m && ezmlm-unsub $pwd/$j mod $m  && echo removed $m from Moderator list for $j/$i
        done
fi
done
)
done
