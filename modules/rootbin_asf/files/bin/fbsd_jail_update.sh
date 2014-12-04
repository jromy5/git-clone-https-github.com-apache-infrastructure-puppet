#!/bin/sh

PATH=/bin:/sbin:/usr/bin:/usr/sbin

if [ -n "$1" ]; then
  jails=$1
  for jail in $jails; do
    D=/jails/$jail
    if [ -d "$D" ]; then
      :
    else
      echo "$0: error: jail $jail does not exist in /jails" >&2
      exit 1
    fi
  done
else
  jails=$(cd /jails ; ls -1)
fi

date=$(date +"%Y%m%d_%H%M%S")

cd /usr/src

for jail in $jails; do
  D=/jails/$jail

#  zfs snapshot zroot$D@before_update-${date}

  make installworld -j12 DESTDIR=$D
  make delete-old BATCH_DELETE_OLD_FILES=yes DESTDIR=$D

  ### XXX: do NOT run this until you've updated EVERY port in the jail
  ### make delete-old-libs BATCH_DELETE_OLD_FILES=yes DESTDIR=$D
done

for jail in $jails; do
  D=/jails/$jail

  mergemaster -i -U -D $D
done

for jail in $jails; do
  D=/jails/$jail

#  zfs snapshot zroot$D@after_update-${date}
done
