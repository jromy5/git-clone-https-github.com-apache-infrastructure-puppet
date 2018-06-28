#!/bin/sh
  
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin
CP=/bin/cp
MV=/bin/mv

if [ $# != 1 ]; then
 echo "You didn't specify a file to gzip!";
 echo "$0 filename";
 echo "Exiting...";
 exit 1;
fi

ARCHIVES=$1

if [ -f $ARCHIVES ];
then
  $CP $ARCHIVES $ARCHIVES.tmp
  gzip -9 $ARCHIVES
  $MV -f $ARCHIVES.tmp $ARCHIVES

  echo "All done, now make sure to symlink the mbox file.";
  echo "calling up the symlink program ..";
  /home/modmbox/scripts/xtract-gz.sh
  /etc/apache2/bin/mod-mbox-util -u .
else
  echo "Hmm, that file doesnt seem to exist, try again (?)";
  exit 1
fi
exit 0
