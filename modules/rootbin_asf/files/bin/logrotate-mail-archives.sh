#!/bin/sh

instance=mail-archives
logprefix=mail_

bzip2=/usr/bin/bzip2

wwwlogdir=/x1/log/www
logarchive=/x1/logarchive/$instance
errorarcdir=$logarchive/errors

date=`date +"%Y%m%d"`
dayfile=`date +"%Y/%m/%d"`
monthdir=`date +"%Y/%m/"`

mv $wwwlogdir/${logprefix}weblog $wwwlogdir/${logprefix}weblog.0
mv $wwwlogdir/${logprefix}error_log $wwwlogdir/${logprefix}error_log.0

sleep 59

# echo "logfiles moved, now restarting daemons"
/usr/local/etc/rc.d/${instance}-httpd.sh graceful

# sleep for 20 minutes so that old gracefully-finishing httpd children will
# log to the logfile.
sleep 1200
# echo "Now moving logfiles to $logarchive" 
mkdir -p $logarchive/$monthdir
mv $wwwlogdir/${logprefix}weblog.0 $logarchive/$dayfile
mv $wwwlogdir/${logprefix}error_log.0 $errorarcdir/error_log_$date

# echo "Now compressing logfiles" 
$bzip2 -9 $logarchive/$dayfile
$bzip2 -9 $errorarcdir/error_log_$date
find $errorarcdir -mtime +31 -type f -exec rm \{\} \;
