#!/bin/sh
DATE_BIN=/bin/date
TODAY=`$DATE_BIN +%Y-%m-%d`

cd /x1/buildmaster/master1/public_html/projects/jmeter/nightlies

# remove r* directories older than 30 days first.
find . -mindepth 1 -maxdepth 1 -type d -name "r*" -mtime +29 -exec rm -rf {} \;

# create page header
cat header.inc > index.html
cat body-top.inc >> index.html
cat << 'EOD' >> index.html
  <table width="85%" cellpadding="1" cellspacing="1" border="1"> <!-- table 4 -->
    <thead>
      <tr>
        <th>Revision</th>
        <th>Build Date</th>
        <th colspan="4">Files to Download</th>
      </tr>
    </thead>
  <tbody>
EOD

# Find all directories named r*; remove leading r; descending numeric sort; pick first and add back r prefix
REV=`find . -mindepth 1 -maxdepth 1 -type d -name "r*" | sed -e 's!./r!!' | sort -gr | sed -ne '1s!^!r!p'`

# Show LATEST
echo '
<tr style="background-color:#F5F5AE;">
<td>LATEST ('$REV')</td>
<td>'$TODAY'</td>
<td><a href="'$REV'/apache-jmeter-'$REV'_bin.tgz">apache-jmeter-'$REV'_bin.tgz</a></td>
<td><a href="'$REV'/apache-jmeter-'$REV'_bin.zip">apache-jmeter-'$REV'_bin.zip</a></td>
<td><a href="'$REV'/apache-jmeter-'$REV'_src.tgz">apache-jmeter-'$REV'_src.tgz</a></td>
<td><a href="'$REV'/apache-jmeter-'$REV'_src.zip">apache-jmeter-'$REV'_src.zip</a></td>
</tr>' >> index.html


# List files in the format
# drwxrwxr-x  2 user  group  2  23 Mar 10:23 r2000
# Field: 1    2  3     4     5  6   7    8     9
# We assume that the user and group don't have spaces in them.

#  The --full-time flag has been removed , we are on FreeBSD 10 now.
ls -dlt r* | while read LINE
do
REV=`echo $LINE | cut -d ' ' -f9`
DATE=`echo $LINE | cut -d ' ' -f6,7`
# Now list all existing entries in reverse order
echo '<tr>
<!-- $LINE -->
<td>'$REV'</td>
<td>'$DATE'</td>
<td><a href="'$REV'/apache-jmeter-'$REV'_bin.tgz">apache-jmeter-'$REV'_bin.tgz</a></td>
<td><a href="'$REV'/apache-jmeter-'$REV'_bin.zip">apache-jmeter-'$REV'_bin.zip</a></td>
<td><a href="'$REV'/apache-jmeter-'$REV'_src.tgz">apache-jmeter-'$REV'_src.tgz</a></td>
<td><a href="'$REV'/apache-jmeter-'$REV'_src.zip">apache-jmeter-'$REV'_src.zip</a></td>
</tr>' >> index.html
done

# Add the footer
cat << 'EOD' >> index.html
    </tbody>
  </table> <!-- end table 4 -->
EOD
cat body-btm.inc >> index.html
