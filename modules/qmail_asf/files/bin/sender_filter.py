#!/usr/bin/env python
#
# Match ENV['SENDER'] against a list of email addresses (stored as a
# simple list in a file). Should SENDER match, then exit(100).
# Otherwise, exit(0) (and be very careful to exit with no other code).
#
# USAGE: sender_filter.py FILENAME
#
# FILE FORMAT:
#   one email address per line (leading/trailing whitespace is ignored)
#   blank lines ignored
#   comments are allowed: # in column 0. no leading whitespace.
#
# EXAMPLE:
#
#   # The current set of email to watch for
#
#   johndoe@example.com
#   janedoe@example.com
#   #notyet@example.com
#
#

import os
import sys


def match_sender(fname):
  sender = os.environ.get('SENDER')
  if not sender:
    sys.stderr.write('%s: empty ENV[SENDER]\n' % (progname(),))
    sys.exit(0)

  try:
    lines = open(fname).readlines()
  except IOError:
    # Presumably, file not found.
    sys.stderr.write("%s: file not found '%s'\n" % (progname(), fname))
    sys.exit(0)

  lines = [l.strip() for l in lines if l.strip() and not l.startswith('#')]

  for email in lines:
    if sender == email:
      # Matched.
      sys.exit(100)
  # No match


def progname():
  return os.path.basename(sys.argv[0])


if __name__ == '__main__':
  if len(sys.argv) != 2:
    sys.stderr.write('USAGE: %s FILENAME\n' % (progname(),))
    sys.exit(0)

  match_sender(sys.argv[1])
