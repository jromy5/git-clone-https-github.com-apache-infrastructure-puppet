#!/bin/sh
# rsync script to sync selected allura-vm stuff to abi

DAY=`/bin/date +%Y%m%d`
FIVE_DAYS_OLD=`/bin/date --date '5 days ago' +%Y%m%d`
OLD_LOG=/root/rsynclogs/backups-allura-$FIVE_DAYS_OLD.log
STUNNEL_BIN=/usr/bin/stunnel4

# New log file created daily.
$STUNNEL_BIN "`dirname $0`"/stunnel.conf
sleep 1
/usr/bin/rsync -rlRtz \
--log-file=/root/rsynclogs/backups-allura-$DAY.log \
--password-file=/root/.pw-abi \
--include allura \
--include activitystream \
--include project-data \
--include task \
--exclude '\*' \
--delete /var/local/backups/dump/ rsync://apb-allura@localhost:1873/allura-vm2/
kill `cat /home/apbackup/rsynclogs/stunnel.pid`

# Clean up five day old logs, not rotating, no need to keep more than five.

  if [ -f $OLD_LOG ]; then
          rm -f $OLD_LOG
  fi
