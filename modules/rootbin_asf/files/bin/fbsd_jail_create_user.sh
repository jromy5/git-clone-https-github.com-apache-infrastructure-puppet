#!/bin/sh

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin


if [ $# != 3 ]; then
 echo "You didn't specify the correct number of values.  You need three";
 echo "$0 jailname username uid";
 echo "$0 forrest gmcdonald 2393";
 echo "Exiting...";
 exit 1;
fi

name=$1
user=$2
user_id=$3

uid=$user_id
gid=$user_id

tld=zones.apache.org
jail=$1.$tld
D=/jails/$jail
jid=$(jls |grep $name |awk '{print $1}')

echo

mkdir $D/usr/home/$user

## give me a user
jexec $jid pw group add $user -g $gid
grep $user /etc/master.passwd >> $D/etc/master.passwd
/usr/sbin/pwd_mkdb -d $D/etc -p $D/etc/master.passwd
jexec $jid pw usermod $user -G wheel,sshusers
chown $user:$user $D/home/$user

## ssh keys
cp /etc/ssh/ssh_keys/$user.pub $D/etc/ssh/ssh_keys
chown $user:wheel $D/etc/ssh/ssh_keys/$user.pub

echo "If your shell differs on the host from what is";
echo "available in the jail you may not be able to log in";
echo "until you change to a valid shell path";
echo "jexec $jid pw usermod $user -s /usr/local/bin/bash";
echo "(for example)";
echo "";

## SET A ROOT PASSWORD
echo 
echo
echo "======================"
echo " SET A ROOT PASSWORD "
echo "======================"

echo "ssh $user@$name.zones.apache.org"


