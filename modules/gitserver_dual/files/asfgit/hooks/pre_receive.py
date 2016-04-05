import datetime
import os
import sys


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

def main():
    # Check if commits are enabled.
    for lockname in cfg.write_locks:
        if os.path.exists(lockname):
            util.abort(WRITE_LOCKED)

    # Check committer's authorization for this
    # repository.
    authorized_committers = auth.authorized_committers(cfg.repo_name)
    if cfg.committer not in authorized_committers:
        util.abort(NOT_AUTHORIZED)

    # Check individual refs and commits for all of
    # our various conditions. Track each ref update
    # so that we can log them if everything is ok.
    refs = []
    for ref in git.stream_refs(sys.stdin):
        refs.append(ref)
        if ref.is_protected(cfg.protect) and ref.is_rewrite():
            util.abort(NO_REWRITES % ref.name)
        if ref.is_tag():
            continue
        for commit in ref.commits():
            if cfg.no_merges and commit.is_merge() \
                    and ref.is_protected(cfg.protect):
                util.abort(NO_MERGES % ref.name)

    # Everything is kosher. Log each ref update and exit
    log_fname = os.path.join(cfg.repo_dir, "ref-updates.log")
    with open(log_fname, 'a') as log:
        for ref in refs:
            stamp = datetime.datetime.now().ctime()
            oldsha = ref.oldsha[:10]
            newsha = ref.newsha[:10]
            mesgfmt = u"[%s] %s %s -> %s %s\n"
            mesg = mesgfmt % (stamp, ref.name, oldsha, newsha, cfg.remote_user)
            log.write(util.encode(mesg))
