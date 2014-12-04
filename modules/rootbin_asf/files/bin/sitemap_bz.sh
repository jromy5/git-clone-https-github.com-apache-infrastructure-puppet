#!/bin/bash -eu
# Produces sitemap_$2_<n>.xml.gz
# and echos a newline-separated list of generated
# filenames to stdout

# Google wants <=50000 URLs per sitemap
BLOCK=50000

# Get row count
total=`mysql --no-defaults --skip-column-names --batch -u readbugs -e 'select count(*) from bugs;' $1`
count=$total
i=1
while [ $count -gt 0 ]
do
  offset=$(($total-$count))
  limit=$(($offset+$BLOCK))

  file=sitemap_$1_$i.xml.gz
  path=/tmp/$file
  if [ -e $path ] ; then
    rm $path
  fi

  {
  echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
  echo "<urlset xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\">"
  # cat << EOF | mysql --no-defaults --skip-column-names -u readbugs $1
  mysql --no-defaults --skip-column-names --batch -u readbugs -e " select CONCAT('<url><loc>https://issues.apache.org/$2/show_bug.cgi?id=', bug_id, '</loc><lastmod>', DATE_FORMAT(greatest(delta_ts,str_to_date('1,4,2010','%d,%m,%Y')),'%Y-%m-%d'), '</lastmod></url>') from bugs where bug_id > $offset and bug_id <= $limit;" $1
  #EOF
  echo "</urlset>"
  }| gzip > $path
  echo "$file"

  count=$(($count-$BLOCK))
  i=$(($i+1))
done
