#!/usr/bin/python3

import os
import sys
import json
import time
import re
import requests
import cgi

def listRepos():
    """ Return a list of all git-wip and gitbox repos """
    repos = {}
    
    # Get git-wip repos
    gitwip = requests.get('https://git-wip-us.apache.org/repos/asf?a=project_index').text
    for line in gitwip.split("\n"):
        if ' ' in line:
            repo, _ = line.split()
            repos[repo] = 'git-wip-us'
    
    # Get local gitbox repos
    for repo in os.listdir("/x1/repos/asf"):
        if '.git' in repo:
            repos[repo] = 'gitbox'
    
    return repos
    

# Fetch CGI payload
xform = cgi.FieldStorage();

reponame = xform.getvalue("repo")
if reponame:
    reponame = reponame.replace(".git", "")
    username = os.environ.get('REMOTE_USER', 'nobody')
    server = xform.getvalue("server", "git-wip-us")
    requests.post("http://gitpubsub.apache.org:2069/json/", json = {
            'commit': {
                "repository": "git",
                "server": server,
                "project": reponame,
                "ref": "asf-site",
                "hash": "000000",
                "sha": "0000000",
                "author": username,
                "email": "%s@apache.org" % username,
                "committer": "site-boop",
                "body": "Manual re-synchronization triggered for %s by %s" % (reponame, username),
                "log": "Manual re-synchronization triggered for %s by %s" % (reponame, username),
                "files": []
            }
    })
    print("Status: 201 Created\r\nContent-Type: text/plain\r\n\r\nWe've triggered a re-sync for %s!\r\n" % reponame)
else:
    try:
        mode = os.stat("/tmp/allrepos.json")
        assert(mode.st_mtime > (time.time() - 1800))
        repos = json.load(open("/tmp/allrepos.json"))
    except:
        repos = listRepos()
        json.dump(repos, open("/tmp/allrepos.json", "w"))
    
    print("Status: 200 Okay\r\nContent-Type: text/html\r\n\r\n")
    print("<style>body { font-family: Sans-Serif;}</style>")
    print("<h2>Re-sync a repository (for GitHub and Web Sites):</h2>")
    print("<p>This page allows you to trigger a re-sync of a repository that may have missed a synchronization cycle. Search for the repo you wish to re-sync, and click on the repo name to trigger a new cycle.</p>")
    print("Search for a repository to re-sync: <input type='text' placeholder='foo.git' onkeyup='filterRepos(this.value);'><br/>\r\n")
    print("<div id='list'></div><script>var repos = " + json.dumps(repos, indent = 2) + ";")
    print("""
          function filterRepos(wat) {
            arr = []
            for (var repo in repos) {
                if (repo.indexOf(wat) != -1) {
                    arr.push(repo);
                }
            }
            arr.sort();
            var l = document.createElement('ul');
            for (var i in arr) {
                var r = arr[i];
                li = document.createElement('li');
                a = document.createElement('a');
                a.setAttribute('href', "resync.cgi?repo="+r+"&server="+repos[r]);
                a.innerText = r;
                li.appendChild(a);
                li.appendChild(document.createTextNode(" (" + repos[r] + ")"))
                l.appendChild(li);
            }
            div = document.getElementById('list');
            div.innerHTML = "";
            div.appendChild(l);
          }
          </script>
          """)
