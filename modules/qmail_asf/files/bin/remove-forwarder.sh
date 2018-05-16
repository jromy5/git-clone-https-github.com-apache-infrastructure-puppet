#!/bin/sh

# Usage $0 << space separated list of forwarding accounts to remove >>
#
# NOTE: remove the account from ldap first or a cron will regenerate .qmail-foo!

cd ~apmail || ( echo "Can't cd ~apmail: $?" && exit 1 )

while [ -n "$1" ]
do
    [ -f .qmail-$1 ] && rm -f .qmail-$1 .qmail-$1-default .qmail-$1-owner \
        || echo $1 not found. >&2
    shift;
done
