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

# repocron.py - script for auto-creating new git repos on the fly.

import os, sys, re, urllib, json, subprocess
import time
import urllib.request
import smtplib
from email.mime.text import MIMEText


# Function for fetching a JSON object from HTTPS - nevermind the first bits :)
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

# If we have a valid JSON queue
if js:
    print("analysing %u items" % len(js))
    # For each item:
    # - Check that it hasn't been created yet
    # - Check that there isn't a repo by that name already
    # - Check that the repo name is valid
    for item in js:
        if not 'created' in item:
            reponame = item['name']
            # Validate name
            if len(reponame) < 5 or reponame.find("..") != -1 or reponame.find("/") != -1:
                print("Invalid repo name!")
                continue
            # Get some vars
            notify = item['notify']
            description = item['description'] if 'description' in item else "Unknown"
            
            # If repo isn't there already, make it..
            if not os.path.exists("/x1/git/repos/asf/%s" % reponame):
                print("%s is a new repo, creating it..." % reponame)
                try:
                    # Same as we alwyas do, but with editor disabled.
                    inp = subprocess.check_output("EDITOR=NONE /x1/git/asfgit-admin/asf/bin/asfgit-init-git -d \"%s\" -c \"%s\" /tmp/%s" % (description, notify, reponame), shell = True).decode('ascii', 'replace')
                    subprocess.check_output("mv /tmp/%s /x1/git/repos/asf/%s" % (reponame, reponame), shell = True).decode('ascii', 'replace')
                except subprocess.CalledProcessError as err:
                    print("Borked: %s" % err.output)
            else:
                print("Repo already exists, ignoring this request...sort of")
            
            # Notify reporeq that we've created this repository!
            print("Notifying https://reporeq.apache.org/ss.lua?created=%s" % reponame)
            request = urllib.request.Request("https://reporeq.apache.org/ss.lua?created=%s" % reponame)
            result = urllib.request.urlopen(request)
            
            # Notify infra@ and private@$pmc that the repo has been set up
            msg = MIMEText("New repository %s was created, as requested by %s.\nYou may view it at: https://git-wip-us.apache.org/repos/asf/%s\n\nWith regards,\nApache Infrastructure." % (reponame, item['requester'], reponame))
            msg['Subject'] = 'New git repository created: %s' % reponame
            msg['From'] = "git@apache.org"
            msg['Reply-To'] = "users@infra.apache.org"
            msg['To'] = "users@infra.apache.org, private@%s.apache.org" % item['pmc']
            
            s = smtplib.SMTP(host='mail.apache.org', port=2025)
            s.send_message(msg)
            s.quit()
            
            # We made a thing!
            created += 1

print("All done for today! Made %u new repos" % created)
