#!/usr/bin/env python
#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# This is mfa.py - cron job for updating the MFA status of people

import json
import urllib2
import ConfigParser


def run():
    CONFIG = ConfigParser.ConfigParser()
    CONFIG.read("grouper.cfg")
    ORG_READ_TOKEN = CONFIG.get('github', 'token')
    
    MFA = {
        'disabled': {},
        'enabled': {}
    }
    
    # Users with MFA disabled
    for n in range(0,1000):
        url = "https://api.github.com/orgs/apache/members?access_token=%s&filter=2fa_disabled&page=%u" % (ORG_READ_TOKEN, n)
        response = urllib2.urlopen(url).read()
        if response:
            js = json.loads(response)
            if len(js) == 0:
                break
            for user in js:
                MFA['disabled'][user['login']] = True
    
    # Users with MFA enabled
    for n in range(0,1000):
        url = "https://api.github.com/orgs/apache/members?access_token=%s&filter=2fa_enabled&page=%u" % (ORG_READ_TOKEN, n)
        response = urllib2.urlopen(url).read()
        if response:
            js = json.loads(response)
            if len(js) == 0:
                break
            for user in js:
                MFA['enabled'][user['login']] = True
    
    json.dump(MFA, open("../mfa.json", "w"))
    print("All done!")


if __name__ == '__main__':
    run()
