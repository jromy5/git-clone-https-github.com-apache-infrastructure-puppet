#! /usr/local/bin/bash
ulimit -t 15

source common.conf

$APMAIL_HOME/apache-autoanswer \
	--file=autoanswer-apachecon.txt \
	--from="ApacheCon Autoresponder <donotreply@apachecon.com>" \
        --accept-for=info@apachecon.com \
        --accept-for=discuss@apachecon.com \
	--accept-for=press@apachecon.com \
        --accept-for=concom@apachecon.com \
        --accept-for=conference@apachecon.com \
        --accept-for=cfp@apachecon.com \
	--ignore-interval=30 \
	--history-db=<%= @apmail_home %>/autoresponded-apachecon \
	--include-original \
	--work-dir=<%= @apmail_home %>/apache-autoanswer.work \
	--ignore-from=MAILER-DAEMON \
	--ignore-from=postmaster \
        --ignore-from="@apachecon.com" \
        --ignore-precedence="list|bulk|junk"
