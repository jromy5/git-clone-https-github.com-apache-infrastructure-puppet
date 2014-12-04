#!/bin/sh -e

svn=/usr/local/bin/svn

/root/bin/setlock.pl /home/smtpd/.svn_update_qmail \
	/usr/bin/env svn=$svn /bin/sh -ec 'cd /var/qmail; $svn cleanup; $svn up -q'

