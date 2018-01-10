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

import os
import sys
import re
import ldap
import urllib2
import json
import requests
import hashlib
import ConfigParser
import sqlite3
import logging

CONFIG = ConfigParser.ConfigParser()
CONFIG.read("grouper.cfg") # Yeah, you're not getting this info...
ORG_READ_TOKEN = CONFIG.get('github', 'token')

def getGitHubRepos():
    """ Fetches all GitHub repos we own """
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

def getClones(repo):
    """ Fetches all clone stats """
    repos = []
    url = "https://api.github.com/repos/apache/%s/traffic/clones?per=day&access_token=%s" % (repo, ORG_READ_TOKEN)
    response = urllib2.urlopen(url)
    data = json.load(response)
    return data

def getViews(repo):
    """ Fetches all view stats """
    repos = []
    url = "https://api.github.com/repos/apache/%s/traffic/views?per=day&access_token=%s" % (repo, ORG_READ_TOKEN)
    response = urllib2.urlopen(url)
    data = json.load(response)
    return data


for repo in getGitHubRepos():
    print("Fetching data for %s" % repo)
    js = {}
    js['clones'] = getClones(repo)
    js['views'] = getViews(repo)
    with open("/x1/gitbox/htdocs/stats/%s.json" % repo, "w") as f:
        json.dump(js, f, indent = 4)
        f.close()
        
print("All done!")
