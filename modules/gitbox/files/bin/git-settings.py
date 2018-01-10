#!/usr/bin/env python3
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


# IMPORT OR EXPORT GIT SETTINGS TO/FROM JSON
# USAGE EXAMPLES:
#
# Export cordova settings from git-wip:
#     python3 git-settings.py --dir /x1/git/repos/asf --export settings.json --glob "cordova*"
#
# Import cordova settings on gitbox:
#     python3 git-settings.py --dir /x1/repos/asf --import /root/settings.json --glob "cordova*"

import os
import sys
import argparse
import fnmatch
import json
import subprocess

parser = argparse.ArgumentParser()
parser.add_argument("--dir", type = str, help = "The location of git dirs to apply settings to", required = True)
parser.add_argument("--glob", type = str, help = "Restrict settings to these git repositories")
parser.add_argument("--export", dest = "save", metavar = "$jsonfile", type = str, help = "Export settings to a JSON file")
parser.add_argument("--import", dest = "load", metavar = "$jsonfile", type = str, help = "Import settings from a JSON file")
args = parser.parse_args()

cdir = os.getcwd()

gitdir = args.dir

if not os.path.isdir(gitdir):
    print("Please specify an existing parent git dir with --dir")
    sys.exit(-1)

if not args.load and not args.save:
    print("You need to specify an action (import or export)")
    sys.exit(-1)

allrepos = filter(lambda repo: os.path.isdir(os.path.join(gitdir, repo)), os.listdir(gitdir))

GIT_SETTINGS = {}

if args.load:
    GIT_SETTINGS = json.load(open(args.load))

for repo in allrepos:
    if not args.glob or fnmatch.fnmatch(repo, args.glob):
        # If exporting settings, grab them from the repo
        os.chdir(os.path.join(gitdir, repo))
        if args.save:
            print("Exporting settings from %s into JSON" % repo)
            GIT_SETTINGS[repo] = {}
            txt = subprocess.check_output(['/usr/bin/git', 'config', '-l']).decode('ascii')
            lines = txt.split("\n")
            for line in lines:
                if '=' in line:
                    key, value = line.rsplit(sep="=",maxsplit=1)
                    # We are only interested in hooks.asfgit.* and apache.* settings here.
                    if 'hooks.asfgit' in key or 'apache' in key:
                        GIT_SETTINGS[repo][key] = value
            print("Found %s settings to export from %s" % (len(GIT_SETTINGS[repo].keys()), repo))
            
        # Otherwise, if we're importing settings, set them if we got 'em
        elif args.load and repo in GIT_SETTINGS:
            print("Importing settings from JSON into %s" % repo)
            for key, value in GIT_SETTINGS[repo].items():
                print("Setting %s = %s" % (key, value))
                subprocess.check_call(['/usr/bin/git', 'config', key, value])
                

if args.save:
    print("Saving exported settings to %s" % args.save)
    os.chdir(cdir)
    json.dump(GIT_SETTINGS, open(args.save, "w"), indent = 4)
    