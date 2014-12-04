#!/bin/sh

# Select DBs to backup
DBSELECT="wikidb"

# Binaries
DATE=/bin/date
GZIP=/bin/gzip
MYSQLDUMP=/usr/bin/mysqldump
SSLBIN=/usr/bin/openssl

# File locations
BACKUPDIR=/x1/backups/databases/mysql
PASSFILE=/root/mysqlbackup.secret

# Misc
TODAY=`${DATE} "+%Y%m%d"`
ONEWEEK=`${DATE} --date '1 week ago' "+%Y%m%d"`

# Use a secure umask
umask 026

# Dump each mysql database in turn, encrypting as we go
for DB in ${DBSELECT}
 do
  OUTFILE=${BACKUPDIR}/mysql-$DB-${TODAY}.sql.gz.enc
  $MYSQLDUMP --single-transaction --quick ${DB} --default-character-set=latin1 | ${GZIP} | ${SSLBIN} enc -aes-256-cbc -salt -out ${OUTFILE} -pass file:${PASSFILE}
  
  # Check that the encrypted output file exists
  if [ ! -f ${OUTFILE} ] ; then
   echo "The encrypted output file ${OUTFILE} is missing. You should run ${0} again."
   exit 1
  fi

  # Delete the backup from 1 week ago
  SQLONEWEEK=${BACKUPDIR}/mysql-$DB-${ONEWEEK}.sql.gz.enc
  if [ -f ${SQLONEWEEK} ]; then
   rm -f ${SQLONEWEEK};
  fi

 done

chgrp -R apbackup ${BACKUPDIR}
