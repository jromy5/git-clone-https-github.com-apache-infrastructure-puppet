#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin

zfs list -r -t snapshot /x1/home \
    | perl -le '@s=sort map {(split)[0]} <>; print for @s[1..($#s - 30)]' \
    | xargs -n 1 zfs destroy

zfs list -r -t snapshot /x1/www \
    | perl -le '@s=sort map {(split)[0]} <>; print for @s[1..($#s - 30)]' \
    | xargs -n 1 zfs destroy

zfs snapshot array/home/apbackup@`date +%Y%m%d`
zfs snapshot array/www@`date +%Y%m%d`
