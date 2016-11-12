import os
import syslog
import time
import traceback

import asfgit.cfg as cfg

def exception():
    logfile = os.path.join(cfg.repo_dir, "error.log")
    tb = traceback.format_exc()
    # Send error message to syslog
    syslog.syslog(syslog.LOG_ERR, "{0} - {1}".format(cfg.script_name, tb))
    # Send error message to script log error.log 
    with open(logfile, "a") as handle:
        handle.write("[{0}] {1}".format(time.ctime(), tb))
