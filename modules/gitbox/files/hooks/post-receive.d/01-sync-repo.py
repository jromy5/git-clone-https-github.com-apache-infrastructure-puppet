#!/usr/local/bin/python

import os
import sys
import traceback

if __name__ == '__main__':
    if not os.environ.get("ASFGIT_ADMIN"):
        print "Invalid server configuration."
        exit(1)
    sys.path.append(os.environ["ASFGIT_ADMIN"])

    import asfgit.log as log
    import asfgit.hooks.sync as hook
    import asfgit.util as util

    try:
        # Only sync if this isn't a mail-only call
        if not os.environ.get("NO_SYNC"):
            hook.main()

    except Exception, exc:
        log.exception()
        print "Error: %s" % exc
        exit(1)


