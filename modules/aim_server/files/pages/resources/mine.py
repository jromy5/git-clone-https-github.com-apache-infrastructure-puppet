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
# OPENAPI-URI: /api/resources/mine
########################################################################
# get:
#   responses:
#     '200':
#       content:
#         application/json:
#           schema:
#             $ref: '#/components/schemas/ProjectList'
#       description: 200 response
#     default:
#       content:
#         application/json:
#           schema:
#             $ref: '#/components/schemas/Error'
#       description: unexpected error
#   security:
#   - cookieAuth: []
#   summary: Display your projects and resources
# post:
#   responses:
#     '200':
#       content:
#         application/json:
#           schema:
#             $ref: '#/components/schemas/ProjectList'
#       description: 200 response
#     default:
#       content:
#         application/json:
#           schema:
#             $ref: '#/components/schemas/Error'
#       description: unexpected error
#   security:
#   - cookieAuth: []
#   summary: Display your projects and resources
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
    
    # Display user's projects and resources
    if method == "GET" or method == "POST":
        
        # Get mailing lists and mods
        mlmods = {}
        with open("private/json/ml-modsubs.json") as f:
            mlmods = json.load(f)
            f.close()
            
        # Get pubsubs
        pubsub = {}
        with open("private/json/pubsub.json") as f:
            pubsub = json.load(f)
            f.close()
            
        # Get all repos
        repositories = {}
        with open("private/json/repositories.json") as f:
            repositories = json.load(f)
            f.close()
        
        projects = {
            'pmcs': []
        }
        
        for pmc, domain in session.user['pmcs'].items():
        
            # DNS
            dns = False
            try:
                dns = socket.gethostbyname("%s.apache.org" % domain)
            except:
                pass
            
            # Fetch mailing lists
            mls = {}
            for ml, entry in mlmods.items():
                l,tlp = ml.split("@", 2)
                if tlp == "%s.apache.org" % domain and not 'infra' in l:
                    mls[l] = {
                        'moderators': entry['moderators'],
                        'subscribers': len(entry['subscribers'])
                    }
            
            
            # Fetch pubsub settings
            ps = None
            for dom, entry in pubsub.items():
                if dom == "%s.apache.org" % domain:
                    ps = entry
            
            # Fetch repositories
            repos = []
            for dom, entry in repositories.items():
                if dom == domain or dom == pmc:
                    repos = entry
                    break
                    
            project = {
                'podling': pmc in session.user['podlings'],
                'dns': dns,
                'id': pmc,
                'mailinglists': mls,
                'pubsub': ps,
                'repositories': repos,
                'domain': "%s.apache.org" % domain
            }
            projects['pmcs'].append(project)
        yield json.dumps(projects)
        return
    
    # Finally, if we hit a method we don't know, balk!
    yield API.exception(400, "I don't know this request method!!")
    