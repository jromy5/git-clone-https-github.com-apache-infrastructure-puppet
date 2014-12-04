#!/bin/sh

PATH="/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin"

if [ -t 0 ]; then :; else
  echo "crontabs.sh shouldn't be used from cron" >&2
  exit 1
fi

OSNAME=`uname -s`
case "$OSNAME" in
  SunOS) 
    SVN_BIN=/opt/subversion-current/bin/svn
    cd /var/spool/cron/crontabs
    ;;
  Linux)
    SVN_BIN=`which svn`
    cd /var/spool/cron/crontabs
    ;;
  *) 
    SVN_BIN=`which svn`
    cd /var/cron/tabs
    ;;
esac

$SVN_BIN --username apmail cleanup
$SVN_BIN --username svn up > /dev/null
chmod 600 *

case "$OSNAME" in
  Linux)
    for c in `ls -1 *`; do
      chown $c $c
    done
    ;;
esac

if [ -d /home/apmail/bin ]; then
  cd /home/apmail/bin
  $SVN_BIN --username apmail cleanup
  $SVN_BIN --username apmail up > /dev/null
fi
