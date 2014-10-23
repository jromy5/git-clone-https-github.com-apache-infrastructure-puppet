#!/bin/bash

DATE_DAY=`/bin/date +%d`
DATE_MONTH=`/bin/date +%m`
DATE_YEAR=`/bin/date +%Y`
FILEPATH="/var/www/pflogsumm/${DATE_YEAR}/${DATE_MONTH}"
FILENAME="${DATE_YEAR}${DATE_MONTH}${DATE_DAY}.txt"

if [ ! -d "${FILEPATH}" ]; then
  /bin/mkdir -p ${FILEPATH}; 
fi

/bin/cat /var/log/mail.log | /usr/sbin/pflogsumm  > ${FILEPATH}/${FILENAME} || echo "Could not create pflogsumm file. Error." 


