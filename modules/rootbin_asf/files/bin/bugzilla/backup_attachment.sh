#!/bin/sh

# Usage backup_attachment.sh database attachment-id

mysql -e "create table if not exists attach_data_archive (id MEDIUMINT NOT NULL, thedata LONGBLOB NOT NULL);" $1
mysql -e "insert into attach_data_archive (id, thedata) select id, thedata from attach_data where id=$2;" $1
