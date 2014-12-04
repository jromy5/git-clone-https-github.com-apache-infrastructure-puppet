#!/bin/sh

if [ -x /usr/local/bin/fastest_cvsup ]; then
    host=$(/usr/local/bin/fastest_cvsup -c us -Q)
else
    host=cvsup2.us.freebsd.org
fi

## pull new code
/usr/bin/csup -g -L2 -r 3 -h ${host}  /fus/projects-supfile
