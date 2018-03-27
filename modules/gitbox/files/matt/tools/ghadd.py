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

# This is ghadd.py - inviter program for the ASF GitHub org.
# It checks the current github team against LDAP (githubUsername attr)
# and invites/removes people accordingly.

import os
import sys
import re
import ldap
import urllib2
import json
import requests
import hashlib
import ConfigParser
import logging

logging.basicConfig(filename='ghadd.log', format='[%(asctime)s]: %(message)s', level=logging.INFO)

# LDAP Defs
UID_RE = re.compile("uid=([^,]+),ou=people,dc=apache,dc=org")

# Run `python grouper.py debug` to check teams but not add/remove users
DEBUG_RUN = True if len(sys.argv) > 1 and sys.argv[1] == 'debug' else False
if DEBUG_RUN:
    print("Debug run active! Not modifying team")

CONFIG = ConfigParser.ConfigParser()
CONFIG.read("grouper.cfg") # Yeah, you're not getting this info...

# LDAP setup
LDAP_URI = "ldaps://ldap-us-ro.apache.org:636"
LDAP_USER = CONFIG.get('ldap', 'user')
LDAP_PASSWORD = CONFIG.get('ldap', 'password')

ORG_READ_TOKEN = CONFIG.get('github', 'token')
TEAM_ID = "644234" # GitHub team ID for the ASF

# Existing map of people we have invited (if it exists, who knows!)
logging.info("Preloading existing GH map...")
MAP= {}
try:
    MAP = json.load(open("../ghadd.json"))
    for k in MAP:
        MAP[k] = MAP[k].lower() # case sensitivity, bleh
except:
    pass


def removeGitHubOrgMember(login):
    """ Remove a team member from the apache org """
    if login.lower() in ['humbedooh', 'asfbot', 'asfgit']:
        logging.info("Not removing this account just yet")
        return
    logging.info("- Removing %s from organisation...")
    url = "https://api.github.com/orgs/apache/members/%s" % login
    r = requests.delete(url, headers = {'Authorization': "token %s" % ORG_READ_TOKEN})

    if r.status_code <= 204:
        logging.info("- Removal done!")
    else:
        logging.error("- Error occurred while trying to remove member!")
        logging.error(r.status_code)

def addGitHubTeamMember(teamID, login):
    """ Add a member to a team """
    if str(int(teamID)) != str(teamID):
        logging.warning("Bad Team ID passed!!")
        return None
    logging.info("- Adding %s to team #%s..." % (login, str(teamID)))
    url = "https://api.github.com/teams/%s/memberships/%s" % (teamID, login)
    r = requests.put(url, headers = {'Authorization': "token %s" % ORG_READ_TOKEN})
    data = json.loads(r.content)
    if 'state' in data:
        logging.info("- Additions done!")
    else:
        logging.error("- Error occurred while trying to add member!")
        logging.error(data)

def getGitHubTeamMembers(teamID):
    """Given a Team ID, fetch the current list of members of the team"""
    members = []
    if str(int(teamID)) != str(teamID):
        logging.warning("Bad Team ID passed!!")
        return None
    for n in range(1, 200): # 200 would be 6000 members, we have 1300ish now...
        url = "https://api.github.com/teams/%s/members?access_token=%s&page=%u" % (teamID, ORG_READ_TOKEN, n)
        response = urllib2.urlopen(url)
        data = json.load(response)
        # Break if no more members
        if len(data) == 0:
            break
        for member in data:
            members.append(member['login'].lower())
    return sorted(members)

def getCommitters():
    """ Gets the list of committers and their github ID """
    committers = {}
    # This might fail in case of ldap bork, if so we'll return nothing.
    try:
        ldapClient = ldap.initialize(LDAP_URI)
        ldapClient.set_option(ldap.OPT_REFERRALS, 0)

        ldapClient.bind(LDAP_USER, LDAP_PASSWORD)

        results = ldapClient.search_s("ou=people,dc=apache,dc=org", ldap.SCOPE_SUBTREE, attrlist=["githubUsername"])

        for result in results:
            result_dn = result[0]
            result_attrs = result[1]
            if "githubUsername" in result_attrs:
                m = UID_RE.match(result_dn)
                asfid = m.group(1)
                ghid = result_attrs['githubUsername'][0]
                committers[asfid] = ghid.lower() # case!

        ldapClient.unbind_s()
    except Exception as err:
        logging.error("Could not fetch LDAP data: %s" % err)
        committers = None
    return committers



####################
# MAIN STARTS HERE #
####################

committers = getCommitters()
current_team = getGitHubTeamMembers(TEAM_ID)
logging.info("Found %u people with GH username in LDAP" % len(committers.values()))
logging.info("Found %u people in our GitHub org" % len(current_team))

gh_added = 0
gh_removed = 0

# Check for expired usernames, remove them.
for member in current_team:
    if member not in committers.values():
        logging.info("%s wasn't found in LDAP, removing!" % member)
        gh_removed += 1
        if not DEBUG_RUN:
            removeGitHubOrgMember(member)

# Check for new users, add if missing
for k in committers:
    member = committers[k]
    # Check that user is not in github (current_team) and hasn't been invited yet (MAP)
    if member not in current_team and member not in MAP.values():
        logging.info("%s (%s) wasn't found in GitHub, inviting!" % (member, k))
        if re.match(r"^[-a-zA-Z_0-9.]+", member):
            gh_added += 1
            if not DEBUG_RUN:
                addGitHubTeamMember(TEAM_ID, member)
        else:
            logging.info("Invalid GH username detected, ignoring this..")

# Save updated map
MAP = committers

# Spit out JSON github map
with open("../ghadd.json", "w") as f:
    json.dump(MAP, f)
    f.close()

logging.info("ALL DONE WITH THIS RUN! Added %u new members, removed %u old ones." % (gh_added, gh_removed))
