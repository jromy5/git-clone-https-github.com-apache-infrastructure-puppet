#!/bin/sh

bzip2=/usr/bin/bzip2

vc_logdir=/var/log/vc
vc_logarchive=/logarchive/vc
vc_errorarcdir=$vc_logarchive/errors

date=`date +"%Y/%m/%d"`
datedir=`date +"%Y/%m/"`

mv $vc_logdir/access_log $vc_logdir/access_log.0
mv $vc_logdir/error_log $vc_logdir/error_log.0
mv $vc_logdir/operation_log $vc_logdir/operation_log.0

sleep 59

# echo "logfiles moved, now restarting daemons"
/usr/local/etc/rc.d/vc-httpd.sh restart

# Sleep for 20 minutes so that old gracefully-finishing
# httpd children will log to the correct logfile.
sleep 1200


# echo "Now moving vc.apache.org logfiles to $vc_logarchive" 
mkdir -p $vc_logarchive/$datedir $vc_errorarcdir/$datedir
mv $vc_logdir/access_log.0 $vc_logarchive/$date
mv $vc_logdir/error_log.0 $vc_errorarcdir/$date
mv $vc_logdir/operation_log.0 $vc_logarchive/$date-operation

# echo "Now compressing vc.apache.org logfiles" 
$bzip2 -9 $vc_logarchive/$date
$bzip2 -9 $vc_logarchive/$date-operation
$bzip2 -9 $vc_errorarcdir/$date
