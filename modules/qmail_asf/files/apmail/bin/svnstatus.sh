#!/bin/sh

# Script to check if the apmail directory tree is synchronised with SVN

source common.conf

# ignore unversioned files (for now)
/usr/bin/svn -q -u status $APMAIL_HOME --config-dir=$APMAIL_HOME/.subversion2 | grep -v '^Status against revision:'
 
