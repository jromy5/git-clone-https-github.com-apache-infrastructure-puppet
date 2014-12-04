#!/bin/sh

## spamassassin watchdog, based on
## Simple ClamAV watchdog, 2004 Erik Abele
## e.g. */10 * * * * /path/to/watchdog.sh
 
if ! kill -0 `cat /var/run/spamd/spamd.pid`; then
        echo "SpamAssassin daemon not running - starting now..."
        /usr/local/etc/rc.d/sa-spamd start
fi


exit 0
