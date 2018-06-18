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

# This is issues.cgi: Handler for GitHub issues (and PRs)

import json
import os
import sys
import time
import cgi
import netaddr
import smtplib
import sqlite3
import git
import re
import ezt
import StringIO
from email.mime.text import MIMEText
import requests
import base64
import email.utils
import email.header

# Define some defaults and debug vars
DEBUG_MAIL_TO = None # "humbedooh@apache.org" # Set to a var to override mail recipients, or None to disable.
DEFAULT_SENDMAIL = True             # Should we default to sending an email to the list? (this is very rarely no)
DEFAULT_JIRA_ENABLED = True         # Is JIRA bridge enabled by default?
DEFAULT_JIRA_ACTION = "comment"     # Default JIRA action (comment/worklog)

# CGI interface
xform = cgi.FieldStorage();

# Check that this is GitHub calling
from netaddr import IPNetwork, IPAddress
GitHubNetwork = IPNetwork("192.30.252.0/22") # This is GitHub's current
                                             # net block. May change!
callerIP = IPAddress(os.environ['REMOTE_ADDR'])
if not callerIP in GitHubNetwork:
    print("Status: 401 Unauthorized\r\nContent-Type: text/plain\r\n\r\nI don't know you!\r\n")
    sys.exit(0)


### Helper functions ###
def getvalue(key):
    val = xform.getvalue(key)
    if val:
        return val
    else:
        return None

def sendEmail(rcpt, subject, message):
    sender = "GitBox <git@apache.org>"
    receivers = [rcpt]
    sub = email.header.Header(subject, 'utf-8').encode()
    msg = """From: %s
To: %s
Subject: %s
Message-ID: %s
Date: %s
Content-Type: text/plain; charset=utf-8
Content-Transfer-Encoding: 8bit

%s

With regards,
Apache Git Services
""" % (sender, rcpt, sub, email.utils.make_msgid("gitbox"), email.utils.formatdate(), message)
    msg = msg.encode('utf-8', errors='replace')
    try:
        smtpObj = smtplib.SMTP("mail.apache.org:2025")
        smtpObj.sendmail(sender, receivers, msg)
    except smtplib.SMTPException:
        raise Exception("Could not send email - SMTP server down or you put .incubator in the recip address, remove it!")

################################
# Message formatting functions #
################################

TMPL_NEW_TICKET = """
GitHub user %(user)s opened a new %(type)s: %(title)s

%(text)s

You can view it online at: %(link)s
"""

TMPL_CLOSED_TICKET = """
GitHub user %(user)s closed #%(id)i: %(title)s

You can view it online at: %(link)s

%(diff)s
"""

TMPL_GENERIC_COMMENT = """
GitHub user %(user)s commented on %(type)s #%(id)i: %(title)s:

%(text)s

You can view it online at: %(link)s
"""

def issueOpened(payload):
    fmt = {}
    obj = payload['pull_request'] if 'pull_request' in payload else payload['issue']
    fmt['user'] = obj['user']['login']
    # PR or issue??
    fmt['type'] = 'issue'
    if 'pull_request' in payload:
        fmt['type'] = 'pull request'
    fmt['id'] = obj['number']
    fmt['text'] = obj['body']
    fmt['title'] = obj['title']
    fmt['link'] = obj['html_url']
    fmt['action'] = 'open'
    return fmt

def issueClosed(payload):
    fmt = {}
    obj = payload['pull_request'] if 'pull_request' in payload else payload['issue']
    fmt['user'] = payload['sender']['login'] if 'sender' in payload else obj['user']['login']
    # PR or issue??
    fmt['type'] = 'issue'
    if 'pull_request' in payload:
        fmt['type'] = 'pull request'
    fmt['id'] = obj['number']
    fmt['text'] = "" # empty line when closing, so as to not confuse
    fmt['title'] = obj['title']
    fmt['link'] = obj['html_url']
    fmt['action'] = 'close'
    fmt['prdiff'] = None
    # If foreign diff, we have to pull it down here
    if obj.get('head') and obj['head'].get('repo') and obj['head']['repo'].get('full_name') and obj.get('diff_url'):
        if not obj['head']['repo']['full_name'].startswith("apache/"):
            txt = requests.get(obj['diff_url']).text
            addendum = None
            # No greater than 5MB or 20,000 lines, whichever comes first.
            if len(txt) > 5000000:
                txt = txt[:5000000]
                addendum = "This diff was greater than 5MB in size, and has been truncated"
            lines = txt.split("\n")
            if len(lines) > 20000:
                txt = "\n".join(lines[:20000])
                addendum = "This diff was longer than 20,000 lines, and has been truncated"
            if addendum:
                txt += "\n\n  (%s...)\n" % addendum
            fmt['prdiff'] = """
As this is a foreign pull request (from a fork), the diff is supplied
below (as it won't show otherwise due to GitHub magic):

%s
""" % txt
    return fmt


def ticketComment(payload):
    fmt = {}
    obj = payload['pull_request'] if 'pull_request' in payload else payload['issue']
    comment = payload['comment']
    # PR or issue??
    fmt['type'] = 'issue'
    if 'pull_request' in payload:
        fmt['type'] = 'pull request'
    # This is different from open/close payloads!
    fmt['user'] = comment['user']['login']
    fmt['id'] = obj['number']
    fmt['text'] = comment['body']
    fmt['title'] = obj['title']
    fmt['link'] = comment['html_url']
    fmt['action'] = payload.get('action', 'created')
    return fmt


def reviewComment(payload):
    fmt = {}
    obj = payload['pull_request'] if 'pull_request' in payload else payload['issue']
    comment = payload['comment']
    # PR or issue??
    fmt['type'] = 'issue'
    if 'pull_request' in payload:
        fmt['type'] = 'pull request'
    fmt['user'] = comment['user']['login']
    fmt['id'] = obj['number']
    fmt['text'] = comment['body']
    fmt['title'] = obj['title']
    fmt['link'] = comment['html_url']
    fmt['action'] = "diffcomment"
    fmt['diff'] = comment['diff_hunk']
    fmt['filename'] = comment['path']
    return fmt

def formatEmail(fmt):
    subjects = {
        'open':         "opened a new %(type)s",
        'close':        "closed %(type)s",
        'comment':      "commented on %(type)s",
        'created':      "commented on %(type)s",
        'edited':       "edited a comment on %(type)s",
        'deleted':      "removed a comment on %(type)s",
        'diffcomment':  "commented on a change in %(type)s"
    }
    fmt['action'] = (subjects[fmt['action']] if fmt['action'] in subjects else subjects['comment']) % fmt
    fmt['subject'] = "%(user)s %(action)s #%(id)i: %(title)s" % fmt
    template = ezt.Template('template.ezt')
    fp = StringIO.StringIO()
    output = template.generate(fp, fmt)
    body = fp.getvalue()
    return {
        'subject': "[GitHub] %s" % fmt['subject'], # Append [GitHub] for mail filters
        'message': body
    }

def updateTicket(ticket, name, txt, worklog):
    auth = open("/x1/jirauser.txt").read().strip()
    auth = str(base64.encodestring(bytes(auth))).strip()

    # Post comment or worklog entry!
    headers = {"Content-type": "application/json",
                 "Accept": "*/*",
                 "Authorization": "Basic %s" % auth
                 }
    try:
        where = 'comment'
        data = {
            'body': txt
        }
        if worklog:
            where = 'worklog'
            data = {
                'timeSpent': "10m",
                'comment': txt
            }

        rv = requests.post("https://issues.apache.org/jira/rest/api/latest/issue/%s/%s" % (ticket, where),headers=headers, json = data)
        if rv.status_code == 200 or rv.status_code == 201:
            return "Updated JIRA Ticket %s" % ticket
        else:
            return rv.text
    except:
        pass # Not much to do just yet

def remoteLink(ticket, url, prno):
    auth = open("/x1/jirauser.txt").read().strip()
    auth = str(base64.encodestring(bytes(auth))).strip()

    # Post comment or worklog entry!
    headers = {"Content-type": "application/json",
                 "Accept": "*/*",
                 "Authorization": "Basic %s" % auth
                 }
    try:
        urlid = url.split('#')[0] # Crop out anchor
        data = {
            'globalId': "github=%s" % urlid,
            'object':
                {
                    'url': urlid,
                    'title': "GitHub Pull Request #%s" % prno,
                    'icon': {
                        'url16x16': "https://github.com/favicon.ico"
                    }
                }
            }
        rv = requests.post("https://issues.apache.org/jira/rest/api/latest/issue/%s/remotelink" % ticket,headers=headers, json = data)
        if rv.status_code == 200 or rv.status_code == 201:
            return "Updated JIRA Ticket %s" % ticket
        else:
            return rv.txt
    except:
        pass # Not much to do just yet

def addLabel(ticket):
    auth = open("/x1/jirauser.txt").read().strip()
    auth = str(base64.encodestring(bytes(auth))).strip()

    # Post comment or worklog entry!
    headers = {"Content-type": "application/json",
                 "Accept": "*/*",
                 "Authorization": "Basic %s" % auth
                 }
    data = {
        "update": {
            "labels": [
                {"add": "pull-request-available"}
            ]
        }
    }
    rv = requests.put("https://issues.apache.org/jira/rest/api/latest/issue/%s" % ticket,headers=headers, json = data)
    if rv.status_code == 200 or rv.status_code == 201:
        return "Added PR label to Ticket %s\n" % ticket
    else:
        sys.stderr.write(rv.text)
        return rv.text

# Main function
def main():
    # Get JSON payload from GitHub
    jsin = getvalue('payload')
    data = json.loads(jsin)

    # Now check if this repo is hosted on GitBox (if not, abort):
    if'repository' in data:
        repo = data['repository']['name']
        repopath = "/x1/repos/asf/%s.git" % repo
    else:
        return None
    if not os.path.exists(repopath):
        return None

    # Get configuration options for the repo
    configpath = os.path.join(repopath, "config")
    if os.path.exists(configpath):
        gconf = git.GitConfigParser(configpath, read_only = True)
    else:
        return "No configuration found for repository %s" % repo

    # Get recipient email address for mail coms
    m = re.match(r"(?:incubator-)([^-]+)", repo)
    project = "infra" # Default to infra
    if m:
        project = m.group(1)
    mailto = gconf.get('apache', 'dev') if gconf.has_option('apache', 'dev') else "dev@%s.apache.org" % project
    # Debug override if testing
    if DEBUG_MAIL_TO:
        mailto = DEBUG_MAIL_TO

    # Now figure out what type of event we got
    fmt = None
    email = None
    isComment = False
    if 'action' in data:
        # Issue opened or reopened
        if data['action'] in ['opened', 'reopened']:
            fmt = issueOpened(data)
        # Issue closed
        elif data['action'] == 'closed':
            fmt = issueClosed(data)
        # Comment on issue or specific code (WIP)
        elif 'comment' in data:
            isComment = True
            # File-specific comment
            if 'path' in data['comment']:
                # Diff review
                if 'diff_hunk' in data['comment']:
                    fmt = reviewComment(data)
            # Standard commit comment
            elif 'commit_id' in data['comment']:
                # We don't quite handle this yet
                pass
            # Generic comment
            else:
                fmt = ticketComment(data)

    # Send email if applicable
    if fmt:
        # EZT needs these to be defined
        for el in ['filename','diff', 'prdiff']:
            if not el in fmt:
                fmt[el] = None
        # Indent comment
        fmt['text'] = "\n".join("   %s" % x for x in fmt['text'].split("\n"))
        # Go ahead and generate the template
        email = formatEmail(fmt)
    if email:
        sendEmail(mailto, email['subject'], email['message'])

    # Now do JIRA if need be
    jiraopt = gconf.get('apache', 'jira') if gconf.has_option('apache', 'jira') else 'default'

    if jiraopt and fmt:
        if 'title' in fmt:
            m = re.search(r"\b([A-Z0-9]+-\d+)\b", fmt['title'])
            if m:
                ticket = m.group(1)
                worklog = True if jiraopt.find('worklog') != -1 else False
                if not (jiraopt.find("nocomment") != -1 and isComment):
                    remoteLink(ticket, fmt['link'], fmt['id']) # Make link to PR
                    addLabel(ticket)
                    return updateTicket(ticket, fmt['user'], email['message'], worklog)
    # All done!
    return None

if __name__ == '__main__':
    rv = main()                                          # run main block
    print("Status: 204 Message received\r\n\r\n")   # Always return this
    # If error was returned, log it in issues.log
    if rv:
        open("/x1/gitbox/issues.log", "a").write(rv + "\r\n")
