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

# Fetch config yaml
cpath = os.path.dirname(os.path.realpath(__file__))
try:
    config = yaml.load(open("%s/sesttings.yml" % cpath))
except:
    print("Can't find config, using defaults (/x1/archives/)")
    config = {
        'archivedir': '/x1/archives',
        'dumpfile': '/x1/archives/bademails.txt'
    }

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
    if recipient:
        # Construct a path to the mbox file we'll archive this inside
        listname, fqdn = recipient.split('@', 1)
        Y = time.strftime("%Y")
        M = time.strftime("%m")
        path = "%s/%s/%s/%s/%s.mbox" % (config['archivedir'], fqdn, listname, Y, M)
        dpath = "%s/%s/%s/%s" % (config['archivedir'], fqdn, listname, Y)
    if recipient and path:
        print("This is for %s, archiving under %s!" % (recipient, path))
        fro = msg.get('return-path', "unknown@unknown").strip('<>')
        fline = "From %s %s UTC\r\n" % (fro, time.strftime("%c", time.gmtime()))
        
        if not os.path.exists(dpath):
            print("Creating directory %s first" % dpath)
            os.makedirs(dpath)
        with open(path, "ab") as f:
            # Write From line so mbox knows what to do
            f.write(bytes(fline, encoding = 'ascii'))
            # Write the body, escape lines starting with "From ..." as ">From ..."
            f.write(re.sub(b"\nFrom ", b"\n>From ", msgstring))
            # End with two blank lines
            f.write(b"\r\n\r\n")
            f.close()
    else:
        print("Valid email received, but appears it's not for us. Nothing to do here.")

if __name__ == '__main__':
    main()
