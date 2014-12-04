#!/bin/sh

PATH=/bin:/sbin:/usr/bin:/usr/sbin

if [ -n "$1" ]; then
  jails=$1
else
  jails=$(cd /jails ; ls -1)
fi

date=$(date +"%Y%m%d_%H%M%S")

zfs snapshot zroot/usr/ports@${date}

for jail in $jails; do
  D=/jails/$jail
  zfs destroy zroot$D/usr/ports 2>/dev/null
  zfs clone zroot/usr/ports@${date} zroot$D/usr/ports
done
