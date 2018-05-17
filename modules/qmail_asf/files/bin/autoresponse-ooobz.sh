#! /usr/local/bin/bash
ulimit -t 15

source common.conf

$APMAIL_HOME/apache-autoanswer \
	--file=autoanswer-ooobz.txt \
	--from="Apache Autoresponder <donotreply@Apache.Org>" \
	--accept-for=ooo-bugzilla-admin@apache.org \
	--ignore-interval=30 \
	--history-db=$APMAIL_HOME/autoresponded-ooobz \
	--include-original \
	--work-dir=$APMAIL_HOME/ooo-autoanswer.work \
	--ignore-from=MAILER-DAEMON \
	--ignore-from=postmaster \
	--ignore-from="@apache.org" \
        --ignore-precedence="list|bulk|junk"
