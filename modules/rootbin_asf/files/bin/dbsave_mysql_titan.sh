#!/bin/bash

## ------------------------
##  Variables
## ------------------------

DATE='/bin/date'
DBHOST='localhost'
DBUSER='dbdump'
DUMP='/usr/bin/mysqldump'
DUMPDATE=`${DATE} +%Y%m%d%H%M`
OLDDUMPDATE=`${DATE} +%Y%m%d%H%M --date='last month'`
DUMPOPTS='--lock-tables --master-data=1'
DUMPROOT='/x1/db_dump/mysql'
LOCKFILE='/tmp/mysql.dump.lock'
MYSQL='/usr/bin/mysql'
PASS=`cat /root/.mysql.dbdump.pass`
PORT='3306'
ALLDBS=`echo "SHOW DATABASES;" | ${MYSQL} -P ${PORT} -h ${DBHOST} -u ${DBUSER} --password=${PASS} | egrep -v "^(Database|information_schema|performance_schema)" 2>&1`;
DBLISTFILE="/tmp/mysql.dump.list"


## ------------------------
## Functions
## ------------------------

backup_db() {
  echo "Dumping ${DBNAME} DB..."
  time ${DUMP} -h ${DBHOST} -u ${DBUSER} --password=${PASS} -P ${PORT} ${DBNAME} | gzip --rsyncable -9 > ${DUMPFILE}
  echo -e "\n\n"
}

check_lock() {
  if [ -f ${LOCKFILE} ]; then
    echo "A lockfile ${LOCKFILE} already exists.  This likely means a backup is still running";
    #exit 1;
  fi
}

create_db_list() {
  echo "Creating list of DB's to dump..."
  echo ${ALLDBS} > ${DBLISTFILE}
  echo ${ALLDBS}
  echo -e "\n\n"
}

create_dumpdir() {
  if [ ! -d ${DUMPDIR} ]; then
    echo "Creating new directory structure ( ${DUMPDIR} ) for new DB ${DBNAME}"
    mkdir -p ${DUMPDIR};
    echo -e "\n\n"
  fi
}

rsync_offsite() {
  DATE_BIN=/bin/date
  TODAY=`$DATE_BIN +%Y%m%d`
  FIVE_DAYS=`$DATE_BIN -d '5 days ago' +%Y%m%d`
  OLD_LOG=/root/rsynclogs/abi/backups-titan-$FIVE_DAYS.log
  RM_BIN=/bin/rm

  /etc/init.d/stunnel4 start
  sleep 1
  echo "rsyncing file ${DUMPFILE} offsite to abi ..."
  echo -e "\n\n"
  time \
  /usr/bin/rsync -rlRptz \
  --log-file=/root/rsynclogs/abi/backups-titan-$TODAY.log \
  --password-file=/root/.pw-abi \
  ${DUMPFILE} rsync://apb-titan@localhost:1873/titan/
  /etc/init.d/stunnel4 stop

  $RM_BIN -f $OLD_LOG
}

remove_olddump_file() {
  rm -f ${OLDDUMPFILE}
}

start_lock() {
  touch ${LOCKFILE}
}

stop_lock() {
 rm -f ${LOCKFILE}
}


## ------------------------
##  Main loop
## ------------------------

date
check_lock
start_lock
create_db_list

## Now lets loops over the DBs and do something
for DBNAME in `cat "${DBLISTFILE}"` ; do
  DUMPDIR="${DUMPROOT}/${DBNAME}"
  DUMPFILE="${DUMPDIR}/${DUMPDATE}.sql.gz"
  date
  create_dumpdir;
  backup_db
  sleep 5
  rsync_offsite
  sleep 5;
done

remove_olddump_file
stop_lock
date
