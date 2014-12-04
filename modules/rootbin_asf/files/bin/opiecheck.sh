#!/bin/sh

PATH="/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin"

OPIEKEYS=/etc/opiekeys
ORTHRUSKEYS=/etc/orthruskeys
OSNAME=`uname -s`
case "$OSNAME" in
  FreeBSD) group=wheel;;
  Linux)   group=admin;;
  SunOS)   group=staff;;
esac

root_users=`getent group $group | sed -e 's,.*:,,' -e 's/root,//' -e 's/,/ /g'`

if [ -f $OPIEKEYS ]; then
  for user in $root_users; do
    rc=`grep -c $user $OPIEKEYS`
    if [ $rc -ne 1 ] && getent passwd $user 2>&1 >/dev/null; then
      echo "$user must configure opie"
    fi
  done
elif [ -f $ORTHRUSKEYS ]; then
  for user in $root_users; do
    rc=`grep -c $user $ORTHRUSKEYS`
    if [ $rc -ne 1 ] && getent passwd $user 2>&1 >/dev/null; then
      echo "$user must configure orthrus"
    fi
  done
else
  echo "OPIE/ORTHRUS are not installed ($OPIEKEYS nor $ORTHRUSKEYS do not exist)"
fi
