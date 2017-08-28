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

space = form.getvalue('space', None)
if not space or not re.match(r"^[A-Z0-9]+$", space):
    sscommon.buggo("Invalid Wiki Space name!")

description = form.getvalue('description', None)
if not description:
    sscommon.buggo("Invalid project description!")

admin = form.getvalue('admin', None)
if not admin:
    sscommon.buggo("Invalid administrator username!")

os.chdir(sscommon.clipath)

try:

    # Check admin user is an actual cwiki id
    subprocess.check_output([
        '/usr/bin/java', '-jar', sscommon.cwikijar,
        '-v',
        '--server', 'https://cwiki.apache.org/confluence',
        '--user', sscommon.config['jira']['username'],
        '--password', sscommon.config['jira']['password'],
        '--action', 'getUser',
        '--userId', admin,
        ], stderr=subprocess.STDOUT)

except:
    print("Status: 500 Creation failed\r\n\r\n<h2>Confluence Space creation failed!</h2><pre>Invalid admin user: %s was not found in Confluence!</pre>" % str(admin))
    sys.exit(0)

try:
    
    # Create cwiki space
    subprocess.check_output([
        '/usr/bin/java', '-jar', sscommon.cwikijar,
        '-v',
        '--server', 'https://cwiki.apache.org/confluence',
        '--user', sscommon.config['jira']['username'],
        '--password', sscommon.config['jira']['password'],
        '--action', 'addSpace',
        '--space', space,
        '--description', description,
        ], stderr=subprocess.STDOUT)
    
    # Set Admin
    subprocess.check_output([
        '/usr/bin/java', '-jar', sscommon.cwikijar,
        '-v',
        '--server', 'https://cwiki.apache.org/confluence',
        '--user', sscommon.config['jira']['username'],
        '--password', sscommon.config['jira']['password'],
        '--action', 'addPermissions',
        '--space', space,
        '--permissions', '@all',
        '--userId', admin,
        ], stderr=subprocess.STDOUT)

    # Enable Anonymous Read access to the space
    subprocess.check_output([
        '/usr/bin/java', '-jar', sscommon.cwikijar,
        '-v',
        '--server', 'https://cwiki.apache.org/confluence',
        '--user', sscommon.config['jira']['username'],
        '--password', sscommon.config['jira']['password'],
        '--action', 'addPermissions',
        '--space', space,
        '--permissions', 'VIEWSPACE',
        '--group', 'Anonymous',
        ], stderr=subprocess.STDOUT)
    
    # Enable logged in users read and export space perms
    subprocess.check_output([
        '/usr/bin/java', '-jar', sscommon.cwikijar,
        '-v',
        '--server', 'https://cwiki.apache.org/confluence',
        '--user', sscommon.config['jira']['username'],
        '--password', sscommon.config['jira']['password'],
        '--action', 'addPermissions',
        '--space', space,
        '--permissions', 'VIEWSPACE,EXPORTSPACE',
        '--group', 'confluence-users',
        ], stderr=subprocess.STDOUT)

    # Remove infrabot permissions which are given by default as space creator
    subprocess.check_output([
        '/usr/bin/java', '-jar', sscommon.cwikijar,
        '-v',
        '--server', 'https://cwiki.apache.org/confluence',
        '--user', sscommon.config['jira']['username'],
        '--password', sscommon.config['jira']['password'],
        '--action', 'removePermissions',
        '--space', space,
        '--permissions', '@all',
        '--userId', 'infrabot',
        ], stderr=subprocess.STDOUT)

    # All done!
    sscommon.sendemail("%s@apache.org" % requser, "New Confluence space created: %s" % space,
"""
Hi there,
As requested by %s@apache.org, a new Confluence space has been set up at:
https://cwiki.apache.org/confluence/display/%s

""" % (requser, space))
    sscommon.hipchat("A new Confluence space, <kbd><a href='https://cwiki.apache.org/confluence/display/%s'>https://cwiki.apache.org/confluence/display/%s</a></kbd>, has been set up as requested by %s@apache.org." % (space, space, requser))
    print("Status: 201 Created\r\n\r\n<h2>CONFLUENCE Space created!</h2>Your wiki space has been set up, and can be accessed at: <a href='https://cwiki.apache.org/confluence/display/%s'>https://cwiki.apache.org/confluence/display/%s</a>." % (space, space))
    
except subprocess.CalledProcessError as err:
    uid = uuid.uuid4()
    with open("/tmp/%s.log" % uid, "w") as f:
        f.write(err.output)
        f.close()
    sscommon.hipchat("A new Confluence space, <kbd><a href='https://cwiki.apache.org/confluence/display/%s'>https://cwiki.apache.org/confluence/display/%s</a></kbd>, was attempted created as requested by %s@apache.org, however one of more components of the setup failed. /tmp/%s.log may have more information" % (space, space, requser, uid))
    print("Status: 500 Creation failed\r\n\r\n<h2>Confluence Space creation failed!</h2><pre>Creation of the CONFLUENCE Space may have failed. Contact an administrator for more information. Error ID: %s</pre>" % uid)

