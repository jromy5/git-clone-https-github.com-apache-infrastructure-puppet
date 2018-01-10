#!/usr/bin/env python
#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# This is maildomains.cgi
import sys
import cgi
import requests
import json

# CGI interface
xform = cgi.FieldStorage();

# Check list availability?
lname = xform.getvalue('list', None)
if lname:
        print("Status: 404\r\n\r\nList %s alrerady exists!" % lname)
        sys.exit(0)

# Get all TLPs
rv = requests.get("https://whimsy.apache.org/public/committee-info.json")
domains = rv.json()['committees']

# Add in current podlings
rv = requests.get("https://whimsy.apache.org/public/public_podlings.json")
podlings = {k: v for k, v in rv.json()['podling'].iteritems() if v['status'] == 'current' }
domains.update(podlings)

dlist = ['apache.org']
for cmt in domains:
    info = domains[cmt]
    if not 'mail_list' in info or not ('@' in info['mail_list'] or ' ' in info['mail_list']):
        part = info.get('mail_list', cmt)
        if part == 'infrastructure':
            part = 'infra' # TO-DO: Ask Sam how to change this
        dlist.append("%s.apache.org" % part)

print("Status: 200\r\nContent-Type: application/json\r\n\r\n")
print(json.dumps(sorted(dlist)))
