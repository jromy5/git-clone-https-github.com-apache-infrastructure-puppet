#!/usr/local/bin/python

import json
import socket
import sys

import asfgit.cfg as cfg
import asfgit.git as git
import asfgit.log as log
import subprocess, os, time

def main():
    ghurl = "git@github:apache/%s.git" % cfg.repo_name
    os.chdir("/x1/git/repos/asf/%s.git" % cfg.repo_name)
    try:
       subprocess.check_call(["git", "push", "--all", ghurl])
       try:
           os.unlink("/x1/git/git-dual/broken/%s.txt" % cfg.repo_name)
       except:
           pass
    except Exception as err:
       with open("/x1/git/git-dual/broken/%s.txt" % cfg.repo_name, "w") as f:
           f.write("BROKEN AT %s\n" % time.strftime("%c"))
           f.close()
       log.exception(err)

