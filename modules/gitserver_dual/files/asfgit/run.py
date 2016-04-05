import pipes
import subprocess as sp

import asfgit.util as util


def cmd(comm, input=None, capture=False, decode=True, check=True, **kwargs):
    stdin, stdout, stderr = None, None, None
    if input is not None:
        stdin = sp.PIPE
    if capture:
        stdout, stderr = sp.PIPE, sp.PIPE
    pipe = sp.Popen(comm, stdin=stdin, stdout=stdout, stderr=stderr, **kwargs)
    (stdout, stderr) = pipe.communicate(input=input)
    exitcode = pipe.wait()
    if check and exitcode != 0:
        raise sp.CalledProcessError(exitcode, comm)
    if decode:
        stdout = util.decode(stdout)
        stderr = util.decode(stderr)
    return (exitcode, stdout, stderr)

def git(comm, *args, **kwargs):
    gcomm = ["git", comm] + list(args)
    gcomm = ' '.join(map(lambda a: pipes.quote(str(a)), gcomm))
    kwargs["shell"] = True
    if "capture" not in kwargs:
        kwargs["capture"] = True
    return cmd(gcomm, **kwargs)
