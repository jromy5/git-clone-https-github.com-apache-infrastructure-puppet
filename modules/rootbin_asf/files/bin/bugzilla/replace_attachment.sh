#!/bin/sh

# ./replace-attachment.sh dbname attachment_id

mysql -e " update attach_data set thedata=load_file('/tmp/attachment-$1-$2') where id=$2;" $1 
