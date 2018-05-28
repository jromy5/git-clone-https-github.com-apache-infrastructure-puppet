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

"""
This is selfserve-make-lists.py - process ML queue and make new lists.

Runbook:
        - Should run every 2-4 hours as a cron job, owned by apmail
        - only accepts requests >= 12 hours old (grace period)
        - validates the JSON request (valid fqdn, list name, muopts, mods etc)
        - checks if the fqdn (foo.apache.org) has been set up in ezmlm,
          if not, create it and update qmail too.
        - runs makelist-apache.sh with the supplied args (after whitelisting)
        - notifies infra and $project about new list
        - on error, notifies infra with what/why, halts queue
"""

import sys
import json
import os
import re
import urllib3
urllib3.disable_warnings() # Mute urllib3 on fbsd - it gets loud!
import requests
import subprocess
import smtplib
import time
import email.utils

execfile("common.conf")

# Define some vars
QUEUE_URL =     "https://selfserve.apache.org/cgi-bin/queue.cgi"
DEBUG =         False # Set to true to not actually make lists, just process
                     # queue and remove items after fake-processing them.
ROOT_DOMAIN =   "apache.org" # Our root domain, don't accept if no match.
INFRAML =       'private@infra.apache.org' # Infra ML

# Valid moderation settings
MUDICT = {
        "mu": "Allow subscribers to post, moderate all others",
        "Mu": "Allow subscribers to post, reject all others",
        "mU": "Moderate all posts"
}

# I thought of using ezt here, but it's just one message, so...
ML_CREATED_TMPL = """
As requested by %s, the following mailing list has been created:
        List name: %s@%s
        Moderators: %s
        Settings: %s
        Reply-To: %s
        %s

---

The list will start accepting mail in 60 minutes from now.  If it's a public
list, it will appear on https://lists.apache.org/ within a few minutes of
the first post to it.
"""


def sendemail(rcpt, subject, message):
    """Simple email helper function"""
    sender = "ASF Self-Service Platform <selfserve@apache.org>"
    receivers = [rcpt]
    if isinstance(rcpt, list):
        receivers = rcpt
    # Weed out infra, we're adding that explicitly to every email.
    receivers = [k for k in receivers if k != INFRAML]
    receivers.append("ASF Infrastructure <%s>"% INFRAML)
    msgid = email.utils.make_msgid()
    msg = """From: %s
Message-ID: %s
To: %s
Reply-To: ASF Infrastructure <users@infra.apache.org>
Subject: %s

%s

With regards,
ASF Self-Service Platform, https://selfserve.apache.org
For inquiries, please contact: users@infra.apache.org
""" % (sender, msgid, ", ".join(receivers), subject, message)
    msg = msg.encode('ascii', errors='replace')
    smtpObj = smtplib.SMTP("mail.apache.org:2025")
    smtpObj.sendmail(sender, receivers, msg)


def process_request(entry):
    # Gather data
    eid = entry['id']
    requester = entry['requester']
    fqdn = entry['domain']
    project = fqdn.split('.')[0] # get first part before a dot
    listname = entry['list']
    mods = ",".join(entry['mods'])
    muopts = entry['muopts']
    private = entry.get('private', False)
    trailer = entry.get('trailer', None)

    # This list should hopefully remain empty!
    errors = []

    # FQDN must be foo.apache.org or just apache.org, reject all others
    if not re.match(r"^([-.a-z0-9]+\.)?apache\.org$", fqdn):
        errors.append("Invalid FQDN")
    # Project must be valid [a-z0-9] name, but can be omitted
    if re.search(r"[^a-z0-9]", project):
        errors.append("Invalid apache project requested")
    # Listname must exist and be valid [a-z0-9](-[a-z0-9]) name
    # like foo or foo-chat
    if not listname or not re.match(r"^[a-z0-9]+(?:-[a-z0-9]+)?$", listname):
        errors.append("Invalid or missing list name")
    # No bad chars in the mod addresses
    if re.search(r"[&;<>!\"\s\?\\]", mods) or len(mods) < 6:
        errors.append("Invalid or missing moderator list")
    # muopts must be one of three recognized options
    if muopts not in ['mu', 'Mu', 'mU']:
        errors.append("Invalid muopts. Must be mu, Mu or mU")
    # Mailing list can't already exist
    if os.path.exists("LISTS_DIR/%s/%s" % (fqdn, listname)):
        errors.append("This mailing list appears to already exist!")

    if errors:
        return errors

    # Make the list if all the above proved to be valid.
    print("Preparing to create %s@%s..." % (listname, fqdn))

    # Make sure parent fqdn exists, and if not, make it.
    # NOTE: This does NOT set up DNS entries for new podlings.
    # We'll have to that manually still, and wait for an automated
    # solution later on.
    if not os.path.exists("LISTS_DIR/%s" % fqdn):
        print(" - %s seems to be a new FQDN, setting up parent dir first" % fqdn)
        try:
            if not DEBUG:
                os.mkdir("LISTS_DIR/%s" % fqdn)
                os.chmod("LISTS_DIR/%s" % fqdn, 0o755)
            print(" - adding %s to rcpthosts" % fqdn)
            if not DEBUG:
                open("/var/qmail/control/rcpthosts", "a").write("%s\n" % fqdn)
            print(" - adding %s to virtualdomains" % fqdn)
            if not DEBUG:
                open("/var/qmail/control/virtualdomains", "a").write("%s:apmail-%s\n" % (fqdn, project))
            print(" - all done, you may have to run the following (I can't do that!): pkill -HUP qmail-send")
        except Exception as err:
            reason = "Could not set up ezmlm/qmail, aborting: %s" % err
            print(reason)
            # Just bail out now
            return [ reason ]

    # Now construct the args for makelist-apache.sh:

    # Basic bash binary and script name
    args = ['/usr/local/bin/bash', 'BIN_DIR/makelist-apache.sh']

    # muopts (-mu, -Mu or -mU)
    args.append('-' + muopts)
    print(" - muopts set to %s: %s" % (muopts, MUDICT[muopts]))
    
    # Trailer?
    if trailer and trailer == 't':
        args.append('-t')

    # Moderators (-m foo@bar.baz,bar@foo.pony)
    args.extend(['-m', mods])
    print(" - moderators: %s" % mods)

    # -v listname, if not foo@apache.org
    if project and fqdn != ROOT_DOMAIN:
        args.extend(['-v', project])
        print(" - this is a 3rd level domain (%s), adding -v flag" % fqdn)
    else:
        print(" - this is a 2nd level domain (%s), not adding -v" % fqdn)

    # Make sure private@ and security@ are always private
    if listname in ['private', 'security']:
        print(" - this is %s@, forcing private flag" % listname)
        private = True

    # Prefix list name with . if private
    ptxt = "This list is public."
    if private:
        args.append('.' + listname)
        ptxt= "This list is private."
        print(" - prefixing list name wih . to signify privacy")
    else:
        args.append(listname)
        print(" - this is a public list")
        
    # If commits|cvs|svn|notif*|issue*@, then note reply-to is dev@
    rto = "%s@%s" % (listname, fqdn)
    if re.match(r"(commits|cvs|svn|notif.*|issue.*)$", listname):
        rto = "dev@%s (forced)" % fqdn

    # Run makelist-apache.sh with args
    print("Going to create %s@%s now..." % (listname, fqdn))
    if not DEBUG:
        print("Running: %s" % " ".join(args))
        try:
            subprocess.check_output(args, stderr=subprocess.STDOUT)
        except subprocess.CalledProcessError as err:
            reason = "makelist returned an error: %s" % err.output
            print("Bork: %s" % reason)
            # Just bail out now
            return [ reason ]
    else:
        print("[DBG] Would run: %s" % " ".join(args))

    notify = [ "%s@apache.org" % requester ]
    # If there exists a private list already, notify it
    if listname != "private" and os.path.exists("LISTS_DIR/%s/private" % fqdn):
        notify.append('private@%s' % fqdn)
    # Notify security@apache.org of all new security list.
    if listname == 'security':
        notify.append('security@apache.org')
    sendemail(notify,
          "[NOTICE] List created: %s@%s" % (listname, fqdn),
          ML_CREATED_TMPL % (requester, listname, fqdn, mods,
                             MUDICT[muopts], rto, ptxt))
    print("Done, removing %s from queue" % eid)
    requests.get("%s?rm=%s" % (QUEUE_URL, eid))

    return [ ]


def main():
    # Fetch queue
    rv = requests.get(QUEUE_URL)
    queue = rv.json()

    # Keep score of queue size and time
    processed = 0
    now = int(time.time())


    # Go through queue
    for entry in queue:
        # We only handle mailing lists!
        if entry.get('type') != "mailinglist":
            continue

        # Make sure this request is old enough, >= 12h
        if entry['requested'] > (now - (3600 * 12)):
            print("skipping %s, request too new!" % entry['id'])
            continue

        processed += 1

        # Do all the work for this ML requeset
        errors = process_request(entry)

        # If we found a buggo, ABORT!
        if errors:
            print("Request was not valid: \n%s" % ", ".join(errors))
            print("Notifying %s" % INFRAML)
            sendemail(INFRAML, "Creation of mailing list FAILED!", "As a precaution, the queue has been suspended. Will retry in 4 hours!\nOutput from program was: %s\n\nJSON input was: \n%s\n" % ("\n".join(errors), json.dumps(entry)))
            break

    print("All done for now, processed %u list requests" % processed)


if __name__ == '__main__':
    main()
