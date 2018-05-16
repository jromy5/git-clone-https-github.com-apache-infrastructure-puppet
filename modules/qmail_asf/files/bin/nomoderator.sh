#!/usr/local/bin/bash

source common.conf

OLDPWD=`pwd`
cd $APMAIL_HOME

echo "The following list have NO MODERATOR"

for LIST in `find lists -type d -mindepth 2 -maxdepth 2` ; do
  DIR="/home/apmail/$LIST"
  if [ -d "$DIR/mod" ] ; then
    if [ -s "$DIR/moderator" ] ; then
      MODS=`ezmlm-list $DIR/mod`
      if [ -z "$MODS" ] ; then
        HOST=`echo $LIST | cut -d/ -f2`
        ADDR=`echo $LIST | cut -d/ -f3`
        echo "  $ADDR@$HOST"
      fi
    fi
  fi
done

cd $OLDPWD
