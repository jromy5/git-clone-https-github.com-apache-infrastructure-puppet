#!/bin/sh
DATE_BIN=/bin/date
TODAY=`$DATE_BIN +%d-%m-%Y`

cd /x1/buildmaster/master1/public_html/projects/subversion/nightlies

REV=`find dist/ -mindepth 1 -type d -mtime 0 | sed -e s'|dist/||'`

echo '<tr>
<td>'$REV'</td>
<td>'$TODAY'</td>
<td><a href="dist/'$REV'/subversion-nightly.tar.gz">subversion-nightly.tar.gz</a></td>
<td><a href="dist/'$REV'/subversion-nightly.tar.bz2">subversion-nightly.tar.bz2</a></td>
<td><a href="dist/'$REV'/subversion-nightly.zip">subversion-nightly.zip</a></td>
<td><a href="dist/'$REV'/svn_version.h.dist">svn_version.h.dist</a></td>
<td><a href="dist/'$REV'/subversion-nightly.tar.gz.sha1">subversion-nightly.tar.gz.sha1</a></td>
<td><a href="dist/'$REV'/subversion-nightly.tar.bz2.sha1">subversion-nightly.tar.bz2.sha1</a></td>
<td><a href="dist/'$REV'/subversion-nightly.zip.sha1">subversion-nightly.zip.sha1</a></td>
</tr>' >> table.inc.tmp
    cat table.inc >> table.inc.tmp
    mv table.inc.tmp table.inc

# remove older than 30 days here.

# find dist -maxdepth 1 -mtime +29 -exec rm -f {} \;

# Note: Enable the below 3 lines when we have enough in the table.
# remove entries in table.inc that match the old files we just removed.
# sed -e :a -e '$d;N;2,10ba' -e 'P;D' < table.inc > table.inc.tmp
# mv table.inc.tmp table.inc

cat header.inc > index.html
cat body-top.inc >> index.html

echo '<tr style="background-color:#F5F5AE;">
<td>LATEST ('$REV')</td>
<td>'$TODAY'</td>
<td><a href="dist/subversion-nightly.tar.gz">subversion-nightly.tar.gz</a></td>
<td><a href="dist/subversion-nightly.tar.bz2">subversion-nightly.tar.bz2</a></td>
<td><a href="dist/subversion-nightly.zip">subversion-nightly.zip</a></td>
<td><a href="dist/svn_version.h.dist">svn_version.h.dist</a></td>
<td><a href="dist/subversion-nightly.tar.gz.sha1">subversion-nightly.tar.gz.sha1</a></td>
<td><a href="dist/subversion-nightly.tar.bz2.sha1">subversion-nightly.tar.bz2.sha1</a></td>
<td><a href="dist/subversion-nightly.zip.sha1">subversion-nightly.zip.sha1</a></td
</tr>' >> index.html
cat table.inc >> index.html
cat body-btm.inc >> index.html

