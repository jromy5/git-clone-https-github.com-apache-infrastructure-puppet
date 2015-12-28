#!/bin/sh

# Invoked from root's crontab on issues (thor)

lgscr=/root/bin/buglog.sh
bzfrom="bugzilla@apache.org"

_doit() {
  /bin/bash ${lgscr} ${bzfrom} "dev@ant.apache.org" "Ant"
#  "Apache httpd-1.3"
  /bin/bash ${lgscr} ${bzfrom} "dev@httpd.apache.org" "Apache httpd-2"
  /bin/bash ${lgscr} ${bzfrom} "bugs@httpd.apache.org" "Apache httpd-2" 1> /dev/null 2>&1
#  "Apache httpd-test"
  /bin/bash ${lgscr} ${bzfrom} "dev@apr.apache.org" "APR"
  /bin/bash ${lgscr} ${bzfrom} "bugs@apr.apache.org" "APR" 1> /dev/null 2>&1
#  "Batik" - Moved to Jira
#  "BCEL" - Moved to Jira
#  "Crimson" - Attic
#  "Fop" - Moved to Jira
  /bin/bash ${lgscr} ${bzfrom} "issues@jmeter.apache.org" "JMeter"
#  "Lenya" - Active but no weekly e-mail
#  "Log4j" - Moved to Jira for Log4j2
#  "ORO" - Attic
#  "POI" - Active but no weekly e-mail
#  "Regexp" - Attic
#  "Ripple" - Active but no weekly e-mail
#  "Rivet" - Active but no weekly e-mail
#  "Security" - Moved to JIRA
#  "Slide" - Attic
#  "Steve" - Active but no weekly e-mail
  /bin/bash ${lgscr} ${bzfrom} "dev@tomcat.apache.org" "Taglibs"
#   "Tomcat 3" - Project Attic
#   "Tomcat 4" - Project Attic
#   "Tomcat 5" - Project Attic
  /bin/bash ${lgscr} ${bzfrom} "dev@tomcat.apache.org" "Tomcat 6"
  /bin/bash ${lgscr} ${bzfrom} "dev@tomcat.apache.org" "Tomcat 7"
  /bin/bash ${lgscr} ${bzfrom} "dev@tomcat.apache.org" "Tomcat 8"
  /bin/bash ${lgscr} ${bzfrom} "dev@tomcat.apache.org" "Tomcat 9"
  /bin/bash ${lgscr} ${bzfrom} "dev@tomcat.apache.org" "Tomcat Connectors"
  /bin/bash ${lgscr} ${bzfrom} "dev@tomcat.apache.org" "Tomcat Modules"
  /bin/bash ${lgscr} ${bzfrom} "dev@tomcat.apache.org" "Tomcat Native"
#  "Watchdog" - Project Attic
#  "WebSH" - Active but no weekly e-mail
#  "XalanJ1" - Project Attic
#  "Xerces-J" - Project Attic
#  "Xindice" - Attic
#  "XmlCommons" - Moved to JIRA
#  "XmlGraphicsCommons" - Moved to JIRA
}

echo "ASF Bugzilla is running its weekly stats at" `date`
echo ""
echo "----------------------------------------------------------------------"

_doit 

echo "----------------------------------------------------------------------"
echo ""
echo "ASF Bugzilla stats run has concluded."
echo "Please note that the sender address of this mail is "
echo "an unmonitored alias."
