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
import uuid
import sscommon

requser = os.environ['REMOTE_USER']

form = cgi.FieldStorage();

project = form.getvalue('project', None)
if not project or not re.match(r"^[A-Z0-9]+$", project):
    sscommon.buggo("Invalid project name!")

name = form.getvalue('name', None)
if not name:
    sscommon.buggo("Invalid project name!")

description = form.getvalue('description', None)
if not description:
    sscommon.buggo("Invalid project description!")

lead = form.getvalue('admins', "").split(',')[0]
if len(lead) < 2:
    sscommon.buggo("Invalid administrator username!")

issuescheme = form.getvalue('issuetype', None)
if not issuescheme or len(issuescheme) == 0:
    sscommon.buggo("Invalid issue type scheme!")

url = form.getvalue('url', None)
if not url or not re.match(r"^https?://.+$", url):
    sscommon.buggo("Invalid project URL!")

workflowscheme = form.getvalue('workflow')
if not workflowscheme or len(workflowscheme) == 0:
    sscommon.buggo("Invalid workflow scheme!")

os.chdir('/usr/local/etc/atlassian-cli-5.7.0/')
try:
    subprocess.check_output([
        '/usr/bin/java', '-jar', sscommon.jirajar,
        '-v',
        '--server', 'https://issues.apache.org/jira',
        '--user', sscommon.config['jira']['username'],
        '--password', sscommon.config['jira']['password'],
        '--action', 'createProject',
        '--project', project,
        '--name', name,
        '--description', description,
        '--lead',  lead,
        '--issueTypeScheme', issuescheme,
        '--url', url,
        '--workflowScheme',  workflowscheme,
        '--notificationScheme', "Empty Scheme"
        ], stderr=subprocess.STDOUT)
    sscommon.sendemail("%s@apache.org" % requser, "New JIRA project created: %s" % project,
"""
Hi there,
As requested by %s@apache.org, a new JIRA project has been set up at:
https://issues.apache.org/jira/browse/%s

URL: %s
Name/Description: %s
Lead: %s


""" % (requser, project, url, description, lead))
    sscommon.hipchat("A new JIRA project, <kbd><a href='https://issues.apache.org/jira/browse/%s'>https://issues.apache.org/jira/browse/%s</a></kbd>, has been set up as requested by %s@apache.org." % (project, project, requser))
    print("Status: 201 Created\r\n\r\n<h2>JIRA project created!</h2>Your project has been set up, and can be accessed at: <a href='https://issues.apache.org/jira/browse/%s'>https://issues.apache.org/jira/browse/%s</a>." % (project, project))
    
except subprocess.CalledProcessError as err:
    uid = uuid.uuid4()
    with open("/tmp/%s.log" % uid, "w") as f:
        f.write(err.output)
        f.close()
    sscommon.hipchat("A new JIRA project, <kbd><a href='https://issues.apache.org/jira/browse/%s'>https://issues.apache.org/jira/browse/%s</a></kbd>, was attempted created as requested by %s@apache.org, however one of more components of the setup failed. /tmp/%s.log may have more information" % (project, project, requser, uid))
    print("Status: 500 Creation failed\r\n\r\n<h2>JIRA creation failed!</h2><pre>Creation of the JIRA project may have failed. Contact an administrator for more information. Error ID: %s</pre>" % uid)

