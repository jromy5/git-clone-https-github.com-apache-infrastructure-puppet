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

MAX_PAGES = 1000


def fetch_users(token, filter, count=MAX_PAGES):
    users = set()
    for n in range(count):
        url = "https://api.github.com/orgs/apache/members?access_token=%s&filter=%s&page=%u" % (token, filter, n)
        response = urllib2.urlopen(url).read()
        if response:
            js = json.loads(response)
            if len(js) == 0:
                break
            for user in js:
                users.add(user['login'])
    return users


def gather_data(token):
    # Fetch the two types of users
    disabled = fetch_users(token, '2fa_disabled')
    all = fetch_users(token, 'all')

    return disabled, all.difference(disabled)


def write_mfa_file(fname, token):
    disabled, enabled = gather_data(token)
    all = disabled.union(enabled)

    MFA = {
        'disabled': {},
        'enabled': {}
    }
    for u in disabled:
        MFA['disabled'][u] = True
    for u in all:
        MFA['enabled'][u] = True

    json.dump(MFA, open(fname, 'w'))


def write_v2_file(fname, token):
    disabled, enabled = gather_data(token)

    MFA = {
        'disabled': list(disabled),
        'enabled': list(enabled),
    }

    json.dump(MFA, open(fname, 'w'))


if __name__ == '__main__':
    CONFIG = ConfigParser.ConfigParser()
    CONFIG.read("grouper.cfg")
    ORG_READ_TOKEN = CONFIG.get('github', 'token')

    write_v2_file('../mfa.json', ORG_READ_TOKEN)
    print("All done!")
