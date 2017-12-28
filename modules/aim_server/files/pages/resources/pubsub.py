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
# OPENAPI-URI: /api/resources/pubsub
########################################################################
# get:
#   responses:
#     '200':
#       content:
#         application/json:
#           schema:
#             $ref: '#/components/schemas/PubSubConfiguration'
#       description: 200 response
#     default:
#       content:
#         application/json:
#           schema:
#             $ref: '#/components/schemas/Error'
#       description: unexpected error
#   security:
#   - cookieAuth: []
#   summary: Display your project's pubsub configuration
# post:
#   responses:
#     '200':
#       content:
#         application/json:
#           schema:
#             $ref: '#/components/schemas/PubSubConfiguration'
#       description: 200 response
#     default:
#       content:
#         application/json:
#           schema:
#             $ref: '#/components/schemas/Error'
#       description: unexpected error
#   security:
#   - cookieAuth: []
#   summary: Display your project's pubsub configuration
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
        
        xdomain = indata.get('domain')
        
        # Get pubsubs
        pubsub = {}
        with open("private/json/pubsub.json") as f:
            pubsub = json.load(f)
            f.close()
        
        pubsubconfig = {
            'domain': xdomain
        }
        for domain, entry in pubsub.items():
            if domain == xdomain:
                pubsubconfig = {
                    'domain': xdomain,
                    'type': entry['type'],
                    'source': entry['source']
                }
                break
        
        canModify = False
        for tlp, domain in session.user['canAdmin'].items():
            if "%s.apache.org" % domain == xdomain:
                pubsubconfig['project'] = tlp
                canModify = True
                break
    
        if not canModify and xdomain != 'foo.apache.org':
            raise API.exception(403, "You cannot edit the pubsub configuration for a project (%s) you are not on the PMC of" % xdomain)
        
        
        yield json.dumps(pubsubconfig)
        return
    
    # Finally, if we hit a method we don't know, balk!
    yield API.exception(400, "I don't know this request method!!")
    