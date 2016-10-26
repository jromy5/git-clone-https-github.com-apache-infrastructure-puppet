#!/bin/sh

## THIS FILE IS MANAGED IN PUPPET: git.apache.org/infrastructure-puppet.git
## Open pull requests here: https://github.com/apache/infrastructure-puppet

cd /x1/buildmaster/master1/public_html/projects/openoffice
cat header.inc > index.html
echo '<div id="contenta">
  <h2>Buildbots</h2>
  <div>
  <p> Summary Results of Builds are available <a href="https://s.apache.org/openoffice-builders" target="_blank">Here<a></p>
  </div>
  <hr />

  <h2>Build Analysis</h2>
    <p  id="rat"> <a href="https://ci.apache.org/projects/openoffice/rat-output.html" target="_blank">RAT Report</a> on the trunk build.</p>
    <p  id="rat"> <a href="https://ci.apache.org/projects/openoffice/release_branch/rat-output.html" target="_blank">RAT Report</a> on the build based on the current release branch.</p>
  <hr />

  <h2>Install Packages / Buildbot Logs</h2>
    <p>'  >> /x1/buildmaster/master1/public_html/projects/openoffice/index.html
cd /x1/buildmaster/master1/public_html/projects/openoffice/install/linux32
echo '<br /> <a href="https://ci.apache.org/projects/openoffice/buildlogs/linux32/log/unxlngi6.pro.build.html" target="_blank">Linux32 Build Logs</a><br />
      <h3 id="linux32">Linux32 Install Packages</h3><br />' >> /x1/buildmaster/master1/public_html/projects/openoffice/index.html
find . -name "*.tar.gz" -exec echo '<li><a href=/projects/openoffice/install/linux32/{} title={}>{} </a></li>' \; | sort -r | sed -e s/\\.\\///g >> /x1/buildmaster/master1/public_html/projects/openoffice/index.html
cd /x1/buildmaster/master1/public_html/projects/openoffice/install/linsnap
echo '<hr /><br /><a href="https://ci.apache.org/projects/openoffice/buildlogs/linsnap/log/unxlngi6.pro.build.html" target="_blank">Linux32 Snapshot Build Logs</a><br />
      <h3 id="linsnap">Linux32 Snapshot Install Packages</h3><br />' >> /x1/buildmaster/master1/public_html/projects/openoffice/index.html
find . -name "*.tar.gz" -exec echo '<li><a href=/projects/openoffice/install/linsnap/{} title={}>{} </a></li>' \; | sort -r | sed -e s/\\.\\///g >> /x1/buildmaster/master1/public_html/projects/openoffice/index.html
cd /x1/buildmaster/master1/public_html/projects/openoffice/install/linux64
echo '<hr /><br /><a href="https://ci.apache.org/projects/openoffice/buildlogs/linux64/log/unxlngx6.pro.build.html" target="_blank">Linux64 Build Logs</a><br />
      <h3 id="linux64">Linux64 Install Packages</h3><br />' >> /x1/buildmaster/master1/public_html/projects/openoffice/index.html
find . -name "*.tar.gz" -exec echo '<li><a href=/projects/openoffice/install/linux64/{} title={}>{} </a></li>' \; | sort -r | sed -e s/\\.\\///g >> /x1/buildmaster/master1/public_html/projects/openoffice/index.html
cd /x1/buildmaster/master1/public_html/projects/openoffice/install/fbsdn
echo '<hr /><br /><a href="https://ci.apache.org/projects/openoffice/buildlogs/fbsdn/log/unxfbsdx.pro.build.html" target="_blank">FreeBSD nightly Build Logs</a><br />
      <h3 id="fbsdn">FreeBSD nightly Install Packages</h3><br />' >> /x1/buildmaster/master1/public_html/projects/openoffice/index.html
find . -name "*.tar.gz" -exec echo '<li><a href=/projects/openoffice/install/fbsdn/{} title={}>{} </a></li>' \; | sort -r | sed -e s/\\.\\///g >> /x1/buildmaster/master1/public_html/projects/openoffice/index.html
cd /x1/buildmaster/master1/public_html/projects/openoffice/install/win
echo '<hr /><br /><a href="https://ci.apache.org/projects/openoffice/buildlogs/win/log/wntmsci12.pro.build.html" target="_blank">Windows Nightly Build Logs</a><br />
      <h3 id="win">Windows Packages</h3><br />' >>  /x1/buildmaster/master1/public_html/projects/openoffice/index.html
find . -name "*.exe" -exec echo '<li><a href=/projects/openoffice/install/win/{} title={}>{} </a></li>' \; | sort -r | sed -e s/\\.\\///g >> /x1/buildmaster/master1/public_html/projects/openoffice/index.html
cd /x1/buildmaster/master1/public_html/projects/openoffice/install/winsnap
echo '<hr /><br /><a href="https://ci.apache.org/projects/openoffice/buildlogs/winsnap/log/wntmsci12.pro.build.html" target="_blank">Windows Snapshot Build logs</a><br />
      <h3 id="winsnap">Windows Snapshot Packages</h3><br />' >>  /x1/buildmaster/master1/public_html/projects/openoffice/index.html
find . -name "*.exe" -exec echo '<li><a href=/projects/openoffice/install/winsnap/{} title={}>{} </a></li>' \; | sort -r | sed -e s/\\.\\///g >> /x1/buildmaster/master1/public_html/projects/openoffice/index.html
cd /x1/buildmaster/master1/public_html/projects/openoffice/
echo '</p>

</div> <!--end div id contenta -->' >> index.html
cat bottom.inc >> index.html

