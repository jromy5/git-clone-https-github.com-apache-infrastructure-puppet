#!/usr/bin/env python

from inotify import watcher
import inotify
import os
import select
import sys
import time, datetime
import json
import re
import socket
import hashlib, random
from collections import defaultdict, namedtuple
from threading import Thread
import random, atexit, signal, inspect
from threading import Lock
import subprocess, collections, argparse, grp, pwd, shutil

# ElasticSearch
from elasticsearch import Elasticsearch, helpers

es = None
hostname = socket.gethostname()
if hostname.find(".apache.org") == -1:
    hostname = hostname + ".apache.org"



regexes = {
    'apache_access': re.compile( 
            r"(?P<client_ip>[\d\.]+)\s" 
            r"(?P<identity>\S*)\s" 
            r"(?P<user>\S*)\s"
            r"\[(?P<time>.*?)\]\s"
            r'"(?P<request>.*?)"\s'
            r"(?P<status>\d+)\s"
            r"(?P<bytes>\S*)\s"
            r'"(?P<referer>.*?)"\s'
            r'"(?P<user_agent>.*?)"\s*'
        ),
    'apache_error': re.compile(
            r"\[(?P<date>.*?)\]\s+"
            r"\[(?P<module>.*?)\]\s+"
            r"\[(?P<pid>.*?)\]\s+"
            r"\[client\s+(?P<client_ip>[0-9.]+):\d+\]\s+"
            r"(?P<message>.+)"
        ),
    'syslog': re.compile( 
            r"(?P<date>\S+ \d+ \d+:\d+:\d+)\s+" 
            r"(?P<host>\S+)\s+" 
            r"(?P<type>\S+):\s+"
            r"(?P<message>.+)"
        ),
    'fail2ban': re.compile( 
            r"(?P<date>\S+ \d+:\d+:[\d,]+)\s+" 
            r"(?P<type>[\S.]+):\s+" 
            r"(?P<message>.+)"
        )
}



tuples = {
    'apache_access': namedtuple('apache_access',
        ['client_ip', 'identity', 'user', 'time', 'request',
        'status', 'bytes', 'referer', 'user_agent',
        'filepath', 'logtype', 'timestamp']
        ),
    'apache_error': namedtuple('apache_error', [
        'date', 'module', 'pid', 'client_ip', 'message',
        'filepath', 'logtype', 'timestamp']
        ),
    'syslog': namedtuple('syslog', [
        'date', 'host', 'type', 'message',
        'filepath', 'logtype', 'timestamp']
        ),
    'fail2ban': namedtuple('fail2ban', [
        'date', 'type', 'message',
        'filepath', 'logtype', 'timestamp']
        )
}



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


w = watcher.AutoWatcher()


paths = ['/var/log/apache2/', '/var/log/', '/var/log/tomcat/', '/x1/log']
filehandles = {}
json_pending = {}
last_push = {}

for t in tuples:
    json_pending[t] = []
    last_push[t] = time.time()

for path in paths:
    try:
        w.add_all(path, inotify.IN_ALL_EVENTS)
    except OSError as err:
        pass
    
if not w.num_watches():
    sys.exit(1)

poll = select.poll()
poll.register(w, select.POLLIN)

timeout = None

threshold = watcher.Threshold(w, 256)

gotindex = {}


class NodeThread(Thread):
    def assign(self, json, logtype, xes):
        self.json = json
        self.logtype = logtype
        self.xes = xes

    def run(self):
        global gotindex
        random.seed(time.time())
        #print("Pushing %u json objects" % len(json_pending))
        iname = time.strftime("logstash-%Y.%m.%d")
        sys.stderr.flush()
        if not iname in gotindex:
            gotindex[iname] = True
            if not self.xes.indices.exists(iname):
                self.xes.indices.create(index = iname, body = {
                        "mappings" : {
                            "apache_access" : {
                                "_all" : {"enabled" : True},
                                "properties" : {
                                    "@timestamp" : { "store": True, "type" : "date", "format": "yyyy/MM/dd HH:mm:ss"},
                                    "url" : { "store": True, "type" : "string", "index": "not_analyzed"},
                                }
                            }
                        }
                    }
                )
            
        js_arr = []
        for entry in self.json:
            js = entry._asdict()
            js['@version'] = 1
            js['@timestamp'] = time.strftime("%Y/%m/%d %H:%M:%S", time.gmtime())
            js['host'] = hostname
            if 'request' in js and not 'url' in js:
                match = re.match(r"(GET|POST)\s+(.+)\s+HTTP/.+", js['request'])
                if match:
                    js['url'] = match.group(2)
            if 'bytes' in js and js['bytes'].isdigit():
                js['bytes_int'] = int(js['bytes'])
            js_arr.append({
                '_op_type': 'index',
                '_index': iname,
                '_type': self.logtype,
                'doc': js,
                '_source': js
            })
            
        if len(js_arr) > 0:
            #es.bulk(index=iname, doc_type=self.logtype, body = js_arr )
            helpers.bulk(self.xes, js_arr)
        #except Exception as err:
            #print(err)
            

def connect_es():
    esx = Elasticsearch([
        {
            'host': 'ul1-eu-central.apache.org',
            'port': 443,
            'url_prefix': 'logstash',
            'use_ssl': True
            }
    ],
        max_retries=5,
        retry_on_timeout=True
    )
    return esx


def parseLine(path, data):
    global json_pending
    for line in (l.rstrip() for l in data.split("\n")):
        for r in regexes:
            match = regexes[r].match(line)
            if match:
                if not r == 'apache_access':
                    print("Found a " + r + " match")
                js = tuples[r]( filepath=path, logtype=r, timestamp = time.time() , **match.groupdict())
                json_pending[r].append(js)
                if not r == 'apache_access':
                    print("Appended a " + r + " match")
                break





class Loggy(Thread):
    def run(self):
        global timeout, w, tuples, regexes, json_pending, last_push
        xes = connect_es()
        while True:
            events = poll.poll(timeout)
            nread = 0
            if threshold() or not events:
                #print('reading,', threshold.readable(), 'bytes available')
                for evt in w.read(0):
                    nread += 1
        
                    # The last thing to do to improve efficiency here would be
                    # to coalesce similar events before passing them up to a
                    # higher level.
        
                    # For example, it's overwhelmingly common to have a stream
                    # of inotify events contain a creation, followed by
                    # multiple modifications of the created file.
        
                    # Recognising this pattern (and others) and coalescing
                    # these events into a single creation event would reduce
                    # the number of trips into our app's presumably more
                    # computationally expensive upper layers.
                    masks = inotify.decode_mask(evt.mask)
                    #print(masks)
                    path = evt.fullpath
                    #print(repr(evt.fullpath), ' | '.join(masks))
                    try:
                        if not u'IN_ISDIR' in masks:
                            
                            if (not u'IN_DELETE' in masks) and (not path in filehandles) and (path.find(".gz") == -1):
                                try:
                                    print("Opening " + path)
                                    filehandles[path] = open(path, "r")
                                    print("Started watching " + path)
                                    filehandles[path].seek(0,2)
                                except Exception as err:
                                    print(err)         
                                    
                            # First time we've discovered this file?
                            if u'IN_CLOSE_NOWRITE' in masks and not path in filehandles:
                                pass
                                    
                            # New file created in a folder we're watching??
                            elif u'IN_CREATE' in masks:
                                pass
                            
                            # File truncated?
                            elif u'IN_CLOSE_WRITE' in masks and path in filehandles:
                            #    print(path + " truncated!")
                                filehandles[path].seek(0,2)
                                
                            # File contents modified?
                            elif u'IN_MODIFY' in masks and path in filehandles:
                          #      print(path + " was modified")
                                rd = 0
                                data = ""
                                while True:
                                    line = filehandles[path].readline()
                                    if not line:
                                        #filehandles[path].seek(0,2)
                                        break
                                    rd += len(line)
                                    data += line
                              #  print("Read %u bytes.." % rd)
                                parseLine(path, data)
                            
                            
                            # File deleted? (close handle)
                            elif u'IN_DELETE' in masks:
                                if path in filehandles:
                                    print("Closed " + path)
                                    filehandles[path].close()
                                    del filehandles[path]
                                   # print("Stopped watching " + path)
                            
                            else:
                                pass
                            
                    except Exception as err:
                        print(err)
                        
        
            for x in tuples:
                if (time.time() > (last_push[x] + 15)) or len(json_pending[x]) > 20:
                    t = NodeThread()
                    t.assign(json_pending[x], x, xes)
                    t.start()
                    json_pending[x] = []
                    last_push[x] = time.time()
                
            if nread:
                #print('plugging back in')
                timeout = None
                poll.register(w, select.POLLIN)
            else:
                #print('unplugging,', threshold.readable(), 'bytes available')
                timeout = 1000
                poll.unregister(w)


parser = argparse.ArgumentParser(description='Command line options.')
parser.add_argument('--user', dest='user', type=str, nargs=1,
                   help='Optional user to run Loggy as')
parser.add_argument('--group', dest='group', type=str, nargs=1,
                   help='Optional group to run Loggy as')
parser.add_argument('--pidfile', dest='pidfile', type=str, nargs=1,
                   help='Optional pid file location')
parser.add_argument('--daemonize', dest='daemon', action='store_true',
                   help='Run as a daemon')
parser.add_argument('--stop', dest='kill', action='store_true',
                   help='Kill the currently running Loggy process')
args = parser.parse_args()

pidfile = "/var/run/loggy.pid"
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
    loggy = Loggy()
    loggy.start()
    
    
## Daemon class
class MyDaemon(Daemonize):
    def run(self, args):
        main()
    
# Get started!
if args.kill:
    print("Stopping Loggy")
    daemon = MyDaemon(pidfile)
    daemon.stop()
else:
    if args.daemon:
        print("Daemonizing...")
        daemon = MyDaemon(pidfile)
        daemon.start(args)
    else:
        main()