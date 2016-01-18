#!/bin/sh

### WARNING THIS FILE IS MANAGED BY PUPPET ###
### See buildbot_asf Module ###

cd /x1/buildmaster/master1/public_html/projects
for F in `find . -mindepth 2 -name rat-output.xml`; do java -jar /x1/buildmaster/saxon9/saxonb9/saxon9.jar -t -s:$F -xsl:/x1/buildmaster/master1/rat-output.xsl -o:`dirname $F`/rat-output.html; done
# find . -mindepth 2 -name rat-output.xml -exec rm -f {} \; ## Leave the xml file whilst testing.
