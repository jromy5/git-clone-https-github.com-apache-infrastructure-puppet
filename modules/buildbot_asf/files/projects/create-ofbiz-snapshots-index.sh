#!/bin/sh

cd /x1/buildmaster/master1/public_html/projects/ofbiz/snapshots
cat ../header.inc > index.html
cat ../body-top.inc >> index.html

echo '	<h2>OFBiz&trade; Nightly Snapshots</h2>
        <!-- column 1 -->
	<div id="col1">
	        <h3>Nightly Trunk Builds</h3>
                        <ul>' >> index.html

find . -name "*trunk*.zip" -exec echo '<li><a href={} title={}>{} </a></li>' \; | sort -r | sed -e s/\\.\\///g >> index.html

                        echo '</ul>
                <h3>Archived Trunk Builds</h3>
	                <ul>' >> index.html
cd ../archive/snapshots
find . -name "*trunk*.zip" -exec echo '<li><a href=/projects/ofbiz/archive/snapshots/{} title={}>{} </a></li>' \; | sort -r | sed -e s/\\.\\///g >> ../../snapshots/index.html
cd ../../snapshots

                        echo '</ul>
        </div>
	<!-- column 1 -->
	<!-- column 2 -->
	<div id="col2">
         	<h3>Nightly 13.07 Builds</h3>
		        <ul>' >> index.html

find . -name "*rel13.07*.zip" -exec echo "<li><a href={} title={}>{} </a></li>" \; | sort -r | sed -e s/\\.\\///g >> index.html

                        echo '</ul>
                        <ul>
			        <li><a href='/projects/ofbiz/archive/snapshots' title='Download archives of 13.07 snapshots'>Download archives of 13.07 snapshots</a></li>
		        </ul>

         	<h3>Nightly 12.04 Builds</h3>
		        <ul>' >> index.html

find . -name "*rel12.04*.zip" -exec echo "<li><a href={} title={}>{} </a></li>" \; | sort -r | sed -e s/\\.\\///g >> index.html

                        echo '</ul>
                        <ul>
			        <li><a href='/projects/ofbiz/archive/snapshots' title='Download archives of 12.04 snapshots'>Download archives of 12.04 snapshots</a></li>
		        </ul>

            <h3>Nightly 11.04 Builds (Discontinued)</h3>
		        <ul><p>No more nightlies supplied</p></ul>

         	<h3>Nightly 10.04 Builds (Discontinued)</h3>
		       <ul><p>No more nightlies supplied</p></ul>

		       <h3>Nightly 9.04 Builds (Discontinued)</h3>
		       <ul><p>No more nightlies supplied</p></ul>

            <h3>Nightly 4.0 Builds (Discontinued)</h3>
		       <ul><p>No more nightlies supplied</p></ul>

	</div>
	<!-- column 2 -->' >> index.html

cat ../body-btm.inc >> index.html
cat ../footer.inc >> index.html

