#!/bin/sh
cd /x1/buildmaster/master1/public_html/projects/xmlgraphics/batik/snapshots
# remove older than 30 days old snapshots first.

find . -maxdepth 1 -type f -mtime +29 -exec rm -f {} \;

# remove entries in table.inc that match the old files we just removed.
sed -e :a -e '$d;N;2,5ba' -e 'P;D' < ../table.inc > ../table.inc.tmp
mv ../table.inc.tmp ../table.inc

DATE_BIN=/bin/date
TODAY=`$DATE_BIN +%Y%m%d`

if [ -f batik-$TODAY.jar ]; then
    echo '<tr>' >> ../table.inc.tmp
    find . -name "batik-$TODAY*" -exec echo '<td class="basic"><a href={} title={}>{} </a></td>' \; | sort -r | sed -e s/\\.\\///g >> ../table.inc.tmp
    echo '</tr>' >> ../table.inc.tmp
    cat ../table.inc >> ../table.inc.tmp
    mv ../table.inc.tmp ../table.inc
fi

cat ../header.inc > index.html
cat ../body-top.inc >> index.html

echo '<a name="whatisthis"></a>
<h2 class="underlined_10">What is this?</h2>
<div class="section">
<p>
The downloads on this page are nightly snapshots, not official releases. That is, they may contain new bugs and regressions from
the official release. Not all unit tests were run during this build. On the other hand, they may also contain bug fixes and the latest and greatest features.
They may be useful for you, but you use them without the guarantees that come with an official release.</p>
</div>

<a name="snapshots"></a>
<h2 class="underlined_10">Download Nightly Snapshots.</h2>
<div class="section">
<p>A new snapshot is automatically generated once a day at 8am UTC. The name of the snapshot contains the date of generation. Each snapshot generates three versions of Apache Batik: a gzipped tar file, a zip file and a jar file. See the section on <a href="#installation">installation</a> for details. 30 days of download sets will be available.</p>
<table class="ForrestTable">
<thead>
<tr>
<th>jar</th><th>zip</th><th>tar.gz</th>
</tr>
</thead>
<tbody>' >> index.html

cat ../table.inc >> index.html

echo '</tbody></table>
        
</div>' >> index.html

cat ../body-btm.inc >> index.html
cat ../footer.inc >> index.html

