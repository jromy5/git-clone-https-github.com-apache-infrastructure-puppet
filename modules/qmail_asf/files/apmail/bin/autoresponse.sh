#! /usr/local/bin/bash
ulimit -t 15

source common.conf

$APMAIL_HOME/apache-autoanswer \
	--file=apache-autoanswer.txt \
	--from="Apache Autoresponder <donotreply@Apache.Org>" \
	--errors-to="human-response@Apache.Org" \
	--include-original \
	--work-dir=$APMAIL_HOME/apache-autoanswer.work \
	--ignore-from MAILER-DAEMON \
        --ignore-precedence="list|bulk|junk"
