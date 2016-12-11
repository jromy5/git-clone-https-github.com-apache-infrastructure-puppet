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

import os, sys, re, ldap, urllib2, json, requests, hashlib, ConfigParser
from requests.auth import HTTPBasicAuth

# Run `python grouper.py debug` to check teams but not add/remove users
DEBUG_RUN = True if len(sys.argv) > 1 and sys.argv[1] == 'debug' else False
if DEBUG_RUN:
    print("Debug run active! Not modifying teams")
CONFIG = ConfigParser.ConfigParser()
CONFIG.read("grouper.cfg") # Yeah, you're not getting this info...

LDAP_URI = "ldaps://ldap-lb-us.apache.org:636"
LDAP_USER = CONFIG.get('ldap', 'user')
LDAP_PASSWORD = CONFIG.get('ldap', 'password')

MATT_PROJECTS = {}
ORG_READ_TOKEN = CONFIG.get('github', 'token')

MFA = json.load(open("../mfa.json"))


def getGitHubTeams():
    """Fetches a list of all GitHub committer teams (projects only, not the parent org team or the admin teams)"""
    print("Fetching GitHub teams...")
    teams = {}
    for n in range(1,100):
        url = "https://api.github.com/orgs/apache/teams?access_token=%s&page=%u" % (ORG_READ_TOKEN, n)
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
                    print("found team: %s-committers" % project)
    return teams


def getGitHubRepos():
    """ Fetches all GitHub repos we own """
    print("Fetching list of GitHub repos, hang on (this may take a while!)..")
    repos = []
    for n in range(1, 100): # 100 would be 3000 repos, we have 750ish now...
        url = "https://api.github.com/orgs/apache/repos?access_token=%s&page=%u" % (ORG_READ_TOKEN, n)
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
        print("Bad Team ID passed!!")
        return None
    for n in range(1, 100): # 100 would be 3000 repos, we have 750ish now...
        url = "https://api.github.com/teams/%s/members?access_token=%s&page=%u" % (teamID, ORG_READ_TOKEN, n)
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
        print("Bad Team ID passed!!")
        return None
    for n in range(1, 10):
        url = "https://api.github.com/teams/%s/repos?access_token=%s&page=%u" % (teamID, ORG_READ_TOKEN, n)
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
    print("- Trying to create %s as a GitHub team..." % project)
    # Make sure we only allow the ones with permission to use MATT
    if not project in MATT_PROJECTS:
        print(" - This project has not been cleared for MATT yet. Aborting team creation")
        return False

    url = "https://api.github.com/orgs/apache/teams?access_token=%s" % ORG_READ_TOKEN
    data = json.dumps({'name': "%s committers" % project})
    r = requests.post(url, data=data, allow_redirects=True)
    data = json.loads(r.content)
    if data and 'id' in data:
        print("New GitHub team created as #%s" % str(data['id']))
        return data['id']
    else:
        print("Unknown return code, dunno if the team was created or not...?")
        print(data)
        return None

def removeGitHubTeamMember(teamID, login):
    """ Remove a team member from a team """
    if str(int(teamID)) != str(teamID):
        print("Bad Team ID passed!!")
        return None
    if login.lower() == 'humbedooh':
        print("Not removing Mr. Humbedooh just yet")
        return
    print("- Removing %s from team #%s..." % (login, str(teamID)))
    url = "https://api.github.com/teams/%s/memberships/%s" % (teamID, login)
    r = requests.delete(url, headers = {'Authorization': "token %s" % ORG_READ_TOKEN})

    if r.status_code <= 204:
        print("- Removal done!")
    else:
        print("- Error occured while trying to remove member!")
        print(r.status_code)

def addGitHubTeamMember(teamID, login):
    """ Add a member to a team """
    if str(int(teamID)) != str(teamID):
        print("Bad Team ID passed!!")
        return None
    print("- Adding %s to team #%s..." % (login, str(teamID)))
    url = "https://api.github.com/teams/%s/memberships/%s" % (teamID, login)
    r = requests.put(url, headers = {'Authorization': "token %s" % ORG_READ_TOKEN})
    data = json.loads(r.content)
    if 'state' in data:
        print("- Additions done!")
    else:
        print("- Error occured while trying to add member!")
        print(data)


def addGitHubTeamRepo(teamID, repo):
    """ Add a repo to a team """
    if str(int(teamID)) != str(teamID):
        print("Bad Team ID passed!!")
        return None
    print("- Adding repo %s to team #%s..." % (repo, str(teamID)))
    url = "https://api.github.com/teams/%s/repos/apache/%s" % (teamID, repo)
    r = requests.put(url, data = "{\"permission\": \"push\"}", headers = {'Authorization': "token %s" % ORG_READ_TOKEN})
    if r.status_code <= 204:
        print("- Team succesfully subscribed to repo!")
    else:
        print("- Error occured while trying to add repo!")
        print(r.content)



def getCommitters(group):
    """ Gets the list of availids in a project committer group """
    # First, check if there's a hardcoded member list for this group
    # If so, read it and return that instead of trying LDAP
    if CONFIG.has_section('group:%s' % group) and CONFIG.has_option('group:%s' % group, 'members'):
        print("Found hardcoded member list for %s!" % group)
        return CONFIG.get('group:%s' % group, 'members').split(' ')
    
    print("Fetching LDAP committer list for %s" % group)
    committers = []
    # This might fail in case of ldap bork, if so we'll return nothing.
    try:
        ldapClient = ldap.initialize(LDAP_URI)
        ldapClient.set_option(ldap.OPT_REFERRALS, 0)

        ldapClient.bind(LDAP_USER, LDAP_PASSWORD)

        results = ldapClient.search_s("cn=%s,ou=groups,dc=apache,dc=org" % group, ldap.SCOPE_BASE)

        for result in results:
            result_dn = result[0]
            result_attrs = result[1]

            if "memberUid" in result_attrs:
                for member in result_attrs["memberUid"]:
                    committers.append(member)

        ldapClient.unbind_s()
        committers = sorted(committers) #alphasort
    except Exception as err:
        print("Could not fetch LDAP data: %s" % err)
        committers = None
    return committers


def getPMC(group):
    """ Gets the list of availids in a project PMC group """
    print("Fetching LDAP PMC list for %s" % group)
    pmcmembers = []
    # This might fail in case of ldap bork, if so we'll return nothing.
    try:
        ldapClient = ldap.initialize(LDAP_URI)
        ldapClient.set_option(ldap.OPT_REFERRALS, 0)

        ldapClient.bind(LDAP_USER, LDAP_PASSWORD)

        results = ldapClient.search_s("cn=%s,ou=pmc,ou=committees,ou=groups,dc=apache,dc=org" % group, ldap.SCOPE_BASE)

        for result in results:
            result_dn = result[0]
            result_attrs = result[1]

            if "member" in result_attrs:
                for member in result_attrs["member"]:
                    m = re.match(r"uid=([^,]+)", member) # results are in the form uid=janedoe,dc=... so weed out the uid
                    if m:
                        pmcmembers.append(m.group(1))

        ldapClient.unbind_s()
        pmcmembers = sorted(pmcmembers) #alphasort
    except Exception as err:
        print("Could not fetch LDAP data: %s" % err)
        pmcmembers = None
    return pmcmembers



####################
# MAIN STARTS HERE #
####################


# Get a list of all asf/github IDs
conn = sqlite3.connect('/x1/gitbox/db/gitbox.db')
cursor = conn.cursor()

cursor.execute("SELECT asfid,githubid,mfa FROM ids")
accounts = cursor.fetchall()

conn.close()

# get a list of all repos that are active on gitbox
gitdir = '/x1/repos/asf'
allrepos = filter(lambda repo: os.path.isdir(os.path.join(gitdir, repo)), os.listdir(dir))

# turn that into a list of projects to run the manager for
for repo in allrepos:
    m = re.match(r"(?incubator-)([^-]+)", repo)
    if m: #don't see why this would fail, but best to be sure
        project = m.group(1)
        if not project in MATT_PROJECTS and project != "infrastructure":
            MATT_PROJECTS[project] = "tlp" if not re.match(r"incubator-", repo) else "podling" # distinguish between tlp and podling

# Then, start off by getting all existing GitHub teams and repos - we'll need that later.
existingTeams = getGitHubTeams()
existingRepos = getGitHubRepos()

# pre-fetch IPMC list for podling extensions
ipmc = getPMC("incubator")

# Process each project in the MATT test
for project in MATT_PROJECTS:
    print("Processing GitHub team for " + project)

    # Does the team exist?
    teamID = None
    for team in existingTeams:
        if existingTeams[team] == project:
            teamID = team
            print("- Team exists on GitHub")
            break
    # If not found, create it (or try to, stuff may break)
    if not teamID:
        print("- Team does not yet exist on GitHub, creating...")
        teamID = createGitHubTeam(project)
        if not teamID:
            print("Something went very wrong here, aborting!")
            break

    # Make sure all $tlp-* repos are writeable by this team
    teamRepos = getGitHubTeamRepos(teamID)
    print ("Team is subbed to the following repos: " + ", ".join(teamRepos))
    for repo in existingRepos:
        m = re.match(r"^(?incubator-)?([^-]+)-?", repo)
        p = m.group(1)
        if p == project and not repo in teamRepos and os.path.exists("/x1/repos/asf/%s.git" % repo):
            print("Need to add " + repo + " repo to the team...")
            addGitHubTeamRepo(teamID, repo)

    # Now get the current list of members on GitHub
    members = getGitHubTeamMembers(teamID)
    if teamID in existingTeams:
        print(existingTeams[teamID] + ": " + ", ".join(members))

    # Now get the committer availids from LDAP
    ldap_team = getCommitters(project)
    if not ldap_team or len(ldap_team) == 0:
        print("LDAP Borked (no group data returned)? Trying next project instead")
        continue
    # If a podling, extend the committer list with the IPMC membership (mentors etc)
    if MATT_PROJECTS[project] == "podling":
        ldap_team.extend(ipmc)

    # For each committer, IF THEY HAVE MFA, add them to a 'this is what it should look like' list
    hopefulTeam = []
    for committer in ldap_team:
        githubID = None
        for account in accounts:
            # Check that we found a match WITH 2FA enabled (bool, so 1 means true)
            if account[0].lower() == committer and account[2] == 1:
                githubID = account[1]
        # Make sure we found the user and the latest MFA scan shows MFA enabled
        if githubID and githubID in MFA['enabled'].keys():
            hopefulTeam.append(githubID)
        # If MFA was disabled again, we can't have 'em here.
        elif githubID and githubID in MFA['disabled'].keys():
            print(githubID + " does not have MFA enabled, can't add to team")
        else:
            print(committer + " does not have a working MATT account yet, ignoring")

    # If no team, assume something broke for now
    if len(hopefulTeam) == 0:
        print("No hopeful GitHub team could be constructed, assuming something's wrong and cycling to next project")
        continue

    # Now, for each member in the team, find those that don't belong here.
    for member in members:
        if not member in hopefulTeam:
            print(member + " should not be a part of this team, removing...")
            if not DEBUG_RUN:
                removeGitHubTeamMember(teamID, member)

    # Lastly, add those that should be here but aren't
    for member in hopefulTeam:
        if not member in members:
            print(member + " not found in GitHub team, adding...")
            if not DEBUG_RUN:
                addGitHubTeamMember(teamID, member)

    print("Done with " + project + ", moving to next project...")

print("ALL DONE!")
