import datetime
import os
import sys
import sqlite3

import asfgit.auth as auth
import asfgit.cfg as cfg
import asfgit.git as git
import asfgit.util as util


WRITE_LOCKED = u"""\
Write access is currently disabled. The ASF Git
repositories are currently undergoing maintenance.
"""

NOT_AUTHORIZED = u"""\
You are not authorized to edit this repository.
"""

NO_REWRITES = u"""\
Rewinding %s is forbidden.
"""

NO_MERGES = u"""\
Merges are not allowed on %s.
"""

SYNC_BROKEN = u"""\
This repository has been locked due to synchronization issues:
 - %s exists due to a previous error, and prevents pushes.
This could either be a benign issue, or the repositories could be out of sync.
Please contact users@infra.apache.org to have infrastructure resolve the issue.
"""

MERGEBOT_APPROVED_IPS = [
    "62.210.60.243",  # mergebot-vm2
]

def main():

    # Check if commits are enabled.
    for lockname in cfg.write_locks:
        if os.path.exists(lockname):
            util.abort(WRITE_LOCKED)

    # Check if the repo is out of sync
    lockfile = "/x1/gitbox/broken/%s.txt" % cfg.repo_name
    if os.path.exists(lockfile):
        util.abort(SYNC_BROKEN % lockfile)

    # Check committer's authorization for this
    # repository.
    authorized_committers = auth.authorized_committers(cfg.repo_name)
    authorized_committers.add('git-site-role')
    authorized_committers.add('mergebot-role')
    authorized_committers.add('buildbot')
    if cfg.committer not in authorized_committers:
        util.abort(NOT_AUTHORIZED)

    # Mergebot can only commit from a.b.c.d
    # IP addresses are listed in the constant above.
    if cfg.committer == "mergebot-role" and cfg.ip not in MERGEBOT_APPROVED_IPS:
        util.abort(u"mergebot only works from the mergebot VM, tut tut!")
    
    # buildbot only possible from bb-slave1
    # 209.188.14.160 is bb-slave1.a.o
    if cfg.committer == "buildbot" and (cfg.ip != "209.188.14.160"):
        util.abort(u"Buildbot role account only accessible via bb-slave1")

    # Check individual refs and commits for all of
    # our various conditions. Track each ref update
    # so that we can log them if everything is ok.
    refs = []
    for ref in git.stream_refs(sys.stdin):
        refs.append(ref)
        # Site writer role
        if ref.name.find("asf-site") == -1 and cfg.committer == "git-site-role":
            util.abort(u"git-site-role can only write to asf-site branches!")
        if ref.is_protected(cfg.protect) and ref.is_rewrite():
            util.abort(NO_REWRITES % ref.name)
        if ref.is_tag():
            continue
        for commit in ref.commits():
            if cfg.no_merges and commit.is_merge() \
                    and ref.is_protected(cfg.protect):
                util.abort(NO_MERGES % ref.name)

    # Log pushlogs to sqlite3
    conn = sqlite3.connect('/x1/gitbox/db/gitbox.db')
    cursor = conn.cursor()
    for ref in refs:
        cursor.execute("""INSERT INTO pushlog
                  (repository, asfid, githubid, baseref, ref, old, new, date)
                  VALUES (?,?,?,?,?,?,?,DATETIME('now'))""", (cfg.repo_name, cfg.committer, 'asfgit', ref.name, ref.name, ref.oldsha, ref.newsha, ))
    
    # Save and close up shop
    conn.commit()
    conn.close()
