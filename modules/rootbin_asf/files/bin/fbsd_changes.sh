#!/bin/sh

PATH="/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin"

CVSROOT=freebsdanoncvs@anoncvs.FreeBSD.org:/home/ncvs
CVS_RSH=ssh
CVS="cvs -q -z3"

yesterday=`date -v-1d "+%Y/%m/%d"`

header "ports changes"
$CVS -d $CVSROOT rdiff -u -D$yesterday ports/MOVED ports/CHANGES ports/KNOBS ports/UIDs ports/GIDs ports/UPDATING

header "src changes"
$CVS -d $CVSROOT -rRELENG_8 rdiff -u -D$yesterday src/UPDATING src/LOCKS src/MAINTAINERS
