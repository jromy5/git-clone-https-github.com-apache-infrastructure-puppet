#!/bin/bash -eu
# Produces sitemap_jira_.*.xml.gz
# and echos a newline-separated list of generated
# filenames to stdout.

# Google wants <=50000 URLs per sitemap
BLOCK=50000
DEBUG=false
PSQL=/usr/local/bin/psql
DB=jira-main

debug()
{
    if $DEBUG; then echo >&2 $*; fi
}

# Get row count
total=`$PSQL $DB -tAc "select count(id) from jiraissue;"`
count=$total
i=1
debug "Processing $total rows"

while [ $count -gt 0 ]
do
    offset=$(($total-$count))

    if [ $(($offset+$BLOCK)) -lt $total ]
    then
        debug "Generating Jira sitemap for $offset to $(($offset+$BLOCK))"
    else
        debug "Generating Jira sitemap for $offset to $total"
    fi

    file=sitemap_jira_$i.xml.gz
    path=/tmp/$file
    if [ -e $path ] ; then
      rm $path
    fi

    {
    echo '<?xml version="1.0" encoding="UTF-8"?>'
    echo '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">'

    $PSQL $DB -tAc "select '<url><loc>https://issues.apache.org/jira/browse/' || pkey || '</loc><lastmod>' || to_char(updated,'YYYY-MM-DD') || '</lastmod></url>' from jiraissue order by updated limit $BLOCK offset $offset;"

    echo '</urlset>'
    }| gzip > $path
    echo "$file"

    count=$(($count-$BLOCK))
    i=$(($i+1))
done
