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

import json
import os
import sys
import time
import cgi
import requests
import base64
import subprocess
import re
import sscommon
import fcntl

requser = os.environ['REMOTE_USER']
staffers = ['humbedooh','gmcdonald','cml','pono','christ','gstein']

def checkDomain(dom):
    """Check if an apache.org ML domain exists or not"""
    rv = requests.get("https://whimsy.apache.org/public/committee-info.json")
    domains = rv.json()['committees']

    # TODO this includes retired and graduated podlings
    rv = requests.get("https://whimsy.apache.org/public/public_podlings.json")
    domains.update(rv.json()['podling'])

    dlist = ['apache.org']
    for cmt in domains:
        info = domains[cmt]
        if not 'mail_list' in info or not ('@' in info['mail_list'] or ' ' in info['mail_list']):
            dlist.append("%s.apache.org" % (info['mail_list'] if 'mail_list' in info else cmt))

    if not dom in dlist:
        return False
    return True



form = cgi.FieldStorage();

# Get and validate domain part
domain = form.getvalue('domain', None)
if not domain or not checkDomain(domain):
    sscommon.buggo("Invalid domain name!")

# Get and validate list part
lists = []
listname = form.getvalue('list', None)
presets = form.getlist('preset')
# Podlists == create the three default lists for new podlings
if presets:
    for val in presets:
        if not presets or not re.match(r"^[a-z0-9]+(?:-[a-z0-9]+)?$", val):
            sscommon.buggo("Invalid list name specified!")
    lists = presets
else:
    if not listname or not re.match(r"^[a-z0-9]+(?:-[a-z0-9]+)?$", listname):
        sscommon.buggo("Invalid list name specified!")
    lists = [listname]

# No Digest List, all lists have a -digest subscription anyway

if "digest" in lists:
  sscommon.buggo("Invalid list name digest.")

# Get and validate mods
mods = form.getvalue('moderators', "").split("\n")
for mod in mods:
    if not re.match(r"^\S+@\S+$", mod):
        sscommon.buggo("Invalid moderator email (no spaces or commas, please!)")

# Get and validate private option
private = form.getvalue("private", False)
if private and listname not in ['private', 'security'] and requser not in staffers:
    sscommon.buggo("Only private@ and security@ can be private by default!")

muopts = form.getvalue('muopts', 'mu')
if not muopts in ['mu', 'Mu', 'mU']:
    sscommon.buggo("Invalid moderation setting requested!")

trailer = form.getvalue('trailer', 'T')
if trailer == 'true':
    trailer = 't'

# Time of request (add 12h to process)
reqqed = int(time.time())

# If staffer, we can expedite requests by faking the request time.
speedup = form.getvalue('expedite', 'false')
if speedup == 'true' and requser in staffers:
    speedup = True
    reqqed -= 86400
else:
    speedup = False

for newlist in lists:
    # Write payload to file
    payload = {
        'type': 'mailinglist',
        'requester': requser,
        'requested': reqqed,
        'domain': domain,
        'list': newlist,
        'muopts': muopts,
        'private': True if (private or newlist in ['private', 'security']) else False, # Force private for private+security@
        'mods': mods,
        'trailer': trailer,
        'expedited': speedup
    }

    filename = "mailinglist-%s-%s.json" % (newlist, domain)
    filepath = "/usr/local/etc/selfserve/queue/" + filename
    # to properly guard against concurrent writes the file cannot be opened by more that one process at once
    # use an external lock file. Create this under /tmp so they will be cleared up from time to time
    lockfile = "/tmp/" + filename + '.lock'
    with open(lockfile, "w") as lock, open(filepath, "w") as f:
        fcntl.flock(lock, fcntl.LOCK_EX)
        json.dump(payload, f)

    add = "This list has been marked as private. " if payload['private'] else ""
    sscommon.sendemail("%s@apache.org" % requser, "New mailing list queued for creation: %s@%s" % (newlist, domain),
    """
    Hi there,
    As requested by %s@apache.org, a new mailing list has been queued for creation:
    %s@%s

    %s
    This request will automatically be processed within 24 hours.
    """ % (requser, newlist, domain, add))
    sscommon.hipchat("A new mailing list, <kbd>%s@%s</kbd>, has been queued for creation, as requested by %s@apache.org. %s" % (newlist, domain, requser, add))
print("Status: 201 Created\r\n\r\n<h2>Mailing List request received!</h2>Your request for a new mailing list has been received and will automatically be processed within 24 hours. We will notify your PMC when the list has been created.")
