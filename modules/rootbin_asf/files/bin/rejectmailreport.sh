#!/usr/local/bin/zsh

PATH=$PATH:/usr/local/bin

echo "Qpsmtpd log analysis for: `hostname`"

typeset -a files_array
pushd /var/log/qmail/smtpd
files=`ls @*`
popd
files_array=(`ls /var/log/qmail/smtpd/@*`)
day=`date "+%d"`
# If we are passed in an argument of any type, run against today.
if [ $# -eq 0 ]; then
  ((day=$day-1))
fi
yearmo=`date "+%Y-%m"`
if [ $day -lt 10 -a $# -eq 0 ]; then
  d="$yearmo-0$day"
else
  d="$yearmo-$day"
fi
matches=(`echo $files | tai64nlocal | grep -n $d | cut -d ':' -f 1`)
# multilog enforces the filename to be when it is finished, so one going on
# to the day after may contain this day's information
file_count=${#files_array}
matches_count=${#matches}
i=1
yesterday_files=()
while [ $i -le $matches_count ]; do
  #echo $files_array[$matches[$i]] | tai64nlocal
  yesterday_files=($yesterday_files $files_array[$matches[$i]])
  ((i=1+$i))
done
if [ $matches[$matches_count] -lt $file_count ]; then
  #echo $files_array[$matches[$matches_count]+1] | tai64nlocal
  yesterday_files=($yesterday_files $files_array[$matches[$matches_count]+1])
else
  yesterday_files=($yesterday_files /var/log/qmail/smtpd/current)
fi

echo "Starting at:" `grep -h 'Accepted connection' $yesterday_files[0] | head -1 | tai64nlocal | cut -d ' ' -f 1-2`
echo Accepted Connections: `grep 'Accepted connection' $yesterday_files | wc -l`
echo Connection Delays: `grep 'Too many connections:' $yesterday_files | wc -l`
echo Connection Max Deny: `grep 'Too many connections from' $yesterday_files | wc -l`
echo Non-resolvable DNS: `grep 'denysoft mail from' $yesterday_files | wc -l`
for i in check_badheaders check_earlytalker clamav spamassassin spamwatch viruswatch exe_filter; do
  echo $i: `grep "$i plugin:" $yesterday_files | wc -l`
done
# exe_filter details
for i in exe_filter; do
  grep "$i plugin:" $yesterday_files > $i.$$
  echo $i details: Exe: `grep 'exe sig' $i.$$ | wc -l` Zip: `grep 'zip sig' $i.$$ | wc -l` VBS: `grep 'vbs sig' $i.$$ | wc -l`
  rm $i.$$
done
# SA details
for i in spamassassin; do
  echo $i rejections: `grep $i $yesterday_files | grep -v 'Could not connect' | wc -l`
  echo $i failures: `grep $i $yesterday_files | grep 'Could not connect' | wc -l`
done
# SPF details
for i in sender_permitted_from; do
  echo $i rejections: `grep $i $yesterday_files | grep 'SPF forgery' | wc -l`
  echo $i failures: `grep $i $yesterday_files | grep 'SPF error' | wc -l`
done
# DNSBL details
for i in dnsbl; do
  grep "$i plugin:" $yesterday_files > $i-raw.$$
  # Cut out multiple rejections from same PID for same IP
  cat $i-raw.$$ | cut -d ' ' -f 2,5- | sort | uniq -c > $i-filter.$$
  for j in dsbl sorbs spamhaus; do
    echo "$j dnsbl rejections:" `cat $i-filter.$$ | grep $j | wc -l`
  done
  echo "Total dnsbl rejections:" `cat $i-filter.$$ | wc -l`
  rm $i-filter.$$
  # Now, give us IP stats...
  sort -t' ' -k2 $i-raw.$$ | cut -s -d'=' -f 2 | sort | uniq -c > $i.$$
  sort -t' ' -k2 $i-raw.$$ | grep -v '=' | cut -s -d'?' -f 2 | sort | uniq -c >> $i.$$
  rm $i-raw.$$
  echo "$i unique IPs rejected:" `cat $i.$$ | wc -l`
  echo "--BEGIN top 10 dnsbl seen (times IP has been rejected) --"
  sort -nr $i.$$ | head -10
  echo "--END top 10 dnsbl seen--"
  rm $i.$$
done
# clamav details
for i in clamav; do
  grep "$i plugin:" $yesterday_files > $i.$$
  echo "--BEGIN top 10 clamav seen--"
  grep "Virus(es) found: " $i.$$ | cut -d " " -f 7 | sort | uniq -c | sort -rn | head -10
  echo "--END top 10 clamav seen--"
  rm $i.$$
done
# top talkers
for i in top_talkers; do
  #@4000000041bf507d179b4044 75024 Accepted connection 88/150 from 213.140.2.6
  grep "Accepted connection" $yesterday_files > $i.$$
  echo "--BEGIN top 10 talkers --"
  cut -d " " -f 7 $i.$$ | sort | uniq -c | sort -rn | head -10
  echo "--END top 10 talkers--"
  rm $i.$$
done
