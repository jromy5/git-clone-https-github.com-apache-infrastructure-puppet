#! /bin/sh
#
# Collect subscription information about the mailing lists.
#

# For ezmlm-list

source common.conf

PATH=$PATH:/usr/local/bin

STATFILE=/tmp/listbackup.$$
echo >> $STATFILE `date +%Y-%m-%d`
PATHTO=$LISTS_DIR
cd $PATHTO
DOMAINS=`find . -type d -maxdepth 1 | grep -v '^\.$' | sed -e 's,^\./,,g;'`
for DOMAIN in $DOMAINS ; do
    LISTS=`find ./$DOMAIN -type d -maxdepth 1 | grep -v "^./$DOMAIN\$" | sed -e "s,^\./$DOMAIN/,,g;"`
    for LIST in $LISTS ; do
        LISTNAME="$LIST@$DOMAIN"
        echo "List: " >> $STATFILE
        echo "$LISTNAME" >> $STATFILE
        echo "Subscribers:" >> $STATFILE
        echo `ezmlm-list $PATHTO/$DOMAIN/$LIST` >> $STATFILE
        if [ -d $PATHTO/$DOMAIN/$LIST/digest ] ; then
            echo "Digest subscribers:" >> $STATFILE
            echo `ezmlm-list $PATHTO/$DOMAIN/$LIST/digest` >> $STATFILE
        fi
        echo "Moderators:" >> $STATFILE
        echo `ezmlm-list $PATHTO/$DOMAIN/$LIST/mod` >> $STATFILE
    done
done
if [ -z "$1" ] ; then
    SENDTO=apmail@apache.org
else
    SENDTO=$1
fi
if [ -f "$STATFILE" ] ; then
    if [ -n "$2" ] ; then
        cat $STATFILE
    else
        mail -s "Apache list backup" "$SENDTO" < $STATFILE
    fi
    rm -f $STATFILE
fi
