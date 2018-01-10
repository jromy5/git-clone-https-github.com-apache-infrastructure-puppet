#!/usr/bin/env python
"""
Script for scanning for active or inactive users and either listing them
or removing them (the inactive ones!) from the wiki installation.
See wiki-users.py --help for help.
"""

import os, sys, re, time
from os import listdir
from os.path import isfile, join, isdir
import argparse

# Shortcuts for getting files/dirs
def files(mypath):
    return [f for f in listdir(mypath) if isfile(join(mypath, f))]
def dirs(mypath):
    return [f for f in listdir(mypath) if isdir(join(mypath, f))]

# active and all users, for later use
active_users = {}
all_users = {}


# args
parser = argparse.ArgumentParser()
parser.add_argument("--data", type= str, help = "Base moin wiki data directory")
parser.add_argument("--years", type= int, help = "Sets to cut-off date for activity to N years (default is 5)")
parser.add_argument("--globaldir", type= str, help = "Optional additional global data dir (for compiling inactive users)")
parser.add_argument("--lactive", action = 'store_true', help = "Lists the active users")
parser.add_argument("--linactive", action = 'store_true', help = "Lists the inactive users")
parser.add_argument("--delete", action = 'store_true', help = "Removes inactive users")
parser.add_argument("--test", action = 'store_true', help = "Just test, don't delete anything")
parser.add_argument("--names", action = 'store_true', help = "Print users' names instead of UIDs")
parser.add_argument("--gonly", action = 'store_true', help = "Only act on global users")
parser.add_argument("--backup", action = 'store_true', help = "Keep a backup of the files instead of deleting them")
parser.add_argument("--filter", type= str, help = "Only scan wikis matching this filter")
args = parser.parse_args()


# Default cutoff for inactivity to 5 year, unless otherwise specified
now = time.time() * 1000000
cutoff = now - (86400*365*5*1000000)

# --years?
if args.years:
    years = args.years
    cutoff = now - (86400*365*years*1000000)

# -- path to wiki data
if args.data:
    wikis = dirs(args.data)
else:
    # I like printing this instead of the argparse bork
    print("Please specify the data dir (/wwww/wiki/data or some such)!")
    sys.exit(-1)
    
# Print and sleep for 4 secs, so people can read this
print("Cut-off date set to: %s" % time.strftime("%m/%d/%Y %H:%M:%S", time.localtime(cutoff/1000000)))
time.sleep(4)

# For each wiki, ...
for wiki in wikis:
    if args.filter and wiki.find(args.filter) == -1:
        continue
    print("Analyzing %s..." % wiki)
    
    # Only perform analysis is the edit log exists, otherwise no point
    if os.path.exists("%s/%s/data/edit-log" % (args.data, wiki)):
        # If wiki-specific userbase, get 'em all for later
        if os.path.isdir("%s/%s/data/user/" % (args.data, wiki)):
            au = files("%s/%s/data/user/" % (args.data, wiki))
            for u in au:
                if u != "name2id" and u != "README":
                    all_users[u] = "%s/%s/data/user/%s" % (args.data, wiki, u)
        # Open edit-log, parse it for all activity
        # Save those that have edited after cutoff date in a list
        with open("%s/%s/data/edit-log" % (args.data, wiki), "r") as f:
            for line in f:
                # timestamp gunk gunk gunk gunk gunk user-id
                match = re.match(r"(\d+)\s+\d+\s+\S+\s+\S+\s+\S+\s+\S+\s+([0-9.]+)", line)
                if match:
                    ts = int(match.group(1))
                    uid = match.group(2)
                    if ts > cutoff:
                        # If not already deemed active, add
                        if not uid in active_users:
                            upath = "%s/%s/data/user/%s" % (args.data, wiki, uid)
                            if args.globaldir and os.path.exists("%s/user/%s" % (args.globaldir, uid)):
                                upath = "%s/user/%s" % (args.globaldir, uid)
                            active_users[uid] = upath
                    
            f.close()
    else:
        print("No edit log found for %s!" % wiki)
print("Found %u active users" % len(active_users))

# Add all global users, regardless - same as with the specific wikis
if args.globaldir:
    for u in files(args.globaldir):
        if u != "name2id":
            all_users[u] = "%s/%s" % (args.globaldir, u)
    if os.path.exists("%s/edit-log" % (args.globaldir)):
        if os.path.isdir("%s/user/" % (args.globaldir)):
            au = files("%s/user/" % (args.globaldir))
            for u in au:
                if u != "name2id" and u != "README":
                    all_users[u] = "%s/user/%s" % (args.globaldir, u)
        with open("%s/edit-log" % (args.globaldir), "r") as f:
            for line in f:
                # timestamp gunk gunk gunk gunk gunk user-id
                match = re.match(r"(\d+)\s+\d+\s+\S+\s+\S+\s+\S+\s+\S+\s+([0-9.]+)", line)
                if match:
                    ts = int(match.group(1))
                    uid = match.group(2)
                    if ts > cutoff:
                        if not uid in active_users:
                            upath = "%s/user/%s" % (args.globaldir, uid)
                            if args.globaldir and os.path.exists("%s/user/%s" % (args.globaldir, uid)):
                                upath = "%s/user/%s" % (args.globaldir, uid)
                            active_users[uid] = upath
                    
            f.close()

# Print active users?
if args.lactive:
    print("Active users:")
    if args.names:
        for uid in active_users:
            fpath = active_users[uid]
            if (not args.gonly) or (args.globaldir and fpath.find(args.globaldir) != -1):
                with open(fpath, "r") as f:
                    d = f.read()
                    f.close()
                    m = re.search(r"\nname=([^\r\n]+)", d)
                    if m:
                        print(m.group(1))
                    else:
                        print(uid)
    else:
        for uid in active_users:
            print(uid)
# Or print the inactive?
elif args.linactive:
    print("Inactive users:")
    for user in all_users:
        if not user in active_users:
            if os.path.exists("%s/user/%s" % (args.globaldir, user)):
                if (not args.gonly) or (args.globaldir and all_users[user].find(args.globaldir) != -1):
                    print("%s (global)" % user)
            elif not args.gonly:
                print("%s (local)" % user)
# rm the inactive?
if args.delete:
    inactive_users = {}
    ia = 0
    for user in all_users:
        if not user in active_users:
            if (not args.gonly) or (args.globaldir and all_users[user].find(args.globaldir) != -1):
                inactive_users[user] = all_users[user]
                ia += 1
    print("Removing %u users from the system..." % ia)
    time.sleep(2)
    rm = 0
    for user in inactive_users:
        rm += 1
        if not args.test:
            fpath = inactive_users[user]
            if (not args.gonly) or (args.globaldir and fpath.find(args.globaldir) != -1):
                if os.path.isfile(fpath):
                    if args.backup:
                        os.rename(fpath, fpath + ".deleted")
                    else:
                        os.unlink(fpath)
            if(rm % 10000 == 0):
                print("Removed %u users so far..." % rm)
