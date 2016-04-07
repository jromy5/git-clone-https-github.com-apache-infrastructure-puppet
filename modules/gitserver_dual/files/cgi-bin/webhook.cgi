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
import hashlib, json, random, os, sys, time, subprocess
import cgi, netaddr


xform = cgi.FieldStorage();

# Check that this is GitHub calling
from netaddr import IPNetwork, IPAddress
GitHubNetwork = IPNetwork("192.30.252.0/22")
callerIP = IPAddress(os.environ['REMOTE_ADDR'])
if not callerIP in GitHubNetwork:
    print("Status: 401 Unauthorized\r\nContent-Type: text/plain\r\n\r\nI don't know you!\r\n")
    sys.exit(0)


def getvalue(key):
    val = xform.getvalue(key)
    if val:
        return val
    else:
        return None

jsin = getvalue('payload')
data = json.loads(jsin)

if 'repository' in data and 'name' in data['repository']:
    reponame = data['repository']['name']
    pusher = data['pusher']['name']
    if pusher != 'asfgit' and os.path.exists("/x1/git/repos/asf/%s.git" % reponame):
        log = "[%s] [%s.git]: Got a sync call for %s.git, pushed by %s\n" % (time.strftime("%c"), reponame, reponame, pusher)
        try:
            # Change to repo dir
            os.chdir("/x1/git/repos/asf/%s.git" % reponame)
            # Run 'git fetch'
            out = subprocess.check_call(["git", "fetch"])
            log += "[%s] [%s.git]: Git fetch succeeded\n" % (time.strftime("%c"), reponame)
            try:
                os.unlink("/x1/git/git-dual/broken/%s.txt" % cfg.repo_name)
            except:
                pass
        except Exception as err:
            log += "[%s] [%s.git]: Git fetch failed: %s\n" % (time.strftime("%c"), reponame, err)
            with open("/x1/git/git-dual/broken/%s.txt" % cfg.repo_name, "w") as f:
                f.write("BROKEN AT %s\n" % time.strftime("%c"))
                f.close()
        with open("/x1/git/git-dual/sync.log", "a") as f:
            f.write(log)
            f.close()


print("Status: 200 Okay\r\nContent-Type: text/plain\r\n\r\nMessage received\r\n")