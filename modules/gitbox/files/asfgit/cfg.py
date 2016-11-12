import ConfigParser
import os
import subprocess as sp

import asfgit.run as run
import asfgit.util as util


NO_DEFAULT = object()
DEFAULT_SUBJECT = "%(repo)s git commit: %(subject)s"

DEFAULT_PUBSUB_HOST = "wilderness.apache.org"
DEFAULT_PUBSUB_PORT = "2069"
DEFAULT_PUBSUB_PATH = "/json"


def _repo_name():
    path = filter(None, os.environ["PATH_INFO"].split("/"))
    path = filter(lambda p: p != "git-receive-pack", path)
    if len(path) != 1:
        raise ValueError("Invalid PATH_INFO: %s" % os.environ["PATH_INFO"])
    path = path[0]
    if path[-4:] == ".git":
        return util.decode(path[:-4])
    return util.decode(path)


def _git_config(key, default=NO_DEFAULT):
    cmd = ["config", key]
    try:
        return run.git(*cmd)[1].strip()
    except sp.CalledProcessError:
        if default == NO_DEFAULT:
            raise
        return default


repo_name = _repo_name()
repo_dir = os.path.join(util.environ("GIT_PROJECT_ROOT"), u"%s.git" % repo_name)
committer = util.environ("GIT_COMMITTER_NAME")
remote_user = util.environ("GIT_COMMITTER_EMAIL")
script_name = util.environ("SCRIPT_NAME")
web_host = util.environ("WEB_HOST")
write_locks = [util.environ("WRITE_LOCK"), os.path.join(repo_dir, "nocommit")]
auth_file = util.environ("AUTH_FILE")

debug = _git_config("hooks.asfgit.debug") == "true"
protect = _git_config("hooks.asfgit.protect").split()
no_merges = _git_config("hooks.asfgit.no-merges") == "true"
sendmail = _git_config("hooks.asfgit.sendmail").strip()
recips = _git_config("hooks.asfgit.recips").split()
subject_fmt = _git_config("hooks.asfgit.subject-fmt", DEFAULT_SUBJECT)
max_size = int(_git_config("hooks.asfgit.max-size"))
max_emails = int(_git_config("hooks.asfgit.max-emails"))
extra_writers = _git_config("hooks.asfgit.extra-writers", default='')
extra_writers = extra_writers.split(',') if extra_writers != '' else []

gitpubsub_host = _git_config("hooks.asfgit.pubsub-host", DEFAULT_PUBSUB_HOST)
gitpubsub_port = _git_config("hooks.asfgit.pubsub-port", DEFAULT_PUBSUB_PORT)
gitpubsub_path = _git_config("hooks.asfgit.pubsub-path", DEFAULT_PUBSUB_PATH)
