#!/bin/sh

## ============================================================================
# Helper script to check for new Debian OS updates.
#
# Copyright (c) 2004-2005 Erik Abele <erik@codefaktor.de>.
# All rights reserved.
## ============================================================================

MAILTO=root
export LANGUAGE=en

UPDATE=`apt-get update 2>&1`
RET=$?

if [ $RET -gt 0 ]; then
	echo $UPDATE | mail -s "`hostname` - APT update failed" $MAILTO
	exit 1
fi

PKGSUPGR=`apt-get -s upgrade | egrep '[0-9]+ upgraded' | awk '{ print $1 }'`

if [ $PKGSUPGR -gt 0 ]; then
	apt-get -s upgrade | \
		mail -s "`hostname` - $PKGSUPGR updated packages available" $MAILTO
fi

exit 0

