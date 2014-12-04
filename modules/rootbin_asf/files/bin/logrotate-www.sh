#!/bin/sh

instance=www
logprefix=

bzip2=/usr/bin/bzip2
fail2banclient=/usr/local/bin/fail2ban-client

wwwlogdir=/x1/log/www
logarchive=/x1/logarchive/$instance
errorarcdir=$logarchive/errors
abuserarcdir=$logarchive/abusers

tab=`printf "\t"`
date=`date +"%Y%m%d"`
dayfile=`date +"%Y/%m/%d"`
monthdir=`date +"%Y/%m/"`

mv $wwwlogdir/${logprefix}weblog $wwwlogdir/${logprefix}weblog.0
mv $wwwlogdir/${logprefix}error_log $wwwlogdir/${logprefix}error_log.0
if [ -f $wwwlogdir/${logprefix}wiki_error_log ]
then
    mv $wwwlogdir/${logprefix}wiki_error_log $wwwlogdir/${logprefix}wiki_error_log.0
fi

sleep 59

# echo "logfiles moved, now restarting daemons"
/usr/local/etc/rc.d/${instance}-httpd.sh graceful

# sleep a few seconds so that the new error log gets written,
# then switch fail2ban out of a possible idle mode
if [ -x $fail2banclient ]
then
    sleep 20
    jails=`$fail2banclient status | \
        awk -F"$tab" '/Jail list:/ {print $NF}' | \
        sed -e 's# ##g' | \
        tr ',' '\n'`
    for jail in $jails
    do
        # Unfortunatly fail2ban uses the error log in /var/log,
        # so we can not use $wwwlogdir here
        $fail2banclient get $jail logpath | \
            egrep -e '/www/(wiki_)?error_log$' > /dev/null 2>&1
        if [ $? -eq 0 ]
        then
            $fail2banclient set $jail idle off > /dev/null
        fi
    done
fi

# sleep for 20 minutes so that old gracefully-finishing httpd children will
# log to the logfile.
sleep 1200
# echo "Now moving logfiles to $logarchive" 
mkdir -p $logarchive/$monthdir
mv $wwwlogdir/${logprefix}weblog.0 $logarchive/$dayfile
mv $wwwlogdir/${logprefix}error_log.0 $errorarcdir/error_log_$date
if [ -f $wwwlogdir/${logprefix}wiki_error_log.0 ]
then
    mv $wwwlogdir/${logprefix}wiki_error_log.0 $errorarcdir/wiki_error_log_$date
fi

# echo "Now compressing logfiles" 
$bzip2 -9 $logarchive/$dayfile
$bzip2 -9 $errorarcdir/error_log_$date
if [ -f $errorarcdir/wiki_error_log_$date ]
then
    $bzip2 -9 $errorarcdir/wiki_error_log_$date
fi
find $errorarcdir -mtime +31 -type f -exec rm \{\} \;
if [ -d $abuserarcdir ]
then
    find $abuserarcdir -mtime +31 -type f -exec rm \{\} \;
fi
