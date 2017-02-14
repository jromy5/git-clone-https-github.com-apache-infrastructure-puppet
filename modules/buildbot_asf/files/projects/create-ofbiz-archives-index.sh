#!/bin/sh

cd /x1/buildmaster/master1/public_html/projects/ofbiz/archive/snapshots
cat ../../header.inc > index.html
cat ../../body-top.inc >> index.html

echo '	<h2>OFBiz&trade; Archived Snapshots</h2>
		<!-- column 1 -->
		<div id="col1">
			<h3>Archived Trunk Builds</h3>
<ul>' >> index.html

find . -name "*trunk*.zip" -exec echo '<li><a href={} title={}>{} </a></li>' \; | sort -r | sed -e s/\\.\\///g >> index.html

echo '</ul>
<ul>
	<li><a href="/projects/ofbiz/snapshots/" title="Download current trunk snapshots">Download current trunk snapshots</a></li>
</ul>
</div>
	<!-- column 1 -->
	<!-- column 2 -->
	<div id="col2">
        	<h3>Archived 13.07 Builds</h3>
		<ul>' >> index.html

find . -name "*rel13.07*.zip" -exec echo '<li><a href={} title={}>{} </a></li>' \; | sort -r | sed -e s/\\.\\///g >> index.html

echo '</ul>
<ul>
			<li><a href='/projects/ofbiz/snapshots' title='Download current 13.07 snapshots'>Download current 13.07 snapshots</a></li>
		</ul>
        	<h3>Archived 12.04 Builds</h3>
		<ul>' >> index.html

find . -name "*rel12.04*.zip" -exec echo '<li><a href={} title={}>{} </a></li>' \; | sort -r | sed -e s/\\.\\///g >> index.html

echo '</ul>
<ul>
			<li><a href='/projects/ofbiz/snapshots' title='Download current 12.04 snapshots'>Download current 12.04 snapshots</a></li>
		</ul>

    <h3>Archived 11.04 Builds  (Discontinued)</h3>
    <h3>Archived 10.04 Builds (Discontinued)</h3>
    <h3>Archived 9.04 Builds (Discontinued)</h3>
    <h3>Archived 4.0 Builds (Discontinued)</h3>


echo "</ul>
	</div>
	<!-- column 2 -->" >> index.html

cat ../../body-btm-archive.inc >> index.html
cat ../../footer.inc >> index.html

