#!/bin/sh

MAILTO=root@apache.org
FILTER=~/bin/moin/abusers.pl
BLOCKLIST=/usr/local/apache2-install/www.apache.org/conf/vhosts/wiki-abusers.txt
LOGBASEDIR=/x1/logarchive/www
ABUSERDIR=$LOGBASEDIR/abusers

# Calculate yesterday's date.
# Caution: going back 24 hours only works
# reliably without DST switches. OK, since
# we are running on UTC
set `perl -e '@t=localtime(time()-24*3600);
              printf("%d %02d %02d\n", $t[5]+1900, $t[4]+1, $t[3]);'`

YEAR=$1
MONTH=$2
DAY=$3
DATE=$YEAR-$MONTH-$DAY

WEBLOGDIR=$LOGBASEDIR/$YEAR/$MONTH
WEBLOGFILE=$WEBLOGDIR/$DAY.bz2
ABUSERSFILE=$ABUSERDIR/abusers_$YEAR$MONTH$DAY.txt

mkdir -p $ABUSERDIR
bunzip2 -c $WEBLOGFILE | $FILTER > $ABUSERSFILE

ips=`cut -f 1 $ABUSERSFILE | sort`
for ip in $ips
do
    grep "^$ip" $BLOCKLIST > /dev/null && blocks="$blocks $ip"
done

count=0
for ip in $blocks
do
    echo "$ip X # $DATE" >> $BLOCKLIST
    count=$((count+1))
done

subject="Blocked moin wiki abusers $DATE ($count IPs)"

mailfile=/tmp/abuser-mail.$$
echo "$subject" > $mailfile
echo "" >> $mailfile
echo $blocks | tr ' ' '\n' | sort >> $mailfile
echo "" >> $mailfile
echo "Complete abuser data for $DATE:" >> $mailfile
echo "" >> $mailfile
cat $ABUSERSFILE >> $mailfile

cat $mailfile | mail -s "$subject" root@apache.org

rm -f $mailfile
