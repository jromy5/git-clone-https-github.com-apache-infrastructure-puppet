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
from subprocess import Popen, PIPE
import subprocess

xform = cgi.FieldStorage();

# Check that this is GitHub calling
from netaddr import IPNetwork, IPAddress
MattNetwork = IPNetwork("10.10.0.33/24")
callerIP = IPAddress(os.environ['REMOTE_ADDR'])
if not callerIP in MattNetwork:
    print("Status: 401 Unaythorized\r\nContent-Type: text/plain\r\n\r\nI don't know you!\r\n")
    sys.exit(0)


def getvalue(key):
    val = xform.getvalue(key)
    if val:
        return val
    else:
        return None

jsin = getvalue('payload')
data = json.loads(jsin)

if 'repository' in data:
    reponame = data['repository']
    pusher = data['pusher']
    ref = data['ref']
    before = data['before']
    after = data['after']
    if pusher != 'asfgit' and os.path.exists("/x1/repos/asf/%s.git" % reponame):
        log = "[%s] [%s.git]: Got a multimail call for %s.git, triggered by %s\n" % (time.strftime("%c"), reponame, reponame, pusher)
        try:
            # Change to repo dir
            os.chdir("/x1/repos/asf/%s.git" % reponame)
            # set some vars
            os.environ['NO_SYNC'] = 'yes'
            os.environ['WEB_HOST'] = "https://gitbox.apache.org/"
            os.environ['GIT_COMMITTER_NAME'] = data['pusher']
            os.environ['GIT_COMMITTER_EMAIL'] = "%s@apache.org" % data['pusher']
            os.environ['GIT_PROJECT_ROOT'] = "/x1/repos/asf/" + reponame + ".git"
            os.environ['PATH_INFO'] = reponame + '.git'
            hook = "/x1/repos/asf/" + reponame + ".git"
            if not hook.endswith('.git'): hook += '/.git'
            hook += '/hooks/post-receive'
        
            # If we found the hook, prep to run it
            if os.path.exists(hook):
              update = "%s %s %s\n" % (before, after, ref)
              cwd = os.getcwd()
              tries = 0
              # We'll try to deploy the mail 6 times
              while tries < 6:
                try:
                  # First, make sure the repo is synced. This is managed by another call,
                  # so we'll use `git cat-file` to check if the last commit has arrived
                  try:
                    subprocess.check_call(['git','cat-file','-e', after])
                  except:
                    raise Exception("Git repo not up to date yet, waiting for sync to kick in")
                  # Commit has arrived, fire off the email hook
                  os.chdir("/x1/repos/asf/" + reponame + ".git")
                  process = Popen([hook], stdin=PIPE, stdout=PIPE, stderr=PIPE, env=os.environ)
                  process.communicate(input=update)
                  log += "[%s] [%s.git]: Multimail deployed!\n" % (time.strftime("%c"), reponame)
                  break
                except Exception as err:
                  log += "Something went wrong (%s), waiting 5 secs...\n" % err
                  tries += 1
                  time.sleep(5)
              
            
        except Exception as err:
            log += "[%s] [%s.git]: Multimail hook failed: %s\n" % (time.strftime("%c"), reponame, err)
        with open("/x1/gitbox/sync.log", "a") as f:
            f.write(log)
            f.close()


print("Status: 200 Okay\r\nContent-Type: text/plain\r\n\r\nMessage received\r\n")
