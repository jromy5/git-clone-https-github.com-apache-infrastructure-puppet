#!/bin/sh

instance=ooo-wiki2
logprefix=

bzip2=/bin/bzip2

wwwlogdir=/x1/log/apache2
logarchive=/x1/logarchive/$instance
errorarcdir=$logarchive/errors

date=`date +"%Y%m%d"`
dayfile=`date +"%Y/%m/%d"`
monthdir=`date +"%Y/%m/"`

mv $wwwlogdir/${logprefix}access.log $wwwlogdir/${logprefix}access.log.0
mv $wwwlogdir/${logprefix}error.log $wwwlogdir/${logprefix}error.log.0

sleep 59

# echo "logfiles moved, now restarting daemons"
/etc/init.d/${instance} graceful

# sleep for 20 minutes so that old gracefully-finishing httpd children will
# log to the logfile.
sleep 1200
# echo "Now moving logiles to $logarchive"
mkdir -p $logarchive/$monthdir
mv $wwwlogdir/${logprefix}access.log.0 $logarchive/$dayfile
mv $wwwlogdir/${logprefix}error.log.0 $errorarcdir/${logprefix}error.log_$date

# echo "Now compressing logfiles"
$bzip2 -9 $logarchive/$dayfile
$bzip2 -9 $errorarcdir/error.log_$date

find $errorarcdir -mtime +31 -type f -exec rm \{\} \;
