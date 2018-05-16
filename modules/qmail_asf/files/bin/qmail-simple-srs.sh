#!/bin/sh
# USAGE: $0 [-u] <<space-separated list of apache user ids>>
#
# Will activate ~apmail/.qmail-foo-owner files linked to .qmail-foo-default
# to set the SENDER of the outbound messages to the contents of that file.
#
# -u: undo's the addition of .qmail-foo-owner files for the listed users.

cd ~apmail || ( echo "Can't cd to ~apmail: $?" >&2 && exit 1 );

if [ "$1" = "-u" ]; then
    shift;
    while [ -n "$1" ]
    do
        [ -f .qmail-$1 ] && rm -f .qmail-$1-owner || echo $1 not found. >&2
        shift;
    done
    exit 0;
fi

while [ -n "$1" ]
do
    [ -f .qmail-$1 ] && ln -sf .qmail-$1-default .qmail-$1-owner \
        || echo $1 not found. >&2
    shift;
done
