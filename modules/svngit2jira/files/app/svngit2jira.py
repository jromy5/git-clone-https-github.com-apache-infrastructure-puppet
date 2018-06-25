#!/usr/bin/env python

############################################################
# svngit2jira - Subversion/Git to JIRA integration service #
# Also does ReviewBoard (and at some point Bugzilla?)      #
# Built for Python 3, works with 2.7 with a few tweaks     #
############################################################

from threading import Thread
from datetime import datetime
import requests
import sys
haveinotify = False
try:
    import pyinotify
    haveinotify = True
    print("Using pyinotify")
except:
    print("pyinotify not available, resorting to polling for config changes :()")

version = 2
if sys.hexversion < 0x03000000:
    print("Using Python 2...")
    import json, httplib, urllib, urllib2, ConfigParser as configparser, re, base64, sys, os, time, atexit, signal, logging, socket, subprocess
    socket._fileobject.default_bufsize = 0
else:
    print("Using Python 3")
    version = 3
    import json, httplib2, http.client, urllib.request, urllib.parse, configparser, re, base64, sys, os, time, atexit, signal, logging, subprocess

############################################
# Get path, set up logging and read config #
############################################
debug = False
logging.basicConfig(filename='svngit2jira.log', format='[%(asctime)s]: %(message)s', level=logging.INFO)


path = os.path.dirname(sys.argv[0])
if len(path) == 0:
    path = "."

# Fetch config
config = configparser.RawConfigParser()
config.read(path + '/svngit2jira.cfg')

# Fetch JIRA user/password
jira_user =  config.get('JIRA', 'username')
f = open("%s/%s" %(path, config.get('JIRA', 'password')), "r")
jira_pass = f.read().rstrip('\r\n')
f.close()

# Fetch ReviewBoard user/password
rb_user = config.get('ReviewBoard', 'username')
f = open("%s/%s" %(path, config.get('ReviewBoard', 'password')), "r")
rb_pass = f.read().rstrip('\r\n')
f.close()

###########################################################
# Daemon class, curtesy of an anonymous good-hearted soul #
###########################################################
class daemon:
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

	def start(self):
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
		self.run()

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



####################
# Helper functions #
####################


# read_chunk: iterator for reading chunks from the stream
# since this is all handled via urllib now, this is quite rudimentary
def read_chunk(req):
    while True:
        try:
            line = req.readline().strip().replace(b"\x00", b"")
            if line:
                yield line
            else:
                print("No more lines?")
                break
        except Exception as info:
            logging.warning("Error reading from stream: %s", info)
            break
    return



################
# JIRA Updater #
################
class JiraTicket:
    def __init__(self, ticket, author, email = None, asfuid = None):

        # Set some vars #
        self.ticket = ticket
        self.author = author
        self.email = email if email else None
        self.asfuid = asfuid
        self.sendIt = False
        if version == 3:
            self.auth = str(base64.encodestring(bytes('%s:%s' % (jira_user, jira_pass), 'ascii')), 'ascii').replace('\n', '')
        else:
            self.auth = str(base64.encodestring(bytes('%s:%s' % (jira_user, jira_pass)))).replace('\n', '')
        self.sender = author
        try:
            # Try to fetch JIRA username by searching for the email
            if self.email != None:
                url = "https://issues.apache.org/jira/rest/api/latest/user/search"
                obj = requests.get(url,
                    headers = {'Authorization': 'Basic %s' % self.auth},
                    params = { 'username': self.email, 'maxResults': 3}
                    ).json()
                if len(obj) > 0 and "name" in obj[0]:
                    logging.info("Found matching email record in JIRA user database")
                    self.sender = "[~%s]" % obj[0]['name']
                    self.sendIt = True

            # If that failed, try to find a user using ldap's alt email
            if self.sendIt == False and self.asfuid:
                # Only run this stuff if the uid is actually an Apache uid
                if re.match("^([a-z0-9]+)$", self.asfuid):
                    try:
                        ldapdata = subprocess.check_output(['ldapsearch', '-xLLL', 'uid=%s' % self.asfuid, 'mail', 'asf-altEmail'])
                        print(ldapdata)
                        for match in re.finditer(r"([^@\s]+@[^@\s]+)", ldapdata):
                            altemail = match.group(0)
                            logging.info("Trying to look up user via alternate email (%s)", altemail)

                            url = "https://issues.apache.org/jira/rest/api/latest/user/search"
                            obj = requests.get(url,
                                headers = {'Authorization': 'Basic %s' % self.auth},
                                params = { 'username': altemail, 'maxResults': 3}
                                ).json()
                            if len(obj) > 0 and "name" in obj[0]:
                                logging.info("Found matching email record in JIRA user database")
                                self.sender = "[~%s]" % obj[0]['name']
                                self.sendIt = True
                                break

                    except Exception as info:
                        logging.warning("LDAP error: %s", info)

            #If still not found, try searching for full name instead
            if self.sendIt == False and self.author:
                url = "https://issues.apache.org/jira/rest/api/latest/user/search"
                obj = requests.get(url,
                    headers = {'Authorization': 'Basic %s' % self.auth},
                    params = { 'username': self.author, 'maxResults': 3}
                    ).json()
                if len(obj) > 0 and "name" in obj[0]:
                    if "displayName" in obj[0] and obj[0]['displayName'] == self.author:
                        logging.info("Found matching full name in JIRA user database")
                        self.sender = "[~%s]" % obj[0]['name']
#                   else:
#                       logging.info("Found a username in JIRA user database")
#                       self.sender = "[~%s]" % obj[0]['name']
                    self.sendIt = True
                else:
                    self.sender = author if author else email
                    self.sendIt = True

            # Fall back to raw email/author if no username was found
            if not self.sender:
                self.sender = author if author else email
                self.sendIt = True

            logging.info("Set sender to: %s" % self.sender)
        except Exception as info:
            logging.info("urllib error: %s", info)
            # We're still gonna send it, even if stoopid unicode gets in our way.
            self.sender = author if author else email
            self.sendIt = True


    def update(self, data, where):
        if self.sendIt:
            logging.info("Updating ticket " + self.ticket)
            logging.info(data)
            headers = {"Content-type": "application/json",
                         "Accept": "*/*",
                         "Authorization": "Basic %s" % self.auth
                         }

            if not debug:
                try:
                    logging.info("Dispatching request to issues.apache.org")
                    conn = None

                    if version == 3:
                        conn = http.client.HTTPSConnection("issues.apache.org", 443)
                        conn.request("POST", "/jira/rest/api/latest/issue/%s/%s" % (self.ticket, where), data, headers)
                        response = conn.getresponse()
                        if response.status == 200 or response.status == 201:
                            logging.info("Posted JIRA update")
                        else:
                            logging.warning("JIRA instance returned status code %u" % response.status )
                    else:
                        try:
                            request = urllib2.Request("https://issues.apache.org/jira/rest/api/latest/issue/%s/%s" % (self.ticket, where), data, headers)
                            response = urllib2.urlopen(request)
                            code = response.getcode()
                            if code == 200 or code == 201:
                                logging.info("Posted JIRA Update")
                            else:
                                logging.warning("JIRA returned HTTP code %u" % code)

                        except Exception as info:
                            logging.warning("JIRA instance returned error: %s", info)

                except Exception as info:
                    logging.warning("JIRA Update failed: %s", info)
            else:
                logging.warning("Foreground mode enabled, no actual JIRA update made")
        else:
            logging.warning("An error occured, not updating ticket")




#######################
# ReviewBoard updater #
#######################
class ReviewBoard:

    def __init__(self, ticket):
        self.ticket = ticket
        self.rid = None
        if version == 3:
            self.auth = str(base64.encodestring(bytes('%s:%s' % (rb_user, rb_pass), 'ascii')), 'ascii').replace('\n', '')
        else:
            self.auth = str(base64.encodestring(bytes('%s:%s' % (rb_user, rb_pass)))).replace('\n', '')
        try:
            opener = None
            if version == 3:
                opener = urllib.request.build_opener()
            else:
                opener = urllib2.build_opener()

            opener.addheaders = [('Authorization', 'Basic %s' % self.auth)]
            opener.addheaders = [('Accept', 'application/json')]
            url = opener.open("https://reviews.apache.org/api/search/?q=%s" % self.ticket)

            data = None
            if version == 3:
                data = str(url.read(), 'ascii')
            else:
                data = str(url.read())

            obj = json.loads(data)
            if "search" in obj and "review_requests" in obj['search']:
                for key in range(len(obj['search']['review_requests'])):
                    summary = obj['search']['review_requests'][key]['summary'] + " "
                    id = obj['search']['review_requests'][key]['id']
                    if re.search(self.ticket + "\D", summary):
                        self.rid = id
                        break
        except:
            logging.warning("urllib error")

    def update(self, data):
        # Only run an update on the ticket if a review ID has been found
        if self.rid:
            logging.info("We found a review, %u" % self.rid)
            try:
                headers = {
                             "Accept": "*/*",
                             "Authorization": "Basic %s" % self.auth
                             }

                post_data = None
                if version == 3:
                    post_data = "api_format=json&ship_it=0&body_top=%s&body_bottom=&public=1" % urllib.parse.quote(data)
                else:
                    post_data = "api_format=json&ship_it=0&body_top=%s&body_bottom=&public=1" % urllib2.quote(data)

                if not debug:
                    logging.info("Dispatching request to reviews.apache.org")

                    conn = None
                    if version == 3:
                        conn = http.client.HTTPSConnection("reviews.apache.org", 443)
                    else:
                        conn = httplib.HTTPSConnection("reviews.apache.org", 443)

                    conn.request("POST", "/api/review-requests/%u/reviews/" % self.rid, post_data, headers)
                    response = conn.getresponse()
                    if response.status == 201:
                        logging.info("Posted ReviewBoard update")
                    else:
                        logging.warning("ReviewBoard instance returned status code %u" % response.status )
                else:
                    logging.warning("Foreground mode enabled, no actual ReviewBoard update made")
            except:
                pass



##################
# Bugzilla class #
##################
class Bugzilla:
    def __init__(self, issue):
        pass

    def update(self, data):
        pass



#########################
# Main listener program #
#########################

# PubSub class: handles connecting to a pubsub service and checking commits
class PubSubClient(Thread):
    def __del__(self):
        logging.warning("Pubsub client for %s died." % self.url)

    def run(self):
        while True:
            logging.info("Connecting to " + self.url + "...")
            self.req = None
            while not self.req:
                try:
                    if version == 3:
                        self.req = urllib.request.urlopen(self.url, None, 30)
                    else:
                        self.req = urllib2.urlopen(self.url, None, 30)
                    logging.info("Connected to " + self.url + ", reading stream")
                except:
                    logging.warning("Could not connect to %s, retrying in 30 seconds..." % self.url)
                    time.sleep(30)
                    continue

            for line in read_chunk(self.req):
                if version == 3:
                    line = str( line, encoding='utf-8', errors = 'replace' ).rstrip('\r\n,') # strip away any old pre-0.9 commas from gitpubsub chunks and \0 in svnpubsub chunks
                else:
                    line = str( line ).rstrip('\r\n,').replace('\x00','') # strip away any old pre-0.9 commas from gitpubsub chunks and \0 in svnpubsub chunks
                try:
                    obj = json.loads(line)
                    if "commit" in obj and "repository" in obj['commit']:
                        if debug:
                            logging.info("Found a commit in %s", obj['commit']['repository'])

                        if obj['commit']['repository'] == "git":

                            # grab some vars
                            commit = obj['commit']
                            project = commit['project']
                            body = commit['body']
                            sha = commit['sha']
                            ssha = commit['hash']
                            author = commit['author']
                            email = commit['email']
                            ref = commit['ref']
                            server = commit['server'] if 'server' in commit else 'git-wip-us'

                            # Find out if this is a project we're tracking
                            for section in config.sections():
                                if config.has_option(section, "trigger") and config.has_option(section, "git"):
                                    trigger = config.get(section, "trigger")
                                    match = config.get(section, "git")
                                    # If a tracking channel's git value matches, then...
                                    if re.match("^" + match + "$", project) and not (config.has_option(section, 'ignoredBranches') and re.match(config.get(section, 'ignoredBranches'), ref)):
                                        logging.info("Git path for %s matches, seeing if %s matches the body" % (section, trigger))
                                        doWorkLog = True if (config.has_option(section, 'worklog') and config.get(section, 'worklog') == "true") else False
                                        # For each ticket reference we find, ...
                                        for ticket in re.finditer(trigger, body):
                                            logging.info("Found: " + ticket.group(0) + " in body, updating ticket")

                                            # We're about to make a JIRA update!
                                            jira = JiraTicket(ticket.group(0), author, email)


                                            # Create a JSON object and RB body for sending
                                            data = None;
                                            if doWorkLog:
                                                data = {'timeSpent': "10m", 'comment': "Commit %s in %s's branch %s from %s\n[ https://%s.apache.org/repos/asf?p=%s.git;h=%s ]\n\n%s" % (sha, project, ref, jira.sender, server, project, ssha, body) }
                                            else:
                                                data = {'body': "Commit %s in %s's branch %s from %s\n[ https://%s.apache.org/repos/asf?p=%s.git;h=%s ]\n\n%s" % (sha, project, ref, jira.sender, server, project, ssha, body) }

                                            rb_data = "Commit %s in %s's branch %s from %s\n[ https://%s.apache.org/repos/asf?p=%s.git;h=%s ]\n\n%s" % (sha, project, ref, author, server, project, ssha, body)

                                            # Update the ticket
                                            jira.update(json.dumps(data), 'worklog' if doWorkLog else 'comment')

                                            # Send to ReviewBoard if set to check that
                                            if config.has_option(section, 'reviewboard') and config.get(section, 'reviewboard') == "true":
                                                rb = ReviewBoard(ticket.group(0))
                                                rb.update(rb_data)

                        # If it's not git (and not JIRA), it must be subversion
                        elif obj['commit']['repository'] == "13f79535-47bb-0310-9956-ffa450edef68":

                            #Grab some vars
                            commit = obj['commit']
                            body = commit['log']
                            svnuser = commit['committer']
                            path, action = commit['changed'].popitem()
                            revision = commit['id']
                            email = svnuser + "@apache.org"

                            # Look for a tracker that matches the svn path..
                            for section in config.sections():
                                if config.has_option(section, "trigger") and config.has_option(section, "svn"):
                                    trigger = config.get(section, "trigger")
                                    match = config.get(section, "svn")

                                    # If a tracker's svn path matches, then...
                                    if re.match("^" + match + "/", path):
                                        logging.info("SVN path for %s matches, seeing if %s matches the body" % (section, trigger))
                                        doWorkLog = True if (config.has_option(section, 'worklog') and config.get(section, 'worklog') == "true") else False
                                        # For each found ticket reference, do...
                                        usedTickets = []
                                        for ticket in re.finditer(r"\b" + trigger, body):
                                            if ticket.group(1) in usedTickets:
                                                logging.info("Found duplicate: " + ticket.group(1) + " in body, not updating ticket")
                                                continue
                                            logging.info("Found: " + ticket.group(1) + " in body, updating ticket")
                                            usedTickets.append(ticket.group(1))
                                            # We're about to make a JIRA update!
                                            # First, let's find the sender's JIRA account, if such exists
                                            jira = JiraTicket(ticket.group(1), None, email, svnuser)

                                            # Create a JSON object for sending
                                            data = None
                                            if doWorkLog:
                                                data = {'timeSpent': "10m", 'comment': "Commit %s from %s\n[ https://svn.apache.org/r%s ]\n\n%s" % (revision, jira.sender, revision, body) }
                                            else:
                                                data = {'body': "Commit %s from %s\n[ https://svn.apache.org/r%s ]\n\n%s" % (revision, jira.sender, revision, body) }

                                            rb_data = "Commit %s from %s\n[ https://svn.apache.org/r%s ]\n\n%s" % (revision, email, revision, body)

                                            # Are we dealing with a branch? If so, change the ticket data slightly
                                            branch = re.search(r"(\w+/branches/[^/]+)", path)
                                            if not branch:
                                                branch = re.search(r"(\w+/trunk)", path)

                                            if branch:
                                                if doWorkLog:
                                                    data['comment'] = "Commit %s from %s in branch '%s'\n[ https://svn.apache.org/r%s ]\n\n%s" % (revision, jira.sender, branch.group(1), revision, body)
                                                else:
                                                    data['body'] = "Commit %s from %s in branch '%s'\n[ https://svn.apache.org/r%s ]\n\n%s" % (revision, jira.sender, branch.group(1), revision, body)

                                            # Send the ticket update
                                            jira.update(json.dumps(data), 'worklog' if doWorkLog else 'comment')

                                            # Send to ReviewBoard if set to check that
                                            if config.has_option(section, 'reviewboard') and config.get(section, 'reviewboard') == "true":
                                                rb = ReviewBoard(ticket.group(1))
                                                rb.update(rb_data)
                except Exception as detail:
                    logging.warning("Bad JSON or something: %s" % detail)
            logging.warning("Disconnected from %s, reconnecting" % self.url)




##########################
# Configuration reloader #
##########################
def updateConfig():
    logging.info("Configuration was updated, reloading")

    # Remove all tracking sections (we'll reload them in a bit)
    for section in config.sections():
        if re.match("Tracking:(.+)", section):
            config.remove_section(section)

    # Re-read config
    config.read(path + '/svngit2jira.cfg')
    projects = []
    for section in config.sections():
        match = re.match("Tracking:(.+)", section)
        if match:
            projects.append(match.group(1))
    projects.sort()
    logging.info("Found the following trackers: %s", ', '.join(projects))

if haveinotify:
    class ModHandler(pyinotify.ProcessEvent):
        # evt has useful properties, including pathname
        def process_IN_CLOSE_WRITE(self, evt):
            updateConfig()


################
# Main program #
################
def main():
    if debug:
        print("Foreground test mode enabled, no POST requests will be sent")

    # Start the git thread
    git_thread = PubSubClient()
    git_thread.url = config.get('PubSub', 'git')
    git_thread.start()

    # Start the svn thread
    svn_thread = PubSubClient()
    svn_thread.url = config.get('PubSub', 'svn')
    svn_thread.start()

    # Idle and check for updates to the config
    if haveinotify:
        handler = ModHandler()
        wm = pyinotify.WatchManager()
        notifier = pyinotify.Notifier(wm, handler)
        wdd = wm.add_watch(path + '/svngit2jira.cfg', pyinotify.IN_CLOSE_WRITE)
        notifier.loop()
    else:
        modded = os.stat(path + '/svngit2jira.cfg').st_mtime
        while True:
            time.sleep(5)
            xmodded = os.stat(path + '/svngit2jira.cfg').st_mtime
            if xmodded != modded:
                modded = xmodded
                logging.info("Configuration was updated, reloading")

                # Remove all tracking sections (we'll reload them in a bit)
                for section in config.sections():
                    if re.match("Tracking:(.+)", section):
                        config.remove_section(section)

                # Re-read config
                config.read(path + '/svngit2jira.cfg')
                projects = []
                for section in config.sections():
                    match = re.match("Tracking:(.+)", section)
                    if match:
                        projects.append(match.group(1))
                projects.sort()
                logging.info("Found the following trackers: %s", ', '.join(projects))


##############
# Daemonizer #
##############
class MyDaemon(daemon):
    def run(self):
        main()

if __name__ == "__main__":
        daemon = MyDaemon('/tmp/svngit2jira.pid')
        if len(sys.argv) == 2:
                if 'start' == sys.argv[1]:
                    daemon.start()
                elif 'stop' == sys.argv[1]:
                    daemon.stop()
                elif 'restart' == sys.argv[1]:
                    daemon.restart()
                elif 'foreground' == sys.argv[1]:
                    debug = True
                    logging.getLogger().addHandler(logging.StreamHandler())
                    main()
                elif 'test' == sys.argv[1]:
                    debug = True
                    logging.getLogger().addHandler(logging.StreamHandler())
                    logging.info("Running tests")
                    run_test()
                else:
                    print("Unknown command")
                    sys.exit(2)
                sys.exit(0)
        else:
                print("usage: %s start|stop|restart|foreground|test" % sys.argv[0])
                sys.exit(2)
