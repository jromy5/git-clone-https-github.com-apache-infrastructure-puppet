#! /usr/local/bin/bash
ulimit -t 15

source common.conf 

$APMAIL_HOME/apache-autoanswer \
	--file=autoanswer-apache.txt \
	--from="Apache Autoresponder <donotreply@Apache.Org>" \
	--accept-for=apache@apache.org \
	--ignore-interval=30 \
	--history-db=$APMAIL_HOME/autoresponded-apache \
	--include-original \
	--work-dir=$APMAIL_HOME/apache-autoanswer.work \
	--ignore-from=MAILER-DAEMON \
	--ignore-from=postmaster \
	--ignore-from="@apache.org" \
        --ignore-precedence="list|bulk|junk"
