#!/usr/bin/env python3.4
# -*- coding: utf-8 -*-
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

# mirrorcron.py - script for auto-creating new git mirrors on the fly.

import os, sys, re, urllib, json, subprocess
import time
import urllib.request
import smtplib
from email.mime.text import MIMEText


# Function for fetching JSON via HTTPS
def getJSON(url, creds = None, cookie = None):
    headers = {}
    if creds and len(creds) > 0:
        xcreds = creds.encode(encoding='ascii', errors='replace')
        auth = base64.encodebytes(xcreds).decode('ascii', errors='replace').replace("\n", '')
        headers = {"Content-type": "application/json",
                     "Accept": "*/*",
                     "Authorization": "Basic %s" % auth
                     }

    request = urllib.request.Request(url, headers = headers)
    result = urllib.request.urlopen(request)
    return json.loads(result.read().decode('utf-8', errors = 'replace'))


# Get the current queue
js = getJSON("https://reporeq.apache.org/queue.json")
created = 0

# If queue is valid:
if js:
    print("analysing %u items" % len(js))
    
    # For each item:
    # - Check that it hasn't been mirrored yet
    # - Check that a repo with this name doesn't exist already
    # - Check that name is valid
    # - Mirror repo if all is okay
    for item in js:
        if not 'mirrored' in item and item['mirror'] == True and 'created' in item:
            reponame = item['name']
            # Check valid name
            if len(reponame) < 5 or reponame.find("..") != -1 or reponame.find("/") != -1:
                print("Invalid repo name!")
                continue
            # Set some vars
            notify = item['notify']
            description = item['description'] if 'description' in item else "Unknown"
            
            # If repo doesn't already exist, create it
            if not os.path.exists("/x1/git/mirrors/%s" % reponame):
                print("%s is a new repo, creating it..." % reponame)
                try:
                    inp = subprocess.check_output("/x1/git/bin/create-mirror-from-git.sh %s \"%s\"" % (reponame, description), shell = True).decode('ascii', 'replace')
                except subprocess.CalledProcessError as err:
                    print("Borked: %s" % err.output)
                    continue
            else:
                print("Repo already exists, ignoring this request...sort of")
            
            # Notify reporeq that we've created this repository!
            print("Notifying https://reporeq.apache.org/ss.lua?mirrored=%s" % reponame)
            request = urllib.request.Request("https://reporeq.apache.org/ss.lua?mirrored=%s" % reponame)
            result = urllib.request.urlopen(request)
            
            # Inform infra@ and private@$pmc that the mirror has been set up
            msg = MIMEText("New repository %s was mirrored to git.a.o (and thus GitHub), as requested by %s.\nNew mirrors are available on GitHub no more than 24 hours later.\n\nWith regards,\nApache Infrastructure." % (reponame, item['requester']))
            msg['Subject'] = 'New git mirror created: %s' % reponame
            msg['From'] = "git@apache.org"
            msg['Reply-To'] = "users@infra.apache.org"
            msg['To'] = "users@infra.apache.org, private@%s.apache.org" % item['pmc']
            
            s = smtplib.SMTP(host='mail.apache.org', port=2025)
            s.send_message(msg)
            s.quit()
            
            # We made a thing!
            created += 1

print("All done for today! Made %u new repos" % created)
