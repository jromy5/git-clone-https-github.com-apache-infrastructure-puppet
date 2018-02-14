#!/usr/bin/python

import os
import sys
import json
import subprocess
import git
import time
import datetime
import re
import requests

GITPATH = "/x1/repos/asf"
PODLINGS_URL = "https://whimsy.apache.org/public/public_podlings.json"
TLPS_URL = "https://whimsy.apache.org/public/committee-info.json"

#PODLINGS['podling'][project]['name']
#TLPS['committees'][project]['display_name']



def getActivity():
    
    # Get Whimsy data first
    PODLINGS = requests.get(PODLINGS_URL).json()
    TLPS = requests.get(TLPS_URL).json()
    
    repos = [x for x in os.listdir(GITPATH) if
                 os.path.isdir(os.path.join(GITPATH, x))
            ]
    
    projects = {}
    gitrepos = {}
    
    for repo in repos:
        
        repopath = os.path.join(GITPATH, repo)
        
        # Get repo description
        repodesc = "No Description"
        dpath = os.path.join(repopath, 'description')
        if os.path.exists(dpath):
            repodesc = open(dpath).read().strip()
            
        # Get git config items
        if False:
            configpath = os.path.join(repopath, "config")
            if os.path.exists(configpath):
                gconf = git.GitConfigParser(configpath, read_only = True)
            
        # Get latest commit timestamp, default to none
        lcommit = 0
        try:
            lcommit = int(subprocess.check_output(['/usr/bin/git', '-C', repopath, 'log', '-n', '1', '--pretty=format:%ct', '--all']))
        except:
            pass # if it failed (no commits etc), default to no commits
        
        now = time.time()
        ago = now - lcommit
        
        # Make 'N ago..' string
        agotxt = "No commits"
        if lcommit == 0:
            agotxt = "No commits"
        elif ago < 60:
            agotxt = "&lt;1 minute ago"
        elif ago < 120:
            agotxt = "&lt;2 minutes ago"
        elif ago < 300:
            agotxt = "&lt;5 minutes ago"
        elif ago < 900:
            agotxt = "&lt;15 minutes ago"
        elif ago < 1800:
            agotxt = "&lt;30 minutes ago"
        elif ago < 3600:
            agotxt = "&lt;1 hour ago"
        elif ago < 7200:
            agotxt = "&lt; 2 hours ago"
        elif ago < 14400:
            agotxt = "&lt; 4 hours ago"
        elif ago < 43200:
            agotxt = "&lt; 12 hours ago"
        elif ago < 86400:
            agotxt = "&lt; 1 day ago"
        elif ago < 172800:
            agotxt = "&lt; 2 days ago"
        elif ago <= (31 * 86400):
            agotxt = "%u days ago" % round(ago/86400)
        else:
            agotxt = "%u weeks ago" % round(ago/(86400*7))
        
        if lcommit == 0:
            agotxt = "<span style='color: #777; font-style: italic;'>%s</span>" % agotxt
        elif ago <= 172800:
            agotxt = "<span style='color: #070;'>%s</span>" % agotxt
            
        # Store in project hash
        r = re.match(r"^(?:incubator-)?([^-.]+).*", repo)
        project = r.group(1)
        projects[project] = projects.get(project, [])
        repo = repo.replace(".git", "") # Crop this for sorting reasons (INFRA-15952)
        projects[project].append(repo)
        if len(repodesc) > 64:
            repodesc = repodesc[:61] + "..."
        gitrepos[repo] = [agotxt, repodesc]
    
    html = ""
    a = 0
    for project in sorted(projects):
        a %= 3
        a += 1
        pname = project[0].upper() + project[1:]
        if project in PODLINGS['podling']:
            pname = "Apache " + PODLINGS['podling'][project]['name'] + " (Incubating)"
        if project in TLPS['committees']:
            pname = "Apache " + TLPS['committees'][project]['display_name']
        
        table = """
<table class="tbl%u">
<thead>
    <tr>
        <td colspan="4">%s</td>
    </tr>
</thead>
<tbody>
    <tr>
        <th>Repository name:</th>
        <th>Description:</th>
        <th>Last changed:</th>
        <th>Links:</th>
    </tr>
""" % (a, pname)
        for repo in sorted(projects[project]):
            table += """
    <tr>
        <td><a href="/repos/asf/?p=%s.git">%s.git</a></td>
        <td>%s</td>
        <td>%s</td>
        <td>
            <a href="/repos/asf/?p=%s.git;a=summary">Summary</a> |
            <a href="/repos/asf/?p=%s.git;a=shortlog">Short Log</a> |
            <a href="/repos/asf/?p=%s.git;a=log">Full Log</a> |
            <a href="/repos/asf/?p=%s.git;a=tree">Tree View</a>
        </td>
    </tr>
""" % (repo, repo, gitrepos[repo][1],gitrepos[repo][0], repo, repo, repo, repo)
    
        table += "</table>"
        html += table
    return html


html = """
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<link rel="stylesheet" href="/css/gitbox.css">
<title>Apache GitBox Repositories</title>
</head>

<body>
<img src="/images/gitbox-logo.png" style="margin-left: 125px; width: 750px;"/><br/>
"""

repohtml = getActivity()

html += repohtml
html += """
</body>
</html>
"""
print(html)