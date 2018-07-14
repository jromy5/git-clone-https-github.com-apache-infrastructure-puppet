#!/usr/bin/env python

############################################################
# ConfigScanner - A buildbot config scanner and updater    #
# Also does ReviewBoard (and at some point Bugzilla?)      #
# Built for Python 3, works with 2.7 with a few tweaks     #
############################################################

SVN='/usr/bin/svn'
BUILDBOT='/x1/buildmaster/bin/buildbot'

buildbotDir = "/x1/buildmaster/master1"
blamelist = ["users@infra.apache.org"]

# SMTP Lib
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from smtplib import SMTPException

# Threading
from threading import Thread
from datetime import datetime

# Rest
import sys, os
import argparse, grp, pwd, shutil

version = 2
if sys.hexversion < 0x03000000:
    print("Using Python 2...")
    import json, httplib, urllib, urllib2, re, base64, sys, os, time, atexit, signal, logging, socket, subprocess
    socket._fileobject.default_bufsize = 0
else:
    print("Using Python 3")
    version = 3
    import json, httplib2, http.client, urllib.request, urllib.parse, re, base64, sys, os, time, atexit, signal, logging, subprocess


PROJECTS_CONF = ('infrastructure/buildbot/aegis/buildmaster/master1/projects/'
                 'projects.conf')


############################################
# Get path, set up logging and read config #
############################################
debug = False
logging.basicConfig(filename='configscanner.log', format='[%(asctime)s]: %(message)s', level=logging.INFO)

path = os.path.dirname(sys.argv[0])
if len(path) == 0:
    path = "."


def sendEmail(rcpt, subject, message):
    sender = "<buildbot@buildbot-vm.apache.org>"
    receivers = [rcpt]
    msg = """From: %s
To: %s
Subject: %s

%s

With regards,
BuildBot
""" % (sender, rcpt, subject, message)

    try:
        smtpObj = smtplib.SMTP("localhost")
        smtpObj.sendmail(sender, receivers, msg)
    except SMTPException:
        raise Exception("Could not send email - SMTP server down??")

####################
# Helper functions #
####################


# read_chunk: iterator for reading chunks from the stream
# since this is all handled via urllib now, this is quite rudimentary
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


#########################
# Main listener program #
#########################

# PubSub class: handles connecting to a pubsub service and checking commits
class PubSubClient(object):
    def start(self):
        broken = False
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
                    line = str( line, encoding='ascii' ).rstrip('\r\n,').replace('\x00','') # strip away any old pre-0.9 commas from gitpubsub chunks and \0 in svnpubsub chunks
                else:
                    line = str( line ).rstrip('\r\n,').replace('\x00','') # strip away any old pre-0.9 commas from gitpubsub chunks and \0 in svnpubsub chunks
                try:
                    obj = json.loads(line)
                    if "commit" in obj and "repository" in obj['commit']:
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


                        # If it's not git (and not JIRA), it must be subversion
                        elif obj['commit']['repository']:

                            #Grab some vars
                            commit = obj['commit']
                            body = commit['log']
                            svnuser = commit['committer']
                            revision = commit['id']
                            email = svnuser + "@apache.org"

                            os.chdir(buildbotDir)
                            # get current revision; assumed good
                            # we do this in outer try block as failure is fatal

                            # --show-item not supported by current SVN client
                            #before=subprocess.check_output([SVN,'info','--show-item','last-changed-revision', 'projects']).rstrip()
                            # Use this instead until SVN is updated
                            before=re.search(r"^Last Changed Rev: (\d+)$", subprocess.check_output([SVN,'info', 'projects']), re.M).group(1)

                            for path in commit['changed']:
                                m = re.match(r"infrastructure/buildbot/aegis/buildmaster/master1/projects/(.+\.conf)", path)
                                if m:
                                    # N.B. this loop only runs on first match as it processes the entire revision at once
                                    time.sleep(3) # why do we wait here?
                                    logging.info("Validating new revision %s (was %s)" % (revision, before))
                                    os.environ['HOME'] = '/x1/buildmaster' # where SVN settings are found
                                    try:
                                        logging.info("Checking out new config")
                                        subprocess.check_output([SVN, 'update', '-r', "%u" % revision, 'projects'])
                                        logging.info("Running config check")
                                        subprocess.check_output([BUILDBOT, "checkconfig"], stderr=subprocess.STDOUT)
                                        logging.info("Check passed, apply the new config")
                                        subprocess.check_output([BUILDBOT, "reconfig"], stderr=subprocess.STDOUT)
                                        if broken: # has this fixed a broken config?
                                            broken = False
                                            blamelist.append(email)
                                            try: # Don't let mail failure cause the update to be treated as failed
                                                for rec in blamelist:
                                                    sendEmail(
                                                        rec,
                                                        "Buildbot configuration back to normal in %s" % revision,
                                                        "Looks like things got fixed, yay!"
                                                        )
                                            except Exception as e:
                                                logging.warning("Failed to send recovery mail: %s", e)
                                            blamelist.remove(email)
                                    except subprocess.CalledProcessError as err:
                                        broken = True
                                        logging.warning("Config check returned code %i" % err.returncode)
                                        logging.warning(err.output)
                                        # Do this first in case mail fails
                                        logging.info("Cleaning up...")
                                        subprocess.call([SVN, 'update', '-r', before, 'projects'])
                                        blamelist.append(email)
                                        out = """
The error(s) below happened while validating the committed changes.
As a precaution, this commit has not yet been applied to BuildBot.
Please correct the below and commit your fixes:

%s
""" % err.output
                                        for rec in blamelist:
                                            sendEmail(
                                                rec,
                                                "Buildbot configuration failure in %s" % revision,
                                                out
                                                )
                                        blamelist.remove(email)

                                    logging.info("All done, back to listening for changes :)")

                                    break # we process the whole revision on the first match

                except (ValueError, Exception) as detail:
                    logging.warning("Bad JSON or something: %s", detail)
                    continue
            logging.info("Disconnected from %s, reconnecting" % self.url)



################
# Main program #
################
def main():
    # Start the svn thread
    svn_thread = PubSubClient()
    svn_thread.url = "http://svn-master.apache.org:2069/commits/*"
    svn_thread.start()


### Run the thing ###
if __name__ == "__main__":

    parser = argparse.ArgumentParser(description='Command line options.')
    parser.add_argument('--user', dest='user', type=str, nargs=1,
                       help='Optional user to run ConfigScanner as')
    parser.add_argument('--group', dest='group', type=str, nargs=1,
                       help='Optional group to run ConfigScanner as')
    parser.add_argument('--pidfile', dest='pidfile', type=str, nargs=1,
                       help='Optional pid file location')
    parser.add_argument('--daemonize', dest='daemon', action='store_true',
                       help='Run as a daemon')
    parser.add_argument('--stop', dest='kill', action='store_true',
                       help='Kill the currently running ConfigScanner process')
    args = parser.parse_args()

    if args.group and len(args.group) > 0:
        gid = grp.getgrnam(args.group[0])
        os.setgid(gid[2])

    logging.getLogger().addHandler(logging.StreamHandler())
    main()
