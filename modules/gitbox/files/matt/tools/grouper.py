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

import ConfigParser
import json
import logging
import os
import re
import sqlite3
import sys
import urllib2

import ldap
import requests

logging.basicConfig(filename='grouper.log',
                    format='[%(asctime)s]: %(message)s', level=logging.INFO)

# LDAP Defs
UID_RE = re.compile("uid=([^,]+),ou=people,dc=apache,dc=org")

# Run `python grouper.py debug` to check teams but not add/remove users
DEBUG_RUN = True if len(sys.argv) > 1 and sys.argv[1] == 'debug' else False
if DEBUG_RUN:
    print("Debug run active! Not modifying teams")
CONFIG = ConfigParser.ConfigParser()
CONFIG.read("grouper.cfg")  # Yeah, you're not getting this info...

LDAP_URI = "ldaps://ldap-us-ro.apache.org:636"
LDAP_USER = CONFIG.get('ldap', 'user')
LDAP_PASSWORD = CONFIG.get('ldap', 'password')

MATT_PROJECTS = {}
ORG_READ_TOKEN = CONFIG.get('github', 'token')

logging.info("Preloading 2FA JSON index...")
MFA = json.load(open("../mfa.json"))

# GH Mappings
WRITERS = {}
LINKS = {}


def getGitHubTeams():
    """Fetches a list of all GitHub committer teams (projects only, not the
    parent org team or the admin teams)"""
    logging.info("Fetching GitHub teams...")
    teams = {}
    for n in range(1, 100):
        url = "https://api.github.com/orgs/apache/teams?access_token=%s&page=%u" % (
            ORG_READ_TOKEN, n)
        response = urllib2.urlopen(url)
        data = json.load(response)
        # Break if we've hit the end
        if len(data) == 0:
            break

        for entry in data:
            # We are only interested in project teams
            m = re.match(r"^(.+)-committers$", entry['slug'])
            if m:
                project = m.group(1)
                # We don't want the umbrella team
                if project != 'apache':
                    teams[entry['id']] = project
                    logging.info("found team: %s-committers" % project)
    return teams


def getGitHubRepos():
    """ Fetches all GitHub repos we own """
    logging.info(
        "Fetching list of GitHub repos, hang on (this may take a while!)..")
    repos = []
    for n in range(1, 100):  # 100 would be 3000 repos, we have 750ish now...
        url = "https://api.github.com/orgs/apache/repos?access_token=%s&page=%u" % (
            ORG_READ_TOKEN, n)
        response = urllib2.urlopen(url)
        data = json.load(response)
        # Break if no more repos
        if len(data) == 0:
            break
        for repo in data:
            repos.append(repo['name'])
    return sorted(repos)


def getGitHubTeamMembers(teamID):
    """Given a Team ID, fetch the current list of members of the team"""
    members = []
    if str(int(teamID)) != str(teamID):
        logging.warning("Bad Team ID passed!!")
        return None
    for n in range(1, 100):  # 100 would be 3000 repos, we have 750ish now...
        url = "https://api.github.com/teams/%s/members?access_token=%s&page=%u" % (
            teamID, ORG_READ_TOKEN, n)
        response = urllib2.urlopen(url)
        data = json.load(response)
        # Break if no more members
        if len(data) == 0:
            break
        for member in data:
            members.append(member['login'])
    return sorted(members)


def getGitHubTeamRepos(teamID):
    """Given a Team ID, fetch the current list of repos in the team"""
    repos = []
    if str(int(teamID)) != str(teamID):
        logging.warning("Bad Team ID passed!!")
        return None
    for n in range(1, 10):
        url = "https://api.github.com/teams/%s/repos?access_token=%s&page=%u" % (
            teamID, ORG_READ_TOKEN, n)
        response = urllib2.urlopen(url)
        data = json.load(response)
        # Break if no more members
        if len(data) == 0:
            break
        for repo in data:
            repos.append(repo['name'])
    return sorted(repos)


def createGitHubTeam(project):
    """ Given a project, try to create it as a GitHub team"""
    logging.info("- Trying to create %s as a GitHub team..." % project)
    # Make sure we only allow the ones with permission to use MATT
    if not project in MATT_PROJECTS:
        logging.error(
            " - This project has not been cleared for MATT yet. Aborting team creation")
        return False

    url = "https://api.github.com/orgs/apache/teams?access_token=%s" % ORG_READ_TOKEN
    data = json.dumps({'name': "%s committers" % project})
    r = requests.post(url, data=data, allow_redirects=True)
    data = json.loads(r.content)
    if data and 'id' in data:
        logging.info("New GitHub team created as #%s" % str(data['id']))
        return data['id']
    else:
        logging.warning(
            "Unknown return code, dunno if the team was created or not...?")
        logging.warning(data)
        return None


def removeGitHubTeamMember(teamID, login):
    """ Remove a team member from a team """
    if str(int(teamID)) != str(teamID):
        logging.warning("Bad Team ID passed!!")
        return None
    if login.lower() == 'humbedooh':
        logging.info("Not removing Mr. Humbedooh just yet")
        return
    logging.info("- Removing %s from team #%s..." % (login, str(teamID)))
    url = "https://api.github.com/teams/%s/memberships/%s" % (teamID, login)
    r = requests.delete(
        url, headers={'Authorization': "token %s" % ORG_READ_TOKEN})

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
    r = requests.put(
        url, headers={'Authorization': "token %s" % ORG_READ_TOKEN})
    data = json.loads(r.content)
    if 'state' in data:
        logging.info("- Additions done!")
    else:
        logging.error("- Error occurred while trying to add member!")
        logging.error(data)


def addGitHubTeamRepo(teamID, repo):
    """ Add a repo to a team """
    if str(int(teamID)) != str(teamID):
        logging.warning("Bad Team ID passed!!")
        return None
    logging.info("- Adding repo %s to team #%s..." % (repo, str(teamID)))
    url = "https://api.github.com/teams/%s/repos/apache/%s" % (teamID, repo)
    r = requests.put(url, data="{\"permission\": \"push\"}",
                     headers={'Authorization': "token %s" % ORG_READ_TOKEN})
    if r.status_code <= 204:
        logging.info("- Team successfully subscribed to repo!")
    else:
        logging.error("- Error occurred while trying to add repo!")
        logging.error(r.content)


def getStandardGroup(group):
    """ Gets the list of availids in a standard group (pmcs, services, podlings) """
    logging.info("Fetching LDAP group list for %s" % group)
    ldap_base = "cn=%s,ou=project,ou=groups,dc=apache,dc=org" % group
    # First, check if there's a hardcoded member list for this group
    # If so, read it and return that instead of trying LDAP
    if CONFIG.has_section('group:%s' % group) and CONFIG.has_option('group:%s' % group, 'members'):
        logging.warning("Found hardcoded member list for %s!" % group)
        return CONFIG.get('group:%s' % group, 'members').split(' ')
    if CONFIG.has_section('group:%s' % group) and CONFIG.has_option('group:%s' % group, 'ldap'):
        ldap_base = CONFIG.get('group:%s' % group, 'ldap')
    ldap_key = "member"
    if CONFIG.has_section('group:%s' % group) and CONFIG.has_option('group:%s' % group, 'ldapkey'):
        ldap_key = CONFIG.get('group:%s' % group, 'ldapkey')
    groupmembers = []
    # This might fail in case of ldap bork, if so we'll return nothing.
    try:
        ldapClient = ldap.initialize(LDAP_URI)
        ldapClient.set_option(ldap.OPT_REFERRALS, 0)

        ldapClient.bind(LDAP_USER, LDAP_PASSWORD)

        # This is using the new podling/etc LDAP groups defined by Sam
        results = ldapClient.search_s(ldap_base, ldap.SCOPE_BASE)

        for result in results:
            result_dn = result[0]
            result_attrs = result[1]
            # We are only interested in the member attribs here. owner == ppmc,
            # but we don't care
            if ldap_key in result_attrs:
                for member in result_attrs[ldap_key]:
                    # results are in the form uid=janedoe,dc=... so weed out
                    # the uid
                    m = UID_RE.match(member)
                    if m:
                        groupmembers.append(m.group(1))

        ldapClient.unbind_s()
        groupmembers = sorted(groupmembers)  # alphasort
    except Exception as err:
        logging.error("Could not fetch LDAP data: %s" % err)
        groupmembers = None
    return groupmembers


####################
# MAIN STARTS HERE #
####################


# Get a list of all asf/github IDs
logging.info("Loading all ASF<->GitHub links from gitbox.db")
conn = sqlite3.connect('/x1/gitbox/db/gitbox.db')
cursor = conn.cursor()

cursor.execute("SELECT asfid,githubid,mfa FROM ids")
accounts = cursor.fetchall()

conn.close()
logging.info("Found %u account links!" % len(accounts))

# get a list of all repos that are active on gitbox
gitdir = '/x1/repos/asf'
allrepos = filter(lambda repo: os.path.isdir(
    os.path.join(gitdir, repo)), os.listdir(gitdir))

# turn that into a list of projects to run the manager for
for repo in allrepos:
    m = re.match(r"(?:incubator-)?([^-.]+)(?:.*\.git)", repo)
    if m:  # don't see why this would fail, but best to be sure
        project = m.group(1)
        if not project in MATT_PROJECTS:
            MATT_PROJECTS[project] = "tlp" if not re.match(
                r"incubator-", repo) else "podling"  # distinguish between tlp and podling

# Then, start off by getting all existing GitHub teams and repos - we'll
# need that later.
existingTeams = getGitHubTeams()
existingRepos = getGitHubRepos()


# Process each project in the MATT test
for project in MATT_PROJECTS:
    logging.info("Processing GitHub team for " + project)
    ptype = MATT_PROJECTS[project]

    # Does the team exist?
    teamID = None
    for team in existingTeams:
        if existingTeams[team] == project:
            teamID = team
            logging.info("- Team exists on GitHub")
            break
    # If not found, create it (or try to, stuff may break)
    if not teamID:
        logging.info("- Team does not yet exist on GitHub, creating...")
        teamID = createGitHubTeam(project)
        if not teamID:
            logging.error("Something went very wrong here, aborting!")
            break

    # Make sure all $tlp-* repos are writeable by this team
    teamRepos = getGitHubTeamRepos(teamID)
    logging.info("Team is subbed to the following repos: " +
                 ", ".join(teamRepos))
    for repo in existingRepos:
        m = re.match(r"^(?:incubator-)?([^-]+)-?", repo)
        p = m.group(1)
        if p == project and not repo in teamRepos and os.path.exists("/x1/repos/asf/%s.git" % repo):
            logging.info("Need to add " + repo + " repo to the team...")
            addGitHubTeamRepo(teamID, repo)

    # Now get the current list of members on GitHub
    members = getGitHubTeamMembers(teamID)
    if teamID in existingTeams:
        logging.info(existingTeams[teamID] + ": " + ", ".join(members))

    # Now get the committer availids from LDAP
    ldap_team = getStandardGroup(project)
    if not ldap_team or len(ldap_team) == 0:
        logging.warning(
            "LDAP Borked (no group data returned)? Trying next project instead")
        continue

    # For each committer, IF THEY HAVE MFA, add them to a 'this is what it
    # should look like' list
    hopefulTeam = []
    for committer in ldap_team:
        githubID = None
        for account in accounts:
            # Check that we found a match
            if account[0].lower() == committer:
                githubID = account[1]
        # Make sure we found the user and the latest MFA scan shows MFA enabled
        if githubID and githubID in MFA['enabled']:
            hopefulTeam.append(githubID)
        # If MFA was disabled again, we can't have 'em here.
        elif githubID and githubID in MFA['disabled']:
            logging.warning(
                githubID + " does not have MFA enabled, can't add to team")
        elif githubID:
            logging.error(
                githubID + " does not seem to be in the MFA JSON (neither disabled nor enabled); likely: unaccepted org invite")
        else:
            logging.warning(
                committer + " does not seem to have linked ASF and GitHub ID at gitbox.a.o/setup yet (not found in gitbox.db), ignoring")

    # If no team, assume something broke for now
    if len(hopefulTeam) == 0:
        logging.warning(
            "No hopeful GitHub team could be constructed, assuming something's wrong and cycling to next project")
        continue

    # Now, for each member in the team, find those that don't belong here.
    for member in members:
        if not member in hopefulTeam:
            logging.info(
                member + " should not be a part of this team, removing...")
            if not DEBUG_RUN:
                removeGitHubTeamMember(teamID, member)

    # Lastly, add those that should be here but aren't
    for member in hopefulTeam:
        if not member in members:
            logging.info(member + " not found in GitHub team, adding...")
            if not DEBUG_RUN:
                addGitHubTeamMember(teamID, member)

    # Add writers to GH map
    WRITERS[project] = hopefulTeam

    logging.info("Done with " + project + ", moving to next project...")

# Spit out JSON github map
for account in accounts:
    LINKS[account[0].lower()] = account[1]
with open("/x1/gitbox/matt/site/ghmap.json", "w") as f:
    json.dump({
        'repos': WRITERS,
        'map': LINKS
    }, f)
    f.close()

logging.info("ALL DONE WITH THIS RUN!")
