#!/bin/sh

bzip2=/usr/bin/bzip2

wwwlogdir=/var/log
mainbz_logarchive=/logarchive/mainbz
sabz_logarchive=/logarchive/sabz
mainbz_errorarcdir=$mainbz_logarchive/errors
sabz_errorarcdir=$sabz_logarchive/errors

date=`date +"%Y/%m/%d"`
datedir=`date +"%Y/%m/"`

mv $wwwlogdir/httpd-mainbz-access.log $wwwlogdir/httpd-mainbz-access.0
mv $wwwlogdir/httpd-mainbz-error.log $wwwlogdir/httpd-mainbz-error.0
mv $wwwlogdir/httpd-sabz-access.log $wwwlogdir/httpd-sabz-access.0
mv $wwwlogdir/httpd-sabz-error.log $wwwlogdir/httpd-sabz-error.0

sleep 59

# echo "logfiles moved, now restarting daemons"
/usr/local/etc/rc.d/apache22 graceful > /dev/null

# sleep for 20 minutes so that old gracefully-finishing httpd children will
# log to the logfile.
sleep 1200
mkdir -p $mainbz_logarchive/$datedir
mv $wwwlogdir/httpd-mainbz-access.0 $mainbz_logarchive/$date
mv $wwwlogdir/httpd-mainbz-error.0 $mainbz_errorarcdir

mkdir -p $sabz_logarchive/$datedir
mv $wwwlogdir/httpd-sabz-access.0 $sabz_logarchive/$date
mv $wwwlogdir/httpd-sabz-error.0 $sabz_errorarcdir

$bzip2 -9 $mainbz_logarchive/$date
rm $mainbz_errorarcdir/httpd-mainbz-err*.bz2
$bzip2 -9 $mainbz_errorarcdir/httpd-mainbz-error*

$bzip2 -9 $sabz_logarchive/$date
rm $sabz_errorarcdir/httpd-sabz-err*.bz2
$bzip2 -9 $sabz_errorarcdir/httpd-sabz-error*
