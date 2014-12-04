#!/bin/sh

# This script keeps a local MySQL db backup for the last 5 days.
# On thor it is invoked from root's crontab.

set -eu
OUTFILE="/home/apbackup/mysql-local/`hostname`-db-`date +%Y-%m-%d`.sql"
# We rely on ~/.my.cnf having the right credentials to do this:
mysqldump --all-databases --result-file=$OUTFILE
[ ! -f "$OUTFILE.bz2" ] && nice bzip2 $OUTFILE || echo "Backup file $OUTFILE.bz2 already exists"
# Chown so apbackup can see it (for remote archiving)
chown apbackup $OUTFILE.bz2

# Now update the symlink so this is remotely archived
rm /home/apbackup/remotelybackedup/`hostname`-db-*.sql.bz2
ln -s $OUTFILE.bz2 /home/apbackup/remotelybackedup/

find /home/apbackup/mysql-local -type f -ctime +5 -name "`hostname`-db-*" | xargs rm -f
