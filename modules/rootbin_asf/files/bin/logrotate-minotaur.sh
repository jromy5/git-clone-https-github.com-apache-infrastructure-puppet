#!/bin/sh

bzip2=/usr/bin/bzip2

wwwlogdir=/var/log/www
logarchive=/x1/logarchive/www
people_logarchive=/x1/logarchive/people
errorarcdir=$logarchive/errors
people_errorarcdir=$people_logarchive/errors

date=`date +"%Y/%m/%d"`
datedir=`date +"%Y/%m/"`

mv $wwwlogdir/weblog $wwwlogdir/weblog.0
mv $wwwlogdir/error_log $wwwlogdir/error_log.0
mv $wwwlogdir/people_access_log $wwwlogdir/people_access_log.0
mv $wwwlogdir/people_error_log $wwwlogdir/people_error_log.0

sleep 59

# echo "logfiles moved, now restarting daemons"
/usr/local/apache2-install/www.apache.org/current/bin/apachectl graceful
/usr/local/apache2-install/people.apache.org/current/bin/apachectl graceful

# Sleep for 20 minutes so that old gracefully-finishing
# httpd children will log to the correct logfile.
sleep 1200

# echo "Now moving www.apache.org logfiles to $logarchive" 
mkdir -p $logarchive/$datedir $errorarcdir
mv $wwwlogdir/weblog.0 $logarchive/$date
mv $wwwlogdir/error_log.0 $errorarcdir/

# echo "Now moving people.apache.org logfiles to $people_logarchive" 
mkdir -p $people_logarchive/$datedir $people_errorarcdir
mv $wwwlogdir/people_access_log.0 $people_logarchive/$date
mv $wwwlogdir/people_error_log.0 $people_errorarcdir/error_log.0

# echo "Now compressing www.apache.org logfiles" 
$bzip2 -9 $logarchive/$date
rm $errorarcdir/err*.bz2
$bzip2 -9 $errorarcdir/err*

# echo "Now compressing people.apache.org logfiles" 
$bzip2 -9 $people_logarchive/$date
rm $people_errorarcdir/err*.bz2
$bzip2 -9 $people_errorarcdir/err*
