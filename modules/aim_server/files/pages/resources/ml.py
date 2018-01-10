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
########################################################################
# OPENAPI-URI: /api/resources/ml
########################################################################
# get:
#   responses:
#     '200':
#       content:
#         application/json:
#           schema:
#             $ref: '#/components/schemas/MailingListConfiguration'
#       description: 200 response
#     default:
#       content:
#         application/json:
#           schema:
#             $ref: '#/components/schemas/Error'
#       description: unexpected error
#   security:
#   - cookieAuth: []
#   summary: Display your project's mailing list configuration
# post:
#   responses:
#     '200':
#       content:
#         application/json:
#           schema:
#             $ref: '#/components/schemas/MailingListConfiguration'
#       description: 200 response
#     default:
#       content:
#         application/json:
#           schema:
#             $ref: '#/components/schemas/Error'
#       description: unexpected error
#   security:
#   - cookieAuth: []
#   summary: Display your project's mailing list configuration
# 
########################################################################


"""
This is the personal project/resource listing handler for Aim
"""

import json
import re
import socket

def run(API, environ, indata, session):
    
    method = environ['REQUEST_METHOD']
    
    # Display a project's pubsub configuratrion
    if method == "GET" or method == "POST":
        
        xdomain = indata.get('ml')
        
        # Get mailing lists
        mls = {}
        with open("private/json/ml-modsubs.json") as f:
            mls = json.load(f)
            f.close()
            
        listname, listdomain = xdomain.split('@', 2)
        
        mlconfig = {
            'domain': listdomain,
            'listname': listname,
        }
        for l, entry in mls.items():
            if l == xdomain:
                mlconfig = {
                    'domain': listdomain,
                    'listname': listname,
                    'type': 'mailinglist',
                    'moderators': entry['moderators'],
                    'private': entry['private'],
                    'trailer': entry['trailer'],
                    'modunsubbed': entry['modunsubbed'],
                    'subscribers': []
                }
                break
        
        canModify = False
        for tlp, domain in session.user['canAdmin'].items():
            if "%s.apache.org" % domain == listdomain:
                mlconfig['project'] = tlp
                canModify = True
                break
    
        if not canModify:
            raise API.exception(403, "You cannot edit the mailing list configuration for a project (%s) you are not on the PMC of" % listdomain)
        
        
        yield json.dumps(mlconfig)
        return
    
    # Finally, if we hit a method we don't know, balk!
    yield API.exception(400, "I don't know this request method!!")
    