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
import cgi, netaddr, SMTP, sqlite3
from email.mime.text import MIMEText

xform = cgi.FieldStorage();

# Check that this is GitHub calling
from netaddr import IPNetwork, IPAddress
GitHubNetwork = IPNetwork("192.30.252.0/22") # TBD!
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

tmpl_missed_webhook = """
The repository %(repository)s seems to have missed a webhook call.
We received a push with %(old) as the parent commit, but this commit
was not found in the repository.

The exact error was:
%(errmsg)s

With regards,
gitbox.apache.org
"""

tmpl_sync_failed = """
The repository %(repository)s seems to be failing to syncronize with
GitHub's repository. This may be a split brain issue, and thus require
manual intervention.

The exact error was:
%(errmsg)s

With regards,
gitbox.apache.org
"""


tmpl_unknown_user = """
The repository %(repository)s was pushed to by a user not known to the
gitbox/MATT system. The GitHub ID was: %(pusher)s. This is not supposed
to happen, please check that the MATT system is operating correctly.

With regards,
gitbox.apache.org
"""

if 'repository' in data and 'name' in data['repository']:
    reponame = data['repository']['name']
    pusher = data['pusher']['name']
    ref = data['ref']
    before = data['before']
    after = data['after']
    repopath = "/x1/repos/asf/%s.git" % reponame
    broken = False
    
    # Unless asfgit is the pusher, we need to act on this.
    if pusher != 'asfgit' and os.path.exists(repopath):
        
        ##################
        # Open SQLite DB #
        ##################
        conn = sqlite3.connect('/x1/gitbox/db/gitbox.db')
        cursor = conn.cursor()
        
        
        ########################
        # Get ASF ID of pusher #
        ########################
        cursor.execute("SELECT asfid FROM ids WHERE githubid=?", (pusher, ))
        row = cursor.fetchone()
        # Found it, yay!
        if row:
            asfid = row[0]
        # Didn't find it, time to notify!!
        else:
            asfid = "(unknown)"
            # Send an email to users@infra.a.o with the bork
            msg = MIMEText(tmpl_unknown_user % locals())
            msg['Subject'] = "gitbox repository %s: push from unknown github user!" % repository
            msg['To'] = "<users@infra.apache.org>"
            msg['From'] = "<gitbox@gitbox.apache.org>"
            s = smtplib.SMTP('localhost')
            s.sendmail(msg['From'], msg['To'], msg.as_string())
        
        
        #######################################
        # Check that we haven't missed a push #
        #######################################
        if before:
            try:
                # First, check the db for pushes we have
                cursor.execute("SELECT id FROM pushlog WHERE new=?", (before, ))
                foundOld = cursor.fetchone()
                if not foundOld:
                    raise Exception("Could not find previous push (??->%s) in push log!" % before)
                # Then, be doubly sure by doing cat-file on the old rev
                os.chdir(repopath)
                subprocess.check_call(['git','cat-file','-e', before])
            except Exception as errmsg:
                # Send an email to users@infra.a.o with the bork
                msg = MIMEText(tmpl_missed_webhook % locals())
                msg['Subject'] = "gitbox repository %s: missed event/push!" % repository
                msg['To'] = "<users@infra.apache.org>"
                msg['From'] = "<gitbox@gitbox.apache.org>"
                s = smtplib.SMTP('localhost')
                s.sendmail(msg['From'], msg['To'], msg.as_string())
        
        ##################################
        # Write Push log, text + sqlite3 #
        ##################################
        cursor.execute("""INSERT INTO pushlog
                  (repository, asfid, githubid, ref, old, new, date)
                  VALUES (?,?,?,?,?,now))""", (reponame, asfid, pusher, reduce, before, after, ))
        
        open("/x1/pushlogs/%s.txt" % reponame, "a").write(
            "[%s] %s -> %s (%s@apache.org / %s)\n" % (
                time.strftime("%Y-%m-%d %H:%M:%S", time.gmtime()),
                before,
                after,
                asfid,
                pusher
                )
            )
        
        
        # commit and close sqlite, no need for it below
        conn.commit()
        conn.close()
        
        ####################
        # SYNC WITH GITHUB #
        ####################
        log = "[%s] [%s.git]: Got a sync call for %s.git, pushed by %s\n" % (time.strftime("%c"), reponame, reponame, asfid)
        try:
            # Change to repo dir
            os.chdir(repopath)
            # Run 'git fetch'
            out = subprocess.check_output(["git", "fetch"])
            log += "[%s] [%s.git]: Git fetch succeeded\n" % (time.strftime("%c"), reponame)
            try:
                os.unlink("/x1/gitbox/broken/%s.txt" % cfg.repo_name)
            except:
                pass
        except subprocess.CalledProcessError as err:
            broken = True
            log += "[%s] [%s.git]: Git fetch failed: %s\n" % (time.strftime("%c"), reponame, err.output)
            with open("/x1/gitbox/broken/%s.txt" % cfg.repo_name, "w") as f:
                f.write("BROKEN AT %s\n" % time.strftime("%c"))
                f.close()
            
            # Send an email to users@infra.a.o with the bork
            errmsg = err.output
            msg = MIMEText(tmpl_sync_failed % locals())
            msg['Subject'] = "gitbox repository %s: sync failed!" % repository
            msg['To'] = "<users@infra.apache.org>"
            msg['From'] = "<gitbox@gitbox.apache.org>"
            s = smtplib.SMTP('localhost')
            s.sendmail(msg['From'], msg['To'], msg.as_string())
            
        open("/x1/gitbox/sync.log", "a").write(log)
        
        
        #####################################
        # Deploy commit mails via multimail #
        #####################################
        if not broken: # only fire this off if the sync succeeded
            log = "[%s] [%s.git]: Got a multimail call for %s.git, triggered by %s\n" % (time.strftime("%c"), reponame, reponame, asfid)
            hook = "%s/hooks/post-receive" % repopath
            # If we found the hook, prep to run it
            if os.path.exists(hook):
                # set some vars
                gitenv = {
                    'NO_SYNC': 'yes',
                    'WEB_HOST': 'https://gitbox.apache.org/',
                    'GIT_COMMITTER_NAME': asfid,
                    'GIT_COMMITTER_EMAIL': "%s@apache.org" % asfid,
                    'GIT_PROJECT_ROOT': '/x1/repos/asf',
                    'PATH_INFO': reponame + '.git',
                    'ASFGIT_ADMIN': '/x1/gitbox',
                    'SCRIPT_NAME': '/x1/gitbox/cgi-bin/sync-repo.cgi',
                    'WRITE_LOCK': '/x1/gitbox/write.lock',
                    'AUTH_FILE': '/x1/gitbox/conf/auth.cfg'
                }
                update = "%s %s %s\n" % (before, after, ref)

                try:                    
                    # Change to repo dir
                    os.chdir(repopath)
                    
                    # Fire off the email hook
                    process = subprocess.Popen([hook], stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=gitenv)
                    process.communicate(input=update)
                    log += "[%s] [%s.git]: Multimail deployed!\n" % (time.strftime("%c"), reponame)
                      
                except Exception as err:
                    log += "[%s] [%s.git]: Multimail hook failed: %s\n" % (time.strftime("%c"), reponame, err)
            open("/x1/gitbox/sync.log", "a").write(log)

print("Status: 204 Message received\r\n\r\n")
