#!/bin/sh

# ./extract-attachment.sh dbname attachment_id

mysql -e " select thedata into dumpfile '/tmp/attachment-$1-$2' from attach_data where id=$2;" $1 
