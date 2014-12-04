#!/bin/sh

## Simple ClamAV watchdog, 2004 Erik Abele
## e.g. */10 * * * * /path/to/watchdog.sh

if [ -z "`ps acx | grep 'clamd'`" ]; then
        echo "ClamAV daemon not running - starting now..."
        /usr/local/etc/rc.d/clamav-clamd start
fi

if [ -z "`ps acx | grep 'freshclam'`" ]; then
        echo "FreshClam daemon not running - starting now..."
        /usr/local/etc/rc.d/clamav-freshclam start
fi

exit 0
