import asfgit.run as run
import asfgit.util as util


FIELDS = [
    ("commit", "%h"),
    ("parents", "%p"),
    ("tree", "%t"),
    ("author", "%aN <%ae>"),
    ("authored", "%ad"),
    ("author_name", "%aN"),
    ("author_email", "%ae"),
    ("committer", "%cN <%ce>"),
    ("committer_email", "%ce"),
    ("committed", "%cd"),
    ("committed_unix", "%ct"),
    ("ref_names", "%d"),
    ("subject", "%s"),
    ("body", "%B")
]


class Commit(object):
    def __init__(self, ref, sha):
        self.ref = ref
        self.sha = sha

        fmt = "--format=format:%s%%x00" % r'%x00'.join([s for _, s in FIELDS])
        args = ["show", "--stat=75", fmt, self.sha]
        parts = map(util.decode, run.git(*args, decode=False)[1].split("\x00"))

        self.stats = u"\n".join(filter(None, parts.pop(-1).splitlines()))
        for pos, (key, _) in enumerate(FIELDS):
            setattr(self, key, parts[pos])

        self.committed_unix = int(self.committed_unix)
        parts = self.committer_email.split(u"@")
        self.committer_uname = parts[0]
        if len(parts) > 1:
            self.committer_domain = parts[1]
        else:
            self.committer_domain = ""

    def __cmp__(self, other):
        return cmp(self.committed_unix, other.committed_unix)

    def is_merge(self):
        return len(self.parents.split()) > 1

    def files(self):
        files = run.git("show", "--name-only", "--format=format:", self.sha)[1]
        return [l.strip() for l in files.splitlines() if l.strip()]

    def diff(self, fname):
        args = ["show", "--format=format:", self.sha, "--", fname]
        return run.git(*args)[1].lstrip()


class RefUpdate(object):
    def __init__(self, name, oldsha, newsha):
        self.name = name
        self.oldsha = oldsha
        self.newsha = newsha

    def created(self):
        return self.oldsha == ("0" * 40)

    def deleted(self):
        return self.newsha == ("0" * 40)

    def is_tag(self):
        return self.name.startswith("refs/tags/")

    def is_protected(self, patterns):
        for p in patterns:
            # foo == foo
            if p == self.name:
                return True
            # foo/ == foo/bar but also foo exactly
            if p.endswith("/") and (self.name.startswith(p) or self.name == p[:-1]):
                return True
            # foo-* == foo-bar, foo-baz etc
            if p.endswith("*") and self.name.startswith(p[:-1]):
                return True
        return False

    def is_rewrite(self):
        return self.merge_base() != self.oldsha

    def commits(self, num=None, reverse=False):
        # Deleted refs have no commits.
        if self.deleted():
            return
        # Only report commits that aren't reachable from any other branch
        refs = []
        args = ["for-each-ref", "--format=%(refname)"]
        for r in run.git(*args)[1].splitlines():
            if r.strip() == self.name:
                continue
            if r.strip().startswith("refs/heads/"):
                refs.append("^%s" % r.strip())
        args = ["rev-list"]
        if num is not None:
            args += ["-n", str(num)]
        if reverse:
            args.append("--reverse")
        if self.created():
            args += refs
        if self.created():
            args.append(self.newsha)
        else:
            args.append("%s..%s" % (self.oldsha, self.newsha))
        for line in run.git(*args)[1].splitlines():
            sha = line.strip()
            yield Commit(self, sha)

    def merge_base(self):
        if ("0" * 40) in (self.oldsha, self.newsha):
            return "0" * 40
        (_, sha, _) = run.git("merge-base", self.oldsha, self.newsha)
        return sha.strip()


def stream_refs(handle):
    line = handle.readline()
    while line:
        oldsha, newsha, name = line.split(None, 2)
        yield RefUpdate(name.strip(), oldsha, newsha)
        line = handle.readline()

