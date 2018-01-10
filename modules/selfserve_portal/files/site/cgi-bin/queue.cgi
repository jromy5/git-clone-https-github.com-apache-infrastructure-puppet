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

# This is queue.cgi
import sys
import cgi
import json
import os
import re

# CGI interface
xform = cgi.FieldStorage();

# Remove a list object?
rm = xform.getvalue('rm', None)
if rm and re.match(r"^[-.a-z0-9]+$", rm):
        if os.path.exists("/usr/local/etc/selfserve/queue/%s.json" % rm):
                os.unlink("/usr/local/etc/selfserve/queue/%s.json" % rm)
        print("Status: 200\r\n\r\nObject removed from queue")
        sys.exit(0)


# Get all queued objects
entries = [k for k in os.listdir("/usr/local/etc/selfserve/queue/") if k.endswith(".json")]

jlist = []
for entry in entries:
        with open("/usr/local/etc/selfserve/queue/%s" % entry) as f:
                js = json.load(f)
                js['id'] = entry[:-5] # cut off .json
                jlist.append(js)
                f.close()
print("Status: 200\r\nContent-Type: application/json\r\n\r\n")
print(json.dumps(jlist))
