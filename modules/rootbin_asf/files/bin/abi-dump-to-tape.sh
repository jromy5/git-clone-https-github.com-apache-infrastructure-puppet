#!/bin/sh 

ZFS_BIN=/sbin/zfs
DATE_BIN=/bin/date
GREP_BIN=/usr/bin/grep
AWK_BIN=/usr/bin/awk
WC_BIN=/usr/bin/wc
GZIP_BIN=/usr/bin/gzip
CHIO_BIN=/bin/chio
TAPE_CHGR=/dev/ch0
TAPE_DRIVE=/dev/sa0
TODAY=`$DATE_BIN +%Y%m%d`
YESTERDAY=`$DATE_BIN -v -1d +%Y%m%d`
FIRST_MONTH=`$DATE_BIN +%Y%m01`
MONTH=`$DATE_BIN +%m`
LAST_MONTH=`$DATE_BIN -v -1m +%m`
SNAP_LIST=/tmp/snapshot.list.$TODAY


echo "Tape changer status :: $TODAY"
$CHIO_BIN status

## If today is the start of the month, we should force a new tape to be loaded.

if [ "$TODAY" = "$FIRST_MONTH" ]; then
  echo "Today is the first of the month. Moving tapes..."
  echo "Moving tape from drive to ** SLOT $LAST_MONTH **"
  $CHIO_BIN -f $TAPE_CHGR move drive 0 slot $LAST_MONTH || echo "The tape move failed. This needs investigating" ; exit 1 
  echo "Tape was successfully moved to slot $LAST_MONTH, it is now ready for ejection"
  echo "Moving this month's tape into the drive..."
  echo "Moving ** SLOT $MONTH to the drive"
  $CHIO_BIN -f $TAPE_CHGR move slot $MONTH to drive 0 || echo "The tape move failed. This needs investigating" ; exit 2
  echo "The tape in the drive is now ready for use"
fi

TAPEINDRIVE=`$CHIO_BIN status -v | $GREP_BIN drive | $AWK_BIN '{print $3}'`

if [ "$TAPEINDRIVE" = "<ACCESS,FULL>" ]; then
   echo "The tape drive is ready, proceeding to copy data"
else
   echo "There doesn't appear to be a valid tape in the drive.  Exiting now to prevent automated idiocy..."  
   exit 3
fi

## Build list of snapshots for today
$ZFS_BIN list -t snapshot | $GREP_BIN $TODAY | $AWK_BIN '{print $1}' > $SNAP_LIST


## Check that we actually have something to copy...
COUNT=`$WC_BIN -l $SNAP_LIST | $AWK_BIN '{print $1}'`
if [ ${COUNT} -lt 1 ] ; then 
  echo 'It seems we do not have any snapshots to send to tape. This is rather unexpected. Exiting.'
  exit 4 
fi


for snapshot in `cat $SNAP_LIST` ; do
  $ZFS_BIN send $snapshot | $GZIP_BIN -3 > $TAPE_DRIVE || echo "*** Failed to send data to tape ***" ; exit 5
  ## Not enabled yet, until we have tape confidence. 
  # $ZFS_BIN destroy $snapshot || exit 6
done

echo "Backup of snapshots for $TODAY sent to drive at /dev/sa0"

echo "Tape changer status at the end of the job:"
$CHIO_BIN status -v
