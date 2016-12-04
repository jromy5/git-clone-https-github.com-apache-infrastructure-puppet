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

# This is oauth.cgi - script for handling ASF and GitHub OAuth.

import hashlib, json, random, os, sys, time, subprocess
import cgi, sqlite3, hashlib, Cookie, urllib, urllib2

xform = cgi.FieldStorage();

""" Get a POST/GET value """
def getvalue(key):
    val = xform.getvalue(key)
    if val:
        return val
    else:
        return None
    
""" Get an account entry from the DB """
def getaccount(uid = None):
    cookies = Cookie.SimpleCookie(os.environ.get("HTTP_COOKIE", ""))
    if "matt" in cookies:
        cookie = cookies['matt']
        conn = sqlite3.connect('/x1/gitbox/db/gitbox.db')
        cursor = conn.cursor()
        cursor.execute("SELECT asfid,githubid,displayname FROM sessions WHERE cookie=?", (cookie,))
        row = cursor.fetchone()
        conn.close()
        if row:
            acc = {
                'asfid':  row[0],
                'github': row[1],
                'mfa':    0,
                'name':   row[2],
                'cookie': cookie,
            }
            return acc
    elif uid:
        conn = sqlite3.connect('/x1/gitbox/db/gitbox.db')
        cursor = conn.cursor()
        cursor.execute("SELECT asfid,githubid,displayname,cookie FROM sessions WHERE asfid=?", (uid,))
        row = cursor.fetchone()
        conn.close()
        if row:
            acc = {
                'asfid':  row[0],
                'github': row[1],
                'mfa':    0,
                'name':   row[2],
                'cookie': row[3],
            }
            return acc
    return None

""" Save/update an account """
def saveaccount(acc):
    conn = sqlite3.connect('/x1/gitbox/db/gitbox.db')
    cursor = conn.cursor()
    cursor.execute("SELECT asfid,githubid,displayname FROM sessions WHERE asfid=?", (aco['asfid'],))
    exists = cursor.fetchone()
    if exists:
        cursor.execute("UPDATE sessions SET cookie=?,githubid=?,displayname=?,mfa=? WHERE asfid=?", (acc['cookie'],acc['github'], acc['name'],acc['mfa'], acc['asfid'],))
    else:
        cursor.execute("INSERT INTO sessions (cookie,asfid,githubid,displayname,mfa) VALUES (?,?,?,?,?)" % (acc['asfid'], acc['github'], acc['name'], acc['mfa']))
    conn.commit()
    

def main():    
    # Get some CGI vars
    load = getvalue("load")             # Fetch account info?
    logout = getvalue("logout")         # Log out of MATT?
    unauth = getvalue("unauth")         # Un-auth an account?
    redirect = getvalue("redirect")     # Redirect to OAuth provider
    code = getvalue("code")             # OAuth return code
    state = getvalue("state")           # OAuth return state
    key = getvalue("key")               # OAuth return key (github/asf)
    
    # These vals need to be valid to pass OAuth later on
    valid = False
    js = None
    isASF = False
    
    # Load and return account info (including MFA status)
    if load and load == 'true':
        account = getaccount()
        if account:
            # MFA check
            if account['github']:
                gu = account['github']
                mfa = JSON.read(open("/x1/gitbox/matt/mfa.json", "r"))
                mfastatus = 0
                if gu in mfa['disabled']:
                    account['mfa'] = False
    
                if gu in mfa['enabled']:
                    account['mfa'] = True
    
            print("Status: 200 Okay\r\nContent-Type: application/json\r\n\r\n")
            print(json.dumps(account))
        else:
            print("Status: 200 Okay\r\nContent-Type: application/json\r\n\r\n{}")
    
    # Logout
    elif logout and logout == 'true':
        account = getaccount()
        if account:
            account['cookie'] = "--"
            saveaccount(account)
        print("302 Found\r\nLocation: /setup/\r\n\r\n")
    
    # Unauth from GitHub
    elif unauth and unauth == 'github':
        account = getaccount()
        if account:
            account['github'] = None
            saveaccount(account)
        print("302 Found\r\nLocation: /setup/\r\n\r\n")
    
    # OAuth provider redirect
    elif redirect:
        rootURL = "https://gitbox.apache.org/setup"
        state = hashlib.sha1("%f-%s") % (time.time(), os.environ['REMOTE_ADDR']).hexdigest()
        rurl = urllib.quote("%s/oauth.cgi?key=%s&state=%s" % (rootURL, redirect, state))
        if redirect == "apache":
            redir = "https://oauth.apache.org/?state=%s&redirect_uri=%s" % (state, rurl)
            print("302 Found\r\nLocation: %s\r\n\r\n" % redir)
        elif redirect == "github":
            f = open("/x1/gitbox/matt/tokens/appid.txt", "r").read()
            m = re.match(r"([a-f0-9]+)|([a-f0-9]+)", f)
            cid = m.group(1)
            csec = m.group(2)
            redir = "https://github.com/login/oauth/authorize?client_id=%s&scope=default&?state=%s&redirect_uri=%s" % (cid, state, rurl)
            print("302 Found\r\nLocation: %s\r\n\r\n" % redir)
    
    
    
    # GitHub OAuth callback
    if code and state and key == 'github':
        
        # get id & secret from file
        f = open("/x1/gitbox/matt/tokens/appid.txt", "r").read()
        m = re.match(r"([a-f0-9]+)|([a-f0-9]+)", f)
        cid = m.group(1)
        csec = m.group(2)
        
        # Construct OAuth backend check POST data
        rargs = "%s&client_id=%s&client_secret=%s" % (os.environ.get("QUERY_STRING"), cid, csec)
        
        req = urllib2.Request("https://github.com/login/oauth/access_token", rargs)
        response = req.urlopen().read()
        token = re.match(r"(access_token=[a-f0-9]+)", response)
        # If we got an access token, fetch user data
        if token:
            req = urllib2.Request("https://api.github.com/user?%s" % token.group(1))
            response = req.urlopen().read()
            js = json.loads(response)
            valid = True
        
    # ASF Oauth callback
    elif state and code and key == 'apache':
        isASF = true
        req = urllib2.Request("https://oauth.apache.org/token", os.environ.get("QUERY_STRING"))
        response = req.urlopen().read()
        js = json.loads(response)
        valid = True
    
    # Did we get something useful from the backend?
    if valid and js:
        eml = js.get('email', None)
        fname = js.get('fullname', None)
        
        # update info
        updated = false
        ncookie = None
        if (eml and fname) or key == 'github':
            oaccount = nil
            # If tying an ASF account, make a session in the DB (if not already there)
            if isASF:
                cid = js.uid
                ncookie = hashlib.sha1("%f-%s" % (time.time(), os.environ.get("REMOTE_ADDR"))).hexdigest()
                # Does the user exist already?
                oaccount = getaccount(cid)
                
                # If not seen before, make a new session
                if not oaccount:
                    saveaccount({
                        'asfid': cid,
                        'name': js.fullname,
                        'githubid': None,
                        'cookie': ncookie,
                        
                    })
                # Otherwise, update the old session with new cookie
                else:
                    oaccount['cookie'] = ncookie
                    saveaccount(oaccount)
                updated = true
            # GitHub linking
            elif key == 'github':
                oaccount = getaccount()
                if oaccount:
                    oaccount['githubid'] = js.login
                    saveaccount(oaccount)
        
        # did stuff correctly!?
        if updated:
            print("302 Found\r\nLocation: /setup/\r\n")
            # New cookie set??
            if ncookie:
                print("Set-Cookie: matt=%s\r\n" % ncookie)
            print("\r\nMoved!")
        # didn't get email or name, bork!
        else:
            print("302 Found\r\nLocation: /setup/error.html\r\n\r\n")
            
    # Backend borked, let the user know
    else:
        print("302 Found\r\nLocation: /setup/error.html\r\n\r\n")

if __name__ == '__main__':
    main()
    