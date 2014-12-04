#!/usr/local/bin/bash

# This script keeps a local Postgres db backup for the last 7 days.
# On hel it is invoked from root's crontab.

# Binaries
DATE=/bin/date
GREP=/usr/bin/grep
PGDUMP=/usr/local/bin/pg_dump
GZIP=/usr/bin/gzip

# File locations
BACKUPDIR=/home/apbackup/backups/databases/pgsql
TSTAMP=`hostname`-db-`$DATE +%Y-%m-%d`
OLDTSTAMP=`hostname`-db-`$DATE -v -8d +%Y-%m-%d`

# Use a secure umask
umask 027

set -eu

# If the backup script is invoked twice on one day this will happen. This prevents the second instance clobbering the first
if [ -d "$BACKUPDIR/${TSTAMP}-inprogress" ]; then
	echo >&2 "Error: unexpected daily backup temp dir '$BACKUPDIR/${TSTAMP}-inprogress' found."
	exit 1
fi
mkdir "$BACKUPDIR/${TSTAMP}-inprogress"
chgrp apbackup "$BACKUPDIR/${TSTAMP}-inprogress"

DBLIST=$(su pgsql -c "psql -l -t" | awk '{print $1}' | $GREP -Ev "template[01]|*test|\|" )
for db in $DBLIST; do
	su pgsql -c "$PGDUMP $db" | $GZIP > "$BACKUPDIR/${TSTAMP}-inprogress/$db.sql.gz"
	chgrp apbackup "$BACKUPDIR/${TSTAMP}-inprogress/$db.sql.gz"
done

if [ ! -d "$BACKUPDIR/${TSTAMP}" ]; then
	mv "$BACKUPDIR/${TSTAMP}-inprogress" "$BACKUPDIR/${TSTAMP}"
else
	# If someone runs this script after the official backup has already
	# run, then leave the first backup files in place (they might be
	# partially rsynced), and create a unique timestamped directory for the
	# subsequent backup
	NEWTSTAMP=`hostname`-db-`$DATE +%Y-%m-%d-%H%M%S`
	echo >&2 "Warning: $0 already run today and produced $BACKUPDIR/${TSTAMP}/. New backup stored at $BACKUPDIR/${NEWTSTAMP}/. This new backup will not be archived remotely."
	mv "$BACKUPDIR/${TSTAMP}-inprogress" "$BACKUPDIR/${NEWTSTAMP}"
fi

# Delete the backups from a week ago today
rm -f "$BACKUPDIR/$OLDTSTAMP"/*.sql.gz
[ -d "$BACKUPDIR/$OLDTSTAMP" ] && rmdir "$BACKUPDIR/$OLDTSTAMP"
# Delete any files from any backup runs after the first, which will be stored with a %H%M%S timestamped directory (matched by -[0-9]* in the glob).
rm -f "$BACKUPDIR/$OLDTSTAMP"-[0-9]*/*.sql.gz
rm -rf "$BACKUPDIR/$OLDTSTAMP"-[0-9]*
