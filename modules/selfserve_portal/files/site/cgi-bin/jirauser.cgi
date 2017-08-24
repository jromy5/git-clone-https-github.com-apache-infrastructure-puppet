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
import requests
import base64
import sscommon

def userExists(username):
    auth = "%s:%s" % (sscommon.config['jira']['username'], sscommon.config['jira']['password'])
    auth = str(base64.encodestring(bytes(auth))).strip()
    
    # Post comment or worklog entry!
    headers = {"Content-type": "application/json",
                 "Accept": "*/*",
                 "Authorization": "Basic %s" % auth
                 }
    try:
        
        rv = requests.get("https://issues.apache.org/jira/rest/api/latest/user?username=%s" % username, headers = headers)
        if rv.status_code == 200 or rv.status_code == 201:
            return True
        else:
            return False
    except:
        pass # Not much to do just yet
    
# CGI interface
xform = cgi.FieldStorage();

username = xform.getvalue('username')
for user in username.split(","):
    if not userExists(user):
        print("Status: 404\r\n\r\nUser %s does not exist!" % user)
        sys.exit(0)

print("Status: 200\r\n\r\nUser exists")
