#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
This is the session library for AIM.
It handles setting/getting cookies and user prefs
"""


# Main imports
import cgi
import re
import sys
import traceback
import http.cookies
import uuid
import elasticsearch
import time
import ldap3
import requests
import hashlib
import json

whimsy_ts = time.time()
whimsy_json = requests.get('https://whimsy.apache.org/public/committee-info.json').json()
podling_json = requests.get('https://whimsy.apache.org/public/public_podlings.json').json()
startup_time = time.time()

class AimChat(object):
    def __init__(self, config, session):
        self.config = config
        self.session = session

    def notifyCompleted(self, obj):
        msg = "Request %s has been handled by %s." % (obj['id'], obj['handler'])
        color = 'green'
        if obj.get('error'):
            msg = "Request %s failed to complete on %s. More information available at <a href='https://aim.apache.org/?page=request&id=%s'>this page</a>." % (obj['id'], obj['id'])
            color = 'red'
        
        diff = obj.get('diff', '')
        if diff:
            msg += "<pre>Requested change:\n--------\n"
            msg += diff
            msg += "</pre>"
        if not 'hipchat' in self.config:
            return
        payload = {
            'room_id': str(self.config['hipchat']['room']),
            'auth_token': self.config['hipchat']['token'],
            'from': "AIM",
            'message_format': 'html',
            'notify': '1',
            'color': color,
            'message': msg
        }
        print("Dispatching chat message: " + msg)
        requests.post('https://api.hipchat.com/v1/rooms/message', data = payload)
    
    def notifyPatched(self, obj, rescheduled = False):
        msg = "%s request %s by %s has been approved by %s." % (obj['type'], obj['id'],obj['creator'], obj['moderator'])
        color = 'green'
        if rescheduled:
            msg = "%s request %s by %s has been rescheduled by %s." % (obj['type'], obj['id'], obj['creator'], obj['moderator'])
            color = 'yellow'
        if obj.get('approved') == False and obj.get('completed') == True:
            msg = "%s request %s by %s was denied by %s." % (obj['type'], obj['id'], obj['creator'], obj['moderator'])
            color = 'red'
        if obj.get('approved') == False and obj.get('completed') == False:
            msg = "%s request %s by %s was unapproved by %s." % (obj['type'], obj['id'], obj['creator'], obj['moderator'])
            color = 'yellow'
        
        diff = obj.get('diff', '')
        if diff:
            msg += "<pre>Requested change:\n--------\n"
            msg += diff
            msg += "</pre>"
        if not 'hipchat' in self.config:
            return
        payload = {
            'room_id': str(self.config['hipchat']['room']),
            'auth_token': self.config['hipchat']['token'],
            'from': "AIM",
            'message_format': 'html',
            'notify': '1',
            'color': color,
            'message': msg
        }
        print("Dispatching chat message: " + msg)
        requests.post('https://api.hipchat.com/v1/rooms/message', data = payload)

    def notifyNew(self, obj):
            msg = "A %s request (%s) for %s by %s has been filed.<br/>" % (obj['type'], obj['id'], obj['project'],obj['creator'])
            color = 'green'
            diff = obj.get('diff', '')
            if diff:
                msg += "<pre>Requested change:\n--------\n"
                msg += diff
                msg += "</pre>"
            if not 'hipchat' in self.config:
                return
            payload = {
                'room_id': str(self.config['hipchat']['room']),
                'auth_token': self.config['hipchat']['token'],
                'from': "AIM",
                'message_format': 'html',
                'notify': '1',
                'color': color,
                'message': msg
            }
            
            print("Dispatching chat message: " + msg)
            requests.post('https://api.hipchat.com/v1/rooms/message', data = payload)
    

class AimAPISession(object):
    
    def newCookie(self):
        cookie = self.asfid
        self.user = self.getPerms()
        doc = {
            'timestamp': time.time(),
            'user': json.dumps(self.user)
        }
        self.DB.ES.index(index=self.DB.dbname, doc_type='uisession', id = cookie, body = doc)
        self.cookie = cookie
        
    def getPerms(self):
        global whimsy_ts, whimsy_json, podling_json
        if (time.time() - whimsy_ts) > 3600:
            print("Updating whimsy JSON data first")
            whimsy_json = requests.get('https://whimsy.apache.org/public/committee-info.json').json()
            podling_json = requests.get('https://whimsy.apache.org/public/public_podlings.json').json()
            whimsy_ts = time.time()
            
        print("looking up %s" % self.asfid)
        pmcs = {}
        podlings = []
        fullName = "Unknown person"
        isRoot = False
        isMember = False
        try:
            ls = ldap3.Server(self.config['ldap']['host'],port=636, use_ssl=True)
            l = ldap3.Connection(ls, user=self.config['ldap']['user'],password=self.config['ldap']['password'],auto_bind=True)
            l.start_tls()
            
            searchBase = "dc=apache,dc=org"
            retrieveAttributes = ["cn"]
            
            # Get full name first
            l.search(search_base = 'ou=people,dc=apache,dc=org', search_filter = '(uid=%s)' % self.asfid, attributes = ['cn'])
            if l.entries:
                fullName = str(l.entries[0].cn)
            
            
            # IF infra-root, allow all projects
            searchBase = "cn=infrastructure-root,ou=groups,ou=services,dc=apache,dc=org"
            l.search(
                search_base = searchBase,
                search_filter = "(member=*)",
                attributes = ['member'],
                search_scope = ldap3.SUBTREE
                )
            for entry in l.entries:
                for uid in entry.member:
                    xid = re.match(r"uid=([^,]+)", uid).group(1)
                    if xid == self.asfid:
                        isRoot = True
                        print("is root")
            
            # Figure out if ASF Member
            searchBase = "cn=member,ou=groups,dc=apache,dc=org"
            l.search(
                search_base = searchBase,
                search_filter = "(memberUid=%s)" % self.asfid,
                attributes = ['memberUid'],
                search_scope = ldap3.SUBTREE
                )
            for entry in l.entries:
                for uid in entry.memberUid:
                    if str(uid) == self.asfid:
                        isMember = True
                        print("is asf member")
            
            
            # Find all projects this user is a owner of (meaning on the PMC of)
            searchBase = "ou=project,ou=groups,dc=apache,dc=org"
            searchFilter = "(|(owner=%s)(owner=uid=%s,ou=people,dc=apache,dc=org))" % (self.asfid, self.asfid)
            
            l.search(
                search_base = searchBase,
                search_filter = searchFilter,
                attributes = ['cn'],
                search_scope = ldap3.SUBTREE
                )
            for entry in l.entries:
                pmc = str(entry.cn)
                if pmc in whimsy_json['committees']:
                    pmcs[pmc] = whimsy_json['committees'][pmc]['mail_list']
                else:
                    pmcs[pmc] = pmc
                    podlings.append(pmc)
            
            if isRoot:
                pmcs['infrastructure'] = 'infra'
            
            # Find PMCs user can modify resources of
            canAdmin = dict(pmcs)
            if isRoot:
                searchBase = "ou=project,ou=groups,dc=apache,dc=org"
                searchFilter = "(owner=*)"
                
                l.search(
                    search_base = searchBase,
                    search_filter = searchFilter,
                    attributes = ['cn'],
                    search_scope = ldap3.SUBTREE
                    )
                for entry in l.entries:
                    pmc = str(entry.cn)
                    if pmc in whimsy_json['committees']:
                        canAdmin[pmc] = whimsy_json['committees'][pmc]['mail_list']
                    else:
                        canAdmin[pmc] = pmc
            
            
        except: # LDAP bork, return empty for now
            pass
        
        for p, entry in podling_json['podling'].items():
            if entry['status'] == 'current' and p not in podlings:
                podlings.append(p)
        return {
            'pmcs': pmcs,
            'podlings': podlings,
            'canAdmin': canAdmin,
            'id': self.asfid,
            'isRoot': isRoot,
            'isMember': isMember,
            'fullName': fullName
        }
    
    def __init__(self, DB, environ, config):
        """
        Loads the current user session or initiates a new session if
        none was found.
        """
        global startup_time
        self.config = config
        self.DB = DB
        self.Chat = AimChat(config, self)
        self.headers = [('Content-Type', 'application/json')]
        self.cookie = None
        self.asfid = environ.get('HTTP_X_REMOTE_USER', 'humbedooh')
        self.user = {
            'name': "Unknown Robit",
            'id': self.asfid,
            'pmcs': [],
            'podlings': [],
            'isRoot': False
        }
        # Construct the URL we're visiting
        self.url = "%s://%s" % (environ['wsgi.url_scheme'], environ.get('HTTP_HOST', environ.get('SERVER_NAME')))
        self.url += environ.get('SCRIPT_NAME', '/')
        
        # Get Aim cookie
        cookie = self.asfid
        try:
            sdoc = self.DB.ES.get(index=self.DB.dbname, doc_type='uisession', id = cookie)
            if sdoc and '_source' in sdoc and 'user' in sdoc['_source']:
                # Make sure this cookie has been used in the past 7 days, else nullify it.
                # Further more, run an update of the session if >1 hour ago since last update.
                age = time.time() - sdoc['_source']['timestamp']
                if age > (7*86400):
                    self.DB.ES.delete(index=self.DB.dbname, doc_type='uisession', id = cookie)
                    sdoc['_source'] = None # Wipe it!
                    doc = None
                elif age > 3600 or sdoc['_source']['timestamp'] < startup_time:
                    sdoc['_source']['timestamp'] = int(time.time()) # Update timestamp in session DB
                    sdoc['_source']['user'] = json.dumps(self.getPerms())
                    self.DB.ES.update(index=self.DB.dbname, doc_type='uisession', id = cookie, body = {'doc':sdoc['_source']})
                if sdoc:
                    self.user = json.loads(sdoc['_source']['user'])
            else:
                cookie = None
        except Exception as err:
            print(err)
            cookie = None
        if not cookie:
            self.newCookie()
        self.cookie = cookie
        self.user['gravatar'] = hashlib.md5( ("%s@apache.org" % self.asfid).lower().encode('ascii') ).hexdigest()
        
