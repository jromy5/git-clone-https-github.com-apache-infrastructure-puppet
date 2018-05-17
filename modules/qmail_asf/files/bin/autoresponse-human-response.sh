#! /usr/local/bin/bash
#
# One unique response per fortnight (14 days)
#
ulimit -t 15

source common.conf

$APMAIL_HOME/apache-autoanswer \
	--file=autoanswer-human-response.txt \
	--from="Apache Autoresponder <donotreply@Apache.Org>" \
	--accept-for=human-response@apache.org \
	--ignore-interval=1209600 \
	--history-db=$APMAIL_HOME/autoresponded-human-response \
	--errors-to="human-response@Apache.Org" \
	--include-original \
	--work-dir=$APMAIL_HOME/apache-autoanswer.work \
	--ignore-from MAILER-DAEMON \
        --ignore-from listserv.vnuemedia.com \
        --ignore-precedence="list|bulk|junk"
