#!/bin/sh

# This file is managed by puppet. See modules:qmail_asf/files/bin/remove-list.sh
# remove-list.sh listname
# remove-list.sh -m "bounce message" listname
#   where "listname" is for example "log4php-private@incubator.apache.org"
#
# This script removes a mailing list.
# It is intended to be executed on mail.apache.org.
# It should do the following on a successful run:
#
# 1) nuke the ~apmail/.qmail-... files
# 2) set up a bounce message for the list if -m "bounce message" is provided
# 3) create an ezmlm-generated backup archive in ~apmail/backup-archive/...
# 4) nuke the list directory
# 5) generate followup instructions on stdout for dealing with archiving
#    on people.apache.org

# Bring in some path vars.

source common.conf

while [ -n "$1" ]; do
    case "$1" in
        -m)
            shift
            message="$1"
            shift
            ;;
        -*)
            echo "Usage: $0 [-m 'bounce message'] listname" >&2
            exit 1
            ;;
        *)
            list="$1"
            shift
            ;;
    esac
done

if [ -z "$list" ]; then
    echo "Missing listname, usage: $0 [-m 'bounce message'] listname" >&2
    exit 1
fi

host=`echo "$list" | sed -e 's/^.*@//'`
name=`echo "$list" | sed -e 's/@.*$//'`
listdir="$LISTS_DIR/$host/$name"
project=`echo "$host" | sed -e 's/\..*$//'`

if [ "$project" = "apache" ]; then
   project=""
   sep=""
else
   sep="-"
fi

dotqmail="$APMAIL_HOME/.qmail-$project$sep$name"
archivedir="$APMAIL_HOME`/backup-archive/$project$sep$name"

if [ -z "$host" ]; then
    echo "Missing host, usage: $0 [-m 'bounce message'] name@host" >&2
    exit 1
fi

if [ -z "$name" ]; then
    echo "Missing name, usage: $0 [-m 'bounce message'] name@host" >&2
    exit 1
fi

if [ $list != "$name@$host" ]; then
    echo "Missing '@'-sign in listname: $list" >&2
    exit 1
fi

if [ ! -d "$listdir" ]; then
    echo "Cannot find list directory using path $listdir" >&2
    exit 1
fi

if [ ! -e "$dotqmail" ]; then
    echo "Cannot find .qmail file for list using path $dotqmail" >&2
    exit 1
fi

if [ -e "$archivedir" ]; then
    echo "Archive dir $archivedir exists - please remove it first." >&2
    exit 1
fi

chmod +t $APMAIL_HOME

rm $dotqmail
for extension in accept-default archive default digest-owner \
    digest-return-default owner reject-default return-default; do

    rm $dotqmail-$extension
done

if [ -n "$message" ]; then
    echo "|bouncesaying \"$message\"" | tee $dotqmail \
        $dotqmail-default > /dev/null
    chmod 0600 $dotqmail $dotqmail-default
fi

chmod -t $APMAIL_HOME

# ok, the list is now disconnected from qmail
# now we make a backup copy of the ezmlm archives
# prior to nuking the list

mkdir -p $archivedir

if tar cf $archivedir/${host}-${name}.tar $listdir; then

    (cd $archivedir && gzip -9 *)
    rm -rf $listdir

else
    err=$?
    echo "'tar cf $archivedir/${host}-${name}.tar $listdir' failed with status $err." >&2
    echo "Therefore list directory $listdir not removed." >&2
    exit 1
fi

cat <<EOF
List removed, backup archives in $archivedir.
Be sure to remove the line matching

    /\"$project$sep$name\"/

from your local copy of ~apmail/bin/.archives and commit the change.

Then run the following commands as apmail on minotaur.apache.org:

    # ### rm $dotqmail-archive
    cd ~apmail/bin; svn up .archives; ./archivealias

Have fun!
EOF

exit 0
