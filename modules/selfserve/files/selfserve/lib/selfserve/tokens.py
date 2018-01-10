#!/usr/bin/python
#
# Library logic for selfserve ss2: authz tokens.
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

import errno
import glob
import logging
import os
import re
import time

from ss2config import *

import selfserve.exceptions
import selfserve.ldap
import selfserve.util

logger = logging.getLogger("%s.lib.tokens" % LOGGER_NAME)

pattern_of_a_magic = re.compile(r'^[0-9a-f]{16}')
def _ismagic(magic):
  return re.match(pattern_of_a_magic, magic)

def censor_token(hextoken):
  "return a string from which the token can be determined given a list of candidates, but not guessed"
  halfway = int(len(hextoken) / 2)
  return hextoken[:halfway] + '.' * (len(hextoken) - halfway)

def _path_token(hextoken):
  return os.path.join(STATE_DIR, hextoken)

def kill_token(hextoken):
  logger.info('killing token=%s', censor_token(hextoken))
  try:
    os.unlink(_path_token(hextoken))
  except (IOError, OSError), e:
    if hasattr(e, 'errno') and e.errno in ( errno.ENOENT, errno.EISDIR ):
      raise selfserve.exceptions.NoSuchToken(hextoken)
    else:
      raise e

def _save_token(magic, hextoken, availid, expiry, cookie):
  fd = open(_path_token(hextoken), 'w')
  fd.writelines(map(lambda x: str(x)+"\n", [magic, hextoken, availid, expiry, cookie]))
  fd.close()
  logger.debug('saved token=%s availid=%s expiry=%d cookie=%s', censor_token(hextoken), availid, expiry, cookie)

def _read_token(magics, hextoken):
  logger.debug('reading token=%s', censor_token(hextoken))
  try:
    # parsing
    fd = open(_path_token(hextoken))
    mymagic    = fd.readline().rstrip()
    myhextoken = fd.readline().rstrip()
    availid    = fd.readline().rstrip()
    expiry     = fd.readline().rstrip()
    cookie     = fd.readline().rstrip() # not validated here

    # input validation
    bad = None
    if not bad and not _ismagic(mymagic): bad = 'magic (not _ismagic())'
    if not bad and mymagic not in magics: bad = 'magic (foreign=%s expected=%s)' % (mymagic, magics)
    if not bad and myhextoken != hextoken: bad = 'hextoken line'
    if not bad:
      try: expiry = int(expiry)
      except ValueError: bad = 'expiry'

    if bad:
      logger.error('malformed token=%s : bad %s', censor_token(hextoken), bad)
      raise selfserve.exceptions.CorruptToken(hextoken)

    logger.debug('parsed token=%s magic=%s', censor_token(hextoken), mymagic)

    # done
    return hextoken, availid, expiry, cookie
  except (OSError, IOError), e:
    if hasattr(e, 'errno') and e.errno in ( errno.ENOENT, errno.EISDIR ):
      logger.info('nonexistent token=%s: probably expired', censor_token(hextoken))
      raise selfserve.exceptions.NoSuchToken(hextoken)
    elif isinstance(e, selfserve.exceptions.SS2Exception):
      raise e
    else:
      logger.error('Exception reading token=%s: %s', censor_token(hextoken), `e`)
      raise

def assert_semantically_valid_token(hextoken, availid, expiry, cookie, wantcookie):
  if not selfserve.ldap.validate_existence_p(availid):
    logger.error('malformed token=%s: bad availid', censor_token(hextoken))
    raise selfserve.exceptions.CorruptToken(hextoken)
  if wantcookie is not None and cookie != wantcookie:
    logger.error('malformed token=%s: cookie mismatch: got=%r expected=%r', censor_token(hextoken), cookie, wantcookie)
    raise selfserve.exceptions.CorruptToken(hextoken)
  if expiry < time.time():
    logger.info('expired token=%s: availid=%s is %d seconds late',
                censor_token(hextoken), availid, time.time() - expiry)
    raise selfserve.exceptions.ExpiredToken(hextoken)

def is_semantically_valid_token(hextoken, availid, expiry, cookie, wantcookie):
  try:
    assert_semantically_valid_token(hextoken, availid, expiry, cookie, wantcookie)
    return True
  except (selfserve.exceptions.CorruptToken, selfserve.exceptions.ExpiredToken):
    return False

def has_token(magic, hextoken, wantcookie):
  hextoken, availid, expiry, cookie = _read_token([magic], hextoken)
  assert_semantically_valid_token(hextoken, availid, expiry, cookie, wantcookie)
  return hextoken, availid, expiry

def iter_tokens(magics):
  # two hex letters per byte
  for tokenfile in glob.iglob(_path_token('[0-9a-fA-F]' * 2*TOKEN_LENGTH)):
    logger.debug("iterating: examining %s", tokenfile)
    try:
      yield _read_token(magics, os.path.basename(tokenfile))
    except (selfserve.exceptions.CorruptToken, selfserve.exceptions.NoSuchToken):
      # already logged at raise
      pass

def make_token(magic, availid, seconds=TOKEN_EXPIRY, cookie='42'):
  expiry = int(time.time()) + seconds
  hextoken = selfserve.util.get_hexed_random_bytes(TOKEN_LENGTH)
  logger.info("new token=%s magic=%s availid=%s expiry=%d cookie=%s", censor_token(hextoken), magic, availid, expiry, cookie)
  _save_token(magic, hextoken, availid, expiry, cookie)
  return hextoken, expiry

if __name__ == '__main__':
    import sys
    raise Exception("Wrong invocation for %s as __main__" % sys.argv[0])
