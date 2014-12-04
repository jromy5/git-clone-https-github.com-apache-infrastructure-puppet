#!/bin/sh

## rbldnsd watchdog, based on
## Simple ClamAV watchdog, 2004 Erik Abele
## e.g. */10 * * * * /path/to/watchdog.sh
 
if ! kill -0 `cat /var/run/rbldnsd.pid`; then
        echo "rbldns daemon not running - starting now..."
        /usr/local/etc/rc.d/rbldnsd start
fi


exit 0
