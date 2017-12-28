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
# OPENAPI-URI: /api/resources/repo
########################################################################
# get:
#   responses:
#     '200':
#       content:
#         application/json:
#           schema:
#             $ref: '#/components/schemas/RepositoryConfiguration'
#       description: 200 response
#     default:
#       content:
#         application/json:
#           schema:
#             $ref: '#/components/schemas/Error'
#       description: unexpected error
#   security:
#   - cookieAuth: []
#   summary: Display your project's repository configuration
# post:
#   responses:
#     '200':
#       content:
#         application/json:
#           schema:
#             $ref: '#/components/schemas/RepositoryConfiguration'
#       description: 200 response
#     default:
#       content:
#         application/json:
#           schema:
#             $ref: '#/components/schemas/Error'
#       description: unexpected error
#   security:
#   - cookieAuth: []
#   summary: Display your project's repository configuration
# 
########################################################################


"""
This is the repository config handler for Aim
"""

import json
import re
import socket

def run(API, environ, indata, session):
    
    method = environ['REQUEST_METHOD']
    
    # Display a project's pubsub configuratrion
    if method == "GET" or method == "POST":
        
        project = indata.get('project', 'foo')
        repo = indata.get('repo', 'foo')
        
        # Get repositories
        repos = {}
        with open("private/json/repositories.json") as f:
            repos = json.load(f)
            f.close()
            
        
        if not project in session.user['canAdmin']:
            raise API.exception(403, "You are not a part of this project!")
        
        
        repoconfig = {
            'project': project,
            'domain': session.user['canAdmin'][project],
            'repository': repo,
            'podling': project in session.user['podlings']
        }
        
        
        if project in repos:
            for v in repos[project]:
                if v['repository'] == repo:
                    repoconfig['type'] = v['type']
                    break
        
        yield json.dumps(repoconfig)
        return
    
    # Finally, if we hit a method we don't know, balk!
    yield API.exception(400, "I don't know this request method!!")
    