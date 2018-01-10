#!/usr/bin/python
#
# Library logic for selfserve ss2: email.
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
import os
import re
import smtplib
import socket
import time
import StringIO

import ezt

from ss2config import *

import selfserve.keys
import selfserve.ldap
import selfserve.tokens
import selfserve.util

logger = logging.getLogger("%s.lib.email" % LOGGER_NAME)

def _hostname():
  return socket.gethostbyaddr(socket.gethostname())[0]

def _make_msgid():
  return "%s.%s@%s" % \
         (time.strftime('%Y%m%d%H%M%S'), selfserve.util.get_hexed_random_bytes(6), _hostname())

def _maybe_encrypt_rfc822(rfc822text, fingerprints, keys):
  rfc822lines = rfc822text.splitlines(True)
  endofheaders = rfc822lines.index("\n")
  headers = "".join(rfc822lines[:endofheaders])
  body = "".join(rfc822lines[endofheaders+1:])
  body, crypted = selfserve.keys.maybe_encrypt(body, fingerprints, keys)
  return (headers + "\n" + body, crypted)

# TODO(bluesky): layering violation of LOOKUP
def send_email(availid, template_dir, remote24, base_url):
  logger.info('emailing availid=%s remote24=%s', availid, remote24)
  infos = selfserve.ldap.validate_existence(availid, True)
  keys = selfserve.keys.fetch_key(availid)
  if selfserve.ldap.unprivileged_p(availid):
    hextoken, expiry = selfserve.tokens.make_token(PW_RESET_MAGIC, availid, cookie=remote24)
  else:
    # root@ cannot reset their passwords.  (Use ../maint/changepw.py instead.)
    # Proceed normally, but without actually creating a token.
    hextoken, expiry = (selfserve.util.get_hexed_random_bytes(TOKEN_LENGTH), int(time.time()) - 86400)
    logger.warning("fabricating token=%s expiry=%d for privileged availid=%s",
                hextoken, expiry, availid)
  msgid = _make_msgid()
  to = '%s@apache.org' % availid
  tdata = {
      'availid' : availid,
      'remote24' : remote24,
      'base_url' : base_url,
      'to' : to,
      'fullname' : infos['fullname'],
      'fromAddress': FROM_ADDRESS,
      'SERVER_ADMIN' : FROM_ADDRESS,
      'token' : hextoken,
      'deadline' : time.strftime(TIME_FMT, time.gmtime(expiry)),
      'message_id' : msgid,
  }
  template = ezt.Template(os.path.join(template_dir, 'resetpassword.email'),
                          compress_whitespace=False)
  buffer = StringIO.StringIO()
  template.generate(buffer, tdata)
  rfc822text = buffer.getvalue()
  rfc822text, crypted = _maybe_encrypt_rfc822(rfc822text, infos['fingerprints'], keys)
  # TODO: Update fail2ban if you change this message!
  logger.warning("emailing password reset token to availid=%s message-id=<%s> remote24=%s encrypted=%s",
                 availid, msgid, remote24, str(crypted))
  smtp = smtplib.SMTP(SMTP_HOST)
  if SMTP_USER:
    smtp.login(SMTP_USER, SMTP_PASSWORD)
  smtp.sendmail(FROM_ADDRESS, to, rfc822text)
  smtp.quit()

  return msgid

if __name__ == '__main__':
    import sys
    raise Exception("Wrong invocation for %s as __main__" % sys.argv[0])
