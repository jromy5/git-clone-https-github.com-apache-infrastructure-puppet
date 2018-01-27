from threading import Thread
import json, urllib.request, urllib.parse, configparser, re, base64, sys, os, time, atexit, signal, logging, subprocess, collections, argparse, grp, pwd, shutil
from threading import Lock
import threading;
from collections import namedtuple
import random, atexit, signal, inspect
import time
import logging
import logging.handlers


path = os.path.dirname(os.path.abspath(sys.argv[0]))
if len(path) == 0:
    path = "."
    
# Fetch config
config = configparser.RawConfigParser()

config.read(path + '/gitwcsub.cfg')



log_handler = logging.handlers.WatchedFileHandler(config.get("Logging", "logFile"))
formatter = logging.Formatter(
	'%(asctime)s gitwcsub [%(process)d]: %(message)s',
	'%b %d %H:%M:%S')
formatter.converter = time.gmtime
log_handler.setFormatter(formatter)
logger = logging.getLogger()
logger.addHandler(log_handler)
logger.setLevel(logging.INFO)

pending = {}



class Daemonize:
	"""A generic daemon class.

	Usage: subclass the daemon class and override the run() method."""

	def __init__(self, pidfile): self.pidfile = pidfile
	
	def daemonize(self):
		"""Deamonize class. UNIX double fork mechanism."""

		try: 
			pid = os.fork() 
			if pid > 0:
				# exit first parent
				sys.exit(0) 
		except OSError as err: 
			sys.stderr.write('fork #1 failed: {0}\n'.format(err))
			sys.exit(1)
	
		# decouple from parent environment
		os.chdir('/') 
		os.setsid() 
		os.umask(0) 
	
		# do second fork
		try: 
			pid = os.fork() 
			if pid > 0:

				# exit from second parent
				sys.exit(0) 
		except OSError as err: 
			sys.stderr.write('fork #2 failed: {0}\n'.format(err))
			sys.exit(1) 
	
		# redirect standard file descriptors
		sys.stdout.flush()
		sys.stderr.flush()
		si = open(os.devnull, 'r')
		so = open(os.devnull, 'a+')
		se = open(os.devnull, 'a+')

		os.dup2(si.fileno(), sys.stdin.fileno())
		os.dup2(so.fileno(), sys.stdout.fileno())
		os.dup2(se.fileno(), sys.stderr.fileno())
	
		# write pidfile
		atexit.register(self.delpid)

		pid = str(os.getpid())
		with open(self.pidfile,'w+') as f:
			f.write(pid + '\n')
	
	def delpid(self):
		os.remove(self.pidfile)

	def start(self, args):
		"""Start the daemon."""

		# Check for a pidfile to see if the daemon already runs
		try:
			with open(self.pidfile,'r') as pf:

				pid = int(pf.read().strip())
		except IOError:
			pid = None
	
		if pid:
			message = "pidfile {0} already exist. " + \
					"Daemon already running?\n"
			sys.stderr.write(message.format(self.pidfile))
			sys.exit(1)
		
		# Start the daemon
		self.daemonize()
		self.run(args)

	def stop(self):
		"""Stop the daemon."""

		# Get the pid from the pidfile
		try:
			with open(self.pidfile,'r') as pf:
				pid = int(pf.read().strip())
		except IOError:
			pid = None
	
		if not pid:
			message = "pidfile {0} does not exist. " + \
					"Daemon not running?\n"
			sys.stderr.write(message.format(self.pidfile))
			return # not an error in a restart

		# Try killing the daemon process	
		try:
			while 1:
				os.kill(pid, signal.SIGTERM)
				time.sleep(0.1)
		except OSError as err:
			e = str(err.args)
			if e.find("No such process") > 0:
				if os.path.exists(self.pidfile):
					os.remove(self.pidfile)
			else:
				print (str(err.args))
				sys.exit(1)

	def restart(self):
		"""Restart the daemon."""
		self.stop()
		self.start()

	def run(self):
		"""You should override this method when you subclass Daemon.
		
		It will be called after the process has been daemonized by 
		start() or restart()."""


# Func for cloning a new repo
def buildRepo(path, URL, branch):
    logging.info("%s does not exist, trying to clone into it as a new dir" % path)
    rv = "No output"
    try:
        rv = subprocess.check_output(("git", "clone", "-b", branch, "--single-branch", URL, path))
    except Exception as err:
        rv = "Error while cloning: %s" % err
    logging.info(rv)
   
   
# Func for updating whatever is in the queue
def updatePending():
    global pending
    xpending = pending;
    pending = {}
    for entry in xpending:
        repo = entry
        path = xpending[entry]
        trueRepo = repo
        httproot = config.get("Servers", "gitroot")
        # Check if non-default git root, if so find new http root
        m = re.match(r"^\$([^/]+)/(.+)$", repo)
        if m:
            trueRepo = m.group(2)
            groot = m.group(1)
            httproot = config.get("Servers", groot) if config.has_option("Servers", groot) else httproot
        # Special branch via repo:branch syntax? Otherwise, default to config global
        branch = config.get("Misc", "branch")
        if ':' in trueRepo:
            trueRepo, branch = trueRepo.split(':', 1)
        newURL = "%s%s.git" % (httproot, trueRepo)
        
        # Check if we need to pull or clone:
        
        # Existing repo?
        if os.path.isdir(path):
            os.chdir(path)
            
            # Check if the repo has moved, and if so, tear down and rebuild
            try:
                oldURL = ""
                try:
                    oldURL = str( subprocess.check_output(("git", "config", "remote.origin.url")), encoding='ascii' ).rstrip('\r\n')
                except Exception as err:
                    logging.warn("Git config exited badly, not a Git repo??")
                    oldURL = ""
                if newURL != oldURL:
                    canClobber = True
                    if oldURL == "":
                        logging.warn("No previous git remote detected, checking for SVN info..")
                        canClobber = False
                        try:
                            rv =subprocess.check_output(("svn", "info"))
                            if re.search(r"URL: ", rv.decode("utf-8"), re.MULTILINE):
                                canClobber = True
                                logging.warn("This is/was a subversion repo, okay to clobber")
                        except Exception as err:
                            logging.warn("Not a repo, not going to clobber it: %s" % err)
                            canClobber = False
                    if canClobber:
                        logging.warn("Local origin (%s) does not match configuration origin (%s), rebuilding!" % (oldURL, newURL))
                        os.chdir("/")
                        shutil.rmtree(path)
                        buildRepo(path, newURL, branch)
            # Otherwise, just pull in changes
                else:
                    logging.info("Pulling changes into %s" % path)
                    rv = subprocess.check_output(("git", "fetch", "origin", branch))
                    logging.info(rv)
                    rv = subprocess.check_output(("git", "reset", "--hard", "origin/%s" % branch))
                    logging.info(rv)
            except Exception as err:
                logging.error("Git update error: %s" % err)
                
        # New repo?
        else:
            buildRepo(path, newURL, branch)
            
def read_chunk(req):
    while True:
        try:
            line = req.readline().strip()
            if line:
                yield line
            else:
                print("No more lines?")
                break
        except Exception as info:
            logging.warning("Error reading from stream: %s", info)
            break
    return
    
def parseGitCommit(commit):
    global pending
    if commit['repository'] == "git":
        if 'project' in commit:
            project = commit['project']
            branch = commit['ref'].replace("refs/heads/", "")
            for option in config.options("Tracking"):
                branchNeeded = config.get("Misc", "branch")
                path = option
                repo = config.get("Tracking", option)
                trueRepo = repo
                # Check if non-default git root, weed that out if so
                m = re.match(r"^\$([^/]+)/(.+)$", repo)
                if m:
                    trueRepo = m.group(2)
                    groot = m.group(1)
                # Check for non-standard publish branch
                if ':' in trueRepo:
                    trueRepo, branchNeeded = trueRepo.split(':', 1)
                if project == trueRepo and branch == branchNeeded:
                    logging.info("Adding %s (%s) to the update queue" % (path, repo))
                    pending[repo] = path
                

            
    
# PubSub class: handles connecting to a pubsub service and checking commits
class PubSubClient(Thread):
   
    
    def run(self):
        self.killed = False
        while not self.killed:
            logging.info("[%s] Connecting to " % self.ident + self.url + "...")
            self.req = None
            while not self.req:
                try:
                    self.req = urllib.request.urlopen(self.url, None, 30)
                    logging.info("[%s] Connected to " % self.ident + self.url + ", reading stream")
                except:
                    logging.warning("[%s] Could not connect to %s, retrying in 30 seconds..." % (self.ident, self.url))
                    time.sleep(30)
                    continue
                
            for line in read_chunk(self.req):
                line = str( line, encoding='ascii', errors='ignore' ).rstrip('\r\n,').replace('\x00','') # strip away any old pre-0.9 commas from gitpubsub chunks and \0 in svnpubsub chunks
                
                try:
                    obj = json.loads(line)
                    if "commit" in obj and "repository" in obj['commit']:
                        logging.info("[%s] Got a commit in '%s'" % (self.ident, obj['commit']['repository']))
                        if obj['commit']['repository'] == "git":
                            parseGitCommit(obj['commit'])
                            
                except ValueError as detail:
                    logging.warning("Bad JSON or something: %s", detail)
                    continue
            logging.info("[%s] Disconnected from %s, reconnecting" % (self.ident, self.url))
            if self.killed:
               logging.info("[%s] Pubsub thread killed, exiting" % self.ident)
               break

parser = argparse.ArgumentParser(description='Command line options.')
parser.add_argument('--user', dest='user', type=str, nargs=1,
                   help='Optional user to run GitWcSub as')
parser.add_argument('--group', dest='group', type=str, nargs=1,
                   help='Optional group to run GitWcSub as')
parser.add_argument('--pidfile', dest='pidfile', type=str, nargs=1,
                   help='Optional pid file location')
parser.add_argument('--daemonize', dest='daemon', action='store_true',
                   help='Run as a daemon')
parser.add_argument('--stop', dest='kill', action='store_true',
                   help='Kill the currently running GitWcSub process')
args = parser.parse_args()

pidfile = "/var/run/gitwcsub.pid"
if args.pidfile and len(args.pidfile) > 2:
    pidfile = args.pidfile

def main():
    
    if args.group and len(args.group) > 0:
        gid = grp.getgrnam(args.group[0])
        os.setgid(gid[2])
    
    if args.user and len(args.user) > 0:
        print("Switching to user %s" % args.user[0])
        uid = pwd.getpwnam(args.user[0])[2]
        os.setuid(uid)
    
    global pending
    pubsub = PubSubClient()
    pubsub.url = config.get("Servers", "pubsub")
    pubsub.start()
    
    logging.warn("Service restarted, checking for updates in all tracked repos")
    for option in config.options("Tracking"):
        repo = config.get("Tracking", option)
        path = option
        pending[repo] = path
    
    while True:
        updatePending()
        time.sleep(3)
        
    
## Daemon class
class MyDaemon(Daemonize):
    def run(self, args):
        main()
    
# Get started!
if args.kill:
    print("Stopping GitWcSub")
    daemon = MyDaemon(pidfile)
    daemon.stop()
else:
    if args.daemon:
        print("Daemonizing...")
        daemon = MyDaemon(pidfile)
        daemon.start(args)
    else:
        main()
