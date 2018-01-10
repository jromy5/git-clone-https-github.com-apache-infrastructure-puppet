#!/usr/bin/python
#
# Library logic for selfserve ss2: interfacing with PGP.
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

import gnupg
import logging
import tempfile
import time
import urllib2

from ss2config import *

import selfserve.exceptions

logger = logging.getLogger("%s.lib.keys" % LOGGER_NAME)

HTTP_NOT_FOUND = 404
def fetch_key(availid):
  try:
    return urllib2.urlopen(KEY_FOR_AVAILID_URL % availid).read()
  except urllib2.HTTPError, he:
    if he.getcode() == HTTP_NOT_FOUND:
      return None
    else:
      raise

# TODO: this may need extension
def _fingerprint_for_gpg(fingerprint):
  # Note: this works even if a slash is not present
  slash = fingerprint.find('/')
  return fingerprint[slash+1:].replace(' ', '')

def maybe_encrypt(plaintext, fingerprints, keys):
  """If possible, encrypt PLAINTEXT to the subset of the given KEYS that
  are also present in FINGERPRINTS.  Return the new text and a boolean
  indicating whether encryption was done."""

  # Can we encrypt?
  if keys is None or fingerprints is None:
    return (plaintext, False)

  expiry = time.time() - 60 # one minute
  homedir = tempfile.mkdtemp(suffix='.%d' % expiry, dir=STATE_DIR, prefix="selfserve-gnupghome.")
  pgp = gnupg.GPG(gnupghome=homedir)
  pgp.import_keys(keys)
  fingerprints = map(_fingerprint_for_gpg, fingerprints)
  ciphertext = pgp.encrypt(plaintext, fingerprints, always_trust=True)
  if not ciphertext:
    raise selfserve.exceptions.EncryptionError(ciphertext)
  return (str(ciphertext), True)
