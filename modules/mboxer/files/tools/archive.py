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
archives the email in the correct mbox file. Does NOT differentiate
between public and private email.

Arguments (optional):
    --lid abcd@xyz.apache.org - use this instead of parsing list-post

    <security-realm> (optional)
    - restricted - file the mail under the directory defined by the 'restricteddir' config item
    - private    - file the mail under the directory defined by the 'privatedir' config item
    - anything else, file it under the directory defined by the 'archivedir' config item

   The above can be combined if required.
"""

import email.parser
import time
import re
import yaml
import os
import io
import sys
import stat
import fcntl
import errno
import argparse

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

# validate an email argument
def valid_mail(m):
    if re.match(r"^.+?@(.*apache\.org|apachecon\.com)$", m):
        return m
    else:
        raise argparse.ArgumentTypeError("%r is not a valid ASF email address" % m)

parser = argparse.ArgumentParser()
parser.add_argument("--lid", type=valid_mail, help="override list id")
parser.add_argument("security", nargs='?') # e.g. restricted, private or omitted
args = parser.parse_args()

def lock(fd):
    """ Attempt to lock a file, wait 0.1 secs if failed. """
    while True:
        try:
            fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
            break
        except BlockingIOError as e:
            if e.errno == errno.EAGAIN or e.errno == errno.EACCES:
                time.sleep(0.1)
            else:
                raise

def dumpbad(what):
    with open(config['dumpfile'], "ab") as f:
        lock(f) # Lock the file
        # The From ... line will always be there, or we couldn't have
        # received the msg in the first place.
        # Write the body, escape lines starting with "(>*)From ..." as ">(>*)From ..."
        # First line must not get an extra LF prefix
        f.write(re.sub(b"\n(>*)From ", b"\n>\\1From ", what))
        # End with one blank line
        f.write(b"\n")
        f.close() # implicitly releases the lock

def main():
    input_stream = sys.stdin.buffer
    
    msgstring = input_stream.read()
    msg = None
    
    # Try parsing the email headers
    try:
        msg = email.parser.BytesHeaderParser().parsebytes(msgstring)
    except Exception as err:
        print("STDIN parser exception: %s" % err)
    
    # If email wasn't valid, dump it in the bademails file
    if msgstring and not msg:
        print("Invalid email received, dumping in %s!" % config['dumpfile'])
        dumpbad(msgstring)
        sys.exit(0) # Bail quietly
    
    # So, we got an email now - who is it for??

    # Have we got a list id override?
    recipient = args.lid

    # If not, try List-Post
    if not recipient:
        header = msg.get('list-post')
        if header:
            print(header)
            m = re.match(r"<mailto:(.+?@.*?)>", header)
            if m:
                recipient = m.group(1)
            else:
                print("Unexpected list-post: %s" % header)
        else:
            print("Missing list-post: %s" % msg.get_unixfrom())
    
    if recipient:
        # validate listname and fqdn, just in case
        listname, fqdn = recipient.lower().split('@', 1)
        # Underscore needed for mod_ftp
        if not re.match(r"^[a-z0-9][-_.a-z0-9]*$", listname) or not re.match(r"^[a-z0-9][-.a-z0-9]*$", fqdn):
            # N.B. the parts are used as path name components so need to be safe for use
            print("Dirty listname or FQDN in '%s', dumping in %s!" % (recipient, config['dumpfile']))
            dumpbad(msgstring)
            sys.exit(0) # Bail quietly
        YM = time.strftime("%Y%m", time.gmtime()) # Use UTC
        adir = config['archivedir']
        dochmod = True
        if args.security == 'restricted':
            adir = config['restricteddir']
            dochmod = False
        elif args.security == 'private':
            adir = config['privatedir']
        # Construct a path to the mbox file
        fqdnpath = os.path.join(adir, fqdn)
        listpath = os.path.join(fqdnpath, listname)
        path = os.path.join(listpath, "%s.mbox" % YM)
        print("This is for %s, archiving under %s!" % (recipient, path))
        # Show some context in case the IO fails:
        print("Return-Path: %s" % msg.get('Return-Path'))
        print("Message-Id: %s" % msg.get('Message-Id'))
        if not os.path.exists(listpath):
            print("Creating directory %s first" % listpath)
            os.makedirs(listpath, exist_ok = True)
            # Since we're running as nobody, we need to...massage things for now
            # chmod fqdn and fqdn/list as 0705
            if dochmod:
                os.chmod(fqdnpath, stat.S_IWUSR | stat.S_IRUSR | stat.S_IXUSR | stat.S_IROTH | stat.S_IXOTH)
                os.chmod(listpath, stat.S_IWUSR | stat.S_IRUSR | stat.S_IXUSR | stat.S_IROTH | stat.S_IXOTH)
        with open(path, "ab") as f:
            lock(f) # Lock the file
            # Write the body, escape lines starting with "(>*)From ..." as ">(>*)From ..."
            # First line is the From_ line so must not be escaped
            # Actual message Header lines cannot start with '>*From '
            f.write(re.sub(b"\n(>*)From ", b"\n>\\1From ", msgstring))
            # End with one blank line
            f.write(b"\n")
            f.close() # Implicitly releases the lock
            os.chmod(path, stat.S_IWUSR | stat.S_IRUSR | stat.S_IROTH)
    else:
        # If we can't find a list for this, still valuable to print out what happened.
        # We shouldn't be getting emails we can't find a valid list for!
        sys.stderr.write("Valid email received, but appears it's not for us!\n")
        sys.stderr.write("  List-Post: %s\n  From: %s\n  To: %s\n  Message-ID: %s\n\n" % \
            (msg.get('list-post', "Unknown"), msg.get('from', "Unknown"), msg.get('to', "Unknown"), msg.get('message-id', "Unknown")))
        dumpbad(msgstring)
        sys.exit(-1) # exit with error (TODO is -1 correct?)

if __name__ == '__main__':
    main()

