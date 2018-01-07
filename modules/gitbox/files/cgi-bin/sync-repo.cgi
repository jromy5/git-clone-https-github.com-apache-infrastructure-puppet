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
import cgi, netaddr, smtplib, sqlite3
from email.mime.text import MIMEText

xform = cgi.FieldStorage();

# Check that this is GitHub calling
from netaddr import IPNetwork, IPAddress
GitHubNetwork = IPNetwork("192.30.252.0/22") # This is GitHub's current
                                             # net block. May change!
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
The repository %(reponame)s seems to have missed a webhook call.
We received a push with %(before)s as the parent commit, but this commit
was not found in the repository.

The exact error was:
%(errmsg)s

With regards,
gitbox.apache.org
"""

tmpl_sync_failed = """
The repository %(reponame)s seems to be failing to syncronize with
GitHub's repository. This may be a split brain issue, and thus require
manual intervention.

The exact error was:
%(errmsg)s

With regards,
gitbox.apache.org
"""


tmpl_unknown_user = """
The repository %(reponame)s was pushed to by a user not known to the
gitbox/MATT system. The GitHub ID was: %(pusher)s. This is not supposed
to happen, please check that the MATT system is operating correctly.

With regards,
gitbox.apache.org
"""

EMPTY_HASH = '0'*40

# Start off by checking if this is a wiki change!
if 'pages' in data:
    log = ""
    repo = data['repository']['name']
    wikipath = "/x1/repos/wikis/%s.wiki.git" % repo
    wikiurl = "https://github.com/apache/%s.wiki.git" % repo
    # If we don't have the wiki.git yet, clone it
    if not os.path.exists(wikipath):
        os.chdir("/x1/repos/wikis/")
        subprocess.check_output(['git','clone', '--mirror', wikiurl, wikipath])
    
    # chdir to wiki git, pull in changes
    os.chdir(wikipath)
    subprocess.check_output(['git','fetch'])
    
    ########################
    # Get ASF ID of pusher #
    ########################
    asfid = "unknown"
    pusher = data['sender']['login']
    conn = sqlite3.connect('/x1/gitbox/db/gitbox.db')
    cursor = conn.cursor()
    cursor.execute("SELECT asfid FROM ids WHERE githubid=? COLLATE NOCASE", (pusher, ))
    row = cursor.fetchone()
    # Found it, yay!
    if row:
        asfid = row[0]
    conn.close()
    
    # Ready the hook env
    gitenv = {
        'NO_SYNC': 'yes',
        'WEB_HOST': 'https://gitbox.apache.org/',
        'GIT_COMMITTER_NAME': asfid,
        'GIT_COMMITTER_EMAIL': "%s@apache.org" % asfid,
        'GIT_PROJECT_ROOT': '/x1/repos/wikis',
        'GIT_ORIGIN_REPO': "/x1/repos/asf/%s.git" % repo,
        'GIT_WIKI_REPO': wikipath,
        'PATH_INFO': repo+".wiki.git",
        'ASFGIT_ADMIN': '/x1/gitbox',
        'SCRIPT_NAME': '/x1/gitbox/cgi-bin/sync-repo.cgi',
        'WRITE_LOCK': '/x1/gitbox/write.lock',
        'AUTH_FILE': '/x1/gitbox/conf/auth.cfg'
    }
    for page in data['pages']:
        after = page['sha']
        before = subprocess.check_output(["git", "rev-list", "--parents", "-n", "1", after]).strip().split(' ')[1]
        update = "%s %s refs/heads/master\n" % (before if before != after else EMPTY_HASH, after)
        
        # Fire off the multimail hook for the wiki
        try:                    
            hook = "/x1/gitbox/hooks/post-receive"
            # Fire off the email hook
            process = subprocess.Popen([hook], stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=gitenv)
            out, err = process.communicate(input=update)
            log += out
            log += "[%s] [%s]: Multimail deployed (%s -> %s)!\n" % (time.strftime("%c"), wikipath, before, after)
              
        except Exception as err:
            log += "[%s] [%s]: Multimail hook failed: %s\n" % (time.strftime("%c"), wikipath, err)
        open("/x1/gitbox/sync.log", "a").write(log)
    
    

elif 'repository' in data and 'name' in data['repository']:
    reponame = data['repository']['name']
    pusher = data['pusher']['name'] if 'pusher' in data else data['sender']['login']
    ref = data['ref']
    baseref = data['base_ref'] if 'base_ref' in data else data['master_branch'] if 'master_branch' in data else data['ref']
    before = data['before'] if 'before' in data else EMPTY_HASH
    after = data['after'] if 'after' in data else EMPTY_HASH
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
        cursor.execute("SELECT asfid FROM ids WHERE githubid=? COLLATE NOCASE", (pusher, ))
        row = cursor.fetchone()
        # Found it, yay!
        if row:
            asfid = row[0]
        # Didn't find it, time to notify!!
        else:
            asfid = "(unknown)"
            # Send an email to users@infra.a.o with the bork
            msg = MIMEText(tmpl_unknown_user % locals(), _charset = "utf-8")
            msg['Subject'] = "gitbox repository %s: push from unknown github user!" % reponame
            msg['To'] = "<team@infra.apache.org>"
            msg['From'] = "<gitbox@gitbox.apache.org>"
            s = smtplib.SMTP('localhost')
            s.sendmail(msg['From'], msg['To'], msg.as_string())
        
        
        #######################################
        # Check that we haven't missed a push #
        #######################################
        if before and before != EMPTY_HASH:
            try:
                # First, check the db for pushes we have
                cursor.execute("SELECT id FROM pushlog WHERE new=?", (before, ))
                foundOld = cursor.fetchone()
                if not foundOld:
                    # See if we've ever gotten any push logs for this repo, or if this is a first
                    tcursor = conn.cursor() # make a temp cursor, try fetching one row
                    tcursor.execute("SELECT id FROM pushlog WHERE repository=?", (reponame, ))
                    foundAny = tcursor.fetchone()
                    if foundAny:
                        raise Exception("Could not find previous push (??->%s) in push log!" % before)
                # Then, be doubly sure by doing cat-file on the old rev
                os.chdir(repopath)
                subprocess.check_call(['git','cat-file','-e', before])
            except Exception as errmsg:
                # Send an email to users@infra.a.o with the bork
                msg = MIMEText(tmpl_missed_webhook % locals(), _charset = "utf-8")
                msg['Subject'] = "gitbox repository %s: missed event/push!" % reponame
                msg['To'] = "<team@infra.apache.org>"
                msg['From'] = "<gitbox@gitbox.apache.org>"
                s = smtplib.SMTP('localhost')
                s.sendmail(msg['From'], msg['To'], msg.as_string())
        
        # If new branch, fetch the old ref from head_commit
        if before and before == EMPTY_HASH and 'head_commit' in data:
            before = data['head_commit']['id']
        
        ##################################
        # Write Push log, text + sqlite3 #
        ##################################
        cursor.execute("""INSERT INTO pushlog
                  (repository, asfid, githubid, baseref, ref, old, new, date)
                  VALUES (?,?,?,?,?,?,?,DATETIME('now'))""", (reponame, asfid, pusher, baseref, ref, before, after, ))
        
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
    
        # Change to repo dir
        os.chdir(repopath)
        # Run 'git fetch --prune' (fetch changes, prune away branches no longer present in remote)
        p = subprocess.Popen(["git", "fetch", "--prune"],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE)
        output,error = p.communicate()
        rv = p.poll()
        if not rv:
            log += "[%s] [%s.git]: Git fetch succeeded\n" % (time.strftime("%c"), reponame)
            try:
                if os.path.exists("/x1/gitbox/broken/%s.txt" % reponame):
                    os.unlink("/x1/gitbox/broken/%s.txt" % reponame)
            except:
                pass # Fail silently
        else:
            broken = True
            log += "[%s] [%s.git]: Git fetch failed: %s\n" % (time.strftime("%c"), reponame, error)
            with open("/x1/gitbox/broken/%s.txt" % reponame, "w") as f:
                f.write("BROKEN AT %s\n\nOutput:\n" % time.strftime("%c"))
                f.write("Return code: %s\nText output:\n" % rv)
                f.write(error)
                f.close()
            
            # Send an email to users@infra.a.o with the bork
            errmsg = error.output
            msg = MIMEText(tmpl_sync_failed % locals(), _charset = "utf-8")
            msg['Subject'] = "gitbox repository %s: sync failed!" % reponame
            msg['To'] = "<team@infra.apache.org>"
            msg['From'] = "<gitbox@apache.org>"
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
                update = "%s %s %s\n" % (before if before != after else EMPTY_HASH, after, ref)
                
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
