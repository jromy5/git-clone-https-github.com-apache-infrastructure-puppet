#!/usr/bin/env python2.7
 
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
 
"""
Generates a list of podling dev mailing lists based on podlings.xml contents (incubator-podlings@a.o)
Also generates the ppmcs@a.o alias containing all the private@ lists for current podlings
"""
 
import sys
if sys.version_info < (2, 7):
    raise Exception("Python 2.7 or above is required")
 
import xml.dom.minidom
import urllib

execfile("common.conf")

PODLINGS_URL = 'http://svn.apache.org/repos/asf/incubator/public/trunk/content/podlings.xml'
SPECIALS = ['wave','blur']

 
def processPodlings(xmlFile):
    """
    Parse a podlings.xml stream
    """
    dom = xml.dom.minidom.parse(xmlFile)
    with open("APMAIL_HOME/.qmail-incubator-podlings", "w") as f, \
         open("APMAIL_HOME/.qmail-ppmcs", "w") as g:
        for row in dom.getElementsByTagName("podling"):
            if row.getAttribute("status") != 'current':
                continue
            podling_id = row.getAttribute("name").strip()
            podling_id = podling_id.lower().replace(' ', '')
            if podling_id == 'odftoolkit':
                f.write("odf-dev@incubator.apache.org\n")
                g.write("odf-private@incubator.apache.org\n")
            elif podling_id in SPECIALS:
                f.write("%s-dev@incubator.apache.org\n" % podling_id)
                g.write("%s-private@incubator.apache.org\n" % podling_id)
            else:
                f.write("dev@%s.incubator.apache.org\n" % podling_id)
                g.write("private@%s.incubator.apache.org\n" % podling_id)

def main():
    podlings_xml = urllib.urlopen(PODLINGS_URL)
    processPodlings(podlings_xml)
 
if __name__ == '__main__':
    main()
