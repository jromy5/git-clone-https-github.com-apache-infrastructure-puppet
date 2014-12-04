#!/bin/sh -e

svn=/usr/local/bin/svn

cd /usr/local/etc/pgeodns
$svn cleanup
$svn up -q

