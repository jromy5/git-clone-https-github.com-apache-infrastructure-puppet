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
        rname = ref.name if hasattr(ref, 'name') else "unknown"
        send_json({
            "repository": "git",
            "server": "gitbox",
            "project": cfg.repo_name,
            "ref": rname,
            "type": "tag" if ref.is_tag() else "branch",
            "from": ref.oldsha if not ref.created() else None,
            "to": ref.newsha if not ref.deleted() else None,
            "action": "created" if ref.created() else "deleted" if ref.deleted() else "updated",
            "actor": cfg.committer,
            "date": time.strftime("%Y-%m-%d %H:%M:%S", time.gmtime()),
        }, "push")    
        if ref.is_tag():
            send_json({
                "repository": "git",
                "server": "gitbox",
                "project": cfg.repo_name,
                "ref": rname,
                "hash": "null",
                "sha": "null",
                "date": time.strftime("%Y-%m-%d %H:%M:%S", time.gmtime()),
                "authored": time.strftime("%Y-%m-%d %H:%M:%S", time.gmtime()),
                "author": cfg.committer,
                "email": cfg.remote_user,
                "committer": cfg.committer,
                "commited": time.strftime("%Y-%m-%d %H:%M:%S", time.gmtime()),
                "ref_names": "",
                "subject": rname,
                "log": "Create %s" % rname,
                "body": "",
                "files": []
            })
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


def send_json(data, key = "commit"):
    try:
        requests.post("http://%s:%s%s" %
                      (cfg.gitpubsub_host, cfg.gitpubsub_port, cfg.gitpubsub_path),
                      data = json.dumps({key: data}))
    except:
        log.exception()
