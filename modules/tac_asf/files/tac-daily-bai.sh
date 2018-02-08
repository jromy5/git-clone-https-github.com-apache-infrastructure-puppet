#!/bin/sh
# rsync script to sync selected tac-vm stuff to abi

DAY=`/bin/date +%Y%m%d`
FIVE_DAYS_OLD=`/bin/date --date '5 days ago' +%Y%m%d`
OLD_LOG=/root/rsynclogs/backups-tac-$FIVE_DAYS_OLD.log
STUNNEL_BIN=/usr/bin/stunnel4

# New log file created daily.
$STUNNEL_BIN "`dirname $0`"/stunnel.conf
sleep 1
/usr/bin/rsync -rlRtz \
--log-file=/root/rsynclogs/backups-tac-$DAY.log \
--password-file=/root/.pw-abi \
  /x1/db_dump rsync://apb-tacvm@localhost:1873/tac-vm/

# Clean up five day old logs, not rotating, no need to keep more than five.

  if [ -f $OLD_LOG ]; then
          rm -f $OLD_LOG
  fi
