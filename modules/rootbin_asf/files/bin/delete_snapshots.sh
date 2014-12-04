#!/bin/sh

PATH=/usr/bin:/bin:/usr/sbin:/sbin

# This sorts snapshots alphabetically, so the daily `date +%Y%m%d` snapshots
# sort first and are those that get deleted.

# delete all but the last 30 snapshots
zfs list -H -t snapshot \
| perl -le '@s=sort map {(split)[0]} <>; print for @s[0..($#s - 30)]' \
| xargs -n 1 zfs destroy 
