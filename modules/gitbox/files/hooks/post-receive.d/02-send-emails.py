#!/usr/local/bin/python

import os
import sys
import traceback
NO_DEFAULT = object()

if __name__ == '__main__':
    if not os.environ.get("ASFGIT_ADMIN"):
        print "Invalid server configuration."
        exit(1)
    sys.path.append(os.environ["ASFGIT_ADMIN"])

    import asfgit.log as log
    import asfgit.git_multimail as git_multimail
    import asfgit.util as util

    path = filter(None, os.environ["PATH_INFO"].split("/"))
    path = filter(lambda p: p != "git-receive-pack", path)
    if len(path) != 1:
        raise ValueError("Invalid PATH_INFO: %s" % os.environ["PATH_INFO"])
    path = path[0]
    repo = ""
    if path[-4:] == ".git":
        repo = util.decode(path[:-4])
    else:
        repo = util.decode(path)

    try:    
        config = git_multimail.Config('multimailhook')
        try:
            environment = git_multimail.GenericEnvironment(config=config)
        except git_multimail.ConfigurationException:
            sys.stderr.write('*** %s\n' % sys.exc_info()[1])
            sys.exit(1)

        mailer = git_multimail.SendMailer(
            os.environ,
            command=['/usr/local/sbin/sendmail', '-oi', '-t'],
            envelopesender='git@apache.org',
            )

        git_multimail.run_as_post_receive_hook(environment, mailer)
    except Exception, exc:
        log.exception()
        print "Error: %s" % exc
        exit(0) # Don't exit(1) here, we want the bleedin' sync to complete!


