#!/usr/bin/python
#
# Library logic for selfserve ss2: exception objects.
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

import logging

from ss2config import *

logger = logging.getLogger("%s.lib.exceptions" % LOGGER_NAME)

class SS2Exception(Exception):
  pass

class BadUserOrPassword(SS2Exception):
  pass

class NoSuchUser(BadUserOrPassword): # subclass, details hidden from user
  pass

class WeakPassword(SS2Exception):
  pass

class InvalidInput(SS2Exception):
  pass

class NoSuchToken(SS2Exception):
  pass

class CorruptToken(SS2Exception):
  pass

class ExpiredToken(NoSuchToken): # subclass, details hidden from user
  pass

class NonMatchingPasswords(SS2Exception):
  pass

class EncryptionError(SS2Exception):
  def __init__(self, ciphertext):
    """argument is a gnupg.Crypt object"""
    self.ciphertext = ciphertext

  def __repr__(self):
    return self.ciphertext.status + "\n" + self.ciphertext.stderr

  pass

if __name__ == '__main__':
    import sys
    raise Exception("Wrong invocation for %s as __main__" % sys.argv[0])
