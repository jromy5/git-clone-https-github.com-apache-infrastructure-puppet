#!/usr/local/bin/python

import json
import socket
import sys

import asfgit.cfg as cfg
import asfgit.git as git
import asfgit.log as log
import asfgit.util as util
import subprocess, os, time

def main():
    ghurl = "git@github:apache/%s.git" % cfg.repo_name
    os.chdir("/x1/repos/asf/%s.git" % cfg.repo_name)
    try:
       for ref in git.stream_refs(sys.stdin):
          print("Syncing %s..." % ref.name)
          subprocess.check_call(["git", "push", ghurl, "%s:%s" % (ref.newsha, ref.name)])
    except subprocess.CalledProcessError as err:
        util.abort("Could not sync with GitHub: %s" % err.output)

