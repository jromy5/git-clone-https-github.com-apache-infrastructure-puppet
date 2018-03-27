#!/bin/bash

TLP=${1}
TODAY=`/bin/date +%Y%m%d`

# Check to make sure a TLP was provdied as ARGV1

if [ -z ${1} ]; then 
  echo "You didn't seem to supply a TLP name. You must supply one, and only one. "
  echo -e "i.e.\n${0} httpd"
  exit 1
fi

echo -e "For jails above 5GB usage, it is a good idea to operate in a screen session.\n"
echo "Continue running this script? [y|N]"
read continue


case $continue in
  y|Y ) ;;
    * ) exit 1;;
esac

# First me need to shut the jail down
echo "Stopping the jail..."
/etc/rc.d/jail stop ${TLP}

# Lets wait a few seconds before checking that 
# the jail has actually stopped.
sleep 10

# Now lets check it has stopped
echo "Checking the jail has stopped..."
/usr/sbin/jls | /usr/bin/grep "${TLP}"

if [ ${?} == "0" ] ; then 
  echo "It seems the ${TLP} jail has not shutdown. Exiting to prevent damage";
  exit 1
fi



# Now lets do each volume for each TLP one at a time.

volcount=0
for VOL in `zfs list | /usr/bin/awk '{print $1}' | grep ${TLP}`; do 
 
 NEWVOL=`echo ${VOL} | /usr/bin/sed -e s,zroot,x1,`

 echo -e "Creating snapshots for ZFS volume ${VOL} for ${TLP} which we will use to copy to the array \n"
 zfs snapshot ${VOL}@${TODAY}


 # Now we use zfs send and recieve to 'copy' the data. 
 echo -e "Copying data. This might take a few minutes...\n\n"
 zfs send ${VOL}@${TODAY} | zfs receive ${NEWVOL}


 # Lets check the zone copied over.
 zfs list | /usr/bin/grep "${NEWVOL}"

 if [ ${?} != "0" ] ; then 
   echo -e "It seems the ${VOL} volume did not copy successfully. Exiting to prevent automated stupidity.\nYou should check to see if the volume copied to ${NEWVOL}";
   echo "This is the command we used to copy the data... "
   echo "zfs send ${VOL}@${TODAY} | zfs receive ${NEWVOL}"
   exit 1
 fi

 echo -e "Deleting the snapshots, as these are no longer needed regardless of state.\n"
 zfs destroy ${VOL}@${TODAY}
 zfs destroy ${NEWVOL}@${TODAY}
 
 if [ $volcount == 0 ] ; then
  TOPVOL=${VOL}
 fi 

let "volcount += 1"
done

# Now we will edit rc.conf so the jail points to the new path.
echo -e "Editing rc.conf to reflect the new path...\n\n"
/usr/bin/perl -p -i -e "s|/jails/${TLP}|/x1/jails/${TLP}|" /etc/rc.conf

echo "** NOTE **"
echo "We have not started the jail automatically."
echo -e "When you are happy the move has gone ok, Start it with :\n\n"
echo -e "/etc/rc.d/jail start ${TLP}\n"
echo -e "We have not deleted the source volume ${TOPVOL} \n You can do that by running zfs destroy -r ${TOPVOL}\n"
