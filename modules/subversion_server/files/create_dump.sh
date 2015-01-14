#!/bin/sh

PATH="/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin"

SVNLOOK_BIN=`which svnlook`
SVN_BIN=`which svn`

usage() {

    echo >&2
    echo >&2 "Usage:"
    echo >&2 "$0 [-hv]"

    exit 1
}

Verbose=0

while getopts hv o; do
    case "$o" in
        h) usage;;
        v) Verbose=1;;
    esac
done

if [ $Verbose -eq 1 ]; then
    set -x
fi

## directories
root=/x1/svn
asf=$root/repos/asf
dumps=$root/dump
tmp_dumps=/dump-tmp
tmp_interim=$root/dump-tmp
statefile=$dumps/.youngest-dumped

## from $statefile+1 to current svn rev
current=`svnlook youngest $asf`
start=`expr 1 + \`cat $statefile\``
end=$current

## dump it a tmp space to prevent people from attempting to use partials
tmp_dump=$tmp_dumps/svn-asf-public-r$start:$end
nice -3 svnadmin dump $asf --incremental --deltas -q -r$start:$end > $tmp_dump
nice -3 p7zip $tmp_dump > /dev/null

## 'sign it'
tmp_dump=$tmp_dump.7z
md5sum $tmp_dump > $tmp_dump.md5
sha256sum $tmp_dump > $tmp_dump.sha256
sha1sum $tmp_dump > $tmp_dump.sha1

## mv the new ones into place
mv $tmp_dumps/* $tmp_interim && mv $tmp_interim/* $dumps

## I don't want to do all that work again!
echo $end > $statefile

exit 0
