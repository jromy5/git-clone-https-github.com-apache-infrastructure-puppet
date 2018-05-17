#!/bin/sh

source common.conf

cd $LOGS2_DIR || exit 1
l="apache@apache.org info@apachecon.com hostmaster@apache.org postmaster@apache.org "
date=`date +%Y-%m-%d`
for f in $l ; do
  mv $f $f.$date && touch $f
done
