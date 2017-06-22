#!/usr/bin/python
#
# Helper file, run from cron to rm expired tokens.
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
import selfserve.tokens

os.chdir(os.path.dirname(sys.argv[0])) # for STATE_DIR
logger = logging.getLogger("%s.maint" % LOGGER_NAME)

if __name__ == '__main__':
  if not sys.stderr.isatty():
    logging.basicConfig(level=logging.__dict__[LOG_LEVEL_INTERACTIVE])
  else:
    logging.basicConfig(level=logging.DEBUG)
    logger.debug('enabled verbose logging since isatty(%d)', sys.stderr.fileno())
  for magics in [(PW_RESET_MAGIC, SESSION_MAGIC), ]:
    for hextoken, availid, expiry, _ in selfserve.tokens.iter_tokens(magics):
      if not selfserve.tokens.is_semantically_valid_token(hextoken, availid, expiry, None, None):
        # ### ignore NoSuchToken errors?
        selfserve.tokens.kill_token(hextoken)
