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
import cgi, sqlite3, hashlib, Cookie, urllib

xform = cgi.FieldStorage();

def getvalue(key):
    val = xform.getvalue(key)
    if val:
        return val
    else:
        return None
""" Get an account entry from the DB """
def getaccount():
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
        cursor.execute("UPDATE sessions SET githubid=?,displayname=?,mfa=? WHERE asfid=?", (acc['github'], acc['name'],acc['mfa'], acc['asfid'],))
    else:
        cursor.execute("INSERT INTO sessions (cookie,asfid,githubid,displayname,mfa) VALUES (?,?,?,?,?)" % (acc['asfid'], acc['github'], acc['name'], acc['mfa']))
    conn.commit()
    
    
# Get some CGI vars
load = getvalue("load")
logout = getvalue("logout")
unauth = getvalue("unauth")
redir = getvalue("redirect")

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
elif logout and logout == 'true':
    account = getaccount()
    if account:
        account['cookie'] = "--"
        saveaccount(account)
    end
    print("302 Found\r\nLocation: /\r\n\r\n")

elif unauth and unauth == 'github':
    account = getaccount()
    if account:
        account['github'] = None
        saveaccount(account)
    end
    print("302 Found\r\nLocation: /\r\n\r\n")



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
    end
end



################################
# THE REST BELOW IS NOT DONE!! #
################################




 -- GitHub Auth callback
if get.code and get.state and get.key == 'github' then
    
    -- get id & secret from file
    local f = io.open("/var/www/matt/tokens/appid.txt", "r")
    local cid, csec = f:read("*a"):match("([a-f0-9]+)|([a-f0-9]+)")
    f:close()
    
    r.args = r.args .. ("&client_id=%s&client_secret=%s"):format(cid, csec)
    local result = https.request("https://github.com/login/oauth/access_token", r.args)
    local token = result:match("(access_token=[a-f0-9]+)")
    if token then
        local result = https.request("https://api.github.com/user?" .. token)
        valid, json = pcall(function() return JSON.decode(result) end)
    end
    
-- ASF Oauth callback
elseif get.state and get.code and get.key == 'apache' then
    isASF = true
    local result = https.request("https://oauth.apache.org/token", r.args)
    valid, json = pcall(function() return JSON.decode(result) end)
end



-- Did we get something useful from the backend?
if valid and json then
    local eml = json.email
    local fname = json.fullname
    
    -- update info
    local updated = false
    if (eml and fname) or get.key == 'github' then
        local oaccount = nil
        if isASF then
            local cid = json.uid
            -- Does the user exist already?
            oaccount = login.get(r, cid)
            if not oaccount then
                login.update(r, cid, {
                    fullname = json.fullname,
                    email = json.email,
                    uid = json.uid,
                    external = {}
                })
            else
                login.update(r, cid, oaccount.credentials)
            end
            updated = true
        elseif get.key == 'github' then
            oaccount = login.get(r)
            if oaccount then
                oaccount.credentials.external.github = {
                    username = json.login
                }
                login.update(r, oaccount.cid, oaccount.credentials)
                updated = true
            end
        end
    end
    
    -- did stuff correctly!
    if updated then
        r.err_headers_out['Location'] = rootURL
        r.status = 302
        return 302
    -- didn't get email or name, bork!
    else
        r.err_headers_out['Location'] = rootURL .. "error.html"
        r.status = 302
        return 302
    end
-- Backend borked, let the user know
else
    r.err_headers_out['Location'] = rootURL .. "error.html"
    r.status = 302
    return 302
end
return apache2.OK