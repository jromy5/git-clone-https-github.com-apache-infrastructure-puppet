#!/usr/local/bin/python

import json
import sys
import time
import requests

import asfgit.cfg as cfg
import asfgit.git as git
import asfgit.log as log


def main():
    for ref in git.stream_refs(sys.stdin):
        if ref.is_tag():
            rname = ref.name if hasattr(ref, 'name') else "unknown"
            send_json({
                "repository": "git",
                "server": "gitbox",
                "project": cfg.repo_name,
                "ref": rname,
                "hash": "null",
                "sha": "null",
                "date": time.strftime("%Y-%m-%d %H:%M:%S", time.gmtime()),
                "authored": time.strftime("%Y-%m-%d %H:%M:%S", time.gmtime()),
                "author": commiter,
                "email": remote_user,
                "committer": committer,
                "commited": time.strftime("%Y-%m-%d %H:%M:%S", time.gmtime()),
                "ref_names": "",
                "subject": rname,
                "log": "Create %s" % rname,
                "body": "",
                "files": []
            })
            continue
        if ref.deleted():
            continue
        for commit in ref.commits(num=10, reverse=True):
            send_json({
                "repository": "git",
                "server": "gitbox",
                "project": cfg.repo_name,
                "ref": commit.ref.name,
                "hash": commit.commit,
                "sha": commit.sha,
                "date": commit.authored,
                "authored": commit.authored,
                "author": commit.author_name,
                "email": commit.author_email,
                "committer": commit.committer,
                "commited": commit.committed,
                "ref_names": commit.ref_names,
                "subject": commit.subject,
                "log": commit.subject,
                "body": commit.body,
                "files": commit.files()
            })


def send_json(data):
    try:
        requests.post("http://%s:%u%s" %
                      (cfg.gitpubsub_host, cfg.gitpubsub_port, cfg.gitpubsub_path),
                      data = json.dumps({"commit": data}))
    except:
        log.exception()

