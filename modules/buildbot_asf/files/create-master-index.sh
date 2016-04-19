#!/bin/sh

### WARNING THIS FILE IS MANAGED BY PUPPET ###
### See the buildbot_asf module ###

cd /x1/buildmaster/master1/public_html/projects
chmod -R 755 . 2>&1 >/dev/null
chmod -R g+w openoffice/milestones 2>&1 >/dev/null
cat header.inc > index.html
echo '<div class="block content">
  <div class="column span-15 colborder">
   <h3 id="intro">
    Introduction
   </h3>
  <div class="section-content">
   <p>Welcome to the ASF Buildbot Instance. Projects are welcome to sign up to have their projects make use of Buildbot.</p>
   <p>For more information see the main <a href="https://ci.apache.org/buildbot.html">Buildbot information page</a></p>
   <p>For info on other CI systems we use at the ASF such as Jenkins and Gump see the main <a href="https://ci.apache.org/"> Index page</a></p>
  </div>
  <h4 id="docs">
   Projects that have published docs and or APIs
  </h4>
  <div class="section-content">' >> index.html

find . -mindepth 2 -name "index.html" -exec echo '<a href={}>{} </a><br />' \; | sort | sed -e s/\\.\\///g >> index.html

echo '<br />
      <h4 id="reports">Projects that have had Apache RAT reports run against them</h4>' >> index.html

find . -mindepth 1 -name "rat-output.html" -exec echo '<a href={}>{} </a><br />' \; | sort | sed -e s/\\.\\///g >> index.html
echo '<br />' >> index.html
find . -mindepth 1 -name "rat-output.txt" -exec echo '<a href={}>{} </a><br />' \; | sort | sed -e s/\\.\\///g >> index.html
echo '<br />' >> index.html
echo '<p><strong>See also: </strong> <a href="https://ci.apache.org/projects/rat-master-summary.html">A master summary table of project RAT reports.</a></p>' >> index.html
echo '<br />
<h4 id="notes">Notes:</h4>
<p>This page is re-generated every hour. Depending on project builds and how they are configured to generate
documentation, APIs, or have RAT reports run against their latest trunk, will determine what links appear here.</p>
<p>Any documentation, install instructions or anything else shown in any project build outputs above are not official released information and should not be treated as such. This is a testing environment and any websites, documentation, javadocs etc are built from the latest unreleased source code in subversion. <strong><em>Always</em></strong> refer to the official project website and/or released documentation.</p>
</div>
         </div>' >> index.html
cat footer.inc >> index.html

