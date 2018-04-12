#!/bin/sh
set -e
set -u

VSN_PKGSITE=9.0-RELENG
VSN_ZSKEL=`uname -r`-p1

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin
cd /home/$5

if [ $# != 6 ]; then
 echo "You didn't specify the correct number of values.  You need six. ";
 echo "$0 name svc ip eth username uid";
 echo "$0 foo j-tlp 140.211.11.x bge1 pctony 2677";
 echo "Exiting...";
 exit 1;
fi

# TODO: Check if a dash - has been entered as the $name, if so need
#       to accept it for the hostname but convert to underscore _ for
#       the jail name. Jail names can not have a dash (-) but the 
#       hostname can. Jail names can have a underscore (_) but the
#       hostname can not.

name=$1
svc=$2
ip=$3
eth=$4
user=$5
user_id=$6

uid=$user_id
gid=$user_id

find_jails_root_mount() {
  for d in /x1/jails /jails ; do
    if [ -d "$d" ]; then
      zfs list -H -o mountpoint,name | sed -ne "s#^$d[	]##p"
      return
    fi
  done
  echo "Failed to find jails root dir" >&2
  exit 1
}

tld=zones.apache.org
jrootzfs=`find_jails_root_mount`
jrootdir=`zfs list -H -o mountpoint $jrootzfs`
destzfs=$jrootzfs/$name.$tld
dest=$jrootdir/$name.$tld

echo

### /etc/rc.conf additions
if ! grep jail_list /etc/rc.conf | grep -w $name; then
    echo "  Editing /etc/rc.conf, don't forget to svn ci"
    perl -pi -e "s,jail_list=\",jail_list=\"$name ," /etc/rc.conf
    cat <<END_CAT >> /etc/rc.conf

jail_${name}_hostname="${name}.${tld}"
jail_${name}_ip="${ip}"
jail_${name}_interface="${eth}"
jail_${name}_rootdir="${dest}"
jail_${name}_devfs_enable="YES"
END_CAT
else
echo " Somewhere in the /etc/rc.conf/ file there is a jail entry with
a name the same as or containing the same name as the jail name you 
just specified.

This script will now end so you can check it out, renaming the similar
entry in the /etc/rc.conf file temporarily if need be.

Relevant entry(s) are:
";
cat /etc/rc.conf | grep jail_list | grep $name
exit 1;
fi

# ## New ZFS container
# echo "  Creating ZFS Container $destzfs"
# zfs create $destzfs
# zfs create $destzfs/usr
# rsync -rlptgoDHExh $jrootdir/skeleton/ $dest/

## Install it
echo "  Installing jail $name to $dest from $jrootzfs/skeleton"
echo "  (### TODO: why isn't this using zfs clone?)"
echo "  (### TODO: why isn't this using -AX flags too?)"
zfs clone $jrootzfs/skeleton@$VSN_ZSKEL $destzfs

## create a ports tree but only if not a j-ltp jail
echo "  Not creating /usr/ports."
# need /usr/ports in jails => portsnap + zfs snapshot + zfs clone into jail.
# need /usr/ports in dm => nfs mount it.

## Configure Jail
echo "  Configuring Jail"
echo "Copying resolv.conf" 
cp /etc/resolv.conf $dest/etc/
echo "Copying aliases" 
cp /etc/mail/aliases $dest/etc/mail/
touch $dest/etc/fstab
echo "Setting TZ"
ln -s /usr/share/zoneinfo/Etc/UTC $dest/etc/localtime

echo "Adding SSHD to rc.conf, and enabling"
cat <<END_CAT > $dest/etc/rc.conf
sshd_enable="YES"
syslogd_flags="-ssAv"
END_CAT

echo "Setting up SSHD config"
cat <<END_CAT >> $dest/etc/ssh/sshd_config 
AuthorizedKeysFile          /etc/ssh/ssh_keys/%u.pub
PermitRootLogin             no
PasswordAuthentication      no
PermitEmptyPasswords        no
AllowTcpForwarding          no
StrictModes                 yes
LoginGraceTime              15
MaxAuthTries                5
UsePam                      no
AllowGroups		    sshusers
END_CAT

## home dirs
echo "  Creating Home dirs top level folder"
mkdir $dest/usr/home
mkdir $dest/usr/home/$user
ln -s usr/home $dest/home
chown -R $user:$user $dest/usr/home/$user

## packagesite
pkgsite=ftp://tb.apache.org/pub/FreeBSD/ports/packages/$VSN_PKGSITE-$svc/Latest/
echo " PACKAGESITE URL -- $pkgsite"
echo "export PACKAGESITE=$pkgsite" >> $dest/etc/profile
echo "setenv PACKAGESITE $pkgsite" >> $dest/etc/csh.cshrc

## Start it
echo "Starting the jail"
/etc/rc.d/jail start $name
# This requires the rc.d/jail patch.  Without that patch --- 'jls host.hostname'
jid=$(jls jid name | grep -- $name |awk '{print $1}')

## give me a user
echo "Add a user to the newly created jail"
jexec $jid pw group add sshusers -g 2680
jexec $jid pw group add $user -g $gid
grep $user /etc/master.passwd >> $dest/etc/master.passwd
/usr/sbin/pwd_mkdb -d $dest/etc -p $dest/etc/master.passwd

echo "Adding $user to wheel, and sshusers groups"
jexec $jid pw usermod $user -G wheel,sshusers

## ssh keys
echo " Setting up ssh keys folder, and copying initial key for $user"
mkdir -p $dest/etc/ssh/ssh_keys
chmod 750 $dest/etc/ssh/ssh_keys
chgrp sshusers $dest/etc/ssh/ssh_keys
cp /etc/ssh/ssh_keys/$user.pub $dest/etc/ssh/ssh_keys
chown $user $dest/etc/ssh/ssh_keys/$user.pub

## don't cache svn pws
echo "  Preventing SVN from caching passwords"
mkdir -p $dest/usr/local/etc
echo "Checkout the ASF subversion config for (/usr/local)/etc/"
svn co https://svn.apache.org/repos/infra/infrastructure/trunk/subversion/subversion $dest/usr/local/etc/subversion --quiet

## setup sudo
echo " Copy sudoers setup"
cp /usr/local/etc/sudoers $dest/usr/local/etc
chown root:wheel $dest/usr/local/etc/sudoers
chmod 400 $dest/usr/local/etc/sudoers

## give us a /root/bin
echo " Checkout /root/bin from SVN"
svn co https://svn.apache.org/repos/infra/infrastructure/trunk/machines/root/bin $dest/root/bin --quiet

## install packages
echo "Perl package installation"
jexec $jid csh -c "pkg_add -r perl > /dev/null"
echo "Running pp.pl --update --jail"
jexec $jid csh -c "/root/bin/pp.pl --update --jail"

## copy static bash into place
echo " Copy shells"
jexec $jid ln -s /usr/local/bin/bash /bin/bash

## Show me
jls | grep $name
echo

## SET A ROOT PASSWORD
echo 
echo
echo "======================"
echo " SET A ROOT PASSWORD "
echo "======================"
jexec $jid passwd
jexec $jid sudo -H -u $user opiepasswd

echo "ssh $user@$name.zones.apache.org"
# SSH fingerprints for authorized_keys(5)
for i in $dest/etc/ssh/*pub ; do ssh-keygen -l -f $i; done

echo "Adding the jail to fail2ban"
service fail2ban reload

echo "Copy /etc/mail/mailer.conf from some other jail"
