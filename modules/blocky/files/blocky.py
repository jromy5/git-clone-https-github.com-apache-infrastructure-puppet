#!/usr/bin/env python
#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Blocky - ES aggregated ban thingy
#
# Example:
#  blocky.py --daemonize
#  requires blocky.cfg

import os
import sys
import time
import json
from threading import Thread
import atexit, signal
import subprocess, argparse, grp, pwd
import ConfigParser
import smtplib
import socket
import urllib
import syslog

syslog.openlog('blocky', logoption=syslog.LOG_PID, facility=syslog.LOG_LOCAL0)

config = ConfigParser.ConfigParser()

es = None
hostname = socket.gethostname()
if hostname.find(".apache.org") == -1:
	hostname = hostname + ".apache.org"
syslog.syslog(syslog.LOG_INFO, "Starting blocky on %s" % hostname)

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



class Blocky(Thread):
	def run(self):
		baddies = {}
		while True:
			try:
				js = json.loads(urllib.urlopen(config.get('aggregator','uri')).read())
				for baddie in js:
			# Got a new one?? :)
					i = baddie['ip']
					ta = baddie['target']
					if not i in baddies and (ta == hostname or ta == '*') and not 'unban' in baddie:
						r = baddie['reason'] if 'reason' in baddie else 'Unknown reason'
						try:
							# Check if we already have such a ban in place using iptables -C
							try:
								subprocess.check_call([
									"iptables",
									"-C", "INPUT",
									"-s", i,
									"-j", "DROP",
									"-m", "comment",
									"--comment",
									"Banned by Blocky"
									])
								# If we reach this point, the rule exists, no need to re-add it
							except subprocess.CalledProcessError as err:
								# We're here which means the rule didn't exist, so let's add it!
								subprocess.check_call([
									"iptables",
									"-A", "INPUT",
									"-s", i,
									"-j", "DROP",
									"-m", "comment",
									"--comment",
									"Banned by Blocky"
									])
								message = """%s banned %s (%s) - Unban with: sudo iptables -D INPUT -s %s -j DROP -m comment --comment "Banned by Blocky"\n""" % (hostname, i, r, i)
								syslog.syslog(syslog.LOG_INFO, message)
						except Exception as err:
							syslog.syslog(syslog.LOG_INFO, "Blocky encountered an error: " + str(err))
						baddies[i] = time.time()
					elif (not i in baddies or (i in baddies and (time.time() - baddies[i]) > 1800)) and (ta == hostname or ta == '*') and 'unban' in baddie and baddie['unban'] == True:
						baddies[i] = time.time()
						r = baddie['reason'] if 'reason' in baddie else 'Unknown reason'
						# Check if we already have such a ban in place using iptables -C
						try:
							subprocess.check_call([
								"iptables",
								"-C", "INPUT",
								"-s", i,
								"-j", "DROP",
								"-m", "comment",
								"--comment",
								"Banned by Blocky"
								])
							# If we reach this point, the rule exists, and we can remove it
							syslog.syslog(syslog.LOG_INFO, "Unbanning %s" % i)
							subprocess.check_call([
								"iptables",
								"-D", "INPUT",
								"-s", i,
								"-j", "DROP",
								"-m", "comment",
								"--comment", "Banned by Blocky"
								])
							message = """From: Blocky <blocky@no-reply@apache.org>
To: Apache Infrastructure Root <root@apache.org>
Reply-To: root@apache.org
Subject: [Blocky] Unbanned %s on %s.

Hi, this is %s.
I have just unbanned %s on this machine due to leniency
from the Blocky master server.

With regards,
Blocky.
	""" % (i, hostname, hostname, i)
							smtpObj = smtplib.SMTP('localhost')
							smtpObj.sendmail("blocky@" + hostname, ['root@apache.org'], message)

						except Exception as err:
							pass
						if i in baddies:
							del baddies[i]
				time.sleep(180)
			except Exception as err:
				syslog.syslog(syslog.LOG_INFO, "Error while running ban check: %s" % err)
				time.sleep(180) # Don't loop every 5ms if we hit a snag!



parser = argparse.ArgumentParser(description='Command line options.')
parser.add_argument('--user', dest='user', type=str, nargs=1,
					help='Optional user to run Blocky as')
parser.add_argument('--group', dest='group', type=str, nargs=1,
					help='Optional group to run Blocky as')
parser.add_argument('--pidfile', dest='pidfile', type=str, nargs=1,
					help='Optional pid file location')
parser.add_argument('--daemonize', dest='daemon', action='store_true',
					help='Run as a daemon')
parser.add_argument('--stop', dest='kill', action='store_true',
					help='Kill the currently running Blocky process')
args = parser.parse_args()

pidfile = "/var/run/blocky.pid"
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

	blocky = Blocky()
	blocky.start()


## Daemon class
class MyDaemon(Daemonize):
	def run(self, args):
		main()

# Get started!
if args.kill:
	print("Stopping Blocky")
	daemon = MyDaemon(pidfile)
	daemon.stop()
else:
	config.read("blocky.cfg")

	if args.daemon:
		print("Daemonizing...")
		daemon = MyDaemon(pidfile)
		daemon.start(args)
	else:
		main()
