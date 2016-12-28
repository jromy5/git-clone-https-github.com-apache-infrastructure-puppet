#!/usr/bin/env python

import os
import sys
import smtplib
import email.mime.text

import asfgit.cfg as cfg
import asfgit.git as git

TMPL_REWRITE = """
Committer %(committer)s has made a rewind of %(refname)s in
repository %(reponame)s on GitBox. This is strictly forbidden
on this branch/tag, hence this notification.

With regards,
GitBox.
"""

TMPL_MERGE = """
Committer %(committer)s has made a merge of %(refname)s in
repository %(reponame)s on GitBox. This is strictly forbidden
on this branch/tag, hence this notification.

With regards,
GitBox.
"""

def notify(msg, subject):
    msg = email.mime.text.MIMEText(msg, _charset = "utf-8")
    msg['Subject'] = subject
    msg['To'] = "<private@infra.apache.org>"
    msg['From'] = "<gitbox@gitbox.apache.org>"
    s = smtplib.SMTP('localhost')
    s.sendmail(msg['From'], msg['To'], msg.as_string())
    

def main():
    # Check individual refs and commits for all of
    # our various conditions. Track each ref update
    # so that we can log them if everything is ok.
    for ref in git.stream_refs(sys.stdin):
        if ref.is_protected(cfg.protect) and ref.is_rewrite():
            refname = ref.name
            reponame = cfg.repo_name
            committer = cfg.committer
            notify(TMPL_REWRITE % locals(), "GitBox: Rewinding attempted on %s in %s" % (ref.name, cfg.repo_name))
        if ref.is_tag():
            continue
        for commit in ref.commits():
            if cfg.no_merges and commit.is_merge() \
                    and ref.is_protected(cfg.protect):
                refname = ref.name
                reponame = cfg.repo_name
                committer = cfg.committer
                notify(TMPL_MERGE % locals(), "GitBox: Merge attempted on %s in %s" % (ref.name, cfg.repo_name))

if __name__ == '__main__':
    main()
