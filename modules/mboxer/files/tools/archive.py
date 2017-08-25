#!/usr/bin/env python3
# -*- coding: utf-8 -*-
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

""" 

This script determines the intended ASF recipient of an email and
archives the email in the correct mbox file. Does NOT discern
between public and private email.

"""

import email
import time
import re
import yaml
import os
import io
import sys
import stat
import fcntl
import errno

# Fetch config yaml
cpath = os.path.dirname(os.path.realpath(__file__))
try:
    config = yaml.load(open("%s/settings.yml" % cpath))
except:
    print("Can't find config, using defaults (/x1/archives/)")
    config = {
        'archivedir': '/x1/archives',
        'restricteddir': '/x1/restricted',
        'dumpfile': '/x1/archives/bademails.txt'
    }

def lock(fd):
    """ Attempt to lock a file, wait 0.1 secs if failed. """
    while True:
        try:
            fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
            break
        except BlockingIOError as e:
            if e.errno != errno.EAGAIN:
                raise
            else:
                time.sleep(0.1)

def main():
    input_stream = sys.stdin.buffer
    
    msgstring = input_stream.read()
    msg = None
    
    # Try loading the email
    try:
        msg = email.message_from_bytes(msgstring)
    except Exception as err:
        print("STDIN parser exception: %s" % err)
    
    # If email wasn't valid, dump it in the bademails file
    if msgstring and not msg:
        print("Invalid email received, dumping in %s!" % config['dumpfile'])
        with open(config['dumpfile'], "ab") as f:
            # Write From line so mbox knows what to do
            fline = "From invalid@unknown %s UTC\r\n" % time.strftime("%c", time.gmtime())
            f.write(bytes(fline, encoding = 'ascii'))
            # Write the body, escape lines starting with "From ..." as ">From ..."
            f.write(re.sub(b"(^|\n)From ", b"\n>From ", msgstring))
            # End with two blank lines
            f.write(b"\r\n\r\n")
            f.close()
        sys.exit(0)
    
    # So, we got an email now - who is it for??
    
    # Try List-Post first
    recipient = None
    if msg.get('list-post'):
        header = msg.get('list-post')
        print(header)
        m = re.match(r"<mailto:(.+@.*apache.org)>", header)
        if m:
            recipient = m.group(1)
    
    # If no bueno, try Received headers
    if not recipient and msg.get('received'):
        # Get all headers, oldest first
        headers = reversed(msg.get_all('received'))
        for header in headers:
            # Find the first (oldest) that mentions apache.org as recipient
            m = re.search(r"for <(.+@.*apache.org)>", header)
            if m:
                recipient = m.group(1)
                break
    path = None
    dpath = None
    if recipient:
        # Construct a path to the mbox file we'll archive this inside
                
        # validate listname and fqdn, just in case
        listname, fqdn = recipient.lower().split('@', 1)
        if not re.match(r"^[a-z0-9][-.a-z0-9]*$", listname) or not re.match(r"^[a-z0-9][-.a-z0-9]*$", fqdn):
            print("Dirty listname or FQDN, bailing!")
            sys.exit(0) # Bail quietly
        YM = time.strftime("%Y%m")
        adir = config['archivedir']
        dochmod = True
        if len(sys.argv) > 1 and sys.argv[1] == 'restricted':
            adir = config['restricteddir']
            dochmod = False
        path = "%s/%s/%s/%s.mbox" % (adir, fqdn, listname, YM)
        dpath = "%s/%s/%s" % (adir, fqdn, listname)
        print("This is for %s, archiving under %s!" % (recipient, path))
        if not os.path.exists(dpath):
            print("Creating directory %s first" % dpath)
            os.makedirs(dpath, exist_ok = True)
            # Since we're running as nobody, we need to...massage things for now
            # chmod fqdn, fqdn/list and fqdn/list/year as 0705
            if dochmod:
                xpath = "%s/%s" % (adir, fqdn)
                os.chmod(xpath, stat.S_IWUSR | stat.S_IRUSR | stat.S_IXUSR | stat.S_IROTH | stat.S_IXOTH)
                xpath = "%s/%s/%s" % (adir, fqdn, listname)
                os.chmod(xpath, stat.S_IWUSR | stat.S_IRUSR | stat.S_IXUSR | stat.S_IROTH | stat.S_IXOTH)                
        with open(path, "ab") as f:
            lock(f) # Lock the file
            # Write the body, escape lines starting with "From ..." as ">From ..."
            f.write(re.sub(b"\nFrom ", b"\n>From ", msgstring))
            # End with two blank lines
            f.write(b"\r\n\r\n")
            f.close() # Implicitly releases the lock
            os.chmod(path, stat.S_IWUSR | stat.S_IRUSR | stat.S_IROTH)
    else:
        print("Valid email received, but appears it's not for us. Nothing to do here.")

if __name__ == '__main__':
    main()

