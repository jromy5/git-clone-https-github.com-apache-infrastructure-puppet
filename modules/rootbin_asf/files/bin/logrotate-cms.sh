#!/bin/sh

bzip2=/usr/bin/bzip2

wwwlogdir=/var/log
logarchive=/x1/logarchive/cms
errorarcdir=$logarchive/errors

date=`date +"%Y/%m/%d"`
datedir=`date +"%Y/%m/"`

mv $wwwlogdir/httpd-access.log $wwwlogdir/httpd-access.0
mv $wwwlogdir/httpd-error.log $wwwlogdir/httpd-error.0

sleep 59

# echo "logfiles moved, now restarting daemons"
/usr/local/etc/rc.d/httpd reload >/dev/null 2>&1
if [ $? -ne 0 ]; then
   echo "httpd reload failed!"
   exit 1
fi

# sleep for 20 minutes so that old gracefully-finishing httpd children will
# log to the logfile.
sleep 1200
# echo "Now moving logfiles to $logarchive" 
mkdir -p $logarchive/$datedir
mv $wwwlogdir/httpd-access.0 $logarchive/$date
mv $wwwlogdir/httpd-error.0 $errorarcdir

# echo "Now compressing logfiles" 
$bzip2 -9 $logarchive/$date
rm $errorarcdir/httpd-err*.bz2
$bzip2 -9 $errorarcdir/httpd-error*
