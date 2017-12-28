#!/usr/bin/env python73
# -*- coding: utf-8 -*-
########################################################################
# OPENAPI-URI: /api/queue/list/{opts}
########################################################################
# delete:
#   requestBody:
#     content:
#       application/json:
#         schema:
#           $ref: '#/components/schemas/QueueItem'
#     description: Queue item to remove from queue
#     required: true
#   responses:
#     '200':
#       content:
#         application/json:
#           schema:
#             $ref: '#/components/schemas/ActionCompleted'
#       description: 200 response
#     default:
#       content:
#         application/json:
#           schema:
#             $ref: '#/components/schemas/Error'
#       description: unexpected error
#   security:
#   - cookieAuth: []
#   summary: Removes one or more items from the queue
# put:
#   requestBody:
#     content:
#       application/json:
#         schema:
#           $ref: '#/components/schemas/QueueItem'
#     description: Texts to analyze
#     required: true
#   responses:
#     '200':
#       content:
#         application/json:
#           schema:
#             $ref: '#/components/schemas/ActionCompleted'
#       description: 200 response
#     default:
#       content:
#         application/json:
#           schema:
#             $ref: '#/components/schemas/Error'
#       description: unexpected error
#   security:
#   - cookieAuth: []
#   summary: Adds one or more items to the queue
# patch:
#   requestBody:
#     content:
#       application/json:
#         schema:
#           $ref: '#/components/schemas/QueueItem'
#     description: Texts to analyze
#     required: true
#   responses:
#     '200':
#       content:
#         application/json:
#           schema:
#             $ref: '#/components/schemas/ActionCompleted'
#       description: 200 response
#     default:
#       content:
#         application/json:
#           schema:
#             $ref: '#/components/schemas/Error'
#       description: unexpected error
#   security:
#   - cookieAuth: []
#   summary: Edit a queue object
# get:
#   parameters:
#        - name: opts
#          in: path
#          description: Specific queue segment options (encrypt, current, old, all)
#          required: true
#          schema:
#            type: string
#   responses:
#     '200':
#       content:
#         application/json:
#           schema:
#             $ref: '#/components/schemas/QueueList'
#       description: 200 response
#     default:
#       content:
#         application/json:
#           schema:
#             $ref: '#/components/schemas/Error'
#       description: unexpected error
#   security:
#   - cookieAuth: []
#   summary: Returns the currently pending items in the process queue
# post:
#   parameters:
#        - name: opts
#          in: path
#          description: Specific queue segment options (encrypt, current, old, all)
#          required: true
#          schema:
#            type: string
#   responses:
#     '200':
#       content:
#         application/json:
#           schema:
#             $ref: '#/components/schemas/QueueList'
#       description: 200 response
#     default:
#       content:
#         application/json:
#           schema:
#             $ref: '#/components/schemas/Error'
#       description: unexpected error
#   security:
#   - cookieAuth: []
#   summary: Returns the currently pending items in the process queue
# 
########################################################################



"""
This is the queue item manager for Aim
"""


import json
import re
import time
import bcrypt
import uuid
import Crypto.PublicKey.RSA
import Crypto.Cipher.PKCS1_v1_5
import base64
import socket
import random
import string

f = open('private/aimkey.pub').read()
pubkey = Crypto.PublicKey.RSA.importKey(f)


# We use our public (but hidden!) key for encrypting
def encrypt(txt):
    cipher = Crypto.Cipher.PKCS1_v1_5.new(pubkey)
    x = base64.b64encode(cipher.encrypt(txt.encode('utf-8'))).decode('utf-8')
    return x

def pubsubChange(doc, API, session):
    """ Calculate a pubsub change """
    diff = ""
    
    pubsubs = {}
    with open("private/json/pubsub.json") as f:
        pubsubs = json.load(f)
        f.close()
        
    # Validate pubsub type
    t = doc.get('type', '')
    if t not in ['git', 'svn']:
        raise API.exception(400, "Invalid pubsub type specified")
    
    # validate domain perms
    d = doc.get('domain', '')
    if d.replace('.apache.org', '') not in session.user['canAdmin'].values():
        raise API.exception(403, "You cannot edit pubsub for this sub-domain!")
    
    # validate source
    s = doc.get('source', '').strip()
    if 'https://git-wip-us.apache.org/repos/asf/' not in s and\
        'https://gitbox.apache.org/repos/asf/' not in s and\
        'https://svn.apache.org/repos/asf/' not in s and\
        'https://github.com/apache/' not in s:
        raise API.exception(400, "PubSub source must point to SVN, Git-Wip, GitBox or GitHub!")
    
    
    
    wwwpath = "/www/%s" % d
    if d in pubsubs:
        diff = "- Modify pubsub settings for %s" % wwwpath
        if pubsubs[d]['type'] == 'svn' and t == 'git':
            diff += "- Change pubsub type to gitpubsub\n"
            doc['clobber_svn'] = True
            doc['add_git'] = True
        elif pubsubs[d]['type'] == 'git' and t == 'svn':
            doc['clobber_git'] = True
            doc['add_svn'] = True
            diff += "- Change pubsub type to svnpubsub\n"
    else:
        diff = "- Create pubsub settings for %s" % wwwpath
    
    diff += "- Change pubsub URL to %s\n" % s
    doc['source'] = s
    return diff, doc

def mlChange(doc, API, session):
    """ Calculate a mailing list change """
    diff = ""
    mls = {}
    with open("private/json/ml-modsubs.json") as f:
        mls = json.load(f)
        f.close()
    li = doc['listname']
    l,d = li.split('@', 2)
    d = d.replace(".apache.org", "")
    
    # Check that we can edit/add lists here
    if d not in session.user['canAdmin'].values():
        raise API.exception(403, "You cannot edit mailing lists for this sub-domain!")
    if doc.get('action', '') not in ['create', 'modify']:
        raise API.exception(400, "Invalid action specified")
    
    if li in mls:
        diff = "- Modify settings for %s\n" % li
    else:
        diff = " - Create mailing list %s\n" % li
    
    # Calculate moderator diff
    xmods = []
    for mod in doc['moderators']:
        if len(mod) > 0:
            if re.match(r"^[^<>\"\s|\\&:;,]+@[^<>\"\s|\\&:;,]+$", mod):
                xmods.append(mod)
            else:
                raise API.exception(400, "Invalid moderator email address supplied!")
            
    # Default options if missing
    doc['private'] =  doc.get('private', False)
    doc['trailer'] =  doc.get('trailer', False)
    doc['modunsubbed'] =  doc.get('modunsubbed', True)
    
    
    newmods = set(xmods)
    newopts = doc.get('options', "")
    doc['mod_remove'] = []
    doc['mod_add'] = []
    if li in mls:
        oml = mls[li]
        oldmods = set(oml['moderators'])
        added = newmods - oldmods
        removed = oldmods - newmods
        for x in removed:
            diff += "- Remove %s as a moderator\n" % x
            doc['mod_remove'].append(x)
        for x in added:
            diff += "- Add %s as a moderator\n" % x
            doc['mod_add'].append(x)
        
        #Privacy settings
        if doc['private'] and not oml['private']:
            diff += "- Set list to private list (moderate subscribers, archive privately)\n"
        elif oml['private'] and not doc['private']:
            diff += "- Set list to public (don't moderate subscribers, archive publicly)\n"
        
        # Trailers
        if doc['trailer'] and not oml['trailer']:
            diff += "- Add unsubscribe trailer to emails\n"
        elif oml['trailer'] and not doc['trailer']:
            diff += "- Remove unsubscribe trailer from emails\n"
        
        # Mod unsubbed
        if doc['modunsubbed'] and not oml['modunsubbed']:
            diff += "- Moderate emails from unsubscribed users\n"
        elif oml['modunsubbed'] and not doc['modunsubbed']:
            diff += "- Do not moderate emails from unsubscribed users\n"
        
        
    else:
        doc['action'] = 'create'
        diff = "- Create new mailing list, %s\n" % li
        for x in xmods:
            diff += "- Add %s as a moderator\n" % x
            doc['mod_add'].append(x)
        
        #Privacy settings
        if doc['private']:
            diff += "- Set list to private list (moderate subscribers, archive privately)\n"
        else:
            diff += "- Set list to public (don't moderate subscribers, archive publicly)\n"
        
        # Trailers
        if doc['trailer']:
            diff += "- Add unsubscribe trailer to emails\n"
        else:
            diff += "- Do not add unsubscribe trailer to emails\n"
        
        # Mod unsubbed
        if doc['modunsubbed']:
            diff += "- Moderate emails from unsubscribed users\n"
        else:
            diff += "- Do not moderate emails from unsubscribed users\n"
        
        
    return diff, doc
    

def unsubChange(doc, API, session):
    """ Calculate a mailing list unsub request """
    diff = ""
    mls = {}
    with open("private/json/ml-modsubs.json") as f:
        mls = json.load(f)
        f.close()
    li = doc['listname']
    l,d = li.split('@', 2)
    d = d.replace(".apache.org", "")
    
    # Check that we can edit/add lists here
    if d not in session.user['canAdmin'].values():
        raise API.exception(403, "You cannot edit mailing lists for this sub-domain!")
    
    # Validate method
    if doc.get('action', '') not in ['unsub', 'ban']:
        raise API.exception(400, "Invalid action specified")
    
    # Validate target
    target = doc.get('target')
    if not re.match(r"^[^<>\"\s|\\&:;,]+@[^<>\"\s|\\&:;,]+$", target):
        raise API.exception(400, "Invalid email address supplied!")
    
    if li in mls:
        if not target in mls[li]['subscribers']:
            raise API.exception(404, "Email address not found in subscriber list!")
    else:
        raise API.exception(404, "Mailing list not found!")
    
    diff = "- Modify subscribers on %s\n" % li
    diff += "- Remove %s from the mailing list\n" % target
    if doc.get('action') == 'ban':
        diff += "- Prevent %s from subscribing to the list\n" % target
    return diff, doc

def dnsChange(doc, API, session):
    """ Calculate a DNS request """
    diff = ""
    
    # Validate domain
    domain = doc.get('domain', '').strip().replace('.apache.org', '')
    if domain == '' or re.search(r"([^-a-z0-9])", domain):
        raise API.exception(400, "Invalid subdomain name!")
    
    # Make sure we have perms
    if domain not in session.user['canAdmin'].values():
        raise API.exception(403, "You do not have permission to request this DNS change; Domain %s not found in your PMC/Podling list." % domain)
    
    # Make sure DNS doesn't already resolve
    try:
        dns = socket.gethostbyname("%s.apache.org" % domain)
        raise API.exception(400, "DNS entry for %s.apache.org already exists" % domain)
    except:
        pass
    
    doc['domain'] = domain
    diff = "- Set up DNS record for %s.apache.org" % domain
    return diff, doc


def repoChange(doc, API, session):
    """ Calculate a repository request diff """
    diff = ""
    repos = {}
    with open("private/json/repositories.json") as f:
        repos = json.load(f)
        f.close()
    
    r = doc['repo'].replace('.git', '')
    p = doc.get('project', 'foo')
    t = doc.get('type', 'gitbox')
    gr = doc.get('graduate', False)
    doc['commitlist'] = doc.get('commitlist', "commits@%s.apache.org" % (session.user['canAdmin'][p]))
    doc['issuelist'] = doc.get('issuelist', "dev@%s.apache.org" % (session.user['canAdmin'][p]))
    doc['jira'] = doc.get('jira', "default")
    
    # Check that we can edit/add repos here
    if p not in session.user['canAdmin']:
        raise API.exception(403, "You cannot edit repositories for this project!")
    
    if t in ['svn', 'svnpmc'] and r != p:
        raise API.exception(400, "SVN areas can only be the name of the project")
    else:
        # Validate repo name
        m = re.match(r"^(incubator-)?([^-.]+)(?:.*\.git)?", r)
        project = m.group(2)
        podling = m.group(1)
        if project != p:
            raise API.exception(403, "Repository %s must be named after the project, for example %s.git or %s-fop.git" % (p, p))
        if project in session.user['podlings'] and not podling:
            raise API.exception(403, "Podling repositories MUST start with 'incubator-'!")
    
    
    # Validate target emails
    if not re.match(r"^[^<>\"\s|\\&:;,]+@[^<>\"\s|\\&:;,]+$", doc['commitlist']):
        raise API.exception(400, "Invalid email address supplied for commit list!")
    if not re.match(r"^[^<>\"\s|\\&:;,]+@[^<>\"\s|\\&:;,]+$", doc['issuelist']):
        raise API.exception(400, "Invalid email address supplied for issue list!")
    
    if t in ['gitbox', 'git-wip']:
        r += ".git"
    found = False
    if project in repos:
        prepos = repos[project]
        for repo in prepos:
            if repo['repository'] == r:
                found = True
                diff += "- Edit settings for %s\n" % r
                if t != repo['type']:
                    diff += "- Move repository to %s\n" % t
                if repo.get('commitlist', '') != doc['commitlist']:
                    diff += "- Set commit notifications to go to %s\n" % doc['commitlist']
                if repo.get('issuelist', '') != doc['issuelist']:
                    diff += "- Set issue notifications to go to %s\n" % doc['issuelist']
                if repo.get('jira', 'default') != doc['jira']:
                    diff += "- Set JIRA opts to: %s\n" % doc['jira']
        
    if not found:
        diff += "- Create new repo %s on %s\n" % (r, t)
        diff += "- Set commit notifications to go to %s\n" % doc['commitlist']
        diff += "- Set issue notifications to go to %s\n" % doc['issuelist']
        diff += "- Set JIRA opts to: %s\n" % doc['jira']
    else:
        if gr:
            diff += " - Graduate repository (remove incubator reference)\n"
        
    
    
    return diff, doc

def run(API, environ, indata, session):
    
    method = environ.get('REQUEST_METHOD', 'POST')
    
    # Add an item to the queue?
    if method == "PUT":
        payload = indata.get('payload')
        t = indata.get('type')
        tlp = indata.get('project')
        por = indata.get('por')
        if not (payload or t):
            raise API.exception(400, "Missing payload or request type!")
        
        #TODO: Validate requests properly, so the workers don't have to bork too often.
        diff = ""
        if t == 'mailinglist':
            diff, payload = mlChange(payload, API, session)
        elif t == 'mail-unsub':
            diff, payload = unsubChange(payload, API, session)
        elif t == 'pubsub':
            diff, payload = pubsubChange(payload, API, session)
        elif t == 'dns':
            diff, payload = dnsChange(payload, API, session)
        elif t == 'repository':
            diff, payload = repoChange(payload, API, session)
        else:
            raise API.exception(400, "Unknown request type!")
        
        itemid = ''.join(random.choice(string.ascii_uppercase + string.digits) for _ in range(4))
        while session.DB.ES.exists(index=session.DB.dbname, doc_type='queueitem', id = itemid):
            itemid = ''.join(random.choice(string.ascii_uppercase + string.digits) for _ in range(4))
        doc = {
            'id': itemid,
            'type': t,
            'project': tlp,
            'por': por,
            'creator': session.user['id'],
            'approved': False,
            'approver': None,
            'createdTime': time.time(),
            'approvedTime': 0,
            'payload': payload,
            'completed': False,
            'error': None,
            'diff': diff,
            'handler': None
        }
        session.DB.ES.index(index=session.DB.dbname, doc_type='queueitem', id = itemid, body = doc)
        session.Chat.notifyNew(doc)
        yield json.dumps({'okay': True, 'message': 'Request has been queued!', 'id': itemid})
    
    # Remove an item from queue? (mark as completed)
    if method == 'DELETE':
        itemid = indata.get('id', 'foobar')
        handler = indata.get('handler', 'unknown.apache.org')
        err = indata.get('error', None)
        if session.DB.ES.exists(index=session.DB.dbname, doc_type='queueitem', id = itemid):
            doc = session.DB.ES.get(index=session.DB.dbname, doc_type='queueitem', id = itemid)['_source']
            doc['completed'] = False if err else True
            doc['handler'] = handler
            doc['error'] = err
            session.DB.ES.index(index=session.DB.dbname, doc_type='queueitem', id = itemid, body = doc)
            session.Chat.notifyCompleted(doc)
            yield json.dumps({'okay': True, 'message': "Item removed from queue"})
        else:
            raise API.exception(404, "Item not found!")
    
    # Patch an item (change status)
    if method == 'PATCH':
        itemid = indata.get('id', 'foobar')
        moderator = session.user['id']
        status = indata.get('status', 'approved')
        err = indata.get('error', None)
        if session.DB.ES.exists(index=session.DB.dbname, doc_type='queueitem', id = itemid):
            doc = session.DB.ES.get(index=session.DB.dbname, doc_type='queueitem', id = itemid)['_source']
            if doc['creator'] == session.user['id'] and (status != 'denied' and status != 'unapproved'):
                raise API.exception(400, "For security reasons, you cannot approve queued items you have created!")
            doc['completed'] = True if status == 'denied' else False
            doc['moderator'] = moderator
            doc['error'] = err
            if status == 'denied':
                doc['approved'] = False
                doc['approver'] = None
                doc['completed'] = True
                doc['error'] = "Denied by %s" % session.user['id']
            if status == 'rescheduled' or status == 'approved':
                doc['error'] = None
                doc['completed'] = False
                doc['approved'] = True
                doc['approver'] = moderator
            if status == 'unapproved':
                doc['error'] = None
                doc['completed'] = False
                doc['approved'] = False
                doc['approver'] = None
            session.DB.ES.index(index=session.DB.dbname, doc_type='queueitem', id = itemid, body = doc)
            session.Chat.notifyPatched(doc, rescheduled = (status == 'rescheduled'))
            time.sleep(1)
            yield json.dumps({'okay': True, 'message': "Item patched"})
        else:
            raise API.exception(404, "Item not found!")
    
    
    # Get queue?
    if method == "GET" or method == "POST":
        if session.user['isRoot'] == False and session.user['id'] != 'asfrobit':
            raise API.exception(403, "You do not have access to view the queue")
        if indata.get('opts', '') == 'pending':
            query = {
                'query': {
                    'bool': {
                        'must': [
                            {
                                'term': {
                                    'approved': False
                                }
                            },
                            {
                                'term': {
                                    'completed': False
                                }
                            }
                        ]
                    }
                }
            }
            res = session.DB.ES.search(
                index=session.DB.dbname,
                doc_type="queueitem",
                body = query
            )
            queue = []
            for hit in res['hits']['hits']:
                entry = hit['_source']
                queue.append(entry)
        
        if indata.get('opts', '') == 'current':
            query = {
                'query': {
                    'bool': {
                        'must': [
                            {
                                'term': {
                                    'approved': True
                                }
                            },
                            {
                                'term': {
                                    'completed': False
                                }
                            }
                        ]
                    }
                }
            }
            res = session.DB.ES.search(
                index=session.DB.dbname,
                doc_type="queueitem",
                body = query
            )
            queue = []
            for hit in res['hits']['hits']:
                entry = hit['_source']
                queue.append(entry)
            
        jsout = {
            'queue': queue
        }
        
        if indata.get('opts', '') == 'encrypt':
            jsout = {
                'queue': encrypt(json.dumps(queue))
            }
        
        yield json.dumps(jsout)
        return

if __name__ == '__main__':
    for f in run(None, {}, {}, {}):
        print(f)
