#!/bin/bash

DATE_DAY=`date +%d`
DATE_MONTH=`date +%m`
DATE_YEAR=`date +%Y`
FILEPATH="/var/www/html/pflogsumm/${DATE_YEAR}/${DATE_MONTH}"
FILENAME="${DATE_YEAR}${DATE_MONTH}${DATE_DAY}.txt"

if [ ! -d "${FILEPATH}" ]; then
  mkdir -p ${FILEPATH}; 
fi

cat /var/log/mail.log | /usr/sbin/pflogsumm  > ${FILEPATH}/${FILENAME} || echo "Could not create pflogsumm file. Error." 


