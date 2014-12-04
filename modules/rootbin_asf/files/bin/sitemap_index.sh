#! /bin/bash

SMDIR=/jails/ull.zones.apache.org/usr/local/www/apache22/issues-data/sitemaps

EIRID=`jls -j eir jid`
SIFID=`jls -j sif jid`

BZ_SITEMAPS=$(
  jexec "$EIRID" /root/bin/sitemap_bz.sh bugs bugzilla
)

SABZ_SITEMAPS=$(
  jexec "$EIRID" /root/bin/sitemap_bz.sh sabugs SpamAssassin
)

OOOBZ_SITEMAPS=$(
  jexec "$SIFID"  /root/bin/sitemap_bz.sh ooobugs ooo
)

lastmod=`date +%Y-%m-%d`

echo '<?xml version="1.0" encoding="UTF-8"?>
<sitemapindex xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">'
for SM in $BZ_SITEMAPS
do
  mv /jails/eir.zones.apache.org/tmp/$SM $SMDIR
  echo -n "  <sitemap>
    <loc>https://issues.apache.org/sitemaps/$SM</loc>
    <lastmod>${lastmod}</lastmod>
  </sitemap>"
done
for SM in $SABZ_SITEMAPS
do
  mv /jails/eir.zones.apache.org/tmp/$SM $SMDIR
  echo -n "  <sitemap>
    <loc>https://issues.apache.org/sitemaps/$SM</loc>
    <lastmod>${lastmod}</lastmod>
  </sitemap>"
done
for SM in $OOOBZ_SITEMAPS
do
  mv /jails/sif.zones.apache.org/tmp/$SM $SMDIR
  echo -n "  <sitemap>
    <loc>https://issues.apache.org/sitemaps/$SM</loc>
    <lastmod>${lastmod}</lastmod>
  </sitemap>"
done

echo '</sitemapindex>'
