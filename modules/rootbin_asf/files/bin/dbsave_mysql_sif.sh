#!/bin/sh

# Select DBs to backup
DBSELECT="ooobugs"

# Binaries
GNUDATE=/bin/date
GZIP=/usr/bin/gzip
MYSQLDUMP=/usr/local/bin/mysqldump
SSLBIN=/usr/bin/openssl

# File locations
BACKUPDIR=/home/apbackup/backups/databases/mysql
PASSFILE=/root/mysqlbackup.secret

# Misc
TODAY=`${GNUDATE} "+%Y%m%d"`
FORTNIGHT=`${GNUDATE} -v-14d "+%Y%m%d"`

# Use a secure umask
umask 026

# Dump each mysql database in turn, encrypting as we go
for DB in ${DBSELECT}
 do
  OUTFILE=${BACKUPDIR}/mysql-$DB-${TODAY}.sql.gz.enc
  $MYSQLDUMP ${DB} | ${GZIP} | ${SSLBIN} enc -aes-256-cbc -salt -out ${OUTFILE} -pass file:${PASSFILE}
  
  # Check that the encrypted output file exists
  if [ ! -f ${OUTFILE} ] ; then
   echo "The encrypted output file ${OUTFILE} is missing. You should run ${0} again."
   exit 1
  fi

  # Delete the old backup
  SQLONEMONTH=${BACKUPDIR}/mysql-$DB-${FORTNIGHT}.sql.gz.enc
  if [ -f ${SQLONEMONTH} ]; then
   rm -f ${SQLONEMONTH};
  fi

 done

chgrp -R apbackup ${BACKUPDIR}
