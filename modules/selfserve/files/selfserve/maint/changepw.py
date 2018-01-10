#!/usr/bin/env python
#
# Client-side app for those who don't want their LDAP password known to id.a.o.
#
# ====================================================================
#    Licensed to the Apache Software Foundation (ASF) under one
#    or more contributor license agreements.  See the NOTICE file
#    distributed with this work for additional information
#    regarding copyright ownership.  The ASF licenses this file
#    to you under the Apache License, Version 2.0 (the
#    "License"); you may not use this file except in compliance
#    with the License.  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing,
#    software distributed under the License is distributed on an
#    "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
#    KIND, either express or implied.  See the License for the
#    specific language governing permissions and limitations
#    under the License.
######################################################################

import getpass
import os
import sys

##########################
# Code to wire up lib dir
def wire():  
  here = os.path.dirname(os.path.abspath(__file__))
  parent = os.path.dirname(here)
  lib = os.path.join(parent, "lib") 
  sys.path.append(lib)
  config = os.path.join(parent, "config")
  sys.path.append(config)

wire()

from ss2config import *
import selfserve.exceptions
import selfserve.ldap


def get_username():
  # TODO: user get_password() to read from s/stdin/tty/
  #return os.getenv('AVAILID', raw_input('Username: '))
  availid = os.getenv('AVAILID')
  if availid:
    return availid
  else:
    return get_password('Username: ')

def get_password(prompt=None):
  return getpass.getpass(prompt and prompt or 'New LDAP Password: ')

def main():
  availid = get_username()
  pw1 = get_password()
  pw2 = get_password()

  # TODO: code duplication
  if not pw1 or not pw2 or pw1 != pw2:
    raise selfserve.exceptions.NonMatchingPasswords()
  if not pw1 or len(pw1) < 6:
    raise selfserve.exceptions.WeakPassword()

  print "\n".join((
    "dn: %s" % USER_DN_T % availid,
    "changetype: modify",
    "replace: %s" % PASSWORD_ATTR,
    "%s: %s" % (PASSWORD_ATTR, selfserve.ldap.do_crypt(pw1)),
    "",
  ))
  # Reader: pipe the output to
  #    "ldapmodify -WxD %s" % USER_DN_T % os.getenv('AVAILID').

if __name__ == '__main__':
  main()
