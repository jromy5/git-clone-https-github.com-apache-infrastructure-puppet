#! /bin/sh
#
# Updates the http://git.apache.org/ web page, index.json, index.txt, and
# github-sync.json

cd /x1/git/mirrors

echo "{" >index.json.new
echo "{" >github-sync.json.new

cat <<EOT >index.new
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" 
               "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"> 
<!--
  Licensed to the Apache Software Foundation (ASF) under one
  or more contributor license agreements.  See the NOTICE file
  distributed with this work for additional information
  regarding copyright ownership.  The ASF licenses this file
  to you under the Apache License, Version 2.0 (the
  "License"); you may not use this file except in compliance
  with the License.  You may obtain a copy of the License at
 
    http://www.apache.org/licenses/LICENSE-2.0
 
  Unless required by applicable law or agreed to in writing,
  software distributed under the License is distributed on an
  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
  KIND, either express or implied.  See the License for the
  specific language governing permissions and limitations
  under the License. 
--> 
<html xmlns="http://www.w3.org/1999/xhtml"> 
  <head> 
    <style type="text/css">
     tr:nth-of-type(odd) td {
	background-color: #DDE;
     }
    th {
        background: linear-gradient(to bottom, #ffffff 0%,#f1f1f1 50%,#e1e1e1 51%,#f6f6f6 100%) !important;
   }
    </style>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/> 
    <meta name="author" content="The Apache Software Foundation"/>
    <title>Git at Apache</title> 
    <meta property="og:image" content="https://www.apache.org/images/asf_logo.gif" /> 
    <link rel="stylesheet" type="text/css" media="screen"
          href="https://www.apache.org/css/style.css"> 
    <script type="text/javascript" src="https://www.apache.org/js/jquery.js"></script> 
    <script type="text/javascript" src="https://www.apache.org/js/apache_boot.js"></script> 
  </head> 
  <body> 
    <div id="page" class="container_16"> 
      <div id="header" class="grid_8"> 
        <img src="https://www.apache.org/images/feather-small.gif" alt="The Apache Software Foundation"> 
        <h1>The Apache Software Foundation</h1> 
        <h2>Git at Apache</h2> 
      </div> 
      <div id="nav" class="grid_8"> 
        <ul> 
          <li><a href="http://www.apache.org/foundation/" title="The Foundation">Foundation</a></li> 
          <li><a href="http://projects.apache.org" title="The Projects">Projects</a></li> 
          <li><a href="http://people.apache.org" title="The People">People</a></li> 
          <li><a href="http://www.apache.org/foundation/getinvolved.html" title="Get Involved">Get Involved</a></li> 
          <li><a href="http://www.apache.org/dyn/closer.cgi" title="Download">Download</a></li> 
          <li><a href="http://www.apache.org/foundation/sponsorship.html" title="Support Apache">Support Apache</a></li> 
        </ul> 
        <form name="search" id="search" action="http://www.google.com/search" method="get"> 
          <input value="*.apache.org" name="sitesearch" type="hidden"/> 
          <input type="text" name="q" id="query"> 
          <input type="submit" id="submit" value="Search"> 
        </form> 
      </div> 
      <div class="clear"></div> 
      <div id="content" class="grid_16"><div class="section-content">
    <p>
      This is a collection of read-only Git mirrors of Apache codebases.
      The mirrors are automatically updated and contain full version
      histories (including branches and tags) from the respective source
      trees in the official Subversion repository at Apache.
      See the <a href="http://www.apache.org/dev/git.html">documentation</a>
      and the <a href="http://wiki.apache.org/general/GitAtApache">wiki page</a>
      for more information (including how to set up git svn dcommit support for
      Apache committers).
      <br />
      Many Apache projects now use Git as their primary SCM. Most are hosted
      on <a href="https://git-wip-us.apache.org/">"Git WiP" system</a>. For 
      more information and project listings for this, please see
      <a href="https://git-wip-us.apache.org/">https://git-wip-us.apache.org</a>.
      The rest use the still-in-development
      <a href="https://gitbox.apache.org/">Github Dual Master</a>, for the
      list of those projects and basic information, please see
      <a href="https://gitbox.apache.org/">https://gitbox.apache.org</a>.
    </p>
    <p>
      Note that these Git mirrors are missing Subversion features like
      svn:ignore, svn:eol-style and svn:keywords settings and support for
      empty directories.
    </p>
    <p>
      Please contact the users@infra.apache.org mailing list if
      you have comments or suggestions regarding this service. See the
      <a href="http://www.apache.org/dev/git.html#git-mirrors">documentation</a>
      for instructions on how to get another Apache codebase mirrored here.
    </p>
    <table style="font-size: 11pt; padding: 1px !important;">
      <thead>
        <tr style="background: linear-gradient(to bottom, #ffffff 0%,#f1f1f1 50%,#e1e1e1 51%,#f6f6f6 100%);">
          <th>Origin</th>
          <th>Git Mirror</th>
          <th>Description</th>
          <th>Git Clone URL</th>
          <th>Alternatives</th>
        </tr>
      </thead>
      <tbody>
EOT

for d in *.git; do
  n=`basename $d .git`
  b=`cat $d/description`
  GIT_DIR=/x1/git/mirrors/$d
  export GIT_DIR
  giturl="git://git.apache.org/$d"
  g=`git config remote.origin.url`
  if test -n "$g"; then
    cat <<EOT >>index.new
          <tr>
            <td>
              <a href="$g"><img title="Go to canonical Git repository" src="/images/icon_commit.png" height="16" width="16"/></a>
            </td>
            <td><a name="$n">$d</a></td>
            <td>$b</td>
            <td>
              <a href="git://git.apache.org/$d">git://git.apache.org/$d</a>
            </td>
            <td>
              <a href="https://github.com/apache/$n"><img title="View on GitHub" src="/images/icon_github.png" height="16" width="16"/></a> &nbsp; 
            </td>
          </tr>
EOT
  else
    svnurl=`git config svn-remote.svn.fetch | sed "s/\(trunk\|site\).*:.*//"`
    g=https://svn.apache.org/repos/asf/$svnurl
    cat <<EOT >>index.new
          <tr>
            <td>
              <a href="$g"><img title="Go to Subversion repository" src="/images/icon_subversion.png" height="16" width="16"/></a>
              <a href="https://svn.apache.org/viewvc/$svnurl"><img title="View Subversion repository" src="/images/icon_viewvc.png" height="16" width="16"/></a>
            </td>
            <td><a name="$n">$d</a></td>
            <td>$b</td>
            <td>
              <a href="git://git.apache.org/$d">git://git.apache.org/$d</a>
            </td>
            <td>
              <a href="https://github.com/apache/$n"><img title="View on GitHub" src="/images/icon_github.png" height="16" width="16"/></a> &nbsp; 
            </td>
          </tr>
EOT
  fi
  cat <<EOT >>index.json.new
"$n": "$g",
EOT
# crossing-fingers that $b does not have JSON-breaking characters
  cat <<EOT >>github-sync.json.new
"$n": {"url":"$giturl", "desc":"$b"},
EOT
  echo "$giturl" >>index.txt.new
done

cat <<EOT >>index.new
      </tbody>
    </table>

      </div></div> 
      <div class="clear"></div> 
    </div> 

    <div id="copyright" class="container_16"> 
      <p>Copyright &#169; 2010-2017 The Apache Software Foundation, Licensed under the <a href="http://www.apache.org/licenses/LICENSE-2.0">Apache License, Version 2.0</a>.<br/>Apache and the Apache feather logo are trademarks of The Apache Software Foundation.</p> 
    </div> 
  </body> 
</html>
EOT

sed -i '$s/,$//' index.json.new
echo "}" >>index.json.new
sed -i '$s/,$//' github-sync.json.new
echo "}" >>github-sync.json.new

mv -f index.new index.html
mv -f index.json.new index.json
mv -f index.txt.new index.txt
mv -f github-sync.json.new github-sync.json
