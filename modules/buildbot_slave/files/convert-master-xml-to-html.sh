#!/bin/sh

### WARNING THIS FILE IS MANAGED BY PUPPET ###
### See the buildbot_asf Module. ###

# This script converts all the gathered rat reports into a html summary.
cd /x1/buildmaster/master1
./create-master-rat-list.sh
java -jar /x1/buildmaster/saxon9/saxonb9/saxon9.jar -t -s:filelist.xml -xsl:rat-master-output.xsl -o:public_html/projects/rat-master-summary.html
