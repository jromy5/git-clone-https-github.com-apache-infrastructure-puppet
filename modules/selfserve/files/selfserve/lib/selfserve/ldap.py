#!/usr/bin/python
#
# Library logic for selfserve ss2: interfacing with LDAP.
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

import crypt
import ldap
import logging
import random
import re
import string
import time

from ss2config import *
import ssconfigprivate

import selfserve.exceptions
import selfserve.tokens

logger = logging.getLogger("%s.lib.ldap" % LOGGER_NAME)

# see ldap_get_options(3), http://www.openldap.org/lists/openldap-software/200202/msg00456.html
# TODO: shouldn't this complain, since the minotaur:636 cert is self-signed?
if REQUIRE_LDAP_CERT:
  ldap.set_option(ldap.OPT_X_TLS_REQUIRE_CERT, ldap.OPT_X_TLS_HARD)

def unprivileged_p(availid):
  logger.debug('checking privilegedness for availid=%s', availid)
  lh = ldap.initialize(LDAP_HOST)
  if REQUIRE_LDAP_CERT:
    ldap.set_option(ldap.OPT_X_TLS_REQUIRE_CERT, ldap.OPT_X_TLS_HARD)
  lh.bind_s(ssconfigprivate.SYSTEM_READ_DN, ssconfigprivate.SYSTEM_READ_PW)
  try:
    # check PRIVILEGED_ATTRS
    search_results = lh.search_s(USER_DN_T % availid, ldap.SCOPE_BASE, attrlist=ssconfigprivate.PRIVILEGED_ATTRS.split())
    assert len(search_results) == 1
    dn, attrs = search_results[0]
    if attrs:
      return False

    # check PRIVILEGED_GROUPS
    search_results = lh.search_s(BASE_DN, ldap.SCOPE_SUBTREE, 
                                 "member=%s" % USER_DN_T % availid, attrlist=['cn'])
    groups = set([attrs['cn'][0] for dn, attrs in search_results])
    admin_groups = set(ssconfigprivate.PRIVILEGED_GROUPS.split())
    logger.debug('groups=%s', groups)
    logger.debug('admin_groups=%s', admin_groups)
    if groups & admin_groups: # set intersection
      return False
  except:
    raise

  return True

def validate_existence(availid, extra_info=False):
  logger.debug('checking existence for availid=%s', availid)
  lh = ldap.initialize(LDAP_HOST)
  if REQUIRE_LDAP_CERT:
    ldap.set_option(ldap.OPT_X_TLS_REQUIRE_CERT, ldap.OPT_X_TLS_HARD)
  lh.bind_s(ssconfigprivate.SYSTEM_READ_DN, ssconfigprivate.SYSTEM_READ_PW)
  try:
    if extra_info:
      search_results = lh.search_s(USER_DN_T % availid, ldap.SCOPE_BASE, attrlist=['cn', 'asf-pgpKeyFingerprint'])
      dn, attrs = search_results[0]
      return {
        'fullname' : attrs['cn'][0],
        'fingerprints' : attrs.get('asf-pgpKeyFingerprint'),
      }
    else:
      lh.search_s(USER_DN_T % availid, ldap.SCOPE_BASE)
      # return {}
  except ldap.NO_SUCH_OBJECT:
    logger.info("no such user availid=%s", availid)
    raise selfserve.exceptions.NoSuchUser(availid)

def validate_existence_p(availid):
  try:
    validate_existence(availid)
    return True
  except selfserve.exceptions.NoSuchUser:
    return False

alphabet = string.ascii_lowercase + string.ascii_uppercase + string.digits
def _do_crypt(pw):
  salt = "$1$" + "".join([random.choice(alphabet) for i in range(6)])
  return "{CRYPT}%s" % crypt.crypt(pw, salt)

def _lh_passwd(lh, availid, pw):
  if not pw or len(pw) < 6:
    logger.debug('denying weak password for availid=%s', availid)
    raise selfserve.exceptions.WeakPassword("password '%s' too short" % '%s') # Nice shovel!

  # DO NOT USE lh.passwd_s(), see ss2config.py for reason
  logger.info('modifying password for availid=%s', availid)
  lh.modify_s(USER_DN_T % availid, [(ldap.MOD_REPLACE, PASSWORD_ATTR, _do_crypt(pw))])

def do_pw_reset(availid, pw1, pw2, hextoken, remote24):
  try:
    validate_existence(availid)
  except selfserve.exceptions.NoSuchUser:
    logger.warning('failed to unforget password for nonexistent availid=%s remote24=%s', availid, remote24)
    raise
  if not pw1 or not pw2 or pw1 != pw2:
    raise selfserve.exceptions.NonMatchingPasswords()

  logger.warning('unforgetting password for availid=%s remote24=%s', availid, remote24)

  lh = ldap.initialize(LDAP_HOST)
  if REQUIRE_LDAP_CERT:
    ldap.set_option(ldap.OPT_X_TLS_REQUIRE_CERT, ldap.OPT_X_TLS_HARD)
  lh.bind_s(ssconfigprivate.SYSTEM_DN, ssconfigprivate.SYSTEM_PW)
  # pass None for "oldPasswd"
  _lh_passwd(lh, availid, pw1)
  lh.unbind_s()
  lh = None

  selfserve.tokens.kill_token(hextoken)

def bind_as_user(availid, pw):
  logger.info('attempting to bind as availid=%s to host=%s', availid, LDAP_HOST)
  validate_existence(availid)
  lh = ldap.initialize(LDAP_HOST)
  if REQUIRE_LDAP_CERT:
    ldap.set_option(ldap.OPT_X_TLS_REQUIRE_CERT, ldap.OPT_X_TLS_HARD)
  try:
    lh.bind_s(USER_DN_T % availid, [pw, ''][pw is None])
    return lh
  except (ldap.INVALID_CREDENTIALS, ldap.UNWILLING_TO_PERFORM):
    logger.info('wrong password for availid=%s', availid)
    raise selfserve.exceptions.BadUserOrPassword(availid)

def do_pw_change(availid, old_pw, pw1, pw2):
  if not pw1 or not pw2 or pw1 != pw2:
    raise selfserve.exceptions.NonMatchingPasswords()

  logger.info('changing password for availid=%s', availid)

  lh = bind_as_user(availid, old_pw)
  _lh_passwd(lh, availid, pw1)
  lh.unbind_s()
  lh = None

def _has_predicated_attr(edits, attr, predicate):
  if edits.get(attr) is None:
    return False
  else:
    return any(map(predicate, edits[attr]))

def _validate_details_change(availid, edits):
  logger.debug('validating edits=%s ATTRIBUTES=%s', edits, ATTRIBUTES)
  for attr, attrdesc in ATTRIBUTES:
    if attr in edits and attrdesc[2]:
      if isinstance(edits[attr], type([])) and len(edits[attr]) != len(dict.fromkeys(edits[attr])):
        raise selfserve.exceptions.InvalidInput("Multiple values specified for '%s' attribute, "
                           "but values are not pairwise distinct" % attr)

  for attr, attrdesc in ATTRIBUTES:
    if attr in edits and not attrdesc[2] and isinstance(edits[attr], type([])) and len(edits[attr]) > 1:
      raise selfserve.exceptions.InvalidInput("Multiple values may not be specified for '%s' attribute" % attr)

  if 'mail' not in edits or edits['mail'] is None:
    raise selfserve.exceptions.InvalidInput("It is not possible to delete the attribute '%s' using this interface"
                       % 'mail')

  # catch mail loops and simple errors in email addresses
  for attr in ['mail', 'asf-altEmail']:
    addresses = edits.get(attr)
    if addresses:
      if isinstance(addresses, str): addresses = [addresses]

      for address in addresses:
        if address.lower() == '%s@apache.org' % availid:
          raise selfserve.exceptions.InvalidInput("Do not cause mail loop by entering your %s@apache.org address" % availid)

        if len(address.split('@')) != 2 or ' ' in address or ',' in address:
          raise selfserve.exceptions.InvalidInput("Invalid email address: %s" % repr(address))

  # Disallow leading/trailing space; does not affect behaviour but makes ldapsearch hard to use
  if _has_predicated_attr(edits, 'asf-pgpKeyFingerprint', lambda fp: re.search(r'^ | $', fp)):
    raise selfserve.exceptions.InvalidInput("Do not enter leading/trailing whitespace on key ids or fingerprints")

  # We allow 4 byte key id or 20-byte fingerprint; check only hex or spaces used
  if _has_predicated_attr(edits, 'asf-pgpKeyFingerprint', lambda fp: re.search(r'[^A-Fa-f0-9 ]', fp)):
    raise selfserve.exceptions.InvalidInput("Only the key id (or fingerprint) may be entered, for example: "
                       "'2CF8 6427' (without the quotes).")

  # check the length (with spaces removed); must be 8 or 40 digits
  if _has_predicated_attr(edits, 'asf-pgpKeyFingerprint', lambda fp: len(fp.replace(' ','')) != 8 and len(fp.replace(' ','')) != 40):
    raise selfserve.exceptions.InvalidInput("Unexpected length: only a key id (8 hex digits) or"
                        " fingerprint (40 hex digits) may be entered (embedded spaces are OK)")

  if _has_predicated_attr(edits, 'sshPublicKey', lambda authorized_key: re.search(r'^ | $', authorized_key)):
    raise selfserve.exceptions.InvalidInput("Do not enter leading/trailing whitespace on SSH keys")


def do_details_change(availid, old_pw, edits):
  if not old_pw:
    raise selfserve.exceptions.BadUserOrPassword(availid)

  logger.info('changing details for availid=%s', availid)

  _validate_details_change(availid, edits)

  # Don't delete a non-existent attribute, hence ldap.MOD_REPLACE
  mods = map(lambda attr: (edits[attr] is None)
                            and (ldap.MOD_REPLACE, attr, None)
                            or  (ldap.MOD_REPLACE, attr, edits[attr]),
             edits.keys())
  lh = bind_as_user(availid, old_pw)
  lh.modify_s(USER_DN_T % availid, mods)
  lh.unbind_s()
  lh = None

def fetch_attributes(availid, attributes):
  logger.info('fetching attributes for availid=%s', availid)
  validate_existence(availid)
  lh = ldap.initialize(LDAP_HOST)
  if REQUIRE_LDAP_CERT:
    ldap.set_option(ldap.OPT_X_TLS_REQUIRE_CERT, ldap.OPT_X_TLS_HARD)
  lh.bind_s(ssconfigprivate.SYSTEM_READ_DN, ssconfigprivate.SYSTEM_READ_PW)
  # This might throw an exception if AVAILID doesn't exist.  But we aren't
  # supposed to be executing this code in that case anyway.
  search_results = lh.search_s(USER_DN_T % availid, ldap.SCOPE_BASE, attrlist=attributes)
  dn, attrs = search_results[0]
  return attrs

if __name__ == '__main__':
    import sys
    raise Exception("Wrong invocation for %s as __main__" % sys.argv[0])
