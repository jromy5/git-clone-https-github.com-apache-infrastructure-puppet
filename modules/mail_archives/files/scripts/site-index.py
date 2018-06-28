#!/usr/bin/env python

import urllib
import xml.etree.cElementTree as ET
import os
import sys

ROOT="/x1/mail-archives/mod_mbox"
OUTFILE = "/x1/mail-archives.apache.org/mod_mbox/index.html"

OUT = ""
# Get the list of podlings from a list the Incubator PMC maintains.
def _get_podlings():
  rv = set()
  u = urllib.urlopen("http://svn.apache.org/repos/asf/incubator/public/trunk/content/podlings.xml")
  string = u.read()
  root = ET.fromstring(string)
  for e in root:
    if e.get('status') == 'graduated':
      continue
    rv.add(e.attrib.get('resource'))
    rv.update(e.attrib.get('resourceAliases', ',').split(','))
  rv.remove('')
  return rv

podlings = _get_podlings()
tlps={}
count = 0
for files in os.listdir(ROOT):
    path = files
    tlp = path[0:path.find('-')]
    list = path[path.find('-')+1:]
    # print "%s - %s %s" % (tlp, list, path)
    if not os.access("%s/%s/listinfo.db" % (ROOT, path), os.F_OK):
        continue
    if tlp == "www":
       tlp = "asf-wide"
    if tlp in podlings: tlp += '.incubator'
    if not tlps.has_key(tlp):
        tlps[tlp] = {}
    tlps[tlp][list] = [path, 'incubator-'+path][tlp[:-10] in podlings]
    count = count + 1

keys = tlps.keys()
keys.sort()

# Ensure asf-wide lists comes first
keys.remove('asf-wide')
keys.insert(0,'asf-wide')

OUT += """<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
<head>
  <title>Available Mailing Lists</title>
  <style>
    body{
      background-color: white;
      background-image: url("/archives/feather.png");
      background-repeat: no-repeat;
      background-position: 98% 0.1em;
      background-size: 45px;
    }
    li h3{
      border-bottom: 1px #D42 solid;
      border-width: 5px;
    }
    li{
      list-style: none;
    }
    li ul{
      border: 1px #D42 solid;
      background-color: #eee;
    }
  </style>

</head>
<!-- Background white, links blue (unvisited), navy (visited), red
(active) -->
 <body
  bgcolor="#FFFFFF" text="#000000" link="#0000FF"
  vlink="#000080" alink="#FF0000">
<script type="text/javascript">
<!--
function TLP_onchange() {
document.location.hash = document.forms[0].TLP[document.forms[0].TLP.selectedIndex].value
}
-->
</script>
<h2>Welcome to the mail archives on mail-archives.apache.org.</h2>
<form action="" method="get" id="tlpform">
<table width="100%">
<tr align="left">
<i>Jump to a specific top-level archive section: </i>
<select size="1" name="TLP" onchange="return TLP_onchange()">
"""

for tlp in keys:
    OUT += "<option value=\"%s\">%s</option>" % \
          (tlp, tlp.replace('.incubator', ' (incubating)'))

OUT += """
</select>
</form>
<table width="100%">
<tr valign="top"><td>
<ul>
"""
i = 0
colcount = 0
for tlp in keys:
    if tlp == "asf-wide":
        OUT += "<li><h3><a name='asf-wide'>ASF-wide lists:</a></h3>"
    else:
        OUT += "<li><h3><a name='%s'>%s.apache.org lists:</a></h3>" % (tlp, tlp)
    OUT += "<ul>"
    klist = tlps[tlp].keys()
    klist.sort()
    for list in klist:
        OUT += "    <li><a href='%s/'>%s</a></li>" % (tlps[tlp][list], list)
        i = i + 1
        colcount = colcount + 1
    OUT += "</ul></li>"
    if colcount >= count/3:
        OUT += """</ul></td><td><ul>"""
        colcount = 0

OUT += """
</ul>
</td>
</tr>
</table>
</body>
</html>
"""

with open(OUTFILE, "w") as f:
    f.write(OUT)
    f.close()

print("Site index generated!")
