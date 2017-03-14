#!/usr/bin/env python
# This script checks pushes for rewinding of refs or merging inside
# protected branches, and notifies infra if it happens.

import os
import sys
import smtplib
import email.mime.text
sys.path.append(os.environ["ASFGIT_ADMIN"])
import asfgit.cfg as cfg
import asfgit.git as git

TMPL_REWRITE = """
Committer %(committer)s has made a %(what)s of %(refname)s in
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
    # Set some vars for use in templating later
    tmplvars = {
        'committer': cfg.committer,
        'reponame': cfg.repo_name,
        'refname': "??",
        'what': 'rewind'
    }
    
    # Check individual refs and commits for all of
    # our various conditions. Track each ref update
    # so that we can log them if everything is ok.
    for ref in git.stream_refs(sys.stdin):
        tmplvars['refname'] = ref.name
        # If protected ref and rewinding is attempted:
        if ref.is_protected(cfg.protect) and ref.is_rewrite():
            tmplvars['what'] = 'rewind'
            notify(TMPL_REWRITE % tmplvars, "GitBox: Rewind attempted on %s in %s" % (ref.name, cfg.repo_name))
        if ref.is_tag():
            continue
        for commit in ref.commits():
            # If protected ref and merge is attempted:
            if cfg.no_merges and commit.is_merge() \
                    and ref.is_protected(cfg.protect):
                tmplvars['what'] = 'merge'
                notify(TMPL_REWRITE % tmplvars, "GitBox: Merge attempted on %s in %s" % (ref.name, cfg.repo_name))

if __name__ == '__main__':
    main()
