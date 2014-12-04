#!/bin/sh

# Select DBs to backup
DBSELECT="confluence_349"
# ^^ Note: the confluence db needs updating every time Confluence is upgraded. Read perms must be granted to the 'backup' user via:
#    GRANT select, lock tables on confluence_46.* to backup@'localhost';

# Binaries
GNUDATE=/usr/local/bin/date
GZIP=/usr/bin/gzip
MYSQLDUMP=/usr/local/mysql/bin/mysqldump
SSLBIN=/opt/openssl/bin/openssl

# File locations
BACKUPDIR=/x1/backups/databases/mysql
PASSFILE=/root/mysqlbackup.secret

# Misc
TODAY=`${GNUDATE} "+%Y%m%d"`
ONEMONTH=`${GNUDATE} --date '1 month ago' "+%Y%m%d"`

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

  # Delete the backup from 1 month ago
  SQLONEMONTH=${BACKUPDIR}/mysql-$DB-${ONEMONTH}.sql.gz.enc
  if [ -f ${SQLONEMONTH} ]; then
   rm -f ${SQLONEMONTH};
  fi

 done

chgrp -R apbackup ${BACKUPDIR}
