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
# This is sscommon.py: common functions for self-serve
YAML_FILE = "/usr/local/etc/selfserve/selfserve.yaml"
import yaml
import sys
import requests
import smtplib
import email.utils
import time

config = yaml.load(open(YAML_FILE))

clipath = '/usr/local/etc/atlassian-cli-5.7.0'
cwikijar = '%s/lib/confluence-cli-5.7.0.jar' % clipath
jirajar = '%s/lib/jira-cli-5.7.0.jar' % clipath

def sendemail(rcpt, subject, message):
    sender = "ASF Self-Service Platform <selfserve@apache.org>"
    receivers = [rcpt]
    if isinstance(rcpt, list):
        receivers = rcpt
    receivers.append('ASF Infrastructure <private@infra.apache.org>')
    # The headers below are not supplied by default by Python, add them!
    msgid = email.utils.make_msgid()
    msgdate = email.utils.formatdate()
    msg = """From: %s
Message-ID: %s
Date: %s
To: %s
Reply-To: ASF Infrastructure <private@infra.apache.org>
Subject: %s

%s

With regards,
ASF Self-Service Platform, https://selfserve.apache.org
For inquiries, please contact: users@infra.apache.org
""" % (sender, msgid, msgdate, ", ".join(receivers), subject, message)
    msg = msg.encode('ascii', errors='replace')
    smtpObj = smtplib.SMTP("mail.apache.org:2025")
    smtpObj.sendmail(sender, receivers, msg)
    

def buggo(msg):
    print("Status: 400 Bad Request\r\n\r\nBad request parameter: %s" % msg)
    sys.exit(0)
    
def hipchat(msg):
    """Send notification to HipChat"""
    payload = {
            'room_id': config['hipchat']['room'],
            'auth_token': config['hipchat']['token'],
            'from': "ASF Self-Serve",
            'message_format': 'html',
            'notify': '0',
            'color':  'green',
            'message': msg
        }
    requests.post('https://api.hipchat.com/v1/rooms/message', data=payload)
