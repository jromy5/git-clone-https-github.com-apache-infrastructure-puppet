#!/bin/sh
PATH=/bin:/sbin:/usr/bin:/usr/sbin

#zfs list -r -t snapshot /usr/home \
#    | perl -le '@s=sort map {(split)[0]} <>; print for @s[1..($#s - 30)]' \
#    | xargs -n 1 zfs destroy

zfs list -r -t snapshot /x1/www \
    | perl -le '@s=sort map {(split)[0]} <>; print for @s[1..($#s - 30)]' \
    | xargs -n 1 zfs destroy

#zfs snapshot zroot/usr/home@`date +%Y%m%d`
zfs snapshot -r tank/x1/www@`date +%Y%m%d`
